classdef freeDrinksAlternate<freeDrinks
    
    properties
    end
    
    methods
        function t=freeDrinksAlternate(soundManager, freeDrinkLikelihood, allowRepeats, reinforcementManager, eyeController, frameDropCorner, dropFrames, ...
                displayMethod, requestPort, saveDetailedFrameDrops, delayManager, responseWindowMs, showText)
            % FREEDRINKSALTERNATE  class constructor.
            % t=freeDrinksAlternate(soundManager,freeDrinkLikelihood,allowRepeats,reinforcementManager, 
            %   [eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %	[delayManager],[responseWindowMs],[showText])

            t=t@freeDrinks(soundManager, freeDrinkLikelihood, allowRepeats, reinforcementManager, eyeController, frameDropCorner, dropFrames, ...
                displayMethod, requestPort, saveDetailedFrameDrops, delayManager, responseWindowMs, showText);
        end
    end
    
end

