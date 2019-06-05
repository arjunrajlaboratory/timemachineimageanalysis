function spotTable = countSpotsNearNuclei(spotIm, dapiIm)

% Deal with spots
h = -fspecial('log',20,2);

filt = imfilter(spotIm,h,'replicate');
irm = imregionalmax(filt);

% Get nuclei

T = adaptthresh(dapiIm,0.3,'ForegroundPolarity','bright');
dp = imbinarize(dapiIm,T);

CC = bwconncomp(dp);
rp = regionprops(CC);
area = [rp.Area];

idx = area > 1000; % Get rid of small stuff

CC2 = CC;
CC2.NumObjects = sum(idx);
CC2.PixelIdxList = CC2.PixelIdxList(idx);

lab = labelmatrix(CC2);

allSpots = [];
cellNumber = [];

for i = 1:CC2.NumObjects
    tempbw = lab == i; % select the ith cell
    tempbw = imdilate(tempbw,strel('disk',30)) - tempbw; % donut around ith cell
    
    temprm = irm.*tempbw; % keep only spots in the donut
    tempSpots = filt(temprm==1)'; % keep signal intensities for the spots in the donut
    
    allSpots = [allSpots tempSpots];
    cellNumber = [cellNumber i*ones(1,numel(tempSpots))];
    
end

spotTable = table(allSpots',cellNumber','VariableNames',["spotIntensities","cellNumber"]);
