function processMERRBySLevel1bBasic(startDateTimeString, stopDateTimeString, basePath, settings, processingTask, filterFunction, filterVariables)
% processMERRBySL1b Processes MERRByS Level1b data
% Inputs
%   # startDateTimeString
%           - Start time for analysing the data. Format: yyyyMMddTHH:mm:ss
%   # stopDateTimeString
%           - Stop time for analysing the data. Format: yyyyMMddTHH:mm:ss
%   # basePath
%           - Folder location of the MERRByS data
%   # processingFunction
%           - A function handle to the function that should be run on each
%           track of MERRByS L1b data
%   # filterFunction
%           - A function to filter the DDMs
%   # filterVariables
%           - A cell array list of strings specifying each of the variables
%           needed to be read in for the filterFunction
%
%  Documentation for the data can be found at:
%    http://www.merrbys.co.uk:8080/CatalogueData/Documents/MERRByS%20Product%20Manual%20V3.pdf
%
%   Start and stop times must be on the MERRByS segmentation boundaries of
%   UTC times: 21:00, 03:00, 09:00, 15:00
%
%   Example:
%   processMERRBySLevel1bBasic('20170217T21:00:00', '20170218T03:00:00',
%   'c:/merrbysData/', ProcessingTaskHistogramAntennaGainvsSNR)
%       - This will process the data for 3 hours eith side of the mid-point
%       time (2017 02 18 T 00:00:00). The data files used will be located
%       within the c:/merrbysData/ folder according to the collection time
%       at c:/merrbysData/L1B/2017-02/18/H00
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

    %% Parse inputs - date/time inputs are strings
    try
        startDateTime = MERRBySDataReader.ParseDateTimeString(startDateTimeString);
    catch
        error(['Could not parse startDateTime: ''' startDateTimeString, '''']);
    end
    try
        stopDateTime = MERRBySDataReader.ParseDateTimeString(stopDateTimeString);
    catch
        error(['Could not parse stopDateTime: ''', stopDateTimeString, '''']);
    end
    %Data is segmented into 6 hour duration windows
    segmentationTimeHours = 6;
    
    dataIdList = MERRBySDataReader.GetListOfDataInRange(startDateTime, stopDateTime, segmentationTimeHours);
    if isempty(dataIdList)
        error(['No data within time range: ', datestr(startDateTime), ' - ', datestr(stopDateTime)]);
    end
    
    %Ensure trailing '/' on path
    basePath = MERRBySDataReader.EnsureFolderHasFinalSlash(basePath);
    L1B_tag = 'L1B';
    
    
    
    progressBar = TextProgressBar;
        
    %% Load anything needed into settings - this gets passed to the processing function
    settings.basePath = basePath;

    %Initialise the processing task
    processingTask = processingTask.Initialise(settings);
    
    %% Decide what should be read from the NetCDF
    varNamesToLoad = processingTask.VarNamesRequired();
    if exist('filterVariables', 'var')
        varNamesToLoad = [varNamesToLoad, filterVariables];
    end
    loadDDMFrames = processingTask.NeedToLoadDDMs();
    if loadDDMFrames
        fprintf('Will load DDM frames\n');
    end
    
    %% Loop through selected data
    for dataIdListIdx = 1:length(dataIdList)
        %% Setup to process this dataId
        dataId = dataIdList{dataIdListIdx};
        paths = MERRBySDataReader.GetPaths(basePath, dataId, L1B_tag);
        
        try
            % Load the metadata file
            fprintf('Fetching metadata for %s.\n',dataId);
            if exist(paths.metadata, 'file')
                metadata = MERRBySDataReader.ReadL1B(paths.metadata, '', false, varNamesToLoad);
                metadata = MERRBySDataReader.DuplicateReceiverDataIntoTracks(metadata);
            else
                fprintf(['  No file for ', dataId, '  Skipping\n']);
                continue;
            end
            
            if isempty(metadata.trackVars)
                fprintf('  Could not locate any reflection tracks.\n')
                continue;
            end

            fprintf('  Processing %d tracks\n', metadata.numOfTracks);
            
            progressBar.DrawBackground();
           
            % Loop through all tracks
            for trackIdx = 1:metadata.numOfTracks
                %Extract the data for this track
                [metadataTrack] = MERRBySDataReader.ExtractTrack(metadata, trackIdx);
                %Add distance to coast to the data
                metadataTrack = appendDataDistanceToLand(metadataTrack, settings.validationData);
                
                %Filter by metadata - This allows us to load only the required tracks
                if exist('filterFunction', 'var')
                    metadataTrackFiltered = filterFunction(metadataTrack, {}, processingTask.filterSettings, settings);
                else
                    metadataTrackFiltered = metadataTrack;
                end
                
                %Load the DDMs only if requested
                ddmDataTrack = [];
                if metadataTrackFiltered.trackLength > 0
                    if loadDDMFrames
                        fprintf('Fetching DDMs for %s : %d.\n', dataId, trackIdx);
                        if exist(paths.metadata, 'file')
                            ddmDataTrack = MERRBySDataReader.ReadL1BDDMFile(paths.ddms, metadata, trackIdx - 1); %Reads one track only
                        else
                            fprintf(['  No file for ', dataId, '  Skipping\n']);
                        end
                    end
                end
                
                %Refilter to additionally filter the DDMs
                if exist('filterFunction', 'var')
                    [metadataTrackFiltered, ddmDataTrackFiltered] = filterFunction(metadataTrack, ddmDataTrack, processingTask.filterSettings, settings);
                else
                    metadataTrackFiltered = metadataTrack;
                    ddmDataTrackFiltered = ddmDataTrack;
                end
                
                % Run the processing function on the track
                processingTaskTrackResults(trackIdx) = processingTask.ProcessTrack(metadataTrackFiltered, ddmDataTrackFiltered);
               
                progressBar.Update(trackIdx / metadata.numOfTracks);
            end
            
            %Combine the data for each track
            % Initialising task for dataId
            processingTasksDataSetArray(dataIdListIdx) = processingTask; % New object
            processingTasksDataSetArray(dataIdListIdx) = processingTasksDataSetArray(dataIdListIdx).InitialiseDataId(metadata);
            for trackIdx = 1:metadata.numOfTracks
                processingTasksDataSetArray(dataIdListIdx) = processingTaskTrackResults(trackIdx).Reduce(processingTasksDataSetArray(dataIdListIdx));
            end

        catch e
            disp(['Error on dataId ', dataId]);
            try
                disp(['Exception: ' e.message])
                for idx = 1:length(e.stack)
                    disp(['File: ' e.stack(idx).file])
                    disp(['Name: ' e.stack(idx).name])
                    disp(sprintf('Line: %d', e.stack(idx).line)) %#ok<DSPS>
                end
            catch
            end
        end
        disp(' ');

    end % for dataIdList


    %% Reduce the data to combine all datasets
    % Prepare for doing the reduce - initialise object to reduce into
    processingTasksReduced = processingTask; % New object
    fprintf('Reducing DataIds.\n');
    for resultIdx = 1:length(processingTasksDataSetArray)
        processingTasksReduced = processingTasksDataSetArray(resultIdx).Reduce(processingTasksReduced);
    end
    
    %% Complete the data - this is where any plots or summary graphs are used
    fprintf('Running Task Completion.\n');
    if ~isempty(processingTasksReduced)
        processingTasksReduced = processingTasksReduced.Complete();
    end
