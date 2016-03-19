classdef minutesPerSession<scheduler

    properties
        minutes = 1;
        hoursBetweenSessions =0;
    end
    
    methods
        function s=minutesPerSession(minutes,hoursBetweenSessions)
            % HOURRANGE  class constructor.
            % s=minutesPerSession(minutes)
            s=s@scheduler();
       

            if minutes>0
                s.minutes=minutes;
            else
                error('must be more than 1 minute');
            end

            if hoursBetweenSessions>0
                s.hoursBetweenSessions=hoursBetweenSessions;
            else
                error('must be positive');
            end            

        end
        
        function [keepWorking secsRemainingTilStateFlip updateScheduler scheduler] = checkSchedule (scheduler, subject, trainingStep, trialRecords, sessionNumber)
            %find the trials of this session
            %
            if ~isempty(trialRecords)
                trialsThisSession=trialRecords([trialRecords.sessionNumber]==sessionNumber);
            else
                trialsThisSession=trialRecords;
            end

            if size(trialsThisSession,2)>1

                startTime=datenum(trialsThisSession(1).date);
            else
                startTime=now;
            end

            if (now-startTime)*(24*60)>scheduler.minutes
                keepWorking=0;
            else
                keepWorking=1;
            end

            secsRemainingTilStateFlip=(now-startTime)*24*60*60;
            updateScheduler=0;
        end

        function d=display(s)
            d=['hour range (minutesPerSession: ' num2str(s.minutes) ')'];
        end
        
        function [hoursBetweenSessions] = getCurrentHoursBetweenSession(s)
            hoursBetweenSessions=s.hoursBetweenSessions;
        end
        
    end
    
end

