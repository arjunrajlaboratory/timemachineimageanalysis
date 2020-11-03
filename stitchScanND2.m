function [tmpStitch, leftCoords, topCoords, tiles] = stitchScanND2(inDir, inFile, outDir, outFileName, scanDim, channel, contrastValues, resizeFactor, saveStitch, insertFrame)
    % inDir is path to find the scan file and transform_coords.mat. (e.g.
    % '/Volumes/Blemert11/20191223_TM31_PLXtimecourse/plate3/wellA1/)
    % inFile is the path to the nd2 scan file (e.g. scan/20191230_162451_662__ChannelCY5,YFP,DAPI_Seq0000.nd2')
    % input a single nd2 file containing the scan images. 
    % outDir is the output director to save the stitched images. 
    % outFileName is the prefix for the saved stitched images. 
    % scanDim is dimension of scan (e.g. [40 40])
    % channel is the channel of multichannel nd2 you'd wish to stich (e.g. 1) 
    % contrastValues are the 16bit values to contrast max and min of image
    % intensities. (e.g. [500 9000])
    % resizeFactor is the amount you'd like to resize the images e.g 2 for
    % 50% reduction. 
    
    %For testing
%     inDir = '/Volumes/Blemert11/20191223_TM31_PLXtimecourse/plate3/wellA1/';
%     inFile = 'scan/20191230_162451_662__ChannelCY5,YFP,DAPI_Seq0000.nd2';
%     outDir = '/Volumes/Blemert11/20191223_TM31_PLXtimecourse/plate3/wellA1/stitch';
%     outFileName = 'TM31_plate3_wellA1_dapi';
%     scanDim = [40 40];
%     channel = 3;
%     contrastValues = [1000 35000];
    
    if ~exist(outDir, 'dir')
        mkdir(outDir)
    end
    
    cd(inDir)
    
    scanMatrix = vec2mat(1:scanDim(1)*scanDim(2), scanDim(1));
    for i = 2:2:scanDim(1)
        scanMatrix(i, :) = fliplr(scanMatrix(i, :));
    end
    
    tilesTmp = transpose(scanMatrix);
    tiles = tilesTmp(:);

    % Read scan file
    reader = bfGetReader(inFile);
    omeMeta = reader.getMetadataStore();        
    dimensionX = omeMeta.getPixelsSizeX(0).getValue();
    dimensionY = omeMeta.getPixelsSizeY(0).getValue();
    
    if exist('transform_coords.mat','file')
        load transform_coords.mat columnTransformCoords rowTransformCoords
    else
        % First, register the rows
        centerIndex = scanMatrix(round(scanDim(1)/2)+2, round(scanDim(2)/2)+2);
        
        reader.setSeries(tiles(centerIndex)-1);
        iPlane = reader.getIndex(0, channel-1, 0) + 1;
        tmpPlane1  = bfGetPlane(reader, iPlane);
        tmpPlane1 = double(scale(tmpPlane1));
        
        reader.setSeries(tiles(centerIndex+scanDim(1))-1);
        iPlane = reader.getIndex(0, channel-1, 0) + 1;
        tmpPlane2  = bfGetPlane(reader, iPlane);
        tmpPlane2 = double(scale(tmpPlane2));

        [moving_out,fixed_out] = cpselect(tmpPlane1,tmpPlane2,'Wait',true);

        rowTransformCoords = round(median(moving_out-fixed_out));
        
        %Next register columns
        reader.setSeries(tiles(centerIndex)-1);
        iPlane = reader.getIndex(0, channel-1, 0) + 1;
        tmpPlane1  = bfGetPlane(reader, iPlane);
        tmpPlane1 = double(scale(tmpPlane1));

        reader.setSeries(tiles(centerIndex+1)-1)
        iPlane = reader.getIndex(0, channel-1, 0) + 1;
        tmpPlane2  = bfGetPlane(reader, iPlane);
        tmpPlane2 = double(scale(tmpPlane2));

        [moving_out,fixed_out] = cpselect(tmpPlane1,tmpPlane2,'Wait',true);

        columnTransformCoords = round(median(moving_out-fixed_out));
        
        save transform_coords.mat columnTransformCoords rowTransformCoords
    end
    
    % Now we have the transforms.  Let's now set up the coordinates for the
    % megapicture.
    matrixOfPositions = vec2mat(1:scanDim(1)*scanDim(2), scanDim(1));
    
    for i = 1:numel(tiles)
        [row,col] = find(matrixOfPositions == i);
        topCoords(i)  = col*columnTransformCoords(1) + row*rowTransformCoords(1);
        leftCoords(i) = row*rowTransformCoords(2) + col*columnTransformCoords(2);
    end

    topCoords = topCoords - min(topCoords) + 1;
    leftCoords = leftCoords - min(leftCoords) + 1;

    tmpStitch = zeros(max(leftCoords)+dimensionY-1,max(topCoords)+dimensionX-1, 'uint16');
    
    %h = fspecial('gaussian',40,20); If you want to apply gaussian filter for DAPI images before stitching. 
    
    for i = 1:numel(tiles)
        reader.setSeries(tiles(i)-1);
        iPlane = reader.getIndex(0, channel - 1, 0) + 1;
        tmpPlane  = bfGetPlane(reader, iPlane);
        if insertFrame == true
            tmpPlane = insertText(tmpPlane,[1 1],tiles(i),'FontSize',18);
            tmpPlane = rgb2gray(tmpPlane);
        end
        %doubleIm = im2double(tmpPlane);
        %imageToAdd = (doubleIm - imfilter(doubleIm,h,'replicate'));

        tmpStitch(leftCoords(i):leftCoords(i)+dimensionY-1, ...
            topCoords(i):topCoords(i)+dimensionX-1) = ...
            im2uint16(tmpPlane);
    end
    
    if saveStitch
        tmpStitch2 = imadjust(tmpStitch, contrastValues/65535, []);
        imwrite(imresize(tmpStitch2, 1/resizeFactor), fullfile(outDir, sprintf('%s_stitch.tif', outFileName)))
        imwrite(im2uint8(imresize(tmpStitch2, 1/resizeFactor)), fullfile(outDir, sprintf('%s_stitch.jpg', outFileName)))
        imwrite(im2uint8(imresize(tmpStitch2, 1/resizeFactor)), fullfile(outDir, sprintf('%s_stitch.jp2', outFileName)))
    end
    
end