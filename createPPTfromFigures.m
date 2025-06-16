function createPPTfromFigures(saveloc)

arguments
    saveloc (1,1) string = "N/A"
end

import mlreportgen.ppt.*

if strcmp(saveloc, "N/A")
    [name,path] = uiputfile("*.pptx","Save Figures");
    if ~path, return, end
    saveloc = fullfile(path,name);
end

if ~endsWith(saveloc,".pptx")
    saveloc = saveloc+".pptx";
end

lb = StandardHelpers.loadBar(0,"Working...");

resourceFolder = "/Users/ryan/Documents/MATLAB/+StandardHelpers/Resources";
templateLocation = fullfile(resourceFolder,"ReportTemplate.pptx");
ppt = Presentation(saveloc,templateLocation);
if ~exist(fileparts(saveloc),"dir"), mkdir(fileparts(saveloc)), end
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
end