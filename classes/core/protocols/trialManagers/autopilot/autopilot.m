classdef autopilot<trialManager
    

    
    methods
        function t=autopilot(sndMgr, reinfMgr, delayManager, frameDropCorner, dropFrames, requestPort, saveDetailedFrameDrops,...
                responseWindowMs, customDescription, showText)
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
            t=t@trialManager(sndMgr,reinfMgr,delayManager, frameDropCorner,dropFrames,requestPort,saveDetailedFrameDrops,...
                responseWindowMs,customDescription,showText);
            
        end
        
        function out=getResponsePorts(trialManager,totalPorts)

            out=setdiff(1:totalPorts,getRequestPorts(trialManager,totalPorts));
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
            msRewardSound=0; % #### this is an attempt at trying soundsToPlay
            msPenalty=0;
            msPenaltySound=0;
            updateRM = false;

            trialDetails=[];
            if strcmp(spec.phaseLabel,'intertrial luminance') && ischar(result) && strcmp(result,'timeout')
                % this should be the only allowable result in autopilot
                result='timedout'; % so we continue to next trial
            end
        end  % end function

        function [soundsToPlay, spec] = getSoundsToPlay(tm, ports, lastPorts, spec, phase, stepsInPhase,msRewardSound, msPenaltySound, ...
                targetOptions, distractorOptions, requestOptions, playRequestSoundLoop, trialDetails)
            % see doc in stimManager.calcStim.txt
            
            playLoopSounds={};
            playSoundSounds={};
            
            if ~isempty(spec.soundPlayed) && ~spec.soundAlreadyPlayed
                playSoundSounds{end+1} = spec.soundPlayed;
                spec.soundAlreadyPlayed = true;
            end           
            
            soundsToPlay = {playLoopSounds, playSoundSounds};
            
        end % end function
    end
    
    methods(Static)
        
        function [targetPorts, distractorPorts, details]=assignPorts(details,~,responsePorts)
            targetPorts=[];
            distractorPorts=[];
            details.targetPorts = [];
            details.distractorPorts = [];
        end
        
        function out=stationOKForTrialManager(~)
            out = true;
            % all stations should in theory be able to implement autopilot
        end
    end
    
    methods (Access = ?trialManager)
        function [stimSpecs, startingStimSpecInd] = createStimSpecsFromParams(tm,stimList,targetPorts,distractorPorts,requestPorts,hz,indexPulses)
            %	INPUTS:
            %		trialManager - the trialManager object (contains the delayManager and responseWindow params)
            %		stimList - cell array ::
            %             { 'stimName1', stimParam1;
            %               'stimName2', stimParams2;...}
            %		targetPorts - the target ports NEEDS TO BE []
            %		distractorPorts - the distractor ports NEEDS TO BE []
            %		requestPorts - the request ports NEEDS TO BE[]
            %		hz - the refresh rate of the current trial
            %		indexPulses - something to do w/ indexPulses, apparently only during discrim phases
            %	OUTPUTS:
            %		stimSpecs, startingStimSpecInd
            
            % there are two ways to have no pre-request/pre-response phase:
            %	1) have calcstim return empty preRequestStim/preResponseStim structs to pass to this function!
            %	2) the trialManager's delayManager/responseWindow params are set so that the responseWindow starts at 0
            %		- NOTE that this cannot affect the preOnset phase (if you dont want a preOnset, you have to pass an empty out of calcstim)
            
            stimNames = stimList(:,1);
            stimParams = stimList(:,2);
            
            % nAFC con only have some stims.
            %  - preDiscrimStim(can be empty, can be multiple)
            %  - discrimStim(nonempty, 1 nos.)
            %  - postDiscrimStim(can be empty, can be multiple)
            
            addedPreDicrimPhases = 0;
            which = strcmp('preDiscrimStim',stimNames);
            if ~isempty(stimParams(which))
                addedPreDicrimPhases = addedPreDicrimPhases+length(stimParams(which));
            end
            
            which = strcmp('discrimStim',stimNames);
            validateattributes(stimParams{which},{'struct'},{'nonempty'});
            
            addedPostDiscrimPhases=0;
            which = strcmp('postDiscrimStim',stimNames);
            if ~isempty(stimParams(which))
                addedPostDiscrimPhases=addedPostDiscrimPhases+length(stimParams(which));
            end
            
            % now generate our stimSpecs
            startingStimSpecInd=1;
            i=1;
            
            doNothing = [];
            
            % preDiscrim
            if addedPreDicrimPhases
                which = strcmp('preDiscrimStim',stimNames);
                preDiscrimStim = stimParams{which};
                for k = 1:length(preDiscrimStim) % loop through the pre discrim stims
                    criterion={doNothing,i+1};                    
                    if length(preDiscrimStim)>1
                        preDiscrimName = sprintf('pre-discrim%d',k);
                    else
                        preDiscrimName = 'pre-discrim';
                    end
                    stimSpecs{i} = stimSpec(preDiscrimStim(k).stimulus,criterion,preDiscrimStim(k).stimType,preDiscrimStim(k).startFrame,...
                        preDiscrimStim(k).framesUntilTimeout,preDiscrimStim(k).autoTrigger,preDiscrimStim(k).scaleFactor,false,hz,'pre-discrim',preDiscrimName,...
                        preDiscrimStim(k).punishResponses,false,[],preDiscrimStim(k).ledON,preDiscrimStim(k).soundPlayed);
                    i=i+1;
                end
            end
            
            % discrim
            criterion={doNothing,i+1};
            which = strcmp('discrimStim',stimNames);
            discrimStim = stimParams{which};
            framesUntilTimeoutDiscrim = discrimStim.framesUntilTimeout;
            soundPlayedDiscrim = {'keepGoingSound',50};
            stimSpecs{i} = stimSpec(discrimStim.stimulus,criterion,discrimStim.stimType,discrimStim.startFrame,...
                discrimStim.framesUntilTimeout,discrimStim.autoTrigger,discrimStim.scaleFactor,false,hz,'discrim','discrim',...
                false,true,indexPulses,discrimStim.ledON,soundPlayedDiscrim); % discrimSoundPlayed is preset
            i=i+1;
            
            % optional postDiscrim Phase
            if addedPostDiscrimPhases
                assert(~isinf(framesUntilTimeoutDiscrim),'autopilot:incompatibleParamValue','stimuli have to time out');
                which = strcmp('postDiscrimStim',stimNames);
                postDiscrimStim = stimParams{which};
                for k = 1:length(postDiscrimStim) % loop through the post discrim stims
                    criterion={doNothing,i+1}; % any response in any part takes you to the reinf
                    if length(postDiscrimStim)>1
                        postDiscrimName = sprintf('post-discrim%d',k);
                    else
                        postDiscrimName = 'post-discrim';
                    end
                    stimSpecs{i} = stimSpec(postDiscrimStim(k).stimulus,criterion,postDiscrimStim(k).stimType,postDiscrimStim(k).startFrame,...
                        postDiscrimStim(k).framesUntilTimeout,postDiscrimStim(k).autoTrigger,postDiscrimStim(k).scaleFactor,false,hz,'post-discrim',postDiscrimName,...
                        postDiscrimStim(k).punishResponses,false,[],postDiscrimStim(k).ledON,postDiscrimStim(k).soundPlayed);
                    i=i+1;
                end
            end
            
            % required final ITL phase
            which = strcmp('interTrialStim',stimNames);
            interTrialStim = stimParams{which};
            soundPlayedITL = {'correctSound',50};
            criterion={[],i+1};
            stimSpecs{i} = stimSpec(interTrialStim.interTrialLuminance,criterion,'cache',0,interTrialStim.duration,[],0,true,hz,'itl','intertrial luminance',false,false,[],false,soundPlayedITL); % do not punish responses here. itl has LED hardcoded to false
            i=i+1;

        end
    end
    
end