function SS = analyzeTimeMachineScanND2(file, threshold, FISH_channel, DAPI_channel)
    
    %file = '20190608_213632_030__ChannelBrightfield,CY3,A594,CY5,DAPI_Seq0000.nd2'; 
    %threshold = 15; % This is something you should set based on makeSpotIntensityHistogram.m
    %FISH_channel = 4;
    %DAPI_channel = 5;
    
    reader = bfGetReader(file);
    omeMeta = reader.getMetadataStore();
    tiles = omeMeta.getImageCount;



    allSpotsTable = cell2table(cell(0,3), 'VariableNames', {'numSpots','cellNumber','fileNumber'});

    for i = 1:tiles

        fprintf('File num %d of %d\n',i, tiles);
        reader.setSeries(i-1);
        
        indexFISH = reader.getIndex(0, FISH_channel - 1, 0) + 1;
        indexDAPI = reader.getIndex(0, DAPI_channel - 1, 0) + 1;
        
        imFISH  = bfGetPlane(reader, indexFISH);
        
        imDAPI = bfGetPlane(reader, indexDAPI);


        spotTable = countSpotsNearNuclei(imFISH,imDAPI);
        
        if ~isempty(spotTable)

            threshFunc = @(spots)sum(spots>threshold);

            [G,TID] = findgroups(spotTable(:,2));

            Y = splitapply(threshFunc,spotTable.spotIntensities,G);

            TT = table(Y,'VariableNames',{'numSpots'});
            TT = [TT TID];
            TT.fileNumber = i*ones(height(TT),1);

            %spotTable.fileNumber = num*ones(height(spotTable),1);

            allSpotsTable = [allSpotsTable ; TT];
        end
    end

    [G,TID] = findgroups(allSpotsTable(:,3));
    Y = splitapply(@max,allSpotsTable.numSpots,G);
    TT = table(Y,'VariableNames',{'maxSpotCount'});
    TT = [TT,TID];
    SS = sortrows(TT,'maxSpotCount','descend');
%    for i = 1:length(SS.fileNumber)
%        SS.fileName(i) = string(dd(SS.fileNumber(i)).name);
%    end
    save(sprintf('spotCounts_w%d.mat', FISH_channel),'SS');
end


