classdef orientedCenterSurround<gratings
    
    properties
        pixPerCycs = {};
        driftfrequencies = {};
        orientations = {};
        phases = {};
        contrasts = {};
        durations = {};
        numRepeats = {};

        radii = {};
        radiusType = 'gaussian';
        location = [];
        waveform='sine';
        normalizationMethod='normalizeDiagonal';
        mean = 0;
        thresh = 0;

        LUT =[];
        LUTbits=0;

        doCombos=true;
        ordering = [];

    end
    
    methods
        function s=orientedCenterSurround(pixPerCycs,driftfrequencies,orientations,phases,contrasts,durations,radii,location,...
    waveform,normalizationMethod,mean,thresh,numRepeats,maxWidth,maxHeight,scaleFactor,interTrialLuminance,doCombos)
            % ORIENTEDCENTRESURROUND  class constructor.
            % s=orientedCenterSurround(pixPerCycs,driftfrequencies,orientations,phases,contrasts,durations,radii,location,...
            %   waveform,normalizationMethod,mean,thresh,numRepeats,maxWidth,maxHeight,scaleFactor,interTrialLuminance,doCombos)
            % Each of the following arguments is a 1xN vector, one element for each of N gratings
            % pixPerCycs - specified as in orientedGabors
            % driftfrequency - specified in cycles per second for now; the rate at which the grating moves across the screen
            % orientations - in radians
            % phases - starting phase of each grating frequency (in radians)
            %
            % contrasts - normalized (0 <= value <= 1) - Mx1 vector
            %
            % durations - up to MxN, specifying the duration (in seconds) of each pixPerCycs/contrast pair
            %
            % radii - the std dev of the enveloping gaussian, (by default in normalized units of the diagonal of the stim region) - can be of length N (N masks)
            % annuli - the radius of annuli that are centered inside the grating (in same units as radii)
            % location - a 2x1 vector, specifying x- and y-positions where the gratings should be centered; in normalized units as fraction of screen
            %           OR: a RFestimator object that will get an estimated location when needed
            % waveform - 'square', 'sine', or 'none'
            % normalizationMethod - 'normalizeDiagonal' (default), 'normalizeHorizontal', 'normalizeVertical', or 'none'
            % mean - must be between 0 and 1
            % thresh - must be greater than 0; in normalized luminance units, the value below which the stim should not appear
            % numRepeats - how many times to cycle through all combos
            % doCombos - a flag that determines whether or not to take the factorialCombo of all parameters (default is true)
            %   does the combinations in the following order:
            %   pixPerCycs > driftfrequencies > orientations > contrasts > phases > durations
            %   - if false, then takes unique selection of these parameters (they all have to be same length)
            %   - in future, handle a cell array for this flag that customizes the
            %   combo selection process.. if so, update analysis too
            % Mar 3 2011 - include blank trials.
            s=s@gratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,durations,radii,location,...
    waveform,normalizationMethod,mean,thresh,numRepeats,maxWidth,maxHeight,scaleFactor,interTrialLuminance,doCombos);

            
            s.ordering.method = 'ordered';
            s.ordering.seed = [];
            s.ordering.includeBlank = false;
        end
        
        
        
    end
    
end
