function data = TemplateSavingFunction(flyFolder, options)
%TEMPLATESAVINGFUNCTION template for a saving function that will save results

%% Input Validation
arguments
    % Required inputs
    flyFolder (1,1) string {mustBeFolder}  % path to flyFolder (where data is saved)

    % Saving options
    options.SaveResults   (1,1) logical = true
    % set to false to skip saving the data output
    options.Overwrite     (1,1) logical = true
    % set to false to run without deleting the previous results if they exist
    % setting this to false will result in rerunning regardless of options.ForceRerun
    options.ForceRerun    (1,1) logical = false
    % set to true  to rerun analysis regardless if there is a previous save available
    options.ResultsFolder (1,1) string  = "results"
    % name of the results folder (should remain the same)
    options.ResultsFile   (1,1) string  = "Template_{timeStamp}"
    % how the save data is named, {timeStamp} is replaced with yyyyMMdd'T'HHmmss date format
    % do NOT add a file extension that is not .mat (it will be overwritten)
end

%% Loading Options
% check save options and if prior runs exist
lastRun = getLastRun(flyFolder,options);
if ~isempty(lastRun) && ~options.ForceRerun && options.Overwrite
    % prior results found and not forcing rerun
    load(lastRun,"data")
    return
end

%% Main Logic
% Will only run if prior data was not loaded
data = 1;

%% Save Results and Cleanup
saveResults(data, flyFolder, lastRun, options)
% insert other clean up code if necessary
end

%% Helper Functions (Saving)
function saveLocation = createSavePath(flyFolder, options, skipTimeStamp)
fileName = options.ResultsFile;
if nargin < 3 || strcmpi(skipTimeStamp, "replaceTimeStamp")
    fileName = strrep(fileName, "{timeStamp}", string(datetime("now","Format","uuuuMMdd'T'HHmmss")));
end
if ~endsWith(fileName,".mat")
    fileName = fileName + ".mat";
end
saveLocation = fullfile(flyFolder, options.ResultsFolder, fileName);
end

function lastRun = getLastRun(flyFolder,options)
lastRun = createSavePath(flyFolder, options, "skipTimeStamp");
lastRun = dir(strrep(lastRun,"{timeStamp}","*"));
if isempty(lastRun), return, end
runTimes = datetime.empty(length(lastRun),0);
for ii = 1:length(lastRun)
    ts = regexp(lastRun(ii).name, "[0-9]{8}T[0-9]{6}", "match", "once");
    runTimes(ii) = datetime(ts, "InputFormat","uuuuMMdd'T'HHmmss");
end
[~,idx] = max(runTimes);
lastRun = fullfile(lastRun(idx).folder, lastRun(idx).name);
end

function saveResults(ori, vidFile, lastRun, options)
if options.Overwrite && ~isempty(lastRun)
    delete(lastRun)
end
saveLocation = createSavePath(vidFile, options);
if ~exist(fileparts(saveLocation),"dir")
    mkdir(fileparts(saveLocation))
end
save(saveLocation, "ori")
end

%% Helper Functions (Analysis)

%% Validation Functions
