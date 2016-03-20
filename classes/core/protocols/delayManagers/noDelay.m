classdef noDelay<delayManager
    
    properties
        value=0;
    end
    
    methods
        function f=noDelay()
            f=f@delayManager('noDelay function');
        end

        function d = calcAutoRequest(c)
            d = 0;
        end
    end
end
