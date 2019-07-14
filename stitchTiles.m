function [] = stitchTiles(scanFile, regions, wavelengths)

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
    
    % Read scan file
    reader = bfGetReader(scanFile);
    omeMeta = reader.getMetadataStore();        
    dimensionX = omeMeta.getPixelsSizeX(0).getValue();
    dimensionY = omeMeta.getPixelsSizeY(0).getValue();
    
    if exist('transform_coords.mat','file')
        load transform_coords.mat columnTransformCoords rowTransformCoords
    else
        % First, register the rows
        centerIndex = idivide(numel(regions.tiles{1}),int16(2), 'ceil');
        
        reader.setSeries(regions.tiles{1}(centerIndex)-1);
        iPlane = reader.getIndex(0, numel(wavelengths) - 1, 0) + 1;
        tmpPlane1  = bfGetPlane(reader, iPlane);
        tmpPlane1 = double(scale(tmpPlane1));
        
        reader.setSeries(regions.tiles{1}(centerIndex+regions.dimensions{1}(2))-1);
        iPlane = reader.getIndex(0, numel(wavelengths) - 1, 0) + 1;
        tmpPlane2  = bfGetPlane(reader, iPlane);
        tmpPlane2 = double(scale(tmpPlane2));

        [moving_out,fixed_out] = cpselect(tmpPlane1,tmpPlane2,'Wait',true);

        rowTransformCoords = round(median(moving_out-fixed_out));
        
        %Next register columns
        reader.setSeries(regions.tiles{1}(centerIndex)-1);
        iPlane = reader.getIndex(0, numel(wavelengths) - 1, 0) + 1;
        tmpPlane1  = bfGetPlane(reader, iPlane);
        tmpPlane1 = double(scale(tmpPlane1));

        reader.setSeries(regions.tiles{1}(centerIndex+1)-1)
        iPlane = reader.getIndex(0, numel(wavelengths) - 1, 0) + 1;
        tmpPlane2  = bfGetPlane(reader, iPlane);
        tmpPlane2 = double(scale(tmpPlane2));

        [moving_out,fixed_out] = cpselect(tmpPlane1,tmpPlane2,'Wait',true);

        columnTransformCoords = round(median(moving_out-fixed_out));
        
        save transform_coords.mat columnTransformCoords rowTransformCoords
    end
    
    % Now we have the transforms.  Let's now set up the coordinates for the
    % megapicture.
    for i = 1:numel(regions.points)
        arrayOfPositions = 1:numel(regions.tiles{i});
        matrixOfPositions = reshape(arrayOfPositions,regions.dimensions{i}(1),regions.dimensions{i}(2));
        matrixOfPositions = transpose(matrixOfPositions);
    
        for ii = 1:numel(regions.tiles{i})
            [row,col] = find(matrixOfPositions == ii);
            topCoords(ii)  = col*columnTransformCoords(1) + row*rowTransformCoords(1);
            leftCoords(ii) = row*rowTransformCoords(2) + col*columnTransformCoords(2);
        end
    
        topCoords = topCoords - min(topCoords) + 1;
        leftCoords = leftCoords - min(leftCoords) + 1;
    
        tmpStitch = zeros(max(leftCoords)+dimensionY-1,max(topCoords)+dimensionX-1, numel(wavelengths), 'uint16');
    
    end
    
    %h = fspecial('gaussian',40,20); If you want to apply gaussian filter for DAPI images before stitching. 
    
    for i = 1:numel(regions.points)
        for ii = 1:numel(regions.tiles{i})
            for iii = 1:numel(wavelengths)
                reader.setSeries(regions.tiles{i}(ii)-1);
                iPlane = reader.getIndex(0, wavelengths(iii) - 1, 0) + 1;
                tmpPlane  = bfGetPlane(reader, iPlane);
                tmpPlane = im2double(tmpPlane);
                %imageToAdd = (doubleIm - imfilter(doubleIm,h,'replicate'));

                tmpStitch(leftCoords(ii):leftCoords(ii)+dimensionY-1, ...
                    topCoords(ii):topCoords(ii)+dimensionX-1, iii) = ...
                    im2uint16(tmpPlane);
            end
        end
        fprintf('Finished stitching position %d\n', i);
        for iii = 1:numel(wavelengths)
            imwrite(imresize(tmpStitch(:,:,iii), 0.5), sprintf('stitch_point%d_w%d.tif', regions.points{i}, wavelengths(iii)))
        end
    end
end