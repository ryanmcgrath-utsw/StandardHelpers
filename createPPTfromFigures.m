import mlreportgen.ppt.*

[name,path] = uiputfile("*.pptx","Save Figures");
if ~path, return, end
saveloc = fullfile(path,name);

lb = StandardHelpers.loadBar(0,"Working...");

resourceFolder = "/Users/ryan/Documents/MATLAB/+StandardHelpers/Resources";
templateLocation = fullfile(resourceFolder,"ReportTemplate.pptx");
ppt = Presentation(saveloc,templateLocation);
open(ppt);

allFigures = findobj("Type","Figure");
[~,idx] = sort([allFigures.Number]);
allFigures = allFigures(idx);

for ii = 1:length(allFigures)
    lb.progress = (ii-1) / length(allFigures);

    slide = add(ppt,"Single Picture");

    tempName = "tempFigure"+ii+".png";
    tempLoc = fullfile(resourceFolder,"dump",tempName);
    saveas(allFigures(ii), tempLoc)
    figPic = Picture(tempLoc);
    replace(slide, slide.Children(1).Name, figPic);
end

lb.progress = 1;
lb.message = "Saving...";
close(ppt);
clear lb