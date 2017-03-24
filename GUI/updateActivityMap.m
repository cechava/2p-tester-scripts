function updateActivityMap(handles, D, meta)

selectedSliceIdx = handles.currSlice.Value; %str2double(handles.currSlice.String);
selectedSlice = D.slices(selectedSliceIdx);
selectedFile = handles.runMenu.Value;


%avgimg = getCurrentSliceImage(handles, D);
fov = repmat(mat2gray(D.avgimg), [1, 1, 3]);

currRunName = meta.file(selectedFile).mw.runName;

% mapStructName = sprintf('maps_Slice%02d.mat', selectedSlice); 
% if ~exist(fullfile(D.guiPrepend, D.outputDir, mapStructName), 'file')
%     mapTypes = {'NaN'};
% else     
%     mapStruct = load(fullfile(D.guiPrepend, D.outputDir, mapStructName));
%     mapTypes = fieldnames(mapStruct.file(selectedFile));
% end

% Populate MAP menu options: --------------------------------------------
if isfield(D, 'dfStructName')
    dfStruct = load(fullfile(D.guiPrepend, D.outputDir, D.dfStructName));
    setappdata(handles.roigui, 'df', dfStruct);
    if isempty(dfStruct.slice(selectedSlice).file)
        fprinf('No DF struct found for slice %i.\n', selectedSlice);
        noDF = true;
    else
        noDF = false;
    end
else
    fprintf('No DF struct found in current acquisition.\n');
    noDF = true;
end

mapStructName = sprintf('maps_Slice%02d.mat', selectedSlice); 
if ~exist(fullfile(D.guiPrepend, D.outputDir, mapStructName), 'file')
    if noDF
        mapTypes = {'NaN'};
    else
        mapTypes = {'maps - notfound'};
    end
else
    mapStruct = load(fullfile(D.guiPrepend, D.outputDir, mapStructName));
    mapTypes = fieldnames(mapStruct.file(selectedFile));
end
if noDF %isempty(dfStruct.slice(selectedSlice).file)
    mapTypes{end+1} = 'maxDf - not found';
else
    mapTypes{end+1} = 'maxDf';
end
handles.mapMenu.String = mapTypes;
    


if handles.mapMenu.Value > length(mapTypes)
    handles.mapMenu.Value = 1;
end
selectedMapIdx = handles.mapMenu.Value;

selectedMapType = mapTypes{selectedMapIdx};
if (any(ismember(mapTypes, 'NaN')) || any(ismember(mapTypes, 'maxDf - not found')))
    displayMap = zeros(size(fov));
elseif strcmp(selectedMapType, 'maxDf')
    displayMap = dfStruct.slice(selectedSlice).file(selectedFile).maxMap;
else
    displayMap = mapStruct.file(selectedFile).(selectedMapType);
    magMap = mapStruct.file(selectedFile).ratio;

    currThresh = str2double(handles.threshold.String);
    thresholdMap = threshold_map(displayMap, magMap, currThresh);
end

switch selectedMapType
    
    case 'phase'
        thresholdMap = threshold_map(displayMap, magMap, currThresh);
        axes(handles.ax2);  
        handles.map = imagesc(scalefov(fov));
        hold on;
        handles.map = imagesc2(scalefov(thresholdMap));
        colormap(handles.ax2, hsv);
        caxis([min(displayMap(:)), max(displayMap(:))]);
        colorbar off;
        
    case 'phasemax'
        thresholdMap = threshold_map(displayMap, magMap, currThresh);
        axes(handles.ax2);  
        handles.map = imagesc(scalefov(fov));
        hold on;
        handles.map = imagesc2(scalefov(thresholdMap));
        colormap(handles.ax2, hsv);
        caxis([min(displayMap(:)), max(displayMap(:))]);
        colorbar off;
        
    otherwise
        % 'ratio' 
        % 'magnitude'
        % 'maxDf'
        axes(handles.ax2);  
        handles.map = imagesc2(scalefov(displayMap)); %, handles.ax2);
        colormap(handles.ax2, hot);
        caxis([min(displayMap(:)), max(displayMap(:))])
        colorbar();

    
end
refPos = handles.ax1.Position;
ax2Pos = handles.ax2.Position;
handles.ax2.Position(3:4) = [refPos(3:4)];
title(currRunName);
%colorbar();
%
end