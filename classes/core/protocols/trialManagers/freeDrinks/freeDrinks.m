classdef freeDrinks<trialManager
    
    properties
        freeDrinkLikelihood=0;
    end
    
    methods
        function t=freeDrinks(soundManager, reinfMgr, delayManager, frameDropCorner, dropFrames, requestPort, saveDetailedFrameDrops, ...
            responseWindowMs, showText, freeDrinkLikelihood, allowRepeats)
            % FREEDRINKS  class constructor.
            % t=freeDrinks(soundManager,freeDrinkLikelihood,allowRepeats,reinforcementManager,
            %   [eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %	[delayManager],[responseWindowMs],[showText])
            
            
            description=sprintf('free drinks\n\t\t\tfreeDrinkLikelihood: %g',freeDrinkLikelihood);
            
            t=t@trialManager(soundManager,reinfMgr,delayManager,frameDropCorner,dropFrames,requestPort,saveDetailedFrameDrops,...
                responseWindowMs, description, showText);
            
            t.freeDrinkLikelihood=freeDrinkLikelihood;
            t.allowRepeats=allowRepeats;
            
        end
        
        function out = checkPorts(tm,targetPorts,distractorPorts)
            
            if isempty(targetPorts) && ~isempty(distractorPorts)
                error('cannot have distractor ports without target ports in freeDrinks');
            end
            
            out=true;
            
        end % end function
        
        function out=getResponsePorts(trialManager,totalPorts)
            out=setdiff(1:totalPorts,getRequestPorts(trialManager,totalPorts));
        end
        
        function out=stationOKForTrialManager(t,s)
            if isa(s,'station')
                out = s.numPorts>=2;
            else
                error('need a station object')
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
            requestRewardSizeULorMS=0;
            msPuff=0;
            msRewardSound=0;
            msPenalty=0;
            msPenaltySound=0;
            updateRM = false;
            % ========================================================
            % if the result is a port vector, and we have not yet assigned correct, then the current result must be the trial response
            % because phased trial logic returns the 'result' from previous phase only if it matches a target/distractor
            % call parent's updateTrialState() to do the request reward handling and check for 'timeout' flag
            [tm, possibleTimeout, result, ~, ~, requestRewardSizeULorMS, ~, ~, ~, ~, ~, ~, ~, updateRM1] = ...
                updateTrialState@trialManager(tm, sm, subject, result, spec, ports, lastPorts, ...
                targetPorts, requestPorts, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
                floatprecision, textures, destRect, requestRewardDone,punishResponses,compiledRecords);
            if ~isempty(result) && ~ischar(result)
                resp=find(result);
                if length(resp)==1
                    result = 'nominal';
                    correct=1;
                    if punishResponses
                        correct=0;
                    end
                else
                    correct=0;
                    result = 'multiple ports';
                end
                trialDetails.correct=correct;
            elseif ischar(result) && ismember(result,{'timedout','multiple ports'})
                correct=0;
                trialDetails.correct=correct;
            elseif ischar(result) && ismember(result,{'nominal'})
                correct=1;
                trialDetails.correct=correct;
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
            if ~isempty(phaseType) && strcmp(phaseType,'reinforced') && framesInPhase==0
                % we only check to do rewards on the first frame of the 'reinforced' phase
                [rm, rewardSizeULorMS, ~, msPenalty, msPuff, msRewardSound, msPenaltySound, updateRM2]=...
                    tm.reinforcementManager.calcReinforcement(subject, trialRecords,compiledRecords);
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
                    
                    spec.framesUntilTransition = framesUntilTransition;
                    [cStim, correctScale] = sm.correctStim(numCorrectFrames);
                    spec.scaleFactor = correctScale;
                    strategy='textureCache';
                    [floatprecision, cStim] = tm.determineColorPrecision(cStim, strategy);
                    textures = tm.cacheTextures(strategy,cStim,window,floatprecision);
                    destRect = tm.determineDestRect(window, correctScale, cStim, strategy);
                    spec=setStim(spec,cStim);
                    
                elseif ~correct
                    % this only happens when multiple ports are triggered
                    rewardSizeULorMS=0;
                    msRewardSound=0;
                    msPuff=0; % for now, we don't want airpuffs to be automatic punishment, right?
                    
                        if isempty(framesUntilTransition)
                            framesUntilTransition = ceil((msPenalty/1000)/ifi);
                        end
                        numErrorFrames=ceil((msPenalty/1000)/ifi);

                    
                    spec.framesUntilTransition = framesUntilTransition;
                    [eStim, errorScale] =sm.errorStim(numErrorFrames);
                    spec.scaleFactor = errorScale;
                    
                    strategy='textureCache';
                    [floatprecision, eStim] = tm.determineColorPrecision(eStim, strategy);
                    textures = tm.cacheTextures(strategy,eStim,window,floatprecision);
                    destRect=Screen('Rect',window);
                    spec=setStim(spec,eStim);
                end
            end % end reward handling
            
            updateRM = updateRM1 || updateRM2;
            
            
            trialDetails=[];
        end  % end function
        
        function [targetPorts, distractorPorts, details]=assignPorts(tm,details,lastTrialRec,responsePorts)
            
            if ~isempty(lastTrialRec)
                try
                    pNum = find(strcmp('reinforcement',{lastTrialRec.phaseRecords.phaseLabel}));
                    rDetails=lastTrialRec.phaseRecords(pNum-1).responseDetails;
                    lastResponse=find(rDetails.tries{end});
                catch err
                    lastResponse=[];
                end
                %             sca
                %             keyboard
                %             pNum
                %             rDetails
            else
                lastResponse=[];
            end
            
            if length(lastResponse)>1
                lastResponse=lastResponse(1);
            end
            if tm.allowRepeats
                targetPorts=responsePorts;
            else
                targetPorts=setdiff(responsePorts,lastResponse);
            end
            distractorPorts=[];
        end
        
        
        function [soundsToPlay, spec] = getSoundsToPlay(tm, ports, lastPorts, spec, phase, stepsInPhase,msRewardSound, msPenaltySound, ...
                targetOptions, distractorOptions, requestOptions, playRequestSoundLoop, trialDetails)
            % see doc in stimManager.calcStim.txt
            
            playLoopSounds={};
            playSoundSounds={};
            
            if ~isempty(spec.soundPlayed) && ~spec.soundAlreadyPlayed
                playSoundSounds{end+1} = spec.soundPlayed;
                spec.soundAlreadyPlayed = true;
            end
            
            if strcmp(spec.phaseType,'pre-request') && (any(ports(targetOptions)) || any(ports(distractorOptions)) || ...
                    (any(ports) && isempty(requestOptions)))
                % play white noise (when responsePort triggered during phase 1)
                playLoopSounds{end+1} = 'trySomethingElseSound';
            elseif ismember(spec.phaseType,{'discrim','pre-response'}) && any(ports(requestOptions))
                % play stim sound (when stim is requested during phase 2)
                playLoopSounds{end+1} = 'keepGoingSound';
            elseif strcmp(spec.phaseType,'reinforced') && stepsInPhase <= 0 && trialDetails.correct
                % play correct sound
                playSoundSounds{end+1} = {'correctSound', msRewardSound};
            elseif strcmp(spec.phaseType,'reinforced') && stepsInPhase <= 0 && ~trialDetails.correct
                % play wrong sound
                playSoundSounds{end+1} = {'wrongSound', msPenaltySound};
            elseif strcmp(spec.phaseType,'earlyPenalty') %&& stepsInPhase <= 0 what does stepsInPhase do? I don't think we need this for this phase
                % play wrong sound
                playSoundSounds{end+1} = {'wrongSound', msPenaltySound};
            end
            
            
            soundsToPlay = {playLoopSounds, playSoundSounds};
            
        end % end function
    
    end
    
    methods (Access = ?trialManager)
        function [stimSpecs, startingStimSpecInd] = createStimSpecsFromParams(tm,stimList,targetPorts,distractorPorts,~,hz,indexPulses)
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
            
            % freeDrinks can only have some stims.
            %  - preRequestStim(nonempty)
            %  - discrimStim(nonempty)
            %  - postDiscrimStim(can be empty)
            
            which = strcmp('discrimStim',stimNames);
            validateattributes(stimParams{which},{'struct'},{'nonempty'});
            
            which = strcmp('postDiscrimStim',stimNames);
            assert(isempty(stimParams{which}),'freeDrinks:createStimSpecsFromParams:incompatibleValue','freeDrinks does not support postDiscrim')
                       
            framesUntilOnset=floor(tm.delayManager.calcAutoRequest()*hz/1000); % autorequest is in ms, convert to frames
            responseWindow=floor(tm.responseWindowMs*hz/1000);
            
            % figure out the indices
            last = 0;
            discrimIndex = last+1;last = last+1;
            reinforcementIndex = last+1; last = last+1;
            itlIndex = last+1;
            
            
            % now generate our stimSpecs
            startingStimSpecInd=1;
            i=1;
            
            doNothing = [];
            
            % discrim
            criterion={doNothing,i+1,[targetPorts distractorPorts],reinforcementIndex};
            % we dont know if 'i+1' is postDiscrim or reinforcement right now...but if you respond, go to reinforcement
            which = strcmp('discrimStim',stimNames);
            discrimStim = stimParams{which};
            framesUntilTimeoutDiscrim=discrimStim.framesUntilTimeout;
            stimSpecs{i} = stimSpec(discrimStim.stimulus,criterion,discrimStim.stimType,discrimStim.startFrame,...
                framesUntilTimeoutDiscrim,discrimStim.autoTrigger,discrimStim.scaleFactor,false,hz,'discrim','discrim',...
                false,true,indexPulses,discrimStim.ledON,discrimStim.soundPlayed); % do not punish responses here
            i=i+1;
            % #### what is the purpose of responseWindow in trialManager????
            

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
end