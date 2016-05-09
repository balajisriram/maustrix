classdef constantReinforcement<reinforcementManager
    
    properties
        rewardSizeULorMS=0;
    end
    
    methods
        function r=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,...
                msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msPuff)
            % ||constantReinforcement||  class constructor.
            % r=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,...
            %   msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msPuff)
            r=r@reinforcementManager(msPenalty,msPuff,scalar,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,requestRewardSizeULorMS,requestMode);
            
            r = setRewardSizeULorMS(r,rewardSizeULorMS);
            
        end
        
        function [r, rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound, updateRM] = ...
                calcReinforcement(r,~,~, subject)
            
            [rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound] = ...
                calcCommonValues(r,r.rewardSizeULorMS,getRequestRewardSizeULorMS(r));
            
            updateRM=0;
        end
        
        function d=disp(r)
            d=[sprintf('\n\t\t\trewardSizeULorMS:\t\t%3.3g',r.rewardSizeULorMS) ...
                ];
            
            %add on the superclass
            d=[d sprintf('\n\t\treinforcementManager:\t') display(r.reinforcementManager)];
        end
        
        
        function r=setRewardSizeULorMS(r, v)
            if v>=0 && isreal(v) && isscalar(v) && isnumeric(v)
                r.rewardSizeULorMS=v;
            else
                error('rewardSizeULorMS must be real numeric scalar >=0')
            end
        end
        
        function d=shortDisp(r)
            d=sprintf('reward: %g\tpenalty: %g',r.rewardSizeULorMS, r.msPenalty);
        end
        
        
    end
    
end

