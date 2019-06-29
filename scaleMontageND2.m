function [] = scaleMontageND2(file, FISH_channel, DAPI_channel, spotCountsFile, rank, scaleFactor, outDir)

%     rank = 200;
%     scaleFactor = 1.5;
%     outDir = '/Volumes/Blemert6/20190606_timeMachine22F/well2/topRankScaled/';
%     file = '20190608_213632_030__ChannelBrightfield,CY3,A594,CY5,DAPI_Seq0000.nd2'; 
% 
%     FISH_channel = 4;
%     DAPI_channel = 5;

    load(spotCountsFile, 'SS');
    
    idx = SS.fileNumber(1:rank);

    reader = bfGetReader(file);
    
    % Make directory for  images
    if ~exist(outDir, 'dir')
        mkdir(outDir)
    end

    for num = idx'

        fprintf('File num %d of %d\n',num, rank);
        reader.setSeries(num-1);

        indexFISH = reader.getIndex(0, FISH_channel - 1, 0) + 1;
        indexDAPI = reader.getIndex(0, DAPI_channel - 1, 0) + 1;

        imFISH  = bfGetPlane(reader, indexFISH);

        imDAPI = bfGetPlane(reader, indexDAPI);

        tmpIm = im2double(imFISH);

        quartiles = quantile(tmpIm,3);

        im2 = imadjust(tmpIm,[quartiles(1) quartiles(3)*scaleFactor]);

        % imshow(im,[]);
        % imshow(im2,[]);
        % imshow(im3,[]);

    %    spotTable = countSpotsNearNuclei(im,im3);

        im3 = insertText(im2,[1 1],num,'FontSize',18);

        outIm = im2uint8(rgb2gray(im3));

        imwrite(outIm,fullfile(outDir, sprintf('contrastedImage_w%d_point%d.jpeg', FISH_channel, num)));
        %imwrite(outIm,['../outputImages/' num2str(num) fn '.jpg']);
    end
end