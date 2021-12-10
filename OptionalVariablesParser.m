classdef OptionalVariablesParser < dynamicprops & ErrorLogger
    %OPTIONALVARIABLESPARSER
    % just add the code below to get started:
    %   persistent optVars
    %   if isempty(optVars)
    %       optVars = OptionalVariablesParser();
    %   end
    %   optVars.parse({functionInputArguments}, indexOfOptionalVariablesCellArray)
    % also add a optVars.checkError(ME) in a try-catch-ME statment to
    % dynamically catch newly added property requirments
    
    properties
        variableRules  % contains the rule set structure
        variableArray  % cell array of user input (matches optionalVariables)
        configPath     % path to the rule set for this parser
        functionName   % name of the function this parser is assigned to
        functionInputs % cell array of all the assigned function inputs 
    end
    
    properties (Dependent)
        variableNames % outputs a field of all dynamic properties (no set)
    end
    
    methods
        %% basic functions
        function obj = OptionalVariablesParser(configPath)
            %CONSTRUCTOR give either nothing if called within the function,
            % the function handle if called outside, or the direct path to
            % the .mat file to be used
            
            if nargin < 1
                stack = dbstack;
                [folder, file, ~] = fileparts(which(stack(2).file));
                obj.configPath = fullfile(folder, [file '.mat']);
            elseif isa(configPath, 'function_handle')
                % given the function handle (likely debugging outside function)
                [folder, file, ~] = fileparts(which(func2str(configPath)));
                obj.configPath = fullfile(folder, [file '.mat']);
            else
                obj.configPath = configPath;
            end
            
            if exist(obj.configPath, 'file')
                load(obj.configPath, 'ruleSet')
                obj.variableRules = ruleSet;
            else
                obj.variableRules = struct.empty;
            end
            
            [~,obj.functionName,~] = fileparts(obj.configPath);
        end
        
        %% functions related to parsing through user input
        function parse(obj, functionInputs, optVarIndex)
            %PARSE call to parse through the inputs the optVarIndex should
            % index into functionInputs to find the optional vaiable cell
            % array to be used as name value pairs
            
            obj.functionInputs = functionInputs;
            optionalVariables  = obj.functionInputs{optVarIndex};
            
            if isequal(optionalVariables, obj.variableArray)
                % nothing changed (saves time and resources)
                return
            else
                % new optional inputs
                obj.clearDynamicProps()
                obj.variableArray = optionalVariables;
            end
            
            % make sure variables user defined are correct
            definedVariables = fields(obj.variableRules); % cell array of variables that have rules
            % indexing through user defined variables
            for ii = 1:2:length(optionalVariables)
                if any(contains(definedVariables, optionalVariables{ii}))
                    % user is defining a variable with set rules so need to
                    % check with applyRules before assigning
                    obj.applyRules(optionalVariables{ii}, optionalVariables{ii+1})
                    % create and assign the variable
                    obj.addprop(optionalVariables{ii});
                    obj.(optionalVariables{ii}) = optionalVariables{ii+1};
                else
                    % user has given a new variable not in rule set so
                    % should ask if user wants to create a rule for it
                    obj.unknownVariable(optionalVariables{ii}, optionalVariables{ii+1});
                end
            end
            
            % check to see if any variables were not defined by user
            for ii = 1:length(definedVariables)
                if ~any(contains(obj.variableNames, definedVariables{ii}))
                    obj.setDefualt(definedVariables{ii})
                end
            end
        end
        
        function applyRules(obj, name, value)
            %APPLYRULES primarily just checks the type for now
            rule = obj.variableRules.(name);
            try
                obj.checkType(rule.type, value, name)
            catch ME
                % safeguard incase checkType fails
                obj.err(0,'Unable to check value type for optional input!',ME)
            end
        end
        
        function checkType(obj, type, value, name)
            %CHECKTYPE based on the type passed checks the value to see if there are
            % any issues and if so throws an error immediately
            switch type
                case 'any'
                    % always passes
                    
                case 'charCell'
                    % value needs to be a cell array containing only character arrays
                    if iscell(value)
                        if ~all(cellfun(@(x) ischar(x), value))
                            obj.err(0,['Error setting [' name '] for function [' obj.functionName ']' newline ...
                                'Expected a cell array of character arrays as input. Ensure input is correct.'])
                        end
                    else
                        obj.err(0,['Error setting [' name '] for function [' obj.functionName ']' newline ...
                                'Expected a cell array of character arrays as input. Ensure input is correct.'])
                    end
                    
                case 'method'
                    % value is either char/string or function handle to be used a 'method' in a switch if block
                    if ~(isa(value, 'function_handle') || ischar(value) || isstring(value))
                        obj.err(0,['Error setting [' name '] for function [' obj.functionName ']' newline ...
                                'Expected a method input which should be a function handle or character/string. Ensure input is correct.'])
                    end
                    
                otherwise
                    % basic attempt to see if type is just a standard matlab type
                    if ~isa(value, type)
                       obj.err(0,['Error setting [' name '] for function [' obj.functionName ']' newline ...
                                'Expected a [' type '] type as input. Ensure input is correct.'])
                    end
            end
        end
        
        function setDefualt(obj, name)
            %SETDEFUALT will try to set the defualt value for a given
            % property if it was not assigned (except for required)
            
            % checks to see if property is set to required
            if ischar(obj.variableRules.(name).defualt) && isequal(obj.variableRules.(name).defualt, 'required')
                obj.err(0,['Error parsing input for [' obj.functionName ']' newline ...
                           'Input [' name '] is required. Ensure to assign it as a name value pair before calling.'])
            end
            
            % attempts to add the property and assign defualt value
            obj.addprop(name);
            if isa(obj.variableRules.(name).defualt, 'function_handle') && ~(isequal(obj.variableRules.(name).type, 'function_handle') || isequal(obj.variableRules.(name).type, 'method'))
                % attempts to dynamically set the property value using an anonymous function 
                try
                    obj.(name) = obj.variableRules.(name).defualt(obj.functionInputs{:}, obj);
                catch ME
                    obj.err(0,['Error setting defualt value for [' name '] in [' obj.functionName ']' newline ...
                               'Ensure ruleSet is properly created and function is being called with all arguments set.'], ME)
                end
            else
                % simple constant assignment
                obj.(name) = obj.variableRules.(name).defualt;
            end
        end
        
        %% functions related to dynamic properties
        function names = get.variableNames(obj)
            % Find dynamic properties which are the optional variable names
            names = properties(obj);
            ii = 1;
            while ii < numel(names)+1
                prop = findprop(obj,names{ii});
                if ~isa(prop,'meta.DynamicProperty')
                    names(ii) = [];
                else
                    ii = ii + 1;
                end
            end
        end
        
        function clearDynamicProps(obj)
            names = properties(obj);
            for ii = 1:numel(names)
                prop = findprop(obj,names{ii});
                if isa(prop,'meta.DynamicProperty')
                    obj.removeProp(names{ii})
                end
            end
        end
        
        function removeProp(obj, name)
            delete(findprop(obj, name))
        end
        
        function unknownVariable(obj, name, value)
            %UNKOWNVARIABLE call to create a new rule set for the name
            % value pair that is given
            
            unlockFigures() % possible modal figures will block this one
            
            % double check the rule has not already been made
            if isfield(obj.variableRules, name)
                disp('wait what really')
            else
                disp('ok continue')
            end
            
            % ask user if they want to create a new rule set
            answer = questdlg(['New variable [' name '] found would you like to create a new rule for this input?']);
            switch answer
                case 'Yes'
                    % ask user to generate the rule set
                    answer = inputdlg({'Insert short description:', 'Insert expected type:', 'Insert defualt value:'}, ...
                                       'Create New Optional Variable', [1 100], ...
                                      {name, 'any', '''required'''});
                    if isempty(answer)
                        % they pressed cancel
                        error('User requested to cancel running of the script.')
                    end
                    obj.variableRules(1).(name).description = answer{1};
                    obj.variableRules(1).(name).type        = answer{2};
                    try
                        % safely try to test the users defualt value
                        obj.variableRules(1).(name).defualt = eval(answer{3});
                    catch
                        %throw error
                    end
                    
                    % if checkError calls this method need to do some extra steps
                    try
                        isRequired = isequal(obj.variableRules(1).(name).defualt, 'required')
                    catch % some things just dont work :(
                        isRequired = false;
                    end
                    if isRequired && nargin < 3
                        % user is making the new variable required and thus
                        % needs to enter a one time value for this instance
                        answer = inputdlg({'Defualt value is set to required, thus for this instance only please give a value to be used. In the future, you will be required to insert a value in name-pair input.'}, ...
                                          'Required Value', [1 100]);
                        if isempty(answer)
                            % they pressed cancel
                        	error('User requested to cancel running of the script.')
                        end
                        % add the require variable for now
                        obj.addprop(name);
                        try
                            % safely try to test the users required value
                            obj.(name) = eval(answer{1});
                        catch
                            %throw error
                        end
                    elseif nargin < 3
                        % they didn't set the value to required but a gave
                        % a defualt that should be set now 
                        obj.setDefualt(name)
                    end
                    obj.saveRuleSet();
                    
                case 'No'
                    obj.addprop(name);
                    obj.(name) = value;
                    
                otherwise
                    % they pressed cancel or something
                    error('User requested to cancel running of the script.')
            end
        end
        
        function pass = checkError(obj, ME)
            %CHECKERROR looks at the given error to see if it is the result
            % of this class lacking a specific property and if so it will
            % ask user to build a new rule for that property
            
            if isequal(ME.identifier, 'MATLAB:noSuchMethodOrField')
                % optVars might be missing property
                names = regexp(ME.message, "'.+?'", 'match');
                if isequal(names{2}(2:end-1), 'OptionalVariablesParser')
                    % optVars is missing names{1}(2:end-1) property
                    obj.unknownVariable(names{1}(2:end-1))
                    pass = true;
                    return
                end
            end
            
            pass = false; % not an OptionalVariablesParser issue
        end
        
        function saveRuleSet(obj)
            ruleSet = obj.variableRules;
            save(obj.configPath,'ruleSet')
        end
    end
    
    methods (Static)
        function getOptions(functionHandle)
            % outputs the rule set for a specific given function
            [folder, file, ~] = fileparts(which(func2str(functionHandle)));
            load(fullfile(folder, [file '.mat']),'ruleSet')
            
            file = which(func2str(functionHandle));
            hyperlinkFunction = sprintf('matlab: open( ''%s'' )', file);
            disp([newline ...
                  '   <a href="' hyperlinkFunction '">' func2str(functionHandle) '</a>  ' newline ...
                  ' ---------------------------' ...
                  newline])
            
            output = table("description",        "type",     {'value'},  ...
          'VariableNames',{'description','expectedType','defualtValue'}, ...
          'RowNames',     {'temp'});
            for field = fields(ruleSet)'
                addRow = table(string(ruleSet.(field{1}).description),   ...
                               string(ruleSet.(field{1}).type),          ...
                               {ruleSet.(field{1}).defualt},             ...
                               'VariableNames',{'description','expectedType','defualtValue'});
                 output(end+1,:) = addRow; %#ok<AGROW>
                 output.Row(end) = field;
            end
            output(1,:) = [];
            disp(output)
        end
        
        function copyOptions(inFun, outFun)
            %COPYOPTIONS takes the options from inFun and applies them to outFun
            
            x = OptionalVariablesParser( inFun);
            y = OptionalVariablesParser(outFun);
            
            y.variableRules = x.variableRules;
            
            y.saveRuleSet()
        end
    end
    
    methods (Access = protected)
        function s = getFooter(obj)
            % fancy pointles display to show the parsing rules
            output = table({'currentValue'},"description",        "type",     {'value'},  ...
          'VariableNames',{  'currentValue','description','expectedType','defualtValue'}, ...
          'RowNames',     {'temp'});
            for field = fields(obj.variableRules)'
                try 
                    currentValue = obj.(field{1});
                catch
                    currentValue = 'N\A';
                end
                addRow = table({currentValue},                                            ...
                               string(obj.variableRules.(field{1}).description),          ...
                               string(obj.variableRules.(field{1}).type),                 ...
                               {obj.variableRules.(field{1}).defualt},                    ...
                               'VariableNames',{'currentValue','description','expectedType','defualtValue'});
                 output(end+1,:) = addRow; %#ok<AGROW>
                 output.Row(end) = field;
            end
            output(1,:) = []; %#ok<NASGU>
            s = [' ---------------------------' newline evalc('disp(output)')];
        end
    end
end