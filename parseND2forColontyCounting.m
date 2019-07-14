

scanFile = '/Volumes/Blemert6/20190626_TM22F_resistantColonies/WellB1/scan/20190702_230015_489__ChannelBrightfield,YFP,A594,CY5,DAPI_Seq0000.nd2';
scanDim = [100, 100];

scanMatrix = vec2mat(1:scanDim(1)*scanDim(2), scanDim(2));
for i = 2:2:scanDim(1)
    scanMatrix(i, :) = fliplr(scanMatrix(i, :));
end

BSeries.points = {4033, 6849, 6055};
BSeries.dimensions = cell(1, numel(BSeries.points));
[BSeries.dimensions{:}] = deal([21,21]);
BSeries.tiles = cell(1,numel(BSeries.points));

for i = 1:numel(BSeries.points)
    [rowIndex, colIndex] = find(scanMatrix == BSeries.points{i});
    tilesTmp = scanMatrix(max(rowIndex-BSeries.dimensions{i}(1), 1): min(rowIndex+BSeries.dimensions{i}(1), scanDim(1)), max(colIndex-BSeries.dimensions{i}(2), 1): min(colIndex+BSeries.dimensions{i}(2), scanDim(2)));
    tilesTmp = transpose(tilesTmp);
    BSeries.tiles{i} = tilesTmp(:);
end

parseTiles(scanFile, BSeries, [], 'outDir', '/Volumes/Blemert6/20190626_TM22F_resistantColonies/WellB1/splitPoints_Bseries/');

CSeries.points = {3580, 5047, 6047};
CSeries.dimensions = cell(1, numel(CSeries.points));
[CSeries.dimensions{:}] = deal([21,21]);
CSeries.tiles = cell(1,numel(CSeries.points));

for i = 1:numel(CSeries.points)
    [rowIndex, colIndex] = find(scanMatrix == CSeries.points{i});
    tilesTmp = scanMatrix(max(rowIndex-CSeries.dimensions{i}(1), 1): min(rowIndex+CSeries.dimensions{i}(1), scanDim(1)), max(colIndex-CSeries.dimensions{i}(2), 1): min(colIndex+CSeries.dimensions{i}(2), scanDim(2)));
    tilesTmp = transpose(tilesTmp);
    CSeries.tiles{i} = tilesTmp(:);
end

parseTiles(scanFile, CSeries, wavelengths, 'outDir', '/Volumes/Blemert6/20190626_TM22F_resistantColonies/WellB1/splitPoints_Cseries/');

