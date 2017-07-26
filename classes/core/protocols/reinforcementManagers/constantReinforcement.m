classdef constantReinforcement<reinforcementManager
    
    properties
        fractionOpenTimeSoundIsOn = 0;
        fractionPenaltySoundIsOn = 0;
        rewardScalar = 1;
        requestRewardScalar = 1;
        penaltyScalar = 1;
        puffScalar = 1;
        requestMode='first'; % 'first','nonrepeats', or 'all'
    end
    
    methods
        function r=constantReinforcement(rewardScalar,requestRewardScalar,penaltyScalar,puffScalar,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,requestMode)
            % ||constantReinforcement||  class constructor.
            % r=constantReinforcement(rewardScalar,requestRewardScalar,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,requestMode)
            r=r@reinforcementManager();
            
            assert(isscalar(rewardScalar)&&rewardScalar>=0,'reinforcementManager:reinforcementManager:incorrectValue','rewardScalar must a single real number be >=0')
            r.rewardScalar=rewardScalar;
            
            assert(isscalar(requestRewardScalar)&&requestRewardScalar>=0,'reinforcementManager:reinforcementManager:incorrectValue','requestRewardScalar must a single real number be >=0')
            r.requestRewardScalar=requestRewardScalar;
            
            assert(isscalar(penaltyScalar)&&penaltyScalar>=0,'reinforcementManager:reinforcementManager:incorrectValue','penaltyScalar must a single real number be >=0')
            r.penaltyScalar=penaltyScalar;
            
            assert(isscalar(puffScalar)&&puffScalar>=0,'reinforcementManager:reinforcementManager:incorrectValue','puffScalar must a single real number be >=0')
            r.puffScalar=puffScalar;
            
            assert(isscalar(fractionOpenTimeSoundIsOn)&&fractionOpenTimeSoundIsOn>=0&&fractionOpenTimeSoundIsOn<=1,'reinforcementManager:reinforcementManager:incorrectValue','fractionOpenTimeSoundIsOn must a single real number be >=0')
            r.fractionOpenTimeSoundIsOn=fractionOpenTimeSoundIsOn;
            
            assert(isscalar(fractionPenaltySoundIsOn)&&fractionPenaltySoundIsOn>=0&&fractionPenaltySoundIsOn<=1,'reinforcementManager:reinforcementManager:incorrectValue','fractionPenaltySoundIsOn must a single real number be >=0')
            r.fractionPenaltySoundIsOn=fractionPenaltySoundIsOn;    

            assert(ischar(requestMode) && ismember(requestMode,{'first','nonrepeats','all'}),'reinforcementManager:reinforcementManager:incorrectValue','requestMode must be ''first'',''nonrepeats'',or ''all''');
            r.requestMode=requestMode;
            
        end
        
        function [r, rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound, updateRM] = ...
                calcReinforcement(r,subject,~,~)
            rewardSizeULorMS = subject.reward*r.rewardScalar;
            requestRewardSizeULorMS = subject.reward*r.requestRewardScalar;
            msPenalty = subject.timeout*r.penaltyScalar;
            msPuff = subject.puff*r.puffScalar;
            msRewardSound = rewardSizeULorMS*r.fractionOpenTimeSoundIsOn;
            msPenaltySound = msPenalty*r.fractionPenaltySoundIsOn;
            updateRM=0;
        end
        
        function [r, rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound, updateTM] = ...
                calcEarlyPenalty(r,subject,~) % ~ = trialRecords
            %currently only cuedGoNoGo+asymetricReinforcement relies on this, but in principle other tm that punish early responses could use it
            %... if that is the case consider factoring code out of
            %cuedGoNoGo.updateTrialState and into trialmanager.updateTrialState
            rewardSizeULorMS = 0;
            requestRewardSizeULorMS = 0;
            msPenalty = subject.timeout*r.penaltyScalar;
            msPuff = subject.puff*r.puffScalar;
            msRewardSound = 0;
            msPenaltySound = msPenalty*r.fractionPenaltySoundIsOn;
            
            updateTM=0;
        end
        
        function d=disp(r)
            d=sprintf('\n\t\t\trewardScalar:\t\t%3.3g',r.rewardScalar);
            
            %add on the superclass
            d=[d sprintf('\n\t\treinforcementManager:\t') r.reinforcementManager.disp()];
        end
                
        function d=shortDisp(r)
            d=sprintf('reward: %g\tpenalty: %g',r.rewardSizeULorMS, r.msPenalty);
        end
        
        function r = set.rewardScalar(r,val)
            assert(isscalar(val)&&val>=0,'','');
            r.rewardScalar = val;
        end
        
        function r = set.requestRewardScalar(r,val)
            assert(isscalar(val)&&val>=0,'','');
            r.requestRewardScalar = val;
        end
        
        function r = set.penaltyScalar(r,val)
            assert(isscalar(val)&&val>=0,'','');
            r.penaltyScalar = val;
        end
    end
    
end