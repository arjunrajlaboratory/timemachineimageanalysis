%Script to fix pixel shift across Z-stack. 
%Uses dftregistration function from https://www.mathworks.com/matlabcentral/fileexchange/18401-efficient-subpixel-image-registration-by-cross-correlation
%to register images. 
inDir = '.';
Nstacks = 5;
channels = {'trans', 'gfp', 'tmr', 'alexa', 'dapi'};
refPlane = 7;
outDir = 'fixedShift';

if ~exist(outDir, 'dir')
    mkdir(outDir)
end

%% 
cd(inDir)

for i =1:Nstacks
    dapiFile = readmm(sprintf('dapi%03d.tif', i));
    dapiStack = im2double(dapiFile.imagedata);
    shiftZ = cell(1, size(dapiStack, 3));
    [shiftZ{:}] = deal([0,0]);
    
    tmpImg = dapiStack(:,:,refPlane);
    for ii = refPlane:size(dapiStack, 3)-1
        output = dftregistration(fft2(tmpImg),fft2(dapiStack(:,:,ii+1)),1);
        shiftZ{ii+1} = output(3:4);
        tmpImg = imtranslate(dapiStack(:,:,ii+1), flip(output(3:4)), 'FillValues', 0);
    end
    ls
    tmpImg = dapiStack(:,:,refPlane);
    for ii = refPlane:-1:2
        output = dftregistration(fft2(tmpImg),fft2(dapiStack(:,:,ii-1)),1);
        shiftZ{ii-1} = output(3:4);
        tmpImg = imtranslate(dapiStack(:,:,ii-1), flip(output(3:4)), 'FillValues', 0);
    end
    
    for iii = 1:numel(channels)
        file = readmm(sprintf('%s%03d.tif',channels{iii},i));
        stack = file.imagedata;
        
        newImage = imtranslate(stack(:,:,1), flip(shiftZ{1}), 'FillValues', 0);
        imwrite(newImage, fullfile(outDir, sprintf('%s%03d.tif',channels{iii},i)))
        
        for iv = 2:size(stack, 3)
            newImage = imtranslate(stack(:,:,iv), flip(shiftZ{iv}), 'FillValues', 0);
            imwrite(newImage, fullfile(outDir, sprintf('%s%03d.tif',channels{iii},i)), 'writemode', 'append')
        end
    end
end

%% Now fix shift in alexa channel due to dichroic mirror
% use totalERK (tmr) vs. phosphoERK (alexa) signal in resistant cells
% (plates 4 and 5) to calculate shift. Apply to all plates. 
inDirs = {'/Volumes/Blemert12/20191223_TM31_PLXtimecourse/plate4/wellA1/round2/onTarget', ...
    '/Volumes/Blemert12/20191223_TM31_PLXtimecourse/plate4/wellA2/round2/onTarget', ...
    '/Volumes/Blemert12/20191223_TM31_PLXtimecourse/plate4/wellB2/round2/onTarget', ...
    '/Volumes/Blemert12/20191223_TM31_PLXtimecourse/plate5/wellA3/round2/onTarget', ...
    '/Volumes/Blemert12/20200622_TM31/plate6/wellB1/round2/onTarget', ...
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
%%
for i = 1:10
    alexaFile = readmm(sprintf('alexa%03d.tif', i));
    alexaStack = im2double(alexaFile.imagedata);

    tmrFile = readmm(sprintf('tmr%03d.tif', i));
    tmrStack = im2double(tmrFile.imagedata);

	output = dftregistration(fft2(tmrStack(:,:,refPlane)),fft2(alexaStack(:,:,refPlane)),1);
    alexaShift{i} = output(3:4);
end

%% Now translate alexa images
inDir = '.';
outDir = '.';
Nstacks = 10;
alexaShift = [];
for i = 1:Nstacks
    alexaFile = readmm(sprintf('alexa%03d.tif', i));
    alexaStack = alexaFile.imagedata;
    
    newStack = zeros(size(alexaStack), 'uint16');
    for ii = 1:size(alexaStack, 3)
        newStack(:,:,ii) = imtranslate(alexaStack(:,:,ii), alexaShift, 'FillValues', 0);
    end
    
    imwrite(newStack(:,:,1), fullfile(outDir, sprintf('alexa%03d.tif',i)))
        
    for iii = 2:size(newStack, 3)
        imwrite(newStack(:,:,iii), fullfile(outDir, sprintf('alexa%03d.tif',i)), 'writemode', 'append')
    end
end

%%
alexaFile = readmm('alexa001.tif');
alexaStack = im2double(alexaFile.imagedata);

tmrFile = readmm('tmr001.tif');
tmrStack = im2double(tmrFile.imagedata);

test = dftregistration(fft2(tmrStack(:,:,7)),fft2(alexaStack(:,:,7)),1);


outDir = '.';

if ~exist(outDir, 'dir')
    mkdir(outDir)
end

%%


for i = 1:Nstacks
    
    
end
%%
dapiFile = readmm(sprintf('dapi%03d.tif', 1));
dapiStack = im2double(dapiFile.imagedata);
shiftZ = cell(1, size(dapiStack, 3));
[shiftZ{:}] = deal([0,0]);

tmpImg = dapiStack(:,:,refPlane);
for ii = refPlane:size(dapiStack, 3)-1
    output = dftregistration(fft2(tmpImg),fft2(dapiStack(:,:,ii+1)),1);
    shiftZ{ii+1} = output(3:4);
    tmpImg = imtranslate(dapiStack(:,:,ii+1), flip(output(3:4)), 'FillValues', 0);
end

tmpImg = dapiStack(:,:,refPlane);
for ii = refPlane:-1:2
    output = dftregistration(fft2(tmpImg),fft2(dapiStack(:,:,ii-1)),1);
    shiftZ{ii-1} = output(3:4);
    tmpImg = imtranslate(dapiStack(:,:,ii-1), flip(output(3:4)), 'FillValues', 0);
end


%%

dapiFile = readmm(sprintf('dapi%03d.tif', 1));
dapiStack = im2double(dapiFile.imagedata);
shiftZ2 = cell(1, size(dapiStack, 3));

[optimizer, metric] = imregconfig('monomodal');

tmpImg = dapiStack(:,:,refPlane);

tform = imregtform(tmpImg, tmpImg, 'translation', optimizer, metric);
shiftZ2{refPlane} = tform;

tform = imregcorr(dapiStack(:,:,8), tmpImg, 'translation');
shiftZ2{refPlane} = tform;


for ii = refPlane:size(dapiStack, 3)-1
    tform = imregtform(dapiStack(:,:,ii+1), dapiStack(:,:,refPlane), 'translation', optimizer, metric);
    shiftZ2{ii+1} = tform;
    tmpImg = imwarp(dapiStack(:,:,ii+1), tform);
end

tmpImg = dapiStack(:,:,refPlane);
for ii = refPlane:-1:2
    tform = imregtform(dapiStack(:,:,ii-1), dapiStack(:,:,refPlane), 'translation', optimizer, metric);
    shiftZ2{ii-1} = tform;
    tmpImg = imwarp(dapiStack(:,:,ii-1), tform);
end
%%
i = 1;
outDir = 'fixedShift5';

if ~exist(outDir, 'dir')
    mkdir(outDir)
end

for iii = 1:numel(channels)
    file = readmm(sprintf('%s%03d.tif',channels{iii},i));
    stack = file.imagedata;

    newImage = imwarp(stack(:,:,1), shiftZ2{1});
    imwrite(newImage, fullfile(outDir, sprintf('%s%03d.tif',channels{iii},i)))

    for iv = 2:size(stack, 3)
        newImage = imwarp(stack(:,:,iv), shiftZ2{1});
        imwrite(newImage, fullfile(outDir, sprintf('%s%03d.tif',channels{iii},i)), 'writemode', 'append')
    end
end

%%
reader = bfGetReader(inFile);
omeMeta = reader.getMetadataStore();

imageCount = omeMeta.getImageCount();

refChannel = 3;
shiftedChannel = 4;

for i = 1
    reader.setSeries(i-1)

    stackSizeC = omeMeta.getPixelsSizeC(i-1).getValue(); % # of wavelength channels
    stackSizeZ = omeMeta.getPixelsSizeZ(i-1).getValue();

    dimX = omeMeta.getPixelsSizeX(0).getValue();
    dimY = omeMeta.getPixelsSizeY(0).getValue();

    imageHolder = zeros(dimY, dimX, stackSizeZ, stackSizeC);
    
    %Get pixel shift
    middleStack = round(stackSizeZ/2);
    iPlane = reader.getIndex(middleStack - 1, refChannel - 1, 0) + 1; 
    ref_fig  = bfGetPlane(reader, iPlane);
    
    iPlane = reader.getIndex(middleStack - 1, shiftedChannel - 1, 0) + 1; 
    shift_fig  = bfGetPlane(reader, iPlane);
    shift_fig_adjusted = imadjust(shift_fig, [980,10000]/65535, []);
    
    [movingPoints, fixedPoints] = cpselect(shift_fig_adjusted, scale(ref_fig), 'Wait', true);
    
    coordTransform = round(median(movingPoints-fixedPoints));
    
    shiftedRange 
end

%%
iPlane = reader.getIndex(7 - 1, 4 - 1, 0) + 1; 
alexaFig  = bfGetPlane(reader, iPlane);
alexaFigAdjusted = imadjust(alexaFig, [980,10000]/65535, []);

newImage = zeros(size(alexaFig), 'uint16');
newImage(:, 5:1024) = alexaFig(:, 1:1020);
newImageAdjusted = imadjust(newImage, [980,10000]/65535, []);

iPlane = reader.getIndex(7 - 1, 5 - 1, 0) + 1; 
dapiFig  = bfGetPlane(reader, iPlane);
dapiFig = scale(dapiFig);

overlay = cat(3, im2uint8(alexaFigAdjusted), im2uint8(alexaFigAdjusted), im2uint8(alexaFigAdjusted) + im2uint8(dapiFig));
overlay2 = cat(3, im2uint8(newImageAdjusted), im2uint8(newImageAdjusted), im2uint8(newImageAdjusted) + im2uint8(dapiFig));

imshow(overlay)