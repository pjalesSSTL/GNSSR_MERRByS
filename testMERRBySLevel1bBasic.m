function testMERRBySLevel1bBasic
%Test the processMERRBySLevel1bBasic function
% This processes the MERRByS Level 1b data and plots the result.
% The example uses the matlab class 'ProcessingTaskHistogramExample' to
% process and combine the data. It is filtered using 'dataFilter'.
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

    %Setup paths ------
    if ~isdeployed
        addpath('include');
        addpath('include/ProcessingTasksCore');
        addpath('include/Plotting');
        addpath('include/Utils');
    end

    %Setup constants ------
    % The base path is the location for searching for the MERRByS data. It
    % is assume the FTP server structure is replicated with data
    % stored in #basePath#/L1B/yyyy-MM/dd/Hhh/....
    basePath = 'Q:/DataOutputPrerelease0p7_test/';

    %The start and end time of the data to processs.
    %The data is segmented into 6 hour files at 03, 09, 15, 21 hours.
    %The length of time to process can be made up of any number of segments
    startDateTimeString = '20170217T21:00:00'; % Format yyyyMMddTHH:mm:ss.FFF
    stopDateTimeString =  '20170218T21:00:00'; % Format yyyyMMddTHH:mm:ss.FFF

    %Setup the processing task - Creates the processing object
    % This is a class inheriting from ProcessingTask
    processingTask = ProcessingTaskHistogramExample;
    
    %Pass in the filtering function
    filterFunction = @dataFilter;
    % List any variables needed by the filter function
    filterVariables = {'DirectSignalInDDM'};
    
    %Add any additional data ---------
    % This is passed into the processing functions through the settings structure
    
    %Land distance map - is added automatically using 'appendDataDistanceToLand' function
    settings.landDistanceMapFileName = '.\include\distToCoastMap\landDistGrid_0.10LLRes_hGSHHSres.mat';
    fprintf('Loading coastal distance map. ');
    landDistGrid = load(settings.landDistanceMapFileName);
    settings.validationData.landDistGrid = landDistGrid.landDistGrid;
    fprintf('Done\n');

    %Run the processing --------------
    processMERRBySLevel1bBasic(startDateTimeString, stopDateTimeString, basePath, settings, processingTask, filterFunction, filterVariables);
    
end


function [ metadataTrackFiltered, ddmDataTrackFiltered ] = dataFilter(metadataTrack, ddmDataTrack, filterSettings, settings)
%dataFilter Example filter function for the L1b tracks
%  Inputs: metadataTrack, ddmDataTrack: from MERRBySDataReader.ReadL1B then MERRBySDataReader.DuplicateReceiverDataIntoTracks
%          filterSettings: 
    
    [trackLength, ~] = size(metadataTrack.trackVars);
    
    % Each filter ANDs with this initialisation
    selectedDDMIdx = logical(true(metadataTrack.trackLength, 1));

    %%    Construct the filters
    % Remove DDMs corrupted by direct signals
    directSignalInDDM = metadataTrack.trackVars(:, metadataTrack.trackVarNames.DirectSignalInDDM);
    selectedDDMIdx = selectedDDMIdx & logical(directSignalInDDM == 0);
    
    % Filter to ocean only
    thresholdLandDistance = 10; % threshold distance in km from land
    % Grid is NaN over land
    for ddmIdx = 1:trackLength
        landDist = metadataTrack.trackVars(:, metadataTrack.trackVarNames.LandDist);
        selectedDDMIdx(ddmIdx) = selectedDDMIdx(ddmIdx) && logical(landDist(ddmIdx) > thresholdLandDistance);
    end
    
    %% Apply the filter
    [ metadataTrackFiltered, ddmDataTrackFiltered ] = MERRBySDataReader.ApplyFilterToTrack(metadataTrack, ddmDataTrack, selectedDDMIdx);
    
end