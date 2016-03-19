classdef noTimeOff<scheduler
    
    properties
    end
    
    methods
        function s=noTimeOff()
            % NOTIMEOFF  class constructor.  
            % s=noTimeOff()
            s=s@scheduler();
        end
        
        function  [keepWorking secsRemainingTilStateFlip  updateScheduler scheduler]= checkSchedule(scheduler,subject,trainingStep, trialRecords,sessionNumber)
            keepWorking=1;
            secsRemainingTilStateFlip=0;
            updateScheduler=0;
        end
        
        function d=display(s)
            d='no time off';
        end
        
        
    end
    
end

