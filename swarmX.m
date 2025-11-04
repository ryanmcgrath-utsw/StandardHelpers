function x = swarmX(y,sz)
%SWARMX creates x values centered at zero that are spaced by distance sz

arguments
    y  (:,1) double
    sz (1,1) double {mustBePositive} = 1
end

[y,orgIdx] = sort(y,"ascend");
[~,sort2org] = sort(orgIdx);

n = length(y);
x = nan(n,1);
x(1) = 0;

for ii = 2:n
    idx = y(ii)-y < sz & (ii > 1:n)';
    if ~any(idx), x(ii) = 0; continue, end
    relX = x(idx);
    relY = y(idx);

    xDist = sqrt(sz^2 - (y(ii) - relY).^2);

    side = sign(relX);
    if all(side>=0)
        [x(ii),idx] = min(relX);
        x(ii) = x(ii) - xDist(idx);
        continue
    elseif all(side<=0)
        [x(ii),idx] = max(relX);
        x(ii) = x(ii) + xDist(idx);
        continue
    end

    [temp,idx] = sort(relX);
    threshs = [temp-xDist(idx), temp+xDist(idx)];

    for jj = 1:size(threshs,1)
        boundHigh = threshs(jj,2);
        boundLow  = threshs(jj,1);
        validLower  = threshs(:,1) <  boundLow & boundLow  < threshs(:,2);
        validHigher = threshs(:,1) < boundHigh & boundHigh < threshs(:,2);
        if any(validLower)
            threshs(jj,1)  = min(threshs(validLower,1));
        else
            threshs(jj,1) = boundLow;
        end
        if any(validHigher)
            threshs(jj,2) = max(threshs(validHigher,2));
        else
            threshs(jj,2) = boundHigh;
        end
    end

    closeX = absMin(threshs(1,1), threshs(end,2));
    for jj = 1:size(threshs,1)-1
        if threshs(jj,2) < threshs(jj+1,1)
            if sign(threshs(jj,2)) == sign(threshs(jj+1,1))
                possX = absMin(threshs(jj+1,1), threshs(jj,2));
                closeX = absMin(possX, closeX);
                if sign(closeX)==1 && closeX < threshs(jj+1,2)
                    break
                end
            else
                closeX = 0;
                break
            end
        end
    end

    x(ii) = closeX;
end

x = x(sort2org);

    function v = absMin(x,y)
        if abs(x) > abs(y)
            v = y;
        else
            v = x;
        end
    end
end

% Old method (Faster but less optimal)
% function x = strat2(y,sz)
%     % function x = gptSwarm(y,sz)
%     n = numel(y);
%     x = nan(n,1);
%     x(1) = 0;
%
%     % Precompute pairwise vertical distances for reuse
%     for ii = 2:n
%         % Limit search to a window instead of scanning whole vector
%         idx = (y > y(ii) - sz) & (y < y(ii) + sz);
%         idx(ii) = false; % remove self
%         relX = x(idx);
%
%         % Skip if no neighbors placed yet
%         validMask = ~isnan(relX);
%         if ~any(validMask)
%             x(ii) = 0;
%             continue
%         end
%
%         relX = relX(validMask);
%         relY = y(idx);
%         relY = relY(validMask);
%
%         % Compute left boundary
%         [farX, farIdx] = min(relX);
%         yDist = y(ii) - relY(farIdx);
%         leftX = farX - sqrt(sz^2 - yDist^2);
%
%         % Compute right boundary
%         [farX, farIdx] = max(relX);
%         yDist = y(ii) - relY(farIdx);
%         rightX = farX + sqrt(sz^2 - yDist^2);
%
%         % Try candidates without recomputing too much
%         jjVals = leftX + (0:99) * (rightX - leftX) / 99;
%         yDiffs = y(ii) - relY;
%         yDiffSq = yDiffs.^2;
%
%         % Vectorized distance check
%         validX = true(size(jjVals));
%         for k = 1:numel(relX)
%             distSq = (jjVals - relX(k)).^2 + yDiffSq(k);
%             validX = validX & (distSq >= (sz - 0.01).^2);
%             if ~any(validX)  % break early if no options left
%                 break
%             end
%         end
%
%         if any(validX)
%             % Choose the valid X with smallest absolute value
%             [~, minIdx] = min(abs(jjVals(validX)));
%             temp = jjVals(validX);
%             x(ii) = temp(minIdx);  % assign the chosen value
%         else
%             dist = sqrt((x(ii)-x(1:ii-1)).^2+(y(ii)-y(1:ii-1)).^2);
%             [val,idx] = min(dist);
%             if val-sz < -10^8
%                 disp(idx)
%             end
%             return
%         end
%
%         dist = sqrt((x(ii)-x(1:ii-1)).^2+(y(ii)-y(1:ii-1)).^2);
%         [val,idx] = min(dist);
%         if val-sz < -10^8
%             disp(idx)
%         end
%     end
% end
