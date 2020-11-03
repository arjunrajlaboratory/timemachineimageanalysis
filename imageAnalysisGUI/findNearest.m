function [I] = findNearest(reference, query, threshold)
    [D,I] = pdist2(reference,query,'euclidean','Smallest',1);
    I = I(find(D < threshold));
end

