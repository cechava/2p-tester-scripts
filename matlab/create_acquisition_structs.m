clear all;
clc;

%% DEFINE SOURCE DIRECTORY:

% Define source dir for current acquisition/experiment:
source_dir = '/nas/volume1/2photon/RESDATA/20161221_JR030W/retinotopy037Hz/';
% source_dir = '/nas/volume1/2photon/RESDATA/20161222_JR030W/retinotopy1/';
% source_dir = '/nas/volume1/2photon/RESDATA/TEFO/20161218_CE024/raw/bar5';
analysis_dir = fullfile(source_dir, 'analysis');
if ~exist(analysis_dir, 'dir')
    mkdir(analysis_dir);
end

% Define TIFF dir if is sub-dir within the source-dir:
channel_idx = 1;
nchannels = 1;
%tiff_dir = sprintf('Corrected_Channel%02d', channel_idx);
%tiff_dir = sprintf('Corrected');
acquisition_name = 'fov1_bar037Hz_run4';

%% Get SI volume info:

metaInfo = 'SI';

corrected = true;
if corrected
    tiff_source = 'Corrected';
else
    tiff_source = 'Parsed';
end

switch metaInfo
    case 'SI'
       
        metastruct_fn = sprintf('%s.mat', acquisition_name);
        
        if ~exist(fullfile(source_dir, metastruct_fn))
            
            % Load and parse raw TIFFs and create meta file:
            movies = dir(fullfile(source_dir,'*.tif'));
            movies = {movies(:).name};
            writeDir = fullfile(source_dir, tiff_source);
            if ~exist(writeDir, 'dir')
                mkdir(writeDir)
            end
            parseSIdata(acquisition_name, movies, source_dir, writeDir)
            
            
            % Load meta struct:
            load(fullfile(source_dir, metastruct_fn));
            meta = struct();
            meta.(acquisition_name) = metaDataSI{1}; % Have info for each file, but this was not corrected in previosuly run MCs...
        else
            meta = load(fullfile(source_dir, metastruct_fn));
        end

        % Sort Parsed files into separate directories:
        numchannels = 2;
        sort_parsed_tiffs(source_dir, tiff_source, numchannels);
            
        nvolumes = meta.(acquisition_name).metaDataSI.SI.hFastZ.numVolumes;
        nslices = meta.(acquisition_name).metaDataSI.SI.hFastZ.numFramesPerVolume;
        ndiscard = meta.(acquisition_name).metaDataSI.SI.hFastZ.numDiscardFlybackFrames;
        nframes_per_volume = nslices + ndiscard;
        ntotal_frames = nframes_per_volume * nvolumes;
        
        si_frame_times = meta.(acquisition_name).metaDataSI.frameTimestamps_sec(1:2:end);
        si_frame_rate = meta.(acquisition_name).metaDataSI.SI.hRoiManager.scanFrameRate;
        si_volume_rate = meta.(acquisition_name).metaDataSI.SI.hRoiManager.scanVolumeRate;
        
        frame_width = meta.(acquisition_name).metaDataSI.SI.hRoiManager.pixelsPerLine;
        slow_multiplier = meta.(acquisition_name).metaDataSI.SI.hRoiManager.scanAngleMultiplierSlow;
        lines_per_frame = meta.(acquisition_name).metaDataSI.SI.hRoiManager.linesPerFrame;
        frame_height = lines_per_frame/slow_multiplier;
        
      
    case 'manual' % No motion-correction/processing, just using raw TIFFs.
        nvolumes = 350;
        nslices = 20;
        ndiscard = 0;
        
        nframes_per_volume = nslices + ndiscard;
        ntotal_frames = nframes_per_volume * nvolumes;
end

% Get paths to each FILE directory (into which TIFFs have been parsed):

channel_dir = sprintf('Channel%02d', channel_idx);
tmp_tiffs = dir(fullfile(source_dir, tiff_source, channel_dir));
tmp_tiffs = tmp_tiffs(arrayfun(@(x) ~strcmp(x.name(1),'.'),tmp_tiffs));
tiff_dirs = {tmp_tiffs(:).name}';
ntiffs = length(tiff_dirs);
fprintf('Found %i TIFF stacks for current acquisition analysis.\n', ntiffs);

%% Specify experiment parameters:

mw_path = fullfile(source_dir, 'mw_data');
mw = get_mw_info(mw_path, ntiffs);
pymat = mw.pymat;

% Create arbitrary stimtype codes:
stim_types = cell(1,length(mw.cond_types));
for sidx=1:length(mw.cond_types)
    sname = sprintf('code%i', sidx);
    stim_types{sidx} = sname;
end

% Get indices of each run to preserve order when indexing into MW
% file-structs:
for run_idx=1:length(mw.run_names)
    run_order.(mw.run_names{run_idx}) = pymat.(mw.run_names{run_idx}).ordernum + 1;
end

%% Grab experiment info for each slice and save a .mat for each run.
%  Stores MW / ARD stimulus info & metadata from SI.

for fidx=1:ntiffs
    
    curr_mw_fidx = mw.mw_fidx + fidx - 1;
    
    % Make sure to grab the correct run based on TIFF order number:
    for order_no=1:length(fieldnames(run_order))
        if run_order.(mw.run_names{order_no}) == curr_mw_fidx
            curr_run_name = mw.run_names{order_no};
        end
    end
    
    mw_sec = (double(pymat.(curr_run_name).time) - double(pymat.(curr_run_name).time(1))) / 1E6;
    cycle_starts = pymat.(curr_run_name).idxs + 1; % Get indices of cycle starts
    mw_dur = (double(pymat.triggers(curr_mw_fidx,2)) - double(pymat.triggers(curr_mw_fidx,1))) / 1E6;
    
    if exist('si_frame_times')
        si_sec_vols = si_frame_times;
    else
        if isfield(pymat, 'ard_file_durs')
            ard_dur = double(pymat.ard_file_durs(curr_mw_fidx));
            %if sample_us==1 % Each frame has a t-stamped frame-onset (only true if ARD sampling every 200us, isntead of standard 1ms)
            si_sec_vols = (double(pymat.frame_onset_times{curr_mw_fidx}) - double(pymat.frame_onset_times{curr_mw_fidx}(1))) / 1E6; 
            if length(si_sec) < ntotal_frames % there are missed frame triggers
                si_sec_vols = linspace(0, ard_dur, ntotal_frames);
                % This is pretty accurate.. only off by ~ 3ms compared to SI's
                % trigger times.
            end
        else
            si_sec_vols = linspace(0, mw_dur, ntotal_frames);
        end
    end
    
    
    if pymat.stimtype=='bar'
        trim_long = 1;
        ncycles = pymat.info.ncycles;
        target_freq = pymat.info.target_freq;
        %si_frame_rate = 1/median(diff(si_sec_vols));
        %si_volume_rate = round(si_frame_rate/nframes_per_volume, 2); % 5.58%4.11 %4.26 %5.58
        n_true_frames = ceil((1/target_freq)*ncycles*si_volume_rate);
        
    end
    
    tiff.acquisition_name = acquisition_name;
    tiff.mw_run_name = curr_run_name;
    tiff.mw_fidx = curr_mw_fidx;
    tiff.mw_path = mw.mw_path;
    %tiff.run_fn = M.run_fns;
    tiff.mw_sec = mw_sec;
    tiff.stim_starts = cycle_starts;
    tiff.mw_dur = mw_dur;
    tiff.si_sec_vols = si_sec_vols;
    tiff.ncycles = ncycles;
    tiff.target_freq = target_freq;
    tiff.si_frame_rate = si_frame_rate;
    tiff.si_volume_rate = si_volume_rate;
    tiff.n_true_frames = n_true_frames;
    
    tiff.nvolumes = nvolumes;
    tiff.nslices = nslices;
    tiff.ntotal_slices = nslices + ndiscard;
    tiff.ntotal_frames = ntotal_frames;
    tiff.nframes_per_volume = nframes_per_volume;
    tiff.tiff_path = fullfile(source_dir, tiff_source, channel_dir, tiff_dirs{fidx});
    tiff.imgX = frame_width;
    tiff.imgY = frame_height;
    
    tiff.tiff_fidx = fidx;
   
    curr_struct_name = char(sprintf('meta_File%03d.mat', fidx));
    meta_path = fullfile(analysis_dir, 'meta');
    if ~exist(meta_path)
        mkdir(meta_path)
    end
    
    save(fullfile(meta_path, curr_struct_name), '-struct', 'tiff');
    
end
    
%% Set up experiment analysis parameters:

% =========================================================================
% Parameters:
% =========================================================================

% -------------------------
preprocessing = 'Acquisition2P';
%preprocessing = 'raw';

% --------------------------
roi_type = 'create_rois';

% roi_type: 
%   'create_rois' : create new ROIs using circle-GUI
%   'smoothed_pixels' : use all pixels, but smooth with kernel size,
%   ksize=2 (default)
%   'prev_rois' : use previosuly-created ROIs 
% --
% TO DO:  1. option to specify kernel size
%         2.  let user select which ROI set to use in a non-stupid way...

% -------------------------
channel_idx = 1;

% -------------------------
meta_structs = dir(fullfile(meta_path, '*meta_*'));
meta_structs = {meta_structs(:).name}';
meta_paths = cell(1, length(meta_structs));
for m=1:length(meta_structs)
    meta_paths{m} = fullfile(meta_path, meta_structs{m});
end
ntiffs = length(meta_paths);



% =========================================================================
% Save analysis info:
% =========================================================================

didx = 1;

datastruct = sprintf('datastruct_%03d', didx);
datastruct_path = fullfile(analysis_dir, datastruct);
if ~exist(datastruct_path)
    mkdir(datastruct_path)
    D = struct();
end

D.name = datastruct;
D.path = datastruct_path;
D.acquisition_name = acquisition_name;
D.preprocessing = preprocessing;
D.roi_type = roi_type;
D.metaPaths = meta_paths;
D.ntiffs = ntiffs;
D.channels = nchannels;

save(fullfile(datastruct_path, datastruct), '-append', '-struct', 'D');


%% Create masks and get traces:

% =========================================================================
% Create masks, and save them:
% =========================================================================

refRun = 1;                                                 % Use ref movie from motion-correction if applicable (obj.refMovNum from Acquisition2P class).
slices_to_use = [5, 10, 15, 20];                            % Specify which slices to use (if empty, will grab traces for all slices)

refMeta = load(meta_paths{refRun});
slice_fns = dir(fullfile(refMeta.tiff_path, '*.tif'));
slice_fns = {slice_fns(:).name}';                           % Get all TIFFs (slices) associated with file and volume of refRun movie.

switch roi_type
    case 'create_rois'
        
        % Create ROIs: ----------------------------------------------------
        create_rois(datastruct_path, acquisition_name, refMeta, slice_fns);
                
        
        % Set up mask info struct to reuse masks across files:
        % -----------------------------------------------------------------
        mask_type = 'circles';
        maskInfo = struct();
        maskInfo.refNum = refRun;
        maskInfo.refMeta = refMeta;
        maskInfo.mask_type = mask_type;

        mask_dir = fullfile(datastruct_path, 'masks');
        mask_structs = dir(fullfile(mask_dir, '*.mat'));
        mask_structs = {mask_structs(:).name}';
        slices_to_use = zeros(1,length(mask_structs));
        for m=1:length(mask_structs)
            m_parts = strsplit(mask_structs{m}, 'Slice');
            m_parts = strsplit(m_parts{2}, '_');
            slices_to_use(m) = str2num(m_parts{1});
        end
        mask_paths = cell(1,length(mask_structs));
        for m=1:length(mask_structs)
            mask_paths{m} = fullfile(mask_dir, mask_structs{m});
        end
        maskInfo.maskPaths = mask_paths;
        maskInfo.slices_to_use = slices_to_use;
        
        
        % =================================================================
        % Get traces with masks:
        % =================================================================
        get_traces(datastruct_path, mask_type, acquisition_name, ntiffs,...
                    nchannels, meta_paths, maskInfo);
        
        
    case 'pixels'
        
        mask_type = 'pixels';
        
        % Set smoothing/filtering params:
        % -----------------------------------------------------------------
        params = struct();
        params.smooth_xy = true;
        params.kernel_xy = 5;
        
        slices_to_use = [5, 10, 15, 20]; % TMP 
        params.slices_to_use = slices_to_use;
        

        
        % =================================================================
        % Get traces:
        % =================================================================
        get_traces(datastruct_path, mask_type, acquisition_name, ntiffs,...
                    nchannels, meta_paths, [], params);

    case 'nmf'
        
        mask_type = 'nmf';
        
        % Get NMF params:
        % -----------------------------------------------------------------
        params = struct();
        
        
        
        
        % =================================================================
        % Get traces:
        % =================================================================
        get_traces(datastruct_path, mask_type, acquisition_name, ntiffs,...
                    nchannels, meta_paths, [], params); 
                    
end


% Update analysis info struct:
% -------------------------------------------------------------------------

D.refRun = refRun;
D.refPath = refMeta.tiff_path;
D.slices = slices_to_use;

D.maskType = mask_type;
if strcmp(D.maskType, 'circles')
    D.maskInfo = maskInfo;
    D.maskType = mask_type;
else
    D.params = params;
end
save(fullfile(datastruct_path, datastruct), '-append', '-struct', 'D');

        
%%  Align stimulus events to traces:

% Load metadata if needed:
meta_structs = dir(meta_path);
meta_structs = {meta_structs(:).name}';

% Load traces if needed:
traces_path = fullfile(datastruct_path, 'traces');
traces_structs = dir(traces_path);
traces_structs = {traces_structs(:).name}';


% % Load FFT analysis structs if needed:
% roi_type = 'pixels';
% fft_structs = dir(fullfile(struct_dir, sprintf('*FFT_*%s*', roi_type)));
% fft_structs = {fft_structs(:).name}';

%%

% Retinotopy:

% slices = [12, 14, 16];
tmp_slice_fns = dir(fullfile(analysis_dir, 'traces', '*traces_*_pixels*'));
slice_fns = {tmp_slice_fns(:).name};

for sidx = 10:length(slice_fns)
    slice_fn = slice_fns{sidx};
    load(fullfile(analysis_dir, 'traces', slice_fn))

    nfiles = length(T.traces.file);
    for fidx = 1:nfiles
        traces = T.traces.file{fidx};
        masks = T.masks.file{fidx};
        avgY = T.avg_image.file{fidx};

        Fs = meta.si_volume_rate;
        target_freq = meta.target_freq;
        ncycles = meta.ncycles;
        ntotal_slices = meta.nframes_per_volume;

        cut_end=1;
        crop = meta.n_true_frames; %round((1/target_freq)*ncycles*Fs);

        winsz = round((1/target_freq)*Fs*2);

        switch roi_type
            case 'create_rois'
                [d1,d2,~] = size(T.masks.file{fidx});
                [nrois, tpoints] = size(T.traces.file{fidx});
            case 'pixels'
                [d1,d2,tpoints] = size(T.traces.file{fidx});
        end

        % Get phase and magnitude maps:
        phase_map = zeros(d1, d2, 1);
        mag_map = zeros(d1, d2, 1);
        max_map = zeros(d1, d2, 1);

        fft_struct = struct();

        check_slice = 1;
        switch roi_type
            case 'create_rois'
                for row=1:size(traces,1)
                    fprintf('Processing ROI #: %i\n', row);
                        roi_no = sprintf('roi%i', row);

                        vol_trace = traces(row, :);

                        for slice=slice_idx:slice_idx %ntotal_slices;
                            slice_indices = slice:tiff.nframes_per_volume:tiff.ntotal_frames;
                            vol_offsets = tiff.si_sec_vols(slice_indices);

                            tmp0 = zeros(1,length(slice_indices));
                            if check_slice==1
                                tmp0(:) = squeeze(vol_trace(1:end)); % don't use volume slice indices if just loading in 1 slice
                            else
                                tmp0(:) = squeeze(vol_trace(slice_indices));
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
                            freq_idx = find(abs((freqs-target_freq))==min(abs(freqs-target_freq)));

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
                            fft_struct.(roi_no).slices = slice_indices;
                            fft_struct.(roi_no).freqs = freqs;
                            fft_struct.(roi_no).freq_idx = freq_idx;
                            fft_struct.(roi_no).target_freq = target_freq;

                            phase_map(masks(:,:,row)==1) = phaseY(freq_idx);
                            mag_map(masks(:,:,row)==1) = magY(freq_idx);
                            max_idx = find(magY==max(magY));
                            max_map(masks(:,:,row)==1) = phaseY(max_idx(1));
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
                        slice_indices = sidx:meta.nframes_per_volume:meta.ntotal_frames;
                        vol_offsets = meta.si_sec_vols(slice_indices);

                        tmp0 = zeros(1,length(slice_indices));
                        if check_slice==1
                            tmp0(:) = squeeze(vol_trace(1:end)); % don't use volume slice indices if just loading in 1 slice
                        else
                            tmp0(:) = squeeze(vol_trace(:,:,slice_indices));
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
                        freq_idx = find(abs((freqs-target_freq))==min(abs(freqs-target_freq)));

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
                        fft_struct.(roi_no).slices = slice_indices;
                        fft_struct.(roi_no).freqs = freqs;
                        fft_struct.(roi_no).freq_idx = freq_idx;
                        fft_struct.(roi_no).target_freq = target_freq;

                        phase_map(row, col) = phaseY(freq_idx);
                        mag_map(row, col) = magY(freq_idx);
                        max_idx = find(magY==max(magY));
                        max_map(row, col) = phaseY(max_idx(1));
                        % end
                    end

                end
            otherwise
                % do sth else
        end


        % Save analysis struct info:
        % --------------------------
        %slice_fn_parts = strsplit(slice_fn, '_');
        % analysis_struct_fn = sprintf('FFT_%s', slice_fn_parts{2});
        analysis_struct_fn = sprintf('FFT_Slice%02d_File%03d_%s', sidx, fidx, roi_type);

        FFT = struct();
        FFT.slice = sidx;
        FFT.file = fidx;
        FFT.sampling_rate = Fs;
        FFT.DC_window = winsz;
        FFT.avgimg = avgY;
        %FFT.fft_struct = fft_struct;

        FFT.phase_map = phase_map;
        FFT.mag_map = mag_map;
        FFT.max_map = mag_map;
        FFT.max_idx = max_idx;
        
        save(fullfile(analysis_dir, 'traces', analysis_struct_fn), 'FFT', '-v7.3');
        
        fft_struct_fn = sprintf('ft_Slice%02d_File%03d_%s', sidx, fidx, roi_type);
        save(fullfile(analysis_dir, 'traces', fft_struct_fn), 'fft_struct', '-v7.3');
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
target_freq_lgd = 1/50;
legend_phase = zeros(size(legend_im,1), size(legend_im,2));
for r_lgd=1:size(legend_im,1)
    for c_lgd=1:size(legend_im,2)
        y_lgd = legend_im(r_lgd,c_lgd,:);
        NFFT_lgd = length(y_lgd);
        legend_ft = fft(y_lgd,NFFT_lgd);
        %freqs = Fs*(0:1/(NFFT/2))/NFFT;
        freqs_lgd = ((0:1/NFFT_lgd:1-1/NFFT_lgd)*Fs_lgd).';
        freq_idx_lgd = find(abs((freqs_lgd-target_freq_lgd))==min(abs(freqs_lgd-target_freq_lgd)));
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
target_freq_lgd = 1/10;
legend_phase = zeros(size(legend_im,1), size(legend_im,2));
for r_lgd=1:size(legend_im,1)
    for c_lgd=1:size(legend_im,2)
        y_lgd = legend_im(r_lgd,c_lgd,:);
        NFFT_lgd = length(y_lgd);
        legend_ft = fft(y_lgd,NFFT_lgd);
        %freqs = Fs*(0:1/(NFFT/2))/NFFT;
        freqs_lgd = ((0:1/NFFT_lgd:1-1/NFFT_lgd)*Fs_lgd).';
        freq_idx_lgd = find(abs((freqs_lgd-target_freq_lgd))==min(abs(freqs_lgd-target_freq_lgd)));
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
save(fullfile(analysis_dir, legend_struct), 'legends', '-v7.3');

%end
%end

%% Plot phase and mag maps:

% TODO:  fix this, make ROI-selector also give back average image used to
% select ROIs...

curr_tiff = sprintf('%s_Slice%02d_Channel%02d_File%03d.tif', acquisition_name, sidx, 1, 1);
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
meta_structs = dir(fullfile(analysis_dir, '*meta_*'));
meta_structs = {meta_structs(:).name}';
tiff_info = load(fullfile(analysis_dir, meta_structs{1}));

% Load FFT analysis structs if needed:
roi_type = 'pixels';
fft_structs = dir(fullfile(analysis_dir, sprintf('*FFT_*%s*', roi_type)));
fft_structs = {fft_structs(:).name}';

curr_slice = 12;
curr_fft_struct = sprintf('FFT_Slice%02d_nFiles%i_%s.mat', curr_slice, length(meta_structs), roi_type);
fft = load(fullfile(analysis_dir, curr_fft_struct));

%%

% conds = {'left', 'right', 'top', 'bottom'};
% cond_idx = 1;

curr_cond_name = meta.mw_run_name;

fig = figure();
%A = repmat(x_scaled, [1, 1, 3]);
ax1 = subplot(2,2,1);
imagesc(avgY);
axis('off')
hb = colorbar('location','eastoutside');
colormap(ax1, gray)

ax4 = subplot(2,2,4);
threshold = .3 %0.1; %8000; %10000; %8000; %(k=3); %20000;
threshold_map = phase_map;
threshold_map(mag_map<(max(mag_map(:))*threshold)) = NaN;

fov = repmat(mat2gray(avgY), [1, 1, 3]);
B = threshold_map; %phase_map
imagesc(fov);
slice_no = strcat('slice', num2str(sidx));
title(sprintf('avg - %s', slice_no))
hold on;
Bimg = imagesc2(B);
title('phase')
colormap(ax4, hsv)
caxis([-pi, pi])

ax3 = subplot(2,2,3);
imagesc(mag_map)
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
tmp_source_dir = '/nas/volume1/2photon/RESDATA/20161221_JR030W/retinotopy037Hz/raw/';
tmp_tiff_dir = 'raw';
resize_dir = fullfile(tmp_source_dir, strcat(tmp_tiff_dir, '_scaled'));
if ~exist(resize_dir, 'dir')
    mkdir(resize_dir)
end
%tmp_tiffs = dir(fullfile(tmp_source_dir, tmp_tiff_dir, '*.tif'));
%tmp_tiffs = {tmp_tiffs(:).name}';
tmp_tiffs = {'fov1_bar037Hz_run4_00003.tif'};

for tmp_idx=1:length(tmp_tiffs)
    %tmp_tiff = sprintf('%s_Slice%02d_Channel01_File003.tif', acquisition_name, tmp_idx);
    tmp_tiff = tmp_tiffs{tmp_idx};
    tmp_tiff_path = fullfile(tmp_source_dir, tmp_tiff_dir, tmp_tiff);
    %imData=bigread2_scale(tmp_tiff_path,1,[],scalevec);
    imData=bigread2(tmp_tiff_path,1);
    
    resize_dir = fullfile(tmp_source_dir, strcat(tmp_tiff_dir, '_scaled'));
    tiffWrite(imData, tmp_tiff, resize_dir);
end
fprintf('Time elapsed: ');
toc();
