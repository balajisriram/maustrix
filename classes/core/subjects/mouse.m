classdef mouse < murine
    properties
        geneticBackground = '';
        backgroundInformation = {};
    end
    
    methods
        function m = mouse(id,gender,strain,birthDate,receivedDate,litterID,supplier,geneticBackground, backgroundInformation)
            m = m@murine(id,gender,strain,birthDate,receivedDate,litterID,supplier);
            m.geneticBackground = geneticBackground;
            if exists('backgroundInformation','var') && ~isempty(backgroundInformation)
                m.backgroundInformation = backgroundInformation;
            end
        end
        
        function disp(s,str)
            if (~exist('str','var')||isempty(str)), str = ''; end
            dispStr = sprintf('species:\t\t%s\t%s',s.species,str);
            disp@subject(s,dispStr);
        end
        
    end
end