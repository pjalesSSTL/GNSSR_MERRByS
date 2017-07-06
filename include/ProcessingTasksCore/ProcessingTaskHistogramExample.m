classdef ProcessingTaskHistogramExample < ProcessingTask
%ProcessingTaskHistogramExample plots 2D histogram of AntennaGain vs SNR
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

    properties
        % From base class
        settings
        filterSettings
        processingType
        netCDFNeedsSaving = false
        processed = false
        % Context for this Task
        context
        figureHandles
    end
    
    methods
        function varNames = VarNamesRequired(obj)
        %VarNamesRequired returns what data should be loaded in
            varNames = {'DDMSNRAtPeakSingleDDM', 'AntennaGainTowardsSpecularPoint'};
        end
        
        function boolOut = NeedToLoadDDMs(obj)
        %NeedToLoadDDMs returns whether DDMs need to be loaded
            boolOut = false;
        end
        
        function obj = Initialise(obj, settings)
        %Initialise() Function to initalise the variables

            obj.settings = settings;
            
            % Initialise histogram settings
            obj.context.xBins = -12:0.2:15;
            obj.context.yBins = -10:0.2:12;
            obj.context.counts = zeros(length(obj.context.yBins) - 1, length(obj.context.xBins) - 1);
        end

        function obj = InitialiseDataId(obj, metadata)
        %InitialiseDataId(obj, metadata) %Initialisation function
        %- run at start of dataId
            %Not needed for this task
        end
        
        function obj = ProcessTrack(obj, metadata, ddmDataTrack)
        %ProcessTrack(obj, metadata, ddmDataTrack)
        % Function to process a track - Adds data to histogram based on processing type

            %Get data
            valsY =  metadata.trackVars(:, metadata.trackVarNames.DDMSNRAtPeakSingleDDM);
            valsX =  metadata.trackVars(:, metadata.trackVarNames.AntennaGainTowardsSpecularPoint);

            %% Add to 2D histogram
            if ~isempty(valsX) && ~isempty(valsY)
                a = hist2d([valsY, valsX], obj.context.yBins, obj.context.xBins);
                obj.context.counts = obj.context.counts + a;
            end
            
            obj.processed = true;
        end
        
        
        function objOut = Reduce(obj1, objReduced)
        %Reduce(obj1, objReduced)
            %Reduce Combine / collate the results into objOut
            % Initialise the output which will have obj1 and obj2 combined into it
            % Obj1 is the next processed data - obj2 is the reduced / combined data
            
            %Initialisation of the reduced object
            if ~objReduced.processed
                objOut = obj1;
                return;
            end
            %No data to add
            if ~obj1.processed
                objOut = objReduced;
                return;
            end
            %Initialise output object
            objOut = objReduced;
            
            %Combine the two objects
            objOut.context.counts =  objReduced.context.counts + obj1.context.counts;
        end
        
        function obj = CompleteDataId(obj, metadata, ddmDataTrack)
        %CompleteDataId(obj, metadata, ddmDataTrack)
            %Does not need to do anything for this task
            return;
        end
        
        function obj = Complete(obj)
        % Complete(obj) Function to complete the processing
        %  - Displays the results of the histogram function

            labelX = 'Antenna Gain [dB]';
            labelY = 'DDM Peak SNR [dB]';

            %% Generate the figure
            figHandle = sfigure('Visible', 'on');
            nXBins = length(obj.context.xBins);
            nYBins = length(obj.context.yBins);
            vXLabel = 0.5*(obj.context.xBins(1:(nXBins-1))+obj.context.xBins(2:nXBins));
            vYLabel = 0.5*(obj.context.yBins(1:(nYBins-1))+obj.context.yBins(2:nYBins));
            %Normalise the histogram
            hist2DNormalised = obj.context.counts / sum(sum(obj.context.counts));

            fprintf('Total data: %d DDMs\n\n', sum(sum(obj.context.counts)));
            
            colormap('jet');
            imagesc(vXLabel, vYLabel, hist2DNormalised);
            set(gca,'YDir','normal')

            xlabel(labelX);
            ylabel(labelY);
            grid on

            h = colorbar;
            ylabel(h, 'Normalised PDF')

            obj.figureHandles = figHandle;

        
        end

        
    end %methods
end %classdef
    