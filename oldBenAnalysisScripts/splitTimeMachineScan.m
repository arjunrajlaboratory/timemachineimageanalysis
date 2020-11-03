function [] = splitTimeMachineScan(inDir, dimensions, varargin)
    p = inputParser;

    p.addRequired('inDir', @ischar);
    p.addRequired('dimensions', [], @(x)validateattributes(x,{'numeric'},{'size',[1 2]});
    p.addParameter('inFile', '', @ischar);
    p.addParameter('regions', 4, @isnumeric);

    p.parse(inDir, dimensions, varargin{:});

    inDir = p.Results.inDir;
    dimensions = p.Results.dimensions;

    if ~isempty(p.Results.inFile)
        inFile = p.Results.inFile;
    else
        inFile = dir(fullfile(inDir, '*.nd2'));
        inFile = {inFile.name};
    end

    %Make output directories for each regions
    for i = 1:p.Results.regions
        outname = sprintf('region%d', i);
        mkdir(outname)
    end
    
    reader = bfGetReader(fullfile(inDir, inFile));
    omeMeta = reader.getMetadataStore();

    imageN = dimensions(1) * dimensions(2};  
    
end