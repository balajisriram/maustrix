classdef standardVisionPhysiologyStationWithLED < standardVisionBehaviorStation
    properties
        trialPin
        framePin
        stimPin
        phasePin
        indexPin
        LEDPin
    end
    
    properties (Constant = true)
        numLED = 1;
        zMQURL = 'tcp://192.168.137.37:5556';
    end
    
    properties (Transient=true)
        arduinoCONN = [];
        zMQConnection = [];
    end
    
    methods
        function s = standardVisionPhysiologyStationWithLED(id, path, MAC, physLoc, decPPortAddr, valveSpec, sensorSpec)
            s = s@standardVisionBehaviorStation(id, path, MAC, physLoc, decPPortAddr, valveSpec, sensorSpec);
            % setup the trialPin, framePin, stimPin, phasePin, indexPin and LEDPin
            s.trialPin = standardVisionBehaviorStation.assignPins(int8([14]),'write',s.decPPortAddr,[],'trialPin');
            s.framePin = standardVisionBehaviorStation.assignPins(int8([9]),'write',s.decPPortAddr,[],'framePin');
            s.stimPin = standardVisionBehaviorStation.assignPins(int8([17]),'write',s.decPPortAddr,[],'stimPin');
            s.phasePin = standardVisionBehaviorStation.assignPins(int8([16]),'write',s.decPPortAddr,[],'phasePin');
            s.indexPin = standardVisionBehaviorStation.assignPins(int8([8]),'write',s.decPPortAddr,[],'indexPin');
            s.LEDPin = standardVisionBehaviorStation.assignPins(int8([5]),'write',s.decPPortAddr,[],'LEDPin');
        end
        
        function s = setupArduino(s)
            % if it gets in here, its active
            devices = BCoreUtil.getAttachedSerialDevices();
            com = [];
            for i = size(devices,1)
                if strfind(lower(devices{i,1}),'arduino')
                    com = devices{i,2};
                end
            end
            com = sprintf('COM%d',com);
            s.arduinoCONN = serial(com);
            fopen(s.arduinoCONN);
            pause(3);
        end
        
        function s = closeArduino(s)
            fclose(s.arduinoCONN);
            pause(1);
        end
        
        function s = setupZMQ(s)
            s.zMQConnection = zeroMQwrapper('StartConnectThread',s.zMQURL);
        end
        
        function s = closeZMQ(s)
            zeroMQwrapper('CloseThread',s.zMQConnection);
        end
                
        function sendZMQ(s,str)
            zeroMQwrapper('Send',s.zMQConnection,str);
        end
        
        function [r, exitByFinishingTrialQuota]=doTrials(s,r,n,rn,trustOsRecordFiles)
            s = s.setupArduino();
            s = s.setupZMQ();
            
            %this will doTrials on station=(s) of BCore=(r).
            %n=number of trials, where 0 means repeat indefinitely
            %rn is a BCore network object, which only the server uses, otherwise leave empty
            %trustOsRecordFiles is risky because we know that they can be wrong when
            %the server is taxed. The BCore downstairs does not trust them. But you
            %are free of oracle dependency. It is not recommended to trustOsRecordFiles
            %unless your permanentStore is local, then it might be okay.
            if ~exist('trustOsRecordFiles','var')
                trustOsRecordFiles=true; % bas cahnged this to debug some stuff ####
            end
            exitByFinishingTrialQuota = false;
            assert(~isempty(getStationByID(r,s.id)),...
                'standardVisionBehaviorStation:doTrials:incompatibleValue',...
                'that BCore doesn''t contain this station');
            
            subject=getCurrentSubject(s,r);
            keepWorking=1;
            trialNum=0;
            
            lastTrialNumForSubject = BCoreUtil.getLastTrialNum(subject.id);
            assert(n>=0,...
                'standardVisionBehaviorStation:doTrials:incorrectValu',...
                'n must be >= 0');
            
            ListenChar(2);
            if usejava('jvm')
                FlushEvents('keyDown');
            end
            
            try
                
                s=s.startPTB();
                
                % ==========================================================================
                
                % This is a hard coded trial records filter
                % Need to decide where to parameterize this
                filter = {'lastNTrials',int32(100)};
                
                % Load a subset of the previous trial records based on the given filter
                [trialRecords, localRecordsIndex, sessionNumber, compiledRecords] = r.getTrialRecordsForSubjectID(subject.id,filter, trustOsRecordFiles);
                
                % take care of ZMQ stuff
                pause(0.1); s.sendZMQ(sprintf('Starting recording on subject ID: %s',subject.id));
                pause(0.1); s.sendZMQ(sprintf('LocalTime: %2.3f',now));
                pause(0.1); s.sendZMQ(sprintf('MAC ID of station: %s',s.MACAddress));
                pause(0.1); s.sendZMQ(sprintf('protocol: %s',subject.protocol.id));
                pause(0.1); s.sendZMQ(sprintf('numSteps in protocol: %d',subject.protocol.numTrainingSteps));
                names = subject.protocol.getTrainingStepNames();
                for i = 1:length(names)
                    pause(0.1); s.sendZMQ(sprintf('\t %d: %s',i,names{i}));
                end
                pause(0.1);
                
                while keepWorking
                    trialNum=trialNum+1;
                    
                    s.sendZMQ(sprintf('TrialStart::%d',trialNum+lastTrialNumForSubject));
                    [subject, r, keepWorking, ~, trialRecords, s]= ...
                        subject.doTrial(r,s,rn,trialRecords,sessionNumber,compiledRecords);
                    s.sendZMQ('TrialEnd');
                    % Cut off a trial record as we increment trials, IFF we
                    % still have remote records (because we need to keep all
                    % local records to properly save the local .mat)
                    if localRecordsIndex > 1
                        trialRecords = trialRecords(2:end);
                    end
                    % Now update the local index (eventually all of the records
                    % will be local if run long enough)
                    localRecordsIndex = max(1,localRecordsIndex-1);
                    % Only save the local records to the local copy!
                    r.updateTrialRecordsForSubjectID(subject.id,trialRecords(localRecordsIndex:end));
                    
                    if n>0 && trialNum>=n
                        keepWorking=0;
                        exitByFinishingTrialQuota = true;
                    end
                end
                
                stopPTB(s);
            catch ex
                disp(['CAUGHT ER (at doTrials): ' getReport(ex)]);
                rethrow(ex);
            end
            
            close all
            FlushEvents('mouseUp','mouseDown','keyDown','autoKey','update');
            ListenChar(0);            
            
            s = s.closeArduino();
            s = s.closeZMQ();
        end
        
        function setStatePins(s,pin,state)
            assert(isscalar(state),'standardVisionPhysiologyStationWithLED:setStatePins:state must be scalar')
            state=logical(state);            
            
            possibles={ ...
                'frame',s.framePin; ...
                'stim',s.stimPin; ...
                'phase',s.phasePin; ...
                'index',s.indexPin;...
                'LED',s.LEDPin;...
                'trial',s.trialPin};
            
            
            for i=1:size(possibles,1)
                if strcmp('all',pin) || strcmp(pin,possibles{i,1}) %pmm finds this faster
                    %if ismember(pinClass,{'all',possibles{i,1}}) %edf worries this is slow
                    pins=possibles{i,2}; %edf worries this is slow
                    if ~isempty(pins)
                        thisState=state(ones(1,length(pins.pinNums)));
                        thisState(pins.invs)=~thisState(pins.invs);
                        lptWriteBits(pins.decAddr,pins.bitLocs,thisState);
                    else
                        warning('setStatePins:unavailableStatePins','station asked to set optional state pins it doesn''t have')
                    end
                end
            end
        end
        
        function setLED(s, led)
            led(s.LEDPin.invs)=~led(s.LEDPin.invs);
            lptWriteBits(s.LEDPin.decAddr,s.LEDPin.bitLocs,led);
        end
        
        function setFrame(s, frame)
            frame(s.framePin.invs)=~frame(s.framePin.invs);
            lptWriteBits(s.framePin.decAddr,s.framePin.bitLocs,frame);
        end
        
        function setStim(s, stim)
            stim(s.stimPin.invs)=~stim(s.stimPin.invs);
            lptWriteBits(s.stimPin.decAddr,s.stimPin.bitLocs,stim);
        end
        
        function setPhase(s, phase)
            phase(s.phasePin.invs)=~phase(s.phasePin.invs);
            lptWriteBits(s.phasePin.decAddr,s.phasePin.bitLocs,phase);
        end
        
    end
end