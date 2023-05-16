function rename(oldName, newName)

arguments
    oldName (1,1) string
    newName (1,1) string
end

evalin('caller', newName + "=" + oldName + "; clear " + oldName)
end