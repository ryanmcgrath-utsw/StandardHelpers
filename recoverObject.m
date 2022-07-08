function [objStruct, fileCleanup] = recoverObject(path2mat, varname)
%RECOVEROBJECT attempts to recover an object as a structure
% the process mainly exploits a work around by creating a temporary class
% that will act as a loadobj method for the lost object and allow for the
% structure of the saved data to be drawn out from the psuedo class
%
%INPUTS:
% - path2mat = full path to the .mat to be loaded
% - varname  = name of the variable that should be loaded from the .mat file
%
%OUTPUTS:
% - objStruct   = structure of the object properties
% - fileCleanup = onCleanup object that will delete the temp file that was created
%
%WARNING: cannot recursively fix objects that contain other objects that
% have class files that are not on the path. 
%
% See also LOAD, ONCLEANUP and CREATETEMPCLASSFILE

arguments
    path2mat char
    varname  char
end

% set the warning given for failing to load in an a custom object to initiate an error
warningCleanup = setWarnings2Errors(); %#ok<NASGU>

%% main logic
try
    % try to load in the object
    obj = load(path2mat,varname);
    % if successful just convert to struct and give it back
    objStruct = obj.(varname);
    warning('recoverObject:safeRecovery',['Object [' varname '] was sucessfully loaded and returned. Not sure if this was intended but it seems [' class(objStruct) '] class is already on the path.'])
catch ME
    if strcmp(ME.identifier, 'MATLAB:load:cannotInstantiateLoadedVariable')
        % use the error message to find which class could not be instantiated and create the new file class to be used
        fileCleanup = StandardHelpers.createTempClassFile(getObjClass(ME.message));
        
        try
            % try once again to read the varname object
            obj = load(path2mat,varname);
            % if successful, extract the struct and give it back
            objStruct = obj.(varname).structure;
        catch ME
            % if something went wrong check if it was due to class failed to initiate or something else
            if strcmp(ME.identifier, 'MATLAB:load:cannotInstantiateLoadedVariable')
                errID  = 'recoverObject:failedFileCreation';
                errMsg =['Something went terribly wrong creating the temp file class and could not load [' varname '] properly!'];
                throw(addCause(MException(errID,errMsg),ME))
            else
                throw(ME)
            end
        end
    else
        throw(ME)
    end
end

%% Helper functions
    function cleanup = setWarnings2Errors()
        % sets a few warnings to be errors instead
        warnStruct(1) = warning('error','MATLAB:load:cannotInstantiateLoadedVariable'); %#ok<CTPCT>
        warnStruct(2) = warning('error','MATLAB:load:variableNotFound'); %#ok<CTPCT>
        cleanup = onCleanup(@() warning(warnStruct)); % at close return to previous warnings
    end

    function className = getObjClass(msg)
        % gets obj class name from the error message and performs cleanup
        className = regexp(msg, 'originally saved as a .* cannot', 'match', 'once');
        if isempty(className),  className = [regexp(msg, 'class ''.*''', 'match', 'once'),' temp']; end
        className = split(className); 
        className = className{end-1}; 
        className = strrep(className,'''','');
    end
end