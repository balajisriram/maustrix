classdef goNoGo<trialManager
    
    properties
        percentCorrectionTrials=0;
        responseLockoutMs=[];
        fractionGo = 0.5;
        rewardCorrectRejection = false;
        punishIncorrectRejection = false;
    end
    
    properties (Constant = true)
        responsePorts = 2;
    end
    
    methods
        function t=goNoGo(sndMgr, reinfMgr, delMgr, frameDropCorner, dropFrames, requestPort, saveDetailedFrameDrops, ...
                responseWindowMs, description, showText,fractionGo,percentCorrectionTrials,responseLockoutMs,...
                rewardCorrectRejection,punishIncorrectRejection)
            % goNoGo  class constructor.
            % t=goNoGo(soundManager,percentCorrectionTrials,responseLockoutMs,rewardManager,
            %         [eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %		  [delayFunction],[responseWindowMs],[showText])
            
            t=t@trialManager(sndMgr,reinfMgr,delMgr,frameDropCorner,dropFrames,requestPort,saveDetailedFrameDrops,responseWindowMs,description,showText);
            
            assert((fractionGo>=0 && fractionGo<=1),'goNoGo:goNoGo:improperValue','fractionGo should be >=0 and <=1');
            t.fractionGo=fractionGo;
            
            assert((percentCorrectionTrials>=0 && percentCorrectionTrials<=1),'goNoGo:goNoGo:improperValue','percentCorrectionTrials should be >=0 and <=1');
            t.percentCorrectionTrials=percentCorrectionTrials;
            
            assert(responseLockoutMs>=0 ,'goNoGo:goNoGo:improperValue','responseLockoutMs should be >=0');
            t.responseLockoutMs=responseLockoutMs;
            
            assert(islogical(rewardCorrectRejection) ,'goNoGo:goNoGo:improperValue','rewardCorrectRejection should be logical');
            t.rewardCorrectRejection=rewardCorrectRejection;
            
            assert(islogical(punishIncorrectRejection) ,'goNoGo:goNoGo:improperValue','punishIncorrectRejection should be logical');
            t.punishIncorrectRejection=punishIncorrectRejection;
        end
        
        function out=stationOKForTrialManager(t,s)
            out = true; % #### need to come up wirth rules to determine if gng stations are different
        end
        
        function [tm, trialDetails, result, spec, rewardSizeULorMS, requestRewardSizeULorMS, ...
                msPuff, msRewardSound, msPenalty, msPenaltySound, floatprecision, textures, destRect,updateRM] = ...
                updateTrialState(tm, sm, subject, result, spec, ports, lastPorts, ...
                targetPorts, requestPorts, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
                floatprecision, textures, destRect, requestRewardDone, punishResponses,compiledRecords)
            % This function is a tm-specific method to update trial state before every flip.
            % Things done here include:
            %   - set trialRecords.correct and trialRecords.result as necessary
            %   - call RM's calcReinforcement as necessary
            %   - update the stimSpec as necessary (with correctStim() and errorStim())
            %   - update the TM's RM if neceesary
                    
            rewardSizeULorMS=0;
            msPuff=0;
            msRewardSound=0;
            msPenalty=0;
            msPenaltySound=0;
            updateRM = false;
            
            if isfield(trialRecords(end),'trialDetails') && isfield(trialRecords(end).trialDetails,'correct')
                correct=trialRecords(end).trialDetails.correct;
            else
                correct=[];
            end
            
            % ========================================================
            % if the result is a port vector, and we have not yet assigned correct, then the current result must be the trial response
            % because phased trial logic returns the 'result' from previous phase only if it matches a target/distractor
            % 3/13/09 - we rely on nAFC's phaseify to correctly assign stimSpec.phaseLabel to identify where to check for correctness
            % call parent's updateTrialState() to do the request reward handling and check for 'timeout' flag
            [tm, possibleTimeout, result, ~, ~, requestRewardSizeULorMS, ~, ~, ~, ~, ~, ~, ~, updateRM1] = ...
                updateTrialState@trialManager(tm,sm, subject, result, spec, ports, lastPorts, ...
                targetPorts, requestPorts, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
                floatprecision, textures, destRect, requestRewardDone, punishResponses,compiledRecords);
            targetStim = trialRecords(end).stimDetails.targetStim;
            if ~isempty(result) && ~ischar(result) && isempty(correct) && strcmp(spec.phaseLabel,'reinforcement')
                resp=find(result);
                if length(resp)==1
                    correct = strcmp(targetStim ,'go');
                    if punishResponses % this means we got a response, but we want to punish, not reward
                        correct=0; % we could only get here if we got a response (not by request or anything else), so it should always be correct=0
                    end
                    result = 'nominal';
                else
                    correct = 0;
                    result = 'multiple ports';
                end
            elseif ischar(result) && strcmp(result,'timedout')
                correct = strcmp(targetStim ,'noGo');
            end
            
            
            % ========================================================
            phaseType = spec.phaseType;
            framesUntilTransition=spec.framesUntilTransition;
            % now, if phaseType is 'reinforced', use correct and call updateRewards(tm,correct)
            % this trialManager-specific method should do the following:
            % - call calcReinforcement(RM)
            % - update msRewardOwed/msAirpuffOwed as necessary (depending on correctness and TM class)
            % - call errorStim(SM), correctStim(SM) as necessary and fill in the stimSpec's stimulus field
            updateRM2=false;
            if ~isempty(phaseType) && strcmp(phaseType,'reinforced') && ~isempty(correct) && framesInPhase==0
                % we only check to do rewards on the first frame of the 'reinforced' phase
                [rm, rewardSizeULorMS, garbage, msPenalty, msPuff, msRewardSound, msPenaltySound, updateRM2] =...
                    calcReinforcement(tm.reinforcementManager,subject,trialRecords,compiledRecords);
                if updateRM2
                    tm.reinforcementManager = rm;
                end
                
                if correct
                    msPuff=0;
                    msPenalty=0;
                    msPenaltySound=0;
                    if strcmp(targetStim,'noGo')
                        rewardSizeULorMS = rewardSizeULorMS*double(tm.rewardCorrectRejection);
                    end
                    if isempty(framesUntilTransition)
                        framesUntilTransition = ceil((rewardSizeULorMS/1000)/ifi);
                    end
                    numCorrectFrames=ceil((rewardSizeULorMS/1000)/ifi);
                    
                    spec.framesUntilTransition=framesUntilTransition;
                    [cStim, correctScale] = sm.correctStim(numCorrectFrames);
                    spec.scaleFactor=correctScale;
                    strategy='textureCache';
                    [floatprecision, cStim] = tm.determineColorPrecision(cStim, strategy);
                    textures = tm.cacheTextures(strategy,cStim,window,floatprecision);
                    destRect = tm.determineDestRect(window, correctScale, cStim, strategy);
                    
                    spec=setStim(spec,cStim);
                else
                    rewardSizeULorMS=0;
                    msRewardSound=0;
                    msPuff=0; % for now, we don't want airpuffs to be automatic punishment, right?
                    if strcmp(targetStim,'go')
                        msPenalty = msPenalty*double(tm.punishIncorrectRejection);
                    end
                    if isempty(framesUntilTransition)
                        framesUntilTransition = ceil((msPenalty/1000)/ifi);
                    end
                    numErrorFrames=ceil((msPenalty/1000)/ifi);
                    
                    
                    spec.framesUntilTransition=framesUntilTransition;
                    [eStim, errorScale] = sm.errorStim(numErrorFrames);
                    spec.scaleFactor = errorScale;
                    strategy='textureCache';
                    [floatprecision, eStim] = tm.determineColorPrecision(eStim, strategy);
                    textures = tm.cacheTextures(strategy,eStim,window,floatprecision);
                    destRect=Screen('Rect',window);
                    spec=setStim(spec,eStim);
                end
                
            end % end reward handling
            
            trialDetails.correct=correct;
            updateRM = updateRM2;
            
        end  % end function
        
        function [targetStim, details]=assignStim(tm,details,lastTrialRec)
            lastResult=[];
            lastCorrect=[];
            lastWasCorrection=0;
            
            if ~isempty(lastTrialRec) % if there were previous trials
                if ~ischar(lastTrialRec.result)
                    try
                        lastResult=find(lastTrialRec.result);
                    catch
                        lastResult=[];
                    end
                    if length(lastResult)>1
                        lastResult=lastResult(1);
                    end
                else
                    lastResult=lastTrialRec.result;
                end
                if isfield(lastTrialRec,'trialDetails') && isfield(lastTrialRec.trialDetails,'correct')
                    lastCorrect=lastTrialRec.trialDetails.correct;
                else
                    try
                        lastCorrect=lastTrialRec.correct;
                    catch
                        lastCorrect=[];
                    end
                end
                
                if any(strcmp(fields(lastTrialRec.stimDetails),'correctionTrial'))
                    lastWasCorrection=lastTrialRec.stimDetails.correctionTrial;
                else
                    lastWasCorrection=0;
                end
            end
            
            % determine correct port
%             if ~isempty(lastCorrect) && ~isempty(lastResult) && ~lastCorrect && (lastWasCorrection || rand<details.pctCorrectionTrials)
%                 details.correctionTrial=1;
%                 %correction trials are a very strange brew for goNoGo... i
%                 %doubt its what we want...
%                 
%                 %'correction trial!'
%                 targetStim=lastTrialRec.stimDetails.targetStim; % same ports are correct
%                 details.targetStim = targetStim;
%             else
                details.correctionTrial=0;
                if rand<tm.fractionGo
                    targetStim = 'go';
                    details.targetStim = 'go';
                else
                    targetStim = 'noGo';
                    details.targetStim = 'noGo';
                end
%             end            
        end
    end
    
    methods (Access = ?trialManager)
        function [stimSpecs, startingStimSpecInd] = createStimSpecsFromParams(tm,stimList,targetPorts,distractorPorts,requestPorts,hz,indexPulses)
            %	INPUTS:
            %		trialManager - the trialManager object (contains the delayManager and responseWindow params)
            %		stimList - cell array ::
            %             { 'stimName1', stimParam1;
            %               'stimName2', stimParams2;...}
            %		targetPorts - the target ports for this trial
            %		distractorPorts - the distractor ports for this trial
            %		requestPorts - the request ports for this trial
            %		hz - the refresh rate of the current trial
            %		indexPulses - something to do w/ indexPulses, apparently only during discrim phases
            %	OUTPUTS:
            %		stimSpecs, startingStimSpecInd
            
            % there are two ways to have no pre-request/pre-response phase:
            %	1) have calcstim return empty preRequestStim/preResponseStim structs to pass to this function!
            %	2) the trialManager's delayManager/responseWindow params are set so that the responseWindow starts at 0
            %		- NOTE that this cannot affect the preOnset phase (if you dont want a preOnset, you have to pass an empty out of calcstim)
            
            % should the stimSpecs we return be dependent on the trialManager class? - i think so...because autopilot does not have reinforcement, but for now nAFC/freeDrinks are the same...
            
            stimNames = stimList(:,1);
            stimParams = stimList(:,2);
            
            % nAFC con only have some stims.
            %  - preRequestStim(nonempty)
            %  - discrimStim(nonempty)
            %  - postDiscrimStim(can be empty)
            
            
            which = strcmp('preRequestStim',stimNames);
            validateattributes(stimParams{which},{'struct'},{'nonempty'});
            
            which = strcmp('discrimStim',stimNames);
            validateattributes(stimParams{which},{'struct'},{'nonempty'});
            
            which = strcmp('postDiscrimStim',stimNames);
            validateattributes(stimParams{which},{'struct'},{'nonempty'});

            framesUntilOnset=floor(tm.delayManager.calcAutoRequest()*hz/1000); % autorequest is in ms, convert to frames
            responseWindow=floor(tm.responseWindowMs*hz/1000);
            
            % figure out the indices
            preRequestIndex = 1;
            discrimIndex = 2;
            postDiscrimIndex = 3;
            reinforcementIndex = 4;
            itlIndex = 5;
            
            % now generate our stimSpecs
            startingStimSpecInd=1;
            i=1;
            
            doNothing = [];
            
            % preRequest
            assert(~isempty(framesUntilOnset),'goNoGo:createStimSpecsFromParams:incompatibleInputs','framesUntilOnset should be non-empty');
            which = strcmp('preRequestStim',stimNames);
            preRequestStim = stimParams{which};
            assert(preRequestStim.punishResponses,'goNoGo:createStimSpecsFromParams:incompatibleInputs','framesUntilOnset should be non-empty');
            criterion={doNothing,discrimIndex}; % preRequest responses are punished
            stimSpecs{i} = stimSpec(preRequestStim.stimulus,criterion,preRequestStim.stimType,preRequestStim.startFrame,...
                preRequestStim.framesUntilTimeout,preRequestStim.autoTrigger,preRequestStim.scaleFactor,false,hz,'pre-request','pre-request',...
                preRequestStim.punishResponses,false,[],preRequestStim.ledON, preRequestStim.soundPlayed);
            i=i+1;
            
            % discrim
            criterion={doNothing,postDiscrimIndex,targetPorts,reinforcementIndex};
            which = strcmp('discrimStim',stimNames);
            discrimStim = stimParams{which};
            framesUntilTimeoutDiscrim=discrimStim.framesUntilTimeout;
            stimSpecs{i} = stimSpec(discrimStim.stimulus,criterion,discrimStim.stimType,discrimStim.startFrame,...
                framesUntilTimeoutDiscrim,discrimStim.autoTrigger,discrimStim.scaleFactor,false,hz,'discrim','discrim',...
                false,true,indexPulses,discrimStim.ledON,discrimStim.soundPlayed); % do not punish responses here
            i=i+1;
            % #### what is the purpose of responseWindow in trialManager????
            
            % optional postDiscrim Phase
            which = strcmp('postDiscrimStim',stimNames);
            postDiscrimStim = stimParams{which};
            for k = 1:length(postDiscrimStim) % loop through the post discrim stims

                criterion={doNothing,i+1,targetPorts,reinforcementIndex}; % any response in any part takes you to the reinf
                
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

            % required reinforcement phase
            criterion={[],i+1};
            stimSpecs{i} = stimSpec([],criterion,'cache',0,[],[],0,false,hz,'reinforced','reinforcement',false,false,[],false,[]); % do not punish responses here, and LED is hardcoded to false (bad idea in general)
            i=i+1;
            
            % required final ITL phase
            which = strcmp('interTrialStim',stimNames);
            interTrialStim = stimParams{which};
            criterion={[],i+1};
            stimSpecs{i} = stimSpec(interTrialStim.interTrialLuminance,criterion,'cache',0,interTrialStim.duration,[],0,true,hz,'itl','intertrial luminance',false,false,[],false,[]); % do not punish responses here. itl has LED hardcoded to false
            i=i+1;
            

        end
    end
    
    methods (Static)
        function sm = makeStandardSoundManager()
            sm=soundManager({soundClip('correctSound','allOctaves',400,20000), ...
                soundClip('keepGoingSound','allOctaves',300,20000), ...
                soundClip('trySomethingElseSound','gaussianWhiteNoise'), ...
                soundClip('wrongSound','tritones',[300 400],20000),...
                soundClip('stimOnSound','allOctaves',350,20000),...
                soundClip('trialStartSound','allOctaves',200,20000)});
        end 
    end
end