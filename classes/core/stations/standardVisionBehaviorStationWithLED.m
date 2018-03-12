classdef standardVisionBehaviorStationWithLED < standardVisionBehaviorStation
    properties
        LEDPins
    end
    
    properties (Constant = true)
        numLED = 2;
        hasLED = true;
    end
    
    properties (Transient=true)
        arduinoCONN = [];
    end
    
    methods
        function s = standardVisionBehaviorStationWithLED(id, path, MAC, physLoc, decPPortAddr, valveSpec, sensorSpec)
            s = s@standardVisionBehaviorStation(id, path, MAC, physLoc, decPPortAddr, valveSpec, sensorSpec);
            % setup the LED pins
            s.LEDPins = standardVisionBehaviorStation.assignPins(int8([5,7]),'write',s.decPPortAddr,[],'LEDPins');
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
        
        function setLED(s, led)
            if length(led)==s.numLED
                led(s.ledPins.invs)=~led(s.ledPins.invs);
                lptWriteBits(s.ledPins.decAddr,s.ledPins.bitLocs,led);
            else
                error('led must be a vector of length numLED')
            end
            
        end
    end
    
end