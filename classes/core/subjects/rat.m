classdef rat < murine
    properties
        species = 'rat';
    end
    
    methods
        function r = rat(id,strain,gender,birthDate,receivedDate,litterID,supplier)
            r = r@murine(id,strain,gender,birthDate,receivedDate,litterID,supplier);
        end
    end
    
end