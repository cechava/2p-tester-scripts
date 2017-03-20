clear all;
clc;

%% DEFINE SOURCE DIRECTORY:

% Define source dir for current acquisition/experiment:
sourceDir = '/nas/volume1/2photon/RESDATA/20161221_JR030W/rsvp';

%sourceDir = '/nas/volume1/2photon/RESDATA/20161221_JR030W/retinotopy037Hz';

% sourceDir = '/nas/volume1/2photon/RESDATA/20161222_JR030W/retinotopy1/';
% sourceDir = '/nas/volume1/2photon/RESDATA/TEFO/20161218_CE024/raw/bar5';
analysisDir = fullfile(sourceDir, 'analysis');
if ~exist(analysisDir, 'dir')
    mkdir(analysisDir);
end

% Define TIFF dir if is sub-dir within the source-dir:
channelIdx = 1;
%nchannels = 1;
%tiff_dir = sprintf('Corrected_Channel%02d', channelIdx);
%tiff_dir = sprintf('Corrected');

acquisitionName = 'fov2_rsvp_25reps';
%acquisitionName = 'fov1_bar037Hz_run4';


%% Define datastruct name for analysis:


didx = 1;

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
    uinput = input('Press Y/n to overwrite or create new: ', 's');
    if strcmp(uinput, 'Y')
        D = struct();
        fprintf('New datastruct created: %s.\n', datastruct);
        fprintf('Not yet saved. Exit now to load existing datastruct.\n');
    else
        didx = input('Enter # to create new datastruct: ');
        datastruct = sprintf('datastruct_%03d', didx);
        while ismember(datastruct, existingAnalyses)
            didx = input('Analysis %s already exists... Choose again.', datastruct);
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
save(fullfile(dstructPath, datastruct), '-append', '-struct', 'D');


%% Get SI volume info:

switch metaInfo
    case 'SI'
       
        siMetaName = sprintf('%s.mat', acquisitionName);
        
        if ~exist(fullfile(sourceDir, siMetaName))
            
            % Load and parse raw TIFFs and create SI-specific meta file:
            movies = dir(fullfile(sourceDir,'*.tif'));
            movies = {movies(:).name};
            writeDir = fullfile(sourceDir, tiffSource);
            if ~exist(writeDir, 'dir')
                mkdir(writeDir)
            end
            parseSIdata(acquisitionName, movies, sourceDir, writeDir);
            
            % Load newly-created meta struct:
            %siMeta = load(fullfile(sourceDir, siMetaName));
            %meta = struct();
            %meta.(acquisitionName) = siMeta.metaDataSI; % Have info for each file, but this was not corrected in previosuly run MCs...
        end
        
        % Creata META with SI (acquisition) and MW (experiment) info:
        meta = createMetaStruct(D);
        
        % Sort Parsed files into separate directories if needed:
        if length(dir(fullfile(sourceDir, tiffSource))) > meta.nChannels
            sort_parsed_tiffs(sourceDir, tiffSource, meta.nChannels);
        end
      
    case 'manual' % No motion-correction/processing, just using raw TIFFs.
        nVolumes = 350;
        nSlices = 20;
        nDiscard = 0;
        
        nFramesPerVolume = nSlices + nDiscard;
        nTotalFrames = nFramesPerVolume * nVolumes;
        
        %.....

end

% Get paths to each FILE directory (into which TIFFs have been parsed):

% channelDir = sprintf('Channel%02d', channelIdx);
% tmpTiffs = dir(fullfile(sourceDir, tiffSource, channelDir));
% tmpTiffs = tmpTiffs(arrayfun(@(x) ~strcmp(x.name(1),'.'),tmpTiffs));
% tiffDirs = {tmpTiffs(:).name}';
% nTiffs = length(tiffDirs);
% fprintf('Found %i TIFF stacks for current acquisition analysis.\n', nTiffs);
% if meta.nTiffs ~= nTiffs
%     fprintf('Check META file at: %s\n', meta.metaPath);
%     fprintf('Meta: %i | Found TIFFS in dir: %i.\n', meta.nTiffs, nTiffs);
% end

D.metaPath = meta.metaPath;
D.nTiffs = meta.nTiffs;
D.nChannels = meta.nChannels;
D.stimType = meta.stimType;

save(fullfile(dstructPath, datastruct), '-append', '-struct', 'D');


%% Specify experiment parameters:

%createMetastruct(sourceDir, acquisitionName);

% mwPath = fullfile(sourceDir, 'mw_data');
% mw = get_mw_info(analysisDir, acquisitionName, mwPath, nTiffs); % pymat = mw.pymat;
% 
% % Create arbitrary stimtype codes:
% stimTypes = cell(1,length(mw.condTypes));
% for sidx=1:length(mw.condTypes)
%     sname = sprintf('code%i', sidx);
%     stimTypes{sidx} = sname;
% end
% 
% % Get indices of each run to preserve order when indexing into MW
% % file-structs:
% runOrder = struct();
% for runIdx=1:length(mw.runNames)
%     runOrder.(mw.runNames{runIdx}) = mw.pymat.(mw.runNames{runIdx}).ordernum + 1;
% end
% 
% mw.stimTypes = stimTypes;
% mw.runOrder = runOrder;
% 
% currStructName = char(sprintf('MW_%s.mat', acquisitionName));
% mwPath = fullfile(analysisDir, 'MW');
% if ~exist(mwPath)
%     mkdir(mwPath)
% end
% 
% save(fullfile(mwPath, currStructName), '-struct', 'mw');

%% Grab experiment info for each slice and save a .mat for each run.
%  Stores MW / ARD stimulus info & metadata from SI.
% 
% tiff = struct();
% for fidx=1:nTiffs
%     
%     currMWfidx = mw.MWfidx + fidx - 1;
%     
%     % Make sure to grab the correct run based on TIFF order number:
%     for orderIdx=1:length(fieldnames(runOrder))
%         if runOrder.(mw.runNames{orderIdx}) == currMWfidx
%             currRunName = mw.runNames{orderIdx};
%         end
%     end
%     
%     % --
% 
%     mwSec = (double(mw.pymat.(currRunName).time) - double(mw.pymat.(currRunName).time(1))) / 1E6;
%     cycleStarts = mw.pymat.(currRunName).idxs + 1; % Get indices of cycle starts
% 
%     mwDur = (double(mw.pymat.triggers(currMWfidx,2)) - double(mw.pymat.triggers(currMWfidx,1))) / 1E6;
%     
%     if exist('siFrameTimes')
%         siSec = siFrameTimes;
%     else
%         if isfield(mw.pymat, 'ard_file_durs')
%             ardDur = double(mw.pymat.ard_file_durs(currMWfidx));
%             %if sample_us==1 % Each frame has a t-stamped frame-onset (only true if ARD sampling every 200us, isntead of standard 1ms)
%             siSec = (double(mw.pymat.frame_onset_times{currMWfidx}) - double(mw.pymat.frame_onset_times{currMWfidx}(1))) / 1E6; 
%             if length(si_sec) < nTotalFrames % there are missed frame triggers
%                 siSec = linspace(0, ardDur, nTotalFrames);
%                 % This is pretty accurate.. only off by ~ 3ms compared to SI's
%                 % trigger times.
%             end
%         else
%             siSec = linspace(0, mwDur, nTotalFrames);
%         end
%     end
%     
%     
%     if strcmp(mw.pymat.stimtype, 'bar')
%         trimLong = 1;
%         ncycles = mw.pymat.info.ncycles;
%         targetFreq = mw.pymat.info.target_freq;
%         %siFrameRate = 1/median(diff(siSec));
%         %siVolumeRate = round(siFrameRate/nFramesPerVolume, 2); % 5.58%4.11 %4.26 %5.58
%         nTrueFrames = ceil((1/targetFreq)*siVolumeRate*ncycles);
%         tiff.mw.targetFreq = targetFreq;
%         tiff.mw.nTrueFrames = nTrueFrames;
%     else
%         ncycles = length(cycleStarts);
%     end
%     
%     tiff.acquisitionName = acquisitionName;
%     tiff.mw.mwRunName = currRunName;
%     tiff.mw.MWfidx = currMWfidx;
%     tiff.mw.mwPath = mw.mwPath;
%     %tiff.run_fn = M.run_fns;
%     tiff.mw.mwSec = mwSec;
%     tiff.mw.stimStarts = cycleStarts;
%     tiff.mw.mwDur = mwDur;
%     tiff.mw.siSec = siSec;
%     tiff.mw.ncycles = ncycles;
%     tiff.mw.pymat = mw.pymat;
%     
%     tiff.si.nChannels = nChannels;
%     tiff.si.siFrameTimes = siFrameTimes;
%     tiff.si.siFrameRate = siFrameRate;
%     tiff.si.siVolumeRate = siVolumeRate;
%     tiff.si.nVolumes = nVolumes;
%     tiff.si.nSlices = nSlices;
%     tiff.si.nTotalSlices = nSlices + nDiscard;
%     tiff.si.nTotalFrames = nTotalFrames;
%     tiff.si.nFramesPerVolume = nFramesPerVolume;
%     tiff.si.tiffPath = fullfile(sourceDir, tiffSource, channelDir, tiffDirs{fidx});
%     tiff.si.imgX = frameWidth;
%     tiff.si.imgY = frameHeight;
%     
%     tiff.si.tiffIdx = fidx;
%    
%     currStructName = char(sprintf('meta_File%03d.mat', fidx));
%     metaPath = fullfile(analysisDir, 'meta');
%     if ~exist(metaPath)
%         mkdir(metaPath)
%     end
%     
%     save(fullfile(metaPath, currStructName), '-struct', 'tiff');
%     
% end
    
%% Set up experiment analysis parameters:

% =========================================================================
% Parameters:
% =========================================================================


% 1. Specifiy preprocessing method:
% --------------------------------------------
preprocessing = 'Acquisition2P';
% preprocessing = 'raw';


% 2.  Specify ROI type for current analysis:
% --------------------------------------------
% roiType = 'create_rois';
roiType = 'condition';
% roiType = 'pixels';

switch roiType
    case 'create_rois'
        [fpath,fcond,~] = fileparts(sourceDir);
        maskSource = fcond;
    case 'condition'
        maskSource = 'retinotopy037Hz';
        fprintf('Using pre-defined masks from condition: %s.\n', maskSource);
        maskSourcePath = fullfile(fpath, maskSource);
        pathToMasks = fullfile(maskSourcePath, 'analysis', datastruct, 'masks');
        maskNames = dir(fullfile(pathToMasks, 'masks_*'));
        maskNames = {maskNames(:).name}';
        maskPaths = cell(1, length(maskNames));
        for maskIdx=1:length(maskNames)
            maskPaths{maskIdx} = fullfile(pathToMasks, maskNames{maskIdx});
        end
end

% [fpath,fcond,~] = fileparts(sourceDir);
% if strcmp(roiType, 'condition')
%     maskSource = 'retinotopy037Hz';
%     maskSourcePath = fullfile(fpath, maskSource);
%     pathToMasks = fullfile(maskSourcePath, 'analysis', datastruct, 'masks');
%     maskNames = dir(fullfile(pathToMasks, 'masks_*'));
%     maskNames = {maskNames(:).name}';
%     maskPaths = cell(1, length(maskNames));
%     for maskIdx=1:length(maskNames)
%         maskPaths{maskIdx} = fullfile(pathToMasks, maskNames{maskIdx});
%     end
%     
% end

% roiType: 
%   'create_rois' : create new ROIs using circle-GUI
%   'smoothed_pixels' : use all pixels, but smooth with kernel size,
%   ksize=2 (default)
%   'prev_rois' : use previosuly-created ROIs 
% --
% TO DO:  1. option to specify kernel size
%         2.  let user select which ROI set to use in a non-stupid way...

% % -------------------------
% channelIdx = 1;
% 
% % -------------------------
% metaStructs = dir(fullfile(D.metaPath, sprintf('meta_%s*', acquisitionName)));
% metaStructName = {metaStructs(:).name}';
% metaPaths = cell(1, length(metaStructName));
% for m=1:length(metaStructs)
%     metaPaths{m} = fullfile(D.metaPath, metaStructName{m});
% end
% 


% =========================================================================
% Save analysis info:
% =========================================================================

% didx = 1;
% 
% datastruct = sprintf('datastruct_%03d', didx);
% dstructPath = fullfile(analysisDir, datastruct);
% if ~exist(dstructPath)
%     mkdir(dstructPath)
%     D = struct();
% end
%D = struct();


D.preprocessing = preprocessing;
D.roiType = roiType;
if strcmp(D.roiType, 'condition')
    D.maskPaths = maskPaths;
    D.maskSource = maskSource;
    D.maskSourcePath = maskSourcePath;
end

save(fullfile(dstructPath, datastruct), '-struct', 'D');


%% Create masks and get traces:

% =========================================================================
% Create masks, and save them:
% =========================================================================
% 
% refRun = 1;                                                 % Use ref movie from motion-correction if applicable (obj.refMovNum from Acquisition2P class).
% slicesToUse = [5, 10, 15, 20];                            % Specify which slices to use (if empty, will grab traces for all slices)
% 
% refMeta = load(metaPaths{refRun});
% traceNames = dir(fullfile(refMeta.si.tiffPath, '*.tif'));
% traceNames = {traceNames(:).name}';                           % Get all TIFFs (slices) associated with file and volume of refRun movie.

switch roiType
    case 'create_rois'
        
        % Choose reference:
        % -----------------------------------------------------------------
        %refRun = 1; % Use ref movie from motion-correction if applicable (obj.refMovNum from Acquisition2P class).
        slicesToUse = [5, 10, 15, 20];                            % Specify which slices to use (if empty, will grab traces for all slices)

        refMeta = load(meta.metaPath);
        %traceNames = dir(fullfile(refMeta.si.tiffPath, '*.tif'));
        %traceNames = {traceNames(:).name}';                           % Get all TIFFs (slices) associated with file and volume of refRun movie.
        refRun = refMeta.file(1).si.motionRefNum;
        
        % Create ROIs:
        % -----------------------------------------------------------------
        create_rois(D, refMeta, slicesToUse);
                
        
        % Set up mask info struct to reuse masks across files:
        % -----------------------------------------------------------------
        maskType = 'circles';
        maskInfo = struct();
        maskInfo.refNum = refRun;
        maskInfo.refMeta = refMeta;
        maskInfo.maskType = maskType;

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
        maskInfo.maskPaths = maskPaths;
        maskInfo.slicesToUse = slicesToUse;
        
        
        % =================================================================
        % Get traces with masks:
        % =================================================================
        [tracesPath, nSlicesTrace] = get_traces(D, maskType, maskInfo);
    
    case 'condition'
        % Use masks from a different condition:
        ref = load(fullfile(D.maskSourcePath, 'analysis', datastruct, sprintf('%s.mat', datastruct)));
        refRun = ref.refRun;
        slicesToUse = ref.slices;
        
        refMeta = load(ref.metaPaths{refRun});
        maskInfo = struct();
        maskInfo = ref.maskInfo;
        maskType = ref.maskType;
        
        [tracesPath, nSlicesTrace] = get_traces(D, maskType, maskInfo);
        
    case 'pixels'
        
        maskType = 'pixels';
        
        % Set smoothing/filtering params:
        % -----------------------------------------------------------------
        params = struct();
        params.smoothXY = true;
        params.kernelXY = 5;
        
        slicesToUse = [5, 10, 15, 20]; % TMP 
        params.slicesToUse = slicesToUse;
        

        
        % =================================================================
        % Get traces:
        % =================================================================
        [tracesPath, nSlicesTrace] = get_traces(D, maskType, [], params);

    case 'nmf'
        
        maskType = 'nmf';
        
        % Get NMF params:
        % -----------------------------------------------------------------
        params = struct();
        
        
        
        
        % =================================================================
        % Get traces:
        % =================================================================
        [tracesPath, nSlicesTrace] = get_traces(D, maskType, [], params); 
                    
end


% Update analysis info struct:
% -------------------------------------------------------------------------

D.refRun = refRun;
D.refPath = refMeta.file(refRun).si.tiffPath;
D.slices = slicesToUse;

D.maskType = maskType;
if strcmp(D.maskType, 'circles')
    D.maskInfo = maskInfo;
    D.maskType = maskType;
else
    D.params = params;
end

D.tracesPath = tracesPath; 
D.nSlicesSelected = nSlicesTrace;

save(fullfile(dstructPath, datastruct), '-append', '-struct', 'D');

        
%%  Align stimulus events to traces:

% Load metadata if needed:
metaStructs = dir(metaPath);
metaStructs = {metaStructs(:).name}';

% Load traces if needed:
traces_path = fullfile(dstructPath, 'traces');
traces_structs = dir(traces_path);
traces_structs = {traces_structs(:).name}';


% % Load FFT analysis structs if needed:
% roiType = 'pixels';
% fft_structs = dir(fullfile(struct_dir, sprintf('*FFT_*%s*', roiType)));
% fft_structs = {fft_structs(:).name}';

%%

% Retinotopy:

% slices = [12, 14, 16];
tmpTraceNames = dir(fullfile(analysisDir, 'traces', '*traces_*_pixels*'));
traceNames = {tmpTraceNames(:).name};

for sidx = 10:length(traceNames)
    traceName = traceNames{sidx};
    load(fullfile(analysisDir, 'traces', traceName))

    nfiles = length(T.traces.file);
    for fidx = 1:nfiles
        traces = T.traces.file{fidx};
        masks = T.masks.file{fidx};
        avgY = T.avgImage.file{fidx};

        Fs = meta.siVolumeRate;
        targetFreq = meta.targetFreq;
        ncycles = meta.ncycles;
        ntotal_slices = meta.nFramesPerVolume;

        cut_end=1;
        crop = meta.nTrueFrames; %round((1/targetFreq)*ncycles*Fs);

        winsz = round((1/targetFreq)*Fs*2);

        switch roiType
            case 'create_rois'
                [d1,d2,~] = size(T.masks.file{fidx});
                [nrois, tpoints] = size(T.traces.file{fidx});
            case 'pixels'
                [d1,d2,tpoints] = size(T.traces.file{fidx});
        end

        % Get phase and magnitude maps:
        phaseMap = zeros(d1, d2, 1);
        magMap = zeros(d1, d2, 1);
        maxMap = zeros(d1, d2, 1);

        fft_struct = struct();

        check_slice = 1;
        switch roiType
            case 'create_rois'
                for row=1:size(traces,1)
                    fprintf('Processing ROI #: %i\n', row);
                        roi_no = sprintf('roi%i', row);

                        vol_trace = traces(row, :);

                        for slice=slice_idx:slice_idx %ntotal_slices;
                            sliceIdxs = slice:tiff.nFramesPerVolume:tiff.nTotalFrames;
                            vol_offsets = tiff.siSec(sliceIdxs);

                            tmp0 = zeros(1,length(sliceIdxs));
                            if check_slice==1
                                tmp0(:) = squeeze(vol_trace(1:end)); % don't use volume slice indices if just loading in 1 slice
                            else
                                tmp0(:) = squeeze(vol_trace(sliceIdxs));
                            end
                            if cut_end==1
                                tmp0 = tmp0(1:crop);
                            end
                            tmp1 = padarray(tmp0,[0 winsz],tmp0(1),'pre');
                            tmp1 = padarray(tmp1,[0 winsz],tmp1(end),'post');
                            rollingAvg=conv(tmp1,fspecial('average',[1 winsz]),'same');%average
                            rollingAvg=rollingAvg(winsz+1:end-winsz);
                            trace_y = tmp0 - rollingAvg;

                            NFFT = length(trace_y);
                            fft_y = fft(trace_y,NFFT);
                            %F = ((0:1/NFFT:1-1/NFFT)*Fs).';
                            freqs = Fs*(0:(NFFT/2))/NFFT;
                            freq_idx = find(abs((freqs-targetFreq))==min(abs(freqs-targetFreq)));

                            magY = abs(fft_y);
                            %phaseY = unwrap(angle(Y));
                            phaseY = angle(fft_y);
                            %phase_rad = atan2(imag(Y(freq_idx)), real(Y(freq_idx)));
                            %phase_deg = phase_rad / pi * 180 + 90;

                            fft_struct.(roi_no).targetPhase = phaseY(freq_idx); % unwrap(angle(Y(freq_idx)));
                            fft_struct.(roi_no).targetMag = magY(freq_idx);

                            fft_struct.(roi_no).fft_y = fft_y;
                            fft_struct.(roi_no).DC_y = trace_y;
                            fft_struct.(roi_no).raw_y = tmp0;
                            fft_struct.(roi_no).slices = sliceIdxs;
                            fft_struct.(roi_no).freqs = freqs;
                            fft_struct.(roi_no).freq_idx = freq_idx;
                            fft_struct.(roi_no).targetFreq = targetFreq;

                            phaseMap(masks(:,:,row)==1) = phaseY(freq_idx);
                            magMap(masks(:,:,row)==1) = magY(freq_idx);
                            max_idx = find(magY==max(magY));
                            maxMap(masks(:,:,row)==1) = phaseY(max_idx(1));
                        end
                end

            case 'pixels'
                for row=1:d1;
                    fprintf('Processing Row #: %i\n', row);
                    for col=1:d2;
                        roi_no = sprintf('roi_x%i_y%i', row, col);

                        vol_trace = traces(row, col, :);
                        %for slice=slice_idx:slice_idx %ntotal_slices;
                            
                        % 1.  Subtract rolling mean to get rid of slow
                        % drift, etc.
                        % ---------------------------------------------
                        sliceIdxs = sidx:meta.nFramesPerVolume:meta.nTotalFrames;
                        vol_offsets = meta.siSec(sliceIdxs);

                        tmp0 = zeros(1,length(sliceIdxs));
                        if check_slice==1
                            tmp0(:) = squeeze(vol_trace(1:end)); % don't use volume slice indices if just loading in 1 slice
                        else
                            tmp0(:) = squeeze(vol_trace(:,:,sliceIdxs));
                        end
                        if cut_end==1
                            tmp0 = tmp0(1:crop);
                        end
                        tmp1 = padarray(tmp0,[0 winsz],tmp0(1),'pre');
                        tmp1 = padarray(tmp1,[0 winsz],tmp1(end),'post');
                        rollingAvg=conv(tmp1,fspecial('average',[1 winsz]),'same');%average
                        rollingAvg=rollingAvg(winsz+1:end-winsz);
                        trace_y = tmp0 - rollingAvg;

                        % 2.  Do FFT analysis for curr ROI time-series:
                        % ---------------------------------------------
                        NFFT = length(trace_y);
                        fft_y = fft(trace_y,NFFT);
                        freqs = Fs*(0:(NFFT/2))/NFFT;
                        freq_idx = find(abs((freqs-targetFreq))==min(abs(freqs-targetFreq)));

                        magY = abs(fft_y);
                        %phaseY = unwrap(angle(Y));
                        phaseY = angle(fft_y);
                        %phase_rad = atan2(imag(Y(freq_idx)), real(Y(freq_idx)));
                        %phase_deg = phase_rad / pi * 180 + 90;

                        fft_struct.(roi_no).targetPhase = phaseY(freq_idx); % unwrap(angle(Y(freq_idx)));
                        fft_struct.(roi_no).targetMag = magY(freq_idx);

                        fft_struct.(roi_no).fft_y = fft_y;
                        fft_struct.(roi_no).DC_y = trace_y;
                        fft_struct.(roi_no).raw_y = tmp0;
                        fft_struct.(roi_no).slices = sliceIdxs;
                        fft_struct.(roi_no).freqs = freqs;
                        fft_struct.(roi_no).freq_idx = freq_idx;
                        fft_struct.(roi_no).targetFreq = targetFreq;

                        phaseMap(row, col) = phaseY(freq_idx);
                        magMap(row, col) = magY(freq_idx);
                        max_idx = find(magY==max(magY));
                        maxMap(row, col) = phaseY(max_idx(1));
                        % end
                    end

                end
            otherwise
                % do sth else
        end


        % Save analysis struct info:
        % --------------------------
        %traceName_parts = strsplit(traceName, '_');
        % analysis_struct_fn = sprintf('FFT_%s', traceName_parts{2});
        analysis_struct_fn = sprintf('FFT_Slice%02d_File%03d_%s', sidx, fidx, roiType);

        FFT = struct();
        FFT.slice = sidx;
        FFT.file = fidx;
        FFT.sampling_rate = Fs;
        FFT.DC_window = winsz;
        FFT.avgimg = avgY;
        %FFT.fft_struct = fft_struct;

        FFT.phaseMap = phaseMap;
        FFT.magMap = magMap;
        FFT.maxMap = magMap;
        FFT.max_idx = max_idx;
        
        save(fullfile(analysisDir, 'traces', analysis_struct_fn), 'FFT', '-v7.3');
        
        fft_struct_fn = sprintf('ft_Slice%02d_File%03d_%s', sidx, fidx, roiType);
        save(fullfile(analysisDir, 'traces', fft_struct_fn), 'fft_struct', '-v7.3');
        clearvars FFT fft_struct
        
    end
end

%% Save LEGEND if needed:
sim_acquisition = zeros(10,50);
sim_acquisition(:,1) = ones(size(sim_acquisition(:,1)));
legend_im = zeros(10,50,100);
legend_im(:,:,1) = sim_acquisition(:,:,1);
tmpA = sim_acquisition;
for lidx=2:100
    legend_im(:,:,lidx) = circshift(tmpA, 1, 2);
    tmpA = legend_im(:,:,lidx);
end

Fs_lgd = 1;
T_lgd = 1/Fs_lgd;
L_lgd = size(legend_im,3);
t_lgd = (0:L_lgd-1)*T_lgd;
targetFreq_lgd = 1/50;
legend_phase = zeros(size(legend_im,1), size(legend_im,2));
for r_lgd=1:size(legend_im,1)
    for c_lgd=1:size(legend_im,2)
        y_lgd = legend_im(r_lgd,c_lgd,:);
        NFFT_lgd = length(y_lgd);
        legend_ft = fft(y_lgd,NFFT_lgd);
        %freqs = Fs*(0:1/(NFFT/2))/NFFT;
        freqs_lgd = ((0:1/NFFT_lgd:1-1/NFFT_lgd)*Fs_lgd).';
        freq_idx_lgd = find(abs((freqs_lgd-targetFreq_lgd))==min(abs(freqs_lgd-targetFreq_lgd)));
        magY = abs(legend_ft);
        legend_phase(r_lgd,c_lgd) = angle(legend_ft(freq_idx_lgd)); % unwrap(angle(Y(freq_idx)));
    end        
end
% figure()
% imagesc(legend_phase)
% colormap hsv
% caxis([-pi, pi])
% %colorbar()
% axis('off')

legends = struct();
legends.left = legend_phase;
legends.right = fliplr(legend_phase);

% HORIZONTAL:
sim_acquisition = zeros(10,50);
sim_acquisition(1,:) = ones(size(sim_acquisition(1,:)));
legend_im = zeros(10,50,100);
legend_im(:,:,1) = sim_acquisition(:,:,1);
tmpA = sim_acquisition;
for lidx=2:100
    legend_im(:,:,lidx) = circshift(tmpA, 1,1);
    tmpA = legend_im(:,:,lidx);
end

Fs_lgd = 1;
T_lgd = 1/Fs_lgd;
L_lgd = size(legend_im,3);
t_lgd = (0:L_lgd-1)*T_lgd;
targetFreq_lgd = 1/10;
legend_phase = zeros(size(legend_im,1), size(legend_im,2));
for r_lgd=1:size(legend_im,1)
    for c_lgd=1:size(legend_im,2)
        y_lgd = legend_im(r_lgd,c_lgd,:);
        NFFT_lgd = length(y_lgd);
        legend_ft = fft(y_lgd,NFFT_lgd);
        %freqs = Fs*(0:1/(NFFT/2))/NFFT;
        freqs_lgd = ((0:1/NFFT_lgd:1-1/NFFT_lgd)*Fs_lgd).';
        freq_idx_lgd = find(abs((freqs_lgd-targetFreq_lgd))==min(abs(freqs_lgd-targetFreq_lgd)));
        magY = abs(legend_ft);
        legend_phase(r_lgd,c_lgd) = angle(legend_ft(freq_idx_lgd)); % unwrap(angle(Y(freq_idx)));
    end        
end
% figure()
% imagesc(legend_phase)
% colormap hsv
% caxis([-pi, pi])
% %colorbar()
% axis('off')

legends.top = legend_phase;
legends.bottom = flipud(legend_phase);
legend_struct = 'retinotopy_legends';

%FFT.legends = legends;
save(fullfile(analysisDir, legend_struct), 'legends', '-v7.3');

%end
%end

%% Plot phase and mag maps:

% TODO:  fix this, make ROI-selector also give back average image used to
% select ROIs...

curr_tiff = sprintf('%s_Slice%02d_Channel%02d_File%03d.tif', acquisitionName, sidx, 1, 1);
Y = tiffRead(fullfile(tiff_info.tiff_path, curr_tiff));
avgY = mean(Y, 3);
maxY = max(Y(:));
minY = min(Y(:));
img_scaled = (avgY-min(avgY(:)))*(maxY-minY)/(max(avgY(:))-min(avgY(:))) + minY;

%

smooth_spatial = 1;
ksize = 8;

if smooth_spatial==1
    for frame=1:size(Y,3);
        curr_frame = Y(:,:,frame);
        padY = padarray(curr_frame, [ksize, ksize], 'replicate');
        convY = conv2(padY, fspecial('average',[ksize ksize]), 'same');
        Y(:,:,frame) = convY(ksize+1:end-ksize, ksize+1:end-ksize);
    end
end
                        
figure();
imagesc(mean(Y,3));
colormap(gray)


%%  LOAD previously generated analysis structs/info:

% Get meta data
metaStructs = dir(fullfile(analysisDir, '*meta_*'));
metaStructs = {metaStructs(:).name}';
tiff_info = load(fullfile(analysisDir, metaStructs{1}));

% Load FFT analysis structs if needed:
roiType = 'pixels';
fft_structs = dir(fullfile(analysisDir, sprintf('*FFT_*%s*', roiType)));
fft_structs = {fft_structs(:).name}';

curr_slice = 12;
curr_fft_struct = sprintf('FFT_Slice%02d_nFiles%i_%s.mat', curr_slice, length(metaStructs), roiType);
fft = load(fullfile(analysisDir, curr_fft_struct));

%%

% conds = {'left', 'right', 'top', 'bottom'};
% cond_idx = 1;

curr_cond_name = meta.mwRunName;

fig = figure();
%A = repmat(x_scaled, [1, 1, 3]);
ax1 = subplot(2,2,1);
imagesc(avgY);
axis('off')
hb = colorbar('location','eastoutside');
colormap(ax1, gray)

ax4 = subplot(2,2,4);
threshold = .3 %0.1; %8000; %10000; %8000; %(k=3); %20000;
thresholdMap = phaseMap;
thresholdMap(magMap<(max(magMap(:))*threshold)) = NaN;

fov = repmat(mat2gray(avgY), [1, 1, 3]);
B = thresholdMap; %phaseMap
imagesc(fov);
slice_no = strcat('slice', num2str(sidx));
title(sprintf('avg - %s', slice_no))
hold on;
Bimg = imagesc2(B);
title('phase')
colormap(ax4, hsv)
caxis([-pi, pi])

ax3 = subplot(2,2,3);
imagesc(ratioMap)
axis('off')
colormap(ax3, hot)
hb = colorbar('location','eastoutside');
title('magnitude')

ax2 = subplot(2,2,2);
imagesc(legends.(curr_cond_name))
axis('off')
caxis([-pi, pi])
colormap(ax2, hsv)


%%
tic();
scalevec = [2 1 1];
tmp_sourceDir = '/nas/volume1/2photon/RESDATA/20161221_JR030W/retinotopy037Hz/raw/';
tmp_tiff_dir = 'raw';
resize_dir = fullfile(tmp_sourceDir, strcat(tmp_tiff_dir, '_scaled'));
if ~exist(resize_dir, 'dir')
    mkdir(resize_dir)
end
%tmpTiffs = dir(fullfile(tmp_sourceDir, tmp_tiff_dir, '*.tif'));
%tmpTiffs = {tmpTiffs(:).name}';
tmpTiffs = {'fov1_bar037Hz_run4_00003.tif'};

for tmp_idx=1:length(tmpTiffs)
    %tmp_tiff = sprintf('%s_Slice%02d_Channel01_File003.tif', acquisitionName, tmp_idx);
    tmp_tiff = tmpTiffs{tmp_idx};
    tmp_tiff_path = fullfile(tmp_sourceDir, tmp_tiff_dir, tmp_tiff);
    %imData=bigread2_scale(tmp_tiff_path,1,[],scalevec);
    imData=bigread2(tmp_tiff_path,1);
    
    resize_dir = fullfile(tmp_sourceDir, strcat(tmp_tiff_dir, '_scaled'));
    tiffWrite(imData, tmp_tiff, resize_dir);
end
fprintf('Time elapsed: ');
toc();
