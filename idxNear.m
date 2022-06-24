function array = idxNear(idx, range)
%IDXNEAR generates an index range around the given idx such that the
% function returns linear integer array of idx+/-range
%
% Example:
% array(idxNear(5,2)) == array(5-2:5+2) == array(3:7)

array = idx-range : idx+range;