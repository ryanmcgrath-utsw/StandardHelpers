import mlreportgen.ppt.*

UserTitle = input("Give title for pptx: ", "s");

lb = StandardHelpers.loadBar(0,"Working...");

resourceFolder = "/Users/ryan/Documents/MATLAB/+StandardHelpers/Resources";
templateLocation = fullfile(resourceFolder,"ReportTemplate.pptx");
ppt = Presentation(UserTitle+".pptx",templateLocation);
open(ppt);

allFigures = findobj("Type","Figure");
[~,idx] = sort([allFigures.Number]);
allFigures = allFigures(idx);

for ii = 1:length(allFigures)
    lb.progress = (ii-1) / length(allFigures);

    slide = add(ppt,"Three Pictures");

    tempName = "tempFigure"+ii+".png";
    tempLoc = fullfile(resourceFolder,"dump",tempName);
    saveas(allFigures(ii), tempLoc)
    figPic = Picture(tempLoc);
    replace(slide, slide.Children(2).Name, figPic);
end

lb.progress = 1;
lb.message = "Saving...";
close(ppt);
clear lb