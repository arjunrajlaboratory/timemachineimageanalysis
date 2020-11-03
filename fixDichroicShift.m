% Script to translate image stacks to correct for pixel shift 
% due to dichroic mirror

inDir = '/Users/benjaminemert/Dropbox (RajLab)/Shared_Ben/timeMachine/rawdata/TM31CarbonCopy/plate1/wellB3/round2/offTarget';
cd(inDir)
outDir = 'fixedShift';
if ~exist(outDir, 'dir')
    mkdir(outDir)
end
channelsToShift = {'alexa'};
channelsToCopy = {'dapi', 'trans', 'tmr', 'gfp'};
%channelsToCopy = {};
stacks = 4;
shift = [6, -1];

%%
for i = 1:stacks
    for ii = 1:numel(channelsToShift)
        image = readmm(sprintf('%s%03d.tif', channelsToShift{ii}, i));
        imageStack = image.imagedata;
        shiftedStack = imtranslate(imageStack, shift);
        imwrite(shiftedStack(:,:,1), fullfile(outDir, sprintf('%s%03d.tif', channelsToShift{ii}, i)))
        for iii = 2:size(shiftedStack, 3)
            imwrite(shiftedStack(:,:,iii), fullfile(outDir, sprintf('%s%03d.tif', channelsToShift{ii}, i)), 'writemode', 'append')
        end
    end
    for iv = 1:numel(channelsToCopy)
        copyfile(sprintf('%s%03d.tif', channelsToCopy{iv}, i), outDir)
    end
end
save(fullfile(outDir, 'shift.mat'), 'shift')
%%
alexaImg = readmm('alexa002.tif');
alexaStack = alexaImg.imagedata;
alexaStackShifted = imtranslate(alexaStack, [6, -1], 'FillValues', 0);
dapiImg = readmm('dapi002.tif');
dapiStack = dapiImg.imagedata;

%%
overlay = cat(3, alexaStack(:,:,6), alexaStack(:,:,6), alexaStack(:,:,6) + dapiStack(:,:,6)); 
%%
overlay2 = cat(3, alexaStackShifted(:,:,6), alexaStackShifted(:,:,6), alexaStackShifted(:,:,6) + dapiStack(:,:,6)); 

