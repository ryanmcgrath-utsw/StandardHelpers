total = input("Give total time worked: ");
start = input("Give start time today (HH:MM): ","s"); % assume 24 hour time
start = datetime(start, "InputFormat", "HH:mm");
start = round(hours(start - datetime("today"))*4)/4;
start = datetime("today") + hours(start);
if total > 50
    target = 80;
else
    target = 40;
end
need = hours(target - total);
if need > hours(5.75)
    need = need + hours(1);
end
disp("Set alarm to end work at: " + datestr(start+need, "HH:MM AM"))