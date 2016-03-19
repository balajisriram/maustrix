classdef flatHazard<delayManager

    properties
        percentile=[];
        value=[];
        fixedDelayMs=[];
    end
    
    methods
        function f=flatHazard(percentile, value, fixedDelayMs)
            % the subclass flatHazard class
            % OBJ=flatHazard(percentile, value, fixedDelayMs)
            % percentile - this percentage of all delays are less than value (ie "99% of all trials are shorter than 10 sec")
            % value - in ms
            % fixedDelayMs - a fixed delay that is added to the random delay generated by the flatHazard function
            f=f@delayManager('flatHazard function');

            % percentile
            if isnumeric(percentile) && length(percentile)==1 && percentile>0 && percentile<=1
                f.percentile=percentile;
            else
                error('percentile must be >0 and <=1');
            end
            % value
            if isnumeric(value) && length(value)==1
                f.value=value;
            else
                error('value must be numeric');
            end
            % fixedDelayMs
            if isnumeric(fixedDelayMs) && length(fixedDelayMs)==1
                f.fixedDelayMs=fixedDelayMs;
            else
                error('fixedDelayMs must be numeric');
            end

        end % end function
        
        function d = calcAutoRequest(hzd)
            % returns autoRequest delay in terms of ms

            % continuous (exponential function)
            p = -hzd.value/log(1-hzd.percentile);
            d=exprnd(p)+hzd.fixedDelayMs;

            % discrete (geometric function)
            % p = 1-exp(log(1-hzd.percentile)/(hzd.value+1));
            % d=geornd(p)+hzd.fixedDelayMs;

        end
        
    end
    
end
