classdef nAFC<trialManager
    
    properties
        percentCorrectionTrials
    end
    
    methods
        function t=nAFC(sndMgr, reinfMgr, frameDropCorner, dropFrames, requestPort, saveDetailedFrameDrops, delayManager, responseWindowMs, showText, percentCorrTrials)
            % NAFC  class constructor.
            % t=nAFC(soundManager,percentCorrectionTrials,rewardManager,
            %         [eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %		  [delayManager],[responseWindowMs],[showText])
            t=t@trialManager(sndMgr,reinfMgr,frameDropCorner,dropFrames,requestPort,saveDetailedFrameDrops,delayManager,responseWindowMs,showText);
            
            assert(isscalar(percentCorrTrials)&&(percentCorrTrials>=0)&&(percentCorrTrials<1),'nAFC:incorrectValue','percentCorrTrials (value:[%s] should a scalar >0 and <1',num2str(percentCorrTrials));
            t.percentCorrectionTrials = percentCorrTrials;
        end
      
        function out = getPercentCorrectionTrials(tm)
            out = tm.percentCorrectionTrials;
        end

        function out=getRequestRewardSizeULorMS(trialManager)

            out=trialManager.requestRewardSizeULorMS;
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
        
        function out=stationOKForTrialManager(t,s)
            if isa(s,'station')
                out = s.numPorts>=3;
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
            [tm, possibleTimeout, result, ~, ~, requestRewardSizeULorMS,updateRM1] = ...
                updateTrialState@trialManager(tm, sm, result, spec, ports, lastPorts, ...
                targetPorts, requestPorts, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
                floatprecision, textures, destRect, ...
                requestRewardDone, punishResponses,compiledRecords,subject);

            if isempty(possibleTimeout)		
                if ~isempty(result) && ~ischar(result) && isempty(correct) && strcmp(getPhaseLabel(spec),'reinforcement')
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
            phaseType = getPhaseType(spec);
            framesUntilTransition=getFramesUntilTransition(spec);
            % now, if phaseType is 'reinforced', use correct and call updateRewards(tm,correct)
            % this trialManager-specific method should do the following:
            % - call calcReinforcement(RM)
            % - update msRewardOwed/msAirpuffOwed as necessary (depending on correctness and TM class)
            % - call errorStim(SM), correctStim(SM) as necessary and fill in the stimSpec's stimulus field
            updateRM2 = false;
            if ~isempty(phaseType) && strcmp(phaseType,'reinforced') && ~isempty(correct) && framesInPhase==0

                % we only check to do rewards on the first frame of the 'reinforced' phase

                [rm, rewardSizeULorMS, ~, msPenalty, ~, msRewardSound, msPenaltySound, updateRM2] =...
                    calcReinforcement(getReinforcementManager(tm),trialRecords,compiledRecords, []);
                if updateRM2
                    tm.reinforcementManager = rm;
                end

                if correct
                    msPuff=0;
                    msPenalty=0;
                    msPenaltySound=0;

                    if window>0
                        if isempty(framesUntilTransition)
                            framesUntilTransition = ceil((rewardSizeULorMS/1000)/ifi);
                        end
                        numCorrectFrames=ceil((rewardSizeULorMS/1000)/ifi);

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
                        [floatprecision, cStim] = determineColorPrecision(tm, cStim, strategy);
                        textures = cacheTextures(tm,strategy,cStim,window,floatprecision);
                        destRect = determineDestRect(tm, window, correctScale, cStim, strategy);
                    elseif strcmp(getDisplayMethod(tm),'LED')
                        floatprecision=[];
                    else
                        error('huh?')
                    end
                    spec=setStim(spec,cStim);
                else
                    rewardSizeULorMS=0;
                    msRewardSound=0;
                    msPuff=0; % for now, we don't want airpuffs to be automatic punishment, right?

                    if window>0
                        if isempty(framesUntilTransition)
                            framesUntilTransition = ceil((msPenalty/1000)/ifi);
                        end
                        numErrorFrames=ceil((msPenalty/1000)/ifi);

                    elseif strcmp(getDisplayMethod(tm),'LED')
                        if isempty(framesUntilTransition)
                            framesUntilTransition=ceil(getHz(spec)*msPenalty/1000);
                        else
                            framesUntilTransition
                            error('LED needs framesUntilTransition empty for reward')
                        end
                        numErrorFrames=ceil(getHz(spec)*msPenalty/1000);
                    else
                        error('huh?')
                    end
                    spec=setFramesUntilTransition(spec,framesUntilTransition);
                    [eStim, errorScale] = errorStim(sm,numErrorFrames);
                    spec=setScaleFactor(spec,errorScale);
                    strategy='noCache';
                    if window>0
                        [floatprecision, eStim] = determineColorPrecision(tm, eStim, strategy);
                        textures = cacheTextures(tm,strategy,eStim,window,floatprecision);
                        destRect=Screen('Rect',window);
                    elseif strcmp(getDisplayMethod(tm),'LED')
                        floatprecision=[];
                    else
                        error('huh?')
                    end
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
    end
    
    methods (Access = private)
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
                framesUntilOnset,preRequestStim.autoTrigger,preRequestStim.scaleFactor,0,hz,'pre-request','pre-request',...
                preRequestStim.punishResponses,false,[],preRequestStim.ledON);
            i=i+1;
            
            % discrim
            criterion={doNothing,i+1,[targetPorts distractorPorts],reinforcementIndex}; 
            % we dont know if 'i+1' is postDiscrim or reinforcement right now...but if you respond, go to reinforcement
            which = strcmp('discrimStim',stimNames);
            discrimStim = stimParams{which};
            framesUntilTimeoutDiscrim=discrimStim.framesUntilTimeout;           
            stimSpecs{i} = stimSpec(discrimStim.stimulus,criterion,discrimStim.stimType,discrimStim.startFrame,...
                framesUntilTimeoutDiscrim,discrimStim.autoTrigger,discrimStim.scaleFactor,0,hz,'discrim','discrim',...
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
                        postDiscrimStim(k).framesUntilTimeout,postDiscrimStim(k).autoTrigger,postDiscrimStim(k).scaleFactor,0,hz,'post-discrim',postDiscrimName,...
                        postDiscrimStim(k).punishResponses,false,[],postDiscrimStim(k).ledON);
                    i=i+1;
                end
            end
            
            % required reinforcement phase
            criterion={[],i+1};
            stimSpecs{i} = stimSpec([],criterion,'cache',0,[],[],0,0,hz,'reinforced','reinforcement',false,false,[],false); % do not punish responses here, and LED is hardcoded to false (bad idea in general)
            i=i+1;
            
            % required final ITL phase
            criterion={[],i+1};
            stimSpecs{i} = stimSpec(interTrialLuminance,criterion,'cache',0,interTrialStim.duration,[],0,1,hz,'itl','intertrial luminance',false,false,[],false); % do not punish responses here. itl has LED hardcoded to false
            i=i+1; 
        end
    end
end

