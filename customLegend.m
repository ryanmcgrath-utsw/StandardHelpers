function customLegend(Colors, Labels)
%CUSTOMLEGEND(Colors, Labels) input cells of the color of the lines and 
% then the label for that color

numColors = length(Colors);
h = zeros(numColors, 1);
for ii = 1:numColors
    try
        h(ii) = plot(seconds(0),NaN,'Color',Colors{ii});
    catch
        h(ii) = plot(NaN,NaN,'Color',Colors{ii});
    end
end
lgd = legend(h, Labels);
lgd.Location = 'best';
end