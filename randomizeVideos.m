function key = randomizeVideos(folder, options)
%RANDOMIZEVIDEOS randomize the filenames in a folder and creates an answer key 

%% input validation
arguments
    folder (1,1) string {mustBeFolder} = uigetdir()

    options.FileType (1,1) string = "avi"
    options.OutputName (1,1) string {mustAllowFormating} = "video_%i"
    options.CsvName (1,1) string = "VideoKey.csv"
    options.ZipName (1,1) string = "OriginalVideos.zip"
end

% clean FileType option and make the searchTerm to use with dir()
if ~startsWith(options.FileType, '.')
    options.FileType = "." + options.FileType;
end
searchTerm = fullfile(folder, "*"+options.FileType);

% ensure output name has same file type used in the search term
if ~endsWith(options.OutputName, options.FileType)
    options.OutputName = options.OutputName + options.FileType;
end

% clean the CsvName to ensure it ends with .csv
if ~endsWith(options.CsvName, ".csv")
    options.CsvName = options.CsvName + ".csv";
end

% clean the ZipName to ensure it ends with .zip
if ~endsWith(options.ZipName, ".zip")
    options.ZipName = options.ZipName + ".zip";
end

% simple feedback to let user know this will take a while
loadbar = waitbar(1, "Randomizing Folder...");
cleaner = onCleanup(@(~) close(loadbar)); 

%% create key table
files = dir(searchTerm);
absPaths = arrayfun(@(x) string(fullfile(x.folder, x.name)), files);
originalName = string({files.name})';
index = randperm(length(originalName))';
annoName = sprintf(options.OutputName+newline, index);
annoName = split(strip(annoName));
key = table(index, originalName, annoName);
csvPath = fullfile(folder,options.CsvName);
writetable(key, csvPath)

%% move/rename files
zip(fullfile(folder, options.ZipName), [absPaths; csvPath])
delete(csvPath)
for ii = 1:height(key)
    oldName = fullfile(folder, key.originalName(ii));
    newName = fullfile(folder, key.annoName(ii));
    movefile(oldName, newName)
end 

end

%% helper functions
function mustAllowFormating(val)
    if length(regexp(val,'%i','match')) ~= 1
        throwAsCaller(MException("randomizeVideos:InvalidOutputName", "OutputName argument must include a '%i' to allow insertion of index number."))
    end
end