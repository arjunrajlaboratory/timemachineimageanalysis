function S = findAllNuclei(S, channelDAPI, contrastValues, sensitivity, sizeThreshold)

    function_binarize = @(block_struct)...
        imbinarize(imadjust(block_struct.data, contrastValues, []), adaptthresh(imadjust(block_struct.data, contrastValues, []), sensitivity, 'ForegroundPolarity','bright')); 
    
    image_binarize = blockproc(S.stitches{channelDAPI}, [500 500], function_binarize, 'BorderSize', [50 50]); 
    
    % find connected components and remove centroid smaller than threshold:
    CC = bwconncomp(image_binarize, 4);

    rp = regionprops(CC);

    area = [rp.Area];
    centroids = [rp.Centroid];
    centroids = reshape(centroids,2,[])'; 
    centroids = round(centroids); 

    idx = area > sizeThreshold; % Get rid of small stuff

    centroids_keep = centroids(idx, 1:end);
    S.nuclei.coords = num2cell(centroids_keep, 2);

end
