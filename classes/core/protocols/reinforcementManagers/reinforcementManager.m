classdef reinforcementManager
    
    properties
        
    end
    
    methods
        function r=reinforcementManager()
            % REINFORCEMENTMANAGER  class constructor.  ABSTRACT CLASS-- DO NOT INSTANTIATE
            % r=rewardManager(msPenalty, msPuff, scalar, fractionOpenTimeSoundIsOn, fractionPenaltySoundIsOn, requestRewardSizeULorMS, requestMode)
            %
            % fractionOpenTimeSoundIsOn - fraction of reward during which sound is played
            % fractionPenaltySoundIsOn - fraction of penalty during which sound is played
            % rewardScalar - reinforcement duration/size multiplier
            % requestRewardScalar - reinforcement duration/size multiplier
            % requestMode - one of the strings {'first', 'nonrepeats', 'all'} that specifies which requests should be rewarded within a trial
            %       'first' means only the first request is rewarded; 'nonrepeats' means all requests that are not same as previous request are rewarded
            %       'all' means all requests are rewarded
        end
        
        function [rm, updateRM] =cache(rm,~, ~)
            updateRM=0;
        end

        function d=disp(r)
            d = 'base Reinforcement manager';
        end
       
        function rm=setReinforcementParam(rm,param,val)
            try
                switch param
                    case {'scalar','rewardScalar'}
                        rm.rewardScalar = val;
                    case 'requestRewardScalar'
                        rm.requestRewardScalar = val;
                    otherwise
                        param
                        error('unrecognized param')
                end
            catch ex
                if strcmp(ex.identifier,'MATLAB:UndefinedFunction')
                    
                    warning(sprintf('can''t set %s for reinforcementManager of this class',param))
                else
                    disp('param');
                    disp(param)
                    disp('value');
                    disp(val)
                    rethrow(ex)
                end
            end
        end
    end
    
end

