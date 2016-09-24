classdef afcGratings<stimManager
    % AFCGRATINGS
    % This class is specifically designed for behavior. It does not incorporate
    % many of the features usually present in GRATINGS like the ability to
    % show multiple types of gratings in the same trial. It shows a single orientation
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
    end
    
    methods
        function s=afcGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,radiusType, annuli,location,...
                waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos, doPostDiscrim)
            % AFCGRATINGS  class constructor.
            % 
            % s = afcGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,annuli,location,
            %       waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance)
            % Each of the following arguments is a {[],[]} cell, each element is a
            % vector of size N
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
            
            s.LEDParams = stimManager.getStandardLEDParams;
            s.doCombos = true;

            % pixPerCycs
            assert(islogical(doCombos),'afcGratings:afcGratings:invalidInput','doCombos not in the right format');
            s.doCombos = doCombos;
            
            % pixPerCycs
            assert(iscell(pixPerCycs) && length(pixPerCycs)==2 && ...
                isnumeric(pixPerCycs{1}) && all(pixPerCycs{1}>0) && isnumeric(pixPerCycs{2}) && all(pixPerCycs{2}>0),...
                'afcGratings:afcGratings:invalidInput','pixPerCycs not in the right format');
            L1 = length(pixPerCycs{1});
            L2 = length(pixPerCycs{2});
            assert(doCombos || length(pixPerCycs{1})==L1 && length(pixPerCycs{2})==L2,'afcGratings:afcGratings:incompatibleValues','the lengths don''t match.');
            s.pixPerCycs = pixPerCycs;
            
            % driftfrequencies
            assert(iscell(driftfrequencies) && length(driftfrequencies)==2 && ...
                isnumeric(driftfrequencies{1}) && all(driftfrequencies{1}>=0) && isnumeric(driftfrequencies{2}) && all(driftfrequencies{2}>=0),...
                'afcGratings:afcGratings:invalidInput','driftfrequencies not in the right format');
            assert(doCombos || length(driftfrequencies{1})==L1 && length(driftfrequencies{2})==L2,'afcGratings:afcGratings:incompatibleValues','the lengths don''t match.');
            s.driftfrequencies = driftfrequencies;
            
            % orientations
            assert(iscell(orientations) && length(orientations)==2 && ...
                isnumeric(orientations{1}) && all(~isinf(orientations{1})) && isnumeric(orientations{2}) &&  all(~isinf(orientations{2})),...
                'afcGratings:afcGratings:invalidInput','orientations not in the right format');
            assert(doCombos || length(orientations{1})==L1 && length(orientations{2})==L2,'afcGratings:afcGratings:incompatibleValues','the lengths don''t match.');
            s.orientations = orientations;
            
            % phases
            assert(iscell(phases) && length(phases)==2 && ...
                isnumeric(phases{1}) && all(~isinf(phases{1})) && isnumeric(phases{2}) && all(~isinf(phases{2})),...
                'afcGratings:afcGratings:invalidInput','phases not in the right format');
            assert(doCombos || length(phases{1})==L1 && length(phases{2})==L2,'afcGratings:afcGratings:incompatibleValues','the lengths don''t match.');
            s.phases = phases;
            
            % contrasts
            assert(iscell(contrasts) && length(contrasts)==2 && ...
                isnumeric(contrasts{1}) && all(contrasts{1}>=0) && all(contrasts{1}<=1) && isnumeric(contrasts{2}) && all(contrasts{2}>=0) && all(contrasts{2}<=1),...
                'afcGratings:afcGratings:invalidInput','contrasts not in the right format');
            assert(doCombos || length(contrasts{1})==L1 && length(contrasts{2})==L2,'afcGratings:afcGratings:incompatibleValues','the lengths don''t match.');
            s.contrasts = contrasts;
            
            % maxDuration
            assert(iscell(maxDuration) && length(maxDuration)==2 && ...
                isnumeric(maxDuration{1}) && all(maxDuration{1}>0) && isnumeric(maxDuration{2}) && all(maxDuration{2}>0),...
                'afcGratings:afcGratings:invalidInput','maxDuration not in the right format');
            assert(doCombos || length(maxDuration{1})==L1 && length(maxDuration{2})==L2,'afcGratings:afcGratings:incompatibleValues','the lengths don''t match.');
            s.maxDuration = maxDuration;
            
            % radii
            assert(iscell(radii) && length(radii)==2 && ...
                isnumeric(radii{1}) && all(radii{1}>=0) && isnumeric(radii{2}) && all(radii{2}>=0),...
                'afcGratings:afcGratings:invalidInput','radii not in the right format');
            assert(doCombos || length(radii{1})==L1 && length(radii{2})==L2,'afcGratings:afcGratings:incompatibleValues','the lengths don''t match.');
            s.radii = radii;
            
            % radiusType
            assert(ischar(radiusType) && ismember(radiusType,{'gaussian','hardEdge'}),'afcGratings:afcGratings:invalidInput','radiusType not in the right format')
            s.radiusType = radiusType;
            
            % annuli
            assert(iscell(annuli) && length(annuli)==2 && ...
                isnumeric(annuli{1}) && all(annuli{1}>=0) && isnumeric(annuli{2}) && all(annuli{2}>=0),...
                'afcGratings:afcGratings:invalidInput','annuli not in the right format');
            assert(doCombos || length(annuli{1})==L1 && length(annuli{2})==L2,'afcGratings:afcGratings:incompatibleValues','the lengths don''t match.');
            s.annuli = annuli;
            
            % location
            assert(iscell(location) && length(location)==2 && ...
                isnumeric(location{1}) && all(location{1}>=0) && size(location{1},2)==2 && ...
                isnumeric(location{2}) && all(location{2}>=0) && size(location{2},2)==2,...
                'afcGratings:afcGratings:invalidInput','location not in the right format');
            assert(doCombos || length(location{1})==L1 && length(location{2})==L2,'afcGratings:afcGratings:incompatibleValues','the lengths don''t match.');
            s.location = location;
            
            % waveform
            assert(ischar(waveform) && ismember(waveform,{'sine','square'}),'afcGratings:afcGratings:invalidInput','waveform not in right format');
            s.waveform = waveform;
            
            
            % normalizationMethod
            assert(ischar(normalizationMethod) && ismember(normalizationMethod,{'normalizeVertical', 'normalizeHorizontal', 'normalizeDiagonal' , 'none'}),...
                'afcGratings:afcGratings:invalidInput','normalizationMethod not in right format')
            s.normalizationMethod = normalizationMethod;
            
            % mean
            assert(mean>=0 && mean<=1,'afcGratings:afcGratings:invalidInput','mean not in right format')
            s.mean = mean;
            
            % thresh
            assert(thresh>=0,'afcGratings:afcGratings:invalidInput','thresh not in right format')
            s.thresh = thresh;
            
            % doPostDiscrim
            assert(islogical(doPostDiscrim),'afcGratings:afcGratings:invalidInput','doPostDiscrim should be logical')
            s.doPostDiscrim = doPostDiscrim;
        end
        
        function [sm,updateSM,resInd,stimList,LUT,targetPorts,distractorPorts,details,text,indexPulses,imagingTasks,ITL] =...
                calcStim(sm,tm,st,tR,~)
            resolutions = st.resolutions;
            displaySize = st.getDisplaySize();
            LUTbits = st.getLUTbits();
            responsePorts = tm.getResponsePorts(st.numPorts);
            scaleFactor = sm.scaleFactor;
            indexPulses=[];
            imagingTasks=[];
            [LUT, sm, updateSM]=getLUT(sm,LUTbits);
            
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
            
            % lets save some of the details for later
%             details.afcGratingType = sm.getType(structize(sm));
            
            % whats the chosen stim?
            if targetPorts==1
                chosenStimIndex = 1;
            elseif targetPorts==3
                chosenStimIndex = 2;
            else
                error('cannot support this here')
            end
            
            stim = [];
            
            
            stim.height = height;
            stim.width = width;
%             stim.rngMethod = sm.ordering.method;
%             if isempty(sm.ordering.seed)
%                 stim.seedVal = sum(100*clock);
%             end
            
            % whats the chosen stim?
            switch sm.doCombos
                case true
                    % choose a random value for each
                    % #### need to use the seed val somehow not used here
                    stim.pixPerCyc          = chooseFrom(sm.pixPerCycs{chosenStimIndex});
                    stim.driftfrequency     = chooseFrom(sm.driftfrequencies{chosenStimIndex});
                    stim.orientation        = chooseFrom(sm.orientations{chosenStimIndex});
                    stim.phase              = chooseFrom(sm.phases{chosenStimIndex});
                    stim.contrast           = chooseFrom(sm.contrasts{chosenStimIndex});
                    stim.radius             = chooseFrom(sm.radii{chosenStimIndex});
                    stim.annulus            = chooseFrom(sm.annuli{chosenStimIndex});
                    stim.maxDuration        = round(chooseFrom(sm.maxDuration{chosenStimIndex})*hz);
                    stim.waveform           = sm.waveform;
                    
                    locations               = sm.location{chosenStimIndex};
                    numLocations            = size(locations,1);
                    stim.location           = locations(chooseFrom(1:numLocations),:);
                case false
                    % #### need to use the seed val somehow not used here
                    tempVar = randperm(length(sm.pixPerCycs{chosenStimIndex}));
                    which = tempVar(1);
                    stim.pixPerCyc          = sm.pixPerCycs{chosenStimIndex}(which);
                    stim.driftfrequency     = sm.driftfrequencies{chosenStimIndex}(which);
                    stim.orientation        = sm.orientations{chosenStimIndex}(which);
                    stim.phase              = sm.phases{chosenStimIndex}(which);
                    stim.contrast           = sm.contrasts{chosenStimIndex}(which);
                    stim.radius             = sm.radii{chosenStimIndex}(which);
                    stim.annulus            = sm.annuli{chosenStimIndex}(which);
                    stim.location           = sm.location{chosenStimIndex}(which,:);
                    stim.maxDuration        = round(sm.maxDuration{chosenStimIndex}(which)*hz);
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
            
            TypeIsExpert = any(sm.driftfrequencies{1}>0)||any(sm.driftfrequencies{2}>0);
            
            switch TypeIsExpert
                case true
                    type = 'expert';
                    % radii
                    if stim.radii==Inf
                        stim.masks={[]};
                    else
                        mask=[];
                        maskParams=[stim.radii 999 0 0 ...
                            1.0 stim.thresh stim.location(1) stim.location(2)]; %11/12/08 - for some reason mask contrast must be 2.0 to get correct result
                        
                        switch details.chosenStim.radiusType
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
                                mask(:,:,2)=double((((WIDTH-width*details.chosenStim.location(1)).^2)+((HEIGHT-height*details.chosenStim.location(2)).^2)-((stim.radii)^2*(height^2)))>0);
                                stim.masks{1}=mask;
                        end
                    end
                    % annulus
                    if ~(stim.annuli==0)
                        annulusCenter=stim.location;
                        annulusRadius=stim.annuli;
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
                    type = 'cache';
                    grating = sm.computeGabor(stim); % #### new                    
            end
            
            
            
            if isinf(stim.maxDuration)
                timeout=[];
            else
                timeout=stim.maxDuration;
            end
            
            
            % LEDParams
            %[details, stim] = setupLED(details, stim, sm.LEDParams,arduinoCONN);
            
            discrimStim=[];
            switch type
                case 'expert'
                    discrimStim.stimulus=stim;
                case 'cache'
                    discrimStim.stimulus=grating;
            end
            discrimStim.stimType=type;
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            discrimStim.autoTrigger=[];
            discrimStim.punishResponses=false;
            discrimStim.framesUntilTimeout=timeout;
            discrimStim.ledON = false; % #### presetting here
            discrimStim.soundPlayed = []; 
            
            preRequestStim=[];
            preRequestStim.stimulus=sm.interTrialLuminance;
            preRequestStim.stimType='loop';
            preRequestStim.scaleFactor=0;
            preRequestStim.startFrame=0;
            preRequestStim.autoTrigger=[];
            preRequestStim.punishResponses=false;
            preRequestStim.ledON = false; % #### presetting here
            preRequestStim.soundPlayed = []; 
            preRequestStim.framesUntilTimeout = 100;
            
            if sm.doPostDiscrim
                postDiscrimStim = preRequestStim;
                postDiscrimStim.framesUntilTimeout = inf;
            else
                postDiscrimStim = [];
            end
            
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
                'preRequestStim',preRequestStim;...
                'discrimStim',discrimStim;...
                'postDiscrimStim',postDiscrimStim;...
                'interTrialStim',interTrialStim};
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
            cycsPerFrameVel = stim.driftfrequencies*ifi; % in units of cycles/frame
            offset = 2*pi*cycsPerFrameVel*i;
            
            % Create a 1D vector x based on the frequency pixPerCycs
            % make the grating twice the normal width (to cover entire screen if rotated)
            x = (1:stim.width*2)*2*pi/stim.pixPerCycs;
            switch stim.waveform
                case 'sine'
                    grating=stim.contrasts*cos(x + offset+stim.phases)/2+stimulus.mean;
                case 'square'
                    grating=stim.contrasts*square(x + offset+stim.phases)/2+stimulus.mean;
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
                (180/pi)*stim.orientations, filtMode);
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
            sweptParameters = afcGratings.getDetails(stim,'sweptParameters');
            n= length(sweptParameters);
            switch n
                case 0
                    out = 'afcGratings_noSweep';
                case 1
                    % sweep of a single datatype
                    switch sweptParameters{1}
                        case {'pixPerCycs','spatialFrequencies'}
                            out = 'afcGratings_sfSweep';
                        case 'driftfrequencies'
                            out = 'afcGratings_tfSweep';
                        case 'orientations'
                            out = 'afcGratings_orSweep';
                        case 'phases'
                            out = 'afcGratings_phaseSweep';
                        case 'contrasts'
                            out = 'afcGratings_cntrSweep';
                        case 'maxDuration'
                            out = 'afcGratings_durnSweep';
                        case 'radii'
                            out = 'afcGratings_radSweep';
                        case 'annuli'
                            out = 'afcGratings_annSweep';
                        otherwise
                            out = 'undefinedGratings';
                    end
                case 2
                    if all(ismember(sweptParameters,{'contrasts','radii'}))
                        out = 'afcGratings_cntrXradSweep';
                    elseif all(ismember(sweptParameters,{'contrasts','pixPerCycs'}))
                        out = 'afcGratings_cntrXsfSweep';
                    elseif all(ismember(sweptParameters,{'phases','maxDuration'}))
                        out = 'afcGratings_durationSweep_Stat';
                    elseif all(ismember(sweptParameters,{'phases','contrasts'}))
                        out = 'afcGratings_contrastSweep_Stat';
                    elseif all(ismember(sweptParameters,{'phases','pixPerCycs'}))
                        out = 'afcGratings_sfSweep_Stat';
                    elseif all(ismember(sweptParameters,{'phases','orientations'}))
                        out = 'afcGratings_orSweep_Stat';
                    elseif all(ismember(sweptParameters,{'maxDuration','phases'}))
                        out = 'afcGratings_durSweep_Stat';
                    elseif all(ismember(sweptParameters,{'contrasts','maxDuration'}))
                        out = 'afcGratings_cntrXdurSweep_Stat';
                    else
                        sweptParameters
                        error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                    end
                case 3
                    if all(ismember(sweptParameters,{'contrasts','pixPerCycs','driftFrequencies'}))
                        out = 'afcGratings_cntrXsfXtfSweep';
                    elseif all(ismember(sweptParameters,{'contrasts','pixPerCycs','phases'}))
                        out = 'afcGratings_cntrXsfStationary';
                    elseif all(ismember(sweptParameters,{'maxDuration','phases','contrasts'}))
                        out = 'afcGratings_cntrXdurSweep_Stat';
                    else
                        sweptParameters
                        error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                    end
                case 4
                    if all(ismember(sweptParameters,{'contrasts','pixPerCycs','driftfrequencies','orientations'}))
                        out = 'afcGratings_cntrXsfXtfXorSweep';
                    else
                        sweptParameters
                        error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                    end
                otherwise
                    error('unsupported type. if you want this make a name for it');
            end
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
        
        function [analysisdata, cumulativedata] = physAnalysis(spikeRecord,stimulusDetails,plotParameters,parameters,cumulativedata,eyeData,LFPRecord)
            
            % processed clusters and spikes
            theseSpikes = logical(spikeRecord.processedClusters);
            spikes=spikeRecord.spikes(theseSpikes);
            spikeWaveforms = spikeRecord.spikeWaveforms(theseSpikes,:);
            spikeTimestamps = spikeRecord.spikeTimestamps(theseSpikes);
            
            % SET UP RELATION stimInd <--> frameInd
            numStimFrames=max(spikeRecord.stimInds);
            analyzeDrops=true;
            if analyzeDrops
                stimFrames=spikeRecord.stimInds;
                correctedFrameIndices=spikeRecord.correctedFrameIndices;
            else
                stimFrames=1:numStimFrames;
                firstFramePerStimInd=~[0 diff(spikeRecord.stimInds)==0];
                correctedFrameIndices=spikeRecord.correctedFrameIndices(firstFramePerStimInd);
            end
            
            %
            trials = repmat(parameters.trialNumber,length(stimFrames),1);
            
            % is there randomization?
            if ~isfield(stimulusDetails,'method')
                mode = {'ordered',[]};
            else
                mode = {stimulusDetails.method,stimulusDetails.seed};
            end
            
            % get the stimulusCombo
            if stimulusDetails.doCombos==1
                comboMatrix = generateFactorialCombo({stimulusDetails.spatialFrequencies,stimulusDetails.driftfrequencies,stimulusDetails.orientations,...
                    stimulusDetails.contrasts,stimulusDetails.phases,stimulusDetails.durations,stimulusDetails.radii,stimulusDetails.annuli},[],[],mode);
                pixPerCycs=comboMatrix(1,:);
                driftfrequencies=comboMatrix(2,:);
                orientations=comboMatrix(3,:);
                contrasts=comboMatrix(4,:); %starting phases in radians
                startPhases=comboMatrix(5,:);
                durations=round(comboMatrix(6,:)*parameters.refreshRate); % CONVERTED FROM seconds to frames
                radii=comboMatrix(7,:);
                annuli=comboMatrix(8,:);
                
                repeat=ceil(stimFrames/sum(durations));
                numRepeats=ceil(numStimFrames/sum(durations));
                chunkEndFrame=[cumsum(repmat(durations,1,numRepeats))];
                chunkStartFrame=[0 chunkEndFrame(1:end-1)]+1;
                chunkStartFrame = chunkStartFrame';
                chunkEndFrame = chunkEndFrame';
                numChunks=length(chunkStartFrame);
                trialsByChunk = repmat(parameters.trialNumber,numChunks,1);
                numTypes=length(durations); %total number of types even having multiple sweeps
            else
                error('analysis not handled yet for this case')
            end
            
            numValsPerParam=...
                [length(unique(pixPerCycs)) length(unique(driftfrequencies))  length(unique(orientations))...
                length(unique(contrasts)) length(unique(startPhases)) length(unique(durations))...
                length(unique(radii))  length(unique(annuli))];
            
            % find which parameters are swept
            names={'pixPerCycs','driftfrequencies','orientations','contrasts','startPhases',...
                'durations','radii','annuli'};
            
            sweptParameters = names(find(numValsPerParam>1));
            numSweptParams = length(sweptParameters);
            valsSwept = cell(length(sweptParameters),0);
            for sweptNo = 1:length(find(numValsPerParam>1))
                valsSwept{sweptNo} = eval(sweptParameters{sweptNo});
            end
            
            % durations of each condition should be unique
            if length(unique(durations))==1
                duration=unique(durations);
            else
                error('multiple durations can''t rely on mod to determine the frame type')
            end
            
            stimInfo.stimulusDetails = stimulusDetails;
            stimInfo.refreshRate = parameters.refreshRate;
            % stimInfo.pixPerCycs = unique(pixPerCycs);
            % stimInfo.driftfrequencies = unique(driftfrequencies);
            % stimInfo.orientations = unique(orientations);
            % stimInfo.contrasts = unique(contrasts);
            % stimInfo.startPhases = unique(startPhases);
            % stimInfo.durations = unique(durations);
            % stimInfo.radii = unique(radii);
            % stimInfo.annuli = unique(annuli);
            % stimInfo.numRepeats = numRepeats;
            stimInfo.sweptParameters = sweptParameters;
            stimInfo.numSweptParams = numSweptParams;
            stimInfo.valsSwept = valsSwept;
            stimInfo.numTypes = numTypes;
            
            % to begin with no attempt will be made to group acording to type
            typesUnordered=repmat([1:numTypes],duration,numRepeats);
            typesUnordered=typesUnordered(stimFrames); % vectorize matrix and remove extras
            repeats = reshape(repmat([1:numRepeats],[duration*numTypes 1]),[duration*numTypes*numRepeats 1]);
            repeats = repeats(stimFrames);
            samplingRate=parameters.samplingRate;
            
            % calc phase per frame, just like dynamic
            x = 2*pi./pixPerCycs(typesUnordered); % adjust phase for spatial frequency, using pixel=1 which is likely always offscreen, given roation and oversizeness
            cycsPerFrameVel = driftfrequencies(typesUnordered)*1/(parameters.refreshRate); % in units of cycles/frame
            offset = 2*pi*cycsPerFrameVel.*stimFrames';
            risingPhases=x+offset+startPhases(typesUnordered);
            phases=mod(risingPhases,2*pi);
            phases = phases';
            
            % count the number of spikes per frame
            % spikeCount is a 1xn vector of (number of spikes per frame), where n = number of frames
            spikeCount=zeros(size(correctedFrameIndices,1),1);
            for i=1:length(spikeCount) % for each frame
                spikeCount(i)=length(find(spikes>=correctedFrameIndices(i,1)&spikes<=correctedFrameIndices(i,2))); % inclusive?  policy: include start & stop
            end
            switch numSweptParams
                case 1
                    valsActual = valsSwept{1};
                    valsOrdered = sort(valsSwept{1});
                    types = nan(size(typesUnordered));
                    for i = 1:length(valsOrdered)
                        types(typesUnordered==i) = find(valsOrdered==valsActual(i));
                    end
                case 2
                    types = nan(size(typesUnordered));
                    numSwept1 = length(unique(valsSwept{1}));
                    numSwept2 = length(unique(valsSwept{2}));
                    valsSwept1 = unique(valsSwept{1});
                    valsSwept2 = unique(valsSwept{2});
                    
                    for i = 1:numSwept1
                        for j = 1:numSwept2
                            types(typesUnordered==((i-1)*numSwept2+j)) = find((valsSwept{1}==valsSwept1(i))&(valsSwept{2}==valsSwept2(j)));
                        end
                    end
                case 3
                    error('not yet supported')
            end
            
            
            
            
            % update what we know about te analysis to analysisdata
            analysisdata.stimInfo = stimInfo;
            analysisdata.trialNumber = parameters.trialNumber;
            analysisdata.subjectID = parameters.subjectID;
            % here be the meat of the analysis
            analysisdata.spikeCount = spikeCount;
            analysisdata.phases = phases;
            analysisdata.types = types;
            analysisdata.repeats = repeats;
            
            % analysisdata.firingRateByPhase = firingRateByPhase;
            analysisdata.spikeWaveforms = spikeWaveforms;
            analysisdata.spikeTimestamps = spikeTimestamps;
            
            
            % for storage in cumulative data....sort the relevant fields
            stimInfo.pixPerCycs = sort(unique(pixPerCycs));
            stimInfo.driftfrequencies = sort(unique(driftfrequencies));
            stimInfo.orientations = sort(unique(orientations));
            stimInfo.contrasts = sort(unique(contrasts));
            stimInfo.startPhases = sort(unique(startPhases));
            stimInfo.durations = sort(unique(durations));
            stimInfo.radii = sort(unique(radii));
            stimInfo.annuli = sort(unique(annuli));
            
            %get eyeData for phase-eye analysis
            if ~isempty(eyeData)
                [px py crx cry]=getPxyCRxy(eyeData,10);
                eyeSig=[crx-px cry-py];
                eyeSig(end,:)=[]; % remove last ones to match (not principled... what if we should throw out the first ones?)
                
                if length(unique(eyeSig(:,1)))>10 % if at least 10 x-positions
                    
                    regionBoundsXY=[1 .5]; % these are CRX-PY bounds of unknown degrees
                    [within ellipses]=selectDenseEyeRegions(eyeSig,1,regionBoundsXY);
                    
                    whichOne=0; % various things to look at
                    switch whichOne
                        case 0
                            %do nothing
                        case 1 % plot eye position and the clusters
                            regionBoundsXY=[1 .5]; % these are CRX-PY bounds of unknown degrees
                            within=selectDenseEyeRegions(eyeSig,3,regionBoundsXY,true);
                        case 2  % coded by phase
                            [n phaseID]=histc(phases,edges);
                            figure; hold on;
                            phaseColor=jet(numPhaseBins);
                            for i=1:numPhaseBins
                                plot(eyeSig(phaseID==i,1),eyeSig(phaseID==i,2),'.','color',phaseColor(i,:))
                            end
                        case 3
                            density=hist3(eyeSig);
                            imagesc(density)
                        case 4
                            eyeMotion=diff(eyeSig(:,1));
                            mean(eyeMotion>0)/mean(eyeMotion<0);   % is close to 1 so little bias to drift and snap
                            bound=3*std(eyeMotion(~isnan(eyeMotion)));
                            motionEdges=linspace(-bound,bound,100);
                            count=histc(eyeMotion,motionEdges);
                            
                            figure; bar(motionEdges,log(count),'histc'); ylabel('log(count)'); xlabel('eyeMotion (crx-px)''')
                            
                            figure; plot(phases',eyeMotion,'.'); % no motion per phase (more interesting for sqaure wave single freq)
                    end
                else
                    disp(sprintf('no good eyeData on trial %d',parameters.trialNumber))
                end
                analysisdata.eyeData = eyeSig;
            else
                analysisdata.eyedata = [];
                eyeSig = [];
            end
            
            % now update cumulativedata
            if isempty(cumulativedata)
                cumulativedata.trialNumbers = parameters.trialNumber;
                cumulativedata.subjectID = parameters.subjectID;
                cumulativedata.stimInfo = stimInfo;
                cumulativedata.spikeCount = spikeCount; % i shall not store firingRateByPhase in cumulative
                cumulativedata.phases = phases;
                cumulativedata.types = types;
                cumulativedata.repeats = repeats;
                cumulativedata.spikeWaveforms = spikeWaveforms;
                cumulativedata.spikeTimestamps = spikeTimestamps;
                cumulativedata.eyeData = eyeSig;
            elseif ~isequal(rmfield(cumulativedata.stimInfo,{'stimulusDetails','refreshRate','valsSwept'}),rmfield(stimInfo,{'stimulusDetails','refreshRate','valsSwept'}))
                keyboard
                error('something mighty fishy going on here.is it just an issue to do with repeats?');
                
            else % now concatenate only along the first dimension of phaseDensity and other stuff
                cumulativedata.trialNumbers = [cumulativedata.trialNumbers;parameters.trialNumber];
                cumulativedata.spikeCount = [cumulativedata.spikeCount;spikeCount]; % i shall not store firingRateByPhase in cumulative
                cumulativedata.phases = [cumulativedata.phases;phases];
                cumulativedata.types = [cumulativedata.types;types];
                repeats = repeats+max(cumulativedata.repeats);
                cumulativedata.repeats = [cumulativedata.repeats;repeats]; % repeats always gets added!
                cumulativedata.spikeWaveforms = [cumulativedata.spikeWaveforms;spikeWaveforms];
                cumulativedata.spikeTimestamps = [cumulativedata.spikeTimestamps;spikeTimestamps];
                cumulativedata.eyeData = [cumulativedata.eyeData;eyeSig];
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