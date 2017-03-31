function [handles, D] = updateStimulusPlot(handles, D)

selectedSliceIdx = handles.currSlice.Value; %str2double(handles.currSlice.String);
selectedSlice = D.slices(selectedSliceIdx);
selectedFile = handles.runMenu.Value;
selectedStimIdx = handles.stimMenu.Value;
stimNames = handles.stimMenu.String;
selectedStim = handles.stimMenu.String{selectedStimIdx};

selectedRoi = str2double(handles.currRoi.String);


stimstruct = getappdata(handles.roigui, 'stimstruct');
stimcolors = getappdata(handles.roigui, 'stimcolors');

trialstruct = getappdata(handles.roigui, 'trialstruct');

% dfMat = stimstruct.slice(selectedSlice).(selectedStim).dfCell{selectedRoi}.*100;
% mwSec = stimstruct.slice(selectedSlice).(selectedStim).mwinterpMat;
mwTrialTimes = stimstruct.slice(selectedSlice).(selectedStim).mwTrialTimes;
% nTrials = size(dfMat,1);

dfMat = stimstruct.slice(selectedSlice).(selectedStim).dfTraceCell{selectedRoi}.*100;
mwSec = stimstruct.slice(selectedSlice).(selectedStim).siTimeMat; % If created before 03/29/2017, need to transpose
trimmed = stimstruct.slice(selectedSlice).(selectedStim).trimmedAndPadded;
nTrials = size(dfMat,2);

%PLOT:
axes(handles.ax3);

if ~handles.stimShowAvg.Value % Show each trial:
%     for trial=1:size(dfMat, 1);
%         trial
%         plot(mwinterpMat(trial,:), dfMat(trial,:), 'Color', [0.7 0.7 0.7], 'LineWidth',0.1);
%         hold on;
%     end
    
    % Plot each trial trace:
%     for trial=1:size(dfMat,2)
% 
% %         handles.stimtrials(trial) = plot(mwSec(:,trial), dfMat(:,trial), 'Color', [0.7 0.7 0.7], 'LineWidth',0.1,...
% %                                         'ButtonDownFcn', @selectTrace);  
%         handles.stimtrials(trial) = plot(mwSec(:,trial), dfMat(:,trial), 'Color', [0.7 0.7 0.7], 'LineWidth',0.1); 
%         handles.stimMenu.UserData.clickedTrial = trialstruct.slice(selectedSlice).info.(selectedStim){trial}.tiffNum;
%         hold on;
%     end
%     setappdata(handles.roigui, 'handles', handles)
        

      handles.stimtrials = plot(mwSec, dfMat, 'Color', [0.7 0.7 0.7], 'LineWidth',0.1);
      setappdata(handles.roigui, 'dfMat', dfMat);          
        %handles.stimplot.trials(trial).
%         handles.stimMenu.UserData.clickedTrial = trialstruct.slice(selectedSlice).info.(selectedStim){trial}.tiffNum;
        %handles.stimplot.trials(trial).ButtonDownFcn = 
        %handles.stimplot.trials(trial).ButtonDownFcn = @ax3_ButtonDownFcn;
%         handles.stimplot.trials(trial).HitTest = 'on';
%         handles.stimplot.trials(trial).PickableParts = 'all';
%         handles.stimplot(trial).HitTest = 'on';
%         handles.stimplot(trial).PickableParts = 'all';
%         handles.stimplot(trial).ButtonDownFcn = @ax3_ButtonDownFcn;
%         
%         hold on;
%     end
    hold on;
    
    % Plot MW stim ON patch:
    stimOnset = mean(mwTrialTimes(:,2));
    stimOffset = mean(mwTrialTimes(:,3));
    ylims = get(gca, 'ylim');
    v = [stimOnset ylims(1); stimOffset ylims(1);...
        stimOffset ylims(2); stimOnset ylims(2)];
    f = [1 2 3 4];
    handles.stimepochs = patch('Faces',f,'Vertices',v,'FaceColor',stimcolors(selectedStimIdx,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    hold on;
    
    % Plot MEAN trace for current ROI across stimulus reps:
    %meanTraceInterp = mean(dfMat, 1);
    meanTraceInterp = nanmean(dfMat, 2);
    meanMWTime = nanmean(mwSec,2);
    handles.stimtrialmean = plot(meanMWTime, meanTraceInterp, 'k', 'LineWidth', 2);
    hold on;
else
    meanDfMat = {};
    for stimIdx=1:length(stimNames)
        stimname = ['stim' num2str(stimIdx)];
        %dfMat = stimstruct.slice(selectedSlice).(stimname).dfCell{selectedRoi}.*100;
        %mwSec = stimstruct.slice(selectedSlice).(stimname).mwinterpMat;
        mwTrialTimes = stimstruct.slice(selectedSlice).(stimname).mwTrialTimes;

        dfMat = stimstruct.slice(selectedSlice).(stimname).dfTraceCell{selectedRoi}.*100;
        mwSec = stimstruct.slice(selectedSlice).(stimname).siTimeMat; %
        trimmed = stimstruct.slice(selectedSlice).(stimname).trimmedAndPadded;
        
        %meanTraceInterp = mean(dfMat, 1);
        meanTraceInterp = nanmean(dfMat, 2);
        meanMWTime = nanmean(mwSec,2);
    
        handles.stimtrialmean(stimIdx) = plot(meanMWTime, meanTraceInterp, 'Color', stimcolors(stimIdx,:), 'LineWidth', 0.5);
        hold on;
        
        meanDfMat{end+1} = meanTraceInterp;
        
    end
    setappdata(handles.roigui, 'dfMat', meanDfMat);      
    
    % Plot MW stim ON patch:
    stimOnset = mean(mwTrialTimes(:,2));
    stimOffset = mean(mwTrialTimes(:,3));
    ylims = get(gca, 'ylim');
    v = [stimOnset ylims(1); stimOffset ylims(1);...
        stimOffset ylims(2); stimOnset ylims(2)];
    f = [1 2 3 4];
    handles.stimplot.mwepochs = patch('Faces',f,'Vertices',v,'FaceColor','black', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    hold on;
    
end


handles.ax3.Box = 'off';
handles.ax3.TickDir = 'out';
hold off;
%handles.ax3.UserData.clickedTrial = 1;

% handles.ax3.PickableParts = 'all';
% handles.ax3.HitTest = 'on';
% set(handles.ax3, 'ButtonDownFcn', @ax3_ButtonDownFcn);

%end

% 
% axes(handles.ax4);
% handles.timecourse = plot(; %, handles.ax2);
% colormap(handles.ax2, hot);
% caxis([min(displayMap(:)), max(displayMap(:))]);
% colorbar();
% handles.retinolegend.Visible = 'off';
% 
% 
% refPos = handles.ax1.Position;
% ax2Pos = handles.ax2.Position;
% handles.ax2.Position(3:4) = [refPos(3:4)];
%title(currRunName);
%colorbar();
%
end

% function selectTrace(hObject,~)
% 
% %trialstruct.slice(selectedSlice).info.(selectedStim){trial}.tiffNum
% trialstruct = getapp
% fprintf('Selected trial: %i\n', clickedTrial);
% end

