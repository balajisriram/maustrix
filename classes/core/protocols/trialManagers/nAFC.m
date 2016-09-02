classdef nAFC<trialManager
    
    properties
        percentCorrectionTrials
    end
    
    methods
        function t=nAFC(sndMgr, reinfMgr, delayManager, frameDropCorner, dropFrames, requestPort, saveDetailedFrameDrops, customDescription, responseWindowMs, showText, percentCorrTrials)
            % NAFC  class constructor.
            % t=nAFC(soundManager,percentCorrectionTrials,rewardManager,
            %         [eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %		  [delayManager],[responseWindowMs],[showText])
            t=t@trialManager(sndMgr,reinfMgr,delayManager, frameDropCorner,dropFrames,requestPort,saveDetailedFrameDrops, customDescription,responseWindowMs,showText);
            
            assert(isscalar(percentCorrTrials)&&(percentCorrTrials>=0)&&(percentCorrTrials<1),'nAFC:incorrectValue','percentCorrTrials (value:[%s] should a scalar >0 and <1',num2str(percentCorrTrials));
            t.percentCorrectionTrials = percentCorrTrials;
        end
        
        function out=getResponsePorts(trialManager,totalPorts)
            
            out=setdiff(1:totalPorts,getRequestPorts(trialManager,totalPorts)); % old: response ports are all non-request ports
            % 5/4/09 - what if we want nAFC L/R target/distractor, but no request port (using delayManager instead)
            % responsePorts then still needs to only be L/R, not all ports (since request ports is empty)
            
            enableCenterPortResponseWhenNoRequestPort=false; %nAFC removes the center port
            if ~enableCenterPortResponseWhenNoRequestPort
                if isempty(getRequestPorts(trialManager,totalPorts)) % removes center port if no requestPort defined
                    out(ceil(length(out)/2))=[];
                end
            end
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
            try
            [tm, possibleTimeout, result, ~, ~, requestRewardSizeULorMS, ~, ~, ~, ~, ~, ~, ~, updateRM1] = ...
                updateTrialState@trialManager(tm, sm, subject, result, spec, ports, lastPorts, ...
                targetPorts, requestPorts, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
                floatprecision, textures, destRect, requestRewardDone, punishResponses,compiledRecords);
            catch % #### need to remove
                sca;
                keyboard
            end

            if isempty(possibleTimeout)
                if ~isempty(result) && ~ischar(result) && isempty(correct) && strcmp(spec.phaseLabel,'reinforcement')
                    resp=find(result);
                    if length(resp)==1
                        correct = ismember(resp,targetPorts);
                        if punishResponses % this means we got a response, but we want to punish, not reward
                            correct=0; % we could only get here if we got a response (not by request or anything else), so it should always be correct=0
                        end
                        result = 'nominal';
                    else
                        correct = 0;
                        result = 'multiple ports';
                    end
                end
            else
                correct=possibleTimeout.correct;
            end
            
            % ========================================================
            phaseType = spec.phaseType;
            framesUntilTransition=spec.framesUntilTransition;
            % now, if phaseType is 'reinforced', use correct and call updateRewards(tm,correct)
            % this trialManager-specific method should do the following:
            % - call calcReinforcement(RM)
            % - update msRewardOwed/msAirpuffOwed as necessary (depending on correctness and TM class)
            % - call errorStim(SM), correctStim(SM) as necessary and fill in the stimSpec's stimulus field
            updateRM2 = false;
            if ~isempty(phaseType) && strcmp(phaseType,'reinforced') && ~isempty(correct) && framesInPhase==0
                
                % we only check to do rewards on the first frame of the 'reinforced' phase
                
                [rm, rewardSizeULorMS, ~, msPenalty, ~, msRewardSound, msPenaltySound, updateRM2] =...
                    calcReinforcement(tm.reinforcementManager,subject,trialRecords,compiledRecords);
                if updateRM2
                    tm.reinforcementManager = rm;
                end
                
                if correct
                    msPuff=0;
                    msPenalty=0;
                    msPenaltySound=0;
                    
                    if isempty(framesUntilTransition)
                        framesUntilTransition = ceil((rewardSizeULorMS/1000)/ifi);
                    end
                    numCorrectFrames=ceil((rewardSizeULorMS/1000)/ifi);
                    
                    spec.framesUntilTransition=framesUntilTransition;
                    [cStim, correctScale] = correctStim(sm,numCorrectFrames);
                    spec.scaleFactor = correctScale;
                    strategy='textureCache';
                    [floatprecision, cStim] = tm.determineColorPrecision(cStim, strategy);
                    textures = tm.cacheTextures(strategy,cStim,window,floatprecision);
                    destRect = tm.determineDestRect(window, correctScale, cStim, strategy);
                    
                    spec=setStim(spec,cStim);
                else
                    rewardSizeULorMS=0;
                    msRewardSound=0;
                    msPuff=0; % for now, we don't want airpuffs to be automatic punishment, right?
                    
                    if isempty(framesUntilTransition)
                        framesUntilTransition = ceil((msPenalty/1000)/ifi);
                    end
                    numErrorFrames=ceil((msPenalty/1000)/ifi);
                    
                    spec.framesUntilTransition=framesUntilTransition;
                    [eStim, errorScale] = errorStim(sm,numErrorFrames);
                    spec.scaleFactor=errorScale;
                    strategy='textureCache';
                    [floatprecision, eStim] = tm.determineColorPrecision(eStim, strategy);
                    textures = tm.cacheTextures(strategy,eStim,window,floatprecision);
                    destRect=Screen('Rect',window);
                    spec=setStim(spec,eStim);
                end
                
            end % end reward handling
            
            trialDetails.correct=correct;
            updateRM = updateRM1 || updateRM2;

        end  % end function
        
    end
    
    methods (Static)
        function out = checkPorts(targetPorts,distractorPorts)
            
            if isempty(targetPorts) && isempty(distractorPorts)
                error('targetPorts and distractorPorts cannot both be empty in nAFC');
            end
            out=true;
        end % end function
        
        function [targetPorts, distractorPorts, details]=assignPorts(details,lastTrialRec,responsePorts)
            % figure out if this is a correction trial
            lastResult=[];
            lastCorrect=[];
            lastWasCorrection=0;
            
            if ~isempty(lastTrialRec) % if there were previous trials
                try
                    lastResult=find(lastTrialRec.result);
                catch
                    lastResult=[];
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
                
                if length(lastResult)>1
                    lastResult=lastResult(1);
                end
            end
            
            % determine correct port
            if ~isempty(lastCorrect) && ~isempty(lastResult) && ~lastCorrect && length(lastTrialRec.targetPorts)==1 && (lastWasCorrection || rand<details.pctCorrectionTrials)
                details.correctionTrial=1;
                %'correction trial!'
                targetPorts=lastTrialRec.targetPorts; % same ports are correct
            else
                details.correctionTrial=0;
                targetPorts=responsePorts(ceil(rand*length(responsePorts))); %choose random response port to be correct answer
            end
            distractorPorts=setdiff(responsePorts,targetPorts);
            
            
        end
        
        function out=stationOKForTrialManager(s)
            if isa(s,'station')
                out = s.numPorts>=3;
            else
                error('need a station object')
            end
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
            
            addedPostDiscrimPhases=0;
            which = strcmp('postDiscrimStim',stimNames);
            if ~isempty(stimParams{which})
                addedPostDiscrimPhases=addedPostDiscrimPhases+length(stimParams{which});
            end
            
            framesUntilOnset=floor(tm.delayManager.calcAutoRequest()*hz/1000); % autorequest is in ms, convert to frames
            responseWindow=floor(tm.responseWindowMs*hz/1000);
            
            % figure out the indices
            preRequestIndex = 1;last = 1;
            discrimIndex = last+1;last = last+1;
            if addedPostDiscrimPhases
                postDiscrimIndices = last+1:last+1+addedPostDiscrimPhases;
                last = last+addedPostDiscrimPhases;
            end
            reinforcementIndex = last+1; last = last+1;
            itlIndex = last+1;
            
            
            % now generate our stimSpecs
            startingStimSpecInd=1;
            i=1;
            
            doNothing = [];
            
            % preRequest
            assert(~isempty(requestPorts) || ~isempty(framesUntilOnset),'nAFC:createStimSpecsFromParams:incompatibleInputs','requestPorts or framesUntilOnset should be non-empty');
            which = strcmp('preRequestStim',stimNames);
            preRequestStim = stimParams{which};
            if preRequestStim.punishResponses
                criterion={doNothing,discrimIndex,requestPorts,discrimIndex,[targetPorts distractorPorts],reinforcementIndex};
            else
                criterion={doNothing,discrimIndex,requestPorts,discrimIndex};
            end
            stimSpecs{i} = stimSpec(preRequestStim.stimulus,criterion,preRequestStim.stimType,preRequestStim.startFrame,...
                framesUntilOnset,preRequestStim.autoTrigger,preRequestStim.scaleFactor,false,hz,'pre-request','pre-request',...
                preRequestStim.punishResponses,false,[],preRequestStim.ledON);
            i=i+1;
            
            % discrim
            criterion={doNothing,i+1,[targetPorts distractorPorts],reinforcementIndex};
            % we dont know if 'i+1' is postDiscrim or reinforcement right now...but if you respond, go to reinforcement
            which = strcmp('discrimStim',stimNames);
            discrimStim = stimParams{which};
            framesUntilTimeoutDiscrim=discrimStim.framesUntilTimeout;
            stimSpecs{i} = stimSpec(discrimStim.stimulus,criterion,discrimStim.stimType,discrimStim.startFrame,...
                framesUntilTimeoutDiscrim,discrimStim.autoTrigger,discrimStim.scaleFactor,false,hz,'discrim','discrim',...
                false,true,indexPulses,discrimStim.ledON); % do not punish responses here
            i=i+1;
            % #### what is the purpose of responseWindow in trialManager????
            
            % optional postDiscrim Phase
            if addedPostDiscrimPhases
                assert(~isinf(framesUntilTimeoutDiscrim),'nAFC:incompatbleParamValue','you are adding post-discrim phases while discrim doesn''t timeout');
                which = strcmp('postDiscrimStim',stimNames);
                postDiscrimStim = stimParams{which};
                for k = 1:length(postDiscrimStim) % loop through the post discrim stims
                    criterion={doNothing,i+1,[targetPorts distractorPorts],reinforcementIndex}; % any response in any part takes you to the reinf
                    
                    assert(~postDiscrimStim(k).punishResponses,'nAFC:createStimSpecsFromParams:incorrectValues','cannot punish responses in postDiscrimStim');
                    if length(postDiscrimStim)>1
                        postDiscrimName = sprintf('post-discrim%d',k);
                    else
                        postDiscrimName = 'post-discrim';
                    end
                    stimSpecs{i} = stimSpec(postDiscrimStim(k).stimulus,criterion,postDiscrimStim(k).stimType,postDiscrimStim(k).startFrame,...
                        postDiscrimStim(k).framesUntilTimeout,postDiscrimStim(k).autoTrigger,postDiscrimStim(k).scaleFactor,false,hz,'post-discrim',postDiscrimName,...
                        postDiscrimStim(k).punishResponses,false,[],postDiscrimStim(k).ledON);
                    i=i+1;
                end
            end

            % required reinforcement phase
            criterion={[],i+1};
            stimSpecs{i} = stimSpec([],criterion,'cache',0,[],[],0,false,hz,'reinforced','reinforcement',false,false,[],false); % do not punish responses here, and LED is hardcoded to false (bad idea in general)
            i=i+1;
            
            % required final ITL phase
            which = strcmp('interTrialStim',stimNames);
            interTrialStim = stimParams{which};
            criterion={[],i+1};
            stimSpecs{i} = stimSpec(interTrialStim.interTrialLuminance,criterion,'cache',0,interTrialStim.duration,[],0,true,hz,'itl','intertrial luminance',false,false,[],false); % do not punish responses here. itl has LED hardcoded to false
            i=i+1;
        end
    end
end

