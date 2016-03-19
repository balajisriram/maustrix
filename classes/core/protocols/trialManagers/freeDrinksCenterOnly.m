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
    
end

