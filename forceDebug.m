function forceDebug()
%FOCEDEBUG creates a breakpoint at the very next line of code that will be
% cleared by a timer

% prepare
stack = dbstack;

% create stop point
dbstop('in',stack(2).file, 'at',num2str(stack(2).line+1))

% create timer
t = timer;
t.StartDelay = 1;
t.TimerFcn = @(~,~) dbclear('in',stack(2).file, 'at',num2str(stack(2).line+1));
t.StopFcn = @(tim,~) delete(tim);
t.ErrorFcn = @(tim,~) delete(tim);

% start timer to clear breakpoint
start(t)
end