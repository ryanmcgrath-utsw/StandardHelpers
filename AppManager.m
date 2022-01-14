classdef AppManager < ErrorLogger
    %APPMANAGER handles managing an app project by ensuring required files
    % exist and preferences are set and resources are generated.
    
    properties
        preferences 
        projectFolder
        appName
    end
    
    methods
        function obj = AppManager(appPath)
            [obj.projectFolder, obj.appName] = fileparts(appPath);
            files = struct2cell( dir(obj.projectFolder) );
            for ii = 1:length(files(1,:))
                ff = files(:,ii);
                if any( strcmp(ff{1}, {'.','..'}) )
                    files(:,ii) = [];
                end
            end
        end
    end
end