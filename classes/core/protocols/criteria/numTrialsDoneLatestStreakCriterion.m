classdef numTrialsDoneLatestStreakCriterion<criterion

    properties
        numTrialsNeeded = 1;
    end
    
    methods
        function s=numTrialsDoneLatestStreakCriterion(numTrialsNeeded)
            % NUMTRIALSDONECRITERION  class constructor.
            % s=numTrialsDoneCriterion([numTrialsNeeded])
            s=s@criterion();
            
            s.numTrialsNeeded = numTrialsNeeded;
            
        end
        
        function [graduate, details] = checkCriterion(c,subject,trainingStep,trialRecords, compiledRecords)
            % this criterion will graduate if we have done a certain number of trials in this trainingStep
            graduate = 0;
            trialsInTR = [trialRecords.trialNumber];
            
            if ~isempty(compiledRecords)
                trialsFromCR = compiledRecords.compiledTrialRecords.trialNumber;
                trialsFromCRToBeIncluded = ~ismember(trialsFromCR,trialsInTR);
                allStepNums = [compiledRecords.compiledTrialRecords.step(trialsFromCRToBeIncluded) trialRecords.trainingStepNum];
            else
                allStepNums = [trialRecords.trainingStepNum];
            end
            
            trialsThisStep=allStepNums==allStepNums(end);
            trialsThisStep(1:find([1 diff(trialsThisStep)]==1,1,'last')-1) = 0;
            
            if sum(trialsThisStep) >= c.numTrialsNeeded
                graduate = 1;
            end
            
            %play graduation tone
            if graduate
                beep;
                pause(.2);
                beep;
                pause(.2);
                beep;
            end
        end
        
    end
    
end

