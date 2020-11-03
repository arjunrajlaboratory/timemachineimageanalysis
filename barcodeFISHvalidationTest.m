%
%Load scan



x = linspace(0,3*pi,200);
y = cos(x) + rand(1,200);
sz = 25;
c = linspace(1,10,length(x));
s = scatter(x,y,sz,c,'filled');
% Add an additional row to the data tips showing the color value
datatipRow = dataTipTextRow('C',c);
s.DataTipTemplate.DataTipRows(end+1) = datatipRow;

%%
x = linspace(0,10);
y = exp(.1*x).*sin(3*x);
y(60) = 2.7;
plot(x,y)
%%
tmpIm = readmm('dapi001.tif');
tmpIm = tmpIm.imagedata;

%%
imshow(imresize(tmpIm(:,:,10), 0.5))
[x, y, button] = ginput(1);
%%
imshow(tmpIm(:,:,10))
n = 0;
x_n = {};
y_n = {};
while true
   [x, y, button] = ginput(1);
   if isempty(x) || button(1) == 1; break; end
   n = n+1;
   x_n{n} = x(1); % save all points you continue getting
   y_n{n} = y(1);
   hold on
   plot(x(1), y(1), 'r')
   drawnow
end
%%
xmin=1;
xmax=500;
n=10;
x=xmin+rand(1,n)*(xmax-xmin);

ymin=1;
ymax=500;
n=10;
y=ymin+rand(1,n)*(ymax-ymin);

%%
imshow(imresize(tmpIm(:,:,10), 0.5))
hold on
scatter(x, y, 15, 'r')
drawnow

%%
while getkey ~= 13
   imshow(imresize(tmpIm(:,:,10), 0.5))
   [x, y] = getpts;
end
close all

%%
KEY_IS_PRESSED = 0;
imshow(imresize(tmpIm(:,:,10), 0.5))
gcf
set(gcf, 'KeyPressFcn', @myKeyPressFcn)
%%
round1 = {};
round2 = {};
imshow(imresize(tmpIm(:,:,10), 0.5))
[x_1, y_1] = getpts;
round1{1} = [x_1, y_1];
[x_2, y_2] = getpts;
round2{1} = [x_2, y_2];
close all

