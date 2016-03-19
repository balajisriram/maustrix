classdef freeDrinksSidesOnly<freeDrinks
   
    properties
    end
    
    methods
        function t=freeDrinksSidesOnly(soundManager, freeDrinkLikelihood, allowRepeats, reinforcementManager, eyeController, frameDropCorner, dropFrames, ...
                displayMethod, requestPort, saveDetailedFrameDrops, delayManager, responseWindowMs, showText)
                % FREEDRINKSSIDESONLY  class constructor.
                % t=freeDrinksSidesOnly(soundManager,freeDrinkLikelihood,allowRepeats,reinforcementManager, 
                %   [eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
                %	[delayManager],[responseWindowMs],[showText])

                t=t@freeDrinks(soundManager, freeDrinkLikelihood, allowRepeats, reinforcementManager, eyeController, frameDropCorner, dropFrames, ...
                    displayMethod, requestPort, saveDetailedFrameDrops, delayManager, responseWindowMs, showText);
                    
          
        end
    end
    
end

