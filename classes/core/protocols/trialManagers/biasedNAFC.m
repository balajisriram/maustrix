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


                    % percentCorrectionTrials
            t=t@nAFC(soundManager,percentCorrectionTrials,rewardManager, ...
                eyeController,frameDropCorner,dropFrames,displayMethod,requestPorts,saveDetailedFramedrops, ...
                delayManager,responseWindowMs,showText);      
            t.bias=bias;
        end
        
        function out = getRequestBias(tM)
            out = tM.bias;
        end
        
    end
    
end

