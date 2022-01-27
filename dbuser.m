function dbuser(msg)
%DBUSER enables debug through activating debug if warning appears and then
% sending a warning using the text given in msg (will return the dbstop if
% warning state to what it was before)

% parse input
if isstring(msg)
    msg = char(msg);
elseif ~ischar(msg)
    msg = char(mlreportgen.utils.toString(msg));
end

% build a valid warning code string to be evaluated in caller
warningCode = ['warning(''DEBUG:ForceStop'', [''' msg ''' newline ''Use dbcont to continue running code!''])'];

% force the break point to enter debug mode
dbstop if warning DEBUG:ForceStop
evalin('Caller',warningCode)
dbclear if warning DEBUG:ForceStop

end