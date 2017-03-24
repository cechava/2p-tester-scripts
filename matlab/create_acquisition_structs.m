clear all;
clc;

%% DEFINE SOURCE DIRECTORY:

% Define source dir for current acquisition/experiment:
sourceDir = '/nas/volume1/2photon/RESDATA/20161221_JR030W/retinotopy037Hz';

%sourceDir = '/nas/volume1/2photon/RESDATA/20161221_JR030W/rsvp_run3';
%sourceDir = '/nas/volume1/2photon/RESDATA/20161221_JR030W/retinotopy037Hz';

% sourceDir = '/nas/volume1/2photon/RESDATA/20161222_JR030W/retinotopy1/';
% sourceDir = '/nas/volume1/2photon/RESDATA/TEFO/20161218_CE024/raw/bar5';

analysisDir = fullfile(sourceDir, 'analysis');
if ~exist(analysisDir, 'dir')
    mkdir(analysisDir);
end

% Define TIFF dir to analysis for traces:
channelIdx = 1;

%acquisitionName = 'fov1_bar037Hz_retinotopy_run2';

%acquisitionName = 'fov2_rsvp_25reps_run3';
acquisitionName = 'fov1_bar037Hz_run4';

extraTiffsExcluded = [];
%extraTiffsExcluded = [9 10];


%% Define datastruct name for analysis:

didx = 2;

datastruct = sprintf('datastruct_%03d', didx);
dstructPath = fullfile(analysisDir, datastruct);
existingAnalyses = dir(analysisDir);
existingAnalyses = {existingAnalyses(:).name}';

if ~exist(dstructPath)
    mkdir(dstructPath)
    D = struct();
else
    fprintf('*********************************************************\n');
    fprintf('WARNING:  Specified datastruct -- %s -- exists. Overwrite?\n');
    uinput = input('Press Y/n to overwrite or create new: \n', 's');
    if strcmp(uinput, 'Y')
        D = struct();
        fprintf('New datastruct created: %s.\n', datastruct);
        fprintf('Not yet saved. Exit now to load existing datastruct.\n');
    else
        didx = input('Enter # to create new datastruct: \n');
        datastruct = sprintf('datastruct_%03d', didx);
        while ismember(datastruct, existingAnalyses)
            didx = input('Analysis %s already exists... Choose again.\n', datastruct);
            datastruct = sprintf('datastruct_%03d', didx);
        end
        dstructPath = fullfile(analysisDir, datastruct);
        mkdir(dstructPath);
        D = struct();
    end
end

D.name = datastruct;
D.datastructPath = dstructPath;
D.sourceDir = sourceDir;
D.acquisitionName = acquisitionName;
D.channelIdx = channelIdx;
D.extraTiffsExcluded = extraTiffsExcluded;
save(fullfile(dstructPath, datastruct), '-struct', 'D');


%% Get SI volume info:

metaInfo = 'SI';

corrected = true;
if corrected
    tiffSource = 'Corrected';
else
    tiffSource = 'Parsed';
end

D.tiffSource = tiffSource;
save(fullfile(D.datastructPath, D.name), '-append', '-struct', 'D');


%% Get SI volume info:

switch metaInfo
    case 'SI'
       
        siMetaName = sprintf('%s.mat', D.acquisitionName);
        
        if ~exist(fullfile(D.sourceDir, siMetaName))
            
            fprintf('No motion-corrected META data found...\n');
            fprintf('Current acquisition is: %s\n', D.acquisitionName);
            fprintf('Parsing SI tiffs, and creating new meta file.\n');
            
            % Load and parse raw TIFFs and create SI-specific meta file:
            movies = dir(fullfile(D.sourceDir,'*.tif'));
            movies = {movies(:).name};
            writeDir = fullfile(D.sourceDir, D.tiffSource);
            if ~exist(writeDir, 'dir')
                mkdir(writeDir)
            end
            parseSIdata(D.acquisitionName, movies, D.sourceDir, writeDir);
            
            % Load newly-created meta struct:
            %siMeta = load(fullfile(sourceDir, siMetaName));
            %meta = struct();
            %meta.(acquisitionName) = siMeta.metaDataSI; % Have info for each file, but this was not corrected in previosuly run MCs...
        end
        
        % Creata META with SI (acquisition) and MW (experiment) info:
        meta = createMetaStruct(D);
        fprintf('Created meta struct for current acquisition,\n');
        
        % Sort Parsed files into separate directories if needed:
        if length(dir(fullfile(D.sourceDir, D.tiffSource))) > meta.nChannels
            sort_parsed_tiffs(D.sourceDir, D.tiffSource, meta.nChannels);
        end
      
    case 'manual' % No motion-correction/processing, just using raw TIFFs.
        nVolumes = 350;
        nSlices = 20;
        nDiscard = 0;
        
        nFramesPerVolume = nSlices + nDiscard;
        nTotalFrames = nFramesPerVolume * nVolumes;
        
        %.....

end


D.metaPath = meta.metaPath;
D.nTiffs = meta.nTiffs;
D.nChannels = meta.nChannels;
D.stimType = meta.stimType;

save(fullfile(D.datastructPath, D.name), '-append', '-struct', 'D');

 
%% Set up experiment analysis parameters:

% =========================================================================
% Parameters:
% =========================================================================


% 1. Specifiy preprocessing method:
% --------------------------------------------
D.preprocessing = 'Acquisition2P';
% preprocessing = 'raw';


% 2.  Specify ROI type for current analysis:
% --------------------------------------------
%D.roiType = 'create_rois';
%D.roiType = 'condition';
%D.roiType = 'pixels';
D.roiType = 'cnmf';

switch D.roiType
    case 'create_rois'
        [fpath,fcond,~] = fileparts(D.sourceDir);
        D.maskSource = fcond;
    case 'condition'
        D.maskSource = 'retinotopy1';
        D.maskDidx = 1;
        D.maskDatastruct = sprintf('datastruct_%03d', D.maskDidx);
        fprintf('Using pre-defined masks from condition: %s.\n', D.maskSource);
        
        [fpath,fcond,~] = fileparts(D.sourceDir);
        D.maskSourcePath = fullfile(fpath, D.maskSource);
        pathToMasks = fullfile(D.maskSourcePath, 'analysis', D.maskDatastruct, 'masks');
        maskNames = dir(fullfile(pathToMasks, 'masks_*'));
        maskNames = {maskNames(:).name}';
        D.maskPaths = cell(1, length(maskNames));
        for maskIdx=1:length(maskNames)
            D.maskPaths{maskIdx} = fullfile(pathToMasks, maskNames{maskIdx});
        end
    case 'cnmf'
        [fpath,fcond,~] = fileparts(D.sourceDir);
        D.maskSource = fcond;
end

% =========================================================================
% Save analysis info:
% =========================================================================

save(fullfile(D.datastructPath, D.name), '-struct', 'D');


%% Create masks and get traces:

% =========================================================================
% Create masks, and save them:
% =========================================================================

slicesToUse = [5, 10, 15, 20];                            % Specify which slices to use (if empty, will grab traces for all slices)

switch D.roiType
    case 'create_rois'
        
        % Choose reference:
        % -----------------------------------------------------------------
        D.slices = slicesToUse;                            % Specify which slices to use (if empty, will grab traces for all slices)

        refMeta = load(meta.metaPath);                          % Get all TIFFs (slices) associated with file and volume of refRun movie.
        D.refRun = refMeta.file(1).si.motionRefNum;
        D.refPath = refMeta.file(D.refRun).si.tiffPath;
        
        % Create ROIs:
        % -----------------------------------------------------------------
        create_rois(D, refMeta);
                
        
        % Set up mask info struct to reuse masks across files:
        % -----------------------------------------------------------------
        D.maskType = 'circles';
        D.maskInfo = struct();
        D.maskInfo.refNum = D.refRun;
        D.maskInfo.refMeta = refMeta;
        D.maskInfo.maskType = D.maskType;

        maskDir = fullfile(dstructPath, 'masks');
        maskStructs = dir(fullfile(maskDir, '*.mat'));
        maskStructs = {maskStructs(:).name}';
        slicesToUse = zeros(1,length(maskStructs));
        for m=1:length(maskStructs)
            mparts = strsplit(maskStructs{m}, 'Slice');
            mparts = strsplit(mparts{2}, '_');
            slicesToUse(m) = str2num(mparts{1});
        end
        maskPaths = cell(1,length(maskStructs));
        for m=1:length(maskStructs)
            maskPaths{m} = fullfile(maskDir, maskStructs{m});
        end
        D.maskInfo.maskPaths = maskPaths;
        D.maskInfo.slices = slicesToUse;
        
        
        % =================================================================
        % Get traces with masks:
        % =================================================================
        tic()
        [D.tracesPath, D.nSlicesTrace] = getTraces(D);
        toc()
        save(fullfile(D.datastructPath, D.name), '-append', '-struct', 'D');
        
    case 'condition'
        % Use masks from a different condition:
        ref = load(fullfile(D.maskSourcePath, 'analysis', datastruct, sprintf('%s.mat', datastruct)));
        D.refRun = ref.refRun;
        refMeta = load(ref.metaPath);
        
        
        D.refPath = ref.refPath; %Meta.file(D.refRun).si.tiffPath;
        D.slices = ref.slices;
        
        D.maskInfo = struct();
        D.maskInfo = ref.maskInfo;
        D.maskType = ref.maskType;
        
        [D.tracesPath, D.nSlicesTrace] = getTraces(D);
        save(fullfile(D.datastructPath, D.name), '-append', '-struct', 'D');

        
    case 'pixels'
        
        D.maskType = 'pixels';
        
        % Set smoothing/filtering params:
        % -----------------------------------------------------------------
        D.params = struct();
        D.params.smoothXY = true;
        D.params.kernelXY = 5;
        
        D.slices = slicesToUse; % TMP 
        D.params.slicesToUse = slicesToUse;
        
        % =================================================================
        % Get traces:
        % =================================================================
        [D.tracesPath, D.nSlicesTrace] = getTraces(D);
        save(fullfile(D.dstructPath, D.name), '-append', '-struct', 'D');

    case 'cnmf'
        
        D.maskType = 'contours';
        D.slices = slicesToUse;

        % Get NMF params:
        % -----------------------------------------------------------------
        D.params = struct();
        
        D.params.K = 500; %50; %300; %50; %150; %35;                                      % number of components to be found
        D.params.tau = 2; %2; %4;                                      % std of gaussian kernel (size of neuron) 
        % tau = [1 1; 2 2];
        % K = [100; 50];

        D.params.p = 2;     % order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
        D.params.merge_thr = 0.8;                                  % merging threshold

%         D.params.options = CNMFSetParms(...                      
%             'd1',d1,'d2',d2,...                         % dimensions of datasets
%             'search_method','dilate','dist',3,...       % search locations when updating spatial components
%             'deconv_method','constrained_foopsi',...    % activity deconvolution method
%             'temporal_iter',2,...                       % number of block-coordinate descent steps 
%             'fudge_factor',0.98,...                     % bias correction for AR coefficients
%             'merge_thr',D.params.merge_thr,...                    % merging threshold
%             'gSig',tau,...%'method','lars',... %jyr
%             'thr_method', 'nrg'... %'max'...
%             );
        
        plotoutputs = false;
        D.params.scaleFOV = true;
        D.params.removeBadFrames = false;
        [nmfstruct, D.maskPaths] = getRoisNMF(D, meta, plotoutputs);
        
        D.params.nmfoptions = nmfstruct.options;
        clear nmfstruct;
        save(fullfile(D.dstructPath, D.name), '-append', '-struct', 'D');
        
        % =================================================================
        % Get traces:
        % =================================================================
        [tracesPath, nSlicesTrace] = getTraces(D, maskType, [], params); 
                    
end
