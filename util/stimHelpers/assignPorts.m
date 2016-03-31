%this should be a static method on trialManagers, but those are only
%available in the new matlab way of doing OOP -- we should eventually
%switch
function [targetPorts, distractorPorts, details]=assignPorts(details,lastTrialRec,responsePorts,TMclass,allowRepeats)

% figure out if this is a correction trial
lastResult=[];
lastCorrect=[];
lastWasCorrection=0;

switch TMclass
    case {'nAFC', 'oddManOut'}


    case 'biasedNAFC'

    case 'freeDrinks'

        
    case 'freeDrinksCenterOnly'
        
    case 'freeDrinksSidesOnly'

    case 'freeDrinksAlternate'

        
    case {'autopilot','reinforcedAutopilot'}
        
    case 'goNoGo'
        
    case 'changeDetectorTM'
        
    otherwise
        error('unknown TM class');
end

end % end function