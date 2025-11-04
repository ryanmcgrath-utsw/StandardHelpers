origin = "/Volumes/Fortress/FlyBehavior1/Pair_noLight3m_1sLight3m_fullLight3m";
final = "/Volumes/Padlock_DT_Rayn2/Data/FlyBehavior1/Pair_noLight3m_1sLight3m_fullLight3m";
files2move = struct2table(dir(fullfile(origin,"*","*","results","*.mat")));
for ff = 1:height(files2move)
    file = fullfile(files2move.folder{ff}, files2move.name{ff});
    newLoc = strrep(file, origin, final);
    if ~exist(newLoc, "file")
        if ~exist(fileparts(newLoc), "dir")
            mkdir(fileparts(newLoc))
        end
        copyfile(file, newLoc)
    end
end