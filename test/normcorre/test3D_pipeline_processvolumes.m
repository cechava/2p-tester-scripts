
clear all;
clc;

addpath(genpath('~/Repositories/ca_source_extraction'));
addpath(genpath('~/Repositories/NoRMCorre'));

%% Specify tiff sources and covnert to matfile objs:

source = '/nas/volume1/2photon/RESDATA/20161221_JR030W';
experiment = 'test_crossref';
tiffroot = fullfile(source, experiment);
savedir = 'nmf';
outpath = fullfile(tiffroot, savedir);

if ~exist(outpath, 'dir')
    mkdir(outpath)
end

nvolumes = 350; %256;
nslices = 20;

tiffs = dir(fullfile(tiffroot, '*.tif'));
tiffs = {tiffs(:).name}'

tiffs = {'fov1_bar037Hz_run4_00005_crop.tif'};
tic()
for tiffidx = 3:3 %1:1 %length(tiffs)
%tpath = '/nas/volume1/2photon/RESDATA/20161222_JR030W/gratings1/fov1_gratings_10reps_run1_00007.tif';
tpath = fullfile(tiffroot, savedir, tiffs{tiffidx});
[sourcepath, filename, ext] = fileparts(tpath);

matpath = fullfile(outpath, sprintf('%s.mat', filename));
data = matfile(matpath,'Writable',true);

%info = imfinfo(tpath);

nSlices = 20; nVolumes = 350;
%tic; Yt = loadtiff(tpath, 1, nSlices*2); toc;
%Yt = Yt(:,:,1:2:end);
tic; Yt = loadtiff(tpath, 1, nSlices*nVolumes); toc;

Y = cell(1, nVolumes);
firstslice = 1;
for vol=1:nVolumes
    Y{vol} = Yt(:,:,firstslice:(firstslice+nSlices-1));
    firstslice = firstslice+nSlices;
end

data.Y(1:size(Yt,1), 1:size(Yt,2), 1:nSlices, 1:nVolumes) = cat(4, Y{1:end});
data.sizY = size(data.Y);
data.Yr(1:prod(data.sizY(:,1:end-1)), 1:nVolumes) = reshape(data.Y,prod(data.sizY(:,1:end-1)),[]);
data.nY = min(data.Yr(:,:));


% Read in chunks at a time:
% sizY = [size(Yt) nVolumes];
% data.Y(sizY(1),sizY(2),sizY(3),sizY(4)) = Yt(1)*0;
% data.Yr(numel(Yt), nVolumes) = Yt(1)*0;
% nY = Inf;
% sframe = 1;
% for i = sframe:(nSlices*2):(nSlices*nVolumes*2)
%     tic()
%     Ytemp = loadtiff(tpath, i, nSlices*2);
%     Ytemp = Ytemp(:,:,1:2:end);
%     Yr = reshape(Ytemp, prod(sizY(1:end-1)), []);
%     nY = min(nY, min(Yr(:)));
%     data.Yr(:,i:i-1+size(Yr,2)) = Yr;
%     %data.Y(1:sizY(1),1:sizY(2),1:sizY(3),i-1+(1:size(Yr,2))) = Ytemp; % fix this to deal with alt. indexing
%     data.Y(1:sizY(1),1:sizY(2),1:sizY(3),(1:size(Yr,2))) = Ytemp;
%     fprintf('Finished chunk %i:\n', i);
%     toc()
% end
% %


% 
% Y_ch1(:,:,sframe:sframe+(chunksize/2)-1) = double(tmpY(1:2:end));
% clear tmpY
% sframe = sframe + chunksize;
% 
% sizY = [size(tmpY) nSlices nVolumes];
% 
% Y_ch1 = tmpY(:,:,1:2:end);
% %Y_ch2 = tmpY(:,:,2:2:end);
% 
% %splitpath = fullfile(outpath, sprintf('%s_splitCH.mat', filename));
% %savefast(splitpath,'Y_ch1','Y_ch2');
% clear tmpY;
% %clear Y_ch2;
% 
% matpath = fullfile(outpath, sprintf('%s.mat', filename));
% data = matfile(matpath,'Writable',true);
% 
% % Reshape to 4d volume for 3d pipeline:
% Y = cell(1, nvolumes);
% firstslice = 1;
% for vol=1:nvolumes
%     Y{vol} = Y_ch1(:,:,firstslice:(firstslice+nslices-1));
%     firstslice = firstslice+nslices;
% end

% figure();
% minY = min(Y_ch1(:));
% maxY = max(Y_ch1(:));
% for slice=1:size(volmat{1}, 3)
%     imagesc(volmat{1}(:,:,slice))
%     %imshow(Y_ch1(:,:,slice))
%     caxis([minY maxY]);
%     pause(1)
% end
% 
% data.Y = cat(4, Y{1:end});
% data.sizY = size(data.Y);
% data.Yr = reshape(data.Y,prod(data.sizY(1:end-1)),[]);
% data.nY = min(data.Yr(:));

end

% 
fprintf('Memmapping completed! Procssed %i files.\n', length(sframe:(nSlices*2):(nSlices*nVolumes*2)));
toc()

% avgvolume = mean(volumemat, 4);
% 
% figure();
% minY = min(avgvolume(:));
% maxY = max(avgvolume(:));
% for slice=1:size(avgvolume, 3)
%     imagesc(avgvolume(:,:,slice))
%     %imshow(Y_ch1(:,:,slice))
%     caxis([minY maxY]);
%     pause(1)
% end

%save(fullfile(sourcepath, savedir, sprintf('%s.mat', filename)), 'volumemat', '-v7.3')


%% Turn volumemat into data memmap object:

% 
% tpath = '/nas/volume1/2photon/RESDATA/20161222_JR030W/gratings1/fov1_gratings_10reps_run1_00007.tif';
% [sourcepath, filename, ext] = fileparts(tpath);
% savedir = 'nmf';
% tiffmat = sprintf('%s.mat', filename);
% 
% fullfilepath = fullfile(sourcepath, savedir, tiffmat);
% tmpdata = matfile(fullfilepath);
% if ~isprop(tmpdata, 'Y')
%     load(fullfilepath)
%     Y = volumemat;
%     clear volumemat;
% 
%     sizY = size(Y);
%     Yr = reshape(Y,prod(sizY(1:end-1)),[]);
%     nY = min(Yr(:));
%     savefast(fullfilepath,'Yr','Y','nY','sizY');
%     data = matfile(fullfilepath,'Writable',true);
%     
% end

%%  Test normcorre stuff:
% 
% addpath(genpath('~/Repositories/ca_source_extraction'));
% addpath(genpath('~/Repositories/NoRMCorre'));


% addpath(genpath('~/Repositories/ca_source_extraction'));
% addpath(genpath('~/Repositories/NoRMCorre'));

for tiffidx = 3:3 %1:1 %length(tiffs)
%tpath = '/nas/volume1/2photon/RESDATA/20161222_JR030W/gratings1/fov1_gratings_10reps_run1_00007.tif';
% tpath = fullfile(tiffroot, tiffs{tiffidx});
% [sourcepath, filename, ext] = fileparts(tpath);
% savedir = 'nmf';
% 
% tiffmat = sprintf('%s.mat', filename);
% matpath = fullfile(sourcepath, savedir, tiffmat);

matpath = fullfile(outpath, [tiffs{tiffidx}(1:end-3), 'mat']);

% load(fullfile(sourcepath, savedir, tiffmat));
% Y = volumemat;
% clear volumemat;

%if exist([filepath(1:end-3),'mat'],'file')
data = matfile(matpath,'Writable',true);
% else
%     sframe=1;						% user input: first frame to read (optional, default 1)
%     num2read=[];					% user input: how many frames to read   (optional, default until the end)
%     chunksize=5000;                 % user input: read and map input in chunks (optional, default read all at once)
%     data = memmap_file(filepath,sframe,num2read,chunksize);
%     %data = memmap_file_sequence(foldername);
% end

% Set parameters
% sizY = size(data,'Y');                  % size of data matrix
% patch_size = [32,32];                   % size of each patch along each dimension (optional, default: [32,32])
% overlap = [4,4];                        % amount of overlap in each dimension (optional, default: [4,4])
% 

if ndims(data.Y) == 4
    [d1,d2,d3,T] = size(data.Y);                            % dimensions of dataset
else
    [d1,d2,T] = size(data.Y);
    d3 = 1;
end
d = d1*d2*d3;                                          % total number of pixels


%% Test NoRMCorre moition correction:

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


    


%% ca_source_extraction.

% Test patches:


sizY = data.sizY;                       % size of data matrix
patch_size = [32,32,4];                   % size of each patch along each dimension (optional, default: [32,32])
overlap = [4,8,3];                        % amount of overlap in each dimension (optional, default: [4,4])

patches = construct_patches(sizY(1:end-1),patch_size,overlap);
K = 7;                                            % number of components to be found
tau = [4,8,3];                                    % std of gaussian kernel (size of neuron) 
p = 2;                                            % order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
merge_thr = 0.8;                                  % merging threshold

options = CNMFSetParms(...
    'd1',d1,'d2',d2,'d3',d3,...
    'search_method','ellipse','dist',3,...      % search locations when updating spatial components
    'deconv_method','constrained_foopsi',...    % activity deconvolution method
    'temporal_iter',2,...                       % number of block-coordinate descent steps 
    'cluster_pixels',false,...
    'ssub',3,...                                % spatial downsampling when processing
    'tsub',1,...                                % further temporal downsampling when processing
    'fudge_factor',0.96,...                     % bias correction for AR coefficients
    'merge_thr',merge_thr,...                   % merging threshold
    'gSig',tau,... 
    'max_size_thr',100,'min_size_thr',10,...    % max/min acceptable size for each component
    'spatial_method','regularized',...          % method for updating spatial components
    'df_prctile',50); %...                       % take the median of background fluorescence to compute baseline fluorescence 
    %);
    
 %% Run on patches (around 15 minutes)
   
tic;
[A,b,C,f,S,P,RESULTS,YrA] = run_CNMF_patches(data,K,patches,tau,p,options)
toc

% 256x256x20 volume:
% Elapsed time is 2797.389282 seconds.


%% compute correlation image on a small sample of the data (optional - for visualization purposes) 

Cn = correlation_image_max(single(data.Y),8);

Cn = correlation_image_3D(data.Y); 

    
%% classify components

[ROIvars.rval_space,ROIvars.rval_time,ROIvars.max_pr,ROIvars.sizeA,keep] = classify_components(data,A,C,b,f,YrA,options);


%% display centers of found components
if show_plots
    plotCenteroverY(Cn, center, [d1,d2,d3]);  % plot found centers against max-projections of background image
end

%% Plot components and view traces:

% Cn looks crappy, try just avg to do sanity check of ROIs:
avgs = zeros(size(Cn));
for slice=1:d3
    avgs(:,:,slice) = mean(data.Y(:,:,slice,:), 4);
end

%[T_out, Y_r_out, C_out, Df_out] = plot_components_3D_GUI(data.Y,A,C,b,f,Cn,options);
[T_out, Y_r_out, C_out, Df_out] = plot_components_3D_GUI(data.Y,A,C,b,f,avgs,options);

%% run GUI for modifying component selection (optional, close twice to save values)
% run_GUI = true;
% if run_GUI
%     Coor = plot_contours(A,Cn,options,1); close;
%     GUIout = ROI_GUI(A,options,Cn,Coor,keep,ROIvars);   
%     options = GUIout{2};
%     keep = GUIout{3};    
% end

%% NO PATCHES -------------------------------------------------------------
% =========================================================================
% =========================================================================
%% Set parameters

K = 500; %200;                                          % number of components to be found
tau = [4,6,3];                                    % std of gaussian kernel (size of neuron) 
p = 2;                                            % order of autoregressive system (p = 0 no dynamics for slow imaging rate)
merge_thr = 0.85;                                 % merging threshold

options = CNMFSetParms(...                      
    'd1',d1,'d2',d2,'d3',d3,...                  % dimensions of datasets
    'search_method','dilate',...                 % search locations when updating spatial components
    'maxIter',15,...                             % number of NMF iterations during initialization
    'deconv_method','constrained_foopsi',...     % activity deconvolution method
    'temporal_iter',2,...                        % number of block-coordinate descent steps 
    'fudge_factor',0.98,...                      % bias correction for AR coefficients
    'merge_thr',merge_thr,...                    % merging threshold
    'gSig',tau,'nb',1 ...
    );

%% Data pre-processing

MC = false;

if MC
    [P,Y] = preprocess_data(mcdata.M1,p);
    Cn = correlation_image_3D(mcdata.M1); 
else
    [P,Y] = preprocess_data(data.Y,p);
    Cn = correlation_image_3D(data.Y); 
end
% for large datasets change with reshape(P.sn,d1,d2,d3), %max(Y,[],3); %std(Y,[],3); % image statistic (only for display purposes)

%Coor = correlation_image_3D(reshape(P.sn,d1,d2,d3), max(Y,[],3), std(Y,[],3));

%% show movie of projections
% plot4Dproj(Y, Cn, [d1,d2,d3]);

%% fast initialization of spatial components using greedyROI and HALS
if MC
    [Ain,Cin,bin,fin,center] = initialize_components(mcdata.M1,K,tau,options,P);  % initialize
else
    [Ain,Cin,bin,fin,center] = initialize_components(data.Y,K,tau,options,P);  % initialize
end
ff = find(sum(Ain)<1e-3*mean(sum(Ain)));   % remove very small components
Ain(:,ff) = [];
Cin(ff,:) = [];
center(ff,:) = [];

%% display centers of found components
if show_plots
    plotCenteroverY(Cn, center, [d1,d2,d3]);  % plot found centers against max-projections of background image
end

%% update spatial components
Yr = reshape(Y,d,T);
%clear Y;
[A,b,Cin] = update_spatial_components(Yr,Cin,fin,[Ain,bin],P,options);

%% update temporal components
P.p = 2;
[C,f,P,S,YrA] = update_temporal_components(Yr,A,b,Cin,fin,P,options);

%%

% Try reshaping Yr:
% Yr = reshape(Yr, options.d1, options.d2, options.d3, T);
% [ROIvars.rval_space,ROIvars.rval_time,ROIvars.max_pr,ROIvars.sizeA,keep] = classify_components(Yr,A,C,b,f,YrA,options);
% 
% Cn2d= max(Y,[],3);
% Coor = plot_contours(A,Cn2d,options,1); close;

%% plot components
%plot_components_3D_GUI(Y,A,C,b,f,Cn,options)
%% merge found components and repeat (optional)
%[Am,Cm,K_m,merged_ROIs,Pm,Sm] = merge_components(Yr,A,b,C,f,P,S,options);

%% repeat (optional)
%[A2,b2,Cm] = update_spatial_components(Yr,Cm,f,Am,Pm,options);
%[C2,f2,P2,S2] = update_temporal_components(Yr,A2,b2,Cm,f,Pm,options);

[T_out, Y_r_out, C_out, Df_out] = plot_components_3D_GUI(Y,A,C,b,f,Cn,options);

close all

%%
% Get center of found 3D component on z-plane:
center = com(A,d1,d2,d3);
if size(center,2) == 2
    center(:,3) = 1;
end
center = round(center);
%zplane = center(i,3);

% To plot extracted Df/f trace:

% plot(1:T,Y_r(i,:)/Df(i),'linewidth',2); 
% hold all; 
% plot(1:T,C(i,:)/Df(i),'linewidth',2);

%minC = max(squeeze(min(min(Cn,[],1),[],2)),0);
%maxC = squeeze(max(max(Cn,[],1),[],2));


nmf_outfile = ['output_' filename, '.mat']
nmf_outputpath = fullfile(sourcepath, nmf_outfile);
nmfoutput = matfile(nmf_outputpath, 'Writable', true);

nmfoutput.filepath = matpath;
nmfoutput.savedir = fullfile(sourcepath, savedir);
nmfoutput.tiff = [filename, '.tif'];
nmfoutput.K = K;
nmfoutput.tau = tau;
nmfoutput.merge_thr = merge_thr;
nmfoutput.p = p;
nmfoutput.options = options;
nmfoutput.motion = MC;

nmfoutput.A = A;
nmfoutput.Cn = Cn;
nmfoutput.T = T_out;
nmfoutput.Y_r = Y_r_out;
nmfoutput.C = C_out;
nmfoutput.Df = Df_out;
nmfoutput.center = center;

% From A:
% nA = full(sqrt(sum(A.^2))');
% [K,~] = size(C);
% A = A/spdiags(nA,0,K,K);    % normalize spatial components to unit energy

% From Cn:
%minC = max(squeeze(min(min(Cn,[],1),[],2)),0);
%maxC = squeeze(max(max(Cn,[],1),[],2));


% To plot ROI contour on center of 3d correl. image:

% imagesc(Cn(:,:,center(i,3)),[minC(center(i,3)),maxC(center(i,3))]); axis equal; axis tight; axis off; hold on; colorbar;
% A_temp = reshape(full(A(:,i)),d1,d2,d3);
% A_temp = A_temp(:,:,center(i,3));
% A_temp = medfilt2(A_temp,[3,3]);            
% A_temp = A_temp(:);
% [temp,ind] = sort(A_temp(:).^2,'ascend');
% temp =  cumsum(temp);
% ff = find(temp > (1-thr)*temp(end),1,'first');
% if ~isempty(ff)
%     [~,ww] = contour(reshape(A_temp,d1,d2),[0,0]+A_temp(ind(ff)),'LineColor','k');
%     ww.LineWidth = 2;
% end

end