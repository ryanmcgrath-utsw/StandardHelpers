function backupDirectory(originDir, finalDir, feedback)
%BACKUPDIRECTORY only gives a list of folders that need to be moved
% DOES NOT MOVE FOLDERS OR WORK WITH FILES AT THE MOMENT TODO

arguments
    originDir (1,1) string = '/Volumes/behavior5/'
    finalDir  (1,1) string = '/Volumes/Aegis DT/Data/Behavior5/'

    feedback (1,1) StandardHelpers.loadBar = initalizeFeedBack()
end

[originFolders, originFiles] = getFoldersAndFiles(originDir);
[ finalFolders,  finalFiles] = getFoldersAndFiles( finalDir); %#ok<ASGLU> 

if ~isempty(originFiles)
    %StandardHelpers.debug('check files!!!!')
end

originFolders = string({originFolders.name});
 finalFolders = string({ finalFolders.name});

for ii = 1:length(originFolders)
    updateFeedBack(feedback, ii, originFolders)
    matchingFolderIndx = find(finalFolders==originFolders(ii),1);
    if isempty(matchingFolderIndx)
        % folder is missing in final
        newOrigin = string(fullfile(originDir, originFolders(ii)));
        newFinal  = string(fullfile( finalDir, originFolders(ii)));
        StandardHelpers.debug("Transfer [" + newOrigin + "] to [" + newFinal + "]")
    else
        % folder exists in final
        newOrigin = fullfile(originDir, originFolders(ii));
        newFinal  = fullfile( finalDir,  finalFolders(matchingFolderIndx));
        increaseDepth(feedback)
        StandardHelpers.backupDirectory(newOrigin, newFinal, feedback)
        finalFolders(matchingFolderIndx) = [];
    end
end

decreaseDepth(feedback)

    function [folders, files] = getFoldersAndFiles(directory)
        folders = dir(fullfile(directory,"*"));
        folders(startsWith({folders.name},'.')) = [];
        files   = folders(~[folders.isdir]);
        folders = folders( [folders.isdir]);
    end

    function updateFeedBack(fb, idx, folders)
        map = @(x) x * (fb.UserData(end-1).maxValue-fb.UserData(end-1).minValue) + fb.UserData(end-1).minValue;
        fb.progress = map((idx-1) / length(folders));
        fb.UserData(end).minValue = map((idx-1) / length(folders));
        fb.UserData(end).maxValue = map(idx / length(folders));
        if toc(fb.UserData(1).time) > fb.UserData(2).time
            fb.UserData(2).time = ceil(toc(fb.UserData(1).time));
            estimate = round(toc(fb.UserData(1).time) / fb.progress - toc(fb.UserData(1).time));
            fb.message = "Estimated Time Left: " + estimate + " seconds";
        end
    end

    function increaseDepth(fb)
        fb.UserData(end+1).minValue = 0;
        fb.UserData(end).maxValue = 1;
    end

    function decreaseDepth(fb)
        fb.UserData(end) = [];
    end
end

function feedback = initalizeFeedBack()
feedback = StandardHelpers.loadBar();
feedback.UserData(1).time = tic;
feedback.UserData(2).time = 1; % time between message refresh 
feedback.UserData(1).minValue = 0;
feedback.UserData(1).maxValue = 1;
feedback.UserData(2).minValue = 0;
feedback.UserData(2).maxValue = 1;
end
