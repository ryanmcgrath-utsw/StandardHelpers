function [pow, freq] = simpleFFT(signal, time)
%SIMPLEFFT see FFT help page as it pretty much does that up to the point of
% the plot of the single sided power spectra

% input validation
if isa(time, 'duration')
    time = seconds(time);
end

% get the frequency
Fs = 1/mean(diff(time));
L = length(time);
freq = Fs*(0:(L/2))/L;
% get power out of the weird complex output of fft
Y = fft(signal);
pow = abs(Y/L);
pow = pow(1:floor(L/2)+1);
pow(2:end-1) = 2*pow(2:end-1);
end