function downloadData(startDateTimeString, stopDateTimeString, dataTypesToDownload, destinationBasePath, username, password)
%downloadData L1bDownload Matlab script to download L1b or L2 data from the MERRByS server
%
% startDateTimeString: Format yyyyMMddTHH:mm:ss.FFF Hours from:[03, 09, 15, 21]
% stopDateTimeString: Format yyyyMMddTHH:mm:ss.FFF Hours from:[03, 09, 15, 21]
% dataTypesToDownload: Cell array {'L1B', 'L2_FDI'}
% destinationBasePath: path to local destination
% username, pasword: FTP server credentials

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

    %Add required paths
    if ~isdeployed
        addpath('include');
        addpath('include/Utils');
    end
    
    %% Configuration
    % Parse inputs - Running from command line so inputs are strings
    try
        startDateTime = MERRBySDataReader.ParseDateTimeString(startDateTimeString);
    catch
        error(['Could not parse startDateTime: ' startDateTimeString]);
    end
    try
        stopDateTime = MERRBySDataReader.ParseDateTimeString(stopDateTimeString);
    catch
        error(['Could not parse stopDateTime: ' stopDateTimeString]);
    end
    segmentationTimeHours = 6;
    
    %Server address
    serverAddress = 'ftp.merrbys.co.uk';
    %Ensure trailing '/' on path
    destinationBasePath = MERRBySDataReader.EnsureFolderHasFinalSlash(destinationBasePath);
    
    %Get list of data to download
    dataIdList = MERRBySDataReader.GetListOfDataInRange(startDateTime, stopDateTime, segmentationTimeHours);
        
    %Create local directories
    if ~exist(destinationBasePath, 'dir')
        mkdir(destinationBasePath)
    end
    
    %Connect to FTP server
    fprintf('Connecting to %s\n', serverAddress);
    ftpobj = ftp(serverAddress, username, password);
    %Enter passive mode: Matlab workaround when FTP from behind firewall
    cd(ftpobj);  sf=struct(ftpobj);  sf.jobject.enterLocalPassiveMode();
    
    %% Download requested data L1b
    if sum(strcmp(dataTypesToDownload, 'L1B'))
        for dataIdListIdx = 1:length(dataIdList)
            %% Setup to process this dataId
            dataId = dataIdList{dataIdListIdx};
            fprintf('Getting L1B: %s\n', dataId);
            
            localPath = [destinationBasePath, 'L1B/', dataId, '/'];
            %Create local directories
            if ~exist(localPath, 'dir')
                mkdir(localPath)
            end

            % Files to download
            files = {'metadata.nc', 'ddms.nc', 'directSignalPower.nc', 'blackbodyNadir.nc', 'blackbodyZenith.nc'};
            for fileIdx = 1:length(files)
                fileName = files{fileIdx};
                
                urlFolder = ['/Data/L1B/', dataId, '/'];
                try
                    cd(ftpobj, urlFolder);
                    mget(ftpobj, fileName, localPath);
                catch
                    fprintf('No data available for %s\n', url);
                end
            end
            
            fprintf('  Done\n');
        end
    end
    
    %% Download requested data L2_FDI
    if sum(strcmp(dataTypesToDownload, 'L2_FDI'))
        for dataIdListIdx = 1:length(dataIdList)
            %% Setup to process this dataId
            dataId = dataIdList{dataIdListIdx};
            fprintf('Getting L2_FDI: %s\n', dataId);
            
            localPath = [destinationBasePath, 'L2_FDI/', dataId, '/'];
            %Create local directories
            if ~exist(localPath, 'dir')
                mkdir(localPath)
            end

            % Files to download
            files = {'L2_FDI.nc'};
            for fileIdx = 1:length(files)
                fileName = files{fileIdx};
                
                urlFolder = ['/Data/L2_FDI/', dataId, '/'];
                try
                    cd(ftpobj, urlFolder);
                    mget(ftpobj, fileName, localPath);
                catch
                    fprintf('    Nothing for %s\n', url);
                end
            end
            
            fprintf('  Done\n');
        end
    end
    
    %Close connection to the FTP server
    close(ftpobj);
end
