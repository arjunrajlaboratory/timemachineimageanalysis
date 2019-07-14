function [] = parseTiles(scanFile, regions, wavelengths, varargin)
    p = inputParser;

    p.addRequired('scanFile', '', @ischar);
    p.addRequired('regions');
    p.addRequired('wavelengths', @(x)validateattributes(x,{'numeric'}));
    
    p.addParameter('inDir', '', @ischar);
    p.addParameter('outDir', '', @ischar);

    p.parse(scanFile, regions, wavelengths, varargin{:});
    
    scanFile = p.Results.scanFile;
    regions = p.Results.regions;
    wavelengths = p.Results.wavelengths;
    
    if ~isempty(p.Results.inDir)
        inDir = p.Results.inDir;
    else
        inDir = pwd;
    end
    
    if ~isempty(p.Results.outDir)
        outDir = p.Results.outDir;
    else
        outDir = fullfile(inDir, 'splitPoints');
    end
    
    %For testing
    %scanFile = '/Volumes/Blemert6/20190626_TM22F_resistantColonies/WellB1/scan/20190702_230015_489__ChannelBrightfield,YFP,A594,CY5,DAPI_Seq0000.nd2';
    %regions.points = {3020, 6055};
    %regions.tiles = {stitchTiles1, stitchTiles2};
    %regions.dimensions = {[21,21], [21,21]};
    %regions.stitch = cell(1,numel(regions.points));
    %wavelengths = {'brightfield', 'YFP', 'A594', 'CY5', 'DAPI'};
    %outDir = '/Volumes/Blemert6/20190626_TM22F_resistantColonies/WellB1/tiles_v2';
    %inDir = '/Volumes/Blemert6/20190626_TM22F_resistantColonies/WellB1/scan';
    
    % Make directory for  images
    if ~exist(outDir, 'dir')
        mkdir(outDir)
    end
    
    % Read scan file
    reader = bfGetReader(fullfile(inDir, scanFile));
        
    for i = 1:numel(regions.points)
        for ii = 1:numel(regions.tiles{i})
            for iii = 1:numel(wavelengths)
                reader.setSeries(regions.tiles{i}(ii)-1);
                iPlane = reader.getIndex(0, iii - 1, 0) + 1;
                tmpPlane  = bfGetPlane(reader, iPlane);
                tmpPlane = im2double(tmpPlane);
                
                imwrite(tmpPlane, fullfile(outDir, sprintf('Scan%03d_w%d_s%d_t1.TIF', i, iii, ii)))
            end
        end
        fprintf('Finished parsing position %d\n', i);
    end
    
end