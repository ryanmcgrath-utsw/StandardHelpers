classdef DirObject
    %DIROBJECT

    properties
        path (1,1) string

        folder     (1,1) string
        file       (1,1) string
        file_NoExt (1,1) string
        ext        (1,1) string
    end

    methods
        function obj = DirObject(val)
            % try to convert value given to a path string
            if isa(val, "struct") && isfield(val, "name") && isfield(val, "folder") && ~isempty(val)
                obj.path = fullfile(val(1).folder, val(1).name);
            else
                try 
                    val = arrayfun(@(x) char(x), string(val), "UniformOutput", false);
                    obj.path = fullfile(val{:});
                catch ME
                    errMsg = "Value given is not able to be converted into a path string. Input is either a path string or a valid DIR() output structure.";
                    errID = "DirObject:InvalidValue";
                    throwAsCaller(MException(errID, errMsg))
                end
            end

            % edit path if either the dot or double dot notation (./..) is used
            [obj.folder, obj.file_NoExt, obj.ext] = fileparts(obj.path);
            obj.file = strcat(obj.file_NoExt, obj.ext);
            if strcmp(obj.file, '.')
                [obj.folder, obj.file_NoExt, obj.ext] = fileparts(obj.folder);
                obj.file = strcat(obj.file_NoExt, obj.ext);
                obj.path = fullfile(obj.folder, obj.file);
            elseif strcmp(obj.file, '..')
                [obj.folder, obj.file_NoExt, obj.ext] = fileparts(fileparts(obj.folder));
                obj.file = strcat(obj.file_NoExt, obj.ext);
                obj.path = fullfile(obj.folder, obj.file);
            end

            % test the generated path string to ensure its valid
            if ~exist(obj.path, "file")
                errMsg = "Value given is not a valid path to either a folder or file.";
                errID ="DirObject:NotAPath";
                throwAsCaller(MException(errID, errMsg))
            end
        end

        function val = string(obj)
            val = obj.path;
        end

        function val = char(obj)
            val = char(obj.path);
        end
    end

    methods (Static)
        function val = dir(val)
            %DIR its just a better dir, imo, but ill never use it :/
            if nargin > 0
                try dirStruct = dir(val); catch ME, throwAsCaller(ME), end
            else
                try dirStruct = dir(); catch ME, throwAsCaller(ME), end
            end
            val = arrayfun(@(x) string(fullfile(x.folder, x.name)), dirStruct);
        end

        function val = uigetfile(varargin)
            [f,p] = uigetfile(varargin{:});
            packStr = getPackage();
            val = eval(strcat(packStr,'DirObject(dir(fullfile(p,f)))'));
        end

        function val = uigetdir(varargin)
            fp = uigetdir(varargin{:});
            packStr = getPackage();
            val = eval(strcat(packStr,'DirObject(fp)'));
        end
    end
end

function packageStr = getPackage()
path = mfilename('fullpath');
folders = split(path, filesep);
folders(end) = [];
packageStr = '';
while strcmp(folders{end}(1), '+')
    packageStr = strcat(folders{end}(2:end), '.', packageStr);
    folders(end) = [];
end
end