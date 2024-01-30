function timerHandle = createTimer(timeDuration, message, varargin)
%CREATETIMER creates and starts a timer that will display a given message
% after the given time duration

arguments
    timeDuration (1,1) duration = minute(1) %#ok<TMNUT>
    message (1,1) string = "Your timer has expired!"
end

arguments (Repeating)
    varargin
end
    

otherTimers = timerfind('Tag', 'createTimer'); % gets all other timers that exist
timerHandle = timer(); % creates a timer for this task

% figure out what other timers are running
otherNumbers = nan(1,length(otherTimers));
for ii = 1:length(otherTimers)
    ot = otherTimers(ii);
    otherNumbers(ii) = str2double(regexp(ot.Name, '[0-9]+', 'match', 'once'));
end

% make sure this timer is unique
timerNumber = 1;
otherNumbers = sort(otherNumbers, 'ascend');
for on = otherNumbers
    if timerNumber==on, timerNumber=timerNumber+1; end
end

% basic labeling
timerHandle.Name = sprintf("UserTimer-%i", timerNumber);
timerHandle.Tag = 'createTimer';

% timer only executes once after timeDuration
timerHandle.TasksToExecute = 1;
timerHandle.ExecutionMode = 'singleShot';
timerHandle.StartDelay = seconds(timeDuration);

% UserData to share info between timer funcitons
timerHandle.UserData.message = sprintf(message, varargin{:});
timerHandle.UserData.duration = timeDuration;
timerHandle.UserData.timerName = sprintf("%s [%s]",timerHandle.Name, timeDuration);

% timer functions see further below for code
timerHandle.StartFcn = @startTimer;
timerHandle.TimerFcn = @timesUp;
timerHandle.StopFcn  = @earlyEnd;
timerHandle.ErrorFcn = @timerError;

start(timerHandle) % start the timer
end

%% Timer Functions
function startTimer(this, ~)
% called when timer is started
this.UserData.ticToc = tic;
this.UserData.complete = false;
end

function timesUp(this,~)
% called when time is up
msg = sprintf("%s >> %s", datestr(now), this.UserData.message);
msgbox(msg, this.UserData.timerName, 'help')
this.UserData.complete = true;
end

function earlyEnd(this,~)
% called when timer is stopped prematurely or after @timesUp
if ~this.UserData.complete
    timeRemaing = this.UserData.duration - seconds(toc(this.UserData.ticToc));
    msg = sprintf("%s >> Timer ended early with [%s] time remaining.", datestr(now), timeRemaing);
    msgbox(msg, this.UserData.timerName, 'warn')
end
end

function timerError(this,~)
% called if there is an error
msg = sprintf("%s || >> Unkonwn Error Encountered!", datestr(now));
msgbox(msg, this.UserData.timerName, 'error')
end