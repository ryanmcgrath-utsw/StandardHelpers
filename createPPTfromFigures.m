function ppt = createPPTfromFigures(saveloc, allFigures, slideGroupings, slideLocation, dontClose)

%% Input Validation
arguments
    saveloc (1,1) string = "N/A"
    allFigures (1,:) matlab.ui.Figure = matlab.ui.Figure.empty(0,1)
    slideGroupings (1,:) double = []
    slideLocation  (1,:) double = []
    dontClose (1,1) logical = false % set to true to not close ppt (allow further editing)
end

import mlreportgen.ppt.*

if strcmp(saveloc, "N/A") || strcmp(saveloc, "")
    [name,path] = uiputfile("*.pptx","Save Figures");
    if ~path, return, end
    saveloc = fullfile(path,name);
end

if ~endsWith(saveloc,".pptx")
    saveloc = saveloc+".pptx";
end

lb = StandardHelpers.loadBar(0,"Working...");

%% Create Powerpoint file
resourceFolder = "/Users/ryan/Documents/MATLAB/+StandardHelpers/Resources"; % FIXME needs use mfilename('fullpath') trick
templateLocation = fullfile(resourceFolder,"ReportTemplate.pptx");
if ~exist(fullfile(resourceFolder,"dump"), "dir"), mkdir(fullfile(resourceFolder,"dump")), end

ppt = Presentation(saveloc,templateLocation);
if ~exist(fileparts(saveloc),"dir"), mkdir(fileparts(saveloc)), end
open(ppt);

%% Use all figures if figures not specified
if isempty(allFigures)
    allFigures = findobj("Type","Figure");
    [~,idx] = sort([allFigures.Number]);
    allFigures = allFigures(idx);
    slideGroupings = 1:length(allFigures); % if figures not given slideGroupings is defualt
end

aspectRatios = arrayfun(@(f) f.Position(3)/f.Position(4), allFigures);
aspectRatios(aspectRatios < 1) = 1 ./ aspectRatios(aspectRatios < 1);
if any(aspectRatios > 3)
    warning("Some Figures have extreme aspect ratios this may cause formating errors.")
end

if isempty(slideGroupings)
    slideGroupings = 1:length(allFigures);
end

%% Save figures as temp images
lb.message = "Saving Figures";
tempFiles = string.empty(length(allFigures),0);
for ff = 1:length(allFigures)
    lb.progress = (ff-1) / length(allFigures);
    tempName = "tempFigure"+ff+".png";
    tempLoc = fullfile(resourceFolder,"dump",tempName);
    saveas(allFigures(ff), tempLoc)
    tempFiles(ff) = tempLoc;
end

%% Add slides to the power point
lb.message = "Generating PowerPoint";
slideIndex = unique(slideGroupings);
for ss = 1:length(slideIndex)
    lb.progress = (ff-1) / length(allFigures);
    % get format info
    groupIdx = slideIndex(ss) == slideGroupings;
    numFigs = sum(groupIdx);

    % determine slide to add
    switch numFigs
        case 1
            slide = add(ppt, "Single Picture");
        case 2
            slide = add(ppt, "Dual Pictures");
        case 3
            slide = add(ppt, "Three Pictures");
        otherwise
            error("Grouping number [%d] has more than 3 instances (feature not implemented).", slideIndex(ss))
    end

    % determine locations to place figures in slide
    if isempty(slideLocation)
        placeLocations = 1:numFigs;
    else
        placeLocations = slideLocation(groupIdx);
    end

    % grab files to add and place them into the slide
    tempLoc = tempFiles(groupIdx);
    for ff = 1:numFigs
        loc2place = determineImageName(numFigs, placeLocations(ff));
        img = mlreportgen.ppt.Picture(tempLoc(ff));
        replace(slide, loc2place, img);
        % placeImg_fit(slide, loc2place, tempLoc(ff))
    end
end

%% Save and cleanup
lb.progress = 1;
lb.message = "Saving...";
if ~dontClose, close(ppt); end
clear lb
end

%% Helper Functions
function placeImg_fit(slide, loc2place, imgLoc)
% Get the content placeholder
idx = arrayfun(@(x) loc2place==x.Name, slide.Children);
contentPlaceholder = slide.Children(idx);

% Retrieve the width of the placeholder
placeholderWidth = contentPlaceholder.Width;
placeholderWidth = regexp(placeholderWidth,"[0-9]*","match","once");
placeholderWidth = str2double(placeholderWidth) / 12700;

% Read the image
I = imread(imgLoc);

% Resize the image to fit the placeholder width while maintaining aspect ratio
aspectRatio = size(I, 2) / size(I, 1); % width / height
newHeight = placeholderWidth / aspectRatio;
J = imresize(I, [newHeight, placeholderWidth]);
imwrite(J,imgLoc)

% Add the resized image to the slide
img = mlreportgen.ppt.Picture(imgLoc);
replace(slide, loc2place, img);
end

function loc2place = determineImageName(numFigs, loc2place)
switch numFigs
    case 1
        loc2place = "MainImage";

    case 2
        switch loc2place
            case 1
                loc2place = "LeftImage";
            case 2
                loc2place = "RightImage";
            otherwise
                error("Attempted to place figure outside acceptable locations. Double check saveLocations given.")
        end

    case 3
        switch loc2place
            case 1
                loc2place = "SmallTopImage";
            case 2
                loc2place = "SmallBottomImage";
            case 3
                loc2place = "MainImage";
            otherwise
                error("Attempted to place figure outside acceptable locations. Double check saveLocations given.")
        end
end
end
