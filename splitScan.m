function [] = splitScan(infile, varargin)
    % Example command to divide infile scan into 16 quadrants and save to
    % outDir:
    % splitScan('pathToInfile', 'splitX', 4, 'splitY', 4, 'outDir', 'splitScans')
    p = inputParser;
 
    p.addRequired('infile', @ischar);
    p.addParameter('splitX', 4, @isnumeric);
    p.addParameter('splitY', 4, @isnumeric);
    p.addParameter('outDir', '', @ischar);
 
    p.parse(infile, varargin{:});
    
    infile = p.Results.infile;
    splitX = p.Results.splitX;
    splitY = p.Results.splitX;
    
    if ~isempty(p.Results.outDir)
        outDir = p.Results.outDir
    else
        [path, name, ext] = fileparts(infile);
        outDir = sprintf('%s_splitScan', name)
    end
    
    if ~exist(outDir, 'dir')
        mkdir(outDir)
    end
    
    reader = bfGetReader(infile);
    omeMeta = reader.getMetadataStore();
    dimensionX = omeMeta.getPixelsSizeX(0).getValue();
    dimensionY = omeMeta.getPixelsSizeY(0).getValue();
    wavelengths = omeMeta.getPixelsSizeC(0).getValue();
    
    width = floor(dimensionX/splitX+1); 
    height = floor(dimensionX/splitY+1);
    
    stepsX = floor(linspace(1, dimensionX-width, splitX+1));
    stepsY = floor(linspace(1, dimensionY-height, splitY+1));

    for i = 1:numel(stepsX)-1
        for ii = 1:numel(stepsY)-1
            for iii = 1:wavelengths
                reader.setSeries(0); %Can change this for multipoint scans
                iPlane = reader.getIndex(0, iii - 1, 0) + 1;
                tmpPlane  = bfGetPlane(reader, iPlane, stepsX(i), stepsY(ii),width,height);
                imwrite(tmpPlane, fullfile(outDir, sprintf('xDim%d_yDim%d_channel%d.tiff', i, ii, iii)))
            end
        end
    end
end

%% For testing
% testFile = '10X10Scan20X001.nd2';
% reader = bfGetReader(testFile);
% omeMeta = reader.getMetadataStore();
% 
% splitX = 3;
% splitY = 3;
% 
% dimensionX = omeMeta.getPixelsSizeX(0).getValue();
% dimensionY = omeMeta.getPixelsSizeY(0).getValue();
% wavelengths = omeMeta.getPixelsSizeC(0).getValue();
% 
% width = floor(dimensionX/splitX+1); 
% height = floor(dimensionX/splitY+1);
% 
% stepsX = floor(linspace(1, dimensionX-width, splitX+1));
% stepsY = floor(linspace(1, dimensionY-height, splitY+1));
% 
% reader.setSeries(0); %Can change this for multipoint scans
% iPlane = reader.getIndex(0, 6 - 1, 0) + 1;
% tmpPlane  = bfGetPlane(reader, iPlane, stepsX(2), stepsY(2),width,height);
