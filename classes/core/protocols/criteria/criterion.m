classdef criterion
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function s=criterion(varargin)
        % CRITERION  class constructor.  ABSTRACT CLASS -- DO NOT INSTANTIATE
        % s=criterion()

           
        end
        
        function graduate = checkCriterion(criterion,subject,trainingStep,trialRecords, compiledRecords)
            graduate=0;
        end
        
        function outStr = getNameFragment(cr)
        % returns abbreviated class name
        % should be overriden by criterion-specific strings
        % used to generate names for trainingSteps

            outStr = class(cr);

        end % end function
        
    end
    
end

