%inspectNetCDF Example script that reads out the structure of the NetCDF
%files for MERRByS
%
% Data documentation for the data can be found at:
%    http://www.merrbys.co.uk:8080/CatalogueData/Documents/MERRByS%20Product%20Manual%20V3.pdf
%
%   Tested on Matlab 2016a MS. Windows
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

%Configuration of the file to read
fprintf('Displaying user dialog to select NetCDF file to inspect\n');
[~,filePath,~] = uigetfile('*.nc', 'MERRByS L1b data');

%The script looks for all the MERRByS Level 1b files
fileNameMetaData = [filePath 'metadata.nc'];
fileNameDDMs = [filePath 'ddms.nc'];
fileNameBlackbodyNadir = [filePath 'blackbodyNadir.nc'];
fileNameBlackbodyZenith = [filePath 'blackbodyZenith.nc'];
fileNameDirectSignalPower = [filePath 'directSignalPower.nc'];

disp('  Inspecting NetCDF Structure')

%% Display the structure of the NetCDF files: L1b Metadata
disp('------- Metadata file structure --------')
fprintf('Reading file: %s\n', fileNameMetaData);
if exist(fileNameMetaData, 'file')
    ncinfoMetadata = ncinfo(fileNameMetaData);

    fprintf('  Attributes-------------------:\n');
    for i = 1:length(ncinfoMetadata.Attributes)
        fprintf('      %26s: %s\n', ncinfoMetadata.Attributes(i).Name, ncinfoMetadata.Attributes(i).Value);
    end

    fprintf('  Dimensions-------------------:\n');
    fprintf('      %s\n', ncinfoMetadata.Dimensions.Name);

    fprintf('  Variables-------------------:\n');
    fprintf('      %36s| %s\n', 'Variable Name', 'Units');
    fprintf('                                       ------\n');
    for i = 1:length(ncinfoMetadata.Variables)
        if length(ncinfoMetadata.Variables(i).Attributes) > 1
            fprintf('      %36s| %s\n', ncinfoMetadata.Variables(i).Name, ncinfoMetadata.Variables(i).Attributes(2).Value);
        else
            fprintf('      %36s|\n', ncinfoMetadata.Variables(i).Name);
        end
    end

    fprintf('  Number of tracks-------------------: %d\n', length(ncinfoMetadata.Groups));

    fprintf('  Track Attributes-------------------:\n');
    fprintf('      %s\n', ncinfoMetadata.Groups(1).Attributes.Name);

    fprintf('  Track Variables-------------------:\n');
    fprintf('      %26s| %s\n', 'Variable Name', 'Units');
    fprintf('                              ------\n');
    for i = 1:length(ncinfoMetadata.Groups(1).Variables)
        if length(ncinfoMetadata.Groups(1).Variables(i).Attributes) > 1
            fprintf('      %26s| %s\n', ncinfoMetadata.Groups(1).Variables(i).Name, ncinfoMetadata.Groups(1).Variables(i).Attributes(2).Value);
        else
            fprintf('      %26s|\n', ncinfoMetadata.Variables(i).Name);
        end
    end
else
    fprintf('File not found %s\n', fileNameMetaData);
end

%% Display the structure of the NetCDF files: L1b DDMs
disp('------- DDM file structure --------')
fprintf('Reading file: %s\n', fileNameDDMs);
if exist(fileNameDDMs, 'file')
    ncinfoDDMs = ncinfo(fileNameDDMs);
    fprintf('  Attributes-------------------:\n');
    for i = 1:length(ncinfoDDMs.Attributes)
        fprintf('      %26s: %s\n', ncinfoDDMs.Attributes(i).Name, ncinfoDDMs.Attributes(i).Value);
    end

    fprintf('  Number of tracks-------------------: %d\n', length(ncinfoDDMs.Groups));
    ncinfoDDMs = ncinfo(fileNameDDMs);

    fprintf('  Track Dimensions-------------------:\n');
    fprintf('      %s\n', ncinfoDDMs.Groups(1).Dimensions.Name);

    fprintf('  Track Variables-------------------:\n');
    fprintf('      %s\n', ncinfoDDMs.Groups(1).Variables.Name);
else
    fprintf('File not found %s\n', fileNameDDMs);
end

%% Display the structure of the NetCDF files: L1b Blackbody Nadir
disp('------- Blackbody Nadir file structure --------')
fprintf('Reading file: %s\n', fileNameBlackbodyNadir);
if exist(fileNameBlackbodyNadir, 'file')
    ncinfoBlackbodyNadir = ncinfo(fileNameBlackbodyNadir);

    fprintf('  Attributes-------------------:\n');
    for i = 1:length(ncinfoBlackbodyNadir.Attributes)
        fprintf('      %26s: %s\n', ncinfoBlackbodyNadir.Attributes(i).Name, ncinfoBlackbodyNadir.Attributes(i).Value);
    end

    fprintf('  Dimensions-------------------:\n');
    fprintf('      %s\n', ncinfoBlackbodyNadir.Dimensions.Name);

    fprintf('  Variables-------------------:\n');
    for i = 1:length(ncinfoBlackbodyNadir.Variables)
        fprintf('<%s>, ', ncinfoBlackbodyNadir.Variables(i).Name);
    end    
else
    fprintf('File not found %s\n', fileNameBlackbodyNadir);
end

%% Display the structure of the NetCDF files: L1b Blackbody Zenith
disp('------- Blackbody Zenith file structure --------')
fprintf('Reading file: %s\n', fileNameBlackbodyZenith);
if exist(fileNameBlackbodyZenith, 'file')
    ncinfoBlackbodyZenith = ncinfo(fileNameBlackbodyZenith);

    fprintf('  Attributes-------------------:\n');
    for i = 1:length(ncinfoBlackbodyZenith.Attributes)
        fprintf('      %26s: %s\n', ncinfoBlackbodyZenith.Attributes(i).Name, ncinfoBlackbodyZenith.Attributes(i).Value);
    end

    fprintf('  Dimensions-------------------:\n');
    fprintf('      %s\n', ncinfoBlackbodyZenith.Dimensions.Name);

    fprintf('  Variables-------------------:\n');
    for i = 1:length(ncinfoBlackbodyZenith.Variables)
        if length(ncinfoBlackbodyZenith.Variables(i).Attributes) > 1
            fprintf('      %26s| %s\n', ncinfoBlackbodyZenith.Variables(i).Name, ncinfoBlackbodyZenith.Variables(i).Attributes(2).Value);
        else
            fprintf('      %26s|\n', ncinfoBlackbodyZenith.Variables(i).Name);
        end
    end    
else
    fprintf('File not found %s\n', fileNameBlackbodyZenith);
end

%% Display the structure of the NetCDF files: L1b DirectSignal
disp('------- DirectSignalAnalysis file structure --------')
fprintf('Reading file: %s\n', fileNameDirectSignalPower);
if exist(fileNameDirectSignalPower, 'file')
    ncinfoDirectSignalPower = ncinfo(fileNameDirectSignalPower);

    fprintf('  Attributes-------------------:\n');
    for i = 1:length(ncinfoDirectSignalPower.Attributes)
        fprintf('      %26s: %s\n', ncinfoDirectSignalPower.Attributes(i).Name, ncinfoDirectSignalPower.Attributes(i).Value);
    end

    fprintf('  Dimensions-------------------:\n');
    fprintf('      %s\n', ncinfoDirectSignalPower.Dimensions.Name);

    fprintf('  Variables-------------------:\n');
    for i = 1:length(ncinfoDirectSignalPower.Variables)
        fprintf('<%s>, ', ncinfoDirectSignalPower.Variables(i).Name);
    end
else
    fprintf('File not found %s\n', fileNameDirectSignalPower);
end
