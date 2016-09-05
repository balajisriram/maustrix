classdef scheduler
    
    properties
    end
    
    methods
        function s=scheduler()
            % SCHEDULER  class constructor.  ABSTRACT CLASS -- DO NOT INSTANTIATE
            % s=scheduler()

            
        end
        
        function [keepWorking, secsRemainingTilStateFlip, updateScheduler, scheduler] = checkSchedule(scheduler,subject,trainingStep,trialRecords,sessionNumber)
            keepWorking=1;
            secsRemainingTilStateFlip=0;
            updateScheduler=0;
            newScheduler=[];
        end
        
        function outStr = getNameFragment(sch)
            % returns abbreviated class name
            % should be overriden by scheduler-specific strings
            % used to generate names for trainingSteps

            outStr = class(sch);

        end % end function
        
    end
    
end

