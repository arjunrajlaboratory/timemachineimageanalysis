function [] = stitchColonyScan(scanFile, inDir , scanDim, splitDim)

    %For testing
%     scanFile = '/Volumes/Blemert6/20190626_TM22F_resistantColonies/WellB1/scan/20190702_230015_489__ChannelBrightfield,YFP,A594,CY5,DAPI_Seq0000.nd2';
%     regions.points = {3020, 6055};
%     regions.tiles = {stitchTiles1, stitchTiles2};
%     regions.dimensions = {[21,21], [21,21]};
%     regions.stitch = cell(1,numel(regions.points));
%     wavelengths = {'brightfield', 'YFP', 'A594', 'CY5', 'DAPI'};
%     outDir = '/Volumes/Blemert6/20190626_TM22F_resistantColonies/WellB1/tiles_v2';
%     inDir = '/Volumes/Blemert6/20190626_TM22F_resistantColonies/WellB1/scan';
    
    % Make directory for  images
%     if ~exist(outDir, 'dir')
%         mkdir(outDir)
%     end
    scanFile = 'Point0000_ChannelDAPI,Brightfield_Seq0000.nd2';
    inDir = '20191118_092542_534/';
    scanDim = [37 36];
    scanMatrix = vec2mat(1:scanDim(1)*scanDim(2), scanDim(1));
    for i = 2:2:scanDim(1)
        scanMatrix(i, :) = fliplr(scanMatrix(i, :));
    end
    
    % If splitting scan into subregions:
%     splitX = scanDim(1)/splitDim(1) 
%     regions.tiles = cell(1,numel(regions.points));
%     for i = 1:numel(regions.points)
%         [rowIndex, colIndex] = find(scanMatrix == regions.points{i});
%         tilesTmp = scanMatrix(max(rowIndex-borderDims{i}(1), 1): min(rowIndex+borderDims{i}(1), scanDim(1)), max(colIndex-borderDims{i}(2), 1): min(colIndex+borderDims{i}(2), scanDim(2)));
%         tilesTmp = transpose(tilesTmp);
%         regions.tiles{i} = tilesTmp(:);
%     end
    % If stitching entire scan:
    tilesTmp = transpose(scanMatrix);
    regions.tiles{1} = tilesTmp(:);
    regions.dimensions{1} = scanDim;
    % Read scan file
    reader = bfGetReader(fullfile(inDir, scanFile));
    omeMeta = reader.getMetadataStore();        
    dimensionX = omeMeta.getPixelsSizeX(0).getValue();
    dimensionY = omeMeta.getPixelsSizeY(0).getValue();
    
    if exist('transform_coords.mat','file')
        load transform_coords.mat columnTransformCoords rowTransformCoords
    else
        % First, register the rows
        centerIndex = scanMatrix(round(scanDim(1)/2), round(scanDim(2)/2));
        
        reader.setSeries(regions.tiles{1}(centerIndex)-1);
        iPlane = reader.getIndex(0, 0, 0) + 1;
        tmpPlane1  = bfGetPlane(reader, iPlane);
        tmpPlane1 = double(scale(tmpPlane1));
        
        reader.setSeries(regions.tiles{1}(centerIndex+regions.dimensions{1}(1))-1);
        iPlane = reader.getIndex(0, 0, 0) + 1;
        tmpPlane2  = bfGetPlane(reader, iPlane);
        tmpPlane2 = double(scale(tmpPlane2));

        [moving_out,fixed_out] = cpselect(tmpPlane1,tmpPlane2,'Wait',true);

        rowTransformCoords = round(median(moving_out-fixed_out));
        
        %Next register columns
        reader.setSeries(regions.tiles{1}(centerIndex)-1);
        iPlane = reader.getIndex(0, 0, 0) + 1;
        tmpPlane1  = bfGetPlane(reader, iPlane);
        tmpPlane1 = double(scale(tmpPlane1));

        reader.setSeries(regions.tiles{1}(centerIndex+1)-1)
        iPlane = reader.getIndex(0, 0, 0) + 1;
        tmpPlane2  = bfGetPlane(reader, iPlane);
        tmpPlane2 = double(scale(tmpPlane2));

        [moving_out,fixed_out] = cpselect(tmpPlane1,tmpPlane2,'Wait',true);

        columnTransformCoords = round(median(moving_out-fixed_out));
        
        save transform_coords.mat columnTransformCoords rowTransformCoords
    end
    
    % Now we have the transforms.  Let's now set up the coordinates for the
    % megapicture.
    arrayOfPositions = 1:numel(regions.tiles{1});
    matrixOfPositions = reshape(arrayOfPositions,regions.dimensions{1}(1),regions.dimensions{1}(2));
    matrixOfPositions = transpose(matrixOfPositions);

    for ii = 1:numel(regions.tiles{1})
        [row,col] = find(matrixOfPositions == ii);
        topCoords(ii)  = col*columnTransformCoords(1) + row*rowTransformCoords(1);
        leftCoords(ii) = row*rowTransformCoords(2) + col*columnTransformCoords(2);
    end

    topCoords = topCoords - min(topCoords) + 1;
    leftCoords = leftCoords - min(leftCoords) + 1;

    tmpStitch = zeros(max(leftCoords)+dimensionY-1,max(topCoords)+dimensionX-1, 2, 'uint16');

    
    %h = fspecial('gaussian',40,20); If you want to apply gaussian filter for DAPI images before stitching. 
    
    for ii = 1:numel(regions.tiles{1})
        for iii = 1:2 %Number of wavelengths
            reader.setSeries(regions.tiles{1}(ii)-1);
            iPlane = reader.getIndex(0, iii - 1, 0) + 1;
            tmpPlane  = bfGetPlane(reader, iPlane);
            tmpPlane = im2double(tmpPlane);
            %imageToAdd = (doubleIm - imfilter(doubleIm,h,'replicate'));

            tmpStitch(leftCoords(ii):leftCoords(ii)+dimensionY-1, ...
                topCoords(ii):topCoords(ii)+dimensionX-1, iii) = ...
                im2uint16(tmpPlane);
        end
    end
    fprintf('Finished stitching position %d\n', i);
    for iii = 1:2 %Number of wavelengths
        imwrite(imresize(tmpStitch(:,:,iii), 0.5), sprintf('stitch_w%d.tif', iii))
    end
     imwrite(im2uint8(imadjust(tmpStitch(:,:,1),[0 18000]/65535 ,[])), 'stitch_w1.jpg')
     imwrite(im2uint8(imadjust(tmpStitch(:,:,2),[16000 50000]/65535 ,[])), 'stitch_w2.jpg')
     imwrite(im2uint8(imresize(imadjust(tmpStitch(:,:,2),[16000 50000]/65535 ,[]), 0.5)), 'stitch_w2_50percent.jpg')
end