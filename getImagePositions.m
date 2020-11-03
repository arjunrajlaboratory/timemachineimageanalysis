
%% 
projectPath = '/Users/benjaminemert/Dropbox (RajLab)/Shared_Ben/timeMachine/';
dataPath = 'rawdata/TM31CarbonCopy/plate3';
extractionPath = 'extractedData/TM31CarbonCopy/GFP'; 

if ~exist(extractionPath, 'dir')
    mkdir(extractionPath)
end

cd(dataPath);

wells = {'wellA1', 'wellA2','wellA3','wellB1','wellB2','wellB3'};
groups = {'onTarget', 'offTarget'};

%% 
allData = {};
for i = 1:numel(wells)
    for ii = 1:numel(groups)

        if exist(sprintf('%s/round1/%s', wells{i}, groups{ii}), 'dir')
            inDir = sprintf('%s/round1/%s', wells{i}, groups{ii});
            inFiles = dir(sprintf('%s/*.nd2',inDir));
            inFiles = {inFiles.name};

            wellData = {};
            counter = 1;

            for iii = 1:numel(inFiles)
                reader = bfGetReader(fullfile(inDir, inFiles{iii}));
                omeMeta = reader.getMetadataStore(); 

                arrayNums = [];
                XPos = [];
                YPos = [];

                imageCount = omeMeta.getImageCount;
                for iv = 1:imageCount
                    arrayNums = [arrayNums, counter];
                    XPos = [XPos, double(omeMeta.getPlanePositionX(iv-1,0).value())];
                    YPos = [YPos, double(omeMeta.getPlanePositionY(iv-1,0).value())];
                    counter = counter + 1;
                end
                
                plate = cell(1, imageCount);
                [plate{:}] = deal('plate3');
                
                well = cell(1, imageCount);
                [well{:}] = deal(wells{i});
                
                type = cell(1, imageCount);
                [type{:}] = deal(groups{ii});

                fileData = horzcat(num2cell(arrayNums'), num2cell(XPos'), num2cell(YPos'), plate', well', type');
                wellData = vertcat(wellData, fileData); 
            end

            allData = vertcat(allData, wellData);                

        end
    end
end
%%
allDataTable = cell2table(allData);

allDataTable.Properties.VariableNames = {'objArrayNum', 'XPos', 'YPos', 'plate', 'well', 'type'};
writetable(allDataTable, fullfile(projectPath, 'extractedData/TM31CarbonCopy/RNAFISH/WM989_plate3_RNAFISH_positions.csv'));


