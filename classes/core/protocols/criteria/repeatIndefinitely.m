classdef repeatIndefinitely<criterion
    
    properties
    end
    
    methods
        function s=repeatIndefinitely()
            % REPEATINDEFINITELY  class constructor.
            % s=repeatIndefinitely()
            s=s@criterion();
        end
        
        function graduate = checkCriterion(criterion,subject,trainingStep,trialRecords, compiledRecords)
            graduate=0;
        end
        
        function d=display(s)
            d='repeat indefinitely';
        end
        
        
    end
    
end

