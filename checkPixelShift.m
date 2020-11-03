% Script to check pixel shift in Alexa channel do to removal of dichroic
% mirror on scope 5. Using dftregistration function from https://www.mathworks.com/matlabcentral/fileexchange/18401-efficient-subpixel-image-registration-by-cross-correlation
%to register images. 

% inDirs = {'/Volumes/Blemert12/20191223_TM31_PLXtimecourse/plate4/wellA1/round2/onTarget', ...
%     '/Volumes/Blemert12/20191223_TM31_PLXtimecourse/plate4/wellA2/round2/onTarget', ...
%     '/Volumes/Blemert12/20191223_TM31_PLXtimecourse/plate4/wellB2/round2/onTarget', ...
%     '/Volumes/Blemert12/20191223_TM31_PLXtimecourse/plate5/wellA3/round2/onTarget', ...
%     '/Volumes/Blemert12/20200622_TM31/plate6/wellB1/round2/onTarget', ...
%     '/Volumes/Blemert12/20200622_TM31/plate6/wellB2/round2/onTarget', ...
%     '/Volumes/Blemert12/20200622_TM31/plate6/wellB3/round2/onTarget', ...
%     '/Volumes/Blemert12/20200622_TM31/plate6/wellA3/round2/offTarget'};

inDirs = {'/Volumes/Blemert12/20200622_TM31/plate6/wellB1/round2/onTarget', ...
    '/Volumes/Blemert12/20200622_TM31/plate6/wellB2/round2/onTarget', ...
    '/Volumes/Blemert12/20200622_TM31/plate6/wellB3/round2/onTarget', ...
    '/Volumes/Blemert12/20200622_TM31/plate6/wellA3/round2/offTarget'};
refPlane = 6;
shifts = struct();

startDir = pwd();
for i = 1:numel(inDirs)
    cd(inDirs{i})
    alexaFiles = dir('alexa*.tif');
    alexaFiles = {alexaFiles.name};
    alexaShift = cell(1, numel(alexaFiles));
    [alexaShift{:}] = deal([0,0]);
    for ii = 1:numel(alexaFiles)
    	alexaFile = readmm(sprintf('alexa%03d.tif', ii));
        alexaStack = im2double(alexaFile.imagedata);

        tmrFile = readmm(sprintf('tmr%03d.tif', ii));
        tmrStack = im2double(tmrFile.imagedata);

        output = dftregistration(fft2(tmrStack(:,:,refPlane)),fft2(alexaStack(:,:,refPlane)),1);
        alexaShift{ii} = output(3:4);
    end
    shifts.(sprintf('well%d',i)) = alexaShift;
    cd(startDir)
end