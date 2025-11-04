function debug(msg, method)
% does the same as disp just adds additional info
arguments
    msg
    method (1,1) string = "basic"
end

if isstring(msg) && isscalar(msg)
    msg = char(msg);
end

if ~ischar(msg)
    msg = evalc('disp(msg)');
end

msg = strip(msg);

switch method
    case 'basic'
        stack = dbstack;
        try
            file = which(stack(2).file);
            hyperlinkFunction = sprintf(['matlab: opentoline( ''%s'', ' num2str(stack(2).line) ')'], file);
            disp([datestr(now) ' || <a href="' hyperlinkFunction '">Line ' num2str(stack(2).line) ': ' stack(2).name '</a> >> ' msg])
        catch
            disp([datestr(now) ' >> ' msg])
        end
        
    case 'full'
        disp([newline datestr(now) ' >> ' ])
        dbstack
        disp(['> ' msg newline])
        
    otherwise
        error(['Unknown debug method (argument position 2) used [' method ']'])
end