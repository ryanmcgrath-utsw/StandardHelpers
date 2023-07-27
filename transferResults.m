function transferResults(expDir, savDir)
% transfers only files in results folders
% creates a mimic of the folder structure in the expDir (regardless of
% results folder's locations)

arguments 
    expDir
    savDir
end

RESULTS_NAME = 'results';

lb = StandardHelpers.loadBar(0, 'Working ...');

expTable = struct2table(dir(fullfile(expDir,"**")));
expFolders = expTable(expTable.isdir & strcmp(expTable.name,'.'),:);
expFolders = string(expFolders.folder);
savFolders = savDir + erase(expFolders, expDir);

lb.resetTimeLeft()
for ii = 1:length(savFolders), folder = savFolders(ii);
    lb.progress = ii/length(savFolders);
    lb.message = "Estimated Time Left: " + lb.estimatedTimeLeft/60 + " minutes";
    if ~exist(folder,'dir')
        mkdir(folder)
    end
    [~,name] = fileparts(folder);
    if strcmp(name, RESULTS_NAME)
        copyfile(expFolders(ii), folder)
    end
end