function lgd = customLegend(Colors, Labels, options)
%CUSTOMLEGEND(Colors, Labels) input cells of the color of the lines and 
% then the label for that color

arguments
    Colors (1,:) cell
    Labels (1,:) cell

    options.LineWidth (1,1) double = 5
    options.Location  (1,1) string = "best"
    options.Tag       (1,1) string = "CustomLegend"
end

if length(Colors) ~= length(Labels)
    err.ID  = "CustomLegend:IncorrectLabelLength";
    err.msg = sprintf("The number of labels [%i] does not match number of colors [%i] provided. Ensure that they are the same length.", length(Labels), length(Colors));
    throw(MException(err.ID, err.msg))
end

numColors = length(Colors);
for ii = 1:numColors
    try
        h(ii) = plot(seconds(0),NaN,'Color',Colors{ii}, 'LineWidth',options.LineWidth, 'Tag',options.Tag);  
    catch
        try
            h(ii) = plot(NaN,NaN,'Color',Colors{ii}, 'LineWidth',options.LineWidth, 'Tag',options.Tag); %#ok<*AGROW> 
        catch
            h(ii) = polarplot(NaN,NaN,'Color',Colors{ii}, 'LineWidth',options.LineWidth, 'Tag',options.Tag);
        end
    end
end
lgd = legend(h, Labels);
lgd.Location = options.Location;
end