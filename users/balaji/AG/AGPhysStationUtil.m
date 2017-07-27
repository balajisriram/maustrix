classdef AGPhysStationUtil
    properties (Constant = true)
        EXPERIMENTER = 'sbalaji1984@gmail.com';
    end
    methods (Static)
        %% standAloneRun
        function standAloneRun(subjectID,BCoreServerPath,setup)
            %standAloneRun([BCorePath],[setupFile],[subjectID])
            %
            % BCorePath (optional, string path to preexisting BCore 'db.mat' file)
            % defaults to checking for db.mat in ...\<BCore install directory>\..\BCoreData\ServerData\
            % if none present, makes new BCore located there, with a dummy subject
            %
            % setup (optional, name of a setProtocol file on the path, typically in the setup directory)
            % defaults to 'setProtocolDEMO'
            % if subject already exists in BCore and has a protocol, default is no action
            %
            % subjectID (optional, must be string id of subject -- will add to BCore if not already present)
            % default is some unspecified subject in BCore (you can't depend on which
            % one unless there is only one)
            
            
            setupEnvironment;
            
            % create ratrix if necessary
            if exist('BCorePath','var') && ~isempty(BCoreServerPath)
                assert(isdir(BCoreServerPath),'standAloneRun:incorrectValue','if BCorePath supplied, it must be a path to a preexisting BCore ''db.mat'' file')
                rx=BCore(BCoreServerPath,0);
            else
                d=dir(fullfile(BCoreUtil.getServerDataPath, 'db.mat'));
                switch length(d)
                    case 0
                        rx = AGPhysStationUtil.createVisionPhysiologyBCore();
                    case 1
                        rx=BCore(BCoreUtil.getServerDataPath,0,fullfile(BCoreUtil.getBCoreDataPath,'PermanentTrialRecordStore'));
                    otherwise
                        error('standAloneRun:unknownError','either a single db.mat exists or none exist. We found %d. Clean your database',length(d));
                end
            end
            
            
            
            % should we add the subject to the ratrix?
            if ~exist('subjectID','var') || isempty(subjectID)
                subjectID='demo1';
            end
            
            % current author is bas
            auth = 'bas';
            
            % add subject if not in BCore
            switch rx.subjectIDInBCore(lower(subjectID))
                case true
                    sub = rx.getSubjectFromID(subjectID);
                case false
                    sub = virtual(subjectID, 'unknown');
                    sub.reward = 100;
                    sub.timeout = 10000;
                    sub.puff = 0;
                    rx=rx.addSubject(sub,auth);
            end
            
            if ~exist('setup','var') || isempty(setup)
                setup=@AGPhysStationUtil.setProtocolHeadFixed;
            elseif ~isa(setup,'function_handle')
                error('AGPhysStationUtil:standAloneRun:incompatibleInput','you input setupFile thats not a function handle');
            end
            rx=setup(rx,{subjectID});
            
            try
                % make sure all the previous data gets shifted to the appropriate place
                boxIDs=getBoxIDs(rx);
                rx=putSubjectInBox(rx,subjectID,boxIDs(1),auth);
                b=getBoxIDForSubjectID(rx,sub.id);
                st=getStationsForBoxID(rx,b);
                maxTrialsPerSession = Inf;
                exitByFinishingTrialQuota = true;
                trustOSRecords = true;
                while exitByFinishingTrialQuota
                    [rx,exitByFinishingTrialQuota]=st.doTrials(rx,maxTrialsPerSession,[],trustOSRecords);
                    deleteOnSuccess = true;
                    BCoreUtil.replicateTrialRecords({rx.standAlonePath},deleteOnSuccess);
                end
                [~, ~] = emptyAllBoxes(rx,'done running trials in standAloneRun',auth);
                %BCoreUtil.compileDetailedRecords
                AGPhysStationUtil.cleanup;
            catch ex
                disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
                
                c = clock;
                message = {sprintf('Failed for subject::%s at time::%d:%d on %d-%d-%d',subjectID,c(4),c(5),c(2),c(3),c(1)),getReport(ex,'extended','hyperlinks','off')};
                AGPhysStationUtil.notify(AGPhysStationUtil.EXPERIMENTER,'Error in Rig',message);
                deleteOnSuccess = true;
                [~, ~] = emptyAllBoxes(rx,'done running trials in standAloneRun',auth);
                AGPhysStationUtil.cleanup;
                BCoreUtil.replicateTrialRecords({rx.standAlonePath},deleteOnSuccess);
                AGPhysStationUtil.cleanup;
                rethrow(ex)
            end
        end
        function cleanup
            sca
            FlushEvents('mouseUp','mouseDown','keyDown','autoKey','update');
            ListenChar(0)
            ShowCursor(0)
        end
        %% default objects
        function rx = createVisionPhysiologyBCore()
            % create base BCore
            remake = true;
            rx = BCore(BCoreUtil.getServerDataPath,remake);
            
            % create station
            id = '1U';
            mac=BCoreUtil.getMACaddressSafely();
            physicalLocation = uint8([1 1 1]);
            stationPath = fullfile(BCoreUtil.getBCoreDataPath,'Stations','station1');
            st = AGPhysStationUtil.makeVisionPhysiologyStation(id,stationPath,mac,physicalLocation);
            
            % create and add box; add station to box.
            boxes=box(int8(1),fullfile(BCoreUtil.getBCoreDataPath,'Boxes','box1'));
            rx=addBox(rx,boxes);
            rx=addStationToBoxID(rx,st,boxes.id);
            
            % set perm storage;
            permStorePath=fullfile(BCoreUtil.getBCoreDataPath,'PermanentTrialRecordStore');
            warning off; mkdir(permStorePath); warning on; % sets the already exists warning off
            rx.standAlonePath=permStorePath;
            fprintf('created new BCore\n')
        end
                
        function st=makeVisionPhysiologyStation(id,path,mac,physicalLocation,~,~,~,~,~)
            
            % our standard parallel port pin assignments
            % pin register	invert	dir	purpose
            %---------------------------------------------------
            % 1   control	inv     i/o	NA
            % 2   data              i/o right reward valve (cooldrive valve 1)
            % 3   data              i/o	center reward valve (cooldrive valve 2)
            % 4   data              i/o	left reward valve (cooldrive valve 3)
            % 5   data              i/o	LED
            % 6   data              i/o NA
            % 7   data              i/o	NA
            % 8   data              i/o indexPulse
            % 9   data              i/o framePulse
            % 10  status            i   center lick sensor
            % 11  status    inv     i	localPump motorRunning
            % 12  status            i   right lick sensor
            % 13  status            i   left lick sensor
            % 14  control	inv     i/o	NA
            % 15  status            i   NA
            % 16  control           i/o phasePulse
            % 17  control	inv     i/o stimPulse
            
            st=standardVisionPhysiologyStationWithLED(id, path, mac, physicalLocation, '0378', int8([4,3,2]), int8([13,10,12]));
        end
        
        function tm = makeVisionPhysAutopilotTrialManager()
            % Create Sound Manager
            sm = BCoreUtil.makeStandardSoundManager();
            % Reward Manager
            rm = BCoreUtil.makeStandardReinforcementManager();
            % Delay Manager
            dm = noDelay();
            
            
            frameDropCorner={'off'};
            dropFrames=false;
            requestPort = 'none';
            saveDetailedFrameDrops = false;
            responseWindowMs = [1 inf];
            customDescription = 'visionAutopilot';
            showText = 'full';
            
            tm=autopilot(sm, rm, dm, frameDropCorner, dropFrames, requestPort, saveDetailedFrameDrops,...
                responseWindowMs, customDescription, showText);
        end
        
        function ts = makeOrientationSweepTS(trialManager, performanceCrit, sch, stepName)
            % gratings stim manager
            pixPerCycs=128;
            driftfrequencies=2;
            orientations=[-pi:pi/8:pi];
            phases=0;
            contrasts=1;
            maxDuration=2;
            radii=1;annuli=0;location=[.5,.5];
            radiusType = 'hardEdge';waveform= 'sine';normalizationMethod='normalizeDiagonal';
            mean=0.5;thresh=.00005;
            maxWidth=1920;
            maxHeight=1080;
            scaleFactor=0;
            interTrialLuminance={.5, 15};
            doCombos = true;
            
            phaseDetails = [];
            LEDParams.active = false;
            LEDParams.numLEDs = 0;
            
            AUTOPILOTGRAT = autopilotGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,radiusType, annuli,location,...
                waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos, phaseDetails);
            
            % training step using other objects as passed in
            ts = trainingStep(trialManager, AUTOPILOTGRAT, performanceCrit, sch,stepName);
        end
        
        function ts = makeLongDurationTS(trialManager, performanceCrit, sch, stepName)
                        % gratings stim manager
            pixPerCycs=128;
            driftfrequencies=2;
            orientations=[-pi/4,pi/4];
            phases=0;
            contrasts=[1,0.15];
            maxDuration=2;
            radii=1;annuli=0;location=[.5,.5];
            radiusType = 'hardEdge';waveform= 'sine';normalizationMethod='normalizeDiagonal';
            mean=0.5;thresh=.00005;
            maxWidth=1920;
            maxHeight=1080;
            scaleFactor=0;
            interTrialLuminance={.5, 15};
            doCombos = true;
            
            phaseDetails = [];
            LEDParams.active = false;
            LEDParams.numLEDs = 0;
            
            AUTOPILOTGRAT = autopilotGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,radiusType, annuli,location,...
                waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos, phaseDetails);
            
            % training step using other objects as passed in
            ts = trainingStep(trialManager, AUTOPILOTGRAT, performanceCrit, sch,stepName);
        end
        
        function ts = makeShortDurationTS(trialManager, performanceCrit, sch, stepName)
                        % gratings stim manager
            pixPerCycs=128;
            driftfrequencies=0;
            orientations=[-pi/4,pi/4];
            phases=0;
            contrasts=[1,0.15];
            maxDuration=[0.05,0.1 0.15,0.2,0.5];
            radii=1;annuli=0;location=[.5,.5];
            radiusType = 'hardEdge';waveform= 'sine';normalizationMethod='normalizeDiagonal';
            mean=0.5;thresh=.00005;
            maxWidth=1920;
            maxHeight=1080;
            scaleFactor=0;
            interTrialLuminance={.5, 15};
            doCombos = true;
            
            phaseDetails = [];
            LEDParams.active = false;
            LEDParams.numLEDs = 0;
            
            AUTOPILOTGRAT = autopilotGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,radiusType, annuli,location,...
                waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos, phaseDetails);
            
            % training step using other objects as passed in
            ts = trainingStep(trialManager, AUTOPILOTGRAT, performanceCrit, sch,stepName);
        end
        

        %% standard protocol List
        
        function r = setProtocolHeadFixed(r,subjIDs)
            assert(isa(r,'BCore'),'BCoreUtil:setProtocolDEMONoRequest:invalidInput','need a BCore object. You sent object of class %s',class(r));
            % TrialManager FreeDrinks
            tmAutoPilot = AGPhysStationUtil.makeVisionPhysAutopilotTrialManager();
            ts1 = AGPhysStationUtil.makeOrientationSweepTS(tmAutoPilot,numTrialsDoneCriterion(5),noTimeOff(), 'OrSweep');
            ts2 = AGPhysStationUtil.makeLongDurationTS(tmAutoPilot,numTrialsDoneCriterion(5),noTimeOff(), 'LongDurationOR');
            ts3 = AGPhysStationUtil.makeShortDurationTS(tmAutoPilot,numTrialsDoneCriterion(20),noTimeOff(), 'ShortDurationOR');
            descriptiveString='Headfix protocol 7/26/2017';
            
            pHeadFix = protocol(descriptiveString,...
                 {ts1,ts2,ts3});
            stepNum = 1;
            %%%%%%%%%%%%
            for i=1:length(subjIDs)
                subj=getSubjectFromID(r,subjIDs{i});
                [~, r]=setProtocolAndStep(subj,pHeadFix,true,false,true,stepNum,r,'call to setProtocolHeadFixed','bas');
            end
            
        end

        
        %% Infrastructure
        
        function notify(WHO,SUBJECT,PARAMS)
            assert(ischar(SUBJECT),'BCoreUtil:notify:invalidInput','SUBJECT needs to be a char. instead is : %s',class(SUBJECT));
            assert(ischar(PARAMS)||iscell(PARAMS),'BCoreUtil:notify:invalidInput','PARAMS needs to be a char or cell. instead is : %s',class(PARAMS));
            switch WHO
                case AGPhysStationUtil.EXPERIMENTER
                    BCoreUtil.mail(AGPhysStationUtil.EXPERIMENTER,SUBJECT,PARAMS);
                case BCoreUtil.SWAPPER
                case 'all'
            end
        end
        
        function mail(address,subject,message,attachment)
            if ~exist('attachment','var') || isempty(attachment)
                attachment = '';
            end
            if ~exist('address','var')
                error('BCoreUtil:mail:variableRequired','address is missing');
            end
            if ~exist('subject','var')
                error('BCoreUtil:mail:variableRequired','subject is missing');
            end
            if ~exist('message','var')
                warning('BCoreUtil:mail:variablePreferred','message is missing.using default message');
                message = '';
            end
            % Define these variables appropriately:
            mail = 'ghoshlab@gmail.com'; %Your GMail email address
            password = 'visualcortex'; %Your GMail password
            
            % Then this code will set up the preferences properly:
            setpref('Internet','E_mail',mail);
            setpref('Internet','SMTP_Server','smtp.gmail.com');
            setpref('Internet','SMTP_Username',mail);
            setpref('Internet','SMTP_Password',password);
            props = java.lang.System.getProperties;
            props.setProperty('mail.smtp.auth','true');
            props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
            props.setProperty('mail.smtp.socketFactory.port','465');
            
            % Send the email
            if ~isempty(attachment)
                sendmail(address,subject,message,attachment);
            else
                sendmail(address,subject,message);
            end
        end
    end
end