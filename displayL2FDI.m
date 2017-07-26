function displayL2FDI(startDateTimeString, stopDateTimeString, basePath)
%displayL2FDI Function to display L2 data over a date time range
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
% Inputs:
% startDateTimeString: Format yyyyMMddTHH:mm:ss.FFF  Hours from:[03, 09, 15, 21]
% stopDateTimeString: Format yyyyMMddTHH:mm:ss.FFF Hours from:[03, 09, 15, 21]
% basePath: location of the MERRByS data

    %Add required paths
    if ~isdeployed
        addpath('include');
        addpath('include/Map');
        addpath('include/m_map');
        addpath('include/Plotting');
        addpath('include/Utils');
    end

    %%Debug - if no inputs are given use these defaults
    if ~exist('startDateTimeString', 'var')
        startDateTimeString = '20160909T21:00:00'; % Format yyyyMMddTHH:mm:ss.FFF
        stopDateTimeString =  '20161010T03:00:00'; % Format yyyyMMddTHH:mm:ss.FFF
        %basePath = 'C:\aaLIVE_c\temp\';
        basePath = 'Q:/DataOutputPrerelease0p7_test/';
    end

    %% Parse inputs - Running from command line so inputs are strings
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
    
    %Ensure trailing '/' on path
    basePath = MERRBySDataReader.EnsureFolderHasFinalSlash(basePath);
    
    dataIdList = MERRBySDataReader.GetListOfDataInRange(startDateTime, stopDateTime, segmentationTimeHours);
    
    IntegrationMidPointTime = [];
    SpecularPointLat = [];
    SpecularPointLon = [];
    WindSpeed = [];
    PRN = [];
    SVN = [];
    FrontEnd = [];
    FrontEndGainMode = [];
    SPIncidenceAngle = [];
    AntennaGainTowardsSpecularPoint = [];
    
    progressBar = TextProgressBar;
    progressBar.DrawBackground();
    
    for dataIdListIdx = 1:length(dataIdList)
        %% Setup to process this dataId
        dataId = dataIdList{dataIdListIdx};
        
        paths = MERRBySDataReader.GetPaths(basePath, dataId, '');
        netCDFFileName = [paths.L2FDI, 'L2_FDI.nc'];
        
        if exist(netCDFFileName, 'file')
            IntegrationMidPointTime = [IntegrationMidPointTime; ncread(netCDFFileName, 'IntegrationMidPointTime')];
            SpecularPointLat = [SpecularPointLat; ncread(netCDFFileName, 'SpecularPointLat')];
            SpecularPointLon = [SpecularPointLon; ncread(netCDFFileName, 'SpecularPointLon')];

            WindSpeed = [WindSpeed; ncread(netCDFFileName, 'WindSpeed')];
            PRN = [PRN; ncread(netCDFFileName, 'PRN')];
            SVN = [SVN; ncread(netCDFFileName, 'SVN')];
            FrontEnd = [FrontEnd; ncread(netCDFFileName, 'FrontEnd')];
            FrontEndGainMode = [FrontEndGainMode; ncread(netCDFFileName, 'FrontEndGainMode')];
            SPIncidenceAngle = [SPIncidenceAngle; ncread(netCDFFileName, 'SPIncidenceAngle')];
            AntennaGainTowardsSpecularPoint = [AntennaGainTowardsSpecularPoint; ncread(netCDFFileName, 'AntennaGainTowardsSpecularPoint')];
        end
        
        progressBar.Update(dataIdListIdx / length(dataIdList));
    end
    
    fprintf('\n');
    if isempty(IntegrationMidPointTime)
        fprintf('No data found. Check data exists in %s\n\n', paths.L2FDI);
        return;
    end
    
    fprintf('Plotting\n');
    
    %% Plot over time
    if 0
        plot((IntegrationMidPointTime - IntegrationMidPointTime(1)) * 24*60*60, WindSpeed);
        xlabel('Time from start of file (s)');
        ylabel('WindSpeed m/s');
        grid on;
    end
    
    %% Display on map
    figHandle = sfigure('Visible', 'on');
    
    %Set up the map
    m_proj('Miller Cylindrical','lat',[-90 90]);
    [xLim yLim] = m_ll2xy(180,90);
    pixelFactor = 16;
    obj.dataMap.sizeLon = 25 * pixelFactor;
    obj.dataMap.xLim = xLim;
    obj.dataMap.offsetLon = obj.dataMap.sizeLon / 2;
    obj.dataMap.scaleLon = linspace(-xLim, xLim, obj.dataMap.sizeLon);
    obj.dataMap.sizeLat = 25 * pixelFactor;
    obj.dataMap.yLim = yLim;
    obj.dataMap.offsetLat = obj.dataMap.sizeLat / 2;
    obj.dataMap.scaleLat = linspace(-yLim, yLim, obj.dataMap.sizeLat);
    obj.dataMap.accum = zeros(obj.dataMap.sizeLon * obj.dataMap.sizeLat, 1);
    obj.dataMap.count = zeros(obj.dataMap.sizeLon * obj.dataMap.sizeLat, 1);
    
    vals = WindSpeed;
    
    % Scale coordinates to map projection
    [x, y] = m_ll2xy(SpecularPointLon, SpecularPointLat, 'clip', 'on');
    xScaled = round(x / obj.dataMap.xLim * obj.dataMap.sizeLon/2 + obj.dataMap.offsetLon);
    yScaled = round(y / obj.dataMap.yLim * obj.dataMap.sizeLat/2 + obj.dataMap.offsetLat);
    linearisedLocation = xScaled + obj.dataMap.sizeLon * yScaled;
    %Saturate the rounding
    linearisedLocation(linearisedLocation > length(obj.dataMap.accum)) = length(obj.dataMap.accum);
    %Average across duplicates
    uniqueLocations = unique(linearisedLocation);
    for i = 1:length(uniqueLocations)
        location = uniqueLocations(i);
        addCount = sum(linearisedLocation == location, 'omitnan');
        addValue = sum(vals(linearisedLocation == location, 'omitnan'));
        % Add to the running average map
        obj.dataMap.accum(location) = obj.dataMap.accum(location) + addValue;
        obj.dataMap.count(location) = obj.dataMap.count(location) + addCount;
    end
    %Plot the map
    dataMap2D = reshape(obj.dataMap.accum ./ obj.dataMap.count, obj.dataMap.sizeLon, obj.dataMap.sizeLat)';    
    alphaMap = isfinite(dataMap2D);
    imagesc(obj.dataMap.scaleLon, obj.dataMap.scaleLat, dataMap2D, 'AlphaData', alphaMap);
    colormap('jet');
    hcb = colorbar;
    set(gca,'ydir','normal');
    m_coast('Color', 'k');
    ylabel(hcb, 'Wind speed (m/s)');
    m_grid();
    clim = [0 25];
    set(gca,'CLim',clim);
    
    fprintf('Done\n');
end
