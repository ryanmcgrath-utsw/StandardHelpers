function [lineHandle, patchHandle] = plotCI(x, data, opts, lineOpts)

arguments
    x (:,:) double
    data (:,:) double = [];
    
    opts.Confidence (1,1) double = 95
    opts.nBoot (1,1) double = 1000
    opts.bootFun (1,1) function_handle = @mean
    
    lineOpts.?matlab.graphics.chart.primitive.Line
end

if isempty(data)
    data = x;
    x = 1:size(data,2);
elseif all(size(x) > 1)
    error("X-Value (first argument for plotCI) must be vector if data given.")
elseif size(x,1) > 1
    x = x';
end

lineOpts = namedargs2cell(lineOpts);
lineHandle = plot(x,mean(data), lineOpts{:});
ci = bootci(opts.nBoot, opts.bootFun, data);
patchHandle = patch([x x(end:-1:1)], [ci(1,:) ci(2,end:-1:1)], lineHandle.Color, ...
              "FaceAlpha",0.3, "EdgeAlpha",0, "HandleVisibility","off");