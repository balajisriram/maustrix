classdef autopilotGratings<stimManager
    % AUTOPILOTGRATINGS
    % This class is specifically designed for autopilot. It shows a single orientation
    % for the 'discrimStim'
    
    properties
        pixPerCycs = [];
        driftfrequencies = [];
        orientations = [];
        phases = [];
        contrasts = [];
        maxDuration = [];
        
        radii = [];
        radiusType = 'gaussian';
        annuli = [];
        location = [];
        waveform='square';
        normalizationMethod='normalizeDiagonal';
        mean = 0;
        thresh = 0;
        doCombos = false;
        doPostDiscrim = true;
        
        LUT =[];
        LUTbits=0;
        
        phaseDetails = [];
        LEDParams = [];
    end
    
    methods
        function s=autopilotGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,radiusType, annuli,location,...
                waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos, phaseDetails,LEDParams)
            % AUTOPILOTGRATINGS  class constructor.
            % 
            % s = autopilotGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,annuli,location,
            %       waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance)
            % Each of the following arguments is a vector of size N
            % pixPerCycs - pix/Cycle
            % driftfrequency - cyc/s
            % orientations - in radians
            % phases - in radians
            % contrasts - [0,1]
            % maxDuration - in seconds (can only be one number)
            % radii - normalized diagonal units
            % annuli - normalized diagonal units
            % location - belongs to [0,1]
            %           OR: a RFestimator object that will get an estimated location when needed
            % waveform - 'square', 'sine', or 'none'
            % normalizationMethod - 'normalizeDiagonal', 'normalizeHorizontal', 'normalizeVertical', or 'none'
            % mean - 0<=m<=1
            % thresh - >0
            % doCombos
            
            s=s@stimManager(maxWidth, maxHeight, scaleFactor,interTrialLuminance);
            
            s.doCombos = true;

            % pixPerCycs
            assert(islogical(doCombos),...
                'autopilotGratings:autopilotGratings:invalidInput','doCombos not in the right format');
            s.doCombos = doCombos;
            
            % pixPerCycs
            assert(isnumeric(pixPerCycs) && all(pixPerCycs>0),'autopilotGratings:autopilotGratings:invalidInput','pixPerCycs not in the right format');
            L = length(pixPerCycs);
            s.pixPerCycs = pixPerCycs;
            
            % driftfrequencies
            assert(isnumeric(driftfrequencies) && all(driftfrequencies>=0),...
                'autopilotGratings:autopilotGratings:invalidInput','driftfrequencies not in the right format');
            assert(doCombos || length(driftfrequencies)==L ,'autopilotGratings:autopilotGratings:incompatibleValues','the lengths don''t match.');
            s.driftfrequencies = driftfrequencies;
            
            % orientations
            assert(isnumeric(orientations) && all(~isinf(orientations)),...
                'autopilotGratings:autopilotGratings:invalidInput','orientations not in the right format');
            assert(doCombos || length(orientations)==L,'autopilotGratings:autopilotGratings:incompatibleValues','the lengths don''t match.');
            s.orientations = orientations;
            
            % phases
            assert(isnumeric(phases) && all(~isinf(phases)),...
                'autopilotGratings:autopilotGratings:invalidInput','phases not in the right format');
            assert(doCombos || length(phases)==L,'autopilotGratings:autopilotGratings:incompatibleValues','the lengths don''t match.');
            s.phases = phases;
            
            % contrasts
            assert(isnumeric(contrasts) && all(contrasts>=0) && all(contrasts<=1),...
                'autopilotGratings:autopilotGratings:invalidInput','contrasts not in the right format');
            assert(doCombos || length(contrasts)==L,'autopilotGratings:autopilotGratings:incompatibleValues','the lengths don''t match.');
            s.contrasts = contrasts;
                        
            % maxDuration
            assert(isnumeric(maxDuration) && all(maxDuration>0) && all(~isinf(maxDuration)),...
                'autopilotGratings:autopilotGratings:invalidInput','maxDuration not in the right format and cannot be infinite here');
            assert(doCombos || length(maxDuration)==L,'autopilotGratings:autopilotGratings:incompatibleValues','the lengths don''t match.');
            s.maxDuration = maxDuration;
            
            % radii
            assert(isnumeric(radii) && all(radii>=0),...
                'autopilotGratings:autopilotGratings:invalidInput','radii not in the right format');
            assert(doCombos || length(radii)==L,'autopilotGratings:autopilotGratings:incompatibleValues','the lengths don''t match.');
            s.radii = radii;
            
            % radiusType
            assert(ischar(radiusType) && ismember(radiusType,{'gaussian','hardEdge'}),'autopilotGratings:autopilotGratings:invalidInput','radiusType not in the right format')
            s.radiusType = radiusType;
            
            % annuli
            assert(isnumeric(annuli) && all(annuli>=0),...
                'autopilotGratings:autopilotGratings:invalidInput','annuli not in the right format');
            assert(doCombos || length(annuli)==L,'autopilotGratings:autopilotGratings:incompatibleValues','the lengths don''t match.');
            s.annuli = annuli;
            
            % location
            assert(isnumeric(location) && all(location>=0) && size(location,2)==2,...
                'autopilotGratings:autopilotGratings:invalidInput','location not in the right format');
            assert(doCombos || length(location)==L,'autopilotGratings:autopilotGratings:incompatibleValues','the lengths don''t match.');
            s.location = location;
            
            % waveform
            assert(ischar(waveform) && ismember(waveform,{'sine','square'}),'autopilotGratings:autopilotGratings:invalidInput','waveform not in right format');
            s.waveform = waveform;
            
            % normalizationMethod
            assert(ischar(normalizationMethod) && ismember(normalizationMethod,{'normalizeVertical', 'normalizeHorizontal', 'normalizeDiagonal' , 'none'}),...
                'autopilotGratings:autopilotGratings:invalidInput','normalizationMethod not in right format')
            s.normalizationMethod = normalizationMethod;
            
            % mean
            assert(mean>=0 && mean<=1,'autopilotGratings:autopilotGratings:invalidInput','mean not in right format')
            s.mean = mean;
            
            % thresh
            assert(thresh>=0,'autopilotGratings:autopilotGratings:invalidInput','thresh not in right format')
            s.thresh = thresh;
            
            
            % phaseDetails
            if ~isempty(phaseDetails)
                [ok, requestsLED] = stimManager.verifyPhaseDetailsOK(phaseDetails);
                assert(ok,'autopilotGratings:autopilotGratings:invalidInput','phaseDetails not OK! Look at stimManager.verifyPhaseDetailsOK for details');
                % some sanity checks about the phaseDetails:
                % phaseDetails can only have preDiscrimStim, discrimStim and postDiscrimStim
                if ~all(ismember({phaseDetails.phaseType},{'preDiscrimStim','discrimStim','postDiscrimStim'}))
                    error('autopilotGratings:autopilotGratings:invalidInput','phaseDetails can only have ''preDiscrimStim'', ''discrimStim'' and ''postDiscrimStim''');
                end
            else
                requestsLED = false;
            end
            s.phaseDetails = phaseDetails;
            
            % LEDParams
            if ~isempty(LEDParams)
                if isempty(phaseDetails)
                    error('autopilotGratings:autopilotGratings:invalidInput','LEDParams is not empty but phaseDetails is! Sad!!');
                end
                assert(stimManager.verifyLEDParamsOK(LEDParams),'autopilotGratings:autopilotGratings:invalidInput','LEDParams not OK! Look at stimManager.verifyLEDParamsOK for details');
            elseif isempty(LEDParams) && requestsLED
                error('autopilotGratings:autopilotGratings:invalidInput','LEDParams is empty but phaseDetails asks for LEDs. Disgusting and Illegal!!');
            end
            s.LEDParams = LEDParams;
            
        end
        
        function [sm,updateSM,resInd,stimList,LUT,targetPorts,distractorPorts,details,text,indexPulses,imagingTasks,ITL] =...
                calcStim(sm,tm,st,tR,~)
            resolutions = st.resolutions;
            displaySize = st.getDisplaySize();
            LUTbits = st.getLUTbits();
            scaleFactor = sm.scaleFactor;
            indexPulses=[];
            imagingTasks=[];
            [LUT, sm, updateSM]=getLUT(sm,LUTbits);
            responsePorts = [];
            
            [resInd, height, width, hz] = st.chooseLargestResForHzsDepthRatio(resolutions,[60],32,sm.maxWidth,sm.maxHeight);
            
            if isnan(resInd)
                resInd=1;
            end
                        
            details.pctCorrectionTrials = tm.percentCorrectionTrials;
            
            if ~isempty(tR) && length(tR)>=2
                lastRec=tR(end-1);
            else
                lastRec=[];
            end
            [targetPorts, distractorPorts, details] = tm.assignPorts(details,lastRec,responsePorts);
            
            % set up params for computeGabors
            height = min(height,sm.maxHeight);
            width = min(width,sm.maxWidth);
            
            stim = [];
            stim.height = height;
            stim.width = width;
            
            % whats the chosen stim?
            switch sm.doCombos
                case true
                    % choose a random value for each
                    % #### need to use the seed val somehow not used here
                    stim.pixPerCyc          = chooseFrom(sm.pixPerCycs);
                    stim.driftfrequency     = chooseFrom(sm.driftfrequencies);
                    stim.orientation        = chooseFrom(sm.orientations);
                    stim.phase              = chooseFrom(sm.phases);
                    stim.contrast           = chooseFrom(sm.contrasts);
                    stim.radius             = chooseFrom(sm.radii);
                    stim.annulus            = chooseFrom(sm.annuli);
                    stim.maxDuration        = round(chooseFrom(sm.maxDuration)*hz); % convert seconds to frames
                    stim.waveform           = sm.waveform;
                    
                    locations               = sm.location; % need to fix this
                    numLocations            = size(locations,1);
                    stim.location           = locations(chooseFrom(1:numLocations),:);
                case false
                    tempVar = randperm(length(sm.pixPerCycs));
                    which = tempVar(1);
                    stim.pixPerCyc          = sm.pixPerCycs(which);
                    stim.driftfrequency     = sm.driftfrequencies(which);
                    stim.orientation        = sm.orientations(which);
                    stim.phase              = sm.phases(which);
                    stim.contrast           = sm.contrasts(which);
                    stim.radius             = sm.radii(which);
                    stim.annulus            = sm.annuli(which);
                    stim.location           = sm.location(which,:);
                    stim.maxDuration        = round(sm.maxDuration(which)*hz);
                    stim.waveform           = sm.waveform;
            end
            
            stim.radiusType = sm.radiusType;
            stim.normalizationMethod=sm.normalizationMethod;
            stim.height=height;
            stim.width=width;
            stim.mean=sm.mean;
            stim.thresh=sm.thresh;
            stim.doCombos=sm.doCombos;
            
            % have a version in ''details''
            details.doCombos            = stim.doCombos;
            details.pixPerCyc           = stim.pixPerCyc;
            details.driftfrequency      = stim.driftfrequency;
            details.orientation         = stim.orientation;
            details.phase               = stim.phase;
            details.contrast            = stim.contrast;
            details.maxDuration         = stim.maxDuration;
            details.radius              = stim.radius;
            details.annulus             = stim.annulus;
            details.waveform            = stim.waveform;
            details.location            = stim.location;
            details.radiusType          = stim.radiusType;
            details.normalizationMethod = stim.normalizationMethod;
            details.height              = stim.height;
            details.width               = stim.width;
            details.mean                = stim.mean;
            details.thresh              = stim.thresh;
            
            TypeIsExpert = any(sm.driftfrequencies>0);
            
            switch TypeIsExpert
                case true
                    type = 'expert';
                    % radii
                    if stim.radius==Inf
                        stim.masks={[]};
                    else
                        mask=[];
                        maskParams=[stim.radius 999 0 0 ...
                            1.0 stim.thresh stim.location(1) stim.location(2)]; %11/12/08 - for some reason mask contrast must be 2.0 to get correct result
                        
                        switch details.radiusType
                            case 'gaussian'
                                mask(:,:,1)=ones(height,width,1)*stim.mean;
                                mask(:,:,2)=computeGabors(maskParams,0,width,height,...
                                    'none', stim.normalizationMethod,0,0);
                                % necessary to make use of PTB alpha blending: 1 -
                                mask(:,:,2) = 1 - mask(:,:,2); % 0 = transparent, 255=opaque (opposite of our mask)
                                stim.masks{1}=mask;
                            case 'hardEdge'
                                mask(:,:,1)=ones(height,width,1)*sm.mean;
                                [WIDTH, HEIGHT] = meshgrid(1:width,1:height);
                                mask(:,:,2)=double((((WIDTH-width*details.location(1)).^2)+((HEIGHT-height*details.location(2)).^2)-((stim.radius)^2*(height^2)))>0);
                                stim.masks{1}=mask;
                        end
                    end
                    % annulus
                    if ~(stim.annulus==0)
                        annulusCenter=stim.location;
                        annulusRadius=stim.annulus;
                        annulusRadiusInPixels=sqrt((height/2)^2 + (width/2)^2)*annulusRadius;
                        annulusCenterInPixels=[width height].*annulusCenter;
                        [x,y]=meshgrid(-width/2:width/2,-height/2:height/2);
                        annulus(:,:,1)=ones(height,width,1)*sm.mean;
                        bool=(x+width/2-annulusCenterInPixels(1)).^2+(y+height/2-annulusCenterInPixels(2)).^2 < (annulusRadiusInPixels+0.5).^2;
                        annulus(:,:,2)=bool(1:height,1:width);
                        stim.annuliMatrices{1}=annulus;
                    else
                        stim.annuliMatrices = {[]};
                    end
                case false
                    type = 'timedFrames';
                    grating = sm.computeGabor(stim); % #### new                    
            end
            
            timeout=stim.maxDuration;
            
            
            discrimStim=[];
            switch type
                case 'expert'
                    discrimStim.stimulus=stim;
                    discrimStim.stimType=type;
                    discrimStim.framesUntilTimeout=timeout;
                case 'timedFrames'
                    discrimStim.stimulus=grating;
                    discrimStim.stimType={type,uint8(timeout)};
                    discrimStim.framesUntilTimeout=timeout;
            end
            
            % discrimStim is standard
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            discrimStim.autoTrigger=[];
            discrimStim.punishResponses=false;
            discrimStim.ledON = false;
            discrimStim.soundPlayed = [];
            
            % interTrialStim is standard
            interTrialStim.interTrialLuminance = sm.interTrialLuminance;
            interTrialStim.duration = sm.interTrialDuration;
            interTrialStim.soundPlayed = [];
            ITL = sm.interTrialLuminance;
            
            details.interTrialDuration = sm.interTrialDuration();
            details.stimManagerClass = class(sm);
            details.trialManagerClass = class(tm);
            details.scaleFactor = scaleFactor;
            
            if strcmp(class(tm),'nAFC') && details.correctionTrial
                text='correction trial!';
            else
                text=sprintf('thresh: %g',sm.thresh);
            end

            stimList = {...
                'discrimStim',discrimStim;...
                'interTrialStim',interTrialStim};
            
            % setupLED
            [details, LEDDetails] = sm.setupLED(details, st);
            
            % phaseDetails
            [details, stimList] = sm.setupPhases(details, stimList, LEDDetails);
        end
        
        function [doFramePulse, expertCache, dynamicDetails, textLabel, i, dontclear, indexPulse] = ...
                drawExpertFrame(stimulus,stim,i,phaseStartTime,totalFrameNum,window,textLabel,destRect,filtMode,...
                expertCache,ifi,scheduledFrameNum,dropFrames,dontclear,dynamicDetails)
            % 11/14/08 - implementing expert mode for gratings
            % this function calculates an expert frame, and then makes and draws the texture; nothing needs to be done in runRealTimeLoop
            % this should be a stimManager-specific implementation (if expert mode is supported for the given stimulus)
            
            floatprecision=1;
            
            % increment i
            if dropFrames
                i=scheduledFrameNum;
            else
                i=i+1;
            end
            
            doFramePulse=true;
            indexPulse = false;
            
            % expertCache should contain masktexs and annulitexs
            if isempty(expertCache)
                expertCache.masktexs=[];
                expertCache.annulitexs=[];
            end
            
            black=0.0;
            white=1.0;
            gray = (white-black)/2;
            
            %stim.velocities is in cycles per second
            cycsPerFrameVel = stim.driftfrequency*ifi; % in units of cycles/frame
            offset = 2*pi*cycsPerFrameVel*i;
            
            % Create a 1D vector x based on the frequency pixPerCycs
            % make the grating twice the normal width (to cover entire screen if rotated)
            x = (1:stim.width*2)*2*pi/stim.pixPerCyc;
            switch stim.waveform
                case 'sine'
                    grating=stim.contrast*cos(x + offset+stim.phase)/2+stimulus.mean;
                case 'square'
                    grating=stim.contrast*square(x + offset+stim.phase)/2+stimulus.mean;
            end
            % Make grating texture
            gratingtex=Screen('MakeTexture',window,grating,0,0,floatprecision);
            
            % set srcRect
            srcRect=[0 0 size(grating,2) 1];
            
            % Draw grating texture, rotated by "angle":
            destWidth = destRect(3)-destRect(1);
            destHeight = destRect(4)-destRect(2);
            destRectForGrating = [destRect(1)-destWidth/2, destRect(2)-destHeight, destRect(3)+destWidth/2,destRect(4)+destHeight];
            Screen('DrawTexture', window, gratingtex, srcRect, destRectForGrating, ...
                (180/pi)*stim.orientation, filtMode);
            try
                if ~isempty(stim.masks{1})
                    % Draw gaussian mask over grating: We need to subtract 0.5 from
                    % the real size to avoid interpolation artifacts that are
                    % created by the gfx-hardware due to internal numerical
                    % roundoff errors when drawing rotated images:
                    % Make mask to texture
                    Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % necessary to do the transparency blending
                    if isempty(expertCache.masktexs)
                        expertCache.masktexs= Screen('MakeTexture',window,double(stim.masks{1}),0,0,floatprecision);
                    end
                    % Draw mask texture: (with no rotation)
                    Screen('DrawTexture', window, expertCache.masktexs, [], destRect,[], filtMode);
                end
                if ~isempty(stim.annuliMatrices{1})
                    Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    if isempty(expertCache.annulitexs)
                        expertCache.annulitexs=Screen('MakeTexture',window,double(stim.annuliMatrices{1}),0,0,floatprecision);
                    end
                    % Draw mask texture: (with no rotation)
                    Screen('DrawTexture',window,expertCache.annulitexs,[],destRect,[],filtMode);
                end
            catch ex
                getReport(ex);
                sca;
                keyboard
            end
            
            % clear the gratingtex from vram
            Screen('Close',gratingtex);
        end % end function
        
        function [out, newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            newLUT=LUTparams.compiledLUT;
            
            try
                stimDetails=[trialRecords.stimDetails];
                [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                [out.doCombos newLUT] = extractFieldAndEnsure(stimDetails,{'doCombos'},'scalar',newLUT);
                [out.pixPerCycs newLUT] = extractFieldAndEnsure(stimDetails,{'pixPerCycs'},'scalar',newLUT);
                [out.driftfrequencies newLUT] = extractFieldAndEnsure(stimDetails,{'driftfrequencies'},'scalar',newLUT);
                [out.orientations newLUT] = extractFieldAndEnsure(stimDetails,{'orientations'},'scalar',newLUT);
                [out.phases newLUT] = extractFieldAndEnsure(stimDetails,{'phases'},'scalar',newLUT);
                [out.contrasts newLUT] = extractFieldAndEnsure(stimDetails,{'contrasts'},'scalar',newLUT);
                [out.maxDuration newLUT] = extractFieldAndEnsure(stimDetails,{'maxDuration'},'scalar',newLUT);
                [out.radii newLUT] = extractFieldAndEnsure(stimDetails,{'radii'},'scalar',newLUT);
                [out.annuli newLUT] = extractFieldAndEnsure(stimDetails,{'annuli'},'scalar',newLUT);
                [out.afcGratingType newLUT] = extractFieldAndEnsure(stimDetails,{'afcGratingType'},'scalarLUT',newLUT);
                [out.LED newLUT] = extractFieldAndEnsure(stimDetails,{'LEDIntensity'},'equalLengthVects',newLUT);
                
                
            catch ex
                if ismember(ex.identifier,{'MATLAB:UnableToConvert'})
                    stimDetails(length(trialRecords)).correctionTrial = NaN;
                    for i = 1:length(trialRecords)
                        if isstruct(trialRecords(i).stimDetails)
                            stimDetails(i).pctCorrectionTrials = trialRecords(i).stimDetails.pctCorrectionTrials;
                            stimDetails(i).correctionTrial = trialRecords(i).stimDetails.correctionTrial;
                            stimDetails(i).afcGratingType = trialRecords(i).stimDetails.afcGratingType;
                            stimDetails(i).doCombos = trialRecords(i).stimDetails.doCombos;
                            stimDetails(i).pixPerCycs = trialRecords(i).stimDetails.pixPerCycs;
                            stimDetails(i).driftfrequencies = trialRecords(i).stimDetails.driftfrequencies;
                            stimDetails(i).orientations = trialRecords(i).stimDetails.orientations;
                            stimDetails(i).phases = trialRecords(i).stimDetails.phases;
                            stimDetails(i).contrasts = trialRecords(i).stimDetails.contrasts;
                            stimDetails(i).radii = trialRecords(i).stimDetails.radii;
                            stimDetails(i).maxDuration = trialRecords(i).stimDetails.maxDuration;
                        else
                            stimDetails(i).pctCorrectionTrials = nan;
                            stimDetails(i).correctionTrial = nan;
                            stimDetails(i).afcGratingType = 'n/a';
                            stimDetails(i).doCombos = nan;
                            stimDetails(i).pixPerCycs = nan;
                            stimDetails(i).driftfrequencies = nan;
                            stimDetails(i).orientations = nan;
                            stimDetails(i).phases = nan;
                            stimDetails(i).contrasts = nan;
                            stimDetails(i).radii = nan;
                            stimDetails(i).maxDuration = nan;
                        end
                    end
                    [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                    [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                    [out.doCombos newLUT] = extractFieldAndEnsure(stimDetails,{'doCombos'},'scalar',newLUT);
                    
                    [out.pixPerCycsCenter newLUT] = extractFieldAndEnsure(stimDetails,{'pixPerCycs'},'scalar',newLUT);
                    [out.driftfrequenciesCenter newLUT] = extractFieldAndEnsure(stimDetails,{'driftfrequencies'},'scalar',newLUT);
                    [out.orientationsCenter newLUT] = extractFieldAndEnsure(stimDetails,{'orientations'},'scalar',newLUT);
                    [out.phasesCenter newLUT] = extractFieldAndEnsure(stimDetails,{'phases'},'scalar',newLUT);
                    [out.contrastsCenter newLUT] = extractFieldAndEnsure(stimDetails,{'contrasts'},'scalar',newLUT);
                    [out.radiiCenter newLUT] = extractFieldAndEnsure(stimDetails,{'radii'},'scalar',newLUT);
                    
                    [out.maxDuration newLUT] = extractFieldAndEnsure(stimDetails,{'maxDuration'},'scalar',newLUT);
                    [out.afcGratingType newLUT] = extractFieldAndEnsure(stimDetails,{'afcGratingType'},'scalarLUT',newLUT);
                else
                    out=handleExtractDetailFieldsException(sm,ex,trialRecords);
                    verifyAllFieldsNCols(out,length(trialRecords));
                    return
                end
            end
            
            verifyAllFieldsNCols(out,length(trialRecords));
        end
        
        function out = getType(sm,stim)
            sweptParameters = autopilotGratings.getDetails(stim,'sweptParameters');
            n= length(sweptParameters);
            switch n
                case 0
                    out = 'autopilotGratings_noSweep';
                case 1
                    % sweep of a single datatype
                    switch sweptParameters{1}
                        case {'pixPerCycs','spatialFrequencies'}
                            out = 'autopilotGratings_sfSweep';
                        case 'driftfrequencies'
                            out = 'autopilotGratings_tfSweep';
                        case 'orientations'
                            out = 'autopilotGratings_orSweep';
                        case 'phases'
                            out = 'autopilotGratings_phaseSweep';
                        case 'contrasts'
                            out = 'autopilotGratings_cntrSweep';
                        case 'maxDuration'
                            out = 'autopilotGratings_durnSweep';
                        case 'radii'
                            out = 'autopilotGratings_radSweep';
                        case 'annuli'
                            out = 'autopilotGratings_annSweep';
                        otherwise
                            out = 'undefinedGratings';
                    end
                case 2
                    if all(ismember(sweptParameters,{'contrasts','radii'}))
                        out = 'autopilotGratings_cntrXradSweep';
                    elseif all(ismember(sweptParameters,{'contrasts','pixPerCycs'}))
                        out = 'autopilotGratings_cntrXsfSweep';
                    elseif all(ismember(sweptParameters,{'phases','maxDuration'}))
                        out = 'autopilotGratings_durationSweep_Stat';
                    elseif all(ismember(sweptParameters,{'phases','contrasts'}))
                        out = 'autopilotGratings_contrastSweep_Stat';
                    elseif all(ismember(sweptParameters,{'phases','pixPerCycs'}))
                        out = 'autopilotGratings_sfSweep_Stat';
                    elseif all(ismember(sweptParameters,{'phases','orientations'}))
                        out = 'autopilotGratings_orSweep_Stat';
                    elseif all(ismember(sweptParameters,{'maxDuration','phases'}))
                        out = 'autopilotGratings_durSweep_Stat';
                    elseif all(ismember(sweptParameters,{'contrasts','maxDuration'}))
                        out = 'autopilotGratings_cntrXdurSweep_Stat';
                    else
                        sweptParameters
                        error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                    end
                case 3
                    if all(ismember(sweptParameters,{'contrasts','pixPerCycs','driftFrequencies'}))
                        out = 'autopilotGratings_cntrXsfXtfSweep';
                    elseif all(ismember(sweptParameters,{'contrasts','pixPerCycs','phases'}))
                        out = 'autopilotGratings_cntrXsfStationary';
                    elseif all(ismember(sweptParameters,{'maxDuration','phases','contrasts'}))
                        out = 'autopilotGratings_cntrXdurSweep_Stat';
                    else
                        sweptParameters
                        error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                    end
                case 4
                    if all(ismember(sweptParameters,{'contrasts','pixPerCycs','driftfrequencies','orientations'}))
                        out = 'autopilotGratings_cntrXsfXtfXorSweep';
                    else
                        sweptParameters
                        error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                    end
                otherwise
                    error('unsupported type. if you want this make a name for it');
            end
        end
        
        function [details, stimList] = setupPhases(s, details, stimList, LEDDetails)
            % this is run only after we setup LEDs(assumption)
            % return if phaseDetails is empty
            details.phaseDetails = struct;
            if isempty(s.phaseDetails)
                return
            end
            stimListOld = stimList;
            stimListNew = {};
            discrimStim = stimList{1,2}; % in autopilot, discrim comes first
            interTrialStim = stimList{2,2};
            % are we adding new phases?
            % preDiscrimStim
            whichPreDiscrim = strcmp({s.phaseDetails.phaseType},'preDiscrimStim');
            numPreDiscrim = sum(whichPreDiscrim);
            preDiscrimPhaseDetails = s.phaseDetails(whichPreDiscrim);
            for i = 1:numPreDiscrim
                if strcmp(preDiscrimPhaseDetails(i).phaseStim,'sameAsDiscrim')
                    preDiscrimStim = discrimStim;
                    preDiscrimStim.framesUntilTimeout = preDiscrimPhaseDetails(i).phaseLengthInFrames;
                    preDiscrimStim.ledON = preDiscrimPhaseDetails(i).LEDON & LEDDetails.LEDON;
                    preDiscrimStim.soundPlayed = preDiscrimPhaseDetails(i).soundsPlayed;
                    
                    preDiscrimLabel = preDiscrimPhaseDetails(i).phaseLabel;
                else
                    preDiscrimStim=[];
                    preDiscrimStim.stimulus=preDiscrimPhaseDetails(i).phaseStim;
                    preDiscrimStim.stimType={'timedFrames',preDiscrimPhaseDetails(i).phaseLengthInFrames};
                    preDiscrimStim.framesUntilTimeout=preDiscrimPhaseDetails(i).phaseLengthInFrames;
                    preDiscrimStim.scaleFactor=discrimStim.scaleFactor; % scale factor remains the same
                    preDiscrimStim.startFrame=0;
                    preDiscrimStim.autoTrigger=[];
                    preDiscrimStim.punishResponses=false;
                    preDiscrimStim.ledON = preDiscrimPhaseDetails(i).LEDON & LEDDetails.LEDON;
                    preDiscrimStim.soundPlayed = preDiscrimPhaseDetails(i).soundsPlayed;
                    
                    preDiscrimLabel = preDiscrimPhaseDetails(i).phaseLabel;
                end
                details.phaseDetails(end+1).phaseLabel = preDiscrimLabel;
                details.phaseDetails(end).phaseType = 'preDiscrimStim';
                details.phaseDetails(end).phaseLengthInFrames = preDiscrimStim.framesUntilTimeout;
                details.phaseDetails(end).ledON = preDiscrimStim.ledON;
                details.phaseDetails(end).ledIntensity = LEDDetails.LEDIntensity;
                
                stimListNew(end+1,:) = {preDiscrimLabel, preDiscrimStim};
            end
            
            % discrimStim
            whichDiscrim = strcmp({s.phaseDetails.phaseType},'discrimStim');
            numPreDiscrim = sum(whichDiscrim);
            assert(numPreDiscrim==1,'autopilotGratings:setupPhases:improperValue','only one discrimStim is allowed. Found::%d',numPreDiscrim);
            discrimPhaseDetails = s.phaseDetails(whichDiscrim);
            % only look at LED
            discrimStim.ledON = discrimPhaseDetails.LEDON & LEDDetails.LEDON;
            details.phaseDetails(end+1).phaseLabel = 'discrimStim';
            details.phaseDetails(end).phaseType = 'discrimStim';
            details.phaseDetails(end).phaseLengthInFrames = discrimStim.framesUntilTimeout;
            details.phaseDetails(end).ledON = discrimStim.ledON;
            details.phaseDetails(end).ledIntensity = LEDDetails.LEDIntensity;
            stimListNew(end+1,:) = {'discrimStim', discrimStim};
            
            % postDiscrim
            whichPostDiscrim = strcmp({s.phaseDetails.phaseType},'postDiscrimStim');
            numPostDiscrim = sum(whichPostDiscrim);
            postDiscrimPhaseDetails = s.phaseDetails(whichPostDiscrim);
            for i = 1:numPostDiscrim
                if strcmp(postDiscrimPhaseDetails(i).phaseStim,'sameAsDiscrim')
                    postDiscrimStim = discrimStim;
                    postDiscrimStim.framesUntilTimeout = postDiscrimPhaseDetails(i).phaseLengthInFrames;
                    postDiscrimStim.ledON = postDiscrimPhaseDetails(i).LEDON & LEDDetails.LEDON;
                    postDiscrimStim.soundPlayed = postDiscrimPhaseDetails(i).soundsPlayed;
                    
                    postDiscrimLabel = postDiscrimPhaseDetails(i).phaseLabel;
                else
                    postDiscrimStim=[];
                    postDiscrimStim.stimulus=postDiscrimPhaseDetails(i).phaseStim;
                    postDiscrimStim.stimType={'timedFrames',postDiscrimPhaseDetails(i).phaseLengthInFrames};
                    postDiscrimStim.framesUntilTimeout=postDiscrimPhaseDetails(i).phaseLengthInFrames;
                    postDiscrimStim.scaleFactor=discrimStim.scaleFactor; % scale factor remains the same
                    postDiscrimStim.startFrame=0;
                    postDiscrimStim.autoTrigger=[];
                    postDiscrimStim.punishResponses=false;
                    postDiscrimStim.ledON = postDiscrimPhaseDetails(i).LEDON & LEDDetails.LEDON;
                    postDiscrimStim.soundPlayed = postDiscrimPhaseDetails(i).soundsPlayed;
                    
                    postDiscrimLabel = postDiscrimPhaseDetails(i).phaseLabel;
                end
                details.phaseDetails(end+1).phaseLabel = postDiscrimLabel;
                details.phaseDetails(end).phaseType = 'postDiscrimStim';
                details.phaseDetails(end).phaseLengthInFrames = postDiscrimStim.framesUntilTimeout;
                details.phaseDetails(end).ledON = postDiscrimStim.ledON;
                details.phaseDetails(end).ledIntensity = LEDDetails.LEDIntensity;
                
                stimListNew(end+1,:) = {postDiscrimLabel, postDiscrimStim};
            end
            % deal with interTrialStim
            stimListNew(end+1,:) = {'interTrialStim',interTrialStim};
            stimList = stimListNew;
            
        end
        
        function [details, LEDDetails]= setupLED(s,details,st)
            if isempty(s.LEDParams)
                LEDDetails.LEDON  = false;
                LEDDetails.whichLED  = NaN;
                LEDDetails.LEDIntensity  = NaN;
                
                details.LEDDetails = LEDDetails;
                return;
            end
            
            whichRND = rand;
            modesCumProb = cumsum([s.LEDParams.IlluminationModes.probability]);
            chosenMode = s.LEDParams.IlluminationModes(find(modesCumProb>whichRND==1,1,'first'));
            
            try
            LEDDetails.LEDON = true;
            LEDDetails.whichLED = chosenMode.whichLED;
            LEDDetails.LEDIntensity = chosenMode.intensity;
            details.LEDDetails = LEDDetails;
            catch
                sca;
                keyboard
            end
            % send info to arduino
            fwrite(st.arduinoCONN, uint8(LEDDetails.LEDIntensity*255));
        end
    end
    
    methods(Static)
        function out = getDetails(stim,what)
            switch what
                case 'sweptParameters'
                    if stim.doCombos
                        if isfield(stim,'spatialFrequencies')
                            sweepnames={'spatialFrequencies','driftfrequencies','phases','contrasts','maxDuration','radii','annuli'};
                        elseif isfield(stim,'pixPerCycs')
                            sweepnames={'pixPerCycs','driftfrequencies','phases','contrasts','maxDuration','radii','annuli'};
                        end
                        which = [false false false false false false false];
                        for i = 1:length(sweepnames)
                            if length(stim.(sweepnames{i}){1})>1 || length(stim.(sweepnames{i}){2})>1
                                which(i) = true;
                            end
                        end
                        out=sweepnames(which);
                        
                        warning('gonna assume same number of orientations for both ports? is that wise?')
                        if length(stim.orientations{1})==1 % gonna be intelligent and consider changes by pi to be identical orientations (but they are opposite directions)
                            % nothing there was no orientation sweep
                        elseif length(stim.orientations{1})==2
                            if diff(mod(stim.orientations{1},pi))<0.000001 && diff(mod(stim.orientations{2},pi))<0.000001%allowing for small changes during serialization
                                % they are the same
                            else
                                out{end+1} = 'orientations';
                            end
                        else
                            % then length >2 then automatically there is some sweep
                            out{end+1} = 'orientations';
                        end
                    else
                        error('unsupported');
                    end
                otherwise
                    error('unknown what');
            end
        end
                
        function out = stimMgrOKForTrialMgr(tm)
            assert(isa(tm,'trialManager'),'afcCoherentDots:stimMgrOKForTrialMgr:incorrectType','need a trialManager object');
            switch class(tm)
                case {'nAFC','biasedNAFC','autopilot','reinforcedAutopilot','goNoGo'}
                    out=true;
                otherwise
                    out=0;
            end
            
        end
        
        function out = computeGabor(params)
            % function out = computeGabors(params,mean,width,height,waveform,normalizeMethod,cornerMarkerOn,normalize)
            % grating=computeGabors(params,0.5,200,200,'square','normalizeVertical',1);
            
            %change log
            % 04072016 copied from old computerGabors
            
            
            if ~exist('cornerMarkerOn','var')
                cornerMarkerOn=0;
            end
            
            radius      = params.radius;
            radiusType  = params.radiusType;
            pixPerCyc   = params.pixPerCyc;
            phase       = params.phase;
            orientation = params.orientation;
            mean        = params.mean;
            contrast    = params.contrast;
            thresh      = params.thresh;
            xPosPct     = params.location(1);
            yPosPct     = params.location(2);
            waveform    = params.waveform;
            xSize       = params.width;
            ySize       = params.height;
            
            img = zeros(ySize,xSize);
            biggest=max(xSize,ySize);
            
            switch params.normalizationMethod
                case 'normalizeVertical'
                    normalizedLength=ySize/2;
                case 'normalizeHorizontal'
                    normalizedLength=xSize/2;
                case 'normalizeDiagonal'  % erik's diag method
                    normalizedLength=sqrt((xSize/2)^2 + (ySize/2)^2);
                case 'none'
                    normalizedLength=1;  % in this case the radius is the std in number of pixels
                otherwise
                    error('normalizeMethod must be ''normalizeVertical'', ''normalizeHorizontal'', or ''normalizeDiagonal''.')
            end
            
            
            
            %calculate the effective frequency in the vertical and horizontal directions
            %instead of frequency use pixPerCyc
            xPPC=pixPerCyc/cos(orientation);
            yPPC=pixPerCyc/sin(orientation);
            xChange=repmat(((1:xSize) -(.5+xPosPct*xSize))  *(2*pi)/xPPC,ySize,1);
            yChange=repmat(((1:ySize)-(.5+yPosPct*ySize))'*(2*pi)/yPPC,1, xSize);
            phases=(xChange+yChange+phase)';
            
            
            switch waveform
                case 'sine'
                    rotated=sin(phases)/2;
                case 'square'
                    %this may not right but really close
                    rotated=sign(sin(phases))/2;
                case 'none'
                    rotated=ones(size(phases)); %Could be sped up by not calculating phases
                otherwise
                    error('waveform must be ''sine'' or ''square'' or ''none''');
            end
            rotated = contrast*rotated;
            
            if radius ~= Inf  %only compute gaussian mask if you need to
                switch radiusType
                    case 'gaussian'
                        mask=zeros(ySize,xSize);
                        mask(1:xSize*ySize)=mvnpdf(...
                            [reshape(repmat((-ySize/2:(-ySize/2 + ySize -1))',1,xSize),xSize*ySize,1) ...
                            reshape(repmat(-xSize/2:(-xSize/2+xSize-1),ySize,1),xSize*ySize,1)],...
                            [yPosPct*ySize-ySize/2 xPosPct*xSize-xSize/2],(radius*diag([normalizedLength normalizedLength])).^2 ...
                            );
                        mask=mask/max(max(mask));
                        masked = rotated'.*mask;
                        
                    case 'hardEdge'
                        [WIDTH, HEIGHT] = meshgrid(1:xSize,1:ySize);
                        mask=double( ...
                            (((WIDTH-xSize*xPosPct).^2)+((HEIGHT-ySize*yPosPct).^2)...
                            -((radius*normalizedLength)^2))<0 ...
                        );
                        masked = rotated'.*mask;
                end
            else
                masked = rotated';
            end
            
            
            masked(abs(masked)<thresh)=0;
            img(:,:)=masked;
            out=mean+img;
            
            clip = false;
            if clip %note this is not what normalize means -- should be called clip!
                out(out<0)=0;
                out(out>1)=1;
            end
            
            if cornerMarkerOn
                out(1)=0;
                out(2)=1;
            end
        end
    end
    
end