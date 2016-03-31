classdef biasedNAFC<nAFC
    
    properties
        bias = 0;
    end
    
    methods
        function t=biasedNAFC(bias, soundManager,percentCorrectionTrials,rewardManager, ...
            eyeController,frameDropCorner,dropFrames,displayMethod,requestPorts,saveDetailedFramedrops, ...
            delayManager,responseWindowMs,showText)
            % BIASEDNAFC  class constructor.
            % t=biasedNAFC(soundManager,percentCorrectionTrials,rewardManager,
            %         [eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %		  [delayManager],[responseWindowMs],[showText])

            assert(percentCorrectionTrials==0,'biasedNAFC:biasedNAFC:incompatibleValue','percentCorrectiontrials should be zero for biasedNAFC');
            t=t@nAFC(soundManager,percentCorrectionTrials,rewardManager, ...
                eyeController,frameDropCorner,dropFrames,displayMethod,requestPorts,saveDetailedFramedrops, ...
                delayManager,responseWindowMs,showText);      
            t.bias=bias;
        end
        
    end
    
    methods (Static)
        function [targetPorts, distractorPorts, details]=assignPorts(details,~,responsePorts)
            % there is no concept of correction trials - bias in responses are
            % a natural part of the actual responses of the animal.
            responsePorts = sort(responsePorts);
            
            % bias is a single number - currently works only for a 2 response
            % ports
            if rand<details.bias
                targetPorts = responsePorts(1);
            else
                targetPorts = responsePorts(2);
            end
            distractorPorts=setdiff(responsePorts,targetPorts);
            
            details.chosenPort = targetPorts;
            details.correctionTrial = 0;
        end
    end
    
end

