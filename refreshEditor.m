function refreshEditor()
%REFRESHEDITOR closes and reopens all current files in the editor
% Only used to refresh docs due to bug in which all opened docs are blank
% and only closing and reopening them makes the contents visible and
% editable, this will take time and is an odd work around
%
% May not work with unsaved documents
%
% Runs by just calling the function (no inputs)
% refreshEditor()
%
% See also matlab.desktop.editor.getAll

X = matlab.desktop.editor.getAll;
filesToReopen = string.empty(0,length(X));
for ii = 1:length(X)
    filesToReopen(ii) = string(X(ii).Filename);
    close(X(ii))
end
for ii = 1:length(X)
    open(filesToReopen(ii))
end
end