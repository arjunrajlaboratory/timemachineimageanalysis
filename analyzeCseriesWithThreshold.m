%%

dd = dir("*w4*.tif"); % C series barcode
dd2 = dir("*w3*.tif"); % B series barcode
dd3 = dir("*w5*.tif"); % DAPI

thresh = 25; % This is something you should set based on makeSpotIntensityHistogram.m


allSpotsTable = cell2table(cell(0,3), 'VariableNames', {'numSpots','cellNumber','fileNumber'});

for num = 1:numel(dd)
    
    fprintf('File num %d of %d\n',num, numel(dd));
    fn = dd(num).name;
    %fn2 = dd2(num).name;
    fn3 = dd3(num).name;
    im = imread(fn);
    %im2 = imread(fn2);
    im3 = imread(fn3);
    
    % imshow(im,[]);
    % imshow(im2,[]);
    % imshow(im3,[]);
    
    spotTable = countSpotsNearNuclei(im,im3);
    if ~isempty(spotTable)
        
        threshFunc = @(spots)sum(spots>thresh);
        
        [G,TID] = findgroups(spotTable(:,2));
        
        Y = splitapply(threshFunc,spotTable.spotIntensities,G);
        
        TT = table(Y,'VariableNames',{'numSpots'});
        TT = [TT TID];
        TT.fileNumber = num*ones(height(TT),1);
        
        %spotTable.fileNumber = num*ones(height(spotTable),1);
        
        allSpotsTable = [allSpotsTable ; TT];
    end
end

%%
[G,TID] = findgroups(allSpotsTable(:,3));
Y = splitapply(@max,allSpotsTable.numSpots,G);
TT = table(Y,'VariableNames',{'maxSpotCount'});
TT = [TT,TID];
SS = sortrows(TT,'maxSpotCount','descend');
for i = 1:length(SS.fileNumber)
    SS.fileName(i) = string(dd(SS.fileNumber(i)).name);
end



