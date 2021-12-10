function stopwatch(t)
a = tic;
while toc(a)<t
    debug(seconds(toc(a)))
    pause(0.25)
end
end