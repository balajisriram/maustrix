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
    
    methods(Static)
        
        function [targetPorts, distractorPorts, details]=assignPorts(details,lastTrialRec,~)
            twoTrialsAgo = lastTrialRec{2};
            lastTrialRec = lastTrialRec{1};
            if ~isempty(lastTrialRec)
                try
                    pNum = find(strcmp('reinforcement',{lastTrialRec.phaseRecords.phaseLabel}));
                    rDetails=lastTrialRec.phaseRecords(pNum-1).responseDetails;
                    lastResponse=find(rDetails.tries{end});
                catch err
                    lastResponse=[];
                end
                %             sca
                %             keyboard
                %             pNum
                %             rDetails
            else
                lastResponse=[];
            end
            
            if ~isempty(twoTrialsAgo)
                try
                    pNum = find(strcmp('reinforcement',{twoTrialsAgo.phaseRecords.phaseLabel}));
                    rDetails=twoTrialsAgo.phaseRecords(pNum-1).responseDetails;
                    secondToLastResponse=find(rDetails.tries{end});
                catch err
                    secondToLastResponse=[];
                end
                %             sca
                %             keyboard
                %             pNum
                %             rDetails
            else
                secondToLastResponse=[];
            end
            
            if length(lastResponse)>1
                lastResponse=lastResponse(1);
            end
            
            if length(secondToLastResponse)>1
                secondToLastResponse=secondToLastResponse(1);
            end
            
            if ismember(lastResponse,[1,3])
                targetPorts = [2];
            else
                if secondToLastResponse == 1
                    targetPorts = [3];
                else
                    targetPorts = [1];
                end
            end
            distractorPorts=[];
        end
    end
    
end

