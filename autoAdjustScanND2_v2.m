%% Script to load images from scan, adjust contrast then save to new directory. 
inDir = '/Volumes/Blemert4/20190413_timeMachine5/well2/scan_v3'; %directory containing scan files. 
%numImages = 4769; %dimensions of scan.
channel = 'alexa';
channelNumber = 1;
outDir  = fullfile(inDir, 'contrasted_v2'); %The name of the directory to place you stitched images.outFileName  - name of the output file. 
%imadjust_constrast = [0.016,0.032]; %Contrast inputs for input image. For 16-bit scale, divide intensity values by 65535 to get scale values between 0 and 1.
%% Make directory for stitch images
if ~exist(outDir, 'dir')
    mkdir(outDir)
end
%% Adjust each image in scan and save to outDir
imFiles = dir(fullfile(inDir, '*.nd2'));
imFiles = strcat(inDir, '/', {imFiles.name});
numImages = numel(imFiles);
for i = 2921:4:numImages
    fprintf('processing %d\n',i);
    
    outIm1 = scaleBensImage(imFiles{i}, channelNumber);
    outIm2 = scaleBensImage(imFiles{i+1}, channelNumber);
    outIm3 = scaleBensImage(imFiles{i+2}, channelNumber);
    outIm4 = scaleBensImage(imFiles{i+3}, channelNumber);
    
    outIm = [outIm1 outIm2; outIm3 outIm4];
    
    imwrite(outIm,fullfile(outDir, sprintf('contrastedImage_%s_%d.jpeg', channel, i)));
end    
%% Adjust each image in scan and save to outDir
%imFiles = dir(fullfile(inDir, '*.nd2'));
%imFiles = strcat(inDir, '/', {imFiles.name});
%numImages = numel(imFiles);
%for i = 1:numImages
%    imFiles{i}
%    tmp = bfopen(imFiles{i});
%    imwrite(im2uint16(imadjust(tmp{1,1}{wavelengths(1),1}, imadjust_constrast, [0,1])), fullfile(outDir, sprintf('Point%d_%s_contrasted.tiff', i-1, channels{wavelengths(1)})))      
    %imwrite(im2uint16(scale(tmp{1,1}{wavelengths(1),1})), fullfile(outDir, sprintf('Point%d_%s_scaleContrasted.tiff', i-1, channels{wavelengths(1)})))      
%end
%imshow(imadjust(imread(fullfile(inDir, 'Scan001_w2_s851_t1.TIF'))));
