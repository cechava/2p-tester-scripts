% RETINOTOPY.

% -------------------------------------------------------------------------
% Acquisition Information:
% -------------------------------------------------------------------------
% Get info for a given acquisition for each slice from specified analysis.
% This gives FFT analysis script access to all neeed vars stored from
% create_acquisition_structs.m pipeline.

% acquisition_info;
%session = '20161219_JR030W';
session = '20161221_JR030W';

%experiment = 'retinotopy2';
%experiment = 'test_crossref';
%experiment = 'retinotopyFinalMask';
experiment = 'test_crossref/nmf';

analysis_no = 7;
tefo = true;

D = loadAnalysisInfo(session, experiment, analysis_no, tefo);


%trimEnd = true;
slicesToUse = D.slices;

meta = load(D.metaPath);
nTiffs = meta.nTiffs;

% -------------------------------------------------------------------------
% Process traces for FFT analysis:
% -------------------------------------------------------------------------
% for sidx = 1:length(slicesToUse)
% 
%     currSlice = slicesToUse(sidx);
%     fprintf('Processing traces for Slice %02d...\n', currSlice);
%     
% Assumes all TIFFs are reps of e/o, so just use file1:
targetFreq = meta.file(1).mw.targetFreq;
winUnit = (1/targetFreq);
crop = meta.file(1).mw.nTrueFrames; %round((1/targetFreq)*ncycles*Fs);
nWinUnits = 3;
switch D.roiType
    case '3Dcnmf'
        processTraces3Dnmf(D, winUnit, nWinUnits, crop)
    case 'cnmf'
        % do other stuff
    otherwise
        processTraces(D, winUnit, nWinUnits, crop)
end

% end

% -------------------------------------------------------------------------
% Get DF/F for whole movie:
% -------------------------------------------------------------------------
dfMin = 20;
switch D.roiType
    case '3Dcnmf'
        dfstruct = getDfMovie3Dnmf(D, dfMin);
    case 'cnmf'
        % do other stuff
    otherwise
        dfstruct = getDfMovie(D, dfMin);
end

D.dfStructName = dfstruct.name;
save(fullfile(D.datastructPath, D.name), '-append', '-struct', 'D');


% Get legends:
legends = makeLegends(D.outputDir);
meta.legends = legends;
save(D.metaPath, '-append', '-struct', 'meta');

%%

fstart = tic();
% -------------------------------------------------------------------------
% FFT analysis:
% -------------------------------------------------------------------------
% For each analysed slice, do FFT analysis on each file (i.e., run, or
% condition rep).
% For a given set of traces (on a given run) extracted from a slice, use 
% corresponding metaInfo for maps.

mapStructNames = cell(1,length(slicesToUse));
fftStructNames = cell(1,length(slicesToUse));
for sidx = 1:length(slicesToUse)

    currSlice = slicesToUse(sidx); % - slicesToUse(1) + 1;
    fprintf('Processing Slice %02d of %i slices...\n', currSlice, length(slicesToUse));
    
    % Load masks:
    if ~strcmp(D.roiType, 'pixels')
        maskstruct = load(D.maskPaths{sidx});
    end
    
    % Load tracestruct:
    tracestruct = load(fullfile(D.tracesPath, D.traceNames{sidx}));
    
    fftStruct = struct();
    for fidx=1:nTiffs
        fprintf('Processing TIFF #%i...\n', fidx);
        
        if ~strcmp(D.roiType, 'pixels')
            if isfield(maskstruct, 'file')
                maskcell = maskstruct.file(fidx).maskcell;
            else
                maskcell = maskstruct.maskcell;
            end

            if isempty(maskcell)
                continue;
            end
        end
        
        %sliceIdxs = currSlice:meta.file(fidx).si.nFramesPerVolume:meta.file(fidx).si.nTotalFrames;
        sliceIdxs = slicesToUse(sidx):meta.file(fidx).si.nFramesPerVolume:meta.file(fidx).si.nTotalFrames;

        expectedTimes = linspace(0, meta.file(fidx).mw.mwDur, meta.file(fidx).mw.nTrueFrames);
        expectedTImes = expectedTimes + meta.file(fidx).mw.mwSec(1); % add offset between trigger and stim-display
        
        %traces = traceStruct.traces.file{fidx};
        if isfield(tracestruct.file(fidx), 'inferredTraces')
            inferredTraces = tracestruct.file(fidx).inferredTraces;
            inferred = true;
        else
            inferred = false;
        end
        
        traceMatDC = tracestruct.file(fidx).traceMatDC;
        DCs = tracestruct.file(fidx).DCs;
        tmptraces = bsxfun(@minus, traceMatDC, DCs);
        traces = tracestruct.file(fidx).traceMat;
        
        if iscell(tracestruct.file(fidx).avgImage)
            avgY = tracestruct.file(fidx).avgImage{1};
        else
            avgY = tracestruct.file(fidx).avgImage;
        end
        
        targetFreq = meta.file(fidx).mw.targetFreq;
        nCycles = meta.file(fidx).mw.nCycles;
        nTotalSlices = meta.file(fidx).si.nFramesPerVolume;
        
        %crop = meta.file(fidx).mw.nTrueFrames; %round((1/targetFreq)*ncycles*Fs);
        
        switch D.roiType
            case 'create_rois'
                [d1,d2] = size(avgY);
                [nframes,nrois] = size(traces);
            case 'condition'
                [d1,d2] = size(avgY);
                [nframes,nrois] = size(traces);
            case 'pixels'
                %[d1,d2,tpoints] = size(T.traces.file{fidx});
                [d1, d2] = size(avgY);
                nframes = size(traces,1);
                nrois = d1*d2;
            case 'cnmf'
                [d1,d2] = size(avgY);
                [nframes,nrois] = size(traces);
            case '3Dcnmf'
                [d1,d2,d3] = size(avgY);
                [nframes,nrois] = size(traces);
        end
        
        % Get phase and magnitude maps:
        phaseMap = zeros([d1, d2]);
        magMap = zeros([d1, d2]);
        ratioMap = zeros([d1, d2]);
        phaseMaxMag = zeros([d1, d2]);
        
        % ---
        if inferred
            phaseMapInferred = zeros([d1, d2]);
            magMapInferred = zeros([d1, d2]);
            ratioMapInferred = zeros([d1, d2]);
            phaseMaxMagInferred = zeros([d1, d2]);
        end
        % ---
        
        
        % Subtrace rolling average:
        Fs = meta.file(fidx).si.siVolumeRate;
        %winUnit = (1/targetFreq);
        
%         winsz = round((1/targetFreq)*Fs*2);
%         %traceMat = arrayfun(@(x), subtractRollingMean(x,winsz),traces);
%         traceMat = arrayfun(@(i) subtractRollingMean(traces(i, :), winsz), 1:size(traces, 1), 'UniformOutput', false);
%         traceMat = cat(1, traceMat{1:end});
%         untrimmedTraceMat = traceMat;
%         if trimEnd
%             traceMat = traceMat(:,1:crop);
%             trimmedRawMat = traces(:,1:crop);
%         end
    
        % TODO:  fix fft sampling to interp (option):
        % ...
        % 
        
        % Do FFT on each row:
        N = size(traces,1);
        dt = 1/Fs;
        t = dt*(0:N-1)';
        dF = Fs/N;
        freqs = dF*(0:N/2-1)';
        freqIdx = find(abs((freqs-targetFreq))==min(abs(freqs-targetFreq)));

        fftfun = @(x) fft(x)/N;
        fftMat = arrayfun(@(i) fftfun(traces(:,i)), 1:size(traces,2), 'UniformOutput', false);
        fftMat = cat(2, fftMat{1:end});
      
        fftMat = fftMat(1:N/2, :);
        fftMat(2:end,:) = fftMat(2:end,:).*2;

        magMat = abs(fftMat);
        ratioMat = magMat(freqIdx,:) ./ (sum(magMat, 1) - magMat(freqIdx,:));
        phaseMat = angle(fftMat);

        [maxmag,maxidx] = max(magMat);
        maxFreqs = freqs(maxidx);
        

        % Get FFT-MAT for inferred: ---------------------------------
        if inferred
            fftMatInferred = arrayfun(@(i) fftfun(inferredTraces(:,i)), 1:size(inferredTraces,2), 'UniformOutput', false);
            fftMatInferred = cat(2, fftMatInferred{1:end});

            fftMatInferred = fftMatInferred(1:N/2, :);
            fftMatInferred(2:end,:) = fftMatInferred(2:end,:).*2;

            magMatInferred = abs(fftMatInferred);
            ratioMatInferred = magMatInferred(freqIdx,:) ./ (sum(magMatInferred, 1) - magMatInferred(freqIdx,:));
            phaseMatInferred = angle(fftMatInferred);

            [maxmag2,maxidx2] = max(magMatInferred);
            maxFreqsInferred = freqs(maxidx2);
        end
        % ------------------------------------------------------------
        
        
        fftStruct.file(fidx).targetPhase = phaseMat(freqIdx,:);
        fftStruct.file(fidx).targetMag = magMat(freqIdx,:);
        fftStruct.file(fidx).freqsAtMaxMag = maxFreqs;
        fftStruct.file(fidx).fftMat = fftMat;
        fftStruct.file(fidx).traces = traces;
        fftStruct.file(fidx).sliceIdxs = sliceIdxs;
        fftStruct.file(fidx).targetFreq = targetFreq;
        fftStruct.file(fidx).freqs = freqs;
        fftStruct.file(fidx).targetFreqIdx = freqIdx;
        fftStruct.file(fidx).magMat = magMat;
        fftStruct.file(fidx).ratioMat = ratioMat;
        fftStruct.file(fidx).phaseMat = phaseMat;

        
        % Get MAPS for current slice: ---------------------------------
        tic();
        if strcmp(D.roiType, 'pixels')
            phaseMap = reshape(phaseMat(freqIdx,:), [d1, d2]);
            magMap = reshape(magMat(freqIdx,:), [d1, d2]);
            ratioMap = reshape(ratioMat, [d1, d2]);
            phasesAtMaxMag = arrayfun(@(i) freqs(magMat(:,i)==max(magMat(:,i))), 1:nrois);
            phaseMaxMag = reshape(phasesAtMaxMag, [d1, d2]);
        else
            phaseMap = assignRoiMap(maskcell, phaseMap, phaseMat, freqIdx);
            magMap = assignRoiMap(maskcell, magMap, magMat, freqIdx);
            ratioMap = assignRoiMap(maskcell, ratioMap, ratioMat);
            phaseMaxMag = assignRoiMap(maskcell, phaseMat, magMat, [], freqs);
        end

        % --
        if inferred
            phaseMapInferred = assignRoiMap(maskcell, phaseMapInferred, phaseMatInferred, freqIdx);
            magMapInferred = assignRoiMap(maskcell, magMapInferred, magMatInferred, freqIdx);
            ratioMapInferred = assignRoiMap(maskcell, ratioMapInferred, ratioMatInferred);
            phaseMaxMagInferred = assignRoiMap(maskcell, phaseMatInferred, magMatInferred, [], freqs);
        end
        % ---
        
        toc();
        
        maps.file(fidx).magnitude = magMap;
        maps.file(fidx).phase = phaseMap;
        maps.file(fidx).phasemax = phaseMaxMag;
        maps.file(fidx).ratio = ratioMap;
        maps.file(fidx).avgY = avgY;
        
        % ---
        if inferred
            maps.file(fidx).magnitudeInferred = magMapInferred;
            maps.file(fidx).phaseInferred = phaseMapInferred;
            maps.file(fidx).phasemaxInferred = phaseMaxMagInferred;
            maps.file(fidx).ratioInferred = ratioMapInferred;
        end
        % ---

        % --- Need to reshape into 2d image if using pixels:
%         if strcmp(D.roiType, 'pixels')
%             mapTypes = fieldnames(maps);
%             for map=1:length(mapTypes)
%                 currMap = maps.(mapTypes{map});
%                 currMap = reshape(currMap, [d1, d2, size(currMap,3)]);
%                 maps.(mapTypes{map}) = currMap;
%             end
%         end
        % --------------------------------------------------------------
        
    end
    
    % Save maps for current slice:
    mapStructName = sprintf('maps_Slice%02d', D.slices(sidx));
    save_struct(D.outputDir, mapStructName, maps);

    fftStructName = sprintf('fft_Slice%02d', D.slices(sidx));
    save_struct(D.outputDir, fftStructName, fftStruct);

    %M.file(fidx) = maps;
    
    fprintf('Finished FFT analysis for Slice %02d.\n', D.slices(sidx));
    
    mapStructNames{sidx} = mapStructName;
    fftStructNames{sidx} = fftStructName;
end

clear fftStruct maps T

fprintf('TOTAL TIME ELAPSED:\n');
toc(fstart);

D.mapStructNames = mapStructNames;
D.fftStructNames = fftStructNames;
save(fullfile(D.datastructPath, D.name), '-append', '-struct', 'D');


%% Get dF/F maps:
% 
% meta = load(D.metaPath);
% 
% minDf = 20;
% 
% fftNames = dir(fullfile(outputDir, 'vecfft_*'));
% fftNames = {fftNames(:).name}';
% 
% dfStruct = struct();
% for sidx = 1:length(slicesToUse)
%     currSlice = slicesToUse(sidx);
%     
%     M = load(maskPaths{sidx});
%     maskcell = M.maskcell;
%     clear M;
%     
%     traceStruct = load(fullfile(tracesPath, traceNames{sidx}));
%     fftName = sprintf('vecfft_Slice%02d.mat', currSlice);
%     fftStruct = load(fullfile(outputDir, fftName));
%     %F = load(fullfile(outputDir, fftNames{sidx}));
%     
%     meanMap = zeros(d1, d2, 1);
%     maxMap = zeros(d1, d2, 1);
%     
%     for fidx=1:length(fftStruct.file)
%         activeRois = [];
%         nRois = length(maskcell);
%         
%         traces = traceStruct.traces.file{fidx};
%         raw = fftStruct.file(fidx).trimmedRawMat;
%         filtered = fftStruct.file(fidx).traceMat;
%         adjusted = filtered + mean(raw,3);
%         %dfFunc = @(x) (x-mean(x))./mean(x);
%         %dfMat = cell2mat(arrayfun(@(i) dfFunc(adjusted(i, :)), 1:size(adjusted, 1), 'UniformOutput', false)');
%         dfMat = arrayfun(@(i) extractDfTrace(adjusted(i, :)), 1:size(adjusted, 1), 'UniformOutput', false);
%         dfMat = cat(1, dfMat{1:end})*100;
%         
%         meanDfs = mean(dfMat,2);
%         maxDfs = max(dfMat, [], 2);
%         activeRois = find(maxDfs >= minDf);
%         fprintf('Found %i ROIs with dF/F > %02.f%%.\n', length(activeRois), minDf);
%         
%         meanMap = assignRoiMap(maskcell, meanMap, meanDfs);
%         maxMap = assignRoiMap(maskcell, maxMap, maxDfs);
%         
%         %meanMap(masks(:,:,1:nRois)==1) = mean(dF,2);
%         %maxMap(masks(:,:,1:nRois)==1) = max(dF,2);
%         
%         dfStruct.file(fidx).meanMap = meanMap;
%         dfStruct.file(fidx).maxMap = maxMap;
%         dfStruct.file(fidx).dfMat = dfMat;
%         dfStruct.file(fidx).activeRois = activeRois;
%         dfStruct.file(fidx).minDf = minDf;
%         dfStruct.file(fidx).maxDfs = maxDfs;
%         
%     end
%     
%     dfName = sprintf('vecdf_Slice%02d', currSlice);
%     save_struct(outputDir, dfName, dfStruct);
% 
% end
