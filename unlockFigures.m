function unlockFigures()
% unsets all modal figures from being modal
figs = findall(groot,'Type','figure');
for ii = 1:length(figs)
    if isequal(figs(ii).WindowStyle, 'modal')
        figs(ii).WindowStyle = 'normal';
    end
end
end