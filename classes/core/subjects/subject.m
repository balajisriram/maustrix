classdef subject
    
    properties
        id = '';
        
        protocol = [];
        trainingStepNum=uint8(0);
        
        protocolVersion=uint8(0);
        manualVersion=uint8(0);
        
        history = {};
    end
    
    methods
        function s = subject(id)
            validateattributes(id,{'char'},{'nonempty'});
            s.id = id;
        end
    end
end