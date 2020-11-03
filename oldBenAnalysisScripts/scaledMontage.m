
idx = SS.fileNumber(1:200);

for num = idx'
    fprintf('File num %d\n',num);
    fn = dd(num).name;
    %fn2 = dd2(num).name;
    fn3 = dd3(num).name;
    im = imread(fn);
    %im2 = imread(fn2);
    im3 = imread(fn3);
    
    tempIm = im2double(im);
    imdata = tempIm(:);
    quartiles = quantile(imdata,3);

    im2 = imadjust(tempIm,[quartiles(1) quartiles(3)*1.5]);
    
    % imshow(im,[]);
    % imshow(im2,[]);
    % imshow(im3,[]);
    
    spotTable = countSpotsNearNuclei(im,im3);
    im3 = imresize(im2,0.5);
    im4 = insertText(im3,[1 1],fn,'FontSize',18);

    outIm = im2uint8(rgb2gray(im4));
    imwrite(outIm,['../outputImages/' num2str(num) fn '.jpg']);
end
