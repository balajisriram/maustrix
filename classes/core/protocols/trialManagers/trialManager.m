classdef trialManager
    
    properties
        soundMgr
        reinforcementManager
        description
        frameDropCorner
        dropFrames
        saveDetailedFramedrops
        requestPorts
        showText
        delayManager
        responseWindowMs
    end
    
    properties (Constant = true)
        allowRepeats = true;
    end
    
    methods
        function t=trialManager(sndMgr,reinfMgr,delMgr,frameDropCorner,dropFrames,requestPorts,saveDetailedFramedrops,responseWindowMs,customDescription,showText)
            % TRIALMANAGER  class constructor.  ABSTRACT CLASS-- DO NOT INSTANTIATE
            % t=trialManager(soundManager,reinforcementManager,eyeController,customDescription,
            %   frameDropCorner, dropFrames, displayMethod, requestPorts,saveDetailedFramedrops,delayManager,responseWindowMs[,showText])
            %
            % 10/8/08 - this is the new integrated trialManager that handles all stims in a phased way - uses phased doTrial and stimOGL
            %
            % soundMgr - the soundManager object
            % reinforcementManager - the reinforcementManager object
            % description - a string description of this trialManager
            % frameDropCorner - a struct containing frameDropCorner params
            % dropFrames - whether or not to skip dropped frames
            % requestPorts - one of the strings {'none', 'center', 'all'}; defines which ports should be returned as requestPorts
            %       by the stimManager's calcStim; the default for nAFC is 'center' and the default for freeDrinks is 'none'
            % saveDetailedFrameDrops - a flag indicating whether or not to save detailed timestamp information for each dropped frame (causes large trialRecord files!)
            % delayManager - an object that determines how to stimulus onset works (could be immediate upon request, or some delay)
            % responseWindowMs - the timeout length of the 'discrim' phase in milliseconds (should be used by phaseify)
            
            %  soundManager
            validateattributes(sndMgr,{'soundManager'},{'nonempty'});
            assert(all(ismember(trialManager.requiredSoundNames, getSoundNames(sndMgr))),'trialManager:trialManager:incompleteInputs','provide a soundManager with all required sounds');
            t.soundMgr=sndMgr;
            
            % reinforcementManager
            validateattributes(reinfMgr,{'reinforcementManager'},{'nonempty'});
            t.reinforcementManager=reinfMgr;
            
            % customDescription
            validateattributes(customDescription,{'char'},{'nonempty'});
            t.description = customDescription;
            
            % frameDropCOrner
            t.frameDropCorner=frameDropCorner;
            
            % dropFrames
            validateattributes(dropFrames,{'logical'},{'nonempty'});
            t.dropFrames=dropFrames;
            
            % frameDropCorver
            validateattributes(frameDropCorner,{'struct','cell'},{'nonempty'});
            t.frameDropCorner = frameDropCorner;
            
            % requestPorts
            assert(ismember(requestPorts,{'none','all','center'}),'trialManager:trialManager:incorrectInput','requestPort should be ''none'',''all'' or ''center''');
            t.requestPorts=requestPorts;
            
            
            % saveDetailedFramedrops
            validateattributes(saveDetailedFramedrops,{'logical'},{'nonempty'});
            t.saveDetailedFramedrops=saveDetailedFramedrops;
            
            % delayManager
            validateattributes(delMgr,{'delayManager'},{'nonempty'});
            t.delayManager=delMgr;
            
            % responseWindowMs
            assert(isnumeric(responseWindowMs)&&all(responseWindowMs>=0)&&length(responseWindowMs)==2,...
                'trialManager:incorrectInput','responseWindowMs must be [min max] within the range [0 Inf] where min cannot be infinite')
            t.responseWindowMs=responseWindowMs;
            
            % showText
            assert(ismember(showText,{'full','light','off'}),'trialManager:trialManager:incorrectInput','only allowed values for showText is ''full'',''light'',''off''');
            t.showText=showText;
        end
        
        function t=decache(t)
            t.soundMgr=decache(t.soundMgr);
        end
        
        function tm=setReinforcementParam(tm,param,val)
            tm.reinforcementManager= tm.reinforcementManager.setReinforcementParam(param,val);
        end
        
        function d=disp(t)
            d=[t.description sprintf('\n\t\t\tsoundManager:\t') display(t.soundMgr)];
        end
        
        function [tm, updateTM, newSM, updateSM, stopEarly, tR, st, updateRM] = doTrial(tm,st,sm,sub,r,rn,tR,sessNo,cR)
            % This function handles most of the per-trial functionality, including stim creation and display, reward handling, and trialRecord recording.
            % Mainly called by trainingStep.doTrial
            % Main functions called: calcStim, createStimSpecsFromParams, stimOGL
            % INPUTS:
            %   trialManager - the trial manager object
            %   station - the station object
            %   stimManager - the stim manager object
            %   subject - the subject object
            %   r - the BCore object
            %   rn - the rnet object
            %   trialRecords - a vector of the current session's trialRecords (includes some history from prev. session until they get replaced by current session)
            %   sessionNumber - the current session number
            % OUTPUTS:
            %   trialManager - the (potentially modified) trial manager object
            %   updateTM - a flag indicating if the trialManager needs to be persisted
            %   newSM - a possibly new stimManager object
            %   updateSM - a flag indicating if the stimManager needs to be persisted
            %   stopEarly - a flag to stop running trials
            %   trialRecords - the updated trial records
            %   station - the (potentially modified) station object
            
            updateTM=false;
            stopEarly=0;
            
            % constants - returned from getConstants(rn) if we have a rnet
            % trialInd - the index of the current trialRecord
            % p - current training protocol
            % t - current training step index
            % ts - current trainingStep object
            
            %% validateattributes
            validateattributes(st,{'station'},{'nonempty'});
            validateattributes(sm,{'stimManager'},{'nonempty'});
            validateattributes(r,{'BCore'},{'nonempty'});
            validateattributes(sub,{'subject'},{'nonempty'});
            assert(tm.stationOKForTrialManager(st),'trialManager:doTrial:incompatibleValues','station not okay for trial manager');
            
            %% initialize trialRecords
            tRInd=length(tR)+1;
            p = sub.protocol;
            t = sub.trainingStepNum;
            ts = p.trainingSteps{t};
            
            if tRInd>1
                tR(tRInd).trialNumber=tR(tRInd-1).trialNumber+1;
            else
                tR(tRInd).trialNumber=1;
            end
            
            
            tR(tRInd).sessionNumber = sessNo;
            tR(tRInd).date = datevec(now);
            tR(tRInd).box = structize(r.getBoxFromID(r.getBoxIDForSubjectID(sub.id)));
            tR(tRInd).station = structize(st);
            tR(tRInd).protocolName = p.id;
            tR(tRInd).trainingStepNum = t;
            tR(tRInd).numStepsInProtocol = p.numTrainingSteps;
            
            tR(tRInd).reinforcementManager = [];
            tR(tRInd).reinforcementManagerClass = [];
            
            stns=r.getStationsForBoxID(r.getBoxIDForSubjectID(sub.id));
            for stNum=1:length(stns)
                tR(tRInd).stationIDsInBox{stNum} = stns(stNum).id;
            end
            
            tR(tRInd).subjectsInBox = r.getSubjectIDsForBoxID(r.getBoxIDForSubjectID(sub.id));
            tR(tRInd).trialManager = structize(decache(tm));
            tR(tRInd).stimManagerClass = class(sm);
            tR(tRInd).stepName = ts.stepName;
            tR(tRInd).trialManagerClass = class(tm);
            tR(tRInd).scheduler = structize(ts.scheduler);
            tR(tRInd).criterion = structize(ts.criterion);
            tR(tRInd).schedulerClass = class(ts.scheduler);
            tR(tRInd).criterionClass = class(ts.criterion);
            
            tR(tRInd).neuralEvents = [];
            
            resolutions=st.resolutions;
            
            %% calcStim
            % calcStim should return the following:
            %	newSM - a (possibly) modified stimManager object
            %	updateSM - a flag whether or not to copy newSM to BCore
            %	resInd - for setting resolution - DO NOT CHANGE
            %	preRequestStim - a struct containing all stim-specifc parameters to create a stimSpec for the pre-request phase
            %	preResponseStim - a struct containing all stim-specific parameters to create a stimSpec for the pre-response phase
            %	discrimStim - a struct containing the parameters to create a stimSpec for the discriminandum phase
            %		the parameters needed are: stimType, stim(actual movie frames), scaleFactor, [phaseLabel], [framesUntilTransition], [startFrame], [phaseType]
            %		note that not all of these may be used, depending on the trialManager's delayManager and responseWindow parameters
            %	LUT - the color lookup table - DO NOT CHANGE now; but eventually this should be a cell array of parameters to get the CLUT from oracle!
            %	trialRecords(trialInd).targetPorts - target ports DO NOT CHANGE
            %	trialRecords9trialInd).distractorPorts - distractor ports DO NOT CHANGE (both port sets are constant across the trial)
            %	stimulusDetails - stimDetails DO NOT CHANGE
            %	trialRecords(trialInd).interTrialLuminance - itl DO NOT CHANGE
            %	text - DO NOT CHANGE
            %	indexPulses - DO NOT CHANGE
            
            % now, we should ALWAYS call createStimSpecsFromParams, which should do the following:
            %	INPUTS: preRequestStim, preResponseStim, discrimStim, targetPorts, distractorPorts, requestPorts,interTrialLuminance,hz,indexPulses
            %	OUTPUTS: stimSpecs, startingStimSpecInd
            %		- should handle creation of default phase setup for nAFC/freeDrinks, and also handle additional phases depending on delayManager and responseWindow
            %		- how then does calcStim return a set of custom phases? - it no longer can, because we are forcing calcstim to return 3 structs...to discuss later?
            [newSM, updateSM, resInd, stimList, LUT, targetPorts, distractorPorts, stimulusDetails, text, indexPulses, imagingTasks, interTrialLum] = ...
                calcStim(sm, tm, st, tR, cR);
            
            [st, tR(tRInd).resolution,tR(tRInd).imagingTasks]=setResolutionAndPipeline(st,resolutions(resInd),imagingTasks);
            [newSM, updateSM, stimulusDetails]=postScreenResetCheckAndOrCache(newSM,updateSM,stimulusDetails); %enables SM to check or cache their tex's if they control that
            
            tR(tRInd).station = structize(st); %wait til now to record, so we get an updated ifi measurement in the station object
            tR(tRInd).targetPorts = targetPorts;
            tR(tRInd).distractorPorts = distractorPorts;
            tR(tRInd).interTrialLuminance = interTrialLum;
            
            refreshRate=1/st.ifi; %resolution.hz is 0 on OSX
            
            %% check port logic (depends on trialManager class)
            tm.checkPortLogic(targetPorts,distractorPorts,st);
            tm.checkPorts(targetPorts,distractorPorts);
            [stimSpecs, startingStimSpecInd] = createStimSpecsFromParams(tm,stimList,targetPorts,distractorPorts,tm.getRequestPorts(st.numPorts),...
                refreshRate,indexPulses);
            
            tm.validateStimSpecs(stimSpecs);
            
            [tempSoundMgr, updateSndM] = tm.soundMgr.cacheSounds(st);
            tm.soundMgr = tempSoundMgr;
            updateTM = updateTM || updateSndM;
            
            tR(tRInd).stimManager = structize(decache(newSM)); %many rouge stimManagers have a LUT cached in them and aren't decaching it -- hopefully will be fixed by the LUT fixing... (http://132.239.158.177/trac/rlab_hardware/ticket/224)
            stimulusDetails=structize(stimulusDetails);
            
            manualOn=0;
            if length(tR)>1
                if ~(tR(tRInd-1).leftWithManualPokingOn)
                    manualOn=0;
                elseif tR(tRInd-1).containedManualPokes
                    manualOn=1;
                else
                    error('should never happen')
                end
            end

            drawnow;
            %currentValveStates=st.verifyValvesClosed(); % #### do we need this?
            
            pStr=[tR(tRInd).protocolName 'a)' ' step:' num2str(tR(tRInd).trainingStepNum) '/' num2str(tR(tRInd).numStepsInProtocol) ];
            
            trialLabel=sprintf('session:%d trial:%d (%d)',sessNo,sum(tR(tRInd).sessionNumber == [tR.sessionNumber]),tR(tRInd).trialNumber);
            
            % #### removing datanet controls for now
%             if ~isempty(st.datanet)
%                 % 4/11/09 - also save the stimRecord here, before trial starts (but just the stimManagerClass)
%                 % also send over the filename of the neuralRecords file (so we can create it on the phys side, and then append every 30 secs)
%                 datanet_constants = getConstants(getDatanet(st));
%                 if ~isempty(getDatanet(st))
%                     [~, stopEarly] = handleCommands(getDatanet(st),[]);
%                 end
%                 if ~stopEarly
%                     commands=[];
%                     commands.cmd = datanet_constants.stimToDataCommands.S_TRIAL_START_EVENT_CMD;
%                     cparams=[];
%                     cparams.neuralFilename = sprintf('neuralRecords_%d-%s.mat',tR(tRInd).trialNumber,datestr(tR(tRInd).date,30));
%                     cparams.stimFilename = sprintf('stimRecords_%d-%s.mat',tR(tRInd).trialNumber,datestr(tR(tRInd).date, 30));
%                     cparams.time=datenum(tR(tRInd).date);
%                     cparams.trialNumber=tR(tRInd).trialNumber;
%                     cparams.stimManagerClass=tR(tRInd).stimManagerClass;
%                     cparams.stepName=getStepName(ts);
%                     cparams.stepNumber=t;
%                     commands.arg=cparams;
%                     [~] = sendCommandAndWaitForAck(getDatanet(st), commands);
%                     
%                     subID=sub.id;
%                     trialStartTime=datestr(tR(tRInd).date, 30);
%                     trialNum=tR(tRInd).trialNumber;
%                     stimManagerClass=tR(tRInd).stimManagerClass;
%                     stepName=tR(tRInd).stepName;
%                     frameDropCorner=tm.frameDropCorner;
%                     
%                     try
%                         stim_path = fullfile(getStorePath(getDatanet(st)), 'stimRecords');
%                         save(fullfile(stim_path,cparams.stimFilename),'subID','trialStartTime','trialNum','stimManagerClass','stimulusDetails','frameDropCorner','refreshRate','stepName');
%                     catch ex
%                         error('unable to save to %s',stim_path);
%                     end
%                 end
%             end
            
            tR(tRInd).stimDetails = stimulusDetails;
            
            % stopEarly could potentially be set by the datanet's handleCommands (if server tells this client to shutdown
            % while we are in doTrial)
            if ~stopEarly
                [tm, stopEarly,tR,~,~,~,st,updateRM] ...
                    = stimOGL(tm,stimSpecs,startingStimSpecInd,newSM,LUT,tR(tRInd).targetPorts,tR(tRInd).distractorPorts, ...
                    getRequestPorts(tm, st.numPorts),tR(tRInd).interTrialLuminance,st,manualOn,.1,...
                    text,rn,sub.id,class(newSM),pStr,trialLabel,[],tR,cR,sub);
            end
            
            tR(tRInd).trainingStepName = generateStepName(ts);
            
            verifyValvesClosed(st);
            
            if ischar(tR(tRInd).result) && strcmp(tR(tRInd).result, 'manual flushPorts')
                type='flushPorts';
                typeParams=[];
                validInputs={};
                validInputs{1}=0:getNumPorts(st);
                validInputs{2}=[1 100];
                validInputs{3}=[0 10];
                validInputs{4}=[0 60];
                fpVars = userPrompt(getPTBWindow(st),validInputs,type,typeParams);
                portsToFlush=fpVars(1);
                if portsToFlush==0 % 0 is a special flag that means do all ports (for calibration, we need interleaved ports)
                    portsToFlush=1:getNumPorts(st);
                end
                flushPorts(st,fpVars(3),fpVars(2),fpVars(4),portsToFlush);
                stopEarly=false; % reset stopEarly/quit to be false, so continue doing trials
            elseif ischar(tR(tRInd).result) && (strcmp(tR(tRInd).result, 'nominal') || ...
                    strcmp(tR(tRInd).result, 'multiple ports') || strcmp(tR(tRInd).result,'timedout'))
                % keep doing trials
            else
                tR(tRInd).result
                if strcmp(tR(tRInd).result,'manual training step')
                    updateTM=true; % to make sure that soundMgr gets decached and passed back to the subject/doTrial where the k+t happens
                end
                fprintf('setting stopEarly\n')
                stopEarly = 1;
            end
            
%             if ~isempty(st.datanet) %&& ~stopEarly ####
%                 handleCommands(st.datanet,[]);
%                 datanet_constants = getConstants(st.datanet);
%                 commands=[];
%                 commands.cmd = datanet_constants.stimToDataCommands.S_TRIAL_END_EVENT_CMD;
%                 cparams=[];
%                 cparams.time = now;
%                 commands.arg=cparams;
%                 [~] = sendCommandAndWaitForAck(st.datanet, commands);
%             end
            
            tR(tRInd).reinforcementManager = structize(tm.reinforcementManager);
            tR(tRInd).reinforcementManagerClass = class(tm.reinforcementManager);
            
            verifyValvesClosed(st);            
            if stopEarly
                tm.soundMgr=uninit(tm.soundMgr,st);
            end
            
        end
        
        function outStr = getNameFragment(trialManager)
            % returns abbreviated class name
            % should be overriden by trialManager-specific strings
            % used to generate names for trainingSteps
            
            outStr = class(trialManager);
            
        end % end function
        
        function out=getRequestPorts(tm,numPorts)
            switch tm.requestPorts
                case 'none'
                    out=[];
                case 'all'
                    out=1:numPorts;
                case 'center'
                    out=floor((numPorts+1)/2);
            end
        end
        
        function [tm, trialDetails, result, spec, rewardSizeULorMS, requestRewardSizeULorMS, ...
                msPuff, msRewardSound, msPenalty, msPenaltySound, floatprecision, textures, destRect, updateRM] = ...
                updateTrialState(tm, sm, subject, result, spec, ports, lastPorts,~,requestPorts,lastRequestPorts,~,trialRecords, ~, ~, ~, ...
                floatprecision, textures, destRect,requestRewardDone, ~,compiledRecords)
            % This function is a TM base class method to update trial state before every flip.
            % Things done here include:
            % - check for request rewards
            
            rewardSizeULorMS=0;
            requestRewardSizeULorMS=0;
            msPuff=0;
            msRewardSound=0;
            msPenalty=0;
            msPenaltySound=0;
            
            if isfield(trialRecords(end),'trialDetails') && isfield(trialRecords(end).trialDetails,'correct')
                correct=trialRecords(end).trialDetails.correct;
            else
                correct=[];
            end
            
            if ~isempty(result) && ischar(result) && strcmp(result,'timeout') && isempty(correct) && strcmp(getPhaseLabel(spec),'reinforcement')
                correct=0;
                result='timedout';
                trialDetails=[];
                trialDetails.correct=correct;
            elseif ~isempty(result) && ischar(result) && strcmp(result,'timeout') && isempty(correct) && strcmp(getPhaseLabel(spec),'itl')
                % timeout during 'itl' phase - neither correct nor incorrect (only happens when no stim is shown)
                result='timedout';
                trialDetails=[];
            else
                trialDetails=[];
            end
            
            updateRM = false;
            if (any(ports(requestPorts)) && ~any(lastPorts(requestPorts))) && ... % if a request port is triggered
                    ((strcmp(tm.reinforcementManager.requestMode,'nonrepeats') && ~any(ports&lastRequestPorts)) || ... % if non-repeat
                    strcmp(tm.reinforcementManager.requestMode,'all') || ...  % all requests
                    ~requestRewardDone) % first request
                
                [rm, rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound, updateRM] =...
                    tm.reinforcementManager.calcReinforcement(subject,trialRecords,compiledRecords);
                if updateRM
                    tm.reinforcementManager = rm;
                end  
            end
            
            
        end
    end
    
    methods (Access=private)
  
        function xTextPos = drawText(tm, window, labelFrames, subID, xOrigTextPos, yTextPos, normBoundsRect, stimID, protocolStr, ...
                textLabel, trialLabel, i, frameNum, manual, didManual, didAPause, numDrops, numApparentDrops, phaseInd, phaseType,textType)
            
            %DrawFormattedText() won't be any faster cuz it loops over calls to Screen('DrawText'), tho it would clean this code up a bit.
            
            xTextPos=xOrigTextPos;
            brightness=100;
            switch textType
                case 'full'
                    if labelFrames
                        [xTextPos] = Screen('DrawText',window,['ID:' subID ],xOrigTextPos,yTextPos,brightness*ones(1,3));
                        xTextPos=xTextPos+50;
                        [garbage,yTextPos] = Screen('DrawText',window,['trlMgr:' class(tm) ' stmMgr:' stimID  ' prtcl:' protocolStr ],xTextPos,yTextPos,brightness*ones(1,3));
                    end
                    yTextPos=yTextPos+1.5*normBoundsRect(4);
                    
                    if labelFrames
                        if iscell(textLabel)  % this is a reoccuring cost per frame... could be before the loop... pmm
                            txtLabel=textLabel{i};
                        else
                            txtLabel=textLabel;
                        end
                        if iscell(phaseType)
                            phaseTypeDisplay=phaseType{1};
                        else
                            phaseTypeDisplay=phaseType;
                        end
                        [garbage,yTextPos] = Screen('DrawText',window,sprintf('priority:%g %s stimInd:%d frame:%d drops:%d(%d) stim:%s, phaseInd:%d strategy:%s',Priority(),trialLabel,i,frameNum,numDrops,numApparentDrops,txtLabel,phaseInd,phaseTypeDisplay),xTextPos,yTextPos,brightness*ones(1,3));
                        yTextPos=yTextPos+1.5*normBoundsRect(4);
                    end
                case 'light'
                    [garbage,yTextPos] = Screen('DrawText',window,sprintf('%s stimInd:%d frame:%d drops:%d(%d)',trialLabel,i,frameNum,numDrops,numApparentDrops),xTextPos,yTextPos,brightness*ones(1,3));
                    yTextPos=yTextPos+1.5*normBoundsRect(4);
                otherwise
                    error('unsupported')
            end
            
            if manual
                manTxt='on';
            else
                manTxt='off';
            end
            if didManual
                [garbage,yTextPos] = Screen('DrawText',window,sprintf('trial record will indicate manual poking on this trial (k+m to toggle for next trial: %s)',manTxt),xTextPos,yTextPos,brightness*ones(1,3));
                yTextPos=yTextPos+1.5*normBoundsRect(4);
            end
            
            if didAPause
                %[garbage,yTextPos] = ...
                Screen('DrawText',window,'trial record will indicate a pause occurred on this trial',xTextPos,yTextPos,brightness*ones(1,3));
                %yTextPos=yTextPos+1.5*normBoundsRect(4);
            end
            
            
        end % end function
        
        function [tm, done, newSpecInd, specInd, updatePhase, transitionedByTimeFlag, transitionedByPortFlag, result,...
                isRequesting, lastSoundsLooped, getSoundsTime, soundsDoneTime, framesDoneTime, ...
                portSelectionDoneTime, isRequestingDoneTime, goDirectlyToError] = ...
                handlePhasedTrialLogic(tm, done, ...
                ports, lastPorts, station, specInd, phaseType, transitionCriterion, framesUntilTransition, numFramesInStim,...
                framesInPhase, isFinalPhase, trialDetails, stimDetails, result, ...
                stimManager, msRewardSound, mePenaltySound, targetOptions, distractorOptions, requestOptions, ...
                playRequestSoundLoop, isRequesting, soundNames, lastSoundsLooped)
            
            updatePhase=0;
            newSpecInd = specInd;
            transitionedByTimeFlag = false;
            transitionedByPortFlag = false;
            goDirectlyToError=false;
            
            % ===================================================
            % Check against framesUntilTransition - Transition BY TIME
            % if we are at grad by time, then manually set port to the correct one
            % note that we will need to flag that this was done as "auto-request"
            if ~isempty(framesUntilTransition) && framesInPhase == framesUntilTransition - 1 % changed to framesUntilTransition-1 % 8/19/08
                % find the special 'timeout' transition (the port set should be empty)
                newSpecInd = transitionCriterion{find(cellfun('isempty',transitionCriterion))+1};
                % this will always work as long as we guarantee the presence of this special indicator (checked in stimSpec constructor)
                updatePhase = 1;
                if isFinalPhase
                    done = 1;
                    %      error('we are done by time');
                end
                %error('transitioned by time in phase %d', specInd);
                transitionedByTimeFlag = true;
                if isempty(result)
                    result='timeout';
                    if isRequesting
                        isRequesting=false;
                    else
                        isRequesting=true;
                    end
                end
            end
            
            
            % Check against transition by numFramesInStim (based on size of the stimulus in 'cache' or 'timedIndexed' mode)
            % in other modes, such as 'loop', this will never pass b/c numFramesInStim==Inf
            if framesInPhase==numFramesInStim
                % find the special 'timeout' transition (the port set should be empty)
                newSpecInd = transitionCriterion{cellfun('isempty',transitionCriterion)+1};
                % this will always work as long as we guarantee the presence of this special indicator (checked in stimSpec constructor)
                updatePhase = 1;
                if isFinalPhase
                    done = 1;
                    %      error('we are done by time');
                end
            end
            
            framesDoneTime=GetSecs;
            
            % Check for transition by port selection
            for gcInd=1:2:length(transitionCriterion)-1
                if ~isempty(transitionCriterion{gcInd}) && any(logical(ports(transitionCriterion{gcInd})))
                    % we found port in this port set
                    % first check if we are done with this trial, in which case we do nothing except set done to 1
                    if isFinalPhase
                        done = 1;
                        updatePhase = 1;
                        %              'we are done with this trial'
                        %              specInd
                    else
                        % move to the next phase as specified by graduationCriterion
                        %      specInd = transitionCriterion{gcInd+1};
                        newSpecInd = transitionCriterion{gcInd+1};
                        %             if (specInd == newSpecInd)
                        %                 error('same indices at %d', specInd);
                        %             end
                        updatePhase = 1;
                    end
                    transitionedByPortFlag = true;
                    
                    % set result to the ports array when it is triggered during a phase transition (ie result will be whatever the last port to trigger
                    %   a transition was)
                    result = ports;
                    
                    if length(find(ports))>1
                        goDirectlyToError=true;
                    end
                    
                    % we should stop checking all the criteria if we already passed one (essentially first come first served)
                    break;
                end
            end
            
            if done && isempty(result)
                % this means we were on 'autopilot', so the result should technically be nominal for this trial
                result='nominal';
            end
            
            portSelectionDoneTime=GetSecs;
            
            % =================================================
            % SOUNDS
            % changed from newSpecInd to specInd (cannot anticipate phase transition b/c it hasnt called updateTrialState to set correctness)
            soundsToPlay = getSoundsToPlay(stimManager, ports, lastPorts, specInd, phaseType, framesInPhase,msRewardSound, mePenaltySound, ...
                targetOptions, distractorOptions, requestOptions, playRequestSoundLoop, class(tm), trialDetails, stimDetails);
            getSoundsTime=GetSecs;
            % soundsToPlay is a cell array of sound names {{playLoop sounds}, {playSound sounds}} to be played at current frame
            % validate soundsToPlay here (make sure they are all members of soundNames)
            if ~isempty(setdiff(soundsToPlay{1},soundNames)) || ~all(cellfun(@(x) ismember(x{1},soundNames),soundsToPlay{2}))
                error('getSoundsToPlay assigned sounds that are not in the soundManager!');
            end
            
            % first end any loops that were looping last frame but should no longer be looped
            stopLooping=setdiff(lastSoundsLooped,soundsToPlay{1});
            for snd=stopLooping
                tm.soundMgr = playLoop(tm.soundMgr,snd,station,0);
            end
            
            % then start any loops that weren't already looping
            startLooping=setdiff(soundsToPlay{1},lastSoundsLooped);
            for snd=startLooping
                if ~isempty(snd)
                    tm.soundMgr = playLoop(tm.soundMgr,snd,station,1);
                end
            end
            
            lastSoundsLooped = soundsToPlay{1};
            
            % now play one-time sounds
            for i=1:length(soundsToPlay{2})
                tm.soundMgr = playSound(tm.soundMgr,soundsToPlay{2}{i}{1},soundsToPlay{2}{i}{2}/1000.0,station);
            end
            
            soundsDoneTime=GetSecs;
            
            
            % set isRequesting when request port is hit according to these rules:
            %   if isRequesting was already 1, then set it to 0
            %   if isRequesting was 0, then set it to 1
            %   (basically flip the bit every time request port is hit)
            %
            if any(ports(requestOptions)) && ~any(lastPorts(requestOptions))
                if isRequesting
                    isRequesting=false;
                else
                    isRequesting=true;
                end
            end
            
            isRequestingDoneTime=GetSecs;
        end % end function
        
        function [tm, Quit, trialRecords, eyeData, eyeDataFrameInds, gaze, frameDropCorner, station, updateRM] ...
                = runRealTimeLoop(tm, subject, window, ifi, stimSpecs, startingStimSpecInd, phaseData, stimManager, ...
                targetOptions, distractorOptions, requestOptions, interTrialLuminance, interTrialPrecision, ...
                station, manual,timingCheckPct,textLabel,rn,subID,stimID,protocolStr,trialLabel,...
                originalPriority, eyeTracker, frameDropCorner,trialRecords,compiledRecords)
            % This function does the real-time looping for stimulus presentation. The rough order of events per loop:
            %   - (possibly) update phase-specific information
            %   - call updateTrialState to set correctness and determine rewards
            %   - update stim frame index and draw new frame as needed
            %   - (possibly) get eyeTracker data
            %   - check for keyboard input
            %   - check for port input
            %   - carry out logic (whether we need to transition phases, what responses we got, what sounds to play)
            %   - carry out rewards
            %   - check for server and datanet commands
            %   - carry out airpuffs
            updateRM = false;
            station.securePins();
            station.setStatePins('trial',true); % start the trial
            
            % =====================================================================================================================
            %   show movie following mario's 'ProgrammingTips' for the OpenGL version of PTB
            %   http://www.kyb.tuebingen.mpg.de/bu/people/kleinerm/ptbosx/ptbdocu-1.0.5MK4R1.html
            %   except we drop frames (~1 per 45mins at 100Hz) if we preload all textures as he recommends, so we make and load them each frame
            
            % high level important settings -- should move all to stimManager
            filtMode = 0;               %how to compute the pixel values when the texture is drawn scaled
            %                           %0 = Nearest neighbour filtering, 1 = Bilinear filtering (default, and BAD)
            
            framesPerUpdate = 1;        %set number of monitor refreshes for each one of your refreshes
            
            labelFrames = 1;            %print a frame ID on each frame (makes frame calculation slow!)
            textType = tm.showText;
            showText = ~strcmp(textType,'off'); %whether or not to call draw text to print any text on screen

            if ismac
                %http://psychtoolbox.org/wikka.php?wakka=FaqPerformanceTuning1
                %Screen('DrawText'): This is fast and low-quality on MS-Windows and beautiful but slow on OS/X.
                %also not good enough on asus mobo w/8600
                
                %setting textrenderer and textantialiasing to 0 not good enough
                labelFrames=0;
            end
            
            dontclear = 2;              %will be passed to flip
            %                           %0 = flip will set framebuffer to background (slow, but other options fail on some gfx cards, like the integrated gfx on our asus mobos?)
            %                           %1 = flip will leave the buffer as is ("incremental drawing" - but unclear if it copies the buffer just drawn into the buffer you're about to draw to, or if it is from a frame before that...)
            %                           %2 = flip does nothing, buffer state undefined (you must draw into each pixel if you care) - fastest
            % =====================================================================================================================
            
            trialInd=length(trialRecords);
            expertCache=[];
            ports=logical(0*readPorts(station));
            stochasticPorts = ports;
            lastPorts=ports;
            lastRequestPorts=ports;
            playRequestSoundLoop=false;
            
            requestRewardStarted=false;
            requestRewardStartLogged=false;
            requestRewardDone=false;
            requestRewardDurLogged=false;
            requestRewardOpenCmdDone=false;
            
            rewardCurrentlyOn=false;
            msRewardOwed=0;
            msRequestRewardOwed=0;
            msAirpuffOwed=0;
            airpuffOn=false;
            lastAirpuffTime=[];
            msRewardSound=0;
            msPenaltySound=0;
            lastRewardTime=[];
            thisRewardPhaseNum=[];
            thisAirpuffPhaseNum=[];
            
            Quit=false;
            responseOptions = union(targetOptions, distractorOptions);
            done=0;
            containedExpertPhase=0;
            eyeData=[];
            eyeDataFrameInds=[];
            gaze=[];
            soundNames=getSoundNames(tm.soundMgr);
            
            phaseInd = startingStimSpecInd; % which phase we are on (index for stimSpecs and phaseData)
            phaseNum = 0; % increasing counter for each phase that we visit (may not match phaseInd if we repeat phases) - start at 0 b/c we increment during updatePhase
            updatePhase = 1; % are we starting a new phase?
            
            lastI = 0;
            isRequesting=0;
            
            lastSoundsLooped={};
            totalFrameNum=1; % for eyetracker
            totalEyeDataInd=1;
            doFramePulse=1;
            
            doValves=0*ports;
            newValveState=doValves;
            doPuff=false;
            
            % =========================================================================
            
            timestamps.loopStart=0;
            timestamps.phaseUpdated=0;
            timestamps.frameDrawn=0;
            timestamps.frameDropCornerDrawn=0;
            timestamps.textDrawn=0;
            timestamps.drawingFinished=0;
            timestamps.when=0;
            timestamps.prePulses=0;
            timestamps.postFlipPulse=0;
            timestamps.missesRecorded=0;
            timestamps.eyeTrackerDone=0;
            timestamps.kbCheckDone=0;
            timestamps.keyboardDone=0;
            timestamps.enteringPhaseLogic=0;
            timestamps.phaseLogicDone=0;
            timestamps.rewardDone=0;
            timestamps.serverCommDone=0;
            timestamps.phaseRecordsDone=0;
            timestamps.loopEnd=0;
            timestamps.prevPostFlipPulse=0;
            timestamps.vbl=0;
            timestamps.ft=0;
            timestamps.missed=0;
            timestamps.lastFrameTime=0;
            
            timestamps.logicGotSounds=0;
            timestamps.logicSoundsDone=0;
            timestamps.logicFramesDone=0;
            timestamps.logicPortsDone=0;
            timestamps.logicRequestingDone=0;
            
            timestamps.kbOverhead=0;
            timestamps.kbInit=0;
            timestamps.kbKDown=0;
            
            % =========================================================================
            
            responseDetails.numMisses=0;
            responseDetails.numApparentMisses=0;
            
            responseDetails.numUnsavedMisses=0;
            responseDetails.numUnsavedApparentMisses=0;
            
            responseDetails.misses=[];
            responseDetails.apparentMisses=[];
            
            responseDetails.afterMissTimes=[];
            responseDetails.afterApparentMissTimes=[];
            
            responseDetails.missIFIs=[];
            responseDetails.apparentMissIFIs=[];
            
            responseDetails.missTimestamps=timestamps;
            responseDetails.apparentMissTimestamps=timestamps;
            
            responseDetails.numDetailedDrops=1000;
            
            responseDetails.nominalIFI=ifi;
            responseDetails.tries={};
            responseDetails.times={};
            responseDetails.durs={};
            % responseDetails.requestRewardDone=false;
            responseDetails.requestRewardPorts={};
            responseDetails.requestRewardStartTime={};
            responseDetails.requestRewardDurationActual={};
            
            responseDetails.startTime=[];
            
            % =========================================================================
            
            phaseRecordAllocChunkSize = 1;
            [phaseRecords(1:length(stimSpecs)).responseDetails]= deal(responseDetails);
            
            [phaseRecords(1:length(stimSpecs)).proposedRewardDurationMSorUL] = deal(0);
            [phaseRecords(1:length(stimSpecs)).proposedAirpuffDuration] = deal(0);
            [phaseRecords(1:length(stimSpecs)).proposedPenaltyDurationMSorUL] = deal(0);
            [phaseRecords(1:length(stimSpecs)).actualRewardDurationMSorUL] = deal(0);
            [phaseRecords(1:length(stimSpecs)).actualAirpuffDuration] = deal(0);
            
            [phaseRecords(1:length(stimSpecs)).valveErrorDetails]=deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToOpenValves]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToCloseValveRecd]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToCloseValves]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToRewardCompleted]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToRewardCompletelyDone]= deal([]);
            [phaseRecords(1:length(stimSpecs)).primingValveErrorDetails]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToOpenPrimingValves]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToClosePrimingValveRecd]= deal([]);
            [phaseRecords(1:length(stimSpecs)).latencyToClosePrimingValves]= deal([]);
            [phaseRecords(1:length(stimSpecs)).actualPrimingDuration]= deal([]);
            
            [phaseRecords(1:length(stimSpecs)).containedManualPokes]= deal([]);
            [phaseRecords(1:length(stimSpecs)).leftWithManualPokingOn]= deal([]);
            [phaseRecords(1:length(stimSpecs)).containedAPause]= deal([]);
            [phaseRecords(1:length(stimSpecs)).didHumanResponse]= deal([]);
            [phaseRecords(1:length(stimSpecs)).containedForcedRewards]= deal([]);
            [phaseRecords(1:length(stimSpecs)).didStochasticResponse]= deal([]);
            
            % =========================================================================
            
            headroom=nan(1,responseDetails.numDetailedDrops);
            
            if ~isempty(rn)
                constants = getConstants(rn);
            end
            % ####
%             if strcmp(station.rewardMethod,'serverPump')
%                 if isempty(rn) || ~isa(rn,'rnet')
%                     error('need an rnet for station with rewardMethod of serverPump')
%                 end
%             end
            
            [keyIsDown,secs,keyCode]=KbCheck; %load mex files into ram + preallocate return vars
            GetSecs;
            Screen('Screens');
            
            
            if window>0
                standardFontSize=12;
                oldFontSize = Screen('TextSize',window,standardFontSize);
                [normBoundsRect, offsetBoundsRect]= Screen('TextBounds', window, 'TEST');
            end
            
            
            KbName('UnifyKeyNames'); %does not appear to choose keynamesosx on windows - KbName('KeyNamesOSX') comes back wrong
            
            %consider using RestrictKeysForKbCheck for speedup of KbCheck
            
            KbConstants.allKeys=KbName('KeyNames');
            KbConstants.allKeys=lower(cellfun(@char,KbConstants.allKeys,'UniformOutput',false));
            KbConstants.controlKeys=find(cellfun(@(x) ~isempty(x),strfind(KbConstants.allKeys,'control')));
            KbConstants.shiftKeys=find(cellfun(@(x) ~isempty(x),strfind(KbConstants.allKeys,'shift')));
            KbConstants.kKey=KbName('k');
            KbConstants.pKey=KbName('p');
            KbConstants.qKey=KbName('q');
            KbConstants.mKey=KbName('m');
            KbConstants.aKey=KbName('a');
            KbConstants.rKey=KbName('r');
            KbConstants.tKey=KbName('t');
            KbConstants.fKey=KbName('f');
            KbConstants.eKey=KbName('e');
            KbConstants.atKeys=find(cellfun(@(x) ~isempty(x),strfind(KbConstants.allKeys,'@')));
            KbConstants.asciiOne=double('1');
            KbConstants.portKeys={};
            for i=1:length(ports)
                KbConstants.portKeys{i}=find(strncmp(char(KbConstants.asciiOne+i-1),KbConstants.allKeys,1));
            end
            KbConstants.numKeys={};
            for i=1:10
                KbConstants.numKeys{i}=find(strncmp(char(KbConstants.asciiOne+i-1),KbConstants.allKeys,1));
            end
            
            priorityLevel=MaxPriority('GetSecs','KbCheck');
            
            Priority(priorityLevel);
            
            % =========================================================================
            
            if ~isempty(eyeTracker)
                perTrialSyncing=false; %could pass this in if we ever decide to use it; now we don't
                if perTrialSyncing && isa(eyeTracker,'eyeLinkTracker')
                    status=Eyelink('message','SYNCTIME');
                    if status~=0
                        error('message error, status: %g',status)
                    end
                end
                
                framesPerAllocationChunk=getFramesPerAllocationChunk(eyeTracker);
                
                
                if isa(eyeTracker,'eyeLinkTracker')
                    eyeData=nan(framesPerAllocationChunk,length(getEyeDataVarNames(eyeTracker)));
                    eyeDataFrameInds=nan(framesPerAllocationChunk,1);
                    gaze=nan(framesPerAllocationChunk,2);
                else
                    error('no other methods')
                end
            end
            
            % =========================================================================
            
            didAPause=0;
            didManual=false;
            paused=0;
            pressingM=0;
            pressingP=0;
            framesSinceKbInput = 0;
            shiftDown=false;
            ctrlDown=false;
            atDown=false;
            kDown=false;
            portsDown=false(1,length(ports));
            pNum=0;
            
            trialRecords(trialInd).result=[]; %initialize
            trialRecords(trialInd).correct=[];
            analogOutput=[];
            startTime=0;
            logIt=true;
            lookForChange=false;
            punishResponses=[];
            
            % =========================================================================
            % do first frame and  any stimulus onset synched actions
            % make sure everything after this point is preallocated
            % efficiency is crticial from now on
            
            if window>0
                % draw interTrialLuminance first
                Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                interTrialTex=Screen('MakeTexture', window, interTrialLuminance,0,0,interTrialPrecision); %need floatprecision=0 for remotedesktop
                Screen('DrawTexture', window, interTrialTex,phaseData{end}.destRect, [], filtMode);
                [timestamps.vbl, sos, startTime]=Screen('Flip',window);
            end
            
            timestamps.lastFrameTime=GetSecs;
            timestamps.missesRecorded       = timestamps.lastFrameTime;
            timestamps.eyeTrackerDone       = timestamps.lastFrameTime;
            timestamps.kbCheckDone          = timestamps.lastFrameTime;
            timestamps.keyboardDone         = timestamps.lastFrameTime;
            timestamps.enteringPhaseLogic   = timestamps.lastFrameTime;
            timestamps.phaseLogicDone       = timestamps.lastFrameTime;
            timestamps.rewardDone           = timestamps.lastFrameTime;
            timestamps.serverCommDone       = timestamps.lastFrameTime;
            timestamps.phaseRecordsDone     = timestamps.lastFrameTime;
            timestamps.loopEnd              = timestamps.lastFrameTime;
            timestamps.prevPostFlipPulse    = timestamps.lastFrameTime;
            
            %show stim -- be careful in this realtime loop!
            while ~done && ~Quit;
                timestamps.loopStart=GetSecs;
                
                xOrigTextPos = 10;
                xTextPos=xOrigTextPos;
                yTextPos = 20;
                
                if updatePhase == 1
                    %wind=Screen('OpenWindow', 0, 0);
                    Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    %####setStatePins(station,'stim',false);
                    %####setStatePins(station,'phase',true);
                    
                    startTime=GetSecs(); % startTime is now per-phase instead of per trial, since corresponding times in responseDetails are also per-phase
                    phaseNum=phaseNum+1;
                    if phaseNum>length(phaseRecords)
                        
                        nextPhaseRecordNum=length(phaseRecords)+1;
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).responseDetails]= deal(responseDetails);
                        
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).proposedRewardDurationMSorUL] = deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).proposedAirpuffDuration] = deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).proposedPenaltyDurationMSorUL] = deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).actualRewardDurationMSorUL] = deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).actualAirpuffDuration] = deal([]);
                        
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).valveErrorDetails]=deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToOpenValves]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToCloseValveRecd]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToCloseValves]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToRewardCompleted]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToRewardCompletelyDone]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).primingValveErrorDetails]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToOpenPrimingValves]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToClosePrimingValveRecd]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).latencyToClosePrimingValves]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).actualPrimingDuration]= deal([]);
                        
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).containedManualPokes]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).leftWithManualPokingOn]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).containedAPause]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).didHumanResponse]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).containedForcedRewards]= deal([]);
                        [phaseRecords(nextPhaseRecordNum:nextPhaseRecordNum+phaseRecordAllocChunkSize).didStochasticResponse]= deal([]);
                    end
                    
                    i=0;
                    frameIndex=0;
                    frameNum=1;
                    phaseStartTime=GetSecs;
                    firstVBLofPhase=timestamps.vbl;
                    
                    didPulse=0;
                    didValves=0;
                    arrowKeyDown=false;
                    
                    currentValveState=getValves(station); % if valve reward is still going from previous phase, we force it closed. in other words, make sure your phases are long enough for the rewards that happen in them!
                    serverValveChange=false;
                    serverValveStates=false;
                    didStochasticResponse=false;
                    didHumanResponse=false;
                    
                    % =========================================================================
                    phase = phaseData{phaseInd};
                    floatprecision = phase.floatprecision;
                    frameIndexed = phase.frameIndexed;
                    loop = phase.loop;
                    trigger = phase.trigger;
                    timeIndexed = phase.timeIndexed;
                    indexedFrames = phase.indexedFrames;
                    timedFrames = phase.timedFrames;
                    strategy = phase.strategy;
                    toggleStim = phase.toggleStim; %lickometer % now passed in from calcStim
                    phaseRecords(phaseNum).toggleStim=toggleStim; % flag for whether the end of a beam break ends the request state
                    destRect = phase.destRect;
                    textures = phase.textures;
                    
                    % =========================================================================
                    spec = stimSpecs{phaseInd};
                    stim = spec.stimulus;
                    transitionCriterion = spec.transitions;
                    framesUntilTransition = spec.framesUntilTransition;
                    phaseType = spec.phaseType;
                    punishLastResponse=punishResponses;
                    punishResponses = spec.punishResponses;
                    
                    % =========================================================================
                    
                    framesInPhase = 0;
                    if ~isempty(spec.startFrame)
                        i=spec.startFrame;
                        framesInPhase=i;
                    end
                    
                    if ischar(strategy) && strcmp(strategy,'cache')
                        numFramesInStim = size(stim)-i;
                    elseif timeIndexed
                        if timedFrames(end)==0
                            numFramesInStim = Inf; % hold last frame, so even in 'cache' mode we are okay
                        else
                            numFramesInStim = sum(timedFrames);
                        end
                    else
                        numFramesInStim = Inf;
                    end
                    
                    isFinalPhase = spec.isFinalPhase;
                    autoTrigger = spec.autoTrigger;
                    
                    % =========================================================================
                    
                    phaseRecords(phaseNum).dynamicDetails=[];
                    phaseRecords(phaseNum).loop = loop;
                    phaseRecords(phaseNum).trigger = trigger;
                    phaseRecords(phaseNum).strategy = strategy;
                    phaseRecords(phaseNum).autoTrigger = autoTrigger;
                    phaseRecords(phaseNum).timeoutLengthInFrames = framesUntilTransition;
                    phaseRecords(phaseNum).floatprecision = floatprecision;
                    phaseRecords(phaseNum).phaseType = phaseType;
                    phaseRecords(phaseNum).phaseLabel = spec.phaseLabel;
                    
                    phaseRecords(phaseNum).responseDetails.startTime = startTime;
                    
                    updatePhase = 0;
                    
                    % =========================================================================
                    
                    %####setStatePins(station,'phase',false);
                    if spec.isStim
                        %####setStatePins(station,'stim',true);
                    end
                    
                    if any(spec.ledON)
                        LEDStatus = getLED(spec);
                        %####setStatePins(station,'LED1',LEDStatus(1));
                        %####if length(LEDStatus)==2, setStatePins(station,'LED2',LEDStatus(2)); end
                    else
                        %####setStatePins(station,'LED1',false);
                        %####setStatePins(station,'LED2',false);
                    end
                    
                end % fininshed with phaseUpdate
                
                timestamps.phaseUpdated=GetSecs;
                doFramePulse=true;
                
                if ~paused
                    % here should be the function that also checks to see if we should assign trialRecords.correct
                    % and trialRecords.response, and also does tm-specific reward checks (nAFC should check to update reward/airpuff
                    % if first frame of a 'reinforced' phase)
                    [tm, trialRecords(trialInd).trialDetails, trialRecords(trialInd).result, spec, rewardSizeULorMS, requestRewardSizeULorMS, ...
                        msPuff, msRewardSound, msPenalty, msPenaltySound, floatprecision, textures, destRect, updateRMThisFrame] = ...
                        tm.updateTrialState(stimManager, subject, trialRecords(trialInd).result, spec, ports, lastPorts, ...
                        targetOptions, requestOptions, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
                        floatprecision, textures, destRect, requestRewardDone, punishLastResponse,compiledRecords);
                    updateRM = updateRM || updateRMThisFrame;
                    
                    if rewardSizeULorMS~=0
                        doRequestReward=false;
                        msRewardOwed=msRewardOwed+rewardSizeULorMS;
                        phaseRecords(phaseNum).proposedRewardDurationMSorUL = rewardSizeULorMS;
                    elseif msPenalty~=0
                        doRequestReward=false;
                        msAirpuffOwed=msAirpuffOwed+msPuff;
                        phaseRecords(phaseNum).proposedAirpuffDuration = msPuff;
                        phaseRecords(phaseNum).proposedPenaltyDurationMSorUL = msPenalty;
                    end
                    framesUntilTransition=spec.framesUntilTransition;
                    stim=spec.stimulus;
                    scaleFactor=spec.scaleFactor;
                    
                    if requestRewardSizeULorMS~=0
                        doRequestReward=true;
                        msRequestRewardOwed=msRequestRewardOwed+requestRewardSizeULorMS;
                        phaseRecords(phaseNum).responseDetails.requestRewardPorts{end+1}=ports;
                        phaseRecords(phaseNum).responseDetails.requestRewardStartTime{end+1}=GetSecs();
                        phaseRecords(phaseNum).responseDetails.requestRewardDurationActual{end+1}=0;
                        
                        lastRequestPorts=ports;
                        playRequestSoundLoop=true;
                        requestRewardDone=true;
                    end
                    
                    lastPorts=ports;
                end
                
                if window>0
                    if ~paused
                        scheduledFrameNum=ceil((GetSecs-firstVBLofPhase)/(framesPerUpdate*ifi)); %could include pessimism about the time it will take to get from here to the flip and how much advance notice flip needs
                        % this will surely have drift errors...
                        % note this does not take pausing into account -- edf thinks we should get rid of pausing
                        
                        switch strategy
                            case {'textureCache','noCache'}
                                [tm, frameIndex, i, done, doFramePulse, didPulse] ...
                                    = tm.updateFrameIndexUsingTextureCache(frameIndexed, loop, trigger, timeIndexed, frameIndex, indexedFrames, size(stim,3), isRequesting, ...
                                    i, frameNum, timedFrames, responseOptions, done, doFramePulse, didPulse, scheduledFrameNum);
                                indexPulse=getIndexPulse(spec,i);

                                switch strategy
                                    case 'textureCache'
                                        tm.drawFrameUsingTextureCache(window, i, frameNum, size(stim,3), lastI, dontclear, textures(i), destRect, ...
                                            filtMode, labelFrames, xOrigTextPos, yTextPos,strategy,floatprecision);
                                    case 'noCache'
                                        tm.drawFrameUsingTextureCache(window, i, frameNum, size(stim,3), lastI, dontclear, squeeze(stim(:,:,i)), destRect, ...
                                            filtMode, labelFrames, xOrigTextPos, yTextPos,strategy,floatprecision);
                                end
                                
                            case 'expert'
                                [doFramePulse, expertCache, phaseRecords(phaseNum).dynamicDetails, textLabel, i, dontclear, indexPulse] ...
                                    = stimManager.drawExpertFrame(stim,i,phaseStartTime,totalFrameNum,window,textLabel,...
                                    destRect,filtMode,expertCache,ifi,scheduledFrameNum,tm.dropFrames,dontclear,...
                                    phaseRecords(phaseNum).dynamicDetails);
                            otherwise
                                sca;
                                keyboard
                                error('unrecognized strategy');
                        end
                        
                        %####setStatePins(station,'index',indexPulse);
                        
                        timestamps.frameDrawn=GetSecs;
                        
                        if frameDropCorner.on
                            Screen('FillRect', window, frameDropCorner.seq(frameDropCorner.ind), frameDropCorner.rect);
                            frameDropCorner.ind=frameDropCorner.ind+1;
                            if frameDropCorner.ind>length(frameDropCorner.seq)
                                frameDropCorner.ind=1;
                            end
                        end
                        
                        timestamps.frameDropCornerDrawn=GetSecs;
                        
                        %text commands are supposed to be last for performance reasons
                        if manual
                            didManual=1;
                        end
                        if window>=0 && showText
                            xTextPos = tm.drawText(window, labelFrames, subID, xOrigTextPos, yTextPos, normBoundsRect, stimID, protocolStr, ...
                                textLabel, trialLabel, i, frameNum, manual, didManual, didAPause, phaseRecords(phaseNum).responseDetails.numMisses, ...
                                phaseRecords(phaseNum).responseDetails.numApparentMisses, phaseInd, spec.stimType,textType);
                        end
                        
                        timestamps.textDrawn=GetSecs;
                        
                    else
                        %do we need to copy previous screen?
                        %Screen('CopyWindow', window, window);
                        if window>=0
                            Screen('FillRect',window)
                            Screen('DrawText',window,'paused (k+p to toggle)',xTextPos,yTextPos,100*ones(1,3));
                        end
                    end
                    
                    [timestamps, headroom(totalFrameNum)] = tm.flipFrameAndDoPulse(window, dontclear, framesPerUpdate, ifi, paused, doFramePulse,station,timestamps);
                    lastI=i;
                    
                    [phaseRecords(phaseNum).responseDetails, timestamps] = ...
                        tm.saveMissedFrameData(phaseRecords(phaseNum).responseDetails, frameNum, timingCheckPct, ifi, timestamps);
                    
                    timestamps.missesRecorded=GetSecs;
                else
%                     
%                     if ~isempty(analogOutput) || window<=0 || strcmp(tm.displayMethod,'LED')
%                         phaseRecords(phaseNum).LEDintermediateTimestamp=GetSecs; %need to preallocate
%                         phaseRecords(phaseNum).intermediateSampsOutput=get(analogOutput,'SamplesOutput'); %need to preallocate
%                         
%                         if ~isempty(framesUntilTransition)
%                             %framesUntilTransition is calculated off of the screen's ifi which is not correct when using LED
%                             framesUntilTransition=framesInPhase+2; %prevent handlePhasedTrialLogic from tripping to next phase
%                         end
%                         
%                         %note this logic is related to updateFrameIndexUsingTextureCache
%                         if ~loop && (get(analogOutput,'SamplesOutput')>=numSamps || ~outputsamplesOK)
%                             if isempty(responseOptions)
%                                 done=1;
%                             end
%                             if ~isempty(framesUntilTransition)
%                                 framesUntilTransition=framesInPhase+1; %cause handlePhasedTrialLogic to trip to next phase
%                             end
%                         end
%                     end
                    
                end
                
                % =========================================================================
                
                if ~isempty(eyeTracker)
                    if ~checkRecording(eyeTracker)
                        sca
                        error('lost tracker connection!')
                    end
                    [gazeEstimates, samples] = getSamples(eyeTracker);
                    % gazeEstimates should be a Nx2 matrix, samples should be Nx43 matrix, totalFrameNum is the frame number we are on
                    numEyeTrackerSamples = size(samples,1);
                    
                    if (totalEyeDataInd+numEyeTrackerSamples)>length(eyeData) %if samples from this frame make us exceed size of eyeData
                        
                        %edf notes that this method is more expensive than necessary -- by expanding the matrix in this way, the old matrix still has to be copied in
                        %instead, consider using a cell array and adding your new allocation chunk as an {end+1} cell with your matrix of nans, then no copying will be necessary
                        %then you can concat all your cells at the end of the trial
                        
                        %  allocateMore
                        newEnd=length(eyeData)+ framesPerAllocationChunk;
                        %             disp(sprintf('did allocation to eyeTrack data; up to %d samples enabled',newEnd))
                        eyeData(end+1:newEnd,:)=nan;
                        eyeDataFrameInds(end+1:newEnd,:)=nan;
                        gaze(end+1:newEnd,:)=nan;
                    end
                    
                    if ~isempty(gazeEstimates) && ~isempty(samples)
                        gaze(totalEyeDataInd:totalEyeDataInd+numEyeTrackerSamples-1,:) = gazeEstimates;
                        eyeData(totalEyeDataInd:totalEyeDataInd+numEyeTrackerSamples-1,:) = samples;
                        eyeDataFrameInds(totalEyeDataInd:totalEyeDataInd+numEyeTrackerSamples-1,:) = totalFrameNum;
                        totalEyeDataInd = totalEyeDataInd + numEyeTrackerSamples;
                    end
                end
                
                timestamps.eyeTrackerDone=GetSecs;
                
                % =========================================================================
                % all trial logic follows
                
                if ~paused
                    ports=readPorts(station);
                end
                doValves=0*ports;
                doPuff=false;
                
                [keyIsDown,secs,keyCode]=KbCheck; % do this check outside of function to save function call overhead
                timestamps.kbCheckDone=GetSecs;
                
                if keyIsDown
                    [didAPause, paused, done, res, doValves, ports, didValves, didHumanResponse, manual, ...
                        doPuff, pressingM, pressingP,timestamps.kbOverhead,timestamps.kbInit,timestamps.kbKDown] ...
                        = tm.handleKeyboard(keyCode, didAPause, paused, done, trialRecords(trialInd).result, doValves, ports, didValves, didHumanResponse, ...
                        manual, doPuff, pressingM, pressingP, originalPriority, priorityLevel, KbConstants);
                    trialRecords(trialInd).result = res; clear res; % because of weird effects when result is empty
                end
                
                timestamps.keyboardDone=GetSecs;
                
                % do stochastic port hits after keyboard so that wont happen if another port already triggered
                if ~paused
                    if ~isempty(autoTrigger) && ~any(ports)
                        for j=1:2:length(autoTrigger)
                            if rand<autoTrigger{j}
                                ports(autoTrigger{j+1}) = 1;
                                stochasticPorts = ports;
                                didStochasticResponse=true; %edf: shouldn't this only be if one was tripped?
                                break;
                            end
                        end
                    end
                end
                
                if ~paused
                    % end of a response
                    if lookForChange && any(ports~=lastPorts) % end of a response
                        phaseRecords(thisResponsePhaseNum).responseDetails.durs{end+1} = GetSecs() - respStart;
                        lookForChange=false;
                        logIt=true;
                        if ~toggleStim % beambreak mode (once request ends, stop showing stim)
                            isRequesting=~isRequesting;
                        end
                        
                        % 1/21/09 - how should we handle tries? - do we count attempts that occur during a phase w/ no port transitions (ie timeout only)?
                        % start of a response
                    elseif any(ports~=lastPorts) && logIt
                        phaseRecords(phaseNum).responseDetails.tries{end+1} = ports;
                        phaseRecords(phaseNum).responseDetails.times{end+1} = GetSecs() - startTime;
                        respStart = GetSecs();
                        playRequestSoundLoop = false;
                        logIt=false;
                        lookForChange=true;
                        thisResponsePhaseNum=phaseNum;
                    end
                end
                
                timestamps.enteringPhaseLogic=GetSecs;
                if ~paused
                    [tm, done, newSpecInd, phaseInd, updatePhase, transitionedByTimeFlag, ...
                        transitionedByPortFlag, trialRecords(trialInd).result, isRequesting, lastSoundsLooped, ...
                        timestamps.logicGotSounds, timestamps.logicSoundsDone, timestamps.logicFramesDone, ...
                        timestamps.logicPortsDone, timestamps.logicRequestingDone, goDirectlyToError] ...
                        = handlePhasedTrialLogic(tm, done, ...
                        ports, lastPorts, station, phaseInd, phaseType, transitionCriterion, framesUntilTransition, numFramesInStim, framesInPhase, isFinalPhase, ...
                        trialRecords(trialInd).trialDetails, trialRecords(trialInd).stimDetails, trialRecords(trialInd).result, ...
                        stimManager, msRewardSound, msPenaltySound, targetOptions, distractorOptions, requestOptions, ...
                        playRequestSoundLoop, isRequesting, soundNames, lastSoundsLooped);
                    % if goDirectlyToError, then reset newSpecInd to the first error phase in stimSpecs
                    if goDirectlyToError
                        newSpecInd=find(strcmp(cellfun(@(x) x.phaseType, stimSpecs,'UniformOutput',false),'reinforced'));
                    end
                    
                    
                end
                timestamps.phaseLogicDone=GetSecs;
                
                % =========================================================================
                
                
                
                % =========================================================================
                % reward handling
                % calculate elapsed time since last loop, and decide whether to start/stop reward
                if isempty(thisRewardPhaseNum)
                    % default to this phase's phaseRecord, but we will hard-set this during a rStart, so that
                    % the last loop of a reward gets added to the correct N-th phaseRecord, instead of the (N+1)th
                    % this happens b/c the phaseNum gets updated before reward stuff...
                    thisRewardPhaseNum = phaseNum;
                end
                
                if ~isempty(lastRewardTime) && rewardCurrentlyOn
                    rewardCheckTime = GetSecs();
                    elapsedTime = rewardCheckTime - lastRewardTime;
                    if ~doRequestReward % this was a normal reward, log it
                        msRewardOwed = msRewardOwed - elapsedTime*1000.0;
                        phaseRecords(thisRewardPhaseNum).actualRewardDurationMSorUL = phaseRecords(thisRewardPhaseNum).actualRewardDurationMSorUL + elapsedTime*1000.0;
                    else % this was a request reward, dont log it
                        msRequestRewardOwed = msRequestRewardOwed - elapsedTime*1000.0;
                        phaseRecords(thisRewardPhaseNum).responseDetails.requestRewardDurationActual{end}=phaseRecords(thisRewardPhaseNum).responseDetails.requestRewardDurationActual{end}+elapsedTime*1000.0;
                    end
                end
                lastRewardTime = GetSecs();
                rStart = msRewardOwed+msRequestRewardOwed > 0.0 && ~rewardCurrentlyOn;
                rStop = msRewardOwed+msRequestRewardOwed <= 0.0 && rewardCurrentlyOn;
                
                if rStart
                    thisRewardPhaseNum=phaseNum;
                    % used to properly put reward logging data in their respective phaseRecords
                    % default is current phase, but will set after rStart
                    stochasticPorts = tm.forceRewards(stochasticPorts);
                end
                
                if rStop % if stop, then reset owed time to zero
                    msRewardOwed=0;
                    msRequestRewardOwed=0;
                end
                currentValveStates=getValves(station);
                
                % =========================================================================
                % if any doValves, override this stuff
                % newValveState will be used to keep track of doValves stuff - figure out server-based use later
                if any(doValves~=newValveState)
                    [newValveState, phaseRecords(phaseNum).valveErrorDetails]=...
                        setAndCheckValves(station,doValves,currentValveStates,phaseRecords(phaseNum).valveErrorDetails,GetSecs,'doValves');
                else
                    if rStart || rStop
                        rewardValves=zeros(1,station.numPorts);
                        % we give the reward at whatever port is specified by the current phase (weird...fix later?)
                        % the default if the current phase does not have a transition port is the requestOptions (input to stimOGL)
                        % 1/29/09 - fix, but for now rewardValves is jsut wahtever the current port triggered is (this works for now..)
                        if strcmp(class(ports),'double') %happens on osx, why?
                            ports=logical(ports);
                        end
                        rewardValves(ports|stochasticPorts)=1;
                        
                        rewardValves=logical(rewardValves);
                        
                        
                        
                        if length(rewardValves) ~= 3
                            error('rewardValves has %d and currentValveStates has %d with port = %d', length(rewardValves), length(currentValveStates), port);
                        end
                        
                        if rStart
                            rewardValves = tm.forceRewards(rewardValves); % used in the reinforced autopilot state
                            rewardCurrentlyOn = true;
                            [currentValveStates, phaseRecords(thisRewardPhaseNum).valveErrorDetails]=...
                                setAndCheckValves(station,rewardValves,currentValveStates,phaseRecords(thisRewardPhaseNum).valveErrorDetails,lastRewardTime,'correct reward open');
                        elseif rStop
                            rewardCurrentlyOn = false;
                            [currentValveStates, phaseRecords(thisRewardPhaseNum).valveErrorDetails]=...
                                setAndCheckValves(station,zeros(1,station.numPorts),currentValveStates,phaseRecords(thisRewardPhaseNum).valveErrorDetails,lastRewardTime,'correct reward close');
                            % also add the additional time that reward was on from rewardCheckTime to now
                            rewardCheckToValveCloseTime = GetSecs() - rewardCheckTime;
                            %                         rewardCheckToValveCloseTime
                            if ~doRequestReward
                                phaseRecords(thisRewardPhaseNum).actualRewardDurationMSorUL = phaseRecords(thisRewardPhaseNum).actualRewardDurationMSorUL + rewardCheckToValveCloseTime*1000.0;
                                %                             phaseRecords(thisRewardPhaseNum).actualRewardDurationMSorUL
                                %                             'stopping normal reward'
                            else
                                phaseRecords(thisRewardPhaseNum).responseDetails.requestRewardDurationActual{end}=phaseRecords(thisRewardPhaseNum).responseDetails.requestRewardDurationActual{end}+rewardCheckToValveCloseTime*1000.0;
                                %                             'stopping request reward'
                            end
                            % newValveState=doValves|rewardValves; % this shouldnt be used for now...figure out later...
                        else
                            error('has to be either start or stop - should not be here');
                        end
                    end
                    
                end % end valves
                
                timestamps.rewardDone=GetSecs;
                
%                 % also do datanet handling here
%                 % this should only handle 'server Quit' commands for now.... (other stuff is caught by doTrial/bootstrap)
%                 if ~isempty(station.datanet)
%                     [~, Quit] = handleCommands(station.datanet,[]);
%                 end
%                 
%                 timestamps.serverCommDone=GetSecs;
                
                % =========================================================================
                % airpuff ####
%                 if isempty(thisAirpuffPhaseNum)
%                     thisAirpuffPhaseNum=phaseNum;
%                 end
%                 
%                 if ~isempty(lastAirpuffTime) && airpuffOn
%                     airpuffCheckTime = GetSecs();
%                     elapsedTime = airpuffCheckTime - lastAirpuffTime;
%                     msAirpuffOwed = msAirpuffOwed - elapsedTime*1000.0;
%                     phaseRecords(thisAirpuffPhaseNum).actualAirpuffDuration = phaseRecords(thisAirpuffPhaseNum).actualAirpuffDuration + elapsedTime*1000.0;
%                 end
%                 
%                 aStart = msAirpuffOwed > 0 && ~airpuffOn;
%                 aStop = msAirpuffOwed <= 0 && airpuffOn; % msAirpuffOwed<=0 also catches doPuff==false, and will stop airpuff when k+a is lifted
%                 if aStart || doPuff
%                     thisAirpuffPhaseNum = phaseNum; % set default airpuff phase num
%                     setPuff(station, true);
%                     airpuffOn = true;
%                 elseif aStop
%                     doPuff = false;
%                     airpuffOn = false;
%                     setPuff(station, false);
%                     airpuffCheckToSetPuffTime = GetSecs() - airpuffCheckTime; % time from the airpuff check to after setPuff returns
%                     % increase actualAirpuffDuration by this 'lag' time...
%                     phaseRecords(thisAirpuffPhaseNum).actualAirpuffDuration = phaseRecords(thisAirpuffPhaseNum).actualAirpuffDuration + airpuffCheckToSetPuffTime*1000.0;
%                 end
%                 lastAirpuffTime = GetSecs();
                
                % =========================================================================
                
                if updatePhase
                    phaseRecords(phaseNum).transitionedByPortResponse = transitionedByPortFlag;
                    phaseRecords(phaseNum).transitionedByTimeout = transitionedByTimeFlag;
                    phaseRecords(phaseNum).containedManualPokes = didManual;
                    phaseRecords(phaseNum).leftWithManualPokingOn = manual;
                    phaseRecords(phaseNum).containedAPause = didAPause;
                    phaseRecords(phaseNum).containedForcedRewards = didValves;
                    phaseRecords(phaseNum).didHumanResponse = didHumanResponse;
                    phaseRecords(phaseNum).didStochasticResponse = didStochasticResponse;
                    
                    phaseRecords(phaseNum).responseDetails.totalFrames = frameNum;
                    % how do we only clear the textures from THIS phase (since all textures for all phases are precached....)
                    % close all textures from this phase if in non-expert mode
                    %         if ~strcmp(strategy,'expert')
                    %             Screen('Close');
                    %         else
                    %             expertCleanUp(stimManager);
                    %         end
                    containedExpertPhase=strcmp(strategy,'expert') || containedExpertPhase;
                end
                
                timestamps.phaseRecordsDone=GetSecs;
                
                if ~paused
                    framesInPhase = framesInPhase + 1; % moved from handlePhasedTrialLogic to prevent copy on write
                    
                    phaseInd = newSpecInd;
                    frameNum = frameNum + 1;
                    totalFrameNum = totalFrameNum + 1;
                    framesSinceKbInput = framesSinceKbInput + 1;
                end
                timestamps.loopEnd=GetSecs;
            end
            
            securePins(station);
            
            trialRecords(trialInd).phaseRecords=phaseRecords;
            % per-trial records, collected from per-phase stuff
            trialRecords(trialInd).containedAPause=any([phaseRecords.containedAPause]);
            trialRecords(trialInd).didHumanResponse=any([phaseRecords.didHumanResponse]);
            trialRecords(trialInd).containedForcedRewards=any([phaseRecords.containedForcedRewards]);
            trialRecords(trialInd).didStochasticResponse=any([phaseRecords.didStochasticResponse]);
            trialRecords(trialInd).containedManualPokes=didManual;
            trialRecords(trialInd).leftWithManualPokingOn=manual;
            
            if ~isempty(analogOutput)
                evts=showdaqevents(analogOutput);
                if ~isempty(evts)
                    evts
                end
                
                stop(analogOutput);
                delete(analogOutput); %should pass back to caller and preserve for next trial so intertrial works and can avoid contruction costs
            end
            
            
            if ~containedExpertPhase
                Screen('Close'); %leaving off second argument closes all textures but leaves windows open
            else
                %maybe once this was per phase, but now its per trial
                expertPostTrialCleanUp(stimManager);
            end
            
            
            Priority(originalPriority);
            
            plotHeadroom=false;
            if plotHeadroom
                headroomfig=figure;
                plot(headroom)
                title('headroom')
            end
            
            plotGaze=false;
            if plotGaze
                gazefig=figure;
                subplot(2,1,1)
                plot(gaze)
                title('gaze')
                legend({'gaze_x','gaze_y'})
                subplot(2,1,2)
                plot(eyeData(:,27:30))
                legend({'raw_pupil_x','raw_pupil_y','raw_cr_x','raw_cr_y'})
            end
            
            if plotGaze || plotHeadroom
                fprintf('hit a key to close headroom and/or gaze figures')
                pause
                if plotHeadroom
                    close(headroomfig)
                end
                if plotGaze
                    close(gazefig)
                end
            end
        end % end function
        
        function [responseDetails, timestamps] = ...
                saveMissedFrameData(tm, responseDetails, frameNum, timingCheckPct, ifi, timestamps)
            
            debug=false;
            type='';
            thisIFI=timestamps.vbl-timestamps.lastFrameTime;
            
            if timestamps.missed>0
                type='caught';
                responseDetails.numMisses=responseDetails.numMisses+1;
                
                if  responseDetails.numMisses<responseDetails.numDetailedDrops
                    
                    responseDetails.misses(responseDetails.numMisses)=frameNum;
                    responseDetails.afterMissTimes(responseDetails.numMisses)=GetSecs();
                    responseDetails.missIFIs(responseDetails.numMisses)=thisIFI;
                    if tm.saveDetailedFramedrops
                        responseDetails.missTimestamps(responseDetails.numMisses)=timestamps; %need to figure out: Error: Subscripted assignment between dissimilar structures
                    end
                else
                    responseDetails.numUnsavedMisses=responseDetails.numUnsavedMisses+1;
                end
                
            else
                thisIFIErrorPct = abs(1-thisIFI/ifi);
                if  thisIFIErrorPct > timingCheckPct
                    type='unnoticed';
                    
                    responseDetails.numApparentMisses=responseDetails.numApparentMisses+1;
                    
                    if responseDetails.numApparentMisses<responseDetails.numDetailedDrops
                        responseDetails.apparentMisses(responseDetails.numApparentMisses)=frameNum;
                        responseDetails.afterApparentMissTimes(responseDetails.numApparentMisses)=GetSecs();
                        responseDetails.apparentMissIFIs(responseDetails.numApparentMisses)=thisIFI;
                        if tm.saveDetailedFramedrops
                            responseDetails.apparentMissTimestamps(responseDetails.numApparentMisses)=timestamps; %need to figure out: Error: Subscripted assignment between dissimilar structures
                        end
                    else
                        responseDetails.numUnsavedApparentMisses=responseDetails.numUnsavedApparentMisses+1;
                    end
                    
                end
            end
            
            if ~strcmp(type,'') && debug
                printDroppedFrameReport(1,timestamps,frameNum,thisIFI,ifi,type); %fid=1 is stdout (screen)
            end
            
            timestamps.lastFrameTime=timestamps.vbl;
            timestamps.prevPostFlipPulse=timestamps.postFlipPulse;
            
            
        end % end function
        
        function frameDropCorner = setCLUTandFrameDropCorner(tm, window, LUT, frameDropCorner)
            
            [scrWidth, scrHeight]=Screen('WindowSize', 0);
            
            
            if window>=0
                scrRect = Screen('Rect', 0);
                scrLeft = scrRect(1); %am i retarted?  why isn't [scrLeft scrTop scrRight scrBottom]=Screen('Rect', window); working?  deal doesn't work
                scrTop = scrRect(2);
                scrRight = scrRect(3);
                scrBottom = scrRect(4);
                scrWidth= scrRight-scrLeft;
                scrHeight=scrBottom-scrTop;
            else
                scrLeft = 0;
                scrTop = 0;
            end
            
            frameDropCorner.left  =scrLeft               + scrWidth *(frameDropCorner.loc(2) - frameDropCorner.size(2)/2);
            frameDropCorner.right =frameDropCorner.left  + scrWidth *frameDropCorner.size(2);
            frameDropCorner.top   =scrTop                + scrHeight*(frameDropCorner.loc(1) - frameDropCorner.size(1)/2);
            frameDropCorner.bottom=frameDropCorner.top   + scrHeight*frameDropCorner.size(1);
            frameDropCorner.rect=[frameDropCorner.left frameDropCorner.top frameDropCorner.right frameDropCorner.bottom];
            
            [~, ~, reallutsize] = Screen('ReadNormalizedGammaTable', 0);
            
            if isreal(LUT) && (all(size(LUT)==[256 3]) || all(size(LUT)==[1024 3]))
                if any(LUT(:)>1) || any(LUT(:)<0)
                    error('LUT values must be normalized values between 0 and 1')
                end
                try
                    oldCLUT = Screen('LoadNormalizedGammaTable', 0, LUT,0); %apparently it's ok to use a window ptr instead of a screen ptr, despite the docs
                catch ex
                    ex.message
                    sca;
                    error('couldnt set clut')
                end
                currentCLUT = Screen('ReadNormalizedGammaTable', 0);
                
                try
                if all(all(abs(currentCLUT-LUT)<0.00001))
                    %pass
                else
                    disp(oldCLUT);
                    disp(currentCLUT);
                    disp(LUT);             %requested
                    disp(currentCLUT-LUT); %error
                    error('the LUT is not what you think it is')
                end
                catch
                    sca;
                    keyboard
                end
                switch tm.frameDropCorner{1}
                    case 'off'
                    case 'flickerRamp'
                        inds=findClosestInds(tm.frameDropCorner{2},mean(currentCLUT'));
                        frameDropCorner.seq=size(currentCLUT,1):-1:inds(1);
                        frameDropCorner.seq(2,:)=inds(2);
                        frameDropCorner.seq=frameDropCorner.seq(:); %interleave them
                    case 'sequence'
                        frameDropCorner.seq=findClosestInds(tm.frameDropCorner{2},mean(currentCLUT'));
                    otherwise
                        error('shouldn''t happen')
                end
            else
                reallutsize
                error('LUT must be real 256 X 3 matrix')
            end
            
        end % end function
        
        function [tm, quit, trialRecords, eyeData, eyeDataFrameInds, gaze, station, updateRM] ...
                = stimOGL(tm, stimSpecs, startingStimSpecInd, stimManager, LUT, targetOptions, distractorOptions, requestOptions, interTrialLuminance, ...
                station, manual,timingCheckPct,textLabel,rn,subID,stimID,protocolStr,trialLabel,eyeTracker,trialRecords,compiledRecords,subject)
            % This function gets ready for stimulus presentation by precaching textures (unless expert mode), and setting up some other small stuff.
            % All of the actual real-time looping is handled by runRealTimeLoop.
            
            
            verbose = false;
            responseOptions = union(targetOptions, distractorOptions);
            
            originalPriority = Priority;
            
            %ListenChar(2);
            %FlushEvents('keyDown');
            %edf moved these to station.doTrials() so that we don't get garbage sent to matlab windows from between-trial keypresses.
            %however, whether they're here or there, we still seem to get garbage -- figure out why!
            %something wrong with flushevents?
            
            phaseData = cell(1,length(stimSpecs));
            
            window=station.window;
                
            ifi=station.ifi;
            
            frDropCorner.size=[.05 .05];
            frDropCorner.loc=[1 0];
            if ~isempty(tm.frameDropCorner)
                frDropCorner.on=~strcmp(tm.frameDropCorner{1},'off');
            else
                tm.frameDropCorner{1}='off';
            end
            frDropCorner.ind=1;
            
            try
                frDropCorner = setCLUTandFrameDropCorner(tm, window, LUT, frDropCorner);
                
                for i=1:length(stimSpecs)
                    spec = stimSpecs{i};
                    stim = spec.stimulus;
                    type = spec.stimType;
                    metaPixelSize = spec.scaleFactor;
                    framesUntilTransition = spec.framesUntilTransition;

                    [phaseData{i}.loop,phaseData{i}.trigger, phaseData{i}.frameIndexed ,phaseData{i}.timeIndexed, ...
                        phaseData{i}.indexedFrames, phaseData{i}.timedFrames, phaseData{i}.strategy, phaseData{i}.toggleStim] = ...
                        tm.determineStrategy(stim, type, responseOptions, framesUntilTransition);
                    
                    [phaseData{i}.floatprecision, stim] = tm.determineColorPrecision(stim, phaseData{i}.strategy);
                    stimSpecs{i}=setStim(spec,stim);
                    
                    if window>0
                        phaseData{i}.destRect = tm.determineDestRect(window, metaPixelSize, stim, phaseData{i}.strategy);
                        
                        phaseData{i}.textures = tm.cacheTextures(phaseData{i}.strategy, stim, window, phaseData{i}.floatprecision);
                    else
                        
                        phaseData{i}.destRect=[];
                        phaseData{i}.textures=[];
                        
                    end
                end
                
                [interTrialPrecision, interTrialLuminance] = tm.determineColorPrecision(interTrialLuminance, 'static');
                
                [tm, quit, trialRecords, eyeData, eyeDataFrameInds, gaze, ~, station, updateRM] ...
                    = runRealTimeLoop(tm, subject, window, ifi, stimSpecs, startingStimSpecInd, phaseData, stimManager, ...
                    targetOptions, distractorOptions, requestOptions, interTrialLuminance, interTrialPrecision, ...
                    station, manual,timingCheckPct,textLabel,rn,subID,stimID,protocolStr,trialLabel,...
                    originalPriority,eyeTracker,frDropCorner,trialRecords,compiledRecords);
                
            catch ex
                disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                
                securePins(station);
                
                Screen('CloseAll');
                Priority(originalPriority);
                ShowCursor(0);
                FlushEvents('mouseUp','mouseDown','keyDown','autoKey','update');
                ListenChar(0);
                
                if ispc
                    daqreset;
                end
                
                if ~isempty(eyeTracker)
                    cleanUp(eyeTracker);
                end
                
                trialRecords(end).response=sprintf('error_in_StimOGL: %s',ex.message);
                
                rethrow(ex);
            end
        end
           
        function [tm, frameIndex, i, done, doFramePulse, didPulse] ...
                = updateFrameIndexUsingTextureCache(tm, frameIndexed, loop, trigger, timeIndexed, frameIndex, indexedFrames,...
                stimSize, isRequesting, ...
                i, frameNum, timedFrames, responseOptions, done, doFramePulse, didPulse, scheduledFrameNum)
            
            % This method calculates the correct frame index (which frame of the movie to play at the given loop)
            
            if frameIndexed
                if loop
                    if tm.dropFrames
                        frameIndex = mod(scheduledFrameNum,length(indexedFrames));
                        if frameIndex==0
                            frameIndex=length(indexedFrames);
                        end
                    else
                        % frameIndex = mod(frameIndex,length(indexedFrames)-1)+1; %02.03.09 edf notices this has same problem as loop condition (next). changing to:
                        frameIndex = mod(frameIndex,length(indexedFrames))+1;
                    end
                else
                    if tm.dropFrames
                        frameIndex = min(length(indexedFrames),scheduledFrameNum);
                    else
                        frameIndex = min(length(indexedFrames),frameIndex+1);
                    end
                end
                i = indexedFrames(frameIndex);
            elseif loop
                if tm.dropFrames
                    i = mod(scheduledFrameNum,stimSize);
                    if i==0
                        i=stimSize;
                    end
                else
                    % i = mod(i,stimSize-1)+1; %original was incorrect!  never gets to last frame
                    
                    % 8/16/08 - changed to:
                    %     i = mod(i+1,stimSize);
                    %     if i == 0
                    %         i = stimSize;
                    %     end
                    
                    % 02.03.09 edf changing to:
                    i = mod(i,stimSize)+1;
                end
                
            elseif trigger
                if isRequesting
                    i=1;
                else
                    i=2;
                end
                
            elseif timeIndexed
                
                %should precache cumsum(double(timedFrames))
                if tm.dropFrames
                    i=min(find(scheduledFrameNum<=cumsum(double(timedFrames))));
                else
                    i=min(find(frameNum<=cumsum(double(timedFrames))));
                end
                
                if isempty(i)  %if we have passed the last stim frame
                    i=length(timedFrames);  %hold the last frame if the last frame duration specified was zero
                    if timedFrames(end)
                        error('currently broken')
                        
                        i=i+1;      %otherwise move on to the finalScreenLuminance blank screen -- this will probably error on the phased architecture, need to advance phase, but it's too late by this point?
                        % from fan:
                        % > i think this would have to be handled by the framesUntilTransition timeout.
                        % > it would be up to the user to correctly pass in a framesUntilTransition
                        % > argument of 600 frames if they vector of timedFrames sums up to 600 and does
                        % > not end in zero. phaseify could automatically handle this, but new calcStims
                        % > would have to be aware of this.
                        
                    end
                end
                
            else
                
                if tm.dropFrames
                    i=min(scheduledFrameNum,stimSize);
                else
                    i=min(i+1,stimSize);
                end
                
                if isempty(responseOptions) && i==stimSize
                    done=1;
                end
                
                if i==stimSize && didPulse
                    doFramePulse=0;
                end
                didPulse=1;
            end
            
        end
        
        function checkPortLogic(tm,targetPorts,distractorPorts,st)
            if (isempty(targetPorts) || isvector(targetPorts))...
                    && (isempty(distractorPorts) || isvector(distractorPorts))
                
                portUnion=[targetPorts distractorPorts];
                if length(unique(portUnion))~=length(portUnion) ||...
                        any(~ismember(portUnion, tm.getResponsePorts(st.numPorts)))
                    error('targetPorts and distractorPorts must be disjoint, contain no duplicates, and subsets of responsePorts')
                end
            else
                error('targetPorts and distractorPorts must be row vectors')
            end
        end
    end
    
    methods (Static)
        function out = requiredSoundNames
            out = {'correctSound','keepGoingSound','trySomethingElseSound','wrongSound','trialStartSound'};
        end
        
        function out=stationOKForTrialManager(s)
            validateattributes(s,{'standardVisionBehaviorStation','standardOSXStation'},{'nonempty'});
            out = s.numPorts>=3;
        end
        
        function out=boxOKForTrialManager(b,r)
            validateattributes(b,{'box'},{'nonempty'});
            validateattributes(r,{'BCore'},{'nonempty'});
            
            out=false;
            
            stations=r.getStationsForBoxID(b.id);
            for i=1:length(stations)
                if trialManager.stationOKForTrialManager(stations(i))
                    out=true;
                end
            end
        end
        
        function out = checkPorts(varargin)
            % trialManager does nothing particularly special here
            out=true;
        end
        
        function out=getResponsePorts(totalPorts)
            out=1:totalPorts;
        end
        
        function textures = cacheTextures(strategy, stim, window, floatprecision)
            if ~(ischar(strategy) && strcmp(strategy,'expert')) && (floatprecision~=0 || ~strcmp(class(stim),'uint8'))
                error('expects floatprecision to be 0 and stim to be uint8 so that maketexture is fast')
            end
            
            textures=[];
            
            switch strategy
                case 'textureCache'
                    %load all frames into VRAM
                    
                    if ~isempty(stim) % necessary because size([],3)==1 stupidly enough
                        textures=zeros(1,size(stim,3));
                        for i=1:size(stim,3)
                            if window>=0
                                textures(i)=Screen('MakeTexture', window, squeeze(stim(:,:,i)),0,0,floatprecision); %need floatprecision=0 for remotedesktop
                            end
                        end
                    end
                case 'noCache'
                    %pass
                case 'expert'
                    % no caching of textures should happen
                otherwise
                    error('unrecognized strategy')
            end
            
        end
        
        function [floatprecision, stim] = determineColorPrecision(stim, strategy)
            
            if ~isempty(strategy) && strcmp(strategy, 'expert')
                floatprecision = []; % no default floatprecision for expert mode - override during drawExpertFrame or will throw error
            else
                floatprecision=0;
                if isreal(stim)
                    switch class(stim)
                        case {'double','single'}
                            if any(stim(:)>1) || any(stim(:)<0)
                                error('stim had elements <0 or >1 ')
                            else
                                floatprecision=1;%will tell maketexture to use 0.0-1.0 format with 16bpc precision (2 would do 32bpc)
                            end
                            
                            %maketexture barfs on singles
                            if strcmp(class(stim),'single')
                                stim=double(stim);
                            end
                            
                        case 'uint8'
                            %do nothing
                        case 'uint16'
                            stim=single(stim)/intmax('uint16');
                            floatprecision=1;
                        case 'logical'
                            stim=uint8(stim)*intmax('uint8'); %force to 8 bit
                        otherwise
                            error('unexpected stim variable class; currently stimOGL expects double, single, unit8, uint16, or logical')
                    end
                else
                    stim
                    class(stim)
                    error('stim  must be real')
                end
                
                if floatprecision ~=0 || ~strcmp(class(stim),'uint8')
                    %convert stim/floatprecision to uint8 so when drawFrameUsingTextureCache calls maketexture it is fast
                    %(especially when strategy is noCache and we make each texture during each frame)
                    floatprecision=0;
                    warning('off','MATLAB:intConvertNonIntVal')
                    stim=uint8(stim*double(intmax('uint8')));
                    warning('on','MATLAB:intConvertNonIntVal')
                end
            end
        end
        
        function destRect = determineDestRect(window, metaPixelSize, stim, strategy)
            
            [scrWidth, scrHeight]=Screen('WindowSize', window);
            
            if ~isempty(strategy) && strcmp(strategy, 'expert')
                stimheight = stim.height;
                stimwidth = stim.width;
            else
                stimheight=size(stim,1);
                stimwidth=size(stim,2);
            end
            
            if metaPixelSize == 0
                scaleFactor = [scrHeight scrWidth]./[stimheight stimwidth];
            elseif length(metaPixelSize)==2 && all(metaPixelSize)>0
                scaleFactor = metaPixelSize;
            elseif isempty(metaPixelSize)
                % empty only for 'reinforced' phases, in which case we dont care what destRect is, since it will get overriden anyways
                % during updateTrialState(tm)
                scaleFactor = [1 1];
            else
                error('trialManager:determineDestRect:incorrectValue','bad metaPixelSize argument')
            end
            if any(scaleFactor.*[stimheight stimwidth]>[scrHeight scrWidth])
                error('trialManager:determineDestRect:incorrectValue','metaPixelSize is too large');
            end
            height = scaleFactor(1)*stimheight;
            width = scaleFactor(2)*stimwidth;
            
            if window>=0
                scrRect = Screen('Rect', window);
                scrLeft = scrRect(1); %am i retarted?  why isn't [scrLeft scrTop scrRight scrBottom]=Screen('Rect', window); working?  deal doesn't work
                scrTop = scrRect(2);
                scrRight = scrRect(3);
                scrBottom = scrRect(4);
                scrWidth= scrRight-scrLeft;
                scrHeight=scrBottom-scrTop;
            else
                scrLeft = 0;
                scrTop = 0;
                scrRight = scrWidth;
                scrBottom = scrHeight;
            end
            destRect = round([(scrWidth/2)-(width/2) (scrHeight/2)-(height/2) (scrWidth/2)+(width/2) (scrHeight/2)+(height/2)]); %[left top right bottom]
        end
        
        function validateStimSpecs(stimSpecs)
            for i=1:length(stimSpecs)
                spec = stimSpecs{i};
                cr = spec.transitions;
                fr = spec.framesUntilTransition;
                stimType = spec.stimType;
                
                % if expert mode, check that the stim is a struct with the following fields:
                %   floatprecision
                %   height
                %   width
                if ischar(stimType) && strcmp(stimType,'expert')
                    s=spec.stimulus;
                    if isstruct(s) && isfield(s,'height') && isfield(s,'width')
                        % pass
                    elseif isa(s,'stimManager')
                        % pass for now
                    else
                        sca;
                        keyboard
                        error('in ''expert'' mode, stim must be a struct with fields ''height'' and ''width''');
                    end
                end
                
                if strcmp(cr{1}, 'none') && (isempty(fr) || (isscalar(fr) && fr<=0))
                    error('must have a transition port set or a transition by timeout');
                end
            end
        end
        
        function rewardValves = forceRewards(rewardValves)
            %pass
        end
        
        function [done, quit, valveErrorDetail, serverValveStates, serverValveChange, response, newValveState, requestRewardDone, requestRewardOpenCmdDone] ...
                = handleServerCommands(rn, done, quit, requestRewardStarted, requestRewardStartLogged, requestRewardOpenCmdDone, ...
                requestRewardDone, station, ports, serverValveStates, doValves, response)
            
            valveErrorDetail=[];
            serverValveChange = false;
            
            if ~isConnected(rn)
                done=true; %should this also set quit?
                quit=true; % 7/1/09 - also set quit (copied from v1.0.1)
            end
            
            constants=getConstants(rn);
            
            %serverValveStates=currentValveState; %what was the purpose of this line?  serverValveStates should only be changed by SET_VALVES_CMD
            %needed to remove, cuz was causing keyboard control to make valves stick open
            
            while commandsAvailable(rn,constants.priorities.IMMEDIATE_PRIORITY) && ~done && ~quit
                %logwrite('handling IMMEDIATE priority command in stimOGL');
                if ~isConnected(rn)
                    done=true;%should this also set quit?
                    quit=true; % 7/1/09 - also set quit (copied from v1.0.1)
                end
                com=getNextCommand(rn,constants.priorities.IMMEDIATE_PRIORITY);
                if ~isempty(com)
                    [good cmd args]=validateCommand(rn,com);
                    %logwrite(sprintf('command is %d',cmd));
                    if good
                        switch cmd
                            
                            case constants.serverToStationCommands.S_SET_VALVES_CMD
                                isPrime=args{2};
                                if isPrime
                                    if requestRewardStarted && ~requestRewardDone
                                        quit=sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'stimOGL received priming S_SET_VALVES_CMD while a non-priming request reward was unfinished');
                                    else
                                        timeout=-1;
                                        [quit valveErrorDetail]=clientAcceptReward(rn,...
                                            com,...
                                            station,...
                                            timeout,...
                                            valveStart,...
                                            requestedValveState,...
                                            [],...
                                            isPrime);
                                        if quit
                                            done=true;
                                        end
                                    end
                                else
                                    if all(size(ports)==size(args{1}))
                                        
                                        serverValveStates=args{1};
                                        serverValveChange=true;
                                        
                                        if requestRewardStarted && requestRewardStartLogged && ~requestRewardDone
                                            if requestRewardOpenCmdDone
                                                if all(~serverValveStates)
                                                    requestRewardDone=true;
                                                else
                                                    quit=sendError(rn,com,constants.errors.CORRUPT_STATE_SENT,'stimOGL received S_SET_VALVES_CMD for closing request reward but not all valves were indicated to be closed');
                                                end
                                            else
                                                if all(serverValveStates==requestRewardPorts)
                                                    requestRewardOpenCmdDone=true;
                                                else
                                                    quit=sendError(rn,com,constants.errors.CORRUPT_STATE_SENT,'stimOGL received S_SET_VALVES_CMD for opening request reward but wrong valves were indicated to be opened');
                                                end
                                            end
                                        else
                                            quit=sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'stimOGL received unexpected non-priming S_SET_VALVES_CMD');
                                        end
                                    else
                                        quit=sendError(rn,com,constants.errors.CORRUPT_STATE_SENT,'stimOGL received inappropriately sized S_SET_VALVES_CMD arg');
                                    end
                                end
                                
                            case constants.serverToStationCommands.S_REWARD_COMPLETE_CMD
                                if requestRewardDone
                                    quit=sendAcknowledge(rn,com);
                                else
                                    if requestRewardStarted
                                        quit=sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'client received S_REWARD_COMPLETE_CMD apparently not preceeded by open and close S_SET_VALVES_CMD''s');
                                    else
                                        quit=sendError(rn,com,constants.errors.BAD_STATE_FOR_COMMAND,'client received S_REWARD_COMPLETE_CMD not preceeded by C_REWARD_CMD (MID_TRIAL)');
                                    end
                                end
                            otherwise
                                %the following lines referred to 'done' rather than 'quit' -- this is the bug that leads to the 'i am the king' bug?
                                quit=clientHandleVerifiedCommand(rn,com,cmd,args,constants.statuses.MID_TRIAL);
                                if quit
                                    response='server kill';
                                end
                        end
                    end
                end
            end
            newValveState=doValves|serverValveStates;
            
        end
        
        % testing methods
        function testStimOGL() %laboratory for finding and fixing framedrops - call like testStimOGL(trialManager)
            
            %any of the following will cause frame drops (just on entering new code blocks) on the first subsequent run, but not runs thereafter:
            %clear java, clear classes, clear all, clear mex (NOT clear Screen)
            %each of these causes the code to be reinterpreted
            %note that this is what setupenvironment does!
            %mlock protects a file from all of these except clear classes (and sometimes clear functions?) -- but you have to unlock it to read in changes!
            
            %setupEnvironment
            clear Screen
            clc
            
            try
                [sm, tm, st] = trialManager.setupObjects();
                
                st=startPTB(st);
                
                resolutions=st.resolutions;
                
                [tm.soundMgr, ~]=cacheSounds(tm.soundMgr,st);
                
                [sm, ...
                    ~, ...
                    resInd, ...
                    stim, ...
                    LUT, ...
                    scaleFactor, ...
                    type, ...
                    targetPorts, ...
                    distractorPorts, ...
                    ~, ...
                    interTrialLuminance, ...
                    text]= ...
                    calcStim(sm, ...
                    class(tm), ...
                    resolutions, ...
                    getDisplaySize(st), ...
                    getLUTbits(st), ...
                    getResponsePorts(tm,getNumPorts(st)), ...
                    getNumPorts(st), ...
                    []);
                
                [st,~]=setResolution(st,resolutions(resInd));
                
                stimOGL( ...
                    tm, ...
                    stim, ...
                    [], ...
                    LUT, ...
                    type, ...
                    scaleFactor, ...
                    union(targetPorts, distractorPorts), ...
                    getRequestPorts(tm, getNumPorts(st)), ...
                    interTrialLuminance, ...
                    st, ...
                    0, ...
                    1, ...
                    .1, ... % 10% should be ~1 ms of acceptable frametime error
                    0,text,[],'dummy',class(sm),'dummyProtocol(1m:1a) step:1/1','session:1 trial:1 (1)',tm.eyeTracker,0);
                
                st=stopPTB(st);
            catch ex
                disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                Screen('CloseAll');
                Priority(0);
                ShowCursor(0);
                ListenChar(0);
                clear Screen
            end
        end
        
        function [sm, tm, st] = setupObjects()
            st=makeDummyStation();
            
            sm=makeStandardSoundManager();
            
            rewardSizeULorMS        =50;
            msPenalty               =1000;
            fractionOpenTimeSoundIsOn=1;
            fractionPenaltySoundIsOn=1;
            scalar=1;
            msAirpuff=msPenalty;
            
            constantRewards=constantReinforcement(rewardSizeULorMS,msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msAirpuff);
            
            msFlushDuration         =1000;
            msMinimumPokeDuration   =10;
            msMinimumClearDuration  =10;
            
            requestRewardSizeULorMS=10;
            percentCorrectionTrials=.5;
            msResponseTimeLimit=0;
            pokeToRequestStim=true;
            maintainPokeToMaintainStim=true;
            msMaximumStimPresentationDuration=0;
            maximumNumberStimPresentations=0;
            doMask=false;
            
            tm=nAFC(msFlushDuration,msMinimumPokeDuration,msMinimumClearDuration,sm,requestRewardSizeULorMS,...
                percentCorrectionTrials,msResponseTimeLimit,pokeToRequestStim,maintainPokeToMaintainStim,msMaximumStimPresentationDuration,...
                maximumNumberStimPresentations,doMask,constantRewards);
            
            d=2; %decrease to broaden
            gran=100;
            x=linspace(-d,d,gran);
            [a b]=meshgrid(x);
            
            ports=cellfun(@uint8,{1 3},'UniformOutput',false);
            [noiseSpec(1:length(ports)).port]=deal(ports{:});
            
            [noiseSpec.distribution]         =deal('gaussian');
            [noiseSpec.origHz]               =deal(0);
            [noiseSpec.contrast]             =deal(pickContrast(.5,.01));
            [noiseSpec.startFrame]           =deal('randomize');
            [noiseSpec.loopDuration]         =deal(1);
            [noiseSpec.locationDistribution]=deal(reshape(mvnpdf([a(:) b(:)],[-d/2 d/2]),gran,gran),reshape(mvnpdf([a(:) b(:)],[d/2 d/2]),gran,gran));
            [noiseSpec.maskRadius]           =deal(.045);
            [noiseSpec.patchDims]            =deal(uint16([50 50]));
            [noiseSpec.patchHeight]          =deal(.4);
            [noiseSpec.patchWidth]           =deal(.4);
            [noiseSpec.background]           =deal(.5);
            [noiseSpec.orientation]         =deal(-pi/4,pi/4);
            [noiseSpec.kernelSize]           =deal(.5);
            [noiseSpec.kernelDuration]       =deal(.2);
            [noiseSpec.ratio]                =deal(1/3);
            [noiseSpec.filterStrength]       =deal(1);
            [noiseSpec.bound]                =deal(.99);
            
            maxWidth               = 1920; %osx has timing problems at 800x600 (red flash at open window)
            maxHeight              = 1200;
            scaleFactor            = 0;
            interTrialLuminance     =.5;
            
            sm=filteredNoise(noiseSpec,maxWidth,maxHeight,scaleFactor,interTrialLuminance);
        end
        
        function st=makeDummyStation()
            stationSpec.id                                = '1U';
            if ismac
                stationSpec.path                              = '/Users/eflister/Desktop/dummyStation';
            else
                stationSpec.path                              = 'C:\Documents and Settings\rlab\Desktop\dummyStation';
            end
            stationSpec.MACaddress                        = '000000000000';
            stationSpec.physicalLocation                  = uint8([1 1 1]);
            % stationSpec.screenNum                         = uint8(max(Screen('Screens')));
            stationSpec.soundOn                           = true;
            % stationSpec.rewardMethod                      = 'localTimed';
            % stationSpec.portSpec.parallelPortAddress      = '0378';
            % stationSpec.portSpec.valveSpec                = int8([4,3,2]);
            % stationSpec.portSpec.sensorPins               = int8([13,10,12]);
            % stationSpec.portSpec.framePulsePins           = int8(9);
            % stationSpec.portSpec.eyePuffPins              = int8(6);
            %
            % if ismac
            %     stationSpec.portSpec = int8(3);
            % elseif ispc
            %     %do nothing
            % else
            %     error('unknown OS')
            % end
            %st=station(stationSpec);
            st=makeDefaultStation(stationSpec.id,stationSpec.path,stationSpec.MACaddress,stationSpec.physicalLocation,[],[],[],stationSpec.soundOn);
        end
        
        function [didAPause, paused, done, result, doValves, ports, didValves, didHumanResponse, manual, doPuff, pressingM, pressingP, overheadTime, initTime, kDownTime] ...
                = handleKeyboard(keyCode, didAPause, paused, done, result, doValves, ports, didValves, ...
                didHumanResponse, manual, doPuff, pressingM, pressingP, originalPriority, priorityLevel, KbConstants)
            
            % note: this function pretty much updates a bunch of flags....
            
            overheadTime=GetSecs;
            
            mThisLoop = 0;
            pThisLoop = 0;
            
            shiftDown=any(keyCode(KbConstants.shiftKeys));
            ctrlDown=any(keyCode(KbConstants.controlKeys));
            atDown=any(keyCode(KbConstants.atKeys));
            kDown=any(keyCode(KbConstants.kKey));
            tDown=any(keyCode(KbConstants.tKey));
            fDown=any(keyCode(KbConstants.fKey));
            eDown=any(keyCode(KbConstants.eKey));
            portsDown=false(1,length(KbConstants.portKeys));
            numsDown=false(1,length(KbConstants.numKeys));
            
            % arrowKeyDown=false; % initialize this variable
            % 1/9/09 - phil to add stuff about arrowKeyDown
            for pNum=1:length(KbConstants.portKeys)
                portsDown(pNum)=any(keyCode(KbConstants.portKeys{pNum}));
                % arrowKeyDown=arrowKeyDown || any(strcmp(KbName(keys(keyNum)),{'left','down','right'}));
            end
            
            for nNum=1:length(KbConstants.numKeys)
                numsDown(nNum)=any(keyCode(KbConstants.numKeys{nNum}));
            end
            
            initTime=GetSecs;
            
            if kDown
                if any(keyCode(KbConstants.pKey))
                    pThisLoop=1;
                    
                    if ~pressingP
                        
                        didAPause=1;
                        paused=~paused;
                        
                        if paused
                            Priority(originalPriority);
                        else
                            Priority(priorityLevel);
                        end
                        
                        pressingP=1;
                    end
                elseif any(keyCode(KbConstants.qKey)) && ~paused
                    done=1;
                    result='manual kill';
                elseif tDown
                    done=1;
                    result=sprintf('manual training step');
                elseif fDown
                    result=sprintf('manual flushPorts');
                    didHumanResponse=true;
                    done=1;
                elseif eDown
                    error('some kind of error here to test stuff...');
                elseif any(portsDown)
                    if ctrlDown
                        doValves(portsDown)=1;
                        didValves=true;
                    else
                        ports(portsDown)=1;
                        didHumanResponse=true;
                    end
                elseif any(keyCode(KbConstants.mKey))
                    mThisLoop=1;
                    
                    if ~pressingM && ~paused
                        %         if ~paused
                        
                        manual=~manual;
                        dispStr=sprintf('set manual to %d\n',manual);
                        disp(dispStr);
                        pressingM=1;
                    end
                elseif any(keyCode(KbConstants.aKey))
                    doPuff=true;
                elseif any(keyCode(KbConstants.rKey)) && strcmp(station.rewardMethod,'localPump')
                    doPrime(station);
                end
            end
            if shiftDown && atDown
                disp('WARNING!!!  you just hit shift-2 ("@"), which mario declared a synonym to sca (screen(''closeall'')) -- everything is going to break now');
                done=1;
                result='shift-2 kill';
            end
            
            kDownTime=GetSecs;
            if ~mThisLoop && pressingM
                pressingM=0;
            end
            if ~pThisLoop && pressingP
                pressingP=0;
            end
        end
        
        function out = bias()
            out = 0;
        end
        
        function [loop, trigger, frameIndexed, timeIndexed, indexedFrames, timedFrames, strategy, toggleStim] = determineStrategy(stim, type, responseOptions, framesUntilTransition)
            
            if length(size(stim))>3
                error('stim must be 2 or 3 dims')
            end
            
            loop=0;
            trigger=0;
            frameIndexed=0; % Whether the stim is indexed with a list of frames
            timeIndexed=0; % Whether the stim is timed with a list of frames
            indexedFrames = []; % List of indices referencing the frames
            timedFrames = [];
            toggleStim=true; % default, overriden by {'trigger',toggleStim}
            
            if iscell(type)
                if length(type)~=2
                    error('Stim type of cell should be of length 2')
                end
                switch type{1}
                    case 'indexedFrames'
                        frameIndexed = 1;
                        loop=1;
                        trigger=0;
                        indexedFrames = type{2};
                        if isNearInteger(indexedFrames) && isvector(indexedFrames) && all(indexedFrames>0) && all(indexedFrames<=size(stim,3))
                            strategy = 'textureCache';
                        else
                            class(indexedFrames)
                            size(indexedFrames)
                            indexedFrames
                            size(stim,3)
                            error('bad vector for indexedFrames type: must be a vector of integer indices into the stim frames (btw 1 and stim dim 3)')
                        end
                    case 'timedFrames'
                        timeIndexed = 1;
                        timedFrames = type{2};
                        if isinteger(timedFrames) && isvector(timedFrames) && size(stim,3)==length(timedFrames) && all(timedFrames(1:end-1)>=1) && timedFrames(end)>=0
                            strategy = 'textureCache';
                            %dontclear = 1;  %might save time, but breaks on lame graphics cards (such as integrated gfx on asus mobos?)
                        else
                            error('bad vector for timedFrames type: must be a vector of length equal to stim dim 3 of integers > 0 (number or refreshes to display each frame). A zero in the final entry means hold display of last frame.')
                        end
                    case 'trigger'   %2 static frames -- if request, show frame 1; else show frame 2
                        strategy = 'textureCache';
                        loop = 0;
                        trigger = 1;
                        toggleStim=type{2};
                        if size(stim,3)~=2
                            error('trigger type must have stim with exactly 2 frames')
                        end
                    otherwise
                        error('Unsupported stim type using a cell, either indexedFrames or timedFrames')
                end
            else
                switch type
                    case 'static'   %static 1-frame stimulus
                        strategy = 'textureCache';
                        if size(stim,3)~=1
                            error('static type must have stim with exactly 1 frame')
                        end
                    case 'cache'    %dynamic n-frame stimulus (play once)
                        strategy = 'textureCache';
                    case 'loop'     %dynamic n-frame stimulus (loop)
                        strategy = 'textureCache';
                        loop = 1;
                    case 'dynamic'
                        error('dynamic type not yet implemented')
                    case 'expert' %callback stimManager.drawExpertFrame() to call ptb drawing methods, but leave frame labels, framedrop corner, and 'drawingfinished' to stimOGL
                        strategy='expert';
                    otherwise
                        error('unrecognized stim type, must be ''static'', ''cache'', ''loop'', ''dynamic'', ''expert'', {''indexedFrames'' [frameIndices]}, or {''timedFrames'' [frameTimes]}')
                end
            end
            
            if isempty(responseOptions) && isempty(framesUntilTransition) && (trigger || loop || (timeIndexed && timedFrames(end)==0) || frameIndexed)
                trigger
                loop
                timeIndexed
                frameIndexed
                error('can''t loop with no response ports -- would have no way out')
            end
            
            % why are we not cacheing???
            
%             if strcmp(strategy,'textureCache') % texture precaching causes dropped frames (~1 per 45mins @ 100Hz)
%                 strategy = 'noCache';
%             end
            
        end

        function drawFrameUsingTextureCache(window, i, frameNum, stimSize, lastI, dontclear, texture, destRect, filtMode, labelFrames, ...
                xOrigTextPos, yNewTextPos, strategy,floatprecision)
            
            if window>=0
                if i>0 && i <= stimSize
                    if i~=lastI || (dontclear~=1) %only draw if texture different from last one, or if every flip is redrawn
                        if strcmp(strategy,'noCache')
                            texture=Screen('MakeTexture', window, texture,0,0,floatprecision); %need floatprecision=0 for remotedesktop
                        end
                        Screen('DrawTexture', window, texture,[],destRect,[],filtMode);
                        if strcmp(strategy,'noCache')
                            Screen('Close',texture);
                        end
                    else
                        if labelFrames
                            thisMsg=sprintf('This frame stim index (%d) is staying here without drawing new textures %d',i,frameNum);
                            Screen('DrawText',window,thisMsg,xOrigTextPos,yNewTextPos-20,100*ones(1,3));
                        end
                    end
                else
                    if stimSize==0
                        %probably a penalty stim with zero duration
                    else
                        i
                        sprintf('stimSize: %d',stimSize)
                        error('request for an unknown frame')
                    end
                end
            end
            
            
        end % end function
        
        function [timestamps, headroom] = flipFrameAndDoPulse(window, dontclear, framesPerUpdate, ifi, paused, doFramePulse,station,timestamps)
            
            timeStamps.enteredFlipFrameAndDoPulse=GetSecs;
            
            if window>=0
                Screen('DrawingFinished',window,dontclear); % supposed to enhance performance
                % this usually returns fast but on asus mobos sometimes takes up to 2ms.
                % it is not strictly necessary and there have been some hints
                % that it actually hurts performance -- mario usually does not (but
                % sometimes does) include it in demos, and has mentioned to be suspect of
                % it.  it's almost certainly very sensitive to driver version.
                % we may want to consider testing effects of removing it or giving user control over it.
            end
            timestamps.drawingFinished=GetSecs;
            
            timestamps.when=timestamps.vbl+(framesPerUpdate-0.8)*ifi; %this 0.8 is critical -- get frame drops if it is 0.2.  mario uses 0.5.  in theory any number 0<x<1 should give identical results.
            %                                                         %discussion at http://tech.groups.yahoo.com/group/psychtoolbox/message/9165
            
            
            
            if doFramePulse && ~paused
                %####setStatePins(station,'frame',true);
            end
            
            timestamps.prePulses=GetSecs;
            headroom=(timestamps.vbl+(framesPerUpdate)*ifi)-timestamps.prePulses;
            
            if window>=0
                [timestamps.vbl sos timestamps.ft timestamps.missed]=Screen('Flip',window,timestamps.when,dontclear);
                %http://psychtoolbox.org/wikka.php?wakka=FaqFlipTimestamps
                %vbl=vertical blanking time, when bufferswap occurs (corrected by beampos logic if available/reliable)
                %sos=stimulus onset time -- vbl + a computed constant corresponding to the duration of the vertical blanking (a delay in when, after vbl, that the swap actually happens, depends on a lot of guts)
                %ft=timestamp from the end of flip's execution
            else
                waitTime=GetSecs()-timestamps.when;
                if waitTime>0
                    WaitSecs(waitTime);
                end
                timestamps.ft=timestamps.when;
                timestamps.vbl=ft;
                timestamps.missed=0;
            end
            
            if doFramePulse && ~paused
                %####setStatePins(station,'frame',false);
            end
            
            
            timestamps.postFlipPulse=GetSecs;
            
            if timestamps.ft-timestamps.vbl>.15*ifi
                %this occurs when my osx laptop runs on battery power
                fprintf('long delay inside flip after the swap-- ft-vbl:%.15g%% of ifi, now-vbl:%.15g\n',(timestamps.ft-timestamps.vbl)/ifi,GetSecs-timestamps.vbl)
            end
            
        end % end function
        
    end
    
end
%% OLD CREATESTIM SPECFROMPARAMS
%         function [stimSpecs, startingStimSpecInd] = createStimSpecsFromParams(trialManager,preRequestStim,preResponseStim,discrimStim,postDiscrimStim,interTrialStim,...
%                 targetPorts,distractorPorts,requestPorts,interTrialLuminance,hz,indexPulses)
%             % do nothing here. this is a place holder.
%             %	INPUTS:
%             %		trialManager - the trialManager object (contains the delayManager and responseWindow params)
%             %		preRequestStim - a struct containing params for the preOnset phase
%             %		preResponseStim - a struct containing params for the preResponse phase
%             %		discrimStim - a struct containing params for the discrim phase
%             %		targetPorts - the target ports for this trial
%             %		distractorPorts - the distractor ports for this trial
%             %		requestPorts - the request ports for this trial
%             %		interTrialLuminance - the intertrial luminance for this trial (used for the 'final' phase, so we hold the itl during intertrial period)
%             %		hz - the refresh rate of the current trial
%             %		indexPulses - something to do w/ indexPulses, apparently only during discrim phases
%             %	OUTPUTS:
%             %		stimSpecs, startingStimSpecInd
%             
%             % there are two ways to have no pre-request/pre-response phase:
%             %	1) have calcstim return empty preRequestStim/preResponseStim structs to pass to this function!
%             %	2) the trialManager's delayManager/responseWindow params are set so that the responseWindow starts at 0
%             %		- NOTE that this cannot affect the preOnset phase (if you dont want a preOnset, you have to pass an empty out of calcstim)
%             
%             % should the stimSpecs we return be dependent on the trialManager class? - i think so...because autopilot does not have reinforcement, but for now nAFC/freeDrinks are the same...
%             
%             % check for empty preRequestStim/preResponseStim and compare to values in trialManager.delayManager/responseWindow
%             % if not compatible, ERROR
%             % nAFC should not be allowed to have an empty preRequestStim (but freeDrinks can)
%             
%             if isempty(preRequestStim) && strcmp(class(trialManager),'nAFC')
%                 error('nAFC cannot have an empty preRequestStim'); % i suppose we could default to the ITL here, but really shouldnt
%             end
%             responseWindowMs=getResponseWindowMs(trialManager);
%             if isempty(preResponseStim) && responseWindowMs(1)~=0
%                 error('cannot have nonzero start of responseWindow with no preResponseStim');
%             end
%             
%             % get an optional autorequest from the delayManager
%             dm = getDelayManager(trialManager);
%             if ~isempty(dm)
%                 framesUntilOnset=floor(calcAutoRequest(dm)*hz/1000); % autorequest is in ms, convert to frames
%             else
%                 framesUntilOnset=[]; % only if request port is triggered
%             end
%             % get responseWindow
%             responseWindow=floor(responseWindowMs*hz/1000); % can you floor inf?
%             
%             % now generate our stimSpecs
%             startingStimSpecInd=1;
%             i=1;
%             addedPreResponsePhase=0;
%             addedPostDiscrimPhase=0;
%             addedDiscrimPhase = 0;
%             switch class(trialManager)
%                 case {'nAFC','oddManOut','goNoGo','freeDrinks','freeDrinksCenterOnly','freeDrinksSidesOnly','freeDrinksAlternate','biasedNAFC'}
%                     % we need to figure out when the reinforcement phase is (in case we want to punish responses, we need to know which phase to transition to)
%                     if ~isempty(preResponseStim) && responseWindow(1)~=0
%                         addedPreResponsePhase=addedPreResponsePhase+1;
%                     end
%                     
%                     if ~isempty(postDiscrimStim)
%                         addedPostDiscrimPhase=addedPostDiscrimPhase+length(postDiscrimStim); % changed 4/26/15 to include multiple postDiscrims
%                     end
%                     
%                     if (~isfield(preRequestStim, 'ledON'))
%                         preRequestStim.ledON=false;
%                     end
%                     % optional preOnset phase
%                     if ~isempty(preRequestStim) &&  ismember(class(trialManager),{'nAFC','biasedNAFC','goNoGo','cuedGoNoGo'}) % only some classes have the pre-request phase if no delayManager in 'nAFC' class
%                         if preRequestStim.punishResponses
%                             criterion={[],i+1,requestPorts,i+1,[targetPorts distractorPorts],i+1+addedPreResponsePhase};  %was:i+2+addedPhases ;  i+1+addedPreResponsePhase? or i+2+addedPreResponsePhase?
%                         else
%                             criterion={[],i+1,requestPorts,i+1};
%                         end
%                         stimSpecs{i} = stimSpec(preRequestStim.stimulus,criterion,preRequestStim.stimType,preRequestStim.startFrame,...
%                             framesUntilOnset,preRequestStim.autoTrigger,preRequestStim.scaleFactor,0,hz,'pre-request','pre-request',...
%                             preRequestStim.punishResponses,false,[],preRequestStim.ledON);
%                         i=i+1;
%                         if isempty(requestPorts) && isempty(framesUntilOnset)
%                             error('cannot have empty requestPorts with no auto-request!');
%                         end
%                     end
%                     
%                     % optional preResponse phase
%                     if ~isempty(preResponseStim) && responseWindow(1)~=0
%                         if preResponseStim.punishResponses
%                             criterion={[],i+1,[targetPorts distractorPorts],i+2+addedPostDiscrimPhase}; % balaji was i+2 earlier but added postDiscrimPhase
%                         else
%                             criterion={[],i+1};
%                         end
%                         stimSpecs{i} = stimSpec(preResponseStim.stimulus,criterion,preResponseStim.stimType,preResponseStim.startFrame,...
%                             responseWindow(1),preResponseStim.autoTrigger,preResponseStim.scaleFactor,0,hz,'pre-response','pre-response',...
%                             preResponseStim.punishResponses,false,[],preResponseStim.ledON);
%                         i=i+1;
%                     end
%                     
%                     % required discrim phase
%                     criterion={[],i+1,[targetPorts distractorPorts],i+1+addedPostDiscrimPhase};
%                     if isinf(responseWindow(2))
%                         framesUntilTimeout=[];
%                     else
%                         framesUntilTimeout=responseWindow(2);
%                     end
%                     if isfield(discrimStim,'framesUntilTimeout') && ~isempty(discrimStim.framesUntilTimeout)
%                         if ~isempty(framesUntilTimeout)
%                             error('had a finite responseWindow but also defined framesUntilTimeout in discrimStim - CANNOT USE BOTH!');
%                         else
%                             framesUntilTimeout=discrimStim.framesUntilTimeout;
%                         end
%                     end
%                     
%                     
%                     if (~isfield(discrimStim, 'ledON'))
%                         discrimStim.ledON=false;
%                     end
%                     
%                     stimSpecs{i} = stimSpec(discrimStim.stimulus,criterion,discrimStim.stimType,discrimStim.startFrame,...
%                         framesUntilTimeout,discrimStim.autoTrigger,discrimStim.scaleFactor,0,hz,'discrim','discrim',...
%                         false,true,indexPulses,discrimStim.ledON); % do not punish responses here
%                     i=i+1;
%                     
%                     % optional postDiscrim Phase
%                     if ~isempty(postDiscrimStim) % currently just check for existence. lets figure out a more complicated set of requirements later
%                         if length(postDiscrimStim)==1
%                             % criterion is the similar as for discrim
%                             criterion={[],i+1,[targetPorts distractorPorts],i+1};
%                             
%                             % cannot punish responses in postDiscrimStim
%                             if postDiscrimStim.punishResponses
%                                 error('cannot punish responses in postDiscrimStim');
%                             end
%                             if isfield(postDiscrimStim,'framesUntilTimeOut') && ~isempty(postDiscrimStim.framesUntilTimeout)
%                                 if ~isinf(framesUntilTimeout)
%                                     framesUntilTimeoutPostDiscrim = postDiscrim.framesUntilTimeout;
%                                 else
%                                     error('cannot both specify a discrim noninf frames until timeout and a postDiscrimPhase')
%                                 end
%                             else
%                                 framesUntilTimeoutPostDiscrim = inf; % asume that the framesuntiltimeout is inf
%                             end
%                             stimSpecs{i} = stimSpec(postDiscrimStim.stimulus,criterion,postDiscrimStim.stimType,postDiscrimStim.startFrame,...
%                                 framesUntilTimeoutPostDiscrim,postDiscrimStim.autoTrigger,postDiscrimStim.scaleFactor,0,hz,'post-discrim','post-discrim',...
%                                 postDiscrimStim.punishResponses,false,[],postDiscrimStim.ledON);
%                             i=i+1;
%                         else
%                             for k = 1:length(postDiscrimStim) % loop through the post discrim stims
%                                 criterion={[],i+1,[targetPorts distractorPorts],i+1+length(postDiscrimStim)-k}; % any response in any part takes you to the reinf
%                                 
%                                 if postDiscrimStim(k).punishResponses
%                                     error('cannot punish responses in postDiscrimStim');
%                                 end
%                                 
%                                 if isfield(postDiscrimStim(k),'framesUntilTimeout') && ~isempty(postDiscrimStim(k).framesUntilTimeout)
%                                     if ~isinf(framesUntilTimeout)
%                                         framesUntilTimeoutPostDiscrim = postDiscrimStim(k).framesUntilTimeout;
%                                     else
%                                         error('cannot both specify a discrim noninf frames until timeout and a postDiscrimPhase')
%                                     end
%                                 else
%                                     framesUntilTimeoutPostDiscrim = inf; % asume that the framesuntiltimeout is inf
%                                 end
%                                 postDiscrimName = sprintf('post-discrim%d',k);
%                                 stimSpecs{i} = stimSpec(postDiscrimStim(k).stimulus,criterion,postDiscrimStim(k).stimType,postDiscrimStim(k).startFrame,...
%                                     framesUntilTimeoutPostDiscrim,postDiscrimStim(k).autoTrigger,postDiscrimStim(k).scaleFactor,0,hz,'post-discrim',postDiscrimName,...
%                                     postDiscrimStim(k).punishResponses,false,[],postDiscrimStim(k).ledON);
%                                 i=i+1;
%                                 
%                             end
%                         end
%                     end
%                     
%                     
%                     % required reinforcement phase
%                     criterion={[],i+1};
%                     stimSpecs{i} = stimSpec([],criterion,'cache',0,[],[],0,0,hz,'reinforced','reinforcement',false,false,[],false); % do not punish responses here, and LED is hardcoded to false (bad idea in general)
%                     i=i+1;
%                     % required final ITL phase
%                     criterion={[],i+1};
%                     stimSpecs{i} = stimSpec(interTrialLuminance,criterion,'cache',0,interTrialStim.duration,[],0,1,hz,'itl','intertrial luminance',false,false,[],false); % do not punish responses here. itl has LED hardcoded to false
%                     i=i+1;
%                     
%                 case 'cuedGoNoGo'
%                     % we need to figure out when the reinforcement phase is (in case we want to punish responses, we need to know which phase to transition to)
%                     if ~isempty(preResponseStim) && responseWindow(1)~=0
%                         addedPreResponsePhase=addedPreResponsePhase+1;
%                     end
%                     % optional preOnset phase
%                     if ~isempty(preRequestStim) &&  ismember(class(trialManager),{'cuedGoNoGo'}) % only some classes have the pre-request phase if no delayManager in 'nAFC' class
%                         if preRequestStim.punishResponses
%                             criterion={[],i+1,[targetPorts distractorPorts],i+3+addedPreResponsePhase};  %was:i+2+addedPhases ;  i+1+addedPreResponsePhase? or i+2+addedPreResponsePhase?
%                         else
%                             criterion={[],i+1,requestPorts,i+1};
%                         end
%                         stimSpecs{i} = stimSpec(preRequestStim.stimulus,criterion,preRequestStim.stimType,preRequestStim.startFrame,...
%                             framesUntilOnset,preRequestStim.autoTrigger,preRequestStim.scaleFactor,0,hz,'pre-request','pre-request',...
%                             preRequestStim.punishResponses,false,[],preRequestStim.ledON);
%                         i=i+1;
%                         if isempty(requestPorts) && isempty(framesUntilOnset)
%                             error('cannot have empty requestPorts with no auto-request!');
%                         end
%                     end
%                     % optional preResponse phase
%                     if ~isempty(preResponseStim) && responseWindow(1)~=0
%                         if preResponseStim.punishResponses
%                             criterion={[],i+1,[targetPorts distractorPorts],i+3};  %not i+2 but?  i+3?
%                         else
%                             criterion={[],i+1};
%                         end
%                         stimSpecs{i} = stimSpec(preResponseStim.stimulus,criterion,preResponseStim.stimType,preResponseStim.startFrame,...
%                             responseWindow(1),preResponseStim.autoTrigger,preResponseStim.scaleFactor,0,hz,'pre-response','pre-response',...
%                             preResponseStim.punishResponses,false,[],preResponseStim.ledON);
%                         i=i+1;
%                     end
%                     % required discrim phase
%                     criterion={[],i+1,[targetPorts distractorPorts],i+1};
%                     if isinf(responseWindow(2))
%                         framesUntilTimeout=[];
%                     else
%                         framesUntilTimeout=responseWindow(2);
%                     end
%                     if isfield(discrimStim,'framesUntilTimeout') && ~isempty(discrimStim.framesUntilTimeout)
%                         if ~isempty(framesUntilTimeout)
%                             error('had a finite responseWindow but also defined framesUntilTimeout in discrimStim - CANNOT USE BOTH!');
%                         else
%                             framesUntilTimeout=discrimStim.framesUntilTimeout;
%                         end
%                     end
%                     
%                     stimSpecs{i} = stimSpec(discrimStim.stimulus,criterion,discrimStim.stimType,discrimStim.startFrame,...
%                         framesUntilTimeout,discrimStim.autoTrigger,discrimStim.scaleFactor,0,hz,'discrim','discrim',...
%                         false,true,indexPulses,discrimStim.ledON); % do not punish responses here
%                     
%                     i=i+1;
%                     % required reinforcement phase
%                     criterion={[],i+2};
%                     stimSpecs{i} = stimSpec([],criterion,'cache',0,[],[],0,0,hz,'reinforced','reinforcement',false,false,[],false); % do not punish responses here
%                     i=i+1;
%                     
%                     %required early response penalty phase
%                     criterion={[],i+1};
%                     %stimulus=[]?,transitions=criterion,stimType='cache',startFrame=0,framesUntilTransition=[]? or earlyResponsePenaltyFrames, autoTrigger=,scaleFactor=0,isFinalPhase=0,hz,phaseType='earlyPenalty',phaseLabel='earlyPenalty',punishResponses=false,[isStim]=false,[indexPulses]=false)
%                     %maybe could calc eStim here? or pass [] and calc later
%                     stimSpecs{i} = stimSpec([],criterion,'cache',0,1,[],0,0,hz,'earlyPenalty','earlyPenalty',false,false,[],false); % do not punish responses here
%                     i=i+1;
%                     
%                     % required final ITL phase
%                     criterion={[],i+1};
%                     stimSpecs{i} = stimSpec([],criterion,'cache',0,1,[],0,1,hz,'itl','intertrial luminance',false,false,[],false); % do not punish responses here
%                     i=i+1;
%                     
%                 case 'autopilot'
%                     % do autopilot stuff..
%                     % required discrim phase
%                     criterion={[],i+1,[targetPorts distractorPorts],i+1};
%                     if isinf(responseWindow(2))
%                         framesUntilTimeout=[];
%                     else
%                         framesUntilTimeout=responseWindow(2);
%                     end
%                     if isfield(discrimStim,'framesUntilTimeout') && ~isempty(discrimStim.framesUntilTimeout)
%                         if ~isempty(framesUntilTimeout)
%                             error('had a finite responseWindow but also defined framesUntilTimeout in discrimStim - CANNOT USE BOTH!');
%                         else
%                             framesUntilTimeout=discrimStim.framesUntilTimeout;
%                         end
%                     end
%                     stimSpecs{i} = stimSpec(discrimStim.stimulus,criterion,discrimStim.stimType,discrimStim.startFrame,...
%                         framesUntilTimeout,discrimStim.autoTrigger,discrimStim.scaleFactor,0,hz,'discrim','discrim',false,true,indexPulses,[],discrimStim.ledON); % do not punish responses here
%                     i=i+1;
%                     % required final ITL phase
%                     criterion={[],i+1};
%                     stimSpecs{i} = stimSpec(interTrialLuminance,criterion,'cache',0,interTrialStim.duration,[],0,1,hz,'itl','intertrial luminance',false,false,[],false); % do not punish responses here
%                     i=i+1;
%                     
%                 case 'reinforcedAutopilot'
%                     % do reinforcedAutopilot stuff..
%                     % required discrim phase
%                     criterion={[],i+1,[targetPorts distractorPorts],i+1};
%                     if isinf(responseWindow(2))
%                         framesUntilTimeout=[];
%                     else
%                         framesUntilTimeout=responseWindow(2);
%                     end
%                     if isfield(discrimStim,'framesUntilTimeout') && ~isempty(discrimStim.framesUntilTimeout)
%                         if ~isempty(framesUntilTimeout)
%                             error('had a finite responseWindow but also defined framesUntilTimeout in discrimStim - CANNOT USE BOTH!');
%                         else
%                             framesUntilTimeout=discrimStim.framesUntilTimeout;
%                         end
%                     end
%                     stimSpecs{i} = stimSpec(discrimStim.stimulus,criterion,discrimStim.stimType,discrimStim.startFrame,...
%                         framesUntilTimeout,discrimStim.autoTrigger,discrimStim.scaleFactor,0,hz,'discrim','discrim',false,true,indexPulses,discrimStim.ledON); % do not punish responses here
%                     
%                     
%                     % required reinforcement phase
%                     i=i+1;
%                     criterion={[],i+1};
%                     % reinfAutoTrigger = {0.999999,2}; % True for reinforcement stage in reinforcedAutopilot - we will use this as a stochastic reward on each trial...
%                     stimSpecs{i} = stimSpec([],criterion,'cache',0,[],[],0,0,hz,'reinforced','reinforcement',false,false,[],false); % do not punish responses here
%                     
%                     
%                     
%                     
%                     i=i+1;
%                     % required final ITL phase
%                     criterion={[],i+1};
%                     stimSpecs{i} = stimSpec(interTrialLuminance,criterion,'cache',0,interTrialStim.duration,[],0,1,hz,'itl','intertrial luminance',false,false,[],false); % do not punish responses here
%                     i=i+1;
%                     
%                 case 'changeDetectorTM' % This is like nAFC, except, somethings are different
%                     % we need to figure out when the reinforcement phase is (in case we want to punish responses, we need to know which phase to transition to)
%                     if ~isempty(preResponseStim) && responseWindow(1)~=0
%                         addedPreResponsePhase=addedPreResponsePhase+1;
%                     end
%                     
%                     if ~isempty(postDiscrimStim)
%                         addedPostDiscrimPhase=addedPostDiscrimPhase+1;
%                     end
%                     
%                     if ~isempty(discrimStim)
%                         addedDiscrimPhase=addedDiscrimPhase+1;
%                     end
%                     
%                     
%                     % optional preOnset phase
%                     if ~isempty(preRequestStim) % only some classes have the pre-request phase if no delayManager in 'nAFC' class
%                         if preRequestStim.punishResponses
%                             criterion={[],i+1,requestPorts,i+1,[targetPorts distractorPorts],i+1+addedPreResponsePhase};  %was:i+2+addedPhases ;  i+1+addedPreResponsePhase? or i+2+addedPreResponsePhase?
%                         else
%                             criterion={[],i+1,requestPorts,i+1};
%                         end
%                         stimSpecs{i} = stimSpec(preRequestStim.stimulus,criterion,preRequestStim.stimType,preRequestStim.startFrame,...
%                             framesUntilOnset,preRequestStim.autoTrigger,preRequestStim.scaleFactor,0,hz,'pre-request','pre-request',preRequestStim.punishResponses,false);
%                         i=i+1;
%                         if isempty(requestPorts) && isempty(framesUntilOnset)
%                             error('cannot have empty requestPorts with no auto-request!');
%                         end
%                     end
%                     
%                     % required preResponse phase
%                     if isempty(preResponseStim)
%                         error('cannot have changeDetectorTM and have empty preResponseStim');
%                     end
%                     if ~preResponseStim.punishResponses
%                         error('changeDetectorTM forces punishResponses in preResponsePhase');
%                     end
%                     if ~isscalar(preResponseStim.framesUntilTimeout)
%                         error('preResponseStim should timeout at some point in time');
%                     end
%                     criterion={[],i+1,[targetPorts distractorPorts],i+2+addedPostDiscrimPhase}; % balaji was i+2 earlier but added postDiscrimPhase
%                     stimSpecs{i} = stimSpec(preResponseStim.stimulus,criterion,preResponseStim.stimType,preResponseStim.startFrame,...
%                         preResponseStim.framesUntilTimeout,preResponseStim.autoTrigger,preResponseStim.scaleFactor,0,hz,'pre-response','pre-response',preResponseStim.punishResponses,false);
%                     i=i+1;
%                     
%                     % for changeDetectorTM, discrim stim may be optional (for catch
%                     % trials)
%                     
%                     criterion={[],i+1,[targetPorts distractorPorts],i+1+addedPostDiscrimPhase};
%                     if isinf(responseWindow(2))
%                         framesUntilTimeout=[];
%                     else
%                         framesUntilTimeout=responseWindow(2);
%                     end
%                     if isfield(discrimStim,'framesUntilTimeout') && ~isempty(discrimStim.framesUntilTimeout)
%                         if ~isempty(framesUntilTimeout)
%                             error('had a finite responseWindow but also defined framesUntilTimeout in discrimStim - CANNOT USE BOTH!');
%                         else
%                             framesUntilTimeout=discrimStim.framesUntilTimeout;
%                         end
%                     end
%                     
%                     stimSpecs{i} = stimSpec(discrimStim.stimulus,criterion,discrimStim.stimType,discrimStim.startFrame,...
%                         framesUntilTimeout,discrimStim.autoTrigger,discrimStim.scaleFactor,0,hz,'discrim','discrim',false,true,indexPulses); % do not punish responses here
%                     i=i+1;
%                     
%                     % optional postDiscrim Phase
%                     if ~isempty(postDiscrimStim) % currently just check for existence. lets figure out a more complicated set of requirements later
%                         % criterion is the similar as for discrim
%                         criterion={[],i+1,[targetPorts distractorPorts],i+1};
%                         
%                         % cannot punish responses in postDiscrimStim
%                         if postDiscrimStim.punishResponses
%                             error('cannot punish responses in postDiscrimStim');
%                         end
%                         if isfield(postDiscrimStim,'framesUntilTimeOut') && ~isempty(postDiscrimStim.framesUntilTimeout)
%                             if ~isinf(framesUntilTimeout)
%                                 framesUntilTimeoutPostDiscrim = postDiscrim.framesUntilTimeout;
%                             else
%                                 error('cannot both specify a discrim noninf frames until timeout and a postDiscrimPhase')
%                             end
%                         else
%                             framesUntilTimeoutPostDiscrim = inf; % asume that the framesuntiltimeout is inf
%                         end
%                         stimSpecs{i} = stimSpec(postDiscrimStim.stimulus,criterion,postDiscrimStim.stimType,postDiscrimStim.startFrame,...
%                             framesUntilTimeoutPostDiscrim,postDiscrimStim.autoTrigger,postDiscrimStim.scaleFactor,0,hz,'post-discrim','post-discrim',postDiscrimStim.punishResponses,false);
%                         i=i+1;
%                     end
%                     
%                     
%                     % required reinforcement phase
%                     criterion={[],i+1};
%                     stimSpecs{i} = stimSpec([],criterion,'cache',0,[],[],0,0,hz,'reinforced','reinforcement',false,false); % do not punish responses here
%                     i=i+1;
%                     % required final ITL phase
%                     criterion={[],i+1};
%                     stimSpecs{i} = stimSpec(interTrialLuminance,criterion,'cache',0,1,[],0,1,hz,'itl','intertrial luminance',false,false); % do not punish responses here
%                     i=i+1;
%                     
%                 otherwise
%                     class(trialManager)
%                     error('unsupported trial manager class');
%             end
%             
%             
%         end % end function
