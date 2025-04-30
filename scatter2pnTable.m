function scatter2pnTable(ax, sigVal, lacksDisplayNames)
%SCATTER2PNTABLE takes an axis containing scatter plots and generates a table of p-Vals 
% set lacks display names to true if you didn't add display names to
% classify the groups (NOT RECOMMENDED)

arguments
    ax (1,1) matlab.graphics.axis.Axes = gca
    sigVal (1,1) double = 0.05
    lacksDisplayNames (1,1) logical = false
end

plottedData = findobj(ax,"Type","Scatter");
cats = get(plottedData,'DisplayName');
if lacksDisplayNames
    missingIdx = find(cellfun(@isempty,cats));
    cats(missingIdx) = arrayfun(@(x) ['Group_' num2str(x)], missingIdx, "UniformOutput", false);
else
    cats(cellfun(@isempty,cats)) = [];
end
pnTable = table('Size',[0 6],'VariableTypes',["string","double","string","double","double","logical"],'VariableNames',["Group1","n1","Group2","n2","ranksum_pVal","significant"]);
for ii = 1:(length(cats)-1)
    for jj = ii+1:length(cats)
        dataSet1 = plottedData(ii).YData;
        dataSet2 = plottedData(jj).YData;
        p = ranksum(dataSet1, dataSet2);
        pnTable.Group1(end+1) = string(cats{ii});
        pnTable.Group2(end) = string(cats{jj});
        pnTable.n1(end) = length(dataSet1);
        pnTable.n2(end) = length(dataSet2);
        pnTable.ranksum_pVal(end) = p;
        pnTable.significant(end) = p < sigVal;
    end
end