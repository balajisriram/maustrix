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
    end
    
    properties (Transient=true)
        arduinoCONN = [];
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
        
        function [r, exitByFinishingTrialQuota]=doTrials(s,r,n,rn,trustOsRecordFiles)
            s = s.setupArduino();
            [r, exitByFinishingTrialQuota]=doTrials@standardVisionBehaviorStation(s,r,n,rn,trustOsRecordFiles);
        end
        
        function setStatePins(s,pin,state)
            assert(isscalar(state),'standardVisionPhysiologyStationWithLED::setStatePins::state must be scalar')
            state=logical(state);            
            
            possibles={ ...
                'frame',s.framePin; ...
                'stim',s.stimPin; ...
                'phase',s.phasePin; ...
                'index',s.indexPin...
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
            led(s.ledPins.invs)=~led(s.ledPins.invs);
            lptWriteBits(s.ledPins.decAddr,s.ledPins.bitLocs,led);
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