function flies = initializeFlyTable(expFolder)
%INITIALIZEFLYTABLE generates a starting fly table to work off of given expFolder
% Works with the file system setup using fly folders following the
% fly_timestamp_genotype_{conditions}_sex that are placed in date folders
% that are under a single experiment folder

arguments
    expFolder (1,1) string {mustBeFolder} = uigetdir()
end

flies = dir(fullfile(expFolder,'*','fly*'));
flies = struct2table(flies);
flies = removevars(flies,["bytes","date","datenum","isdir"]);
flies(contains(flies.name,'NoFly'),:) = [];
flies.name = string(flies.name);
flies.folder = string(flies.folder);
info = split(flies.name,'_');
flies.timeStamp = datetime(info(:,2), "InputFormat", "yyyyMMdd'T'HHmmss");
flies.genotype  = categorical(info(:,3));
flies.condition = categorical(arrayfun(@(x) join(info(x,4:end-1),'_'), 1:height(flies))');
flies.sex       = categorical(info(:,end));
end
