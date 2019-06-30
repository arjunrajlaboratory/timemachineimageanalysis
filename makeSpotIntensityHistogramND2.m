function [] = makeSpotIntensityHistogramND2(file, FISH_channel, DAPI_channel)

    %file = '20190608_213632_030__ChannelBrightfield,CY3,A594,CY5,DAPI_Seq0000.nd2'; 
    %FISH_channel = 4;
    %DAPI_channel = 5;
    
    reader = bfGetReader(file);
    omeMeta = reader.getMetadataStore();
    tiles = omeMeta.getImageCount;

    
    allSpotsTable = cell2table(cell(0,3), 'VariableNames', {'spotIntensities','cellNumber','fileNumber'});

    index = round(linspace(1,tiles,100));

    for num = index

        fprintf('File num %d of %d\n',num, tiles);
        reader.setSeries(num-1);
        
        indexFISH = reader.getIndex(0, FISH_channel - 1, 0) + 1;
        indexDAPI = reader.getIndex(0, DAPI_channel - 1, 0) + 1;
        
        imFISH  = bfGetPlane(reader, indexFISH);
        
        imDAPI = bfGetPlane(reader, indexDAPI);


        spotTable = countSpotsNearNuclei(imFISH,imDAPI);


        spotTable.fileNumber = num*ones(height(spotTable),1);

        allSpotsTable = [allSpotsTable ; spotTable];
    end

    histogram(allSpotsTable.spotIntensities);
    xlim([0 100])
end
