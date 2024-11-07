function f = layoutFigures(fArray, spacing, padding, menuYShift)

arguments
    fArray = []
    spacing (1,1) double = 0
    padding (1,1) double = 10
    menuYShift (1,1) double = 56
end

set(groot,'units','pixels') 
screenSize = get(groot, "ScreenSize");

if isempty(fArray)
    f = findobj(groot,"Type","Figure");
elseif isa(fArray, 'matlab.ui.Figure')
    f = fArray;
elseif isnumeric(fArray)
    f = matlab.ui.Figure.empty(length(fArray),0);
    for ii = 1:length(fArray)
        f(ii) = figure(fArray(ii));
    end
end

[~,idx] = sort(cell2mat(get(f,"Number")),"ascend");
f = f(idx);

f(1).Position([1 2]) = [padding screenSize(4)-padding-f(1).Position(4)];
yPos = screenSize(4)-padding;
pause(0.1)
lowEdge = f(1).Position(2) - spacing - menuYShift;
for ii = 2:length(f)
    xPos = f(ii-1).Position(1) + f(ii-1).Position(3) + spacing;
    farEdge = xPos + f(ii).Position(4) + padding;
    if farEdge > screenSize(3)
        xPos = padding;
        yPos = lowEdge;
        lowEdge = screenSize(4);
    end
    f(ii).Position([1 2]) = [xPos yPos-f(ii).Position(4)];
    pause(0.1)
    lowEdge = min([lowEdge, f(ii).Position(2)-menuYShift]);
end