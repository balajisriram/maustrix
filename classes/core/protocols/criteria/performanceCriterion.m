classdef performanceCriterion<criterion

    properties
        pctCorrect=0;
        consecutiveTrials=0;
    end
    
    methods
        function s=performanceCriterion(pctCorrect,consecutiveTrials)
            % PERFORMANCECRITERION  class constructor.  
            % s=performanceCriterion(pctCorrect,consecutiveTrials)
            %percent correct is a vector of possible graduation points, the first one
            %that is reached will cause a graduation. For example: 
            %performanceCriterion([.95, .85], [20,200]);
            %will graduate a subject if he is 95% correct after 20 consecutive trials
            %or if he is at least 85% correct after 200 consecutive trials
            s=s@criterion();
  
            if length(pctCorrect)~=length(consecutiveTrials) || ~isvector(pctCorrect) || ~isvector(consecutiveTrials)
                error('size of percent correct must be the same as the size of consecutive trials and both must be vectors')
            end    
            if all(pctCorrect>=0 & pctCorrect<=1) && isinteger(consecutiveTrials) && all(consecutiveTrials>=1)
                s.pctCorrect=pctCorrect;
                s.consecutiveTrials=consecutiveTrials;
            else
                error('0<=pctCorrect<=1 and consecutiveTrials must be an integer >= 1')
            end

        end
        
        function [graduate details] = checkCriterion(c,subject,trainingStep,trialRecords, compiledRecords)

            fieldNames = fields(trialRecords);

            forcedRewards = 0;
            stochastic = 0;
            humanResponse = 0;

            warnStatus = false;

            trialsInTR = [trialRecords.trialNumber];
            if ~isempty(compiledRecords)
                trialsFromCR = compiledRecords.compiledTrialRecords.trialNumber;
                trialsFromCRToBeIncluded = ~ismember(trialsFromCR,trialsInTR);
                allStepNums = [compiledRecords.compiledTrialRecords.step(trialsFromCRToBeIncluded) trialRecords.trainingStepNum];
            else
                trialsFromCRToBeIncluded = [];
                allStepNums = [trialRecords.trainingStepNum];
            end
            td(length(trialRecords)).correct = nan;
            for tnum = 1:length(trialRecords)
                if isfield(trialRecords(tnum),'trialDetails') && ~isempty(trialRecords(tnum).trialDetails) ...
                        && ~isempty(trialRecords(tnum).trialDetails.correct)
                    td(tnum).correct = trialRecords(tnum).trialDetails.correct;
                else
                    td(tnum).correct = nan;
                end
            end

            if ~isempty(compiledRecords)
                allCorrects = [compiledRecords.compiledTrialRecords.correct(trialsFromCRToBeIncluded) td.correct];
            else
                allCorrects = [td.correct];
            end

            if ismember({'containedForcedRewards'},fieldNames)
                ind = find(cellfun(@isempty,{trialRecords.containedForcedRewards}));
                if ~isempty(ind)
                    warning('using pessimistic values for containedForcedRewards');
                    for i=1:length(ind)
                        trialRecords(ind(i)).containedForcedRewards = 1;
                    end
                end
                forcedRewards = [trialRecords.containedForcedRewards]==1;
            else 
                warnStatus = true;
            end

            if ~isempty(compiledRecords)
                allForcedRewards = [compiledRecords.compiledTrialRecords.containedForcedRewards(trialsFromCRToBeIncluded) forcedRewards];
            else
                allForcedRewards = [forcedRewards];
            end

            if ismember({'didStochasticResponse'},fieldNames)
                ind = find(cellfun(@isempty,{trialRecords.didStochasticResponse}));
                if ~isempty(ind)
                    warning('using pessimistic values for didStochasticResponse');
                    for i=1:length(ind)
                        trialRecords(ind(i)).didStochasticResponse = 1;
                    end
                end
                stochastic = [trialRecords.didStochasticResponse];
            else 
                warnStatus = true;
            end

            if ~isempty(compiledRecords)
                allStochastic = [compiledRecords.compiledTrialRecords.didStochasticResponse(trialsFromCRToBeIncluded) stochastic];
            else
                allStochastic = [stochastic];
            end

            if ismember({'didHumanResponse'},fieldNames)
                ind = find(cellfun(@isempty,{trialRecords.didHumanResponse}));
                if ~isempty(ind)
                    warning('using pessimistic values for didHumanResponse');
                    for i=1:length(ind)
                        trialRecords(ind(i)).didHumanResponse = 1;
                    end
                end
                humanResponse = [trialRecords.didHumanResponse];
            else 
                warnStatus = true;
            end

            if ~isempty(compiledRecords)
                allHumanResponse = [compiledRecords.compiledTrialRecords.didHumanResponse(trialsFromCRToBeIncluded) humanResponse];
            else
                allHumanResponse = [humanResponse];
            end

            if warnStatus
                warning(['checkCriterion found trialRecords of the older format. some necessary fields are missing. ensure presence of ' ...
                '''containedForcedRewards'',''didStochasticResponse'' and ''didHumanResponse'' in trialRecords to remove this warning']);
            end


            trialsThisStep=allStepNums==allStepNums(end);

            which= trialsThisStep & ~allStochastic & ~allHumanResponse & ~allForcedRewards;
            which= trialsThisStep & ~allStochastic & ~allForcedRewards;

            % modified to allow human responses to count towards graduation (performanceCriterion)
            % which= trialsThisStep & ~stochastic & ~forcedRewards;

            try
            [graduate whichCriteria correct]=aboveThresholdPerformance(c.consecutiveTrials,c.pctCorrect,[],allCorrects(which));
            catch
                sca;
                keyboard
            end

            %play graduation tone
            if graduate
                beep;
                pause(.2);
                beep;
                pause(.2);
                beep;

                if (nargout > 1)
                    details.date = now;
                    details.criteria = c;
                    details.graduatedFrom = stepNum;
                    details.allowedGraduationTo = stepNum + 1;
                    details.correct = correct;
                    details.whichCriteria = whichCriteria;
                end
            end
        end
        
        
        function d=display(s)
            d=['performance criterion (pctCorrect: ' num2str(s.pctCorrect) ' consecutiveTrials: ' num2str(s.consecutiveTrials) ')'];
        end
        
        
        
        
    end
    
end

