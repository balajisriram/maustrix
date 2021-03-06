classdef BCoreUtil
    properties (Constant = true)
        EXPERIMENTER = 'balaji.sriram@biogen.com';
    end
    methods (Static)
        %% get paths
        function BCorePath=getBCorePath()
            [pathstr, ~, ~] = fileparts(mfilename('fullpath'));
            [pathstr, ~, ~] = fileparts(pathstr);
            BCorePath = fileparts(pathstr);
        end
        
        function BasePath = getBasePath()
            p = BCoreUtil.getBCorePath();
            [BasePath, ~, ~] = fileparts(p);
        end
        
        function ServerDataPath = getServerDataPath()
            p = BCoreUtil.getBasePath();
            p = fullfile(p,'BCoreData');
            ServerDataPath = fullfile(p,'ServerData');
        end
        
        function dataPath = getBCoreDataPath()
            p = BCoreUtil.getBasePath();
            dataPath = fullfile(p,'BCoreData');
        end
        
        function compiledDataPath = getLocalCompiledDataPath()
            p = BCoreUtil.getBCoreDataPath();
            compiledDataPath = fullfile(p,'CompiledTrialRecords');
        end
        
        function permanentDataPath = getLocalPermanentDataPath()
            p = BCoreUtil.getBCoreDataPath();
            permanentDataPath = fullfile(p,'\PermanentTrialRecordStore');
        end
        
        function [success, mac]=getMACaddress()
            success=false;
            switch computer
                case {'PCWIN64','PCWIN32'}
                    macidcom = fullfile(PsychtoolboxRoot,'PsychContributed','macid');
                    [rc, mac] = system(macidcom);
                    mac=mac(~isstrprop(mac,'wspace'));
                    if rc==0 && isMACaddress(mac)
                        success=true;
                    end
                case {'GLNXA64','MACI64'}
                    compinfo = Screen('Computer');
                    if isfield(compinfo, 'MACAddress')
                        mac = compinfo.MACAddress;
                        % Remove the : that are a part of the string
                        mac = mac(mac~=':');
                        if isMACaddress(mac)
                            success = true;
                        end
                    end
                otherwise
                    error('BCoreUtil:getMACAddress:unsupportedSystem','In getMACaddress() unknown OS');
            end
        end
        
        function mac = getMACaddressSafely()
            try
                [success, mac]=BCoreUtil.getMACaddress();
                if ~success
                    mac='000000000000';
                end
            catch
                mac='000000000000';
            end
        end
        %% default objects
        function sm = makeStandardSoundManager()
            sm=soundManager({soundClip('correctSound','allOctaves',400,20000), ...
                soundClip('keepGoingSound','allOctaves',300,20000), ...
                soundClip('trySomethingElseSound','gaussianWhiteNoise'), ...
                soundClip('wrongSound','tritones',[300 400],20000),...
                soundClip('trialStartSound','empty')});
        end
        
        function sm = makeStandardSoundManagerGNG()
            sm=soundManager({soundClip('correctSound','allOctaves',400,20000), ...
                soundClip('keepGoingSound','allOctaves',300,20000), ...
                soundClip('trySomethingElseSound','gaussianWhiteNoise'), ...
                soundClip('wrongSound','tritones',[300 400],20000),...
                soundClip('stimOnSound','allOctaves',350,20000),...
                soundClip('trialStartSound','allOctaves',200,20000)});
        end
        
        function rm = makeStandardReinforcementManager(requestRewardON)
            if ~exist('requestRewardON','var')|| isempty(requestRewardON)
                requestRewardON = false;
            end
                
            rewardScalar          =1;
            if requestRewardON
                requestRewardScalar   =0.2;
            else
                requestRewardScalar   =0;
            end
                
            requestMode           ='first';
            penaltyScalar         =1;
            fractionOpenTimeSoundIsOn =1;
            fractionPenaltySoundIsOn  =1;
            puffScalar                 =penaltyScalar;
            
            rm=constantReinforcement(rewardScalar,requestRewardScalar,penaltyScalar,puffScalar,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,requestMode);
        end
        
        function tm = makeStandardTrialManagerNAFC(requestRewardON)
            if ~exist('requestRewardON','var')|| isempty(requestRewardON)
                requestRewardON = false;
            end

            % Create Sound Manager
            sm = BCoreUtil.makeStandardSoundManager();
            
            % Reward Manager
            rm = BCoreUtil.makeStandardReinforcementManager(requestRewardON);
            
            
            dropFrames=false;
            percentCorrectionTrials = 0.5;
            frameDropCorner={'off'};
            saveDetailedFrameDrops = false;
            reqPort = 'center';
            customDescription = 'trialNAFC';
            showText = 'full';
            responseWindowMS = [1 inf];
            tm=nAFC(sm,rm,noDelay,frameDropCorner,dropFrames,reqPort,saveDetailedFrameDrops,customDescription,responseWindowMS,showText,percentCorrectionTrials);
        end
        
        function tm = makeStandardTrialManagerNAFCNoRequest()
            % Create Sound Manager
            sm = BCoreUtil.makeStandardSoundManager();
            
            % Reward Manager
            rm = BCoreUtil.makeStandardReinforcementManager();
            
            % delayManager
            dm = flatHazard(0.999,5000,500);
            
            dropFrames=false;
            percentCorrectionTrials = 0.5;
            frameDropCorner={'off'};
            saveDetailedFrameDrops = false;
            reqPort = 'none';
            customDescription = 'trialNAFC_HeadFix';
            showText = 'full';
            responseWindowMS = [1 inf];
            tm=nAFC(sm,rm,dm,frameDropCorner,dropFrames,reqPort,saveDetailedFrameDrops,customDescription,responseWindowMS,showText,percentCorrectionTrials);
        end
        
        function [tmAuto, tmEarned] = makeStandardTrialManagerFreeDrinks()
            % Create Sound Manager
            sm = BCoreUtil.makeStandardSoundManager();
            
            % Reward Manager
            rm = BCoreUtil.makeStandardReinforcementManager();
            
            % delayManager
            dm = noDelay;
            
            dropFrames=false;
            frameDropCorner={'off'};
            saveDetailedFrameDrops = false;
            reqPort = 'none';
            showText = 'full';
            responseWindowMS = [1 inf];
            
            freeDrinkLikelihood = 0.001;
            allowRepeats = false;
            tmAuto=freeDrinks(sm,rm,dm,frameDropCorner,dropFrames,reqPort,saveDetailedFrameDrops,responseWindowMS,showText,...
                freeDrinkLikelihood,allowRepeats);
            
            freeDrinkLikelihood = 0;
            tmEarned=freeDrinks(sm,rm,dm,frameDropCorner,dropFrames,reqPort,saveDetailedFrameDrops,responseWindowMS,showText,...
                freeDrinkLikelihood,allowRepeats);
        end
        
        function tm = makeStandardTrialManagerGNG()
            % Create Sound Manager
            sndm = BCoreUtil.makeStandardSoundManagerGNG();
            
            % Reward Manager
            rm = BCoreUtil.makeStandardReinforcementManager();
            
            
            dropFrames=false;
            percentCorrectionTrials = 0.5;
            frameDropCorner={'off'};
            saveDetailedFrameDrops = false;
            reqPort = 'center';
            customDescription = 'trialGNG';
            showText = 'full';
            responseWindowMS = [1 inf];
            fractionGo = 0.5;
            responseLockoutMs = 1000;
            rewardCorrectRejection = false;
            punishIncorrectRejection = false;
            tm=goNoGo(sndm,rm,noDelay,frameDropCorner,dropFrames,reqPort,saveDetailedFrameDrops,...
                responseWindowMS,customDescription,showText,fractionGo,percentCorrectionTrials,responseLockoutMs,...
                rewardCorrectRejection,punishIncorrectRejection);
        end
        
        function rx = createDefaultBCore()
            % create base BCore
            remake = true;
            rx = BCore(BCoreUtil.getServerDataPath,remake);
            
            % create station
            id = '1U';
            mac=BCoreUtil.getMACaddressSafely();
            physicalLocation = uint8([1 1 1]);
            stationPath = fullfile(BCoreUtil.getBCoreDataPath,'Stations','station1');
            st = BCoreUtil.makeDefaultStation(id,stationPath,mac,physicalLocation);
            %st = BCoreUtil.makeDefaultKBStation(id,stationPath,mac,physicalLocation);
            
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
        
        function rx = createDefaultPhysiologyBCore()
            % create base BCore
            remake = true;
            rx = BCore(BCoreUtil.getServerDataPath,remake);
            
            % create station
            id = '1U';
            mac=BCoreUtil.getMACaddressSafely();
            physicalLocation = uint8([1 1 1]);
            stationPath = fullfile(BCoreUtil.getBCoreDataPath,'Stations','station1');
            st = BCoreUtil.makeDefaultPhysiologyStation(id,stationPath,mac,physicalLocation);
            
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
        
        function st=makeDefaultStation(id,path,mac,physicalLocation,~,~,~,~,~)
            
            % our standard parallel port pin assignments
            % pin register	invert	dir	purpose
            %---------------------------------------------------
            % 1   control	inv     i/o	NA
            % 2   data              i/o right reward valve (cooldrive valve 1)
            % 3   data              i/o	center reward valve (cooldrive valve 2)
            % 4   data              i/o	left reward valve (cooldrive valve 3)
            % 5   data              i/o	NA
            % 6   data              i/o NA
            % 7   data              i/o	NA
            % 8   data              i/o NA
            % 9   data              i/o NA
            % 10  status            i   center lick sensor
            % 11  status    inv     i	NA
            % 12  status            i   right lick sensor
            % 13  status            i   left lick sensor
            % 14  control	inv     i/o	NA
            % 15  status            i
            % 16  control           i/o NA
            % 17  control	inv     i/o NA
            % STILL AVAILABLE: 
            
            switch computer
                case {'PCWIN64','PCWIN32','PCWIN'}
                    st=standardVisionBehaviorStation(id, path, mac, physicalLocation, 'D010', int8([4,3,2]), int8([13,10,12]));
                case 'MACI64'
                    st = standardOSXStation(id, path, mac, physicalLocation);
            end
        end
        
        function st=makeDefaultKBStation(id,path,mac,physicalLocation,~,~,~,~,~)
            switch computer
                case {'PCWIN64','PCWIN32','PCWIN'}
                    st=standardKBStation(id, path, mac, physicalLocation);
                case 'MACI64'
                    st = standardOSXStation(id, path, mac, physicalLocation);
            end
        end
        
        function st=makeDefaultPhysiologyStation(id,path,mac,physicalLocation,~,~,~,~,~)
            
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
            
            switch computer
                case {'PCWIN64','PCWIN32','PCWIN'}
                    st=standardVisionPhysiologyStationWithLED(id, path, mac, physicalLocation, '0378', int8([4,3,2]), int8([13,10,12]));
                case 'MACI64'
                    st = standardOSXStation(id, path, mac, physicalLocation);
            end
        end
        
        %% standard protocol List
        function r = setProtocolDEMO(r,subjIDs)
            assert(isa(r,'BCore'),'BCoreUtil:setProtocolDEMO:invalidInput','need a BCore object. You sent object of class %s',class(r));
            % TrialManager
            tm = BCoreUtil.makeStandardTrialManagerNAFC();
            
            ts = BCoreUtil.createDEMOTrainingStep(tm, repeatIndefinitely(),noTimeOff(), 'easyAFC');
            
            descriptiveString='DEMO protocol 4/5/2016';
            
            pElementaryVision100915 = protocol(descriptiveString,...
                {ts});
            stepNum = 1;
            %%%%%%%%%%%%
            for i=1:length(subjIDs)
                subj=getSubjectFromID(r,subjIDs{i});
                [~, r]=setProtocolAndStep(subj,pElementaryVision100915,true,false,true,stepNum,r,'call to setProtocolMIN','bas');
            end
            
        end
        
        function r = setProtocolDEMOFreeDrinks(r,subjIDs)
            assert(isa(r,'BCore'),'BCoreUtil:setProtocolDEMO:invalidInput','need a BCore object. You sent object of class %s',class(r));
            % TrialManager
            [tm1,tm2] = BCoreUtil.makeStandardTrialManagerFreeDrinks();
            
            [ts1,ts2] = BCoreUtil.createFreeDrinksTrainingSteps({tm1,tm2}, repeatIndefinitely(),noTimeOff(), 'easyFreeDrinks v0.0.1 Apr-17-2018');
            
            descriptiveString='DEMO Free drink protocol 3/16/2018';
            
            pFreeDrink03162018 = protocol(descriptiveString,...
                {ts1,ts2});
            stepNum = 1;
            %%%%%%%%%%%%
            for i=1:length(subjIDs)
                subj=getSubjectFromID(r,subjIDs{i});
                [~, r]=setProtocolAndStep(subj,pFreeDrink03162018,true,false,true,stepNum,r,'call to setProtocolDEMOFreeDrinks','bas');
            end
            
        end
        
        function r = setProtocolBehavior(r,subjIDs)
            assert(isa(r,'BCore'),'BCoreUtil:setProtocolDEMO:invalidInput','need a BCore object. You sent object of class %s',class(r));
            % TrialManager
            [tm1,tm2] = BCoreUtil.makeStandardTrialManagerFreeDrinks();
            requestRewardON = true;
            tm3 = BCoreUtil.makeStandardTrialManagerNAFC(requestRewardON);
            requestRewardON = false;
            tm4 = BCoreUtil.makeStandardTrialManagerNAFC(requestRewardON);
            
            ts1 = BCoreUtil.createFreeDrinksTrainingSteps(tm1, repeatIndefinitely(),noTimeOff(), 'easyFreeDrinks v0.0.2 Apr-17-2018 stochastic');
            ts2 = BCoreUtil.createFreeDrinksTrainingSteps(tm2, repeatIndefinitely(),noTimeOff(), 'easyFreeDrinks v0.0.2 Apr-17-2018 earned');
            ts3 = BCoreUtil.createDEMOTrainingStepAFCGratingsPosition(tm3,repeatIndefinitely(),noTimeOff(),'easy afcGratings v0.0.2 May-15-2018 w/ request reward');
            ts4 = BCoreUtil.createDEMOTrainingStepAFCGratingsPosition(tm4,repeatIndefinitely(),noTimeOff(),'easy afcGratings v0.0.2 May-15-2018 no request reward');
            descriptiveString='DEMO Behavior protocol 5/16/2018 v0.0.2';
            
            pBehavior05152018 = protocol(descriptiveString,...
                {ts1,ts2,ts3,ts4});
            stepNum = 3;
            %%%%%%%%%%%%
            for i=1:length(subjIDs)
                subj=getSubjectFromID(r,subjIDs{i});
                [~, r]=setProtocolAndStep(subj,pBehavior05152018,true,false,true,stepNum,r,'call to setProtocolBehavior','bas');
            end
            
        end
        
        function r = setProtocolDEMONoRequest(r,subjIDs)
            assert(isa(r,'BCore'),'BCoreUtil:setProtocolDEMONoRequest:invalidInput','need a BCore object. You sent object of class %s',class(r));
            % TrialManager
            tm = BCoreUtil.makeStandardTrialManagerNAFCNoRequest();
            
            ts = BCoreUtil.createDEMOTrainingStepAFCGratings(tm, repeatIndefinitely(),noTimeOff(), 'easyAFC');
            
            descriptiveString='DEMO protocol 4/5/2016';
            
            pElementaryVision100915 = protocol(descriptiveString,...
                {ts});
            stepNum = 1;
            %%%%%%%%%%%%
            for i=1:length(subjIDs)
                subj=getSubjectFromID(r,subjIDs{i});
                [~, r]=setProtocolAndStep(subj,pElementaryVision100915,true,false,true,stepNum,r,'call to setProtocolMIN','bas');
            end
            
        end
        
        function r = setProtocolHeadFixed(r,subjIDs)
            assert(isa(r,'BCore'),'BCoreUtil:setProtocolDEMONoRequest:invalidInput','need a BCore object. You sent object of class %s',class(r));
            % TrialManager FreeDrinks
            [tmStoch, tmEarned] = BCoreUtil.makeStandardTrialManagerFreeDrinksNoRequest();
            ts1 = BCoreUtil.createFreeDrinksTrainingSteps(tmStoch,repeatIndefinitely(),noTimeOff(), 'Stochastic FreeDrinks');
            ts2 = BCoreUtil.createFreeDrinksTrainingSteps(tmEarned,repeatIndefinitely(),noTimeOff(), 'Earned FreeDrinks');
            
            % TrialManager NAFC
            tm = BCoreUtil.makeStandardTrialManagerNAFCNoRequest();
            ts3 = BCoreUtil.createDEMOTrainingStepAFCGratings(tm, repeatIndefinitely(),noTimeOff(), 'easyAFC');
            
            descriptiveString='DEMO protocol 4/5/2016';
            
            pElementaryVision100915 = protocol(descriptiveString,...
                {ts1,ts2,ts3});
            stepNum = 1;
            %%%%%%%%%%%%
            for i=1:length(subjIDs)
                subj=getSubjectFromID(r,subjIDs{i});
                [~, r]=setProtocolAndStep(subj,pElementaryVision100915,true,false,true,stepNum,r,'call to setProtocolMIN','bas');
            end
            
        end
        
        function r = setProtocolDEMOGNG(r,subjIDs)
            
            assert(isa(r,'BCore'),'BCoreUtil:setProtocolDEMOGNG:invalidInput','need a BCore object. You sent object of class %s',class(r));
            % TrialManager
            tm = BCoreUtil.makeStandardTrialManagerGNG();
            
            ts = BCoreUtil.createDEMOTrainingStepGNG(tm, repeatIndefinitely(),noTimeOff(), 'easyAFC');
            
            descriptiveString='DEMO protocol 4/5/2016';
            
            pElementaryVision100915 = protocol(descriptiveString,...
                {ts});
            stepNum = 1;
            %%%%%%%%%%%%
            for i=1:length(subjIDs)
                subj=getSubjectFromID(r,subjIDs{i});
                [~, r]=setProtocolAndStep(subj,pElementaryVision100915,true,false,true,stepNum,r,'call to setProtocolMIN','bas');
            end
            
        end
        
        function ts = createDEMOTrainingStep(trialManager, performanceCrit, sch, stepName)
            % makes a basic, easy drifting grating training step
            % correct response = side toward which grating drifts?
            
            numDots = {100,100};                            % Number of dots to display
            bkgdNumDots = {0,0};                            % task irrelevant dots
            dotCoherence = {0.8, 0.8};                      % Percent of dots to move in a specified direction
            bkgdCoherence = {0.2, 0.2};                     % percent of bkgs dots moving in the specified direction
            dotSpeed = {2,2};                               % How fast do our little dots move (dotSize/sec)
            bkgdSpeed = {0.9,0.9};                          % speed of bkgd dots
            dotDirection = {pi,0};                          % 0 is to the right. pi is to the left
            bkgdDirection = {0:pi/4:2*pi,0:pi/4:2*pi};      % 0 is to the right. pi is to the left
            dotColor = {[1 1 1 0.5],[1 1 1 0.5]};           % can be a single number< 1 (used as a gray scale value); a single row of 3/4 (RGB/RGBA) ; or many rows o4 the above number sets in which case randomly chosen
            bkgdDotColor = {[1 0 1 0.5],[1 0 1 0.5]};       % can be a single number< 1 (used as a gray scale value); a single row of 3/4 (RGB/RGBA) ; or many rows o4 the above number sets in which case randomly chosen
            dotSize = {60,60};                              % Width of dots in pixels
            bkgdSize = {30,30};                             % Width in pixels
            dotShape = {{'circle'},{'circle'}};             % 'circle' or 'rectangle'
            bkgdShape = {{'square'},{'square'}};            % 'circle' or 'square'
            renderMode = {'flat'};                          % {'flat'} or {'perspective',[renderDistances]}{'perspective',[1 5]};
            % renderDistance = NaN;                           % is 1 for flat and is a range for perspective
            maxDuration = {inf, inf};                       % in seconds (inf is until response)
            background = 0;                                 % black background
            maxWidth=1920;
            maxHeight=1080;
            scaleFactor=0;
            interTrialLuminance={.5,120};
            doCombos = true;
            doPostDiscrim=false;
            
            AFCDOTS = afcCoherentDots(numDots,bkgdNumDots, dotCoherence,bkgdCoherence, dotSpeed,bkgdSpeed, dotDirection,bkgdDirection,...
                dotColor,bkgdDotColor, dotSize,bkgdSize, dotShape,bkgdShape, renderMode, maxDuration,background,...
                maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos,doPostDiscrim);
            
            % training step using other objects as passed in
            ts = trainingStep(trialManager, AFCDOTS, performanceCrit, sch,stepName);
        end
        
        function ts = createDEMOTrainingStepAFCGratings(trialManager, performanceCrit, sch, stepName)
            % makes a basic, easy gngGrating training step
            % correct response = side toward which grating tilts
            
            % gratings stim manager
            pixPerCycs={[256,128],[256,128]};
            driftfrequencies={[0],[0]};
            orientations={-deg2rad([45]),deg2rad([45])};
            phases={[0],[0]};
            contrasts={[1],[1]};
            maxDuration={[1],[1]};
            radii={[0.5],[0.5]};
            radiusType = 'hardEdge';
            annuli={[0],[0]};
            location={[.5 .5],[0.5 0.5]};      % center of mask
            waveform= 'sine';
            normalizationMethod='normalizeDiagonal';
            mean=0.5;
            thresh=.00005;
            maxWidth=1920;
            maxHeight=1080;
            scaleFactor=0;
            interTrialLuminance=.5;
            doCombos = true;
            
            doPostDiscrim = true;
            phaseDetails = [];
            LEDParams.active = false;
            LEDParams.numLEDs = 0;
            
            AFCGRAT = afcGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,radiusType,annuli,location,...
                waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance,doCombos,doPostDiscrim);

            
            % training step using other objects as passed in
            ts = trainingStep(trialManager, AFCGRAT, performanceCrit, sch,stepName);
        end
        
        function ts = createDEMOTrainingStepAFCGratingsPosition(trialManager, performanceCrit, sch, stepName)
            % makes a basic, easy gngGrating training step
            % correct response = side toward which grating tilts
            
            % gratings stim manager
            pixPerCycs={[128],[128]};
            driftfrequencies={[0],[0]};
            orientations={deg2rad([0,45,90,135]),deg2rad([0,45,90,135])};
            phases={linspace(0,2*pi,8),linspace(0,2*pi,8)};
            contrasts={[1],[1]};
            maxDuration={[1],[1]};
            radii={[0.2],[0.2]};
            radiusType = 'gaussian';
            annuli={[0],[0]};
            location={[.25 .5],[0.75 0.5]};      % center of mask
            waveform= 'sine';
            normalizationMethod='normalizeDiagonal';
            mean=0.5;
            thresh=.00005;
            maxWidth=1920;
            maxHeight=1080;
            scaleFactor=0;
            interTrialLuminance=.5;
            doCombos = true;
            
            doPostDiscrim = true;
            phaseDetails = [];
            LEDParams.active = false;
            LEDParams.numLEDs = 0;
            
            AFCGRAT = afcGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,radiusType,annuli,location,...
                waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance,doCombos,doPostDiscrim);

            
            % training step using other objects as passed in
            ts = trainingStep(trialManager, AFCGRAT, performanceCrit, sch,stepName);
        end
        
        function ts = createFreeDrinksTrainingSteps(trialManager, performanceCrit, sch, stepName)
            % makes a basic, easy gngGrating training step
            % correct response = side toward which grating tilts
            
            pixPerCycs              =[64];
            targetOrientations      =[pi/2];
            distractorOrientations  =[];
            mean                    =.5;
            radius                  =.075;
            contrast                =1;
            thresh                  =.00005;
            yPosPct                 =.65;
            maxWidth                =1920;
            maxHeight               =1080;
            scaleFactor             =[1 1];
            interTrialLuminance     =.5;
            waveform = 'square';
            normalizedSizeMethod = 'normalizeVertical';
            FREESTIM = orientedGaborsFreeDrinks(pixPerCycs,targetOrientations,distractorOrientations,mean,radius,contrast,thresh,...
                yPosPct,maxWidth,maxHeight,scaleFactor,interTrialLuminance,waveform,normalizedSizeMethod);
            
            
            % training step using other objects as passed in
            ts = trainingStep(trialManager, FREESTIM, performanceCrit, sch,stepName);
        end
        
        function ts = createDEMOTrainingStepGNG(trialManager, performanceCrit, sch, stepName)
            % makes a basic, easy gngGrating training step
            % correct response = side toward which grating tilts
            
            % gratings stim manager
            pixPerCycs={[256,128],[256,128]};
            driftfrequencies={[0],[0]};
            orientations={-deg2rad([45]),deg2rad([45])};
            phases={[0],[0]};
            contrasts={[1],[1]};
            maxDuration={[1],[1]};
            radii={[0.2],[0.2]};
            radiusType = 'hardEdge';
            annuli={[0],[0]};
            location={[.5 .5],[0.5 0.5]};      % center of mask
            waveform= 'sine';
            normalizationMethod='normalizeDiagonal';
            mean=0.5;
            thresh=.00005;
            maxWidth=1920;
            maxHeight=1080;
            scaleFactor=0;
            interTrialLuminance=.5;
            doCombos = true;
            
            doPostDiscrim = true;
            phaseDetails = [];
            LEDParams.active = false;
            LEDParams.numLEDs = 0;
            
            GNGGRAT = gngGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,radiusType,annuli,location,...
                waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance,doCombos,doPostDiscrim,phaseDetails,LEDParams);

            
            % training step using other objects as passed in
            ts = trainingStep(trialManager, GNGGRAT, performanceCrit, sch,stepName);
        end
        
        %% Trial processing
        function replicateTrialRecords(paths,deleteOnSuccess)
            % This function transforms the raw, local trialRecords file into the formatted permanent-store trialRecords file.
            % Does the following:
            %   1) calls collectTrialRecords to format from {tr1,tr2,tr3,etc} to vectorized format
            %   2) does LUT processing
            %   3) Copy the trial records stored in the (local) BCoreData directory to the
            %       set of paths given in paths. Typically, paths is a location on the fileserver (ie each subject's permanent store path).
            
            input_paths = paths;
            
            subDirs=struct([]); % cannot pre allocate - number of subject files is unknown
            boxesDirs=fullfile(BCoreUtil.getBasePath,'BCoreData','Boxes');
            boxDirsToCheck=BCoreUtil.cleandir(boxesDirs);
            for b=1:length(boxDirsToCheck)
                subjectDirs=fullfile(boxesDirs,boxDirsToCheck(b).name,'subjectData');
                subjectDirsToCheck=BCoreUtil.cleandir(subjectDirs);
                for s=1:length(subjectDirsToCheck)
                    subName=subjectDirsToCheck(s).name;
                    subDir=fullfile(subjectDirs,subName);
                    if length(dir(fullfile(subDir,'trialRecords.mat')))==1
                        subDirs(end+1).dir=subDir;
                        subDirs(end).name=subName;
                        subDirs(end).file='trialRecords.mat';
                    end
                end
            end
            
            for f=1:length(subDirs)
                subjectName=subDirs(f).name;
                filePath=subDirs(f).dir;
                fileName=subDirs(f).file;
                
                % most likely failure mode is corrupt files
                [~,fn,fe]=fileparts(fileName);
                try
                    tr=load(fullfile(filePath,fileName)); %this is safe cuz it's local
                catch ME
                    switch ME.identifier
                        case 'MATLAB:load:unableToReadMatFile'
                            warning('BCoreUtil:replicateTrialPaths:corruptFile','can''t load file %s, renaming',fullfile(filePath,fileName))
                            tr.trialRecords=[];
                            movefile(fullfile(filePath,fileName),fullfile(filePath,['corrupt.' fileName '.' datestr(now,30) '.corrupt']));
                        otherwise
                            disp(['CAUGHT ERROR: ' getReport(ME,'extended')])
                            error('BCoreUtil:replicateTrialPaths:unknownError','unknown load problem');
                    end
                end
                
                % collection process
                trialRecords = BCoreUtil.collectTrialRecords(tr);
                trialNums=[trialRecords.trialNumber];
                % 3/17/09 - do the 'collection' and LUTizing here, then resave to local trialRecords.mat
                % because the replicate processes uses movefile instead of matlab save
                sessionLUT={};
                fieldsInLUT={};
                
                % 5/5/09 - lets try splitting the processFields according to trainingStepNum
                tsNums=double([trialRecords.trainingStepNum]);
                tsIntervals=[];
                tsIntervals(:,1)=[tsNums(find(diff(tsNums))) tsNums(end)]';
                tsIntervals(:,2)=[1 find(diff(tsNums))+1];
                tsIntervals(:,3)=[find(diff(tsNums)) length(tsNums)];
                
                for i=1:size(tsIntervals,1) % for each interval, process
                    fields=fieldnames([trialRecords(tsIntervals(i,2):tsIntervals(i,3))]);
                    % do not process the 'result' or 'type' fields because they will mess up LUT handling
                    % both fields could potentially contain strings and numerics mixed (bad for LUT indexing!)
                    fields(find(strcmp(fields,'result')))=[];
                    fields(find(strcmp(fields,'type')))=[];
                    [sessionLUT, fieldsInLUT, trialRecords(tsIntervals(i,2):tsIntervals(i,3))] = ...
                        BCoreUtil.processFields(fields,sessionLUT,fieldsInLUT,trialRecords(tsIntervals(i,2):tsIntervals(i,3)));
                end
                
                save(fullfile(filePath,fileName),'trialRecords','sessionLUT','fieldsInLUT');
                
                newFileName=[fn '_' num2str(trialNums(1)) '-' num2str(trialNums(end)) '_' ...
                    datestr(trialRecords(1).date,30) '-' datestr(trialRecords(end).date,30) fe];
                
                success = false(1,length(paths));
                for j=1:length(paths)
                    
                    [success(j), ~, messageID]=mkdir(fullfile(paths{j},subjectName));

                    switch messageID
                        case {'','MATLAB:MKDIR:DirectoryExists'}
                            d=BCoreUtil.cleandir(fullfile(paths{j},subjectName));
                            %not safe cuz of windows networking/filesharing bug -- but will just result in overwriting existing trialRecord file in case of name collision, should never happen -- ultimately just compare against filenames in oracle
                            fileAlreadyExists = ismember({d.name},newFileName);
                            if any(fileAlreadyExists)
                                % move the file to '.old'
                                dt=datevec(now);
                                frac=dt(6)-floor(dt(6));
                                successM=movefile(fullfile(paths{j},subjectName,newFileName),fullfile(paths{j},subjectName,['old.' newFileName '.old.' datestr(dt,30) '.' sprintf('%03d',floor(frac*1000))]));
                                success(j)=success(j) && successM;
                            end
                            if success(j)
                                paths{j} = fullfile(paths{j},subjectName);
                                successC=copyfile(fullfile(filePath,fileName),fullfile(paths{j},newFileName));
                                if ~successC
                                    error('couldn''t copy file')
                                end
                                success(j)=success(j) && successC;
                            end
                            
                        case 'MATLAB:MKDIR:OSError'
                            warning('BCoreUtil:replicateTrialRecords:UnableToAccess','file path is not accessible');
                            % ## need to find ways to check if file
                            % path is remote and if so make success
                            % "true" again. this happens only when
                            % ethernet is gone
                    end
                end
                
                if deleteOnSuccess && all(success)
                    delete(fullfile(filePath,fileName));
                    % no sending data to back up bullshit!!
                elseif ~all(success)
                    BCoreUtil.notify(BCoreUtil.EXPERIMENTER,'BCoreUtil:replicateTrialRecords:IncompleteProcessing',paths(~success));
                end
            end
            
        end
        
        function trialRecords = getTrialRecordsFromPermanentStore(permanentStorePath, subjectID, filter, trustOsRecordFiles, subjectSpecificPermStore, serverDataPath)
            % r,sID, {filterType filterParameters}
            % {'dateRange',<dateFromInclusive dateToInclusive>} -- valid input for date num and length==2
            % {'lastNTrials', numTrials}
            % {'all'}
            %
            % 9/30/08 - added serverDataPath argument to getTrialRecordsFromPermanentStore call for location of temp.mat file
            
            
            trialRecords = [];
            
            if isempty(permanentStorePath)
                return
            end
            
            % Make the directory all the way down to the subject
            if subjectSpecificPermStore
                subjPath = permanentStorePath;
            else
                subjPath = fullfile(permanentStorePath,subjectID);
            end
            if ~isdir(subjPath) %not a problem if this fails due to windows filesharing/networking bug, cuz mkdir just noops with warning if dir exists
                [succ, msg, msgid]=mkdir(fullfile(permanentStorePath,subjectID)); %9/17/08 - dont need to depend on subjectSpecificPermStore flag cuz it wont happen in that case
                if ~succ
                    error('BCoreUtil:getTrialRecordsFromPermanentStore:AccessUnavailable','couldn''t access permanent store msg : %s msgid %d path: %s',msg,msgid,permanentStorePath)
                end
            end
            
            if ~trustOsRecordFiles
                %use oracle to get trailRecordFiles
                
                conn=dbConn();
                fileNames=getTrialRecordFiles(conn,subjectID);
                s = getSubject(conn,subjectID);
                closeConn(conn);
                
                % Only if the subject is not a test rat should we load files from the permanent store
                if s.test
                    'subjectID'
                    subjectID
                    warning(['Found a test subject not loading trial records']);
                    return
                end
            else
                %getTrialRecordFiles from the Os... less reliable if server is taxed...
                %but okay on local computer and has less dependency on the oracle db
                if subjectSpecificPermStore
                    fullFileNames=BCoreUtil.getTrialRecordFiles(permanentStorePath);
                else
                    fullFileNames=BCoreUtil.getTrialRecordFiles(fullfile(permanentStorePath,subjectID));
                end
                if ~isempty(fullFileNames)
                    for i=1:length(fullFileNames)
                        [filePath fileName fileExt]=fileparts(fullFileNames{i});
                        fileNames{i,1}=[fileName fileExt];
                    end %fileNames are chronological if using OS, but not necessarily if using conn to db... think it's okay because they're sorted in a few lines - pmm 08/06/26
                else
                    fileNames=[];
                end
            end
            
            if length(fileNames) <= 0
                % Normally this function is never allowed to return empty
                % the only exception is where there are no files listed in the db for
                % this subject
                warning('No records recovered from permanent store');
                return
            end

            goodRecs=BCoreUtil.getRangesFromTrialRecordFileNames(fileNames);
            
            [files lowestTrialNum highestTrialNum]=applyTrialFilter(goodRecs,filter);
            if iscell(filter)
                filterType=filter{1};
            else
                error('filter must be a cell array');
            end
            
            if length(files) <= 0
                error('Files listed in db, but no records recovered')
            end
            
            % Sort the trial record files
            [garbage sortIndices]=sort([files.trialStart]);
            files = files(sortIndices);
            
            
            for i=1:length(files)
                %'*****'
                completed=false;
                nAttempts=0;
                while ~completed
                    nAttempts = nAttempts+1;
                    try
                        %             tmpFile='C:\temp.mat';
                        % 9/29/08 - changed to be cross-platform; use top-level BCoreData folder for temp.mat
                        tmpFile = fullfile(fileparts(serverDataPath), 'temp.mat');
                        [success message messageid]=copyfile(fullfile(subjPath,files(i).name),tmpFile);
                        if ~success
                            message
                            error('Unable to copy trial records from remote store to local drive')
                        end
                        tr=load(tmpFile);
                        completed=true;
                    catch  ex
                        % Why are we doing this?  Because we don't want all of the
                        % computers to load the file from the remote store at the same
                        % time.  To cut down on the chance of this, we are
                        % (faux) nondeterministically waiting between loads
                        numSecsForLoad=GetSecs();
                        numSecsForLoad=fliplr(num2str(numSecsForLoad-floor(numSecsForLoad),'%.9g'));
                        % Take 2 off for the '0.' of the str.
                        lenSecs=length(numSecsForLoad)-2;
                        numSecsForLoad=str2num(numSecsForLoad)/10^lenSecs*10; % Up to 10 seconds between tries
                        pause(numSecsForLoad);
                        if exist('tr','var')
                            tr
                        else
                            permanentStorePath
                            subjectSpecificPermStore
                            subjectID
                            'I don''t have a tr'
                        end
                    end
                    
                end
                if ~completed
                    ple(ex)
                    rethrow(ex)
                end
                %'******'
                
                switch(filterType)
                    case 'dateRange'
                        dates = [];
                        for j=1:length(tr.trialRecords)
                            dates(end+1) = datenum(tr.trialRecords(j).date);
                        end
                        recIndices=intersect(find(dates>dateStart),find(dates < dateStop));
                        newTrialRecords = tr.trialRecords(recIndices);
                    case 'lastNTrials'
                        % NOTE: I'm only checking start, since once we hit the start
                        % value everything higher is included
                        if lowestTrialNum > files(i).trialStart
                            startIndex=find([tr.trialRecords.trialNumber]==lowestTrialNum)
                            if length(startIndex) ~= 1
                                error('trialRecords have multiple trials with the same trialNumber!')
                            end
                        else
                            startIndex = 1;
                        end
                        newTrialRecords = tr.trialRecords(startIndex:end);
                    case 'all'
                        newTrialRecords = tr.trialRecords;
                    otherwise
                        error('Unsupported filter type')
                end
                % Add the trial records
                
                
                %
                %         trialRecords
                %         newTrialRecords
                %         class(trialRecords)
                %         class(newTrialRecords)
                %         size(trialRecords)
                %         size(newTrialRecords)
                if ~isempty(trialRecords) && ~isempty(newTrialRecords)
                    f = fieldnames(trialRecords);
                    newf = fieldnames(newTrialRecords);
                    temp = f;
                    temp(end+1: end+length(newf)) = newf;
                    bothF = unique(temp);
                    
                    for i = 1: length(bothF)
                        oldHasIt(i)= ismember(bothF(i), f);
                        newHasIt(i)= ismember(bothF(i), newf);
                    end
                    
                    for oldNeedsIt=find(~oldHasIt)
                        fprintf(' old records need field: %s\n',bothF{oldNeedsIt})
                        [trialRecords(:).(bothF{oldNeedsIt})]=deal([]);
                    end
                    
                    for newNeedsIt=find(~newHasIt)
                        fprintf(' new records need field: %s\n',bothF{newNeedsIt})
                        [newTrialRecords(:).(bothF{newNeedsIt})]=deal([]);
                    end
                end
                
                trialRecords = [ trialRecords newTrialRecords];
                
                
                
            end
        end

        function [sessionLUT, fieldsInLUT, trialRecords] = processFields(fields,sessionLUT,fieldsInLUT,trialRecords,prefix)
            
            % if prefix is defined, then use it for fieldsInLUT
            if ~exist('prefix','var')
                prefix='';
            end
            
            for ii=1:length(fields)
                fn = fields{ii};
                try
                    if ~isempty(prefix)
                        fieldPath = [prefix '.' fn];
                    else
                        fieldPath = fn;
                    end
                    if ischar(trialRecords(1).(fn))
                        % this field is a char - use LUT
                        [indices sessionLUT] = BCoreUtil.addOrFindInLUT(sessionLUT,{trialRecords.(fn)});
                        for i=1:length(indices)
                            trialRecords(i).(fn) = indices(i);
                        end
                        if ~ismember(fieldPath,fieldsInLUT)
                            fieldsInLUT{end+1}=fieldPath;
                        end
                    elseif isstruct(trialRecords(1).(fn)) && ~isempty(trialRecords(1).(fn)) && ~strcmp(fn,'errorRecords')...
                            && ~strcmp(fn,'responseDetails') && ~strcmp(fn,'phaseRecords') && ~strcmp(fn,'trialDetails') ...
                            && ~strcmp(fn,'stimDetails') % check not an empty struct
                        % 12/23/08 - note that this assumes that all fields are the same structurally throughout this session
                        % this doesn't work in the case of errorRecords, which is empty sometimes, and non-empty other times
                        % this is a struct - recursively call processFields on all fields of the struct
                        thisStructFields = fieldnames((trialRecords(1).(fn)));
                        % now call processFields recursively - pass in fn as a prefix (so we know how to store to fieldsinLUT)
                        [sessionLUT, fieldsInLUT, theseStructs] = BCoreUtil.processFields(thisStructFields,sessionLUT,fieldsInLUT,[trialRecords.(fn)],fieldPath);
                        % we have to return a temporary 'theseStructs' and then manually reassign in trialRecords unless can figure out correct indexing
                        for j=1:length(trialRecords)
                            trialRecords(j).(fn)=theseStructs(j);
                        end
                    elseif iscell(trialRecords(1).(fn))
                        % if a simple cell (all entries are strings), then do LUT stuff
                        % otherwise, we should recursively look through the entries, but this is complicated and no easy way to track in fieldsInLUT
                        % because the places where you might find struct/cell in the cell array is not consistent across trials
                        % keeping track of each exact location in fieldsInLUT will result in trialRecords.stimDetails.imageDetails{i} for all i in trialRecords
                        % this kills the point of using a LUT! - for now, just don't handle complicated cases (leave as is)
                        addToLUT=false;
                        for trialInd=1:length(trialRecords)
                            thisRecordCell=[trialRecords(trialInd).(fn)];
                            if all(cellfun('isclass',thisRecordCell,'char') | cellfun('isreal',thisRecordCell)) % 3/3/09 - should change to if all(ischar or isscalar)
                                [indices sessionLUT] = BCoreUtil.addOrFindInLUT(sessionLUT,thisRecordCell);
                                trialRecords(trialInd).(fn)=indices;
                                addToLUT=true;
                            end
                        end
                        if addToLUT && ~ismember(fieldPath,fieldsInLUT)
                            fieldsInLUT{end+1}=fieldPath;
                        end
                    elseif ismember(fieldPath,fieldsInLUT)
                        % 5/5/09 - if this field was LUTized in a prior training step interval, ALWAYS LUTize it here!
                        % just do basic processing on this field (fails for char -> struct/cell conversions)
                        [indices sessionLUT] = BCoreUtil.addOrFindInLUT(sessionLUT,{trialRecords.(fn)});
                        for i=1:length(indices)
                            trialRecords(i).(fn) = indices(i);
                        end
                    end
                catch ex
                    disp(['CAUGHT EX: ' getReport(ex)]);
                    warning('LUT processing of trialRecords failed! - probably due to manual training step switching.');
                end
            end
            
        end
        
        function out = cleandir(d)
            d = dir(d);
            out = d(~ismember({d.name},{'.','..'}));
        end
        
        function trialRecords = collectTrialRecords(tr)
            % tr should be a struct with fields 'tr0', 'tr1', 'tr2', etc
            % where tr0 is a blank (empty to create the trialRecords.mat file)
            % and subsequent trN fields are the trialRecord for each the N-th trial
            %
            % we should return a struct array of trialRecords in our customary format
            % and also do some sanity checking
            
            fields=fieldnames(tr);
            unsortedRecords = [];
            order = [];
            
%             this doesnt sound like the correct thing at all!! what was happening here? wtf??
            for i=1:length(fields)
                [match, tokens] = regexpi(fields{i},'tr(\d+)','match','tokens');
                if ~isempty(match) && ~strcmp(match,'tr0')
                    order=[order str2double(tokens{1}{1})];
                    unsortedRecords=[unsortedRecords tr.(fields{i})];
                end
            end
            
            [~, ind]=sort(order);
            trialRecords=unsortedRecords(ind);
            
            if isempty(trialRecords) % when would this happen?
                return;
            end
            
            % sanity checks
            if any([trialRecords.trialNumber]~=trialRecords(1).trialNumber:trialRecords(end).trialNumber)
                error('BCoreUtil:collectTrialRecords:incorrectValue','trialNumber not monotonically increasing');
            end
            
            if length(unique([trialRecords.sessionNumber]))>1
                error('BCoreUtil:collectTrialRecords:incorrectValue','more than one unique sessionNumber');
            end
            
            if length(unique([trialRecords.subjectsInBox]))>1
                error('BCoreUtil:collectTrialRecords:incorrectValue','more than one unique subjectInBox');
            end
            
        end
        
        function out = getLastTrialNum(subjectID)
            p = fullfile(BCoreUtil.getLocalPermanentDataPath(),subjectID);
            [~,ranges] = BCoreUtil.getTrialRecordFiles(p,true);
            try
                out = max(ranges(2,:));
            catch ex
                switch ex.identifier
                    case 'MATLAB:badsubscript'
                        disp('came here because this is probably the first trial for the animal');
                        out = 0;
                    otherwise
                        sca;
                        keyboard
                        rethrow(ex)
                end
            end
        end
        
        function failures = compileRecords(ids,recompile,source,destination)
            if ~exist('recompile','var') || isempty(recompile)
                recompile = false;
            end
            
            if ~exist('source','var') || isempty(source)
                source = BCoreUtil.getLocalPermanentDataPath();
            end
            
            if ~exist('destination','var') || isempty(destination)
                destination = BCoreUtil.getLocalCompiledDataPath();
            end
            
            failures = {};
            
            if ~exist('ids','var') || isempty(ids) % if ids not given as input, retrieve from oracle or from source
                d=dir(source);
                d = d([d.isdir] & ~ismember({d.name},{'.','..'}));
                ids = {d.name};
            end
            
            % ==============================================================================================
            % get trialRecord files
            subjectFiles=cell(1,length(ids));
            ranges=cell(1,length(ids));
            
            for i=1:length(ids)
                store_path = fullfile(source, ids{i});
                [subjectFiles{i}, ranges{i}]=BCoreUtil.getTrialRecordFiles(store_path); %unreliable if remote
            end
            
            for i=1:length(ids)
%                 try
                    fprintf('\ndoing %s\n',ids{i});
                    compiledDetails=[];
                    compiledTrialRecords=[]; % used to be called basicRecs, but we want to keep same syntax as compileTrialRecords
                    compiledLUT={};
                    expectedTrialNumber=1;
                    classes={};
                    compiledRecordsDirectory=destination;
                    
                    d=dir(fullfile(compiledRecordsDirectory,[ids{i} '.compiledTrialRecords.*.mat'])); %unreliable if remote
                    compiledFile=[];
                    compiledRange=zeros(2,1);
                    addedRecords=false;
                    if length(d)>1
                        error('BCoreUtil:improperData','too many (%d) compiledRecords found for id::%s. Expected ONE',length(d),ids{i});
                    elseif length(d)<1
                        % no compilation has been done
                    else
                        [rng, num, er]=sscanf(d.name,[ids{i} '.compiledTrialRecords.%d-%d.mat'],2);
                        assert(num==2,'BCoreUtil:compileDetailedRecords:incompatibleFormat','unable to parse compiledTrialRecords - error::%s',er);
                        compiledFile=fullfile(compiledRecordsDirectory,d.name);
                        compiledRange=rng;
                    end
                        
                    % load from existing compile record if it exists
                    if ~isempty(compiledFile) && ~recompile
                        fieldNames = BCoreUtil.getStandardCompiledFields();
                        [compiledTrialRecords, compiledDetails, compiledLUT]=loadDetailedTrialRecords(compiledFile,compiledRange,fieldNames);
                        % set expectedTrialNumber
                        expectedTrialNumber = compiledTrialRecords.trialNumber(end) + 1;
                        % set classes
                        classes = cell(2,length(compiledDetails));
                        for k=1:length(compiledDetails)
                            classes{1,k} = compiledDetails(k).className; % class name
                            classes{2,k} = sort([compiledDetails(k).trialNums compiledDetails(k).bailedTrialNums]);
                        end
                    end
                    
                    allDetails=compiledDetails;
                    for j=1:length(subjectFiles{i})
                        [~, tokens] = regexpi(subjectFiles{i}{j}, 'trialRecords_(\d+)-(\d+).*\.mat', 'match', 'tokens');
                        rng=[str2double(tokens{1}{1}), str2double(tokens{1}{2})];
                        if expectedTrialNumber ~= rng(1)
                            continue; % this is not the trial records we were looking for
                        end
                        addedRecords=true; % if we ever got passed the skip, then we added records and thus can delete compiledFile
                        
                        fprintf('\tdoing %s of %d\n',subjectFiles{i}{j},ranges{i}(2,end));
                        warning('off','MATLAB:elementsNowStruc'); %expect some class defs to be out of date, will get structs instead of objects (shouldn't keep objects in records anyway)
                        tr=load(subjectFiles{i}{j});
                        warning('on','MATLAB:elementsNowStruc');
                        
                        sessionLUT=tr.sessionLUT;
                        fieldsInLUT=tr.fieldsInLUT;
                        tr=tr.trialRecords;
                        
                        % 3/5/09 - we should separate the compile process based on trainingStepNum
                        % to handle manual training step transitions gracefully
                        % tsIntervals should be [tsNum startNum stopNum; ...] for each unique ts interval
                        
                        % xx some thinking necessary about changes in protocol
                        tsNums=double([tr.trainingStepNum]);
                        tsIntervals=[];
                        tsIntervals(:,1)=[tsNums(find(diff(tsNums))) tsNums(end)]'; % find the places where tsNums changes and get tsNums there
                        tsIntervals(:,2)=[1 find(diff(tsNums))+1]; % trial numbers corresponding to start of tsInterval
                        tsIntervals(:,3)=[find(diff(tsNums)) length(tsNums)]; % trial numbers corresponding to end of tsInterval
                        loadedClasses=classes;
                        
                        for intInd=1:size(tsIntervals,1)
                            tsNum=tsIntervals(intInd,1);
                            thisTsInds=tsIntervals(intInd,2):tsIntervals(intInd,3);
                            classes=loadedClasses;
                            compiledDetails=[];
                            
                            % START COMPILE PROCESS
                            % ================================================
                            for k=thisTsInds
                                assert(tr(k).trialNumber==expectedTrialNumber,'BCoreUtil:compileRecords:incorrectData',...
                                    'unexpected trial number. Expected %d. Got %d',expectedTrialNumber,tr(k).trialNumber);
                                expectedTrialNumber=expectedTrialNumber+1;
                                if ~isempty(classes)
                                    ind=find(strcmp(BCoreUtil.LUTlookup(sessionLUT,tr(k).stimManagerClass),classes(1,:)));
                                else
                                    ind=[];
                                end
                                
                                if length(ind)==1 %should this be ind==1 if we are deleting????
                                    %nothing
                                elseif length(ind)>1
                                    error('BCoreUtil:compileRecords:unexpectedData','found more than one cached default stim manager class match')
                                else
                                    fprintf('\t\tmaking first %s\n',BCoreUtil.LUTlookup(sessionLUT,tr(k).stimManagerClass))
                                    classes{1,end+1}=BCoreUtil.LUTlookup(sessionLUT,tr(k).stimManagerClass);
                                    ind=length(classes);
                                    % this confusing term just means that we set the indices of trialRecords that belong to this class
                                    % to start indexing at 1, instead of wherever they might fall on the session's multiple trainingSteps
                                    classes{2,end}=k-(thisTsInds(1)-1);
                                end
                                
                            end
                            
                            % it is very important that this function keep the same fieldNames in newBasicRecs as they were in trialRecords
                            % because otherwise we don't know which fields are using the sessionLUT
                            [newBasicRecs, compiledLUT]=stimManager.extractBasicFields(tr(thisTsInds),compiledLUT);
                            verifyAllFieldsNCols(newBasicRecs,length(tr(thisTsInds)));
                            
                            % 12/18/08 - now update newBasicRecs as appropriate (shift LUT indices by the length of compiledLUT)
                            % then add sessionLUT to compiledLUT
                            newBasicRecsToUpdate=intersect(fieldsInLUT,fields(newBasicRecs));
                            for n=1:length(newBasicRecsToUpdate)
                                % for each field in newBasicRecs that uses the sessionLUT
                                try
                                    % 1/2/09 - need to do something about fieldsInLUT to avoid this error?
                                    % Warning: 'trialManager.trialManager.reinforcementManager.reinforcementManager.rewardStrategy'
                                    % exceeds MATLAB's maximum name length of 63 characters and has been truncated to
                                    % 'trialManager.trialManager.reinforcementManager.reinforcementMan'.
                                    % - maybe separate each element of fieldsInLUT (a fieldPath) into each step, and then build thisFieldValue from that
                                    
                                    % 1/20/09 - split fieldsInLUT using \. as the delimiter, and then loop through each "step" in the path
                                    % this addresses the comment from 1/2/09
                                    pathToThisField = regexp(newBasicRecsToUpdate{n},'\.','split');
                                    thisField=newBasicRecs;
                                    for nn=1:length(pathToThisField)
                                        thisField=thisField.(pathToThisField{nn});
                                    end
                                    thisFieldValues = sessionLUT(thisField);
                                catch
                                    %                     warningStr=sprintf('could not find %s in newBasicRecs - skipping',newBasicRecsToUpdate{n});
                                    %                     warning(warningStr);
                                    continue;
                                end
                                [indices, compiledLUT] = BCoreUtil.addOrFindInLUT(compiledLUT, thisFieldValues);
                                for nn=1:length(indices)
                                    evalStr=sprintf('newBasicRecs.%s(nn) = indices(nn);',newBasicRecsToUpdate{n});
                                    eval(evalStr); % set new indices
                                end
                                %             newBasicRecs.(fieldsInLUT{n}) = indices; % set new indices based on integrated LUT
                            end
                            
                            if isempty(compiledTrialRecords)
                                compiledTrialRecords=newBasicRecs;
                            else
                                try
                                    compiledTrialRecords=BCoreUtil.concatAllFields(compiledTrialRecords,newBasicRecs);
                                catch ex
                                    keyboard
                                end
                            end
                            for c=1:size(classes,2)
                                
                                if length(classes{2,c})>0 %prevent subtle bug that is easy to write into extractDetailFields -- if you send zero trials to them, they may try to look deeper than the top level of fields, but they won't exist ('MATLAB:nonStrucReference') -- see example in crossModal.extractDetailFields()
                                    %no way to guarantee that a stim manager's calcStim will make a stimDetails
                                    %that includes all info its super class would have, so cannot call this
                                    %method on every anscestor class.  must leave calling super class's
                                    %extractDetailFields up to the sub class.
                                    colInds=classes{2,c};
                                    
                                    LUTparams=[];
                                    LUTparams.lastIndex=length(compiledLUT);
                                    LUTparams.compiledLUT=compiledLUT;
                                    % call on the class name
                                    evalStr = sprintf('%s.extractDetailFields(colsFromAllFields(newBasicRecs,colInds),tr(thisTsInds),LUTparams);',classes{1,c});
                                    [newRecs, compiledLUT]=eval(evalStr);
                                    verifyAllFieldsNCols(newRecs,length(classes{2,c}));
                                    bailed=isempty(fieldnames(newRecs)); %extractDetailFields bailed for some reason (eg unimplemented or missing fields from old records)
                                    
                                    if length(compiledDetails)<c
                                        compiledDetails(c).className=classes{1,c};
                                        if bailed
                                            compiledDetails(c).records=[];
                                        else
                                            compiledDetails(c).records=newRecs;
                                        end
                                        compiledDetails(c).trialNums=[];
                                        compiledDetails(c).bailedTrialNums=[];
                                    elseif strcmp(compiledDetails(c).className,classes{1,c})
                                        if ~bailed
                                            compiledDetails(c).records=BCoreUtil.concatAllFields(compiledDetails(c).records,newRecs);
                                        end
                                    else
                                        error('class name doesn''t match')
                                    end
                                    tmp=colsFromAllFields(newBasicRecs,colInds);
                                    if bailed
                                        compiledDetails(c).bailedTrialNums(end+1:end+length(classes{2,c}))=tmp.trialNumber;
                                    else
                                        compiledDetails(c).trialNums(end+1:end+length(classes{2,c}))=tmp.trialNumber;
                                    end
                                end
                            end
                            
                            if isempty(allDetails)
                                allDetails=compiledDetails;
                            else
                                for d=1:length(compiledDetails)
                                    [tf loc]=ismember(compiledDetails(1).className,{allDetails.className});
                                    if tf
                                        % append records, dont make new class
                                        if ~isempty(compiledDetails(d).records)
                                            allDetails(loc).records=concatAllFields(allDetails(loc).records,compiledDetails(d).records);
                                        end
                                        allDetails(loc).trialNums=[allDetails(loc).trialNums compiledDetails(d).trialNums];
                                        allDetails(loc).bailedTrialNums=[allDetails(loc).bailedTrialNums compiledDetails(d).bailedTrialNums];
                                    else
                                        allDetails=[allDetails compiledDetails(d)];
                                    end
                                end
                            end
                            
                            % END COMPILE PROCESS
                            % ================================================
                        end % end for each trainingStep loop
                        
                        % sometimes useful for debuggging or recompiling all, when errors may happen
                        buildAsYouGo=false;
                        if buildAsYouGo
                            compiledDetails=allDetails;
                            maxTrialDone=max([compiledDetails.trialNums]);
                            save(fullfile(compiledRecordsDirectory,sprintf('%s.compiledTrialRecords.%d-%d.mat',ids{i},ranges{i}(1,1),maxTrialDone)),'compiledDetails','compiledTrialRecords','compiledLUT');
                        end
                        
                        if any(cellfun(@isempty,compiledLUT))
                            warning('empty found in LUT! - WHY? debug it!')
                            %the empty will cause errors down the line... all cells must be char
                            compiledLUT
                            keyboard
                        end
                    end
                    
                    % delete old compiledDetails file if we added records
                    if addedRecords
                        delete(compiledFile);
                        % save
                        compiledDetails=allDetails;
                        save(fullfile(compiledRecordsDirectory,sprintf('%s.compiledTrialRecords.%d-%d.mat',ids{i},ranges{i}(1,1),ranges{i}(2,end))),'compiledDetails','compiledTrialRecords','compiledLUT');
                        tmp=[];
                        for c=1:length(compiledDetails)
                            newNums=[compiledDetails(c).trialNums compiledDetails(c).bailedTrialNums];
                            tmp=[tmp [newNums;repmat(c,1,length(newNums))]];
                        end
                        [a b]=sort(tmp(1,:));
                        if any(a~=1:length(a))
                            error('missing trials')
                        end
                    else
                        dispStr=sprintf('nothing to do for %s',ids{i});
                        disp(dispStr);
                    end

%                 catch ex
%                     failures{end+1} = sprintf('failed on %s: %s',ids{i},ex.identifier);
%                 end
            end % end for each subject loop
            
        end % end function
        
        function out = getStandardCompiledFields()
            out={  'trialNumber',...
                'sessionNumber',...
                'date',...
                'soundOn',...
                'physicalLocation',...
                'numPorts',...
                'step',...
                'trainingStepName',...
                'protocolName',...
                'numStepsInProtocol',...
                'manualVersion',...
                'autoVersion',...
                'protocolDate',...
                'correct',...
                'trialManagerClass',...
                'stimManagerClass',...
                'schedulerClass',...
                'criterionClass',...
                'reinforcementManagerClass',...
                'scaleFactor',...
                'type',...
                'targetPorts',...
                'distractorPorts',...
                'result',...
                'containedManualPokes',...
                'didHumanResponse',...
                'containedForcedRewards',...
                'didStochasticResponse',...
                'containedAPause',...
                'correctionTrial',...
                'numRequests',...
                'firstIRI',...
                'response',...
                'responseTime',...
                'actualRewardDuration'};
        end
        
        function [compiledTrialRecords, compiledDetails, compiledLUT]=loadDetailedTrialRecords(compiledFile,compiledRange,fieldNames)
            %loads the compiled detailed records in the specified range, for the requested (expected) field names
            %won't allow a load if the names don't match.
            %
            %12/5/08 - also returns LUT for dynamic caching
            
            fprintf('\nloading %s...\n',compiledFile);
            t=GetSecs;
            ctr=load(compiledFile);
            fprintf('elapsed time: %g\n',GetSecs-t)
            compiledTrialRecords=ctr.compiledTrialRecords;
            if isfield(ctr,'compiledDetails')
                compiledDetails=ctr.compiledDetails;
            else
                compiledDetails={};
            end
            if isfield(ctr,'compiledLUT')
                compiledLUT=ctr.compiledLUT;
            else
                compiledLUT={};
            end
            trialNums=[compiledTrialRecords.trialNumber];
            
            if ~all(trialNums==compiledRange(1):compiledRange(2)) || compiledRange(1)~=1
                compiledFile
                min(trialNums)
                max(trialNums)
                compiledRange
                error('compiledTrialRecords file found not to contain proper trial numbers')
            end
            if length(fieldNames)~=length(fields(compiledTrialRecords))
                setdiff(fieldNames,fields(compiledTrialRecords))
                warning('compiledTrialRecords have different fields than the targets (this is okay now because we have nan padding)');
            end
            for m=1:length(fieldNames)
                if ~ismember(fieldNames{m},fields(compiledTrialRecords))
                    fieldNames
                    fields(compiledTrialRecords)
                    warning('compiledTrialRecords don''t contain all target fields (this is okay now because we have nan padding)');
                end
            end
            
            %cast all vectors to be doubles (for back compatibility, in case they were logicals) pmm
            existingFields=fields(compiledTrialRecords);
            for i=1:length(existingFields)
                if ~strcmp(class(compiledTrialRecords.(existingFields{i})),'double') && ~iscell(compiledTrialRecords.(existingFields{i}))
                    compiledTrialRecords.(existingFields{i})=double(compiledTrialRecords.(existingFields{i}));
                    disp(existingFields{i})
                    warning('found a non-double vector, casting it as double')
                end
            end
        end
        
        function a=concatAllFields(a,b)
            if isempty(a) && isscalar(b) && isstruct(b)
                a=b;
                return
            end
            if isscalar(a) && isscalar(b) && isstruct(a) && isstruct(b)
                fn=fieldnames(a);
                if all(ismember(fieldnames(b),fn)) && all(ismember(fn,fieldnames(b)))
                    for k=1:length(fn)
                        try
                            numRowsBNeeds=size(a.(fn{k}),1)-size(b.(fn{k}),1);
                        catch
                            ple
                            keyboard
                        end
                        if iscell(b.(fn{k}))
                            if ~iscell(a.(fn{k})) && all(isnan(a.(fn{k})))
                                a.(fn{k})=cell(1,length(a.(fn{k})));
                                
                                %turn nans into a cell
                                %a.(fn{k});
                                %warning('that point where its slow')
                                %[x{1:length(a.(fn{k}))}]=deal(nan);  nan filling is slow, but empty filling is fast
                                %a.(fn{k})=x;
                                %keyboard
                                %[a.(fn{k}){:,end+1:end+size(b.(fn{k}),2)}]=deal(b.(fn{k}));
                                
                                % %                     %other way
                                % %                     temp=cell(1,length(a.(fn{k}))+size(b.(fn{k}),2));
                                % %                     [temp{end-size(b.(fn{k}),2)+1:end}]=deal(b.(fn{k}){:});
                                % %                     a.(fn{k})=temp;
                                
                                
                            else
                                if numRowsBNeeds~=0
                                    error('nan padding cells not yet implemented')
                                end
                                
                            end
                            [a.(fn{k}){:,end+1:end+size(b.(fn{k}),2)}]=deal(b.(fn{k}));
                        elseif ~iscell(a.(fn{k})) && ~iscell(b.(fn{k})) %anything else to check?  %isarray(a.(fn{k})) && isarray(b.(fn{k}))
                            if numRowsBNeeds>0
                                b.(fn{k})=[b.(fn{k});nan*zeros(numRowsBNeeds,size(b.(fn{k}),2))];
                            elseif numRowsBNeeds<0
                                a.(fn{k})=[a.(fn{k});nan*zeros(-numRowsBNeeds,size(a.(fn{k}),2))];
                            end
                            a.(fn{k})=[a.(fn{k}) b.(fn{k})];
                        else
                            (fn{k})
                            error('only works if both are cells or both are arrays')
                        end
                    end
                else
                    % 4/10/09 - added 'actualTargetOnSecs', 'actualTargetOffSecs', 'actualFlankerOnSecs', and 'actualFlankerOffSecs' to compiledDetails
                    % for ifFeature, which were not there previously.
                    % now, instead of erroring here, we should just fill w/ nans in a and recall concatAllFields
                    warning('a and b do not match in fields - padding with nans')
                    fieldsToNan=setdiff(fieldnames(b),fn);
                    numToNan=length(a.(fn{1}));
                    for k=1:length(fieldsToNan)
                        a.(fieldsToNan{k})=nan*ones(1,numToNan);
                    end
                    fieldsToNan=setdiff(fn,fieldnames(b));
                    numToNan=length(b.(fn{1}));
                    for k=1:length(fieldsToNan)
                        b.(fieldsToNan{k})=nan*ones(1,numToNan);
                    end
                    a=concatAllFields(a,b);
                end
            else
                a
                b
                error('a and b have to both be scalar struct')
            end
            
        end
        
        function recsToUpdate=getIntersectingFields(fieldsInLUT,recs)
            recsToUpdate={};
            for i=1:length(fieldsInLUT)
                pathToThisField = regexp(fieldsInLUT{i},'\.','split');
                thisField=recs;
                canAdd=true;
                for nn=1:length(pathToThisField)
                    if isfield(thisField,pathToThisField{nn})
                        thisField=thisField.(pathToThisField{nn});
                    else
                        canAdd=false;
                        break;
                    end
                end
                if canAdd
                    recsToUpdate{end+1}=fieldsInLUT{i};
                end
            end
            
        end
        
        function [verifiedHistoryFiles, ranges]=getTrialRecordFiles(permanentStore, doWarn)
            
            if ~exist('doWarn','var') || isempty(doWarn)
                doWarn = true;
            end
            
            if ~isempty(strfind(permanentStore,'\\')) && doWarn
                warning('BCoreUtil:getTrialRecordFiles:useWithCaution','this function is dangerous when used remotely -- dir can silently fail or return a subset of existing files')
            end
            
            %this needs to trust the FS in standalone conditions, but consider relying
            %solely on oracle for this listing when possible
            %consider merging with getTrialRecordsFromPermanentStore (using the trustOsRecordFiles flag)
            historyFiles=dir(fullfile(permanentStore,'trialRecords_*.mat'));
            
            try
                fileRecs=BCoreUtil.getRangesFromTrialRecordFileNames({historyFiles.name},true);
            catch ex
                fprintf('Issue with the permanent store : %s\n',permanentStore);
                rethrow(ex)
            end
            
            if ~isempty(fileRecs)
                ranges=[[fileRecs.trialStart];[fileRecs.trialStop]];
                
                verifiedHistoryFiles=cell(1,length(fileRecs));
                for i=1:length(fileRecs)
                    verifiedHistoryFiles{i}=fullfile(permanentStore,fileRecs(i).name);
                end
            else
                fprintf('permanent store path:%s\n',permanentStore);
                ranges=[];
                verifiedHistoryFiles={};
                warning('BCoreUtil:getTrialRecordFiles:unexpectedCondition','no filenames')
            end
        end
        
        function goodRecs=getRangesFromTrialRecordFileNames(fileNames,checkRanges)
            
            if ~exist('checkRanges','var') || isempty(checkRanges)
                checkRanges=true;
            end
            goodRecs = [];
            for i=1:length(fileNames)
                goodRecs(end+1).name=fileNames{i};
                ranges= textscan(goodRecs(end).name,'trialRecords_%d-%d_%15s-%15s.mat');
                goodRecs(end).trialStart = ranges{1};
                goodRecs(end).trialStop = ranges{2};
                goodRecs(end).dateStart = BCoreUtil.datenumFor30(ranges{3}{1});
                goodRecs(end).dateStop = BCoreUtil.datenumFor30(ranges{4}{1});
            end
            
            if checkRanges
                [~, order]=sort([goodRecs.trialStart]);
                goodRecs=goodRecs(order);
                ranges=[[goodRecs.trialStart];[goodRecs.trialStop]];
                
                assert(ranges(1,1) == 1,'BCoreUtil:getRangesFromTrialRecordFileNames:incorrectData','first file doesn''t start at 1');
                
                if ~all(ranges(1,:)==([1 ranges(2,1:end-1)+1])) || ~all(ranges(2,:)>=ranges(1,:))
                    disp(ranges);
                    disp('The problem trial ranges');
                    whichProblematic = ranges(1,:)~=([1 ranges(2,1:end-1)+1]); 
                    disp(ranges(:,whichProblematic))
                    error('ranges don''t follow consecutively')
                end
            end
        end
        %% Infrastructure
        
        function notify(WHO,SUBJECT,PARAMS)
            assert(ischar(SUBJECT),'BCoreUtil:notify:invalidInput','SUBJECT needs to be a char. instead is : %s',class(SUBJECT));
            assert(ischar(PARAMS)||iscell(PARAMS),'BCoreUtil:notify:invalidInput','PARAMS needs to be a char or cell. instead is : %s',class(PARAMS));
            switch WHO
                case BCoreUtil.EXPERIMENTER
                    BCoreUtil.mail(BCoreUtil.EXPERIMENTER,SUBJECT,PARAMS);
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
        
        function devs = getAttachedSerialDevices()
            devs = {};
            Skey = 'HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM';
            % Find connected serial devices and clean up the output
            [~, list] = dos(['REG QUERY ' Skey]);
            list = strread(list,'%s','delimiter',' ');
            coms = 0;
            for i = 1:numel(list)
                if strcmp(list{i}(1:3),'COM')
                    if ~iscell(coms)
                        coms = list(i);
                    else
                        coms{end+1} = list{i};
                    end
                end
            end
            key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';
            % Find all installed USB devices entries and clean up the output
            [~, vals] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);
            vals = textscan(vals,'%s','delimiter','\t');
            vals = cat(1,vals{:});
            out = 0;
            % Find all friendly name property entries
            for i = 1:numel(vals)
                if strcmp(vals{i}(1:min(12,end)),'FriendlyName')
                    if ~iscell(out)
                        out = vals(i);
                    else
                        out{end+1} = vals{i};
                    end
                end
            end
            % Compare friendly name entries with connected ports and generate output
            for i = 1:numel(coms)
                match = strfind(out,[coms{i},')']);
                ind = 0;
                for j = 1:numel(match)
                    if ~isempty(match{j})
                        ind = j;
                    end
                end
                if ind ~= 0
                    com = str2double(coms{i}(4:end));
                    % Trim the trailing ' (COM##)' from the friendly name - works on ports from 1 to 99
                    if com > 9
                        length = 8;
                    else
                        length = 7;
                    end
                    devs{i,1} = out{ind}(27:end-length);
                    devs{i,2} = com;
                end
            end
        end
        
        %% Utilities for Compilation
        function n=datenumFor30(x)
            %converts text strings of iso 8601 into matlab's datenum
            %oddly datenum does not support this type, maybe it's the 'T'
            %
            %x='20071013T000552'
            %y=datenumFor30 (x)
            
            year=str2double(x(1:4));
            month=str2double(x(5:6));
            day=str2double(x(7:8));
            hour=str2double(x(10:11));
            minute=str2double(x(12:13));
            second=str2double(x(14:15));
            
            n = datenum(year,month,day,hour,minute,second);
            
            assert(strcmp(x,datestr(n,30)),'BCoreUtil:datenumFor30:invalidConversion','fails to preserve ID of that time');
        end
        
        function value = LUTlookup(LUT, key)
            % returns the value specified by the given key in the LUT
            % if LUT is empty, then just return the key (for convenience in compileDetailedRecords)
            if ~isempty(LUT)
                value = LUT{key};
            else
                value=key;
            end
            
        end
        
        function [indices, LUT] = addOrFindInLUT(LUT, fields)
            % this function takes in an existing LUT and fields, both as cell arrays
            % and tries to find each element in fields in the LUT.
            % if the field does not exist in LUT, then it is added to the LUT
            % returns the updated LUT, and indices, which is an array of the same size as fields that contains the index for each element in fields
            % whether or not it was added.
            
            indices=zeros(1,length(fields));
            for i=1:length(fields)
                if ischar(fields{i})
                    result=find(strcmp(LUT,fields{i}));
                    if isempty(result) % did not find in LUT - ADD
                        LUT{end+1} = fields{i};
                        result=length(LUT);
                    end
                    indices(i)=result;
                elseif isempty(fields{i})
                    % don't add the empty set, tho it is a number according to matlab
                    indices(i)=nan;
                elseif isnumeric(fields{i})
                    result=find(cellfun(@(x) isnumeric(x)&&all(x==fields{i}), LUT));
                    if isempty(result) % did not find in LUT - ADD
                        LUT{end+1} = fields{i};
                        result=length(LUT);
                    end
                    indices(i)=result;
                else
                    error('can only add strings and numerics to the LUT');
                end
            end
            
        end % end function
    end
end