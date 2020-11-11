function outIm = scaleBensImage(imdata, frameN)

    quartiles = quantile(imdata,3);

    im2 = imadjust(tempIm,[quartiles(1) quartiles(3)*1.5]);

    im3 = imresize(im2,0.5);
    
    %position = regexp(filename,'Seq\d+','match');
    im4 = insertText(im3,[1 1],frameN,'FontSize',18);

    outIm = im2uint8(rgb2gray(im4));
end
   