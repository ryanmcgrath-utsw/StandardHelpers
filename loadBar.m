classdef loadBar < handle
    %TODO add comments, white space, and clean up

    properties
        fig     %(1,1) matlab.ui.Figure this does not work as expected
        progress (1,1) double = 0
        message  (1,1) string = "Loading ..."
        UserData % open for misc purposes
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
            obj.fig = waitbar(progress,message);
            obj.progress = progress;
            obj.message = message;
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

        function delete(obj)
            if isvalid(obj.fig)
                close(obj.fig)
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
            obj.progress = val;
            obj.updateFig()
        end

        function set.message(obj, val)
            arguments
                obj  % this
                val (1,1) string
            end
            obj.message = val;
            obj.updateFig()
        end
    end
end