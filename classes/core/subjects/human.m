classdef human < subject
    properties
        otherDetails = {};
    end
    
    methods
        function h=human(id,gender,varargin)
            % HUMAN  class constructor.
            % s = subject(id,species,otherDetails)
            h = h@subject(id,gender);
            
            if nargin == 3
                h.otherDetails = varargin;
            end
        end
    end
end