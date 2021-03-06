classdef murine < subject
    properties
        strain
        modification
        
        birthDate
        receivedDate
        
        litterID
        supplier
        
    end
    
    methods
        
        function m = murine(id,gender,strain,birthDate,receivedDate,litterID,supplier)
            m = m@subject(id,gender);
            validateattributes(strain,{'char'},{'nonempty'});
            assert(ismember(gender,{'male','female'}),'murine:improperValue','gender has to be ''male'' or ''female''');
            validateattributes(birthDate,{'datetime'},{'nonempty'});
            validateattributes(receivedDate,{'datetime'},{'nonempty'})
            validateattributes(litterID,{'char'},{'nonempty'});
            validateattributes(supplier,{'char'},{'nonempty'});
            
            m.strain = strain;
            m.gender = gender;
            m.birthDate = birthDate;
            m.receivedDate = receivedDate;
            m.litterID = litterID;
            m.supplier = supplier;
        end
        
        function disp(s,str) 
            dispStr = sprintf('strain:\t\t%s\tgender:\t\t%s\tbirthdate:\t\t%s\t%s',s.strain,s.gender,datestr(s.birthDate),str);
            disp@subject(s,dispStr);
        end
        
    end
    
end