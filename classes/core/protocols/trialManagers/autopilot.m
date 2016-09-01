classdef autopilot<trialManager
    

    
    methods
        function t=autopilot(soundManager, rewardManager, eyeController, frameDropCorner, dropFrames, ...
                displayMethod, requestPort, saveDetailedFrameDrops, delayManager, responseWindowMs, showText)
            % AUTOPILOT  class constructor.
            % t=autopilot(percentCorrectionTrials,soundManager,...
            %      rewardManager,[eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %	   [delayManager],[responseWindowMs],[showText])
            %
            % Used for the whiteNoise, bipartiteField, fullField, and gratings stims, which don't require any response to go through the trial
            % basically just play through the stims, with no sounds, no correction trials
            
            % requestPorts
            assert(ismember(requestPort,{'none'}),'autopilot:autopilot:incompatibleValue','requestPort has to be ''none''');
            d=sprintf('autopilot');
            t=t@trialManager(soundManager,rewardManager,eyeController,d,frameDropCorner,dropFrames,displayMethod,requestPort,saveDetailedFrameDrops,delayManager,responseWindowMs,showText);
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
                msPuff, msRewardSound, msPenalty, msPenaltySound, floatprecision, textures, destRect, updateRM] = ...
                updateTrialState(tm, sm, subject, result, spec, ports, lastPorts, ...
                targetPorts, requestPorts, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
                floatprecision, textures, destRect, requestRewardDone, punishResponses,compiledRecords)
            % autopilot updateTrialState does nothing!
            
            rewardSizeULorMS=0;
            requestRewardSizeULorMS=0;
            msPuff=0;
            msRewardSound=0;
            msPenalty=0;
            msPenaltySound=0;
            updateRM = false;

            trialDetails=[];
            if strcmp(getPhaseLabel(spec),'intertrial luminance') && ischar(result) && strcmp(result,'timeout')
                % this should be the only allowable result in autopilot
                result='timedout'; % so we continue to next trial
            end
        end  % end function

        
    end
    
    methods(Static)
        
        function [targetPorts, distractorPorts, details]=assignPorts(details,~,responsePorts)
            temp = [1,3];
            x = randperm(length(temp));
            targetPorts=temp(x(1));
            distractorPorts=setdiff(responsePorts,temp);
        end
    end
    
end

