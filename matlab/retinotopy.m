% RETINOTOPY.

% -------------------------------------------------------------------------
% Acquisition Information:
% -------------------------------------------------------------------------
% Get info for a given acquisition for each slice from specified analysis.
% This gives FFT analysis script access to all neeed vars stored from
% create_acquisition_structs.m pipeline.

acquisition_info;

% -------------------------------------------------------------------------
% FFT analysis:
% -------------------------------------------------------------------------
% For each analysed slice, do FFT analysis on each file (i.e., run, or
% condition rep).
% For a given set of traces (on a given run) extracted from a slice, use 
% corresponding metaInfo for maps.

for sidx = 1:length(slices_to_use)
    currSlice = slices_to_use(sidx);
    
    M = load(maskPaths{sidx});
    masks = M.masks;
    clear M;
        
    T = load(fullfile(tracesDir, tracePaths{sidx}));
    
    for fidx=1:ntiffs
        
        meta = load(metaPaths{fidx});
        
        traces = T.traces.file{fidx};
        avgY = T.avg_image.file{fidx};
        

        target_freq = meta.target_freq;
        ncycles = meta.ncycles;
        ntotal_slices = meta.nframes_per_volume;
        
        cut_end=1;
        crop = meta.n_true_frames; %round((1/target_freq)*ncycles*Fs);
        
        switch roiType
            case 'create_rois'
                [d1,d2] = size(avgY);
                [nrois, tpoints] = size(T.traces.file{fidx});
            case 'pixels'
                %[d1,d2,tpoints] = size(T.traces.file{fidx});
                [d1, d2] = size(avgY);
                tpoints = size(T.traces.file{fidx},3);
        end
        
        % Get phase and magnitude maps:
        phaseMap = zeros(d1, d2, 1);
        magMap = zeros(d1, d2, 1);
        ratioMap = zeros(d1, d2, 1);
        phaseMaxMag = zeros(d1, d2, 1);

        fft_struct = struct();
        for roi=1:size(traces,1)
            
            if mod(roi,10)==0
                fprintf('Processing roi #%i...\n', roi)
            end
            
            slice_indices = currSlice:meta.nframes_per_volume:meta.ntotal_frames;
            currTrace = traces(roi, :);
            
            % Subtract rolling mean to get rid of drift:
            % -------------------------------------------------------------
%             if check_slice
%                 tmp0(:) = squeeze(currTrace(1:end));
%             end

            Fs = meta.si_volume_rate;
            winsz = round((1/target_freq)*Fs*2);
           
            if cut_end==1
                tmp0 = currTrace(1:crop);
            else
                tmp0 = currTrace;
            end
            tmp1 = padarray(tmp0,[0 winsz],tmp0(1),'pre');
            tmp1 = padarray(tmp1,[0 winsz],tmp1(end),'post');
            rollingAvg=conv(tmp1,fspecial('average',[1 winsz]),'same');%average
            rollingAvg=rollingAvg(winsz+1:end-winsz);
            trace_y = tmp0 - rollingAvg;
            
            % Do FFT:
            % -------------------------------------------------------------
            N = length(trace_y);
            dt = 1/Fs;
            t = dt*(0:N-1)';
            dF = Fs/N;
            freqs = dF*(0:N/2-1)';
            
            fft_y = fft(trace_y)/N;
            fft_y = fft_y(1:N/2);
            fft_y(2:end) = 2*fft_y(2:end);
            %freqs = Fs*(0:(NFFT/2))/NFFT;
            freq_idx = find(abs((freqs-target_freq))==min(abs(freqs-target_freq)));
            %fprintf('Target frequency %02.2f found at idx %i.\n', target_freq, freq_idx);
            
            magY = abs(fft_y);
            ratioY = magY(freq_idx) / (sum(magY) - magY(freq_idx));
            %phaseY = unwrap(angle(Y));
            phaseY = angle(fft_y);
            %phase_rad = atan2(imag(Y(freq_idx)), real(Y(freq_idx)));
            %phase_deg = phase_rad / pi * 180 + 90;
            
            % Store FFT analysis resuts to struct:
            % -------------------------------------------------------------
            fft_struct.roi(roi).targetPhase = phaseY(freq_idx); % unwrap(angle(Y(freq_idx)));
            fft_struct.roi(roi).targetMag = magY(freq_idx);
            fft_struct.roi(roi).maxFreq = freqs(magY==max(magY(:)));
            fft_struct.roi(roi).fft = fft_y;
            fft_struct.roi(roi).trace = trace_y;
            fft_struct.roi(roi).raw = tmp0;
            fft_struct.roi(roi).slices = slice_indices;
            fft_struct.roi(roi).freqs = freqs;
            fft_struct.roi(roi).freq_idx = freq_idx;
            fft_struct.roi(roi).target_freq = target_freq;

            phaseMap(masks(:,:,roi)==1) = phaseY(freq_idx);
            magMap(masks(:,:,roi)==1) = magY(freq_idx);
            ratioMap(masks(:,:,roi)==1) = ratioY;
            max_idx = find(magY==max(magY));
            phaseMaxMag(masks(:,:,roi)==1) = phaseY(max_idx(1));
            
            maps.magnitude = magMap;
            maps.phase = phaseMap;
            maps.phasemax = phaseMaxMag;
            maps.ratio = ratioMap;
                            
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
        
        % Save file info for current slice and file:
%         map_fn = sprintf('maps_Slice%02d_File%03d', currSlice, fidx);
%         save_struct(figDir, map_fn, maps);
%         
%         fft_fn = sprintf('fft_Slice%02d_File%03d', currSlice, fidx);
%         save_struct(outputDir, fft_fn, fft_struct);
%         
%         %M.file(fidx) = maps;
%         clear fft_struct maps
    end
    
    % Save maps for current slice:
    map_fn = sprintf('maps_Slice%02d', currSlice);
    save_struct(figDir, map_fn, maps);

    fft_fn = sprintf('fft_Slice%02d', currSlice);
    save_struct(outputDir, fft_fn, fft_struct);

    %M.file(fidx) = maps;
    clear fft_struct maps
    
    fprintf('Finished FFT analysis for Slice %02d.\n', currSlice);
    
end