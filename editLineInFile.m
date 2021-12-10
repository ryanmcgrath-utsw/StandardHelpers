function found = editLineInFile(fileLocation, targetLine, insertLine)
%EDITLINEINFILE goes through a file (loacted at "fileLocation" and finds a 
% specific "targetLine" and replaces it with the "newLine"
% - targetLine doesn't need to include any white space in front of the first true character or after the last true character
% - newLine is stripped of leading and trialing white space before being inserted with the same whitespace leading as the original target line
% - trialing whitespace is always removed replaced with newline character
% - if line was not found will return a false else true
% - uses regexp to search for targetLine thus target line can be a regexp

% open the file and clean up input
insertLine = strip(insertLine);
targetLine = strip(targetLine);
found = 0;
fid = fopen(fileLocation,'r');
currLine = fgetl(fid);

% check first line and prep for while loop
if ~isempty(regexp(strip(currLine), targetLine, 'once'))
    found = 1;
    firstNonWhitespace = regexp(currLine,'\S','once');
    if ~isempty(firstNonWhitespace) && firstNonWhiteSpace~=1
        whitespace = currLine(1:firstNonWhitespace-1);
        buffer = [whitespace insertLine]; %#ok<*AGROW>
    else
        buffer = insertLine;
    end
else
    buffer = currLine; 
end

currLine = fgetl(fid); % get next line to prep for loop

% loop through file searching for file
while ischar(currLine)
    
    if ~isempty(regexp(strip(currLine), targetLine, 'once'))
        % found the target line
        found = 1;
        firstNonWhitespace = regexp(currLine,'\S','once');
        if ~isempty(firstNonWhitespace) && firstNonWhitespace~=1
            whitespace = currLine(1:firstNonWhitespace-1);
            buffer = [buffer newline whitespace insertLine]; %#ok<*AGROW>
        else
            buffer = [buffer newline insertLine];
        end
    else
        % not the target line just add to buffer
        buffer = [buffer newline currLine];
    end
    
    currLine = fgetl(fid);
end

% reopen the file and rewrite the the using the buffer with the inserted line
fclose(fid);
fid = fopen(fileLocation, 'w');
fwrite(fid, buffer);
fclose(fid);
end

