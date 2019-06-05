dd = dir("*w5*.tif"); %Barcode
dd2 = dir("*w3*.tif"); % smFISH against GFP
dd3 = dir("*w2*.tif"); % DAPI


allSpotsTable = cell2table(cell(0,3), 'VariableNames', {'spotIntensities','cellNumber','fileNumber'});

for num = 1:numel(dd)
    
    fprintf('File num %d\n',num);
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
    
    spotTable.fileNumber = num*ones(height(spotTable),1);
    
    allSpotsTable = [allSpotsTable ; spotTable];
end

% This will reveal the threshold. For this data, 50 seems reasonable
% enough.
histogram(allSpotsTable.spotIntensities);
xlim([0 100])


thresh = 50;
threshFunc = @(spots)sum(spots>thresh);

G = findgroups(allSpotsTable(:,2:3));

Y = splitapply(threshFunc,allSpotsTable.spotIntensities,G);

imshow(imoverlay(filt>50,dp))
thresh = 50;

for i = 1:max(cellNumber)
    tempSpots = allSpots(cellNumber == i);
    sm(i) = sum(tempSpots > thresh);
end

