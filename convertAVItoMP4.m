function [vw, vr] = convertAVItoMP4(filePath)

arguments
    filePath (1,1) string {mustBeFile} = uigetfile("*.avi")
end

vr = VideoReader(filePath);
vw = VideoWriter(rename(filePath), "MPEG-4");
vw.FrameRate = vr.FrameRate;
open(vw)

for ii = 1:length(vr)
    vw.writeVideo(vr.read(ii))
end

close(vw)

function newName = rename(oldName)
    [folder,file,~] = fileparts(oldName);
    newName = fullfile(folder, strcat(file,".mp4"));
end

end