

scanFile = '/Volumes/Blemert6/20190626_TM22F_resistantColonies/WellB2/scan/20190703_135412_909__ChannelBrightfield,YFP,A594,CY5,DAPI_Seq0000.nd2';
wavelengths = [2, 3, 4];
inDir = '/Volumes/Blemert6/20190626_TM22F_resistantColonies/WellB2/scan';
scanDim = [100, 100];

scanMatrix = vec2mat(1:scanDim(1)*scanDim(2), scanDim(2));
for i = 2:2:scanDim(1)
    scanMatrix(i, :) = fliplr(scanMatrix(i, :));
end

regions.points = {7011, 7030, 7050, 7070, 7090, 8990, 8971, 8951, 8931, 8911};
regions.dimensions = {[21,21], [21,21], [21,21], [21,21], [21,21], [21,21], [21,21], [21,21], [21,21], [21,21]};
borderDims = cellfun(@(x) idivide(uint16(x), 2, 'floor'), regions.dimensions, 'UniformOutput', false);

regions.tiles = cell(1,numel(regions.points));
for i = 1:numel(regions.points)
    [rowIndex, colIndex] = find(scanMatrix == regions.points{i});
    tilesTmp = scanMatrix(max(rowIndex-borderDims{i}(1), 1): min(rowIndex+borderDims{i}(1), scanDim(1)), max(colIndex-borderDims{i}(2), 1): min(colIndex+borderDims{i}(2), scanDim(2)));
    tilesTmp = transpose(tilesTmp);
    regions.tiles{i} = tilesTmp(:);
end

stitchTiles(scanFile, regions, wavelengths);

    %Save stitched images. 
% for i = 1:numel(regions.points)
%         imwrite(imresize(regions.stitch{i}(:,:,2), 0.5), fullfile(inDir, sprintf('stitch_point%d_gfp.tif', i+18)))
%         imwrite(imresize(regions.stitch{i}(:,:,3), 0.5), fullfile(inDir, sprintf('stitch_point%d_alexa.tif', i+18)))
%         imwrite(imresize(regions.stitch{i}(:,:,4), 0.5), fullfile(inDir, sprintf('stitch_point%d_cy.tif', i+18)))
% end

% clear regions