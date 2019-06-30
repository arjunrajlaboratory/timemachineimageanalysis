dd = dir("*w5*.tif"); %Barcode
dd2 = dir("*w3*.tif"); % smFISH against GFP
dd3 = dir("*w2*.tif"); % DAPI

num = 108;

fn = dd(num).name;
fn2 = dd2(num).name;
fn3 = dd3(num).name;
im = imread(fn);
im2 = imread(fn2);
im3 = imread(fn3);

imshow(im,[]);
imshow(im2,[]);
imshow(im3,[]);


% Deal with spots
h = -fspecial('log',20,2);

filt = imfilter(im,h,'replicate');

irm = imregionalmax(filt);
imshow(filt*500);


%iim = scale(im);

% Get nuclei

bw2 = imbinarize(im3,'adaptive','ForegroundPolarity','bright');

T = adaptthresh(im3,0.3,'ForegroundPolarity','bright');

imshow(imbinarize(im3,T));

dp = imbinarize(im3,T);


% Now let's find the nuclei
CC = bwconncomp(dp);
rp = regionprops(CC);
area = [rp.Area];

idx = area > 1000;

CC2 = CC;
CC2.NumObjects = sum(idx);
CC2.PixelIdxList = CC2.PixelIdxList(idx);

lab = labelmatrix(CC2);

allSpots = [];
cellNumber = [];

for i = 1:CC2.NumObjects
    tempbw = lab == i;
    tempbw = imdilate(tempbw,strel('disk',30)) - tempbw;
    
    %filt2 = im2double(filt).*tempbw;
    temprm = irm.*tempbw;
    tempSpots = filt(temprm==1)';
    %spotprops = regionprops(filt2);
    
    allSpots = [allSpots tempSpots];
    cellNumber = [cellNumber i*ones(1,numel(tempSpots))];
    
end


imshow(imoverlay(filt>50,dp))
thresh = 50;

for i = 1:max(cellNumber)
    tempSpots = allSpots(cellNumber == i);
    sm(i) = sum(tempSpots > thresh);
end

