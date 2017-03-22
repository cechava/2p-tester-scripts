function dfstruct = getDfMovie(D, varargin)

% Get dF/F maps:

meta = load(D.metaPath);
nTiffs = meta.nTiffs;

switch length(varargin)
    case 0
        minDf = 20;
        fftPrepend = 'fft_*';
    case 1
        minDf = varargin{1};
        fftPrepend = 'fft_*';
    case 2
        minDf = varargin{1};
        fftPrepend = varargin{2};
end



%fftNames = dir(fullfile(D.outputDir, fftPrepend));
%fftNames = {fftNames(:).name}';

slicesToUse = D.slices;

dfstruct = struct();
for sidx = 1:length(slicesToUse)
    currSlice = slicesToUse(sidx);
    
    M = load(D.maskPaths{sidx});
    maskcell = M.maskcell;
    clear M;
    
    tracestruct = load(fullfile(D.tracesPath, D.traceNames{sidx}));
    %fftName = sprintf('%s_Slice%02d.mat', fftPrepend, currSlice);
    %fftStruct = load(fullfile(D.outputDir, fftName));
    %F = load(fullfile(outputDir, fftNames{sidx}));
    
    meanMap = zeros(d1, d2, 1);
    maxMap = zeros(d1, d2, 1);
    
    for fidx=1:nTiffs
        activeRois = [];
        nRois = length(maskcell);
        
        %traces = tracestruct.traces.file{fidx};
        %raw = fftStruct.file(fidx).trimmedRawMat;
        %filtered = fftStruct.file(fidx).traceMat;
        %adjusted = filtered + mean(raw,3);
        adjustTraces = tracestruct.traceMat.file{fidx}; 
        % This is already corrected with DC -- do the following to get back
        % DC offset removed:  traceMat = bsxfun(@plus, DCs, traceMat);
        
        %dfFunc = @(x) (x-mean(x))./mean(x);
        %dfMat = cell2mat(arrayfun(@(i) dfFunc(adjusted(i, :)), 1:size(adjusted, 1), 'UniformOutput', false)');
        dfMat = arrayfun(@(i) extractDfTrace(adjustTraces(i, :)), 1:size(adjustTraces, 1), 'UniformOutput', false);
        dfMat = cat(1, dfMat{1:end})*100;
        
        meanDfs = mean(dfMat,2);
        maxDfs = max(dfMat, [], 2);
        activeRois = find(maxDfs >= minDf);
        fprintf('Found %i ROIs with dF/F > %02.f%%.\n', length(activeRois), minDf);
        
        meanMap = assignRoiMap(maskcell, meanMap, meanDfs);
        maxMap = assignRoiMap(maskcell, maxMap, maxDfs);
        
        %meanMap(masks(:,:,1:nRois)==1) = mean(dF,2);
        %maxMap(masks(:,:,1:nRois)==1) = max(dF,2);
        
        dfstruct.file(fidx).meanMap = meanMap;
        dfstruct.file(fidx).maxMap = maxMap;
        dfstruct.file(fidx).dfMat = dfMat;
        dfstruct.file(fidx).activeRois = activeRois;
        dfstruct.file(fidx).minDf = minDf;
        dfstruct.file(fidx).maxDfs = maxDfs;
        
    end
    
    dfName = sprintf('df_Slice%02d', currSlice);
    save_struct(D.outputDir, dfName, dfstruct);
    
    D.dfStructName = dfName;
    save(fullfile(D.datastructDir, D.name), '-append', '-struct', 'D');
    
    
end