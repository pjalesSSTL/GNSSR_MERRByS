classdef TextProgressBar < handle
    %TEXTPROGRESSBAR Draw a text progress bar to the console
    
    properties
        progressBarLength = 60;
        progresBarIdx = 0;
    end
    
    methods
        function DrawBackground(obj)
        %DrawBackground Progress bar - draw background
            fprintf(['|', repmat('-', 1, obj.progressBarLength), '|\n ']) %make the "background"
            obj.progresBarIdx = 0;
        end
        
        function Update(obj, progress)
        %SetProgress Progress bar - update with progress 0 to 1
            if progress >= 0 && progress <= 1
                while(obj.progresBarIdx < (progress * obj.progressBarLength))
                    obj.progresBarIdx = obj.progresBarIdx + 1;
                    fprintf('*');
                end
            end
        end
    end
    
end

