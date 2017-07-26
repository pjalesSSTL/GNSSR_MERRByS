function receivedPower = calcReceivedPowerSMN(ddmPixel, noiseEstimate, systemGain, inputCableGainLin)
% calcReceivedPowerSNR Calculate the received signal power at the output
% from SNR corrected by antenna noise temperature

% Parameters:
%    - ddmPixel [counts]
%    - noiseEstimate [counts]
%    - systemGain [Counts / Watt]
%    - inputCableLossLin [unit-less]

    k = 1.38064852e-23; % Boltzmann constant m2 kg s-2 K-1
    
    implementationLossSignal = 1;
    
    receivedPower = (ddmPixel - noiseEstimate) ...
                        ./ systemGain ...
                        ./ implementationLossSignal ...
                        ./ inputCableGainLin;
