function h = sfigure(varargin)
% SFIGURE  Create figure window (minus annoying focus-theft).
%
% Usage is identical to figure.
% Extended to allow figure(h, option, value)
%
% Daniel Eaton, 2005
%
% See also figure

if nargin == 1
    h = varargin{1};
    if ishandle(h)
        set(0, 'CurrentFigure', h);
    else
        h = figure(h);
    end
elseif nargin == 2
    option = varargin{1};
    val = varargin{2};
    h = figure(option, val);
elseif nargin == 3
    h = varargin{1};
    option = varargin{2};
    val = varargin{3};
    if ishandle(h)
        %Set option and current figure
        set(0, 'CurrentFigure', h);
        set(h, option, val);
    elseif strcmp(option, 'Visible') == 1
        %Special case for invisible new figure with specified handle
        set(0,'DefaultFigureVisible','off');
        h = figure(h);
        set(0,'DefaultFigureVisible','on');
    else
        error('Unrecognised option');
    end
else
	h = figure;
end