classdef constantDelay<delayManager
    
    properties
        value=[];
    end
    
    methods
        function f=constantDelay(value)
            % the subclass constantDelay class
            % OBJ=constantDelay(value)
            % value - in ms
            f=f@delayManager('constantDelay function');
            f.value=value;
        end

        function d = calcAutoRequest(c)
        % returns autoRequest delay in terms of ms
            d=c.value;
        end
    end
end

