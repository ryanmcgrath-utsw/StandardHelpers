function test(evalStr)
try
    evalin('caller',evalStr)
catch ME
    dbstop if warning
    pause(0.1)
    warning('Test failed')
    dbclear if warning
end
end