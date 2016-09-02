classdef trainingStep
    
    properties
        trialManager
        stimManager
        criterion
        scheduler
        stepName
    end
    
    methods
        function t=trainingStep(tm,sm,crit,sched,name)
            % TRAININGSTEP  class constructor.
            % t = trainingStep(trialManager,stimManager,criterion,scheduler,stepName)
                        
            validateattributes(tm,{'trialManager'},{'nonempty'});
            validateattributes(sm,{'stimManager'},{'nonempty'});
            validateattributes(crit,{'criterion'},{'nonempty'});
            validateattributes(sched,{'scheduler'},{'nonempty'});
            validateattributes(name,{'char'},{'nonempty'});

            t.trialManager = tm;
            t.stimManager = sm;
            t.criterion = crit;
            t.scheduler = sched;
            t.stepName=name;
            
            assert(sm.stimMgrOKForTrialMgr(tm),'trainingStep:invalidParamValue','stimManager ''%s'' incompatible with trialManager ''%s''',class(sm),class(tm))
        end
        
        function ok=boxOKForTrainingStep(t,b,r)
            validateattributes(b,{'box'},{'nonempty'});
            validateattributes(r,{'BCore'},{'nonempty'});
            ok=t.trialManager.boxOKForTrialManager(b,r) & t.stimManager.boxOKForStimManager(b,r);
        end

        function t=decache(t)
            t.trialManager=t.trialManager.decache();
            t.stimManager=t.stimManager.decache();
        end
        
        function d=disp(t)
            %following line causes 'can't find path specified' error?
            %d=['\t\ttrialManager: ' display(t.trialManager) '\n\t\tstimManager: '
            %display(t.stimManager) '\n\t\tcriterion: ' display(t.criterion) '\n\t\tscheduler: ' display(t.scheduler)];
            d=sprintf('\ntrialManager: %s\t\tstimManager: %s\t\tcriterion: %s\t\tscheduler%s',class(t.trialManager),class(t.stimManager),class(t.criterion),class(t.scheduler));
        end
        
        function stopEarly = doInterSession(ts, rn, window)
            %hack : in the future call "run" on trial manager with the variable far more ally known as "intertrial context" sent to the stimManager
            
            %things to do here:
            %1) save the trialRecords, get the RS to send em to the DS
            %this prevents the memory problems with large trail records
            
            %note: the number of session is preserved in the session
            %record in the the training step, but this hack version
            %always overwrites the BCore, so isn't making use of that
            %funcitonality, even though it should work
            
            %always make a new session after an intersession
            stopEarly = 1;  %stopEarly = 0;
            interSessionScreenLuminance=0;
            texture=Screen('MakeTexture', window, interSessionScreenLuminance);
            destRect= Screen('Rect', window);
            xTextPos = 25;
            yTextPos =100;
            if ~isempty(rn)
                constants = getConstants(rn);
            end
            
            
            interSessionStart = now;
            interTrialContinues=1; i=0;
            while interTrialContinues
                fprintf('waited for %d frames\n',i);
                i=i+1;
                secondsSince=etime(datevec(now),datevec(interSessionStart));
                secondsUntil=getCurrentHoursBetweenSession(ts.scheduler)*3600-secondsSince;  %okay this depends on my scheduler
                %consider secsRemainingTilStateFlip
                
                if rand<0.001
                    disp(sprintf('timeSince %d, timeUntil: %d',secondsSince,secondsUntil))
                end
                
                Screen('DrawTexture', window, texture,[],destRect,[],0);
                [~,~] = Screen('DrawText',window,[ ' frame ind:' num2str(i) ' hoursSince: ' num2str(secondsSince/3600,'%8.3f') ' hoursUntil: ' num2str(secondsUntil/3600,'%8.3f') ' percentThere: ' num2str((100*secondsSince/(secondsSince+secondsUntil)),'%8.1f') ],xTextPos,yTextPos,100*ones(1,3));
                [~, ~, ~]=Screen('Flip',window);
                
                if secondsUntil< 0
                    interTrialContinues=0;
                end
                
                %check for key presses
                [keyIsDown,secs,keyCode]=KbCheck;
                keys=find(keyCode);
                kDown=0;
                if keyIsDown
                    for keyNum=1:length(keys)
                        kDown= kDown || strcmp(KbName(keys(keyNum)),'k');  % IF HOLD "K"
                    end
                end
                
                if kDown
                    for keyNum=1:length(keys)
                        keyName=KbName(keys(keyNum));
                        if strcmp(keyName,'q')  % AND PRESS "Q"
                            interTrialContinues=0;
                            disp('manual kill of interSession')
                            stopEarly = 1;
                        end
                    end
                end
                
                if ~isempty(rn)
                    if ~isConnected(rn)
                        interTrialContinues=0;
                    end
                    
                    while commandsAvailable(rn,constants.priorities.IMMEDIATE_PRIORITY) && interTrialContinues
                        logwrite('handling IMMEDIATE priority command in interTrial');
                        if ~isConnected(rn)
                            interTrialContinues=0;
                        end
                        
                        com=getNextCommand(rn,constants.priorities.IMMEDIATE_PRIORITY);
                        if ~isempty(com)
                            [good, cmd, args]=validateCommand(rn,com);
                            logwrite(sprintf('interSession command is %d',cmd));
                            
                            if good
                                done=clientHandleVerifiedCommand(rn,com,cmd,args,constants.statuses.MID_TRIAL);
                                if done
                                    interTrialContinues = 0;
                                end
                            end
                        end
                    end
                end
            end
        end
        
        function [graduate, keepWorking, secsRemainingTilStateFlip, sub, r, tR, st, manualTs] ...
                =doTrial(ts,st,sub,r,rn,tR,sessNo,cR)
            graduate=0;
            
            manualTs=false;
            validateattributes(st,{'station'},{'nonempty'});
            validateattributes(r,{'BCore'},{'nonempty'});
            validateattributes(sub,{'subject'},{'nonempty'});
            assert((isempty(rn) || isa(rn,'rnet')),'trainingStep:doTrial:incomaptibleDataValue','if you provide a non empty rnet, it has to be an rnet')
            
            try
                [keepDoingTrials, secsRemainingTilStateFlip, updateScheduler, newScheduler] = ts.scheduler.checkSchedule(sub,ts,tR,sessNo);
                
                if keepDoingTrials
                    [newTM, updateTM, newSM, updateSM, stopEarly, tR, st, updateRM]=...
                        ts.trialManager.doTrial(st,ts.stimManager,sub,r,rn,tR,sessNo,cR);
                    keepWorking=~stopEarly;
                    
                    % 1/22/09 - check to see if we want to dynamically change trainingStep (look in trialRecords(end).result, if stopEarly is set)
                    if stopEarly
                        if isfield(tR(end),'result') && ischar(tR(end).result) && strcmp(tR(end).result,'manual training step')
                            manualTs=true;
                        end
                    end
                    
                    graduate = ts.criterion.checkCriterion(sub,ts, tR, cR);
                    
                    % ## not sure updateTM is needed here? causes bug because isnt
                    % set even when reinforcementMgr needs to be updated in TM.
                    updateTS = false;
                    if updateTM || updateRM
                        ts.trialManager=newTM;
                        updateTS = true;
                    end
                    if updateSM
                        ts.stimManager=newSM;
                        updateTS = true;
                    end
                    if updateScheduler
                        ts.scheduler=newScheduler;
                        updateTS = true;
                    end
                    
                    if updateTS
                        % This will update the protocol locally, and also update
                        % the subject's protocolversion.autoVersion, which will
                        % propagate the changes back to the server upon session end
                        [sub, r]=changeProtocolStep(sub,ts,r,'trialManager or stimManager or scheduler state change','BCore');
                    end
                    
                else
                    disp('*************************INTERTRIAL PERIOD STARTS!*****************************')
                    stopEarly = doInterSession(ts, rn, getPTBWindow(st)); % note: we have no records of this
                    keepWorking=~stopEarly;
                    disp('*************************INTERTRIAL PERIOD ENDS!*****************************')
                end
            catch ex
                display(ts)
                %disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                Screen('CloseAll');
                rethrow(ex)
            end
        end
        
        function tsName = generateStepName(ts)
            % assembles a name by calling a getNameFragment() method on its trialMgr, stimMgr, rewadrMgr, and scheduler,
            % the base class inherited implementation for each getNameFragment() could just return 
            % an abbreviated class name, but could be overridden by subclasses to include important parameter values.

            tsName = [getNameFragment(ts.trialManager) '_' getNameFragment(ts.stimManager) '_' getNameFragment(ts.criterion) '_' getNameFragment(ts.scheduler)];

            usersNameOfWholeStep=getStepName(ts); % optional name is used by physiology and could be used by BCore protocols.  defaults to '' when unspecified.
            if ~strcmp(usersNameOfWholeStep,'')
                tsName=[usersNameOfWholeStep '_' tsName];
            end

        end % end function
        
        function out=getCriterion(t)
            out=t.criterion;
        end
        
        function out=getScheduler(t)
            out=t.scheduler;
        end
        
        function out=getStepName(t)
            out=t.stepName;
        end
        
        function out=getStimManager(t)
            out=t.stimManager;
        end
        
        function out=getSVNCheckMode(t)
            out=t.svnCheckMode;
        end
        
        function out = getSVNRevNum(ts)
            out=ts.svnRevNum;
        end
        
        function out = getSVNRevURL(ts)
            out=ts.svnRevURL;
        end
        
        function out=getTrialManager(t)
            out=t.trialManager;
        end
        
        function  out = sampleStimFrame(ts)
            %returns a single image from calc stim movie

            %out=sampleStimFrame(); one day?
            if isa(ts.stimManager,'stimManager')
            out=sampleStimFrame(ts.stimManager,class(ts.trialManager));
            else
                out=[];
                warning('not a stimManager:  maybe the current class definitions don''t match the BCore')
            end

        end
        
        function ts=setReinforcementParam(ts,param,val)
            tM = ts.trialManager;
            tM = tM.setReinforcementParam(param,val);
            ts.trialManager = tM;
        end 
        
        function ts = setStimManager(ts, stim)
            if isa(stim, 'stimManager')
                ts.stimManager = stim ;
            else
                class(stim)
                error('must be stimManager')

            end
        end
        
        function ts=setTrialManager(ts,tm)
            if(isa(tm, 'trialManager'))

                    ts.trialManager = tm;

            else
                 class(tm)
                error('input is not of type trialManager');
            end
        end
        
        function trainingStep=stopEyeTracking(trainingStep)

            trainingStep.trialManager=stopEyeTracking(trainingStep.trialManager);
        end   
        
    end
    
end

