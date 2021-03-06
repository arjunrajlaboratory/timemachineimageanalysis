function outIm = scalePlane(tmpIm, frameN, scaleFactor)

    tmpIm = im2double(tmpIm);

    quartiles = quantile(tmpIm,3);

    im2 = imadjust(tmpIm,[max(0, quartiles(1)) min(quartiles(3)*scaleFactor, 1)]);

    im3 = imresize(im2,1);
    
    %position = regexp(filename,'Seq\d+','match');
    im4 = insertText(im3,[1 1],frameN,'FontSize',18);

    outIm = im2uint8(rgb2gray(im4));
end
   