function handle = myFigure(num)
%MYFIGURE just a fancy version of figure that creates a figure using the
% standard figure input (figure number), clears the figure, docks it, and
% does anything else (check below)
%
% figureHandle = myFigure(figureNumber)
%
% See also FIGURE

% create figure
if nargin<1
    handle = figure();
else
    handle = figure(num);
end

% set custom parameters
handle.WindowStyle = 'docked';
clf
hold on

end