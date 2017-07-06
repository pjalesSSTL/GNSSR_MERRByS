function metadataTrackOut = appendDataDistanceToLand(metadataTrack, validationData)
%appendDataDistanceToLand - Add to metadata the distance to the coast

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

    spLon = metadataTrack.trackVars(:, metadataTrack.trackVarNames.SpecularPointLon);
    spLat = metadataTrack.trackVars(:, metadataTrack.trackVarNames.SpecularPointLat);

    landDistGridLats = validationData.landDistGrid.lats;
    landDistGridLons = validationData.landDistGrid.lons;
    landDistGridArray = validationData.landDistGrid.array;

    % Grid is NaN over land
    landDist = nan(size(spLon));
    for ddmIdx = 1:metadataTrack.trackLength
        latIdx = find(landDistGridLats >= spLat(ddmIdx), 1);
        lonIdx = find(landDistGridLons >= spLon(ddmIdx), 1);
        if isempty(latIdx) %Lat Grid does not work below -89 degrees latitude
            latIdx = 1;
        end
        
        landDist(ddmIdx) = landDistGridArray(latIdx, lonIdx);
    end

    %Append data
    metadataTrackOut = metadataTrack;
    
    %Set up the new variable name
    metadataTrackOut.trackVarColumns = metadataTrack.trackVarColumns + 1;
    metadataTrackOut.trackVarNames.LandDist = metadataTrackOut.trackVarColumns;
    %Append the data
    metadataTrackOut.trackVars(:, metadataTrackOut.trackVarNames.LandDist) = landDist;