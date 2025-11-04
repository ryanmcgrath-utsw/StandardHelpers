classdef SafePref
    % SafePref - Wrapper for getpref/setpref with corruption protection
    
    properties (Constant)
        Group = 'SafePrefGroup';  % All prefs go under one group
        MaxArraySize = 1e6;       % Max allowed elements
        BackupDir = fullfile(tempdir,'SafePrefBackup');
    end
    
    methods (Static)
        function val = get(name, defaultVal)
            % Safely get a preference
            try
                if ispref(SafePref.Group, name)
                    val = getpref(SafePref.Group, name);
                else
                    val = defaultVal;
                end
            catch
                warning('Failed to get pref "%s", returning default.', name);
                val = defaultVal;
            end
        end
        
        function set(name, val)
            % Safely set a preference
            try
                % Only allow simple types to avoid corruption
                if isnumeric(val) && numel(val) > SafePref.MaxArraySize
                    error('Array too large for prefs.');
                elseif isstruct(val) || isa(val,'handle')
                    error('Structs and handles not allowed in prefs.');
                end
                
                % Make backup first
                SafePref.makeBackup();
                
                % Ensure group exists
                if ~ispref(SafePref.Group)
                    addpref(SafePref.Group);
                end
                
                % Set preference
                setpref(SafePref.Group, name, val);
                
            catch ME
                warning('Failed to set pref "%s": %s', name, ME.message);
            end
        end
        
        function makeBackup()
            % Backup prefs file
            prefFile = fullfile(prefdir,'matlabprefs.mat');
            if exist(prefFile,'file')
                if ~exist(SafePref.BackupDir,'dir')
                    mkdir(SafePref.BackupDir);
                end
                copyfile(prefFile, fullfile(SafePref.BackupDir, ...
                    ['matlabprefs_backup_' datestr(now,'yyyymmdd_HHMMSS') '.mat']));
            end
        end
    end

    methods
        function val = safeGet(group, name)
            try
                val = getpref(group,name);
            catch ME
                disp(getReport(ME))
            end
        end
    end
end