classdef phaseReverse<stimManager
    
    properties
        contrasts = [];
        durations = [];
        radii = [];
        annuli = [];
        location = [];
        phaseform='sine';
        normalizationMethod='normalizeDiagonal';
        mean = 0;
        thresh = 0;
        numRepeats = [];
        changeableAnnulusCenter=false;
        LUT =[];
        LUTbits=0;
    end
    
    methods
        function s=phaseReverse(contrasts,durations,radii,annuli,location,waveform,normalizationMethod,mean,thresh,numRepeats,...
                   maxWidth,maxHeight,scaleFactor,interTrialLuminance,changeableAnnulusCenter)
            % ---------ABSTRACT CLASS DO NO INSTANTIATE--------------
            % PHASEREVERSE  class constructor.
            % s = phaseReverse(contrasts,durations,radii,annuli,location,waveform,normalizationMethod,mean,thresh,numRepeats,
            %       maxWidth,maxHeight,scaleFactor,interTrialLuminance)
            %
            % contrasts - normalized (0 <= value <= 1) - Mx1 vector
            % durations - up to MxN, specifying the duration (in seconds) of each
            % pixPerCycs/contrast pair
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
            % doPhaseInversion - the gratings is no longer a traveling wave and is instead a standing wave.
            s=s@stimManager(maxWidth, maxHeight, scaleFactor, interTrialLuminance);

         
            % create object using specified values
            % check for doCombos argument first (it decides other error checking)
            % contrasts
            if isvector(contrasts) && isnumeric(contrasts)
                s.contrasts=contrasts;
            else
                error('contrasts must be numbers');
            end
             % durations
            if isnumeric(durations) && all(all(durations>0))
                s.durations=durations;
            else
                error('all durations must be >0');
            end
            % radii
            if isnumeric(radii) && all(radii>0)
                s.radii=radii;
            else
                error('radii must be >= 0');
            end
            % annuli
            if isnumeric(annuli) && all(annuli>=0)
                s.annuli=annuli;
            else
                error('all annuli must be >= 0');
            end
            % numRepeats
            if isinteger(numRepeats) || isinf(numRepeats) || isNearInteger(numRepeats)
                s.numRepeats=numRepeats;
            end        
            % location
            if isnumeric(location) && all(location>=0) && all(location<=1)
                s.location=location;
            elseif isa(location,'RFestimator')
                s.location=location;
            else
                error('all location must be >= 0 and <= 1, or location must be an RFestimator object');
            end
            % phaseform
            if ischar(waveform)
                if ismember(waveform,{'sine', 'square'})
                    s.phaseform=waveform;
                else
                    error('phaseform must be ''sine'' or ''square''')
                end
            end
            % normalizationMethod
            if ischar(normalizationMethod)
                if ismember(normalizationMethod,{'normalizeVertical', 'normalizeHorizontal', 'normalizeDiagonal' , 'none'})
                    s.normalizationMethod=normalizationMethod;
                else
                    error('normalizationMethod must be ''normalizeVertical'', ''normalizeHorizontal'', or ''normalizeDiagonal'', or ''none''')
                end
            end
            % mean
            if mean >= 0 && mean<=1
                s.mean=mean;
            else
                error('0 <= mean <= 1')
            end
            % thres
            if thresh >= 0
                s.thresh=thresh;
            else
                error('thresh must be >= 0')
            end



            if ismember(changeableAnnulusCenter,[0 1])
                s.changeableAnnulusCenter=logical(changeableAnnulusCenter);
            else
                error('gratingWithChangeableAnnulusCenter must be true / false')
            end

        end
        
        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            newLUT=LUTparams.compiledLUT;

            try
                stimDetails=[trialRecords.stimDetails];
                [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                [out.doCombos newLUT] = extractFieldAndEnsure(stimDetails,{'doCombos'},'scalar',newLUT);

            catch ex
                out=handleExtractDetailFieldsException(sm,ex,trialRecords);
                verifyAllFieldsNCols(out,length(trialRecords));
                return
            end

            verifyAllFieldsNCols(out,length(trialRecords));
        end

        function s=fillLUT(s,method,linearizedRange,plotOn);
            %function s=fillLUT(s,method,linearizedRange [,plotOn]);
            %stim=fillLUT(stim,'linearizedDefault');
            %note: this calculates and fits gamma with finminsearch each time
            %might want a fast way to load the default which is the same each time
            %edf wants to migrate this to a ststion method  - this code is redundant
            %for each stim -- ACK!


            if ~exist('plotOn','var')
                plotOn=0;
            end

            useUncorrected=0;

            switch method
                case 'mostRecentLinearized'    
                    method
                    error('that method for getting a LUT is not defined');
                case 'tempLinearRedundantCode'   
                    LUTBitDepth=8;
                    numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID); 
                    ramp=[0:fraction:1];
                    grayColors= [ramp;ramp;ramp]';
                    %maybe ask for red / green / blue gun only
                    linearizedCLUT=grayColors;
                case '2009Trinitron255GrayBoxInterpBkgnd.5'

                    conn=dbConn();
                    mac='0018F35DFAC0'  % from the phys rig
                    timeRange=[datenum('06-09-2009 23:01','mm-dd-yyyy HH:MM') datenum('06-11-2009 23:59','mm-dd-yyyy HH:MM')];
                    cal=getCalibrationData(conn,mac,timeRange);
                    closeConn(conn)

                    LUTBitDepth=8;
                    spyderCdPerMsquared=cal.measuredValues;
                    stim=cal.details.method{2};
                    vals=double(reshape(stim(:,:,1,:),[],size(stim,4)));
                    if all(diff(spyderCdPerMsquared)>0) && length(spyderCdPerMsquared)==length(vals)
                        range=diff(spyderCdPerMsquared([1 end]));
                        floorSpyder=spyderCdPerMsquared(1);
                        desiredVals=linspace(floorSpyder+range*linearizedRange(1),floorSpyder+range*linearizedRange(2),2^LUTBitDepth);
                        newLUT = interp1(spyderCdPerMsquared,vals,desiredVals,'linear')/vals(end); %consider pchip
                        linearizedCLUT = repmat(newLUT',1,3);
                    else
                        error('vals not monotonic -- should fit parametrically or check that data collection OK')
                    end
                case 'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5'
                    conn=dbConn();
                    [junk mac] = getMACaddress();

                    if ~strcmp(mac,'00095B8E6171')
                        warning('using uncorrected gamma for non-rig monitors')
                        LUTBitDepth=8;
                        numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID);
                        ramp=[0:fraction:1];
                        grayColors= [ramp;ramp;ramp]';
                        %maybe ask for red / green / blue gun only
                        uncorrected=grayColors;
                        useUncorrected=1;
                    else
                        % going to consider saving the calibration in a local file. see
                        % if the local file was created that day. elase download and
                        % use file
                        checkLocal = true;
                        downloadCLUT = true;
                        if checkLocal
                            a = dir(getRatrixPath);
                            if any(ismember({a.name},'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat')) && ...
                                    datenum(a(ismember({a.name},'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat')).date)>floor(now)
                                temp = load(fullfile(getRatrixPath,'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat'));
                                linearizedCLUT = temp.cal.linearizedCLUT;
                                downloadCLUT = false;
                            end
                        end
                        if downloadCLUT
                            timeRange=[datenum('05-15-2011 00:01','mm-dd-yyyy HH:MM') datenum('05-15-2011 23:59','mm-dd-yyyy HH:MM')];
                            cal=getCalibrationData(conn,mac,timeRange);
                            closeConn(conn)
                            linearizedCLUT = cal.linearizedCLUT;
                            % now save cal
                            filename = fullfile(getRatrixPath,'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat');
                            save(filename,'cal');
                        end
                    end
                case 'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5'
                    conn=dbConn();
                    [junk mac] = getMACaddress();

                    if ~strcmp(mac,'00095B8E6171')
                        warning('using uncorrected gamma for non-rig monitors')
                        LUTBitDepth=8;
                        numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID);
                        ramp=[0:fraction:1];
                        grayColors= [ramp;ramp;ramp]';
                        %maybe ask for red / green / blue gun only
                        linearizedCLUT=grayColors;
                    else
                        % going to consider saving the calibration in a local file. see
                        % if the local file was created that day. elase download and
                        % use file
                        checkLocal = true;
                        downloadCLUT = true;
                        if checkLocal
                            a = dir(getRatrixPath);
                            if any(ismember({a.name},'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat')) && ...
                                datenum(a(ismember({a.name},'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat')).date)>floor(now)
                                temp = load(fullfile(getRatrixPath,'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat'));
                                linearizedCLUT = temp.cal.linearizedCLUT;
                                downloadCLUT = false;
                            end
                        end
                        if downloadCLUT
                            timeRange=[datenum('03-19-2011 00:01','mm-dd-yyyy HH:MM') datenum('03-19-2011 15:00','mm-dd-yyyy HH:MM')];
                            cal=getCalibrationData(conn,mac,timeRange);
                            closeConn(conn)
                            linearizedCLUT = cal.linearizedCLUT;
                            % now save cal
                            filename = fullfile(getRatrixPath,'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat');
                            save(filename,'cal');
                        end
                    end
                case 'calibrateNow'
                    %[measured_R measured_G measured_B] measureRGBscale()
                    method
                    error('that method for getting a LUT is not defined');
                otherwise
                    method
                    error('that method for getting a LUT is not defined');
            end


            s.LUT=linearizedCLUT;
        end
        
        function s=flushLUT(s)
            %method to flush the look up table, see fillLUT

            s.LUT=[];   
            s.LUTbits=0;
        end
        
        function out=stimMgrOKForTrialMgr(sm,tm)
            if isa(tm,'trialManager')
                switch class(tm)
                    case 'freeDrinks'
                        out=1;
                    case 'nAFC'
                        out=1;
                    case {'autopilot','reinforcedAutopilot'}
                        out=1;
                    case 'goNoGo'
                        out=1;
                    otherwise
                        out=0;
                end
            else
                error('need a trialManager object')
            end
        end
        
        
        
    end
    
end

