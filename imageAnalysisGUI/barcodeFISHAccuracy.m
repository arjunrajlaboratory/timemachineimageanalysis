%Script to analyze specificity/sensitivity of barcode HCR 09/14/2020
inDir = '/Users/benjaminemert/Dropbox (RajLab)/Papers/Rewind/rawdata/barcodeFISHvalidation/HCR/20200914_HCRtest_F8/well1_TM31topProbes';
scanFile = 'scan/20200914_094422_253__Point0000_ChannelCY5,YFP,DAPI_Seq0000.nd2';
if isfile(fullfile(inDir, 'S.mat')) 
    load(fullfile(inDir, 'S.mat'), 'S')
else
    %First stich scan
    scanDim = [25 25];
    outFilePrefix = 'TM31probeTest_F8_well1';
    contrastValues = [1 65535];
    saveStitch = false;
    nChannels = 3;
    stitches = cell(1, nChannels);
    insertFrame = true;
    for i = nChannels:-1:1 %Going in reverse since want to start with DAPI
        [tmpStitch, leftCoords, topCoords, tiles] = stitchScanND2(inDir, scanFile, inDir, sprintf('%s_w%d', outFilePrefix, i), scanDim, i, contrastValues, 4, saveStitch, insertFrame);
        stitches{i} = tmpStitch;
    end
    S.stitches = stitches;
    S.leftCoords = leftCoords;
    S.topCoords = topCoords;
    S.tiles = tiles;
    %% Now find all nuclei in scan
    channelCy = 1;
    channelGFP = 2;
    channelDAPI = 3;
    contrastValues = [1000 40000]/65535;
    sensitivity = 0.1;
    sizeThreshold = 200;
    S = findAllNuclei(S, channelDAPI, contrastValues, sensitivity, sizeThreshold);
    save(fullfile(inDir, 'S.mat'), 'S', '-v7.3')
end
%% On a per-nucleus level, select all barcodeFISH positive cells
FOV = [1200 1200];
barcodeFISHChannel = 1;
dapiChannel = 3;
S = gui_to_selectBarcodePositive_v2(S,FOV, barcodeFISHChannel, dapiChannel);
%%
save(fullfile(inDir, 'S.mat'), 'S', '-v7.3')
%% Select GFP+ cells
FOV = [1200 1200];
GFPChannel = 2;
dapiChannel = 3;
S = gui_to_selectGFPPositive_v2(S,FOV, GFPChannel, dapiChannel);
%%
save(fullfile(inDir, 'S.mat'), 'S', '-v7.3')

%%
S.nuclei.tile = ones(1, numel(S.nuclei.coords));  
temp_coords = cell2mat(S.nuclei.coords);
for i = max(S.tiles):-1:1 %looping in reverse so that for nuclei in multiple tiles, only the first is kept
    
    leftX = S.topCoords(i);
    rightX = leftX+1024;
    
    topY = S.leftCoords(i);
    bottomY = topY+1022;
    
    inFrameNuclei = inpolygon(temp_coords(:,1), temp_coords(:,2), [leftX rightX rightX leftX leftX], [topY topY bottomY bottomY topY]); 
    
    temp_tiles = S.nuclei.tile;
    temp_tiles(inFrameNuclei) = S.tiles(i);
    S.nuclei.tile = temp_tiles; 
    
end
%%
save(fullfile(inDir, 'S.mat'), 'S', '-v7.3')

%% Export to CSV for further analysis in R
outputTable = table(temp_coords(:,1), temp_coords(:,2), S.nuclei.barcodeFISH', S.nuclei.GFP',S.nuclei.tile');
outputTable.Properties.VariableNames = {'Xpos', 'Ypos', 'barcodePos', 'GFPpos','frame'};
writetable(outputTable, 'extractedData/barcodeFISHvalidation/HCR/barcodeFISHAccuracyTableWell1.csv');

%% Contrast and overlay example images for supp fig 4. Also save origin position for annotation spatial plot. 
frames = [213, 234, 263, 365, 389];
reader = bfGetReader(fullfile(inDir, scanFile));
origins = zeros(numel(frames),3);
outDir = 'extractedData/barcodeFISHvalidation/HCR/20200914_HCRtest_F8/';
for i = 1:numel(frames)
    reader.setSeries(frames(i)-1);
    iPlane = reader.getIndex(0, channelCy-1, 0) + 1;
    tmpPlaneCy  = bfGetPlane(reader, iPlane);
    tmpPlaneCy  = imadjust(tmpPlaneCy, [1400 2000]/65535, []);

    iPlane = reader.getIndex(0, channelGFP-1, 0) + 1;
    tmpPlaneGFP  = bfGetPlane(reader, iPlane);
    tmpPlaneGFP  = imadjust(tmpPlaneGFP, [2000 25000]/65535, []);
    
    iPlane = reader.getIndex(0, channelDAPI-1, 0) + 1;
    tmpPlaneDAPI  = bfGetPlane(reader, iPlane);
    tmpPlaneDAPI  = imadjust(tmpPlaneDAPI, [3000 50000]/65535, []);

    overlayFISH = cat(3, im2double(tmpPlaneCy), im2double(tmpPlaneCy) + (im2double(tmpPlaneDAPI) * 155/255), im2double(tmpPlaneCy) + (im2double(tmpPlaneDAPI) * 223/255)); 
    imwrite(overlayFISH, fullfile(outDir, sprintf('HCRtest_F8_well1_frame%d_20xOverlayFISH.tiff', frames(i))))
    imwrite(im2uint8(overlayFISH), fullfile(outDir, sprintf('HCRtest_F8_well1_frame%d_20xOverlayFISH.jpg', frames(i))))
    
    overlayGFP = cat(3, zeros(size(tmpPlaneGFP)), im2double(tmpPlaneGFP) + (im2double(tmpPlaneDAPI) * 155/255), (im2double(tmpPlaneDAPI) * 223/255)); 
    imwrite(overlayGFP, fullfile(outDir, sprintf('HCRtest_F8_well1_frame%d_20xOverlayGFP.tiff', frames(i))))
    imwrite(im2uint8(overlayGFP), fullfile(outDir, sprintf('HCRtest_F8_well1_frame%d_20xOverlayGFP.jpg', frames(i))))
    
    tmpIndex = find(S.tiles == frames(i));
    origins(i,:) = [frames(i), S.leftCoords(tmpIndex), S.topCoords(tmpIndex)];
end
%%
orginsTable = array2table(origins);
orginsTable.Properties.VariableNames = {'frame', 'Xstart', 'Ystart'};
writetable(orginsTable, fullfile(outDir, 'HCRtest_F8_well1_exampleImages_origins.csv'))
%% Save cropped images 
frames = [234, 365, 389];
cropFrame = {[280 0 420 420], [40 520 450 450], [450 0 320 320]};
reader = bfGetReader(fullfile(inDir, scanFile));
outDir = 'extractedData/barcodeFISHvalidation/HCR/20200914_HCRtest_F8/';
for i = 2:numel(frames)
    reader.setSeries(frames(i)-1);
    iPlane = reader.getIndex(0, channelCy-1, 0) + 1;
    tmpPlaneCy  = bfGetPlane(reader, iPlane);
    tmpPlaneCy = imcrop(tmpPlaneCy, cropFrame{i});
    tmpPlaneCy  = imadjust(tmpPlaneCy, [1600 2200]/65535, []);

    iPlane = reader.getIndex(0, channelGFP-1, 0) + 1;
    tmpPlaneGFP  = bfGetPlane(reader, iPlane);
    tmpPlaneGFP = imcrop(tmpPlaneGFP, cropFrame{i});
    tmpPlaneGFP  = imadjust(tmpPlaneGFP, [2000 25000]/65535, []);
    
    iPlane = reader.getIndex(0, channelDAPI-1, 0) + 1;
    tmpPlaneDAPI  = bfGetPlane(reader, iPlane);
    tmpPlaneDAPI = imcrop(tmpPlaneDAPI, cropFrame{i});
    tmpPlaneDAPI  = imadjust(tmpPlaneDAPI, [3000 50000]/65535, []);

    overlayFISH = cat(3, im2double(tmpPlaneCy), im2double(tmpPlaneCy) + (im2double(tmpPlaneDAPI) * 155/255), im2double(tmpPlaneCy) + (im2double(tmpPlaneDAPI) * 223/255)); 
    imwrite(overlayFISH, fullfile(outDir, sprintf('HCRtest_F8_well1_frame%d_20xOverlayFISH_cropped.tiff', frames(i))))
    imwrite(im2uint8(overlayFISH), fullfile(outDir, sprintf('HCRtest_F8_well1_frame%d_20xOverlayFISH_cropped.jpg', frames(i))))
    
    overlayGFP = cat(3, zeros(size(tmpPlaneGFP)), im2double(tmpPlaneGFP) + (im2double(tmpPlaneDAPI) * 155/255), (im2double(tmpPlaneDAPI) * 223/255)); 
    imwrite(overlayGFP, fullfile(outDir, sprintf('HCRtest_F8_well1_frame%d_20xOverlayGFP_cropped.tiff', frames(i))))
    imwrite(im2uint8(overlayGFP), fullfile(outDir, sprintf('HCRtest_F8_well1_frame%d_20xOverlayGFP_cropped.jpg', frames(i))))
    
end

%%
close all
reader.setSeries(frames(3)-1);
iPlane = reader.getIndex(0, channelCy-1, 0) + 1;
tmpPlaneCy  = bfGetPlane(reader, iPlane);
tmpPlaneCy = imcrop(tmpPlaneCy, cropFrame{3});
tmpPlaneCy  = imadjust(tmpPlaneCy, [1400 2000]/65535, []);
imshow(tmpPlaneCy)

%% Old scripts below

%% 
if ~isfile(fullfile(inDir, 'S.mat'))
    load(fullfile(inDir, 'S.mat'))
else
    S = struct;
end
%% Now select all GFP+

%% Now select all FRAMES with barcodeFISH positive cell

%% Now select all GFP+ FRAMEs


%% For each frame, determine if it contains GFP+ cell and or barcodeFISH+ cell

%% Divide stitch into chunks. Get origin for each chunk
top_starts = (1:2000:size(tmpStitch,2));
left_starts = (1:2000:size(tmpStitch,1));

n_row=numel(left_starts); 
n_col=numel(top_starts); 

top_coords=repmat(top_starts,n_row, 1);
top_coords=top_coords(:)';

left_coords=repmat(top_starts,1,n_col);
left_coords=left_coords(:)';


%%
border =  cat(2, [4001,  4001], [2000 2000]);
tmpPlaneCy  = imcrop(S.stitches{1}, border);
tmpPlaneCy = imadjust(im2double(tmpPlaneCy), [0, 1]); 

tmpPlaneDapi  = imcrop(S.stitches{3},  border);
tmpPlaneDapi = im2double(imadjust(tmpPlaneDapi, [1000 40000]/65535, [])); 

RGB = cat(3, tmpPlaneCy, tmpPlaneCy, tmpPlaneCy+tmpPlaneDapi);

% display the image:
figure
imshow(RGB);
hold on        

rectangle = bbox2points(border);

temp_coords = cell2mat(S.nuclei.coords);
% leftX = 2001;
% rightX = 4001;
% topY = 1;
% bottomY = 2001;
inFrameNuclei = inpolygon(temp_coords(:,1), temp_coords(:,2), rectangle(:,1), rectangle(:,2)); 
inFrameNucleiCoords = temp_coords(inFrameNuclei, :);
inFrameNucleiCoords = inFrameNucleiCoords - rectangle(1,:);

% plot coordinates on image:
scatter(inFrameNucleiCoords(:,1), inFrameNucleiCoords(:,2), 20, 'yellow', 'filled');      

hold off
%%
figure
imshow(RGB);
hold on        

rectangle = bbox2points(border);

temp_coords = cell2mat(S2.nuclei.coords);
% leftX = 2001;
% rightX = 4001;
% topY = 1;
% bottomY = 2001;
inFrameNuclei = inpolygon(temp_coords(:,1), temp_coords(:,2), rectangle(:,1), rectangle(:,2)); 
inFrameNucleiCoords = temp_coords(inFrameNuclei, :);
inFrameNucleiCoords = inFrameNucleiCoords - rectangle(1,:);

% plot coordinates on image:
scatter(inFrameNucleiCoords(:,1), inFrameNucleiCoords(:,2), 20, 'yellow', 'filled'); 

hold off

%%
figure
imshow(RGB);
hold on        

rectangle = bbox2points(border);

temp_coords = cell2mat(S3.nuclei.coords);
% leftX = 2001;
% rightX = 4001;
% topY = 1;
% bottomY = 2001;
inFrameNuclei = inpolygon(temp_coords(:,1), temp_coords(:,2), rectangle(:,1), rectangle(:,2)); 
inFrameNucleiCoords = temp_coords(inFrameNuclei, :);
inFrameNucleiCoords = inFrameNucleiCoords - rectangle(1,:);

% plot coordinates on image:
scatter(inFrameNucleiCoords(:,1), inFrameNucleiCoords(:,2), 20, 'yellow', 'filled'); 

hold off
%%
S = gui_to_selectBarcodePositive_v2(S,[1200 1200], 1, 3);

%% Find tile for each nucleus
reader = bfGetReader(scanFile);
omeMeta = reader.getMetadataStore();        
dimensionX = omeMeta.getPixelsSizeX(0).getValue();
dimensionY = omeMeta.getPixelsSizeY(0).getValue();


%%
S.nuclei.tile = ones(1, numel(S.nuclei.coords));    
for i = max(S.tiles):-1:1 %looping in reverse so that for nuclei in multiple tiles, only the first is kept
    
    leftX = S.topCoords(i);
    rightX = leftX+1024;
    
    topY = S.leftCoords(i);
    bottomY = topY+1022;
    
    inFrameNuclei = inpolygon(temp_coords(:,1), temp_coords(:,2), [leftX rightX rightX leftX leftX], [topY topY bottomY bottomY topY]); 
    
    temp_tiles = S.nuclei.tile;
    temp_tiles(inFrameNuclei) = S.tiles(i);
    S.nuclei.tile = temp_tiles; 
    
end

%%

index = find(S.tiles == 50);
frame50X = S.topCoords(index);
frame50Y = S.leftCoords(index);

nucleiIndex = find(S.nuclei.tile == 50);


tmpPlaneDapi  = imcrop(S.stitches{3},  cat(2, [frame50X,  frame50Y], [1024 1022]));
tmpPlaneDapi = scale(im2double(tmpPlaneDapi)); 

% display the image:
figure
imshow(tmpPlaneDapi);
hold on 

nucleiCoords = cell2mat(S.nuclei.coords(nucleiIndex));
nucleiCoords = nucleiCoords - [frame50X, frame50Y];
% plot coordinates on image:
scatter(nucleiCoords(:,1), nucleiCoords(:,2), 20, 'yellow', 'filled');      






%%
% Divide stitch into chunks. Get origin for each chunk
tileSize = [1000 1000];
top_starts = (1:tileSize(2):size(S.stitches{1},2));
left_starts = (1:tileSize(1):size(S.stitches{1},1));

n_row=numel(left_starts); 
n_col=numel(top_starts); 

top_coords=repmat(top_starts,n_row, 1);
top_coords=top_coords(:)';

left_coords=repmat(top_starts,1,n_col);
left_coords=left_coords(:)';