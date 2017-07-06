classdef (Abstract) ProcessingTask 
%ProcessingTask An abstract class, used to define the interface used for
%each of the processing tasks.
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

    properties (Abstract)
        settings
        % Filter settings as cell array of the filter name-value pairs
        filterSettings
        processingType
        netCDFNeedsSaving
        processed
    end
    
    methods (Abstract)
        %Function used to return what data should be loaded in
        varNames = VarNamesRequired(obj)
        
        %Function to return whether the DDMs need loading in
        boolOut = NeedToLoadDDMs(obj)
        
        %Initialisation function
        obj = Initialise(obj, settings)
        
        %Initialisation function - run at start of dataId
        obj = InitialiseDataId(obj, metadata)
        
        %Process a track
        obj = ProcessTrack(obj, metadata, ddmDataTrack)

        %Process run at end of data ID  i.e. end of dataId
        obj = CompleteDataId(obj, metadata, ddmDataTrack)
        
        %Reduce outputs / collate results into objOut
        objOut = Reduce(obj1, obj2)
        
        %Complete processing of the reduced output
        obj = Complete(obj)
    end
end