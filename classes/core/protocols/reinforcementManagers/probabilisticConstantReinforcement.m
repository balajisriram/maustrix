classdef probabilisticConstantReinforcement<reinforcementManager
    
    properties
        rewardSizeULorMS=0;
        rewardProbability = 0;
    end
    
    methods
        function r=probabilisticConstantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,...
                msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msPuff)
            % ||constantReinforcement||  class constructor.
            % r=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,...
            %   msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msPuff)
            error('need to rewrite');
            r=r@reinforcementManager(msPenalty,msPuff,scalar,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,requestRewardSizeULorMS,requestMode);
            
            r = setRewardSizeULorMSAndRewardProbability(r,rewardSizeULorMS,requestRewardSizeULorMS);
            
        end
        
        function [r, rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound, updateRM] = ...
                calcReinforcement(r,subject,trialRecords,compiledRecord)
            
            [rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound] = ...
                calcCommonValues(r,r.rewardSizeULorMS,getRequestRewardSizeULorMS(r));
            rewardSizeULorMS = rewardSizeULorMS*double(rand<r.rewardProbability);
            updateRM=0;
        end
        
        function d=display(r)
            d=[sprintf('\n\t\t\trewardSizeULorMS:\t%3.3g\trewardProbabaility:\t%3.3g',r.rewardSizeULorMS, r.rewardProbability) ...
                ];
            
            %add on the superclass
            d=[d sprintf('\n\t\treinforcementManager:\t') display(r.reinforcementManager)];
        end
        
        
        function r=setRewardSizeULorMSAndRewardProbability(r, v, p)
            
            if v>=0 && isreal(v) && isscalar(v) && isnumeric(v)
                r.rewardSizeULorMS=v;
            else
                error('rewardSizeULorMS must be real numeric scalar >=0')
            end
            
            if isscalar(p) && p>=0 && p<=1
                r.rewardProbability = p;
            else
                error('reward probability should be a scalar between 0 and 1');
            end
        end
        
        function d=shortDisp(r)
            d=sprintf('reward: %g\tpenalty: %g',r.rewardSizeULorMS, r.msPenalty);
        end
        
        
    end
    
end

