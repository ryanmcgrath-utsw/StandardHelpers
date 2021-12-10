function clearWaitbars()
%CLEARWAITBARS call to delete each waitbar figure
% warning: doesn't delete handles and may not call the close request function

a = findall(groot,'Type','figure');
for ii = 1:length(a)
    fig = a(ii);
    if isequal(fig.Tag,'TMWWaitbar')
        delete(fig)
    end
end

end