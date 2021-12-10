function ax = compactSubplot(m,n,p,r)
%COMPACTSUBPLOT does the same as subplot with m,n,p arguments but reduces
% the gaps between the plots by the reduction given (r)
% given r=1 will be the same as subplot and r=0 will result in no gap
% between adjacent plots

ax = subplot(m,n,p);

startHeight = 0.1100;
startWidth  = 0.1300;
plotHeight  = 0.8150;
plotWidth   = 0.7750;
height2gap  = 0.1947;
width2gap   = 0.1580;

rowHeight = plotHeight / (m + 2*(m-1) * height2gap*r);
rowGap = rowHeight * height2gap * r;

colWidth = plotWidth / (n + 2*(n-1) * width2gap*r);
colGap = colWidth * width2gap * r;

x = mod(p,n);
if ~x
    x = n;
end
y = floor((p-x)/n)+1;

xPos = startWidth + colWidth*(x-1) + 2*(x-1)*colGap;
yPos = startHeight + plotHeight - rowHeight*y - 2*(y-1)*rowGap;

ax.Position = [xPos, yPos, colWidth, rowHeight];
ax.UserData = p;