function [ outputString ] = toWindowsPathSep( inputString )
%TOWINDOWSPATHSEP Convert \ to / in string

    outputString = inputString;

    for i = 1:length(outputString)
       if outputString(i) == '/'
           outputString(i) = '\';
       end
    end

end

