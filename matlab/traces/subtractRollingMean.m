function [trace_y, DC_y] = subtractRollingMean(currTrace, winsz)
    % if cutEnd==1
    %     tmp0 = currTrace(1:crop);
    % else
    ind = 1:length(currTrace);
    ix = ~isnan(currTrace);
    if sum(ix) ~= length(currTrace)
        tmp0 = interp1(ind(ix),currTrace(ix),ind,'linear').';
        % transpose so that in output, cols are still rois and rows are
        % still frames
    else
        tmp0 = currTrace;
    end
    %tmp0 = currTrace;
    % end
    if size(tmp0,1) > size(tmp0,2)
        tmp1 = padarray(tmp0,[winsz 0],tmp0(1),'pre');
        tmp1 = padarray(tmp1,[winsz 0],tmp1(end),'post');
        rollingAvg=nanconv(tmp1,fspecial('average',[winsz 1]),'same');%average
    else
        tmp1 = padarray(tmp0,[0 winsz],tmp0(1),'pre');
        tmp1 = padarray(tmp1,[0 winsz],tmp1(end),'post');
        rollingAvg=nanconv(tmp1,fspecial('average',[1 winsz]),'same');%average
    end
    rollingAvg=rollingAvg(winsz+1:end-winsz);
    trace_y = tmp0 - rollingAvg;
    
    DC_y = mean(tmp0);
    
end