classdef hourRange<scheduler
  
    properties
        startHour=0;
        endHour=0;
    end
    
    methods
        function s=hourRange(startHour,endHour)
            % HOURRANGE  class constructor.  
            % s=randomBursts(startHour,endHour)
            s=s@scheduler();
         

            if startHour>=0 && endHour<=24
                s.startHour=startHour;
                s.endHour=endHour;
            else
                error('startHour must be >=0 and endHour must be <=24')
            end


        end
        
        function d=display(s)
            d=['hour range (startHour: ' num2str(s.startHour) ' endHour: ' num2str(s.endHour) ')'];
        end
        
    end
    
end

