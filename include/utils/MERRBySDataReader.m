classdef MERRBySDataReader
%MERRBySDataReader - Class to read MERRByS GNSS-R data from NetCDF format
%
%   Tested on Matlab 2016a MS. Windows
%
%
% MERRByS Dataset License:
% The MERRByS dataset from from SSTL is licensed under a Creative Commons
% Attribution-NonCommercial 4.0 International License.
%
% Software License:
%  MIT License
% 
% Copyright (c) 2017 Surrey Satellite Technology Ltd.
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
%

    methods (Static)

        function [metadata, ddmData] = ReadL1BGivenDateTimeRange(basePath, dateTimeRange, readDDMs)
        % ReadL1BGivenDateTimeRange Read MERRByS data file for given time dateTimeRange
        % Inputs:
        %     basePath:      The 'L1B' folder location
        %     dateTimeRange: A 2 element array of datenum, for start and stop
        %                    times of the collection
        %     readDDMs:      Boolean property as to whether the DDM file
        %                    should be read
        
            % Ensure path has trailing /
            if basePath(end) ~= '/' && basePath(end) ~= '\'
                basePath = [basePath, '/'];
            end
        
            dataPath = [basePath MERRBySDataReader.GetIDCodeFromDateRange(dateTimeRange) '/'];
            paths = MERRBySDataReader.GetPaths(dataPath);
            
            [metadata, ddmData] = MERRBySDataReader.ReadL1B(paths.metadata, paths.ddms, readDDMs);
            
        end
        
        function [metadata, ddmData] = ReadL1BGivenPath(filePath, readDDMs)
        % ReadL1BGivenPath Read MERRByS data file
        % Inputs:
        %     filePath:      The location of either the metadata.nc or DDMs.nc file
        %     readDDMs:      Boolean property as to whether the DDM file
        %                    should be read
        
            [pathstr,~, ~] = fileparts(filePath);
            
            dataPath = [pathstr MERRBySDataReader.GetIDCodeFromDateRange(dateTimeRange) '/'];
            paths = MERRBySDataReader.GetPaths(dataPath);
            
            [metadata, ddmData] = MERRBySDataReader.ReadL1B(paths.metadata, paths.ddms, readDDMs);
        end
        
        function dateTimeNum = ParseDateTimeString(dateTimeString)
        %ParseDateTimeString Parse date time in format yyyyMMddTHH:mm:ss.FFF
            dateTimeString = strtrim(dateTimeString);
            year = str2double(dateTimeString(1:4));
            month = str2double(dateTimeString(5:6));
            day = str2double(dateTimeString(7:8));
            hour = str2double(dateTimeString(10:11));
            minute = str2double(dateTimeString(13:14));
            second = str2double(dateTimeString(16:end));

            dateTimeNum = datenum(year, month, day, hour, minute, second);
        end
        
        function result = EnsureFolderHasFinalSlash(input)
        %EnsureFolderHasFinalSlash Ensure that folder has / or \ at end
            result = input;
            if result(end) ~= '/' && result(end) ~= '\'
                result = [result, '/'];
            end
        end
        
        function dataIdOut = DataIdWithDotSeparators(dataIdIn)
        % dataIdWithDotSeparators Convert DataId from / separators to . so
        % that it can be used in a file name
            dataIdOut = strrep(dataIdIn, '/', '.');
        end
        
        function dataIdList = GetListOfDataInRange(startDateTime, stopDateTime, segmentationTimeHours)
        %GetListOfDataInRange Get the list of dataIds in the date time range
            segmentationTime = segmentationTimeHours / 24;
            thisStartTime = startDateTime;
            thisStopTime = thisStartTime + segmentationTime;

            % Loop through all time segments from startDateTime
            dataIdList = cell(0);
            dataIdListIdx = 1;
            while thisStopTime <= stopDateTime + (1/24/60/60)
                % Add to list for processing
                dataId = MERRBySDataReader.GetIDCodeFromDateRange([thisStartTime thisStopTime]);
                dataIdList{dataIdListIdx} = dataId;

                % Move to the next step
                thisStartTime = thisStartTime + segmentationTime;
                thisStopTime = thisStartTime + segmentationTime;
                dataIdListIdx = dataIdListIdx + 1;
            end
        end
        
        function [metadata, ddmData] = ReadL1B(metadataPath, ddmsPath, readAllDDMs, varNames)
        %ReadL1B Reads MERRByS L1B files
        %   Inputs:
        %     metadataPath  Path to metadata.nc file
        %     ddmsPath      Path to ddms.nc file
        %     readAllDDMs   Read all the DDMs
        %     globalVarNames Cell array of variable names to read in. Use {'all'} for all variables
        %     trackVarNames Cell array of variable names to read in from tracks.  Use {'all'} for all variables
        %   Outputs:
        %     metadata Structure containing the metadata
        %     ddmData  Matrix of the DDMs

            %Initialise the data structure
            metadata = [];
            
            % Ensure that some fields are always loaded as these are
            % required
            varNames = [varNames, 'IntegrationMidPointTime', 'SpecularPointLon', 'SpecularPointLat'];
            
            ME = [];
            try
                % Open the netCDF metadata file
                ncid = netcdf.open(metadataPath, 'NC_NOWRITE');
                % List out the groups in the file. One group per track
                groupNcids = netcdf.inqGrps(ncid);

                % Read out all the attributes
                metadata.attributes = MERRBySDataReader.ReadMetadataAttributes(ncid);

                % Read out all the variables
                [metadata.varNames, metadata.vars, metadata.varTypes] = MERRBySDataReader.ReadNetCDFVariables(ncid, varNames);

                %Record some sizes
                metadata.numOfTracks = length(groupNcids);
                metadata.varColumns = length(metadata.varNames);
                % Initialise
                metadata.trackLength = zeros(length(groupNcids),1);

                % Loop through all the tracks / groups
                for trackGroupIdx = 1:metadata.numOfTracks
                    %Check that the Track ID matches the index
                    groupName = str2double(netcdf.inqGrpName(groupNcids(trackGroupIdx)));
                    if groupName ~= (trackGroupIdx - 1)
                        error('Error reading NetCDF: groupName not as expected');
                    end

                    % Read in the variable data for this track
                    [metadata.trackVarNames, metadata.trackVars{trackGroupIdx}, metadata.trackVarTypes] = MERRBySDataReader.ReadNetCDFVariables(groupNcids(trackGroupIdx), varNames);

                    %Record the size of the track
                    [metadata.trackLength(trackGroupIdx), ~] = size(metadata.trackVars{trackGroupIdx});
                    metadata.trackVarColumns = length(metadata.trackVarNames);

                    % Read in the attributes - equivalent to the Track Header
                    metadata.trackAttributes{trackGroupIdx} = MERRBySDataReader.ReadMetadataAttributes(groupNcids(trackGroupIdx));

                    % Check the attribute TrackID is the same as the index
                    if metadata.trackAttributes{trackGroupIdx}.TrackID ~= (trackGroupIdx - 1)
                        error('Error reading NetCDF: TrackId not as expected');
                    end

                    % Locate the track's corresponding time stamps in the receiverData
                    % For each track go through the trackVars array and find the
                    % corresponding row in the receiverData array
                    receiverDataTimes = metadata.vars(:, metadata.varNames.IntegrationMidPointTime);
                    trackVarsTimes = metadata.trackVars{trackGroupIdx}(:, metadata.trackVarNames.IntegrationMidPointTime);
                    [~, idxsRD, idxsTD] = intersect(receiverDataTimes, trackVarsTimes);
                    if length(trackVarsTimes) ~= length(idxsTD)
                        error('Not all track epochs were found in receiver file');
                    end
                    % Add this to the trackVars array
                    [rows, columns] = size(metadata.trackVars{trackGroupIdx});
                    metadata.trackVars{trackGroupIdx}(:, columns + 1) = idxsRD';
                    metadata.trackVarNames.ReceiverDataIdx = columns + 1;

                end

                netcdf.close(ncid);
                
            catch ME
            end
            %close the open resources
            if ~isempty(ME)
                if exist('ncid', 'var')
                netcdf.close(ncid);
                rethrow(ME);
                else
                    error(['File exists but unable to open: ', metadataPath])
                end
            end

            % Read the DDM file if requested
            if readAllDDMs
                ddmData = MERRBySDataReader.ReadL1BDDMFile(ddmsPath, metadata, (1:metadata.numOfTracks));
            end

        end
        
        function [result] = GetIDCodeFromDateRange(dateTimeRange)
        %GetIDCodeFromDateRange Returns the identification string for the data files associated with the date time range
        % Inputs:
        %   dateTimeRange(1) is the start datenum
        %   dateTimeRange(2) is the stop datenum
        % Outputs:
        %   A string of the form 'yyyy-mm/dd' for any range of 24 hours or
        %   greater. A strin of the form 'yyyy-mm/dd/HH' for any range of
        %   less than 24 hours.
        
            if (dateTimeRange(2) - dateTimeRange(1)) < datenum(0, 0, 0, 23, 59, 59)
                %Use mid-point if duration less than a day
                midPoint = (dateTimeRange(2) - dateTimeRange(1)) / 2 + dateTimeRange(1);
                monthlyFolderName = datestr(midPoint, 'yyyy-mm');
            	dailyFolderName =  [datestr(midPoint, 'dd'), '/H', datestr(midPoint, 'HH')];
            else
                monthlyFolderName = datestr(dateTimeRange(1), 'yyyy-mm');
                dailyFolderName =  datestr(dateTimeRange(1), 'dd');
            end
            
            result = [monthlyFolderName, '/', dailyFolderName];
        end

        
        function [paths] = GetPaths(basePath, dataId, L1B_tag, L2_tag)
        % GetPaths Determine paths to the components of the dataset
        % Inputs:
        %     basePath:      The folder location of the data
        %     dataId:        The ID of the data, e.g. 2016-01/01/
        %     L1B_tag:       L1B folder name - normally just 'L1B' (optional)
        % Outputs:
        %     paths : A structure containing:
        %       metadata
        %       ddms
        %       directSignals
        %       blackbodyNadir
        %       blackbodyZenith
        %       searchTracks
            
            % Ensure path has trailing /
            if basePath(end) ~= '/' && basePath(end) ~= '\'
                basePath = [basePath, '/'];
            end
            
            % Default L1B folder name
            if ~exist('L1B_tag', 'var')
                L1B_tag = 'L1B';
            end
            if ~exist('L2_tag', 'var')
                L2_tag = 'L2_FDI';
            end
            
            dataPath = [basePath, L1B_tag, '/', dataId, '/'];
        
            paths.basePath = basePath;
            %L1B
            paths.metadata = [dataPath, 'metadata.nc'];
            paths.ddms = [dataPath, 'ddms.nc'];
            paths.directSignals = [dataPath, 'directSignalPower.nc'];
            paths.blackbodyNadir = [dataPath, 'blackbodyNadir.nc'];
            paths.blackbodyZenith = [dataPath, 'blackbodyZenith.nc'];
            %L1B catalogue
            paths.catalogue = [basePath, 'L1B_Catalogue/', dataId, '/',];
            paths.quickLookImages = [basePath, 'L1B_Catalogue/', dataId, '/QuickLook/'];
            paths.summaryImages = [basePath, 'L1B_Catalogue/', dataId, '/SummaryImages/'];
            paths.searchTracks = [basePath, 'L1B_Catalogue/', dataId, '/SearchTracks/'];
            paths.kml = [basePath, 'L1B_Catalogue/', dataId, '/KML/'];
            paths.kmz = [basePath, 'L1B_Catalogue/', '/', dataId, '/', MERRBySDataReader.DataIdWithDotSeparators(dataId), '.kmz'];
            %L2
            paths.L2FDI = [basePath, L2_tag, '/', dataId, '/'];
            %L2 catalogue
            paths.L2FDICatalogue = [basePath, L2_tag, '_Catalogue', '/', dataId, '/'];
            paths.L2FDISummaryImages = [basePath, L2_tag, '_Catalogue', '/', dataId, '/SummaryImages/'];
            paths.L2FDIKML = [basePath, L2_tag, '_Catalogue', '/', dataId, '/KML/'];
            paths.L2FDIKMZ = [basePath, L2_tag, '_Catalogue', '/', dataId, '/', MERRBySDataReader.DataIdWithDotSeparators(dataId), '.kmz'];
            paths.L2FDISearchTracks = [basePath, L2_tag, '_Catalogue', '/', dataId, '/SearchTracks/'];
        end
        
        function [ddmDataForTrack, ddmTrackInfo] = ReadL1BDDMFile(ddmsPath, metadata, trackIdList)
        %ReadL1BDDMFile Reads in the DDM file in NetCDF format
        %   Inputs:
        %     ddmsPath:   Path to ddms.nc file
        %     metadata:   Is the (optional) metadata structure to be
        %         used for consistency checking.
        %     tracksList: List of the tracks to read in
        %   Outputs:
        %     ddmDataForTrack: The ddm data - units are in UInt16 and still
        %             normalised. This is chosen to keep memory usage down
        %     ddmTrackInfo: The DDM scales

            ME = [];
            try
                % Open the netCDF metadata file
                ncid = netcdf.open(ddmsPath,'NC_NOWRITE');
                % List out the groups in the file. One group per track
                groupNcids = netcdf.inqGrps(ncid);

                % Read out all the attributes
                ddmData.attributes = MERRBySDataReader.ReadMetadataAttributes(ncid);

                % Check that the file matches that of the metadata file
                if exist('metadata', 'var')
                    if ddmData.attributes.FileIDCode ~= metadata.attributes.FileIDCode
                        error('DDMs.nc and metadata.nc files do not match');
                    end
                end

                if isempty(groupNcids)
                    error('DDM file empty');
                end

                %Initialise storage
                ddmDataForTrack = cell(1,length(trackIdList));
                outputIdx = 1;

                % The file is organised as each track is a separate group
                % Loop through all the tracks
                for trackId = trackIdList

                    groupIdx = trackId + 1;
                    if groupIdx > length(groupNcids)
                        error('Requested more tracks than found in DDM file');
                    end
                    %Check that the Track ID matches the index
                    groupName = str2double(netcdf.inqGrpName(groupNcids(groupIdx)));
                    if groupName ~= trackId
                        error('Error reading NetCDF: groupName not as expected');
                    end

                    % Read out the DDM's dimensions
                    varIdDelay = netcdf.inqVarID(groupNcids(groupIdx), 'Delay');
                    varIdDoppler = netcdf.inqVarID(groupNcids(groupIdx), 'Doppler');
                    varIdTime = netcdf.inqVarID(groupNcids(groupIdx), 'IntegrationMidPointTime');
                    ddmTrackInfo.delayScale = netcdf.getVar(groupNcids(groupIdx), varIdDelay, 'double');
                    ddmTrackInfo.dopplerScale = netcdf.getVar(groupNcids(groupIdx), varIdDoppler, 'double');
                    ddmTrackInfo.dateTimeScale = netcdf.getVar(groupNcids(groupIdx), varIdTime, 'double');

                    % Get the DDMs
                    varIdDDM = netcdf.inqVarID(groupNcids(groupIdx), 'DDM');
                    ddmDataForTrack{outputIdx} = netcdf.getVar(groupNcids(groupIdx), varIdDDM, 'uint16');

                    % Check that the data has the same dimensions and track names as
                    % the metadata
                    if exist('metadata', 'var')
                        [~, ~, ddmTrackLength] = size(ddmDataForTrack{outputIdx});
                        if ddmTrackLength ~= metadata.trackLength(groupIdx)
                            error('Number of DDMs in the track file does not match')
                        end

                        % Check that the DDM times are the same as the metadata
                        if ddmTrackInfo.dateTimeScale ~= metadata.trackVars{groupIdx}(:, metadata.trackVarNames.IntegrationMidPointTime)
                            error('DDM times do not match trackVars times');
                        end
                    end

                    outputIdx = outputIdx + 1;

                end

                netcdf.close(ncid);
            catch ME
            end
            %close the open resources
            if ~isempty(ME)
                netcdf.close(ncid);
                rethrow(ME);
            end
        end


        function [varNames, variables, varTypes] = ReadNetCDFVariables(ncidOfGroup, listOfVariables)
        %readNetCDFVariables Read in all variables from netCDF file then store in 2D array
        %   Call using [varIndexes, data] = readNetCDFVariables(ncidOfGroup, listOfVariables)
        %   where ncidOfGroup is the ncid number of the group to read from.
        %       Parameter: listOfVariables is an list of variable names to
        %       read. This is optional and can be {} to read all variables
        %   Outputs:
        %     'data' is a 2D matrix. Each row is a new time value. Each column
        %           is a separate variable
        %     'varIndexes' is a structure that can be used to access the
        %           columns of 'data'.   e.g. data(varIndexes.nameOfNetCDFVariable, :) will
        %           get the column for 'nameOfNetCDFVariable' and all rows
        %     'varTypes' data type of the original variable

            % Initialise results
            varNames = struct;
        
            % Read out the information from the NetCDF file
            [~, nvars, ~, ~] = netcdf.inq(ncidOfGroup);
            % Time variable is given by: unlimdimid

            % Determine the dimension that is valid for this group
            dimids = netcdf.inqDimIDs(ncidOfGroup, false);

            %Determine the length of the time dimension
            [~, dateTimeLength] = netcdf.inqDim(ncidOfGroup, dimids);

            %varTypesInt = zeros(1, nvars);
            constantNames{1} = 'NC_BYTE';
            constantNames{2} = 'NC_CHAR';
            constantNames{3} = 'NC_SHORT';
            constantNames{4} = 'NC_INT';
            constantNames{5} = 'NC_FLOAT';
            constantNames{6} = 'NC_DOUBLE';
            constantNames{7} = 'NC_UBYTE';
            constantNames{8} = 'NC_USHORT';
            constantNames{9} = 'NC_UINT';
            constantNames{10} = 'NC_INT64';
            constantNames{11} = 'NC_UINT64';
            constantNames{12} = 'NC_STRING';
            
            getAllVariables = false;
            if sum(strcmp(listOfVariables, 'all')) > 0
                getAllVariables = true;
            end
            
            % Loop through all variables and find matches
            matchingListOfVariables = [];
            for varIdx = 0:(nvars-1)
                % Get the name of the variable
                [variableName, ~] = netcdf.inqVar(ncidOfGroup,varIdx);
                % Check to see if this varible is needed
                if getAllVariables || sum(strcmp(listOfVariables, variableName))
                    matchingListOfVariables = [matchingListOfVariables, varIdx]; %#ok<AGROW>
                end
            end
            
            %Initialise the variable storage
            varTypes = cell(length(matchingListOfVariables), 1);
            variables = zeros(dateTimeLength, length(matchingListOfVariables));
            
            % Loop through all matching variables and read them in
            resultVarIdx = 1;
            for varIdx = matchingListOfVariables
                % Get the name of the variable
                [variableName, variableTypeInt] = netcdf.inqVar(ncidOfGroup,varIdx);
                % Check to see if this varible is needed
                if getAllVariables || sum(strcmp(listOfVariables, variableName))
                    % Store the name of the variable in a structure with the data index
                    varNames.(variableName) = resultVarIdx;
                    variableTypeAsString = constantNames(variableTypeInt);
                    varTypes{resultVarIdx} = variableTypeAsString{1};
                    % Read in the data
                    variables(:, resultVarIdx) = netcdf.getVar(ncidOfGroup, varIdx, 'double');
                    resultVarIdx = resultVarIdx + 1;
                end
            end

        end

        function [attributes] = ReadMetadataAttributes(ncid)
        %readMetaDataAttributes Reads out all the global attributes of the netCDF
        %                           file and returns them in a structure
        %   The resulting output is translated to a matlab structure, with 
        %    a field for each attribute.

            attributes = [];

            % Read out the information from the NetCDF file
            [~, ~, numglobalatts, ~] = netcdf.inq(ncid);

            for i = 0:(numglobalatts-1)

                % Get name of global attribute
                gattname = netcdf.inqAttName(ncid, netcdf.getConstant('NC_GLOBAL'),i);

                % Get value of global attribute.
                gattval = netcdf.getAtt(ncid, netcdf.getConstant('NC_GLOBAL'),gattname);

                % Store to a matlab structure
                typeInfo = whos('gattval');
                if strcmp(typeInfo.class, 'char') == 0
                    matval = double(gattval);
                else
                    matval = gattval;
                end
                attributes.(gattname) = matval;
            end

        end

        function [metadataMerged] = DuplicateReceiverDataIntoTracks(metadata)
        %DuplicateReceiverDataIntoTracks Match up the receiver data with
        %    the tracks
        %
        % This function goes through each track and adds the receiver
        % metadata fields as new columns. The receiverData and 
        % receiverDataByName fields are therefore removed.
        %
        % Inputs:
        %    metadata: The metadata structure returned by
        %                    MERRBySDataReader.ReadL1B
        % Outputs:
        %    metadataFlat: A structure with the elements:
        %       data        Matrix containing all the track data
        %       dataByName  The column names
        %       attributes The dataset attributes
        %       totalRows   The total length of the flattened dataset
            varNames = fieldnames(metadata.varNames);
            
            %Copy existing data across to output
            metadataMerged.trackVars = metadata.trackVars;
            metadataMerged.trackVarNames = metadata.trackVarNames;
            
            % Loop through each track and add the receiver metadata fields
            % as new columns
            for trackIdx = 1:metadata.numOfTracks
                % Add all the receiver meta data to the array
                % Index to the receiver data
                idxsRD = metadata.trackVars{trackIdx}(:, metadata.trackVarNames.ReceiverDataIdx);

                [~, receiverDataCols] = size(metadata.vars);
                [~, trackVarsCols] = size(metadata.trackVars{trackIdx});
                for i = 1:receiverDataCols
                    %Replicate data across into new column
                    trackVarsCols = trackVarsCols + 1;
                    metadataMerged.trackVars{trackIdx}(:, trackVarsCols) = ...
                            metadata.vars(idxsRD, i);
                    
                    %Get column name
                    columnName = varNames{i};
                    %Add to field names
                    metadataMerged.trackVarNames.(columnName) = trackVarsCols;
                end
            end
            
            % Copy across the remaining unchanged
            metadataMerged.attributes = metadata.attributes;
            metadataMerged.numOfTracks = metadata.numOfTracks;
            metadataMerged.trackLength = metadata.trackLength;
            metadataMerged.trackAttributes = metadata.trackAttributes;
            metadataMerged.trackVarColumns = trackVarsCols;
        end
        
        
        
        function [metadataFlat, ddmsFlat] = FlattenTracks(metadataMerged, ddmTracks)
        %FlattenTrackAttributes Flatten all the tracks together into one matrix
        %
        % This function unpacks the tracks into a single matrix. All the
        % header information that is the same for a whole track is
        % duplicated into every row of the matrix. The 'trackVars' cell
        % array is therefore replaced by a matrix 'data'.
        %
        % Inputs:
        %    metadata: The metadata structure returned by MERRBySDataReader.DuplicateReceiverDataIntoTracks
        %    ddms:  The cell array, with tracks of DDMs
        % Outputs:
        %    metadataFlat: A structure with the elements:
        %       data        Matrix containing all the track data
        %       dataByName  The column names
        %       attributes The dataset attributes
        %       totalRows   The total length of the flattened dataset
        %   ddmsFlat : A 3D matrix of the DDMs
        
            % Flatten the track data
            % Loop through each track and add each track header item as a new
            % column (duplicated across all rows in the track)
            totalRows = 0;
            for trackIdx = 1:metadataMerged.numOfTracks

                trackHeaderNames = fieldnames(metadataMerged.trackAttributes{trackIdx});

                %Loop through all the header fields
                %Initialise
                [trackVarsRows, trackVarsCols] = size(metadataMerged.trackVars{trackIdx});
                for i = 1:numel(trackHeaderNames)
                    %Get header name
                    headerName = trackHeaderNames{i};
                    %Get header value
                    headerVal = metadataMerged.trackAttributes{trackIdx}.(headerName);
                    
                    if ~isempty(headerVal) && ~ischar(headerVal)
                        %Replicate data across all of new column
                        trackVarsCols = trackVarsCols + 1;
                        metadataMerged.trackVars{trackIdx}(:, trackVarsCols) = headerVal;

                        %Add to field names
                        metadataMerged.trackVarNames.(headerName) = trackVarsCols;
                    end
                end
                
                totalRows = totalRows + trackVarsRows;
            end
            
            %Put all the tracks into one matrix
            %Initialise
            metadataFlat.data = zeros(totalRows, trackVarsCols);
            
            %Copy all tracks to one matrix
            currentRow = 1;
            for trackIdx = 1:metadataMerged.numOfTracks
                [trackVarsRows, ~] = size(metadataMerged.trackVars{trackIdx});
                metadataFlat.data(currentRow:(currentRow+trackVarsRows-1), :) = metadataMerged.trackVars{trackIdx};
                ddmsFlat(:,:,currentRow:(currentRow+trackVarsRows-1)) = ddmTracks(:,:,:);
                currentRow = currentRow + trackVarsRows;
            end
            
            %Store the names of the columns
            metadataFlat.trackVarNames = metadataMerged.trackVarNames;
            
            % Copy across the remaining unchanged
            metadataMerged.attributes = metadata.attributes;
            metadataMerged.trackLength = metadata.totalRows;
            metadataMerged.trackVarColumns = trackVarsCols;
        end
        
        function [metadataTrack] = ExtractTrack(metadata, trackIdx)
        %ExtractTrack Extract the specified track from the metadata
        %
        % This function selects the data from a single track and returns it
        % in the same structure as the input metadata.
        %
        % Inputs:
        %    metadata: The metadata structure returned by
        %                    MERRBySDataReader.ReadL1B or
        %                    MERRBySDataReader.DuplicateReceiverDataIntoTracks
        % Outputs:
        %    metadataTrack
            
            %Copy data across to output
            metadataTrack.trackVarNames = metadata.trackVarNames;
            metadataTrack.trackVars = metadata.trackVars{trackIdx};
            metadataTrack.attributes = metadata.attributes;
            metadataTrack.numOfTracks = length(trackIdx);
            metadataTrack.trackLength = metadata.trackLength(trackIdx);
            metadataTrack.trackAttributes = metadata.trackAttributes{trackIdx};
            metadataTrack.trackVarColumns = metadata.trackVarColumns;
        end
        
        function [metadataTrackFiltered, ddmDataTrackFiltered] = ApplyFilterToTrack(metadataTrack, ddmDataTrack, selectedDDMIdx)
        %ApplyFilterToTrack Selects data for the track
        % Returns the metadata and DDMs filtered by the logical array selectedDDMIdx
            
            %% Apply the available filters
            selectedDDMIdx = logical(selectedDDMIdx);

            %Copy data across to output for the selected DDMs
            metadataTrackFiltered.trackVarNames = metadataTrack.trackVarNames;
            metadataTrackFiltered.trackVars = metadataTrack.trackVars(selectedDDMIdx, :);
            metadataTrackFiltered.attributes = metadataTrack.attributes;
            metadataTrackFiltered.numOfTracks = 1;
            metadataTrackFiltered.trackLength = sum(selectedDDMIdx);
            metadataTrackFiltered.trackAttributes = metadataTrack.trackAttributes;
            metadataTrackFiltered.trackVarColumns = metadataTrack.trackVarColumns;

            if ~isempty(ddmDataTrack)
                ddmDataTrackFiltered = ddmDataTrack{1}(:,:,selectedDDMIdx);
            else
                ddmDataTrackFiltered = zeros(0,0,0);
            end 
            
        end
        
    end % methods
end % classdef


