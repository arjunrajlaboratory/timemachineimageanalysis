function [] = autoAdjustScanND2(scanSize, wavelength, varargin)
%   Script to load images from scan, adjust contrast, stitch n x m tiles then save to new directory. 
%   Option to bin tiles into composite images. Requires that scan be
%   divisible into n x m frames. Note, simply "sitches" images side by side, does not correct for overlap. 
%
%   Input Args (required):
%   scanSize - Dimension of the scan. # images in X (across) * # of images in Y (up and down). 
%   wavelength - Numeric value indicating which fluorescence channel to process.
%
%   Input Args (optional):
%   inDir - Path to the directory containing the scan ND2 file. Default is working directory.  
%   inFile - Option to specify the scan file name. Default is to process one .nd2 file in inDir. Note, if multiple .nd2 files in inDir, specify which .nd2 to process with inFile option.   
%   outDir - Name of directory to save the contrasted and stitched micrographs.
%   binSize - The size (# of tiles in X and Y) for each output micrograph. Must be a factor of the scanSize. Default is 3x3 or smallest factor of the scanSize.   
%   scaleFactor - Parameter for adjusting image contrast. Larger values increase the max intensity (micrographs look darker). See scalePlane.m for further details. 
%   rankFile - Seldom used legacy parameter for the path to a "rankFile". The analyzeTimeMachineScanND2.m function will try to automatically 
%              rank images (tiles) by barcode RNA FISH signal (see analyzeTimeMachineScanND2.m script for details). 
%              This ranking is saved to a file called something like spotCounts.mat (usually with a specified wavelength and spot intensity threshold). 
%              If the rankFile and rank parameters are used, then this script will stitch tiles in the order specified in
%              the rankFile, up to the specified rank. Ultimately, I have found it to ignore this parameter and just review     
%              micrographs of the entire scan. 
%   rank - Numeric value. See explanation of rankFile above. 
%
%   Example command:
%   autoAdjustScanND2([40 40], 2, 'inDir', 'exampleData', 'outDir', 'contrasted', 'binSize', [2 2])
%----------------------------------------------------------------
    p = inputParser;
    
    p.addRequired('scanSize', @(x)validateattributes(x,{'numeric'},{'size',[1 2]}));
    p.addRequired('wavelength', @isnumeric);

    p.addParameter('inDir', '', @ischar);
    p.addParameter('inFile', '', @ischar);
    p.addParameter('outDir', '', @ischar);
    p.addParameter('binSize', [3,3], @(x)validateattributes(x,{'numeric'}, {'size',[1 2]}));
    p.addParameter('scaleFactor', 2, @isnumeric);
    p.addParameter('rankFile', 'spotCounts.mat', @ischar);
    p.addParameter('rank', 0, @(x)validateattributes(x,{'numeric'}, {'nonnegative'}));
    
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
        outDir = fullfile(inDir, 'contrasted');
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
    end
    
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
    if ~isempty(p.Results.inFile)
       scanFile = dir(fullfile(inDir, '*.nd2'));
       scanFile = scanFile.name;
    else
        scanFile = p.Results.inFile;
    end

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
     
end