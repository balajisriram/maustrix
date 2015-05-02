classdef mouse < murine
    properties
        species = 'mouse';
        geneticBackground = '';
        backgroundInformation = {};
    end
    
    methods
        function m = mouse(id,strain,gender,birthDate,receivedDate,litterID,supplier,geneticBackground, backgroundInformation)
            m = m@murine(id,strain,gender,birthDate,receivedDate,litterID,supplier);
            m.geneticBackground = geneticBackground;
            if exists('backgroundInformation','var') && ~isempty(backgroundInformation)
                m.backgroundInformation = backgroundInformation;
            end
        end
    end
end