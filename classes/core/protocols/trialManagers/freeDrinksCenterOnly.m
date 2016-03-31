classdef freeDrinksCenterOnly<freeDrinks
    
    properties
    end
    
    methods
        function t=freeDrinksCenterOnly(soundManager, freeDrinkLikelihood, allowRepeats, reinforcementManager, eyeController, frameDropCorner, dropFrames, ...
                displayMethod, requestPort, saveDetailedFrameDrops, delayManager, responseWindowMs, showText)
            % FREEDRINKSCENTERONLY  class constructor.
            % t=freeDrinksCenterOnly(soundManager,freeDrinkLikelihood,allowRepeats,reinforcementManager, 
            %   [eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %	[delayManager],[responseWindowMs],[showText])

            t=t@freeDrinks(soundManager, freeDrinkLikelihood, allowRepeats, reinforcementManager, eyeController, frameDropCorner, dropFrames, ...
                displayMethod, requestPort, saveDetailedFrameDrops, delayManager, responseWindowMs, showText);

        end
    end
    
    methods(Static)
        
        function [targetPorts, distractorPorts, details]=assignPorts(details,~,~)
            targetPorts = 2; % assumes the center port is port 2....confirm that this is true
            distractorPorts=[];
        end
    end
    
end

