function [] = autoAdjustScanND2(scanSize, wavelength, varargin)
% Script to load images from scan, adjust contrast, stitch n x m tiles then save to new directory. 
% Option to bin tiles into composite images. Needs to be updated to perform
% better stitching. Requires that scan be divisible into n x m frames. 
    p = inputParser;
    
    p.addRequired('scanSize', @(x)validateattributes(x,{'numeric'},{'size',[1 2]}));
    p.addRequired('wavelength', @isnumeric);

    p.addParameter('inDir', '', @ischar);
    p.addParameter('outDir', '', @ischar);
    p.addParameter('binSize', [3,3], @(x)validateattributes(x,{'numeric'}, {'size',[1 2]}));
    p.addParameter('scaleFactor', 2, @isnumeric);
    p.addParameter('rank', 0, @(x)validateattributes(x,{'numeric'}, {'nonnegative'}));
    p.addParameter('rankFile', 'spotCounts.mat', @ischar);
    
    p.parse(scanSize, wavelength, varargin{:});
    
    fileRank = p.Results.rank;
    
    if ~isempty(p.Results.inDir)
       inDir = p.Results.inDir;
    else
       inDir = pwd;
    end

    if ~isempty(p.Results.outDir)
        outDir = p.Results.outDir;
    else
        outDir = fullfile(inDir, 'renamed');
    end
    
    scanSize = p.Results.scanSize;
    wavelength = p.Results.wavelength;
    binsize = p.Results.binSize;
    scaleFactor = p.Results.scaleFactor;
    
    %Check that scan is evenly divisible into bins. If not, set new binsize
    if ~mod((scanSize(1) * scanSize(2)) / (binsize(1) * binsize(2)), 1) == 0
        dimX = 2:scanSize(1);
        dimY = 2:scanSize(2);
        binsizeX = min(dimX(rem(scanSize(1), dimX)==0));
        binsizeY = min(dimY(rem(scanSize(2), dimY)==0));
        binsize = [binsizeX, binsizeY];
        sprintf('Scan not evenly divisble into specified binsize. Resetting binsize to [%d, %d]', binsize(1), binsize(2))
    else
        binsize = binsize;  
    end
    
    %For testing
%     scanSize = [90, 75];
%     binsize = [2,3];
    %Split the scan dimensions into regions based on binsize. Regions will
    %be ordered by rank if specified in command. 
    scanMatrix = vec2mat(1:scanSize(1)*scanSize(2), scanSize(2));
    for i = 2:2:scanSize(1)
        scanMatrix(i, :) = fliplr(scanMatrix(i, :));
    end

    if (fileRank > 0) && isfile(p.Results.rankFile)
        load(p.Results.rankFile, 'SS')
        rankList = table2array(SS(:,'fileNumber'));
        regionHolder = cell(1, fileRank);
        borderSize = idivide(uint16(binsize), 2, 'floor');
        borderMod = double(mod(binsize,2) == 0);
        for i = 1:fileRank
            [row, col] = find(scanMatrix == rankList(i));
            regionHolder{i} = reshape(scanMatrix(max(row-borderSize(1)+borderMod(1), 1):min(row + borderSize(1), scanSize(1)), max(col-borderSize(2)+borderMod(2), 1):min(col + borderSize(2), scanSize(2))), 1, []);
        end
    else
        regionHolder = cell(1, (scanSize(1) * scanSize(2)/(binsize(1) * binsize(2))));
        splitX = (scanSize(1)/binsize(1));
        splitY = (scanSize(2)/binsize(2));
        for i = 1:splitX
            for j = 1:splitY
                regionN = ((i-1) * splitY) + j;
                regionHolder{regionN} = reshape(scanMatrix(((i-1) * binsize(1)+1):(i * binsize(1)), ((j-1) * binsize(2)+1):(j * binsize(2))), 1, []);
            end
        end
    end

    % Read scan file, contrast planes, and tile planes
    scanFile = dir(fullfile(inDir, '*.nd2'));
    scanFile = scanFile.name;
    reader = bfGetReader(fullfile(inDir, scanFile));
    omeMeta = reader.getMetadataStore();        
    dimensionX = omeMeta.getPixelsSizeX(0).getValue();
    dimensionY = omeMeta.getPixelsSizeY(0).getValue();
    
    % Make directory for  images
    if ~exist(outDir, 'dir')
        mkdir(outDir)
    end
    
    for i = 1:numel(regionHolder) % Loop through images
        tmpOutIm = zeros(binsize .* [dimensionY, dimensionX], 'uint8');  
        for ii = 1:binsize(2)
            for iii = 1:binsize(1)
                frame = ((ii-1) * binsize(2)) + iii;
                if frame <= numel(regionHolder{i})
                    reader.setSeries(regionHolder{i}(frame)-1);
                    iPlane = reader.getIndex(0, wavelength - 1, 0) + 1;
                    tmpPlane  = bfGetPlane(reader, iPlane);
                    tmpPlane = scalePlane(tmpPlane, regionHolder{i}(frame), scaleFactor);
                    tmpOutIm((iii-1) * dimensionY + 1:(iii * dimensionY), (ii-1) * dimensionX + 1:ii * dimensionX) = tmpPlane;
                end
            end
        end
        if fileRank > 0
             imwrite(tmpOutIm,fullfile(outDir, sprintf('contrastedImage_w%d_point%d_rank%d.jpeg', wavelength, rankList(i), i)));
        else
             imwrite(tmpOutIm,fullfile(outDir, sprintf('contrastedImage_w%d_point%d.jpeg', wavelength, i)));
        end
        fprintf('Finished position %d of %d\n', i, numel(regionHolder));
    end
     
%         tmpOutIm = zeros(binsize .* [dimensionY, dimensionX], 'uint8'); 
%         for ii = 1:binsize(2)
%             for iii = 1:binsize(1)
%                 %test = ((ii-1) * binsize(1))
%                 frame = ((ii-1) * binsize(2)) + iii;
%                 reader.setSeries(regionHolder{100}(frame)-1);
%                 iPlane = reader.getIndex(0, wavelength - 1, 0) + 1;
%                 tmpPlane  = bfGetPlane(reader, iPlane);
%                 tmpPlane = scalePlane(tmpPlane, regionHolder{100}(frame));
%                 %(ii-1) * dimensionX
%                 %(iii-1) * dimensionY
%                 %size(tmpPlane)
%                 %size(tmpOutIm((iii-1) * dimensionY + 1:(iii * dimensionY), (ii-1) * dimensionX + 1:ii * dimensionX));
%                 %size(tmpPlane)
%                 %frame
%                 %regionHolder{100}(frame)
%                 tmpOutIm((iii-1) * dimensionY + 1:(iii * dimensionY), (ii-1) * dimensionX + 1:ii * dimensionX) = tmpPlane;
%             end
%         end
        %imwrite(tmpOutIm,fullfile(outDir, sprintf('contrastedImage_%s_%d.jpeg', channel, i)));
end