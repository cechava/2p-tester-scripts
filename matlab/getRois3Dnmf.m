function [options, nmf_outpaths] = getRois3Dnmf(D, meta, show_plots)
% clear all;
% clc;
% 
% addpath(genpath('~/Repositories/ca_source_extraction'));
% addpath(genpath('~/Repositories/NoRMCorre'));

%% Specify tiff sources and covnert to matfile objs:

% source = '/nas/volume1/2photon/RESDATA/20161221_JR030W';
% experiment = 'test_crossref';
% tiffroot = fullfile(source, experiment);
% savedir = 'nmf';
% outpath = fullfile(tiffroot, savedir);
% 
% mempath = fullfile(D.nmfPath, 'memfiles');
% if ~exist(mempath, 'dir')
%     mkdir(mempath)
% end
% 
% nmf_outpaths = {};
% 
% tiffs = dir(fullfile(D.sourceDir, '*.tif'));
% tiffs = {tiffs(:).name}'
% 
% files = dir(fullfile(mempath, '*.mat'));
% files = {files(:).name}';
% for fn=1:length(files)
%     if strfind(files{fn}, '_substack')
%         files{fn} = [];
%     end
% end
% 
% 
% 
% if length(tiffs)>length(files)
% 
% 
% tic()
% for tiffidx = 1:length(tiffs)
% %tpath = '/nas/volume1/2photon/RESDATA/20161222_JR030W/gratings1/fov1_gratings_10reps_run1_00007.tif';
% tpath = fullfile(D.sourceDir, tiffs{tiffidx});
% [source, filename, ext] = fileparts(tpath);
% 
% matpath = fullfile(mempath, sprintf('%s.mat', filename));
% data = matfile(matpath,'Writable',true);
% 
% %info = imfinfo(tpath);
% 
% %nSlices = 20; nVolumes = 350;
% %tic; Yt = loadtiff(tpath, 1, nSlices*2); toc;
% %Yt = Yt(:,:,1:2:end);
% 
% %nSlices = meta.file(tiffidx).si.nSlices;
% nSlices = meta.file(tiffidx).si.nFramesPerVolume;
% nRealFrames = meta.file(tiffidx).si.nSlices;
% nVolumes = meta.file(tiffidx).si.nVolumes;
% if D.tefo
%     nChannels=2;
% else
%     nChannels=1;
% end
% 
% tic; Yt = loadtiff(tpath, 1, nSlices*nVolumes*nChannels); toc;
% 
% % Only grab green channel:
% if strcmp(D.preprocessing, 'raw')
%     Yt = Yt(:,:,1:2:end);
% end
% 
% Y = cell(1, nVolumes);
% firstslice = 1;
% for vol=1:nVolumes
%     Y{vol} = Yt(:,:,firstslice:(firstslice+nRealFrames-1));
%     firstslice = firstslice+nSlices;
% end
% Y = cat(4, Y{1:end});
% if ~isa(Y, 'double'); Y = double(Y); end    % convert to double
% Y = Y -  min(Y(:));                         % make data non-negative
% 
% data.Y = Y;
% data.sizY = size(data.Y);
% data.Yr(1:prod(data.sizY(:,1:end-1)), 1:nVolumes) = reshape(data.Y,prod(data.sizY(:,1:end-1)),[]);
% data.nY = min(data.Yr(:,:));
% 
% fprintf('Memmapping finished for %i of %i files.\n', tiffidx, length(tiffs));
% fprintf('Size of memmaped movie is: %s\n', mat2str(data.sizY));
% 
% 
% end
% 
% % 
% fprintf('Done!');
% toc()
% 
% 
% end
% 
% 
% %% Turn volumemat into data memmap object:
% 
% % 
% % tpath = '/nas/volume1/2photon/RESDATA/20161222_JR030W/gratings1/fov1_gratings_10reps_run1_00007.tif';
% % [sourcepath, filename, ext] = fileparts(tpath);
% % savedir = 'nmf';
% % tiffmat = sprintf('%s.mat', filename);
% % 
% % fullfilepath = fullfile(sourcepath, savedir, tiffmat);
% % tmpdata = matfile(fullfilepath);
% % if ~isprop(tmpdata, 'Y')
% %     load(fullfilepath)
% %     Y = volumemat;
% %     clear volumemat;
% % 
% %     sizY = size(Y);
% %     Yr = reshape(Y,prod(sizY(1:end-1)),[]);
% %     nY = min(Yr(:));
% %     savefast(fullfilepath,'Yr','Y','nY','sizY');
% %     data = matfile(fullfilepath,'Writable',true);
% %     
% % end
% 
% %%  Test normcorre stuff:
% % 
% % addpath(genpath('~/Repositories/ca_source_extraction'));
% % addpath(genpath('~/Repositories/NoRMCorre'));
% 
% 
% % addpath(genpath('~/Repositories/ca_source_extraction'));
% % addpath(genpath('~/Repositories/NoRMCorre'));
% 
% 
% % patch_size = [32,32,4];                   % size of each patch along each dimension (optional, default: [32,32])
% % overlap = [4,8,3];                        % amount of overlap in each dimension (optional, default: [4,4])
% % 
% % K = 7;                                            % number of components to be found
% % tau = [4,8,3];                                    % std of gaussian kernel (size of neuron) 
% % p = 2;                                            % order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
% % merge_thr = 0.8;                                  % merging threshold
% 
% %mempath = fullfile(D.nmfPath, 'memfiles');
% files = dir(fullfile(mempath, '*.mat'));
% files = {files(:).name}';
% for fn=1:length(files)
%     if strfind(files{fn}, '_substack')
%         files{fn} = [];
%     end
% end
% files
% 
% 
% for tiffidx = 1:length(files)
% 
% fprintf('Creating substack for %i of %i files...\n', tiffidx, length(files))
% 
% first_tic = tic();
% %tpath = '/nas/volume1/2photon/RESDATA/20161222_JR030W/gratings1/fov1_gratings_10reps_run1_00007.tif';
% % tpath = fullfile(tiffroot, tiffs{tiffidx});
% % [sourcepath, filename, ext] = fileparts(tpath);
% % savedir = 'nmf';
% % 
% % tiffmat = sprintf('%s.mat', filename);
% % matpath = fullfile(sourcepath, savedir, tiffmat);
% nSlices = meta.file(tiffidx).si.nFramesPerVolume;
% nRealFrames = meta.file(tiffidx).si.nSlices;
% nVolumes = meta.file(tiffidx).si.nVolumes;
% if D.tefo
%     nChannels=2;
% else
%     nChannels=1;
% end
% 
% 
% tpath = fullfile(mempath, files{tiffidx});
% [filepath, filename, ext] = fileparts(tpath);
% 
% %matpath = fullfile(mempath, sprintf('%s.mat', filename));
% 
% %tpath = '/nas/volume1/2photon/RESDATA/20161221_JR030W/test_crossref/nmf/analysis/datastruct_002/nmf/memfiles/fov1_bar037Hz_run4_00005_crop.mat';
% %[~, filename, ext] = fileparts(tpath);
% 
% tmpdata = matfile(tpath,'Writable',true);
% 
% filename = [filename, '_substack']
% data = matfile(fullfile(filepath, [filename, ext]), 'Writable', true);
% % CROP flybacK;
% data.Y = tmpdata.Y(:,:,6:end,:);
% data.sizY = size(data.Y);
% data.Yr(1:prod(data.sizY(:,1:end-1)), 1:nVolumes) = reshape(data.Y,prod(data.sizY(:,1:end-1)),[]);
% data.nY = min(data.Yr(:,:));
% 
% clear tmpdata;
% 
% fprintf('Finished:  substack size is %s\n', mat2str(data.sizY));
% 
% end

nmf_outpaths = {};


mempath = fullfile(D.nmfPath, 'memfiles');

tmpfiles = dir(fullfile(mempath, '*.mat'));
tmpfiles = {tmpfiles(:).name}';
subidxs = cell2mat(cellfun(@(x) ~isempty(strfind(x, '_substack')), tmpfiles, 'UniformOutput', 0));
files = tmpfiles(subidxs);

patch_size = D.maskInfo.params.patch_size;
overlap = D.maskInfo.params.overlap;
K = D.maskInfo.params.K;
tau = D.maskInfo.params.tau;
p = D.maskInfo.params.p;
merge_thr = D.maskInfo.params.merge_thr;
 
for tiffidx = 1:length(files)
    
        
first_tic = tic();

tpath = fullfile(mempath, files{tiffidx});
[filepath, filename, ext] = fileparts(tpath);

matpath = fullfile(mempath, sprintf('%s.mat', filename));
data = matfile(matpath,'Writable',true);

fprintf('Processing patches for FILE %s (%i of %i tiffs).\n', filename, tiffidx, length(files));

    
nSlices = meta.file(tiffidx).si.nFramesPerVolume;
nRealFrames = meta.file(tiffidx).si.nSlices;
nVolumes = meta.file(tiffidx).si.nVolumes;
if D.tefo
    nChannels=2;
else
    nChannels=1;
end

if ndims(data.Y) == 4
    [d1,d2,d3,T] = size(data.Y);                            % dimensions of dataset
else
    [d1,d2,T] = size(data.Y);
    d3 = 1;
end
d = d1*d2*d3;                                          % total number of pixels


%% Test NoRMCorre moition correction:

MC = false;

% % Rigid:
% 
% % set parameters:
% options_rigid = NoRMCorreSetParms('d1',size(data.Y,1),'d2',size(data.Y,2),'d3',size(data.Y,3),...
%                 'bin_width',50,'max_shift',15,'us_fac',50);
% % perform motion correction
% tic; [M1,shifts1,template1] = normcorre(data,options_rigid); toc
% 
% % Save MC outputs:
% savefast([filepath(1:end-4),'_MC.mat'],'M1','shifts1','template1');           % save shifts of each file at the respective subfolder
% mcdata = matfile([filepath(1:end-4),'_MC.mat'], 'Writable', true);
% 
% 
% % ** this gets killed.... **
% % now try non-rigid motion correction (also in parallel)
% options_nonrigid = NoRMCorreSetParms('d1',size(data.Y,1),'d2',size(data.Y,2),'d3',size(data.Y,3),...
%                 'grid_size',[32,32],'mot_uf',4,'bin_width',50,'max_shift',15,...
%                 'max_dev',3,'us_fac',50);
% tic; [M2,shifts2,template2] = normcorre_batch(data,options_nonrigid); toc
% 
% %% compute metrics
% 
% nnY = quantile(data.Y(:),0.005);
% nnY = min(nnY(:));
% mmY = quantile(data.Y(:,:,:,:),0.995);
% mmY = min(mmY(:));
% 
% [cY,mY,vY] = motion_metrics(data.Y,5); %10);
% [cM1,mM1,vM1] = motion_metrics(M1,5); %10);
% 
% [cM2,mM2,vM2] = motion_metrics(M2,10);
% T = length(cY);
% 
% %% plot metrics
% figure;
%     ax1 = subplot(2,3,1); imagesc(mY,[nnY,mmY]);  axis equal; axis tight; axis off; title('mean raw data','fontsize',14,'fontweight','bold')
%     ax2 = subplot(2,3,2); imagesc(mM1,[nnY,mmY]);  axis equal; axis tight; axis off; title('mean rigid corrected','fontsize',14,'fontweight','bold')
%     ax3 = subplot(2,3,3); imagesc(mM2,[nnY,mmY]); axis equal; axis tight; axis off; title('mean non-rigid corrected','fontsize',14,'fontweight','bold')
%     subplot(2,3,4); plot(1:T,cY,1:T,cM1,1:T,cM2); legend('raw data','rigid','non-rigid'); title('correlation coefficients','fontsize',14,'fontweight','bold')
%     subplot(2,3,5); scatter(cY,cM1); hold on; plot([0.9*min(cY),1.05*max(cM1)],[0.9*min(cY),1.05*max(cM1)],'--r'); axis square;
%         xlabel('raw data','fontsize',14,'fontweight','bold'); ylabel('rigid corrected','fontsize',14,'fontweight','bold');
%     subplot(2,3,6); scatter(cM1,cM2); hold on; plot([0.9*min(cY),1.05*max(cM1)],[0.9*min(cY),1.05*max(cM1)],'--r'); axis square;
%         xlabel('rigid corrected','fontsize',14,'fontweight','bold'); ylabel('non-rigid corrected','fontsize',14,'fontweight','bold');
%     linkaxes([ax1,ax2,ax3],'xy')
%     
% %% plot shifts        
% 
% shifts_r = horzcat(shifts1(:).shifts)';
% shifts_nr = cat(ndims(shifts2(1).shifts)+1,shifts2(:).shifts);
% shifts_nr = reshape(shifts_nr,[],ndims(Y)-1,T);
% shifts_x = squeeze(shifts_nr(:,1,:))';
% shifts_y = squeeze(shifts_nr(:,2,:))';
% 
% patch_id = 1:size(shifts_x,2);
% str = strtrim(cellstr(int2str(patch_id.')));
% str = cellfun(@(x) ['patch # ',x],str,'un',0);
% 
% figure;
%     ax1 = subplot(311); plot(1:T,cY,1:T,cM1,1:T,cM2); legend('raw data','rigid','non-rigid'); title('correlation coefficients','fontsize',14,'fontweight','bold')
%             set(gca,'Xtick',[])
%     ax2 = subplot(312); plot(shifts_x); hold on; plot(shifts_r(:,1),'--k','linewidth',2); title('displacements along x','fontsize',14,'fontweight','bold')
%             set(gca,'Xtick',[])
%     ax3 = subplot(313); plot(shifts_y); hold on; plot(shifts_r(:,2),'--k','linewidth',2); title('displacements along y','fontsize',14,'fontweight','bold')
%             xlabel('timestep','fontsize',14,'fontweight','bold')
%     linkaxes([ax1,ax2,ax3],'x')
% 
% %% plot a movie with the results
% 
% figure;
% for t = 1:1:T
%     subplot(121);
% %     imagesc(data.Y(:,:,t),[nnY,mmY]); xlabel('raw data','fontsize',14,'fontweight','bold'); axis equal; axis tight;
%     imagesc(data.Y(:,:,10,t),[nnY,mmY]); xlabel('raw data','fontsize',14,'fontweight','bold'); axis equal; axis tight;
% 
%     title(sprintf('Frame %i out of %i',t,T),'fontweight','bold','fontsize',14); colormap('bone')
%     subplot(122);imagesc(M1(:,:,10,t),[nnY,mmY]); xlabel('non-rigid corrected','fontsize',14,'fontweight','bold'); axis equal; axis tight;
%     title(sprintf('Frame %i out of %i',t,T),'fontweight','bold','fontsize',14); colormap('bone')
%     set(gca,'XTick',[],'YTick',[]);
%     drawnow;
%     pause(0.02);
% end
% 
% 
% 

%% Specify paths to memmapped files:



%% ca_source_extraction.

% Test patches:


sizY = data.sizY;                       % size of data matrix
% patch_size = [32,32,4];                   % size of each patch along each dimension (optional, default: [32,32])
% overlap = [4,8,3];                        % amount of overlap in each dimension (optional, default: [4,4])
% 
patches = construct_patches(sizY(1:end-1),patch_size,overlap);
% K = 7;                                            % number of components to be found
% tau = [4,8,3];                                    % std of gaussian kernel (size of neuron) 
% p = 2;                                            % order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
% merge_thr = 0.8;                                  % merging threshold

options = CNMFSetParms(...
    'd1',d1,'d2',d2,'d3',d3,...
    'search_method','ellipse','dist',3,...      % search locations when updating spatial components
    'deconv_method','constrained_foopsi',...    % activity deconvolution method
    'temporal_iter',2,...                       % number of block-coordinate descent steps 
    'cluster_pixels',false,...
    'ssub',1,...                                % spatial downsampling when processing
    'tsub',1,...                                % further temporal downsampling when processing
    'fudge_factor',0.96,...                     % bias correction for AR coefficients
    'merge_thr',merge_thr,...                   % merging threshold
    'gSig',tau,... 
    'max_size_thr',50,'min_size_thr',2,...    % max/min acceptable size for each component
    'spatial_method','regularized',...          % method for updating spatial components
    'df_prctile',50,...
    'space_thresh',0.6); %...                       % take the median of background fluorescence to compute baseline fluorescence 
    %);

%%

%K = 1705;
if D.maskInfo.params.patches
    %% Run on patches (around 15 minutes)

    tic;
    [A,b,C,f,S,P,RESULTS,YrA] = run_CNMF_patches(data,K,patches,tau,p,options);
    fprintf('Completed CNMF patches for %i of %i tiffs.\n', tiffidx, length(files));

    results_fn = fullfile(D.nmfPath, sprintf('patch_results_File%03d_substack', tiffidx) );
    patch_results = matfile(results_fn, 'Writable', true);
    patch_results.RESULTS = RESULTS;
    patch_results.A = A;
    patch_results.b = b;
    patch_results.C = C;
    patch_results.f = f;
    patch_results.S = S;
    patch_results.P = P;
    patch_results.YrA = YrA;
    patch_results.patch_size = patch_size;
    patch_results.patch_overlap = overlap;

    fprintf('Saved results of run_CNMF_patches, File%03d.\n', tiffidx);

    toc

    % 256x256x20 volume:
    % Elapsed time is 2797.389282 seconds.


else

    [P,Y] = preprocess_data(data.Y,p);    

    rois = load('/nas/volume1/2photon/RESDATA/TEFO/20161219_JR030W/retinotopyFinalMask/analysis/datastruct_006/rois.mat');
    roiA = rois.all;
    P.ROI_list = double(roiA);
    [Ain,Cin,bin,fin,center] = initialize_components(data.Y,K,tau,options,P);  % initialize

    ff = find(sum(Ain)<1e-3*mean(sum(Ain)));   % remove very small components

    % Get centers of each ROI:
    centers = com(Ain,d1,d2,d3);
    if size(centers,2) == 2
        centers(:,3) = 1;
    end
    centers = round(centers);

    % Get avgs of each slice (instead of corr imgs):
    avgs = zeros([d1,d2,d3]);
    for slice=1:d3
        avgs(:,:,slice) = mean(data.Y(:,:,slice,:), 4);
    end


    plotCenteroverY(avgs, center, [d1,d2,d3]);  % plot found centers against max-projections of background image

    [A,b,Cin] = update_spatial_components(data.Yr,Cin,fin,[Ain,bin],P,options);

    P.p = 0;
    [C,f,P,S,YrA] = update_temporal_components(data.Yr,A,b,Cin,fin,P,options);
    P.p = 2;

end

%% compute correlation image on a small sample of the data (optional - for visualization purposes) 

% Cn = correlation_image_max(single(data.Y),8);
% 
Cn = correlation_image_3D(data.Y); 
% 
%     
% %% classify components
% 
% [ROIvars.rval_space,ROIvars.rval_time,ROIvars.max_pr,ROIvars.sizeA,keep] = classify_components(data,A,C,b,f,YrA,options);
% 
% 
% %% display centers of found components
% if show_plots
%     plotCenteroverY(Cn, center, [d1,d2,d3]);  % plot found centers against max-projections of background image
% end

%% Plot components and view traces:

% Cn looks crappy, try just avg to do sanity check of ROIs:
avgs = zeros([d1,d2,d3]);
for slice=1:d3
    avgs(:,:,slice) = mean(data.Y(:,:,slice,:), 4);
end

%[T_out, Y_r_out, C_out, Df_out] = plot_components_3D_GUI(data.Y,A,C,b,f,Cn,options);
[T_out, Y_r_out, C_out, Df_out] = plot_components_3D_GUI(data.Y,A,C,b,f,avgs,options);


%[T_out, Y_r_out, C_out, Df_out] = plot_components_3D_GUI(data.Y,patch.A,patch.C,patch.b,patch.f,avgs,options);

%% SAVE nmf output:

nmf_outfile = ['nmfoutput_' filename, '_substack.mat']
nmf_outputpath = fullfile(D.nmfPath, nmf_outfile);
nmfoutput = matfile(nmf_outputpath, 'Writable', true);

nmfoutput.mempath = mempath;
nmfoutput.outpath = nmf_outputpath; %fullfile(sourcepath, savedir);
nmfoutput.tiff = [filename, '.tif'];
nmfoutput.K = K;
nmfoutput.tau = tau;
nmfoutput.merge_thr = merge_thr;
nmfoutput.p = p;
nmfoutput.options = options;
nmfoutput.motion = MC;

nmfoutput.A = A;
nmfoutput.Cn = Cn;
nmfoutput.avgs = avgs;
nmfoutput.C = C;
nmfoutput.b = b;
nmfoutput.f = f;
nmfoutput.Y = data.Y;

nmfoutput.T_out = T_out;
nmfoutput.Yr_out = Y_r_out;
nmfoutput.C_out = C_out;
nmfoutput.Df_out = Df_out;
%nmfoutput.center = center;

fprintf('Finished CNMF trace extraction for %i of %i files.\n', tiffidx, length(files));
fprintf('TOTAL ELAPSED TIME for file %i: \n')
toc(first_tic);

nmf_outpaths{end+1} = nmf_outputpath; %fullfile(maskPath, nmfStructName);

close all;

end