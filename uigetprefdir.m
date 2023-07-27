function path = uigetprefdir(group, name)
%UIGETPREFDIR fancy uigetdir/file that remembers what you gave it
% Missing plenty of options such as defualts or options to ask again or
% asking again everytime but remembering the folder or extensions
% Also needs comments added TODO

arguments
    group (1,1) string
    name  (1,1) string
end

path = getpref(group, name, "unset");
if path == "unset"
    path = askForPath();
elseif ~exist(path, 'dir') || ~exist(path, 'file')
    answer = questdlg("Directory ["+path+"] does not exist. Reset preference or continue anyway?", "Invalid Directory", "Reset", "Continue", "Cancel", "Reset");
    switch answer
        case "Reset"
            path = askForPath();
        case "Continue"
            % do nothing
        otherwise
            path = [];
    end
end
setpref(group, name, path)

    function path = askForPath()
        switch questdlg("Are you looking for a file or folder?", "File or Folder", "File", "Folder", "Cancel", "Folder")
            case "File"
                [folder, file] = uigetfile();
                path = fullfile(folder, file);
            case "Folder"
                path = uigetdir();
            otherwise
                path = [];
                return
        end
    end
end