function addFileDivider()
%ADDFILEDIVIDER opens a file with a styled name that makes seperating
% multiple files in the editor window easier
% file names follow: '<fileDividerFormat>#.m' where # is replaced with how
% many file dividers are open

% shows up at the top of each of these files
fileDividerComment = '% File Divider (feel free to delete, only used to make seperating files in editor window easy, DO NOT EDIT)';
fileDividerFormat  = 'l______________l';

X = matlab.desktop.editor.getAll; % fancy structure with all files

openDividers = zeros(1,length(X));
for ii = 1:length(X)
    dividerIndex = regexp(X(ii).Filename,[fileDividerFormat '[0-9]+'],'once');
    if ~isempty(dividerIndex)
        fileName = X(ii).Filename(dividerIndex:end);
        openDividers(ii) = str2double(regexp(fileName,'[0-9]+','match','once'));
    end
end
openDividers(openDividers==0) = [];
openDividers = [0 openDividers];

nextDividerIndex = find(diff(sort(openDividers))>1,1);
if isempty(nextDividerIndex)
    nextDividerIndex = max(openDividers) + 1;
else
    nextDividerIndex = openDividers(nextDividerIndex) + 1;
end
if isnan(nextDividerIndex), error('Critical Error: can''t find the next divider index'); end
newDividerName = [fileDividerFormat num2str(nextDividerIndex) '.m'];

path = fullfile(userpath, 'fileDividers');
if ~exist(path,'dir')
    mkdir(path)
end
fid = fopen(fullfile(path,newDividerName),'w');
fwrite(fid, fileDividerComment);
fclose(fid);

open(fullfile(path,newDividerName))