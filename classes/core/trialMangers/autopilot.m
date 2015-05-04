classdef autopilot <trialManager
    properties
        % nothing new defined here
    end
    
    methods
        function a = autopilot(varargin)
            switch nargin
                case 0
                    argin{1} = soundManager();
                    argin{2} = reinforcementManager();
                    argin{3} = delayManager();
                    argin{4} = false;
                    argin{5} = false;
                    argin{6} = 'center';
                    argin{7} = false;
                    argin{8} = false;
                    argin{9} = false;
                case 9
                    argin{1} = varargin{1};
                    argin{2} = varargin{2};
                    argin{3} = varargin{3};
                    argin{4} = varargin{4};
                    argin{5} = varargin{5};
                    argin{6} = varargin{6};
                    argin{7} = varargin{7};
                    argin{8} = varargin{8};
                    argin{9} = varargin{9};
            end
            a = a@trialManager(argin);
        end
        
        function out=stationOKForTrialManager(~,s)
            validateattributes(s,{'station'},{'nonempty'})
            out = getNumPorts(s)>=3;
        end
        
        function [tm, trialDetails, result, spec, rewardSizeULorMS, requestRewardSizeULorMS, ...
                msPuff, msRewardSound, msPenalty, msPenaltySound, floatprecision, textures, destRect] = ...
                updateTrialState(tm, ~, result, spec, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, floatprecision, ...
                textures, destRect, ~, ~)
            % autopilot updateTrialState does nothing!
            
            rewardSizeULorMS=0;
            requestRewardSizeULorMS=0;
            msPuff=0;
            msRewardSound=0;
            msPenalty=0;
            msPenaltySound=0;
            
            trialDetails=[];
            if strcmp(getPhaseLabel(spec),'intertrial luminance') && ischar(result) && strcmp(result,'timeout')
                % this should be the only allowable result in autopilot
                result='timedout'; % so we continue to next trial
            end
        end  % end function
    end
    
end