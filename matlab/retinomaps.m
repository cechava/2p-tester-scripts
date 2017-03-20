% RETINOTOPY.

% -------------------------------------------------------------------------
% Acquisition Information:
% -------------------------------------------------------------------------
% Get info for a given acquisition for each slice from specified analysis.
% This gives FFT analysis script access to all neeed vars stored from
% create_acquisition_structs.m pipeline.

acquisition_info;
trimEnd = true;

fstart = tic();
% -------------------------------------------------------------------------
% FFT analysis:
% -------------------------------------------------------------------------
% For each analysed slice, do FFT analysis on each file (i.e., run, or
% condition rep).
% For a given set of traces (on a given run) extracted from a slice, use 
% corresponding metaInfo for maps.

for sidx = 1:length(slicesToUse)

    currSlice = slicesToUse(sidx);
    fprintf('Processnig Slice %02d...\n', currSlice);
    
    M = load(maskPaths{sidx});
    %masks = M.masks;
    maskcell = M.maskcell;
    clear M;
        
    traceStruct = load(fullfile(tracesPath, traceNames{sidx}));
    
    fftStruct = struct();
    for fidx=1:nTiffs
        fprintf('Processing TIFF #%i...\n', fidx);
        
        meta = load(metaPath);
        
        sliceIdxs = currSlice:meta.file(fidx).si.nFramesPerVolume:meta.file(fidx).si.nTotalFrames;
        
        traces = traceStruct.traces.file{fidx};
        avgY = traceStruct.avgImage.file{fidx};
        

        targetFreq = meta.file(fidx).mw.targetFreq;
        nCycles = meta.file(fidx).mw.nCycles;
        nTotalSlices = meta.file(fidx).si.nFramesPerVolume;
        
        crop = meta.file(fidx).mw.nTrueFrames; %round((1/targetFreq)*ncycles*Fs);
        
        switch roiType
            case 'create_rois'
                [d1,d2] = size(avgY);
                [nrois, tpoints] = size(traceStruct.traces.file{fidx});
            case 'pixels'
                %[d1,d2,tpoints] = size(T.traces.file{fidx});
                [d1, d2] = size(avgY);
                tpoints = size(traceStruct.traces.file{fidx},3);
        end
        
        % Get phase and magnitude maps:
        phaseMap = zeros(d1, d2, 1);
        magMap = zeros(d1, d2, 1);
        ratioMap = zeros(d1, d2, 1);
        phaseMaxMag = zeros(d1, d2, 1);
        
        
        % Subtrace rolling average:
        Fs = meta.file(fidx).si.siVolumeRate;
        winsz = round((1/targetFreq)*Fs*2);
        %traceMat = arrayfun(@(x), subtractRollingMean(x,winsz),traces);
        traceMat = arrayfun(@(i) subtractRollingMean(traces(i, :), winsz), 1:size(traces, 1), 'UniformOutput', false);
        traceMat = cat(1, traceMat{1:end});
        untrimmedTraceMat = traceMat;
        if trimEnd
            traceMat = traceMat(:,1:crop);
            trimmedRawMat = traces(:,1:crop);
        end
        
        % Do FFT on each row:
        N = size(traceMat,2);
        dt = 1/Fs;
        t = dt*(0:N-1)';
        dF = Fs/N;
        freqs = dF*(0:N/2-1)';
        freqIdx = find(abs((freqs-targetFreq))==min(abs(freqs-targetFreq)));

        fftfun = @(x) fft(x)/N;
        fftMat = cell2mat(arrayfun(@(i) fftfun(traceMat(i,:)), 1:size(traces, 1), 'UniformOutput', false)');
        fftMat = fftMat(:, 1:N/2);
        fftMat(:,2:end) = fftMat(:,2:end).*2;
        
        magMat = abs(fftMat);
        ratioMat = magMat(:, freqIdx) ./ (sum(magMat, 2) - magMat(:, freqIdx));
        phaseMat = angle(fftMat);
        
        fftStruct.file(fidx).targetPhase = phaseMat(:, freqIdx);
        fftStruct.file(fidx).targetMat = magMat(:,freqIdx);
        
        [maxmag,maxidx] = max(magMat,[],2);
        maxFreqs = freqs(maxidx);
        
        fftStruct.file(fidx).freqsAtMaxMag = maxFreqs;
        fftStruct.file(fidx).fftMat = fftMat;
        fftStruct.file(fidx).traceMat = traceMat;
        fftStruct.file(fidx).untrimmedTraceMat = untrimmedTraceMat;
        fftStruct.file(fidx).rawMat = traces;
        fftStruct.file(fidx).trimmedRawMat = trimmedRawMat;
        fftStruct.file(fidx).sliceIdxs = sliceIdxs;
        fftStruct.file(fidx).targetFreq =targetFreq;
        fftStruct.file(fidx).freqs = freqs;
        fftStruct.file(fidx).targetFreqIdx = freqIdx;

        
        % ---------------- FIX:
        
        
        tic();
        phaseMap = assignRoiMap(maskcell, phaseMap, phaseMat, freqIdx);
        magMap = assignRoiMap(maskcell, magMap, magMat, freqIdx);
        ratioMap = assignRoiMap(maskcell, ratioMap, ratioMat);
        phaseMaxMag = assignRoiMap(maskcell, phaseMat, magMat, [], freqs);
        toc();
        
       

        
        
%         phaseMap(masks(:,:,roi)==1) = phaseMat(freqIdx); %phaseY(freqIdx);
%         magMap(masks(:,:,roi)==1) = magY(freqIdx);
%         ratioMap(masks(:,:,roi)==1) = ratioY;
%         %phaseMaxMag(masks(:,:,roi)==1) = phaseY(magY==max(magY));
%         phaseMaxMag(masks(:,:,roi)==1) = find(freqs==freqs(magY==max(magY))); % FIXED 03/2017
%         
        
        maps.file(fidx).magnitude = magMap;
        maps.file(fidx).phase = phaseMap;
        maps.file(fidx).phasemax = phaseMaxMag;
        maps.file(fidx).ratio = ratioMap;
        maps.file(fidx).avgY = avgY;

        % --- Need to reshape into 2d image if using pixels:
        if strcmp(roiType, 'pixels')
            mapTypes = fieldnames(maps);
            for map=1:length(mapTypes)
                currMap = maps.(mapTypes{map});
                currMap = reshape(currMap, [d1, d2, size(currMap,3)]);
                maps.(mapTypes{map}) = currMap;
            end
        end
        % ---   
    end
    
    % Save maps for current slice:
    mapStructName = sprintf('vecmaps_Slice%02d', currSlice);
    save_struct(outputDir, mapStructName, maps);

    fftStructName = sprintf('vecfft_Slice%02d', currSlice);
    save_struct(outputDir, fftStructName, fftStruct);

    %M.file(fidx) = maps;
    
    fprintf('Finished FFT analysis for Slice %02d.\n', currSlice);
    
end

clear fftStruct maps T

fprintf('TOTAL TIME ELAPSED:\n');
toc(fstart);

%% Get dF/F maps:

meta = load(metaPath);

minDf = 20;

fftNames = dir(fullfile(outputDir, 'vecfft_*'));
fftNames = {fftNames(:).name}';

dfStruct = struct();
for sidx = 1:length(slicesToUse)
    currSlice = slicesToUse(sidx);
    
    M = load(maskPaths{sidx});
    maskcell = M.maskcell;
    clear M;
    
    traceStruct = load(fullfile(tracesPath, traceNames{sidx}));
    fftName = sprintf('vecfft_Slice%02d.mat', currSlice);
    fftStruct = load(fullfile(outputDir, fftName));
    %F = load(fullfile(outputDir, fftNames{sidx}));
    
    meanMap = zeros(d1, d2, 1);
    maxMap = zeros(d1, d2, 1);
    
    for fidx=1:length(fftStruct.file)
        activeRois = [];
        nRois = length(maskcell);
        
        traces = traceStruct.traces.file{fidx};
        raw = fftStruct.file(fidx).trimmedRawMat;
        filtered = fftStruct.file(fidx).traceMat;
        adjusted = filtered + mean(raw,3);
        %dfFunc = @(x) (x-mean(x))./mean(x);
        %dfMat = cell2mat(arrayfun(@(i) dfFunc(adjusted(i, :)), 1:size(adjusted, 1), 'UniformOutput', false)');
        dfMat = arrayfun(@(i) extractDfTrace(adjusted(i, :)), 1:size(adjusted, 1), 'UniformOutput', false);
        dfMat = cat(1, dfMat{1:end})*100;
        
        meanDfs = mean(dfMat,2);
        maxDfs = max(dfMat, [], 2);
        activeRois = find(maxDfs >= minDf);
        fprintf('Found %i ROIs with dF/F > %02.f%%.\n', length(activeRois), minDf);
        
        meanMap = assignRoiMap(maskcell, meanMap, meanDfs);
        maxMap = assignRoiMap(maskcell, maxMap, maxDfs);
        
        %meanMap(masks(:,:,1:nRois)==1) = mean(dF,2);
        %maxMap(masks(:,:,1:nRois)==1) = max(dF,2);
        
        dfStruct.file(fidx).meanMap = meanMap;
        dfStruct.file(fidx).maxMap = maxMap;
        dfStruct.file(fidx).dfMat = dfMat;
        dfStruct.file(fidx).activeRois = activeRois;
        dfStruct.file(fidx).minDf = minDf;
        dfStruct.file(fidx).maxDfs = maxDfs;
        
    end
    
    dfName = sprintf('vecdf_Slice%02d', currSlice);
    save_struct(outputDir, dfName, dfStruct);

end