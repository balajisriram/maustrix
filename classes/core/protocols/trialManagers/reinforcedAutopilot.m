classdef reinforcedAutopilot<trialManager
    
    properties
        percentCorrectionTrials=0;
    end
    
    methods
        function t=reinforcedAutopilot(percentCorrectionTrials, soundManager, rewardManager, eyeController, frameDropCorner, dropFrames, ...
                displayMethod, requestPort, saveDetailedFrameDrops, delayManager, responseWindowMs, showText)
            % REINFORCEDAUTOPILOT  class constructor.
            % t=reinforcedAutopilot(percentCorrectionTrials,soundManager,...
            %      rewardManager,[eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %	   [delayManager],[responseWindowMs],[showText])
            %
            % Used for the whiteNoise, bipartiteField, fullField, and gratings stims, which don't require any response to go through the trial
            % basically just play through the stims, with no sounds, no correction trials

            d=sprintf('reinforcedAutopilot');
            t=t@trialManager(soundManager,rewardManager,eyeController,d,frameDropCorner,dropFrames,displayMethod,requestPort,saveDetailedFrameDrops,delayManager,responseWindowMs,showText);

 
            % percentCorrectionTrials
            if percentCorrectionTrials>=0 && percentCorrectionTrials<=1
                t.percentCorrectionTrials=percentCorrectionTrials;
            else
                error('1 >= percentCorrectionTrials >= 0')
            end

        end
        
        function rewardValves = forceRewards(tm,rewardValves)
            %forceRewards only sets if the valves are set to [0 0 0]

            if ~any(rewardValves)
                rewardValves = [0 1 0];
            end

        end
        
        function out = getPercentCorrectionTrials(tm)
            out = tm.percentCorrectionTrials;
        end
        
        function out=getResponsePorts(trialManager,totalPorts)

            out=setdiff(1:totalPorts,getRequestPorts(trialManager,totalPorts));
        end

        function out=stationOKForTrialManager(t,s)
            if isa(s,'station')
                out = getNumPorts(s)>=3;
            else
                error('need a station object')
            end
        end
        
        function [tm, trialDetails, result, spec, rewardSizeULorMS, requestRewardSizeULorMS, ...
    msPuff, msRewardSound, msPenalty, msPenaltySound, floatprecision, textures, destRect,updateRM] = ...
    updateTrialState(tm, sm, result, spec, ports, lastPorts, ...
    targetPorts, requestPorts, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
    floatprecision, textures, destRect, ...
    requestRewardDone, punishResponses,compiledRecords,subject)

            rewardSizeULorMS=0;
            requestRewardSizeULorMS = 0;
            msPuff=0;
            msRewardSound=0;
            msPenalty=0;
            msPenaltySound=0;
            updateRM = false;
            phaseType = getPhaseType(spec);
            framesUntilTransition=getFramesUntilTransition(spec);
            % now, if phaseType is 'reinforced', use correct and call updateRewards(tm,correct)
            % this trialManager-specific method should do the following:
            % - call calcReinforcement(RM)
            % - update msRewardOwed/msAirpuffOwed as necessary (depending on correctness and TM class)
            % - call errorStim(SM), correctStim(SM) as necessary and fill in the stimSpec's stimulus field

            if ~isempty(phaseType) && strcmp(phaseType,'reinforced') && framesInPhase==0
                % we only check to do rewards on the first frame of the 'reinforced' phase
                [rm, rewardSizeULorMS, ~, msPenalty, ~, msRewardSound, msPenaltySound, updateRM] =...
                    calcReinforcement(getReinforcementManager(tm),trialRecords,compiledRecords, []);
                if updateRM
                    tm.reinforcementManager = rm;
                end

                msPuff=0;
                msPenalty=0;
                msPenaltySound=0;

                if window>0
                    if isempty(framesUntilTransition)
                        framesUntilTransition = ceil((rewardSizeULorMS/1000)/ifi);
                    end
                    numCorrectFrames=ceil((rewardSizeULorMS/1000)/ifi);
                    if framesUntilTransition == 0
                        framesUntilTransition = 1; % preset this because 0 implied infinity
                    end
                elseif strcmp(getDisplayMethod(tm),'LED')
                    if isempty(framesUntilTransition)
                        framesUntilTransition=ceil(getHz(spec)*rewardSizeULorMS/1000);
                    else
                        framesUntilTransition
                        error('LED needs framesUntilTransition empty for reward')
                    end
                    numCorrectFrames=ceil(getHz(spec)*rewardSizeULorMS/1000);
                else
                    error('huh?')
                end

                spec=setFramesUntilTransition(spec,framesUntilTransition);
                [cStim, correctScale] = correctStim(sm,numCorrectFrames);
                spec=setScaleFactor(spec,correctScale);

                strategy='noCache';
                if window>0
                    [floatprecision cStim] = determineColorPrecision(tm, cStim, strategy);
                    textures = cacheTextures(tm,strategy,cStim,window,floatprecision);
                    destRect = determineDestRect(tm, window, correctScale, cStim, strategy);
                elseif strcmp(getDisplayMethod(tm),'LED')
                    floatprecision=[];
                else
                    error('huh?')
                end
                spec=setStim(spec,cStim);


            end % end reward handling

            if strcmp(getPhaseLabel(spec),'intertrial luminance') && ischar(result) && strcmp(result,'timeout')
                % this should be the only allowable result in autopilot
                result='timedout'; % so we continue to next trial
            end

            trialDetails.correct=true;

            end  % end function
        
    end
    
end

