function [] = stitchAndRescaleScanND2(inDir, scanFile, scanDim,rows, cols, wavelengths, resizeFactor)
    %For testing 
    scanDim = [100 100];
    scanFile = '20190703_135412_909__ChannelBrightfield,YFP,A594,CY5,DAPI_Seq0000.nd2';
    rows = 46:56;
    cols = 85:95;
    wavelengths = [2,3,4, 5];
    resizeFactor = 1;
    %cd(inDir)
    reader = bfGetReader(scanFile);
    omeMeta = reader.getMetadataStore();        
    dimensionX = omeMeta.getPixelsSizeX(0).getValue();
    dimensionY = omeMeta.getPixelsSizeY(0).getValue();
    dimensionX = dimensionX/resizeFactor;
    dimensionY = dimensionY/resizeFactor;
    %Create matrix of how the scan was acquired. This can be updated as a
    %parameter in the future for other scan patterns. 
    scanMatrix = vec2mat(1:scanDim(1)*scanDim(2), scanDim(2));
    for i = 2:2:scanDim(1)
        scanMatrix(i, :) = fliplr(scanMatrix(i, :));
    end
    
    if exist('transform_coords.mat','file')
        load transform_coords.mat columnTransformCoords rowTransformCoords
    else
        % First, register the rows
        centerIndex = idivide(int16(scanDim),int16(2), 'ceil');
        
        reader.setSeries(scanMatrix(centerIndex(1), centerIndex(2))-1);
        iPlane = reader.getIndex(0, numel(wavelengths) - 1, 0) + 1;
        tmpPlane1  = bfGetPlane(reader, iPlane);
        tmpPlane1 = double(scale(imresize(tmpPlane1, 1/resizeFactor)));
        
        reader.setSeries(scanMatrix(centerIndex(1)+1, centerIndex(2))-1);
        iPlane = reader.getIndex(0, numel(wavelengths) - 1, 0) + 1;
        tmpPlane2  = bfGetPlane(reader, iPlane);
        tmpPlane2 = double(scale(imresize(tmpPlane2, 1/resizeFactor)));

        [moving_out,fixed_out] = cpselect(tmpPlane1,tmpPlane2,'Wait',true);

        rowTransformCoords = round(median(moving_out-fixed_out));
        
        %Next register columns
        reader.setSeries(scanMatrix(centerIndex(1), centerIndex(2))-1);
        iPlane = reader.getIndex(0, numel(wavelengths) - 1, 0) + 1;
        tmpPlane1  = bfGetPlane(reader, iPlane);
        tmpPlane1 = double(scale(imresize(tmpPlane1, 1/resizeFactor)));

        reader.setSeries(scanMatrix(centerIndex(1), centerIndex(2)+1)-1)
        iPlane = reader.getIndex(0, numel(wavelengths) - 1, 0) + 1;
        tmpPlane2  = bfGetPlane(reader, iPlane);
        tmpPlane2 = double(scale(imresize(tmpPlane2, 1/resizeFactor)));

        [moving_out,fixed_out] = cpselect(tmpPlane1,tmpPlane2,'Wait',true);

        columnTransformCoords = round(median(moving_out-fixed_out));
        
        save transform_coords.mat columnTransformCoords rowTransformCoords
    end
    
    % Now we have the transforms.  Let's now set up the coordinates for the
    % megapicture.  
    stitchMatrix = scanMatrix(rows, cols);
    %stitchMatrix = transpose(stitchMatrix);
    %stitchMatrixT = transpose(stitchMatrix);
    stitchTiles = stitchMatrix(:);
    
    for i = 1:numel(stitchTiles)
        [row,col] = find(stitchMatrix == stitchTiles(i));
        topCoords(i)  = col*columnTransformCoords(1) + row*rowTransformCoords(1);
        leftCoords(i) = row*rowTransformCoords(2) + col*columnTransformCoords(2);
    end

    topCoords = topCoords - min(topCoords) + 1;
    leftCoords = leftCoords - min(leftCoords) + 1;

    tmpStitch = zeros(max(leftCoords)+dimensionY-1,max(topCoords)+dimensionX-1, numel(wavelengths), 'uint16');

    %h = fspecial('gaussian',40,20); If you want to apply gaussian filter for DAPI images before stitching. 
    

    for i = 1:numel(stitchTiles)
        for ii = 1:numel(wavelengths)
            reader.setSeries(stitchTiles(i)-1);
            iPlane = reader.getIndex(0, wavelengths(ii) - 1, 0) + 1;
            tmpPlane  = bfGetPlane(reader, iPlane);
            tmpPlane = im2double(imresize(tmpPlane, 1/resizeFactor));
            %imageToAdd = (doubleIm - imfilter(doubleIm,h,'replicate'));

            tmpStitch(leftCoords(i):leftCoords(i)+dimensionY-1, ...
                topCoords(i):topCoords(i)+dimensionX-1, ii) = ...
                im2uint16(tmpPlane);
        end
    end
    
    for iii = 1:numel(wavelengths)
        %imwrite(im2uint16(scale(tmpStitch(:,:,iii))), sprintf('stitch_rows%d_%d_cols%d_%d_w%d.jpg', rows(1), rows(numel(rows)), cols(1), cols(numel(rows)), wavelengths(iii)), 'BitDepth',16)
        imwrite(imresize(tmpStitch(:,:,iii), 0.5), sprintf('stitch_rows%d_%d_cols%d_%d_w%d.tif', rows(1), rows(numel(rows)), cols(1), cols(numel(rows)), wavelengths(iii)))
    end
    imwrite(imadjust(tmpStitch(:, :, 2), [650, 2000]/65535,[]), 'stitch_point3140_w3.tif')

end