function DF = getDfMovie3Dnmf(D, varargin)

% Get dF/F maps:

meta = load(D.metaPath);
nTiffs = meta.nTiffs;

switch length(varargin)
    case 0
        minDf = 20;
    case 1
        minDf = varargin{1};
end

DF = struct();

%fftNames = dir(fullfile(D.outputDir, fftPrepend));
%fftNames = {fftNames(:).name}';

slicesToUse = D.slices;

dfstruct = struct();

%for sidx = 1:length(slicesToUse)
   
%currSlice = slicesToUse(sidx);
%fprintf('Processing SLICE %i...\n', currSlice);



% % Load 3D masks:
% masks = load(D.maskInfo.maskPaths{1});
% Not consistent -- FIX THSI.
% D.maskPaths is cell of paths to each slice's masks (for some reference
% FILE, usually, but for now, tested only on single file File003.
% This is silly, but was needed for single planar analyses and manual ROI
% selection.
% "3D masks" is in D.maskInfo.maskPaths, this is really just a single path,
% and it is different than the "standard" masks_Slice0x_File00y.mat naming
% stucture, since it is created/set during getRois3Dnmf()

% Load 3D Traces:
%tracestruct = load(fullfile(D.tracesPath, D.tracesName3D{fidx}));
%fftName = sprintf('%s_Slice%02d.mat', fftPrepend, currSlice);
%fftStruct = load(fullfile(D.outputDir, fftName));
%F = load(fullfile(outputDir, fftNames{sidx}));

for fidx=1:nTiffs
    
    % Load 3D masks:
    masks = load(D.maskInfo.maskPaths{fidx});
    
    % Load 3D traces:
    tracestruct = load(fullfile(D.tracesPath, D.traceNames3D{fidx}));
    
%     if isfield(masks, 'file')
    maskcell = masks.maskcell3D;
    centers = masks.centers;
%     else
%         maskcell = masks.maskcell;
%     end

    activeRois = [];
    nRois = size(tracestruct.rawTraces,2); %length(maskcell);

    avgY = tracestruct.avgImage;
    adjustTraces = tracestruct.traceMatDC; 
    % --> This is already corrected with DC -- do the following to get back
    % DC offset removed:  traceMat = bsxfun(@plus, DCs, traceMat);
    inferredTraces = tracestruct.inferredTraces;
    
    
    switch D.roiType
        case 'create_rois'
            [d1,d2] = size(avgY);
            [nframes, nrois] = size(adjustTraces);
        case 'condition'
            [d1,d2] = size(avgY);
            [nframes, nrois] = size(adjustTraces);
        case 'pixels'
            %[d1,d2,tpoints] = size(T.traces.file{fidx});
            [d1, d2] = size(avgY);
            nframes = size(adjustTraces,1);
            nrois = d1*d2;
        case 'cnmf'
            [d1,d2] = size(avgY);
            [nframes, nrois] = size(adjustTraces);
        case '3Dcnmf'
            [d1,d2] = size(avgY(:,:,1));
            [nframes, nrois] = size(adjustTraces);
    end
    blankMap = zeros([d1, d2]);
    maxMap = zeros([d1, d2]);

    %traces = tracestruct.traces.file{fidx};
    %raw = fftStruct.file(fidx).trimmedRawMat;
    %filtered = fftStruct.file(fidx).traceMat;
    %adjusted = filtered + mean(raw,3);
    %adjustTraces = tracestruct.traceMat.file{fidx}; 


    %dfFunc = @(x) (x-mean(x))./mean(x);
    %dfMat = cell2mat(arrayfun(@(i) dfFunc(adjusted(i, :)), 1:size(adjusted, 1), 'UniformOutput', false)');
%         dfMat = arrayfun(@(i) extractDfTrace(adjustTraces(i, :)), 1:size(adjustTraces, 1), 'UniformOutput', false);
    dfMat = arrayfun(@(i) extractDfTrace(adjustTraces(:,i)), 1:nrois, 'UniformOutput', false);
    dfMat = cat(2, dfMat{1:end})*100;

    meanDfs = mean(dfMat,1);
    maxDfs = max(dfMat);
    % Get rid of ridiculous values, prob edge effects:
    maxDfs(abs(maxDfs)>400) = NaN;
    activeRois = find(maxDfs >= minDf);
    fprintf('Found %i of %i ROIs with dF/F > %02.f%%.\n', length(activeRois), nrois, minDf);
    
    nslices =  size(avgY,3);
    meanMap = assignRoiMap3D(maskcell, centers, nslices, blankMap, meanDfs);
    maxMap = assignRoiMap3D(maskcell, centers, nslices, blankMap, maxDfs);
    
    % ----------------------------------------------------------
    % Make mean/max maps & get ROI traces from inferred traces:
    blankMap = zeros([d1, d2]);
    %dfMatInferred = arrayfun(@(i) extractDfTrace(inferredTraces(:,i)), 1:nrois, 'UniformOutput', false);
    %dfMatInferred = cat(2, dfMatInferred{1:end})*100;
    dfMatInferred = inferredTraces; % alrady df/f * 100
    
    meanDfsInferred = mean(inferredTraces,1);
    maxDfsInferred = max(inferredTraces);
    % Get rid of ridiculous values, prob edge effects:
    maxDfsInferred(abs(maxDfsInferred)>400) = NaN;
    activeRoisInferred = find(maxDfsInferred >= minDf);
    fprintf('Found %i of %i ROIs with inferred dF/F > %02.f%%.\n', length(activeRoisInferred), nrois, minDf);
    
    nslices =  size(avgY,3);
    meanMapInferred = assignRoiMap3D(maskcell, centers, nslices, blankMap, meanDfsInferred);
    maxMapInferred = assignRoiMap3D(maskcell, centers, nslices, blankMap, maxDfsInferred);
    % ----------------------------------------------------------

    
    
    % Sort df traces into "slices":
    currSliceRois = {};
    for sl=1:nslices
        currSliceRois{end+1} = find(centers(:,3)==sl);
    end
    
    dfMatSlices = {};
    dfMatSlicesInferred = {};
    for sl=1:nslices
        dfMatSlices{end+1} = dfMat(:,currSliceRois{sl});
        dfMatSlicesInferred{end+1} = dfMatInferred(:,currSliceRois{sl});
    end
    
    %meanMap(masks(:,:,1:nRois)==1) = mean(dF,2);
    %maxMap(masks(:,:,1:nRois)==1) = max(dF,2);
    for sidx=1:nslices
        
        currSlice = D.slices(sidx);
        
        DF.slice(currSlice).file(fidx).meanMap = meanMap(:,:,sidx);
        DF.slice(currSlice).file(fidx).maxMap = maxMap(:,:,sidx);        
        
        DF.slice(currSlice).file(fidx).meanMapInferred = meanMapInferred(:,:,sidx);
        DF.slice(currSlice).file(fidx).maxMapInferred = maxMapInferred(:,:,sidx);
        
        
        DF.slice(currSlice).file(fidx).dfMat = dfMatSlices{sidx};
        DF.slice(currSlice).file(fidx).dfMatInferred = dfMatSlicesInferred{sidx};
        
        DF.slice(currSlice).file(fidx).centers = currSliceRois{sidx};
    
        DF.slice(currSlice).file(fidx).activeRois = activeRois;
        DF.slice(currSlice).file(fidx).activeRoisInferred = activeRoisInferred;
        
        DF.slice(currSlice).file(fidx).minDf = minDf;
        
        DF.slice(currSlice).file(fidx).maxDfs = maxDfs;
        DF.slice(currSlice).file(fidx).maxDfsInferred = maxDfsInferred;
    end

end
    
%     dfName = sprintf('df_Slice%02d', currSlice);
%     save_struct(D.outputDir, dfName, dfstruct);
%     
%     D.dfStructName = dfName;
%     save(fullfile(D.datastructPath, D.name), '-append', '-struct', 'D');
%     
    %DF.slice(currSlice) = dfstruct;
    
    
%end

dfName = sprintf('dfstruct.mat');
save_struct(D.outputDir, dfName, DF);

DF.name = dfName;

% D.dfStructName = dfName;
% save(fullfile(D.datastructPath, D.name), '-append', '-struct', 'D');

   
end