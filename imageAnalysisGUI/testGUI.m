testScan = '20191230_162451_662__ChannelCY5,YFP,DAPI_Seq0000.nd2';

reader = bfGetReader(testScan);
omeMeta = reader.getMetadataStore();        
imageCountN = omeMeta.getImageCount();
position = 1;
channelDapi=3;
%%
iPlane = reader.getIndex(0, channelDapi-1, 0) + 1;
tmpPlaneDapi  = bfGetPlane(reader, iPlane);
tmpPlaneDapi = scale(im2uint16(tmpPlaneDapi)); 

image_binarize= imbinarize(tmpPlaneDapi, adaptthresh(tmpPlaneDapi, 0.1, 'ForegroundPolarity','bright'));

CC = bwconncomp(image_binarize, 4);

rp = regionprops(CC);

area = [rp.Area];
centroids = [rp.Centroid];
centroids = reshape(centroids,2,[])'; 
centroids = round(centroids); 

idx = area > 200; % Get rid of small stuff

centroids_keep = centroids(idx, 1:end);

points(position).nuclei = centroids_keep;

%%
imshow(tmpPlaneDapi)
hold on
scatter(centroids_keep(:,1), centroids_keep(:,2), 20, 'yellow', 'filled')
%%
imshow(tmpPlaneDapi)
[x, y] = getpts;

%%
positions = {[400 650], [200 300], [500 750]};
ROIs = cell(1,3);
imshow(tmpPlaneDapi)
for i = 1:numel(positions)
    ROIs{i} = drawpoint('Position',positions{i}, 'SelectedColor', 'green');
end
%%
t = cellfun(@(x) x.Selected,ROIs,'UniformOutput',false);

%h = images.roi.Point(gca,'Position',[400 650]);
%h2 = images.roi.Point(gca,'Position',[200 300]);



%%
imshow(tmpPlaneDapi)
[x2, y2] = ginput;
%%
S = struct;
S = gui_to_selectBarcodePositive(testScan, S, 1, 3);

%%
S = gui_to_selectGFPPositive(testScan, S, 2, 3);
%%
S = gui_to_checkSensitivity(testScan, S, 1, 3);

%%
GFPnonempty = cellfun(@(x) ~isempty(x.coords), {S.GFP},'UniformOutput',true);
GFPpositions = find(GFPnonempty ==1);

barcodeFISHnonempty = cellfun(@(x) ~isempty(x.coords), {S.barcodeFISH},'UniformOutput',true);
barcodeFISHpositions = find(barcodeFISHnonempty ==1);
%%
temp_coords = [S(13).barcodeFISH.coords];
temp_coords = reshape(temp_coords, 2, []);
temp_coords = temp_coords';

temp_labels = true(1,numel(S(13).barcodeFISH));

temp_labels(2) = false;

%% Get frames with barcodeFISH positions
%barcodeFISHCell = {S.barcodeFISH};
barcodeFISHnonempty = cellfun(@(x) ~isempty(struct2array(x)),{S.barcodeFISH},'UniformOutput',true);
barcodeFISHframes = find(barcodeFISHnonempty ==1);

%%
points = gui_to_selectBarcodePositive(testScan, points, 1, 3);
%%
points2 = gui_to_selectBarcodePositive(testScan, points, 1, 3);

%%
points2 = gui_to_checkSensitivity(testScan, points2, points, 1, 3);
%%
[test I] = pdist2(points2(10).coordinates, points(10).coordinates, 'euclidean','Smallest',1);
%%
find(~cellfun(@isempty,{points.coordinates}))

A = cellfun(@(x) x(1:3),C,'UniformOutput',false)

%%
function allevents(src,evt)
evname = evt.EventName
    switch(evname)
        case{'ROIClicked'}
            src.Select = 0
    end
end