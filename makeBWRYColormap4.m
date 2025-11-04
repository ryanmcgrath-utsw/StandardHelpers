function M = makeBWRColormap4(low,zero,high,yellowHigh)
%MAKEBWRCOLORMAP4 Blue–white–red–yellow colormap.
%   M = MAKEBWRCOLORMAP4(HIGH,LOW,ZERO,YELLOWHIGH) returns a 255×3 RGB
%   colormap running:
%       low        → zero : blue  → white
%       zero       → high : white → red
%       high → yellowHigh : red   → yellow
%   Values above yellowHigh remain pure yellow.

arguments
    low         (1,1) double
    zero        (1,1) double
    high        (1,1) double
    yellowHigh  (1,1) double {mustBeGreaterThan(yellowHigh,high)}
end

% -------------------------------------------------------------------------
% Position of the "zero" color (white) and the start of the yellow ramp
% -------------------------------------------------------------------------
totalSpan   = yellowHigh - low;
whiteFrac   = (zero - low) / totalSpan;     % fraction of range at zero
highFrac    = (high - low) / totalSpan;     % fraction at start of yellow

idxWhite    = max(1, min(255, round(255 * whiteFrac)));
idxHigh     = max(1, min(255, round(255 * highFrac)));

% Base blue–white–red map (red at top)
baseMap = [ ...
    178  24  43;   % deep red
    214  96  77;
    244 165 130;
    253 219 199;
    247 247 247;   % white
    209 229 240;
    146 197 222;
     67 147 195;
     33 102 172];  % deep blue
iWhite    = 5;                       % white row index
nBase     = size(baseMap,1);
yellow    = [255 255   0];

% -------------------------------------------------------------------------
% Build the full 255×3 map
% -------------------------------------------------------------------------
M = zeros(255,3);

for k = 1:3
    % blue → white
    M(1:idxWhite,k) = interp1( ...
        linspace(1,idxWhite,nBase - iWhite + 1), ...
        baseMap(end:-1:iWhite,k), ...
        1:idxWhite);

    % white → red
    M(idxWhite:idxHigh,k) = interp1( ...
        linspace(idxWhite,idxHigh,iWhite), ...
        baseMap(iWhite:-1:1,k), ...
        idxWhite:idxHigh);

    % red → yellow
    M(idxHigh:255,k) = interp1( ...
        [idxHigh 255], ...
        [baseMap(1,k) yellow(k)], ...
        idxHigh:255);
end

M = M ./ 255;
end
