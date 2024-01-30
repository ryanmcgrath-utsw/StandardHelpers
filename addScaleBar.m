function handles = addScaleBar(ax, xy, txt, sz, hORv)
%ADDSCALEBAR places a scale bar at the specified xy position with length
% given by sz and being horizontal if hORV is 1 or 'h' and vertical if 0 or
% 'v', with the given text set below it
%
% handles = addScaleBar(gca, [1, 1], '1 mm', 1, 'h' or 1)
% handles.p = line plot
% handles.t = text plot
%
% See also TEXT and PLOT

arguments
    ax   (1,1) matlab.graphics.axis.Axes = gca
    xy   (1,2) double = [0.1 0.1]
    txt  (1,:) char = "1 unit"
    sz   (1,1) double {mustBePositive} = 1
    hORv (1,1) = 1
end

% activate the axes to bring to front
axes(ax)
if ishold
    wasHolding = 1;
else
    wasHolding = 0;
    hold on;
end

% parse input
if ~isnumeric(hORv)
    if hORv == 'v'
        hORv = 0;
    else
        hORv = 1;
    end
end

if ~isnumeric(xy)
    xLimits = xlim;
    yLimits = ylim;
    margin = 0.1;
    switch xy
        case 'bottomLeft'
            xy = [xLimits(1)+diff(xLimits)*margin, yLimits(1)+diff(yLimits)*margin];
        case 'topLeft'
            if hORv
                xy = [xLimits(1)+diff(xLimits)*margin, yLimits(2)-diff(yLimits)*margin];
            else
                xy = [xLimits(1)+diff(xLimits)*margin, yLimits(2)-diff(yLimits)*margin-sz];
            end
        case 'bottomRight'
            if hORv
                xy = [xLimits(2)-diff(xLimits)*margin-sz, yLimits(1)+diff(yLimits)*margin];
            else
                xy = [xLimits(2)-diff(xLimits)*margin, yLimits(1)+diff(yLimits)*margin];
            end
        otherwise % 'topRight'
            if hORv
                xy = [xLimits(2)-diff(xLimits)*margin-sz, yLimits(2)-diff(yLimits)*margin];
            else
                xy = [xLimits(2)-diff(xLimits)*margin, yLimits(2)-diff(yLimits)*margin-sz];
            end
    end
end      

if hORv
    xVals = [xy(1), xy(1)+sz];
    yVals = [xy(2), xy(2)];
    scale = ylim;
    scale = diff(scale) * 0.015;
    handles.t = text(xy(1),xy(2)-scale,txt,'FontSize',14);
else
    xVals = [xy(1), xy(1)];
    yVals = [xy(2), xy(2)+sz];
    scale = xlim;
    scale = diff(scale) * 0.015;
    handles.t = text(xy(1)-scale,xy(2),txt,'FontSize',14);
    handles.t.Rotation = 90;
end
handles.p = plot(xVals, yVals, 'LineWidth',1, 'Color','k');

if ~wasHolding
    hold off
end
