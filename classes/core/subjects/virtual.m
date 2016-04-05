classdef virtual < subject
    methods
        function r = virtual(id,gender)
            r = r@subject(id,gender);
        end
        
        function dispStr = disp(s,str)
            if (~exist('str','var')||isempty(str)), str = ''; end
            dispStr = sprintf('virtual:%s',str);
            disp@subject(s,dispStr);
        end
        
    end
    
end