classdef randomBursts<scheduler
    %UNTITLED25 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        minsPerBurst=0;
        burstsPerDay=0;
    end
    
    methods
        function s=randomBursts(minsPerBurst,burstsPerDay)
            % RANDOMBURSTS  class constructor.  
            % s=randomBursts(minsPerBurst,burstsPerDay)
            s=s@scheduler();

            if minsPerBurst>=0 && burstsPerDay>=0
                s.minsPerBurst=minsPerBurst;
                s.burstsPerDay=burstsPerDay;
            else
                error('minsPerBurst and burstsPerDay must be >= 0')
            end

        end
        
        function d=display(s)
            d=['random bursts (minsPerBurst: ' num2str(s.minsPerBurst) ' burstsPerDay: ' num2str(s.burstsPerDay) ')'];
        end
        
    end
    
end

