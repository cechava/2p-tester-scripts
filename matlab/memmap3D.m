function memmap3D(D, meta)

startSliceIdx = D.slices(1);
fprintf('Substacks made starting from slice %i.\n', startSliceIdx);

mempath = fullfile(D.nmfPath, 'memfiles');
if ~exist(mempath, 'dir')
    mkdir(mempath)
end


tiffs = dir(fullfile(D.sourceDir, '*.tif'));
tiffs = {tiffs(:).name}'

files = dir(fullfile(mempath, '*.mat'));
tmpfiles = {files(:).name}';
subidxs = cell2mat(cellfun(@(x) isempty(strfind(x, '_substack')), tmpfiles, 'UniformOutput', 0))
files = tmpfiles(subidxs)

if length(tiffs)>length(files)


    tic()
    for tiffidx = 1:length(tiffs)
    %tpath = '/nas/volume1/2photon/RESDATA/20161222_JR030W/gratings1/fov1_gratings_10reps_run1_00007.tif';
    tpath = fullfile(D.sourceDir, tiffs{tiffidx});
    [source, filename, ext] = fileparts(tpath);

    matpath = fullfile(mempath, sprintf('%s.mat', filename));
    data = matfile(matpath,'Writable',true);

    %info = imfinfo(tpath);

    %nSlices = 20; nVolumes = 350;
    %tic; Yt = loadtiff(tpath, 1, nSlices*2); toc;
    %Yt = Yt(:,:,1:2:end);

    %nSlices = meta.file(tiffidx).si.nSlices;
    nSlices = meta.file(tiffidx).si.nFramesPerVolume;
    nRealFrames = meta.file(tiffidx).si.nSlices;
    nVolumes = meta.file(tiffidx).si.nVolumes;
    if D.tefo
        nChannels=2;
    else
        nChannels=1;
    end

    tic; Yt = loadtiff(tpath, 1, nSlices*nVolumes*nChannels); toc;

    % Only grab green channel:
    if strcmp(D.preprocessing, 'raw') && D.tefo
        Yt = Yt(:,:,1:2:end);
    end

    Y = cell(1, nVolumes);
    firstslice = 1;
    for vol=1:nVolumes
        Y{vol} = Yt(:,:,firstslice:(firstslice+nRealFrames-1));
        firstslice = firstslice+nSlices;
    end
    Y = cat(4, Y{1:end});
    if ~isa(Y, 'double'); Y = double(Y); end    % convert to double
    Y = Y -  min(Y(:));                         % make data non-negative

    data.Y = Y;
    data.sizY = size(data.Y);
    data.Yr(1:prod(data.sizY(:,1:end-1)), 1:nVolumes) = reshape(data.Y,prod(data.sizY(:,1:end-1)),[]);
    data.nY = min(data.Yr(:,:));

    fprintf('Memmapping finished for %i of %i files.\n', tiffidx, length(tiffs));
    fprintf('Size of memmaped movie is: %s\n', mat2str(data.sizY));
    
    end

end

% 
fprintf('Done!');
toc()


% MAKE SUBSTACK:
%startSliceIdx = 4
%mempath = fullfile(D.nmfPath, 'memfiles');
tmpfiles = dir(fullfile(mempath, '*.mat'));
tmpfiles = {tmpfiles(:).name}';
subidxs = cell2mat(cellfun(@(x) ~isempty(strfind(x, '_substack')), tmpfiles, 'UniformOutput', 0))
files = tmpfiles(subidxs);

if isempty(files)
    files = tmpfiles(~subidxs);

    for tiffidx = 1:length(files)

        fprintf('Processing substack for %i of %i files...\n', tiffidx, length(files))

        first_tic = tic();

        nSlices = meta.file(tiffidx).si.nFramesPerVolume;
        nRealFrames = meta.file(tiffidx).si.nSlices;
        nVolumes = meta.file(tiffidx).si.nVolumes;
        if D.tefo
            nChannels=2;
        else
            nChannels=1;
        end


        tpath = fullfile(mempath, files{tiffidx});
        [filepath, filename, ext] = fileparts(tpath);

        %matpath = fullfile(mempath, sprintf('%s.mat', filename));

        %tpath = '/nas/volume1/2photon/RESDATA/20161221_JR030W/test_crossref/nmf/analysis/datastruct_002/nmf/memfiles/fov1_bar037Hz_run4_00005_crop.mat';
        %[~, filename, ext] = fileparts(tpath);

        tmpdata = matfile(tpath,'Writable',true);

        filename = [filename, '_substack']
        data = matfile(fullfile(filepath, [filename, ext]), 'Writable', true);
        % CROP flybacK;
        data.Y = tmpdata.Y(:,:,startSliceIdx:end,:);
        data.sizY = size(data.Y);
        data.Yr(1:prod(data.sizY(:,1:end-1)), 1:nVolumes) = reshape(data.Y,prod(data.sizY(:,1:end-1)),[]);
        data.nY = min(data.Yr(:,:));

        clear tmpdata;

        fprintf('Finished:  substack size is %s\n', mat2str(data.sizY));

    end
else
   
    fprintf('Checking TIFF substakc size...\n');
    
    for tiffidx=1:length(files)
        tpath = fullfile(mempath, files{tiffidx});
        data = matfile(tpath);
        fprintf('TIFF %i of %i: size is %s.\n', tiffidx, length(files), mat2str(data.sizY));

    end
    
end
end
