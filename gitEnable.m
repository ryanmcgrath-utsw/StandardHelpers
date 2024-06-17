function gitEnable(folderName)

arguments
    folderName
end

gitPath = getpref("GitHub","path",[]);

if isempty(gitPath) || ~exist(gitPath, "dir")
    gitPath = uigetdir(pwd,"Select GitHub Folder");
    if isempty(gitPath) || ~exist(gitPath, "dir")
        error("User did not select a valid GitHub folder for gitEnable.")
    else
        setpref("GitHub","path",gitPath)
    end
end

possibleFolders = dir(fullfile(gitPath,"**",folderName));
possibleFolders(~[possibleFolders.isdir]) = [];
possibleFolders(~strcmp({possibleFolders.name},'.')) = [];
if length(possibleFolders) ~= 1
    error("Could not find unique folder iin the GitHub path ("+folderName+").")
end

folder = possibleFolders.folder;
if isempty(folder) || ~exist(folder, "dir")
    error("Folder is not valid ("+folder+").")
end

addpath(genpath(folder))
end