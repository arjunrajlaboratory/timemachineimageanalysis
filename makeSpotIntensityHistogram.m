dd = dir("*w4*.tif"); % C series barcode
dd2 = dir("*w3*.tif"); % B series barcode
dd3 = dir("*w5*.tif"); % DAPI


allSpotsTable = cell2table(cell(0,3), 'VariableNames', {'spotIntensities','cellNumber','fileNumber'});

index = round(linspace(1,numel(dd),100));

for num = index
    
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
histogram(spotTable.spotIntensities);
xlim([0 100])

