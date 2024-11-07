function lgd = customLegend(Colors, Labels, options, legendProps)
%CUSTOMLEGEND(Colors, Labels) input cells of the color of the lines and 
% then the label for that color

arguments
    Colors
    Labels

    options.PlotLineWidth (1,1) double = 5
    options.PlotTag       (1,1) string = "CustomLegend"

    legendProps.?matlab.graphics.illustration.Legend
end

Colors = validateColors(Colors);
Labels = validateLabels(Labels);

if length(Colors) ~= length(Labels)
    err.ID  = "CustomLegend:IncorrectLabelLength";
    err.msg = sprintf("The number of labels [%i] does not match number of colors [%i] provided. Ensure that they are the same length.", length(Labels), length(Colors));
    throw(MException(err.ID, err.msg))
end

numColors = length(Colors);
for ii = 1:numColors
    try
        h(ii) = plot(seconds(0),NaN,'Color',Colors{ii}, 'LineWidth',options.PlotLineWidth, 'Tag',options.PlotTag);  
    catch
        try
            h(ii) = plot(NaN,NaN,'Color',Colors{ii}, 'LineWidth',options.PlotLineWidth, 'Tag',options.PlotTag); %#ok<*AGROW> 
        catch
            h(ii) = polarplot(NaN,NaN,'Color',Colors{ii}, 'LineWidth',options.PlotLineWidth, 'Tag',options.PlotTag);
        end
    end
end
lgd = legend(h, Labels);
lgd.Location = "Best";
if ~isempty(fields(legendProps))
    % legend options were given
    opts = namedargs2cell(legendProps);
    set(lgd, opts{:})
end
end

function Colors = validateColors(Colors)
if iscell(Colors)
    Colors = Colors(:);
elseif isnumeric(Colors)
    temp = cell(size(Colors,1),1);
    for ii = 1:length(temp)
        temp{ii} = Colors(ii,:);
    end
    Colors = temp;
else
    throw(MException("CustomLegend:invalidColors","Invalid 1st input (Colors). Input must be a cell array or matrix with each row being a seperate RGB triplet."))
end
end

function Labels = validateLabels(Labels)
if iscell(Labels)
    Labels = Labels(:);
elseif isstring(Labels)
    temp = cell(size(Labels));
    for ii = 1:length(temp)
        temp{ii} = Labels(ii);
    end
    Labels = temp;
else
    throw(MException("CustomLegend:invalidLabels","Invalid 2nd input (Labels). Input must be a cell or string array containing labels associated with each color."))
end
end