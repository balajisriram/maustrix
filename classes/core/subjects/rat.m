classdef rat < murine
    properties
        species = 'rat';
    end
    
    methods
        function r = rat(id,gender,strain,birthDate,receivedDate,litterID,supplier)
            r = r@murine(id,gender,strain,birthDate,receivedDate,litterID,supplier);
        end
        
        function dispStr = disp(s,str)
            if (~exist('str','var')||isempty(str)), str = ''; end
            dispStr = sprintf('species:\t\t%s\t%s',s.species,str);
            disp@subject(s,dispStr);
        end
        
    end
    
end