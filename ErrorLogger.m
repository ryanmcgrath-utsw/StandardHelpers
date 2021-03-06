classdef ErrorLogger < handle & matlab.mixin.CustomDisplay
    %ERRORLOGGER handle superclass that allow classes to log error using
    % obj.err function with some added features
    properties
        loggedErrors = 0
    end
        
    properties (Hidden)
        errorMsgs    = {}
        errorCodes   = {}
    end
    
    methods
        function err(obj, suppress, msg, code)
            %ERR generates the error needs suppress and either msg or code
            
            % parse input
            if nargin < 2
                suppress = 0;
            end
            if nargin < 3
                msg = '';
            end
            if nargin < 4 && isempty(msg)
                msg = 'Undefined Error!';
            end
            
            % add to log
            obj.loggedErrors = obj.loggedErrors + 1;
            
            if isempty(msg)
                obj.errorMsgs{end+1} = code.message;
            else
                obj.errorMsgs{end+1} = msg;
            end
            
            errCode = MException(strrep(['ErrorLogger:' class(obj)],'.',':'), msg);
            if nargin > 3
                errCode = addCause(errCode, code);
            end 
            try % this will add the stack property in the error code
                throwAsCaller(errCode)
            catch ME
                obj.errorCodes{end+1} = ME;
            end
            
            if ~suppress
                throwAsCaller(errCode)
            end
            
            notify(obj,'ErrorLogged')
        end
        
        function report = getLatestError(obj)
            %GETLATESTERROR returns a report of the latest error added
            report = getReport(obj.errorCodes{end});
        end
        
        function clearErrors(obj)
            %CLEARERRORS reset all the logged errors
            obj.loggedErrors =  0;
            obj.errorMsgs    = {};
            obj.errorCodes   = {};
        end
        
        function compileAndThrowError(obj, msg)
            %COMPILEANDTHROWERROR combines all errors into one large
            % exception and throws that as a critical drror
            if nargin < 2
                msg = 'Critical Errors Detected!';
            end
            finalError = MException([class(obj) ':CriticalError'], msg);
            for err = obj.errorCodes
                finalError = addCause(finalError, err{1});
            end
            throwAsCaller(finalError)
        end     
    end
    
    methods (Access = protected)
        function s = getFooter(obj)
            if numel(obj) == 1 && obj.loggedErrors
                s = [' ---------------------------' newline ...
                     ' Most Recent Error: ' newline ...
                     ' ' getReport(obj.errorCodes{end})];
            else
                s = '';
            end
        end
    end
    
    events
        ErrorLogged % gets notified when a error has been logged
    end
end