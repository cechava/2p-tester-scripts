function S = get_si_info(sourceDir, acquisitionName)
        
        siMetaStruct = struct();
        
        siMetaName = sprintf('%s.mat', acquisitionName);
        meta = load(fullfile(sourceDir, siMetaName));
        
        nTiffs = length(meta.(acquisitionName).metaDataSI);
        
        for fidx=1:nTiffs
            currMeta = meta.(acquisitionName).metaDataSI{fidx};
            
            % Sort Parsed files into separate directories if needed:
            nChannels = length(currMeta.SI.hChannels.channelSave);            
            nVolumes = currMeta.SI.hFastZ.numVolumes;
            nSlices = currMeta.SI.hFastZ.numFramesPerVolume;
            nDiscard = currMeta.SI.hFastZ.numDiscardFlybackFrames;
            nFramesPerVolume = nSlices + nDiscard;
            nTotalFrames = nFramesPerVolume * nVolumes;

            siFrameTimes = currMeta.frameTimestamps_sec(1:2:end);
            siFrameRate = currMeta.SI.hRoiManager.scanFrameRate;
            siVolumeRate = currMeta.SI.hRoiManager.scanVolumeRate;

            frameWidth = currMeta.SI.hRoiManager.pixelsPerLine;
            slowMultiplier = currMeta.SI.hRoiManager.scanAngleMultiplierSlow;
            linesPerFrame = currMeta.SI.hRoiManager.linesPerFrame;
            frameHeight = linesPerFrame/slowMultiplier;

            motionRefNum = meta.(acquisitionName).motionRefMovNum;
            motionRefPath = meta.(acquisitionName).Movies{motionRefNum};
            
            
            siMetaStruct.file(fidx).nChannels = nChannels;
            siMetaStruct.file(fidx).nVolumes = nVolumes;
            siMetaStruct.file(fidx).nSlices = nSlices;
            siMetaStruct.file(fidx).nDiscard = nDiscard;
            siMetaStruct.file(fidx).nFramesPerVolume = nFramesPerVolume;
            siMetaStruct.file(fidx).nTotalFrames = nTotalFrames;
            siMetaStruct.file(fidx).siFrameTimes = siFrameTimes;
            siMetaStruct.file(fidx).siVolumeRate = siVolumeRate;
            siMetaStruct.file(fidx).frameWidth = frameWidth;
            siMetaStruct.file(fidx).slowMultiplier = slowMultiplier;
            siMetaStruct.file(fidx).linesPerFrame = linesPerFrame;
            siMetaStruct.file(fidx).frameHeight = frameHeight;
            siMetaStruct.file(fidx).motionRefNum = motionRefNum;
            siMetaStruct.file(fidx).motionRefPath = motionRefPath;
            
            siMetaStruct.file(fidx).rawTiffPath = meta.(acquisitionName).Movies{fidx};
            %siMetaStruct.file(fidx) = sistruct;
            
        end
        S.acquisitionName = acquisitionName;
        S.nTiffs = nTiffs;
        S.nChannels = nChannels;
        S.SI = siMetaStruct;

end