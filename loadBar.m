classdef loadBar < handle
    %LOADBAR custom version of waitbar that has greater options and handling
    % add comments, white space, and clean up

    properties (Access = public)
        fig             % (1,1) matlab.ui.Figure this does not work as expected
        progress          (1,1) double = 0
        message           (1,1) string = "Loading ..."
        UserData          % left open for misc purposes
    end

    properties (Dependent)
        estimatedTimeLeft (1,1) double % in seconds
    end

    properties (Access = private)
        progressMap       (1,:) cell = {@(x) x * range([0 1]) + 0}
        ticVal            (1,1) uint64 = tic

        parallelIter      (1,1) double = 0
        parallelTotalRuns (1,1) double = 1
        parallelQueue     (1,1) parallel.pool.DataQueue = parallel.pool.DataQueue
        parallelMessage   (1,1) string = "Parallel Est Left: {timeRemaining} seconds"
    end

    methods
        function obj = loadBar(progress, message)
            arguments
                progress (1,1) double = 0
                message  (1,1) string = "Loading ..."
            end
            if progress<0
                progress = 0;
            elseif progress>1
                progress = 1;
            end
            obj.fig = waitbar(progress,message,"Visible","off");
            if getpref("LoadBar","Toggle",true)
                obj.fig.Visible = "on";
            else
                close(obj.fig)
            end
            obj.progress = progress;
            obj.message = message;
            obj.resetTimeLeft()
        end

        function update(obj, prog, mess)
            arguments
                obj  % this
                prog (1,1) double
                mess (1,1) string
            end
            if prog<0
                prog = 0;
            elseif prog>1
                prog = 1;
            end
            obj.progress = prog;
            obj.message = mess;
        end

        function sleep(obj)
            if isvalid(obj.fig)
                obj.fig.Visible = 'off';
            end
        end

        function updateFig(obj)
            if isvalid(obj.fig)
                obj.fig.Visible = 'on';
                waitbar(obj.progress, obj.fig, obj.message)
            end
        end

        function close(obj)
            if isvalid(obj.fig)
                close(obj.fig)
            end
        end

        function delete(obj)
            close(obj)
        end
        
        function increaseDepth(obj, newMax)
            arguments
                obj %this
                newMax (1,1) double = 1
            end
            if newMax < obj.progress
                newMax = obj.progress;
            elseif newMax > 1
                newMax = 1;
            end
            limits = [obj.progress, obj.progressMap{end}(newMax)];
            obj.progressMap{end+1} = @(x) x * range(limits) + limits(1);
        end

        function decreaseDepth(obj)
            if length(obj.progressMap) > 1
                obj.progressMap(end) = [];
            end
        end

        function set.progress(obj, val)
            arguments
                obj  % this
                val (1,1) double
            end
            if val<0
                val = 0;
            elseif val>1
                val = 1;
            end
            val = obj.progressMap{end}(val); %#ok<MCSUP>
            if abs(obj.progress - val) >= 0.01 % don't update if not large enough shift
                obj.progress = val;
                obj.updateFig()
            end
        end

        function set.message(obj, val)
            arguments
                obj  % this
                val (1,1) string
            end
            obj.message = val;
            obj.updateFig()
        end
    
        function resetTimeLeft(obj)
            obj.ticVal = tic;
        end

        function val = get.estimatedTimeLeft(obj)
            val = round(toc(obj.ticVal) / obj.progress - toc(obj.ticVal));
        end
    end

    methods % Parallel Processing Feedback
        function initializeParallelFeedback(obj, totalRuns)
            arguments
                obj % this loadBar
                totalRuns (1,1) double {mustBePositive, mustBeInteger}
            end

            obj.parallelIter = 0;
            obj.parallelTotalRuns = totalRuns;
            afterEach(obj.parallelQueue, @(~) obj.parallelAfterEach());
        end

        function updateParallel(obj, iter, message)
            if nargin > 2
                obj.parallelMessage = message;
            end
            send(obj.parallelQueue, iter)
        end

        function parallelAfterEach(obj) % should be private
            obj.parallelIter = obj.parallelIter + 1;
            obj.progress = obj.parallelIter/ obj.parallelTotalRuns;
            obj.message = strrep(obj.parallelMessage, "{timeRemaining}", string(obj.estimatedTimeLeft));
        end
    end

    methods (Static)
        function prevVal = toggle(val)
            if nargin < 1
                val = ~getpref("LoadBar","Toggle",true);
            end
            if ~islogical(val)
                if ~isnumeric(val)
                    val = strcmpi(val,"on");
                else
                    val = logical(val);
                end
            end
            prevVal = getpref("LoadBar","Toggle",true);
            setpref("LoadBar","Toggle",val)
        end
    end
end