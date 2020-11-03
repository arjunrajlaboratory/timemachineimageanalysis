function [tmpStitch, leftCoords, topCoords, tiles] = stitchScanMM(inDir, outDir, outFileName, scanDim, channel, contrastValues, resizeFactor, saveStitch)
    % inDir is path to find the scan image files and transform_coords.mat. (e.g.
    % '/Volumes/Blemert11/20191223_TM31_PLXtimecourse/plate3/wellA1/)
    % outDir is the output director to save the stitched images. 
    % outFileName is the prefix for the saved stitched images. 
    % scanDim is dimension of scan (e.g. [40 40])
    % channel is the channel of multichannel you'd wish to stich (e.g. 1) 
    % contrastValues are the 16bit values to contrast max and min of image
    % intensities. (e.g. [500 9000])
    % resizeFactor is the amount you'd like to resize the images e.g 2 for
    % 50% reduction. 
    
    %For testing
%     inDir = '/Users/benjaminemert/Dropbox (RajLab)/Shared_Ben/WM989_PLXdose/replicate1/1uMPLX';
%     outDir = '/Users/benjaminemert/Dropbox (RajLab)/Shared_Ben/WM989_PLXdose/replicate1';
%     outFileName = 'WM989_1uMPLX_replicate1';
%     scanDim = [36 37];
%     channel = 1;
%     contrastValues = [1000 35000];
    
    startDir = pwd;
    if ~exist(outDir, 'dir')
        mkdir(outDir)
    end
    cd(inDir)
    
    scanMatrix = vec2mat(1:scanDim(1)*scanDim(2), scanDim(1));
%     for i = 2:2:scanDim(1)
%         scanMatrix(i, :) = fliplr(scanMatrix(i, :));
%     end
    
    tilesTmp = transpose(scanMatrix);
    tiles = tilesTmp(:);

    % List scan files
    scanPrefix = sprintf('Scan001_w%d_s%%d_t1.TIF', channel);
    scanFiles = sprintfc(scanPrefix, 1:scanDim(1)*scanDim(2));

    
    if exist('transform_coords.mat','file')
        load transform_coords.mat columnTransformCoords rowTransformCoords
    else
        % First, register the rows
        centerIndex = scanMatrix(round(scanDim(1)/2), round(scanDim(2)/2));
        
        tmpPlane1  = imread(scanFiles{centerIndex});
        tmpPlane1 = double(scale(tmpPlane1));
        
        tmpPlane2  = imread(scanFiles{centerIndex+scanDim(1)});
        tmpPlane2 = double(scale(tmpPlane2));
        
        [moving_out,fixed_out] = cpselect(tmpPlane1,tmpPlane2,'Wait',true);

        rowTransformCoords = round(median(moving_out-fixed_out));
        
        %Next register columns

        tmpPlane3  = imread(scanFiles{centerIndex+1});
        tmpPlane3 = double(scale(tmpPlane3));

        [moving_out,fixed_out] = cpselect(tmpPlane1,tmpPlane3,'Wait',true);

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
    
    tmpIm = imread(scanFiles{1});
    dimensionX = size(tmpIm,1);
    dimensionY = size(tmpIm,2);
    
    tmpStitch = zeros(max(leftCoords)+dimensionY-1,max(topCoords)+dimensionX-1, 'uint16');
    
    %h = fspecial('gaussian',40,20); If you want to apply gaussian filter for DAPI images before stitching. 
    
    for i = 1:numel(tiles)
        tmpPlane = imread(scanFiles{tiles(i)});
        
        %doubleIm = im2double(tmpPlane);
        %imageToAdd = (doubleIm - imfilter(doubleIm,h,'replicate'));

        tmpStitch(leftCoords(i):leftCoords(i)+dimensionY-1, ...
            topCoords(i):topCoords(i)+dimensionX-1) = ...
            im2uint16(tmpPlane);
    end
    
    cd(startDir)
    
    if saveStitch
        tmpStitch2 = imadjust(tmpStitch, contrastValues/65535, []);
        imwrite(imresize(tmpStitch2, 1/resizeFactor), fullfile(outDir, sprintf('%s_w%d_stitch.tif', outFileName, channel)))
        imwrite(im2uint8(imresize(tmpStitch2, 1/resizeFactor)), fullfile(outDir, sprintf('%s_w%d_stitch.jpg', outFileName, channel)))
    end
    
end