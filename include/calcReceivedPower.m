function peakReceivedPower_dB = calcReceivedPower(metadata)
% calcReceivedPowerSNR Calculate the received signal power at the output
% from SNR corrected by antenna noise temperature - use metadata directly

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

    ddmPeak = metadata.trackVars(:, metadata.trackVarNames.DDMOutputNumericalScaling);
    noiseEstimate = metadata.trackVars(:, metadata.trackVarNames.MeanNoiseBox);
    systemGainBB_dB = metadata.trackVars(:, metadata.trackVarNames.SystemGainBB) + metadata.trackVars(:, metadata.trackVarNames.SystemGainBBComp);
    systemGainExtRef_dB = metadata.trackVars(:, metadata.trackVarNames.SystemGainExtRef) + metadata.trackVars(:, metadata.trackVarNames.SystemGainExtRefComp);
    systemGainLin = zeros(size(systemGainBB_dB));
    for idx = 1:metadata.trackLength
        if metadata.trackVars(idx, metadata.trackVarNames.ReferenceType) == 1 %Blackbody
            systemGainLin(idx) = 10.^(systemGainBB_dB(idx) / 10);
        elseif metadata.trackVars(idx, metadata.trackVarNames.ReferenceType) == 2 %ExtRef
            systemGainLin(idx) = 10.^(systemGainExtRef_dB(idx) / 10);
        elseif metadata.trackVars(:, metadata.trackVarNames.ReferenceType) == 3 %Both available
            systemGainLin(idx) = 10.^(systemGainBB_dB(idx) / 10);
        else
            systemGainLin(idx) = nan;
        end
    end
    inputCableGainLin = 10.^(-0.6/10);

    peakReceivedPowerLin = calcReceivedPowerSMN(ddmPeak, noiseEstimate, systemGainLin, inputCableGainLin);
    peakReceivedPower_dB = 10*log10(peakReceivedPowerLin); %dBW