classdef afcGratingsPDPhases<stimManager
    
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
        
        LUT =[];
        LUTbits=0;
        
        doCombos=true;
        doPostDiscrim = false;
        LEDAndPostDiscrimDetails = [];
    end
    
    methods
        function s=afcGratingsPDPhases(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,radiusType, annuli,location, ...
                waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos, doPostDiscrim, LEDParams, LEDAndPostDiscrimDetails)
            % AFCGRATINGSPDPHASES  class constructor.
            % this class is specifically designed for behavior. It does not incorporate
            % many of the features usually present in GRATINGS like the ability to
            % show multiple types of gratings in the same trial.
            % s = afcGratingsPDPhases(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,annuli,location,
            %       waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance, LEDParams, LEDAndPostDiscrimDetails)
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
            %#### needs to be removed
            s=s@stimManager(maxWidth, maxHeight, scaleFactor, interTrialLuminance);
            
            s.LEDParams.active = false;
            s.LEDParams.numLEDs = 0;
            s.LEDParams.IlluminationModes = {};
            
            s.pixPerCycs = pixPerCycs;
            s.driftfrequencies = driftfrequencies;
            s.orientations = orientations;
            s.phases = phases;
            s.contrasts = contrasts;
            s.maxDuration = maxDuration;
            s.radii = radii;
            s.radiusType = radiusType;
            s.annuli = annuli;
            s.location = location;
            s.waveform = waveform;
            s.normalizationMethod = normalizationMethod;
            s.mean = mean;
            s.thresh = thresh;
            s.maxWidth = maxWidth;
            s.maxHeight = maxHeight;
            s.scaleFactor = scaleFactor;
            s.interTrialLuminance = interTrialLuminance;
            s.doCombos = doCombos;
            s.doPostDiscrim=doPostDiscrim;
            s.LEDParams = LEDParams;
            
            % pixPerCycs
            if islogical(doCombos)
                s.doCombos = doCombos;
            else
                doCombos
                error('doCombos not in the right format');
            end
            
            % pixPerCycs
            if iscell(pixPerCycs) && length(pixPerCycs)==2 && ...
                    isnumeric(pixPerCycs{1}) && all(pixPerCycs{1}>0) && isnumeric(pixPerCycs{2}) && all(pixPerCycs{2}>0)
                s.pixPerCycs = pixPerCycs;
                L1 = length(pixPerCycs{1});
                L2 = length(pixPerCycs{2});
            else
                pixPerCycs
                error('pixPerCycs not in the right format');
            end
            
            % driftfrequencies
            if iscell(driftfrequencies) && length(driftfrequencies)==2 && ...
                    isnumeric(driftfrequencies{1}) && all(driftfrequencies{1}>=0) && isnumeric(driftfrequencies{2}) && all(driftfrequencies{2}>=0)
                s.driftfrequencies = driftfrequencies;
                if ~doCombos && length(driftfrequencies{1})~=L1 && length(driftfrequencies{2})~=L2
                    error('the lengths don''t match. ')
                end
            else
                driftfrequencies
                error('driftfrequencies not in the right format');
            end
            
            % orientations
            if iscell(orientations) && length(orientations)==2 && ...
                    isnumeric(orientations{1}) && all(~isinf(orientations{1})) && isnumeric(orientations{2}) &&  all(~isinf(orientations{2}))
                s.orientations = orientations;
                if ~doCombos && length(orientations{1})~=L1 && length(orientations{2})~=L2
                    error('the lengths don''t match. ')
                end
            else
                orientations
                error('orientations not in the right format');
            end
            
            % phases
            if iscell(phases) && length(phases)==2 && ...
                    isnumeric(phases{1}) && all(~isinf(phases{1})) && isnumeric(phases{2}) && all(~isinf(phases{2}))
                s.phases = phases;
                if ~doCombos && length(phases{1})~=L1 && length(phases{2})~=L2
                    error('the lengths don''t match. ')
                end
            else
                phases
                error('phases not in the right format');
            end
            
            % contrasts
            if iscell(contrasts) && length(contrasts)==2 && ...
                    isnumeric(contrasts{1}) && all(contrasts{1}>=0) && all(contrasts{1}<=1) && isnumeric(contrasts{2}) && all(contrasts{2}>=0) && all(contrasts{2}<=1)
                s.contrasts = contrasts;
                if ~doCombos && length(contrasts{1})~=L1 && length(contrasts{2})~=L2
                    error('the lengths don''t match. ')
                end
            else
                contrasts
                error('contrasts not in the right format');
            end
            
            % maxDuration
            if iscell(maxDuration) && length(maxDuration)==2 && ...
                    isnumeric(maxDuration{1}) && all(maxDuration{1}>0) && isnumeric(maxDuration{2}) && all(maxDuration{2}>0)
                s.maxDuration = maxDuration;
                if ~doCombos && length(maxDuration{1})~=L1 && length(maxDuration{2})~=L2
                    error('the lengths don''t match. ')
                end
            else
                maxDuration
                error('maxDuration not in the right format');
            end
            
            % radii
            if iscell(radii) && length(radii)==2 && ...
                    isnumeric(radii{1}) && all(radii{1}>=0) && isnumeric(radii{2}) && all(radii{2}>=0)
                s.radii = radii;
                if ~doCombos && length(radii{1})~=L1 && length(radii{2})~=L2
                    error('the lengths don''t match. ')
                end
            else
                radii
                error('radii not in the right format');
            end
            
            
            % radiusType
            if ischar(radiusType) && ismember(radiusType,{'gaussian','hardEdge'})
                s.radiusType = radiusType;
            else
                radiusType
                error('radiusType not in the right format');
            end
            
            
            % annuli
            if iscell(annuli) && length(annuli)==2 && ...
                    isnumeric(annuli{1}) && all(annuli{1}>=0) && isnumeric(annuli{2}) && all(annuli{2}>=0)
                s.annuli = annuli;
                if ~doCombos && length(annuli{1})~=L1 && length(annuli{2})~=L2
                    error('the lengths don''t match. ')
                end
            else
                annuli
                error('annuli not in the right format');
            end
            
            % location
            if iscell(location) && length(location)==2 && ...
                    isnumeric(location{1}) && all(location{1}>=0) && size(location{1},2)==2 && ...
                    isnumeric(location{2}) && all(location{2}>=0) && size(location{2},2)==2
                s.location = location;
                if ~doCombos && length(location{1})~=L1 && length(location{2})~=L2
                    error('the lengths don''t match. ')
                end
            else
                location
                error('location not in the right format');
            end
            
            % waveform
            if ischar(waveform) && ismember(waveform,{'sine','square'})
                s.waveform = waveform;
            else
                waveform
                error('waveform not the right format');
            end
            
            % normalizationMethod
            if ischar(normalizationMethod) && ismember(normalizationMethod,{'normalizeVertical', 'normalizeHorizontal', 'normalizeDiagonal' , 'none'})
                s.normalizationMethod = normalizationMethod;
            else
                normalizationMethod
                error('normalizationMethod not the right format');
            end
            
            % mean
            if mean>=0 && mean<=1
                s.mean = mean;
            else
                mean
                error('mean not the right format');
            end
            
            % thresh
            if thresh>=0
                s.thresh = thresh;
            else
                thresh
                error('thresh not the right format');
            end
            
            % doPostDiscrim
            if doPostDiscrim
                % make sure that maxDuration is set to finite values
                if any(isinf(maxDuration{1})) || any(isinf(maxDuration{2}))
                    error('cannot have post-discrim phase and infnite discrim phase. reconsider');
                end
                s.doPostDiscrim = true;
            else
                s.doPostDiscrim = false;
            end
            
            
            % LED state
            if isstruct(LEDParams)
                s.LEDParams = LEDParams;
            else
                error('LED state should be a structure');
            end
            if s.LEDParams.numLEDs>0
                % go through the Illumination Modes and check if they seem
                % reasonable
                cumulativeFraction = 0;
                if s.LEDParams.active && isempty(s.LEDParams.IlluminationModes)
                    error('need to provide atleast one illumination mode if LEDs is to be active');
                end
                for i = 1:length(s.LEDParams.IlluminationModes)
                    if any(s.LEDParams.IlluminationModes{i}.whichLED)>s.LEDParams.numLEDs
                        error('asking for an LED that is greater than numLEDs')
                    else
                        if length(s.LEDParams.IlluminationModes{i}.whichLED)~= length(s.LEDParams.IlluminationModes{i}.intensity) || ...
                                any(s.LEDParams.IlluminationModes{i}.intensity>1) || any(s.LEDParams.IlluminationModes{i}.intensity<0)
                            error('specify a single intensity for each of the LEDs and these intensities hould lie between 0 and 1');
                        else
                            cumulativeFraction = [cumulativeFraction cumulativeFraction(end)+s.LEDParams.IlluminationModes{i}.fraction];
                        end
                    end
                end
                
                if abs(cumulativeFraction(end)-1)>eps
                    error('the cumulative fraction should sum to 1');
                else
                    s.LEDParams.cumulativeFraction = cumulativeFraction;
                end
            end
            
            
            
            
            s.LEDAndPostDiscrimDetails = LEDAndPostDiscrimDetails;
            
            if isstruct(LEDAndPostDiscrimDetails) && ...
                    isfield(LEDAndPostDiscrimDetails,'phaseType') && ...
                    isfield(LEDAndPostDiscrimDetails,'phaseLengthInFrames') && ...
                    isfield(LEDAndPostDiscrimDetails,'LEDON')
                s.LEDAndPostDiscrimDetails = LEDAndPostDiscrimDetails;
            else
                keyboard
                error('need this for sure');
            end
            
        end
        
        function [stimulus,updateSM,resolutionIndex,stimList,LUT,targetPorts,distractorPorts,...
                details,interTrialLuminance,text,indexPulses,imagingTasks] =...
                calcStim(stimulus,trialManager,allowRepeats,resolutions,displaySize,LUTbits,...
                responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % see BCorePath\documentation\stimManager.calcStim.txt for argument specification (applies to calcStims of all stimManagers)
            trialManagerClass = class(trialManager);
            % 1/30/09 - trialRecords now includes THIS trial
            indexPulses=[];
            imagingTasks=[];
            [LUT, stimulus, updateSM]=getLUT(stimulus,LUTbits);
            
            mac = BCoreUtil.getMACaddressSafely;
            switch mac
                case {'A41F7278B4DE','A41F729213E2','A41F726EC11C' } %gLab-Behavior rigs 1,2,3
                    [resolutionIndex, height, width, hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
                case {'7845C4256F4C', '7845C42558DF','A41F729211B1'} %gLab-Behavior rigs 4,5,6
                    [resolutionIndex, height, width, hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
                otherwise
                    [resolutionIndex, height, width, hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
            end
            
            if isnan(resolutionIndex)
                resolutionIndex=1;
            end
            
            scaleFactor=getScaleFactor(stimulus); % dummy value since we are phased anyways; the real scaleFactor is stored in each phase's stimSpec
            interTrialLuminance = getInterTrialLuminance(stimulus);
            interTrialDuration = getInterTrialDuration(stimulus);
            
            details.pctCorrectionTrials=trialManager.percentCorrectionTrials;
            details.bias = getRequestBias(trialManager);
            
            if ~isempty(trialRecords) && length(trialRecords)>=2
                lastRec=trialRecords(end-1);
            else
                lastRec=[];
            end
            [targetPorts, distractorPorts, details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);
            
            
            toggleStim=true; type='expert';
            dynamicMode = true; %false %true
            
            % set up params for computeGabors
            height = min(height,getMaxHeight(stimulus));
            width = min(width,getMaxWidth(stimulus));
            
            % lets save some of the details for later
            possibleStims.pixPerCycs            = stimulus.pixPerCycs;
            possibleStims.driftfrequencies      = stimulus.driftfrequencies;
            possibleStims.orientations          = stimulus.orientations;
            possibleStims.phases                = stimulus.phases;
            possibleStims.contrasts             = stimulus.contrasts;
            possibleStims.waveform              = stimulus.waveform;
            possibleStims.maxDuration           = {stimulus.maxDuration{1}*hz,stimulus.maxDuration{2}*hz};
            possibleStims.radii                 = stimulus.radii;
            possibleStims.radiusType            = stimulus.radiusType;
            possibleStims.annuli                = stimulus.annuli;
            possibleStims.location              = stimulus.location;
            possibleStims.normalizationMethod   = stimulus.normalizationMethod;
            possibleStims.mean                  = stimulus.mean;
            possibleStims.thresh                = stimulus.thresh;
            possibleStims.width                 = width;
            possibleStims.height                = height;
            possibleStims.doCombos              = stimulus.doCombos;
            details.possibleStims               = possibleStims;
            details.afcGratingType              = getType(stimulus,structize(stimulus));
            
            % whats the chosen stim?
            if stimulus.doCombos
                % choose a random value for each
                if length(targetPorts)==1
                    stim = [];
                    if targetPorts == 1 % the first of the possible values
                        % pixPerCycs
                        tempVar = randperm(length(stimulus.pixPerCycs{1}));
                        stim.pixPerCycs = stimulus.pixPerCycs{1}(tempVar(1));
                        
                        % driftfrequencies
                        tempVar = randperm(length(stimulus.driftfrequencies{1}));
                        stim.driftfrequencies = stimulus.driftfrequencies{1}(tempVar(1));
                        
                        % orientations
                        tempVar = randperm(length(stimulus.orientations{1}));
                        stim.orientations = stimulus.orientations{1}(tempVar(1));
                        
                        % phases
                        tempVar = randperm(length(stimulus.phases{1}));
                        stim.phases = stimulus.phases{1}(tempVar(1));
                        
                        % contrasts
                        tempVar = randperm(length(stimulus.contrasts{1}));
                        stim.contrasts = stimulus.contrasts{1}(tempVar(1));
                        
                        % waveform
                        stim.waveform = stimulus.waveform;
                        
                        % maxDuration
                        tempVar = randperm(length(stimulus.maxDuration{1}));
                        if ~ismac
                            stim.maxDuration = round(stimulus.maxDuration{1}(tempVar(1))*hz);
                        elseif ismac && hz==0
                            % macs are weird and return a hz of 0 when they really
                            % shouldnt. assume hz = 60 (hack)
                            stim.maxDuration = round(stimulus.maxDuration{1}(tempVar(1))*60);
                        end
                        
                        % radii
                        tempVar = randperm(length(stimulus.radii{1}));
                        stim.radii = stimulus.radii{1}(tempVar(1));
                        
                        % annuli
                        tempVar = randperm(length(stimulus.annuli{1}));
                        stim.annuli = stimulus.annuli{1}(tempVar(1));
                        
                        % location
                        tempVar = randperm(size(stimulus.location{1},1));
                        stim.location = stimulus.location{1}(tempVar(1),:);
                    elseif targetPorts == 3% the second of the possible values
                        % pixPerCycs
                        tempVar = randperm(length(stimulus.pixPerCycs{2}));
                        stim.pixPerCycs = stimulus.pixPerCycs{2}(tempVar(1));
                        
                        % driftfrequencies
                        tempVar = randperm(length(stimulus.driftfrequencies{2}));
                        stim.driftfrequencies = stimulus.driftfrequencies{2}(tempVar(1));
                        
                        % orientations
                        tempVar = randperm(length(stimulus.orientations{2}));
                        stim.orientations = stimulus.orientations{2}(tempVar(1));
                        
                        % phases
                        tempVar = randperm(length(stimulus.phases{2}));
                        stim.phases = stimulus.phases{2}(tempVar(1));
                        
                        % contrasts
                        tempVar = randperm(length(stimulus.contrasts{2}));
                        stim.contrasts = stimulus.contrasts{2}(tempVar(1));
                        
                        % waveform
                        stim.waveform = stimulus.waveform;
                        
                        % maxDuration
                        tempVar = randperm(length(stimulus.maxDuration{2}));
                        if ~ismac
                            stim.maxDuration = round(stimulus.maxDuration{2}(tempVar(1))*hz);
                        elseif ismac && hz==0
                            % macs are weird and return a hz of 0 when they really
                            % shouldnt. assume hz = 60 (hack)
                            stim.maxDuration = round(stimulus.maxDuration{2}(tempVar(1))*60);
                        end
                        
                        % radii
                        tempVar = randperm(length(stimulus.radii{2}));
                        stim.radii = stimulus.radii{2}(tempVar(1));
                        
                        % annuli
                        tempVar = randperm(length(stimulus.annuli{2}));
                        stim.annuli = stimulus.annuli{2}(tempVar(1));
                        
                        % location
                        tempVar = randperm(size(stimulus.location{2},1));
                        stim.location = stimulus.location{2}(tempVar(1),:);
                    else
                        targetPorts
                        sca;
                        keyboard
                        error('eh? should not come here at all')
                    end
                else
                    targetPorts
                    error('not geared for more than one target port. whats wrong??');
                end
            else
                if length(targetPorts)==1
                    if targetPorts == 1
                        tempVar = randperm(length(stimulus.pixPerCycs{1}));
                        which = tempVar(1);
                        stim.pixPerCycs=stimulus.pixPerCycs{1}(which);
                        stim.driftfrequencies=stimulus.driftfrequencies{1}(which);
                        stim.orientations=stimulus.orientations{1}(which);
                        stim.phases=stimulus.phases{1}(which);
                        stim.contrasts=stimulus.contrasts{1}(which);
                        stim.waveform=stimulus.waveform;
                        if ~ismac
                            stim.maxDuration=round(stimulus.maxDuration{1}(which)*hz);
                        elseif ismac && hz==0
                            % macs are weird and return a hz of 0 when they really
                            % shouldnt. assume hz = 60 (hack)
                            stim.maxDuration = round(stimulus.maxDuration{1}(which)*60);
                        end
                        stim.radii=stimulus.radii{1}(which);
                        stim.annuli=stimulus.annuli{1}(which);
                        stim.location=stimulus.location{1}(which,:);
                    elseif targetPorts == 3
                        tempVar = randperm(length(stimulus.pixPerCycs{2}));
                        which = tempVarVar(1);
                        stim.pixPerCycs=stimulus.pixPerCycs{2}(which);
                        stim.driftfrequencies=stimulus.driftfrequencies{2}(which);
                        stim.orientations=stimulus.orientations{2}(which);
                        stim.phases=stimulus.phases{2}(which);
                        stim.contrasts=stimulus.contrasts{2}(which);
                        stim.waveform=stimulus.waveform;
                        if ~ismac
                            stim.maxDuration=round(stimulus.maxDuration{2}(which)*hz);
                        elseif ismac && hz==0
                            % macs are weird and return a hz of 0 when they really
                            % shouldnt. assume hz = 60 (hack)
                            stim.maxDuration = round(stimulus.maxDuration{2}(which)*60);
                        end
                        stim.radii=stimulus.radii{2}(which);
                        stim.annuli=stimulus.annuli{2}(which);
                        stim.location=stimulus.location{2}(which,:);
                    else
                        error('eh? should not come here at all')
                    end
                else
                    error('not geared for more than one target port. whats wrong??');
                end
            end
            % normalizationMethod,mean,thresh,height,width,scaleFactor,interTrialLuminance
            stim.radiusType = stimulus.radiusType;
            stim.normalizationMethod=stimulus.normalizationMethod;
            stim.height=height;
            stim.width=width;
            stim.mean=stimulus.mean;
            stim.thresh=stimulus.thresh;
            stim.doCombos=stimulus.doCombos;
            details.chosenStim = stim;
            
            % have a version in ''details''
            details.doCombos            = stimulus.doCombos;
            details.pixPerCycs          = stim.pixPerCycs;
            details.driftfrequencies    = stim.driftfrequencies;
            details.orientations        = stim.orientations;
            details.phases              = stim.phases;
            details.contrasts           = stim.contrasts;
            details.maxDuration         = stim.maxDuration;
            details.radii               = stim.radii;
            details.annuli              = stim.annuli;
            details.waveform            = stim.waveform;
            
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
                        mask(:,:,1)=ones(height,width,1)*stimulus.mean;
                        [WIDTH HEIGHT] = meshgrid(1:width,1:height);
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
                annulus(:,:,1)=ones(height,width,1)*stimulus.mean;
                bool=(x+width/2-annulusCenterInPixels(1)).^2+(y+height/2-annulusCenterInPixels(2)).^2 < (annulusRadiusInPixels+0.5).^2;
                annulus(:,:,2)=bool(1:height,1:width);
                stim.annuliMatrices{1}=annulus;
            else
                stim.annuliMatrices = {[]};
            end
            
            if isinf(stim.maxDuration)
                timeout=[];
            else
                timeout=stim.maxDuration;
            end
            
            
            % LEDParams
            
            [details, stim] = setupLED(details, stim, stimulus.LEDParams,arduinoCONN);
            
            discrimStim=[];
            discrimStim.stimulus=stim;
            discrimStim.stimType=type;
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            discrimStim.autoTrigger=[];
            if isnan(timeout)
                sca;
                keyboard;
            end
            discrimStim.framesUntilTimeout=timeout;
            discrimStim.ledON = [stim.LEDParam.LED1ON stim.LEDParam.LED2ON];
            
            preRequestStim=[];
            preRequestStim.stimulus=interTrialLuminance;
            preRequestStim.stimType='loop';
            preRequestStim.scaleFactor=0;
            preRequestStim.startFrame=0;
            preRequestStim.autoTrigger=[];
            preRequestStim.punishResponses=false;
            preRequestStim.ledON = [false false];
            preRequestStim.framesUntilTimeout = inf;
            
            preResponseStim = [];
            postDiscrimDetails = [];
            if stimulus.doPostDiscrim
                % okay here thing will need to change
                postDiscrimPhases = find(ismember({stimulus.LEDAndPostDiscrimDetails.phaseType},'post-discrim'));
                postDiscrimStim(length(postDiscrimPhases)) = preRequestStim;
                for phNum = 1:length(postDiscrimPhases)
                    postDiscrimStim(phNum) = preRequestStim;
                    postDiscrimStim(phNum).framesUntilTimeout = stimulus.LEDAndPostDiscrimDetails(postDiscrimPhases(phNum)).phaseLengthInFrames;
                    switch stimulus.LEDAndPostDiscrimDetails(postDiscrimPhases(phNum)).LEDON
                        case 'SameAsDiscrim'
                            postDiscrimStim(phNum).ledON = discrimStim.ledON;
                            postDiscrimDetails(phNum).ledON = postDiscrimStim(phNum).ledON;
                            postDiscrimDetails(phNum).duration = stimulus.LEDAndPostDiscrimDetails(postDiscrimPhases(phNum)).phaseLengthInFrames;
                        case 'AlwaysOn'
                            postDiscrimStim(phNum).ledON = [true true];
                            postDiscrimDetails(phNum).ledON = postDiscrimStim(phNum).ledON;
                            postDiscrimDetails(phNum).duration = stimulus.LEDAndPostDiscrimDetails(postDiscrimPhases(phNum)).phaseLengthInFrames;
                        case 'Random'
                            if rand >0.5
                                which = true;
                            else
                                which = false;
                            end
                            postDiscrimStim(phNum).ledON = [which which];
                            postDiscrimDetails(phNum).ledON = postDiscrimStim(phNum).ledON;
                            postDiscrimDetails(phNum).duration = stimulus.LEDAndPostDiscrimDetails(postDiscrimPhases(phNum)).phaseLengthInFrames;
                        case 'Never'
                            postDiscrimStim(phNum).ledON = [false false];
                            postDiscrimDetails(phNum).ledON = postDiscrimStim(phNum).ledON;
                            postDiscrimDetails(phNum).duration = stimulus.LEDAndPostDiscrimDetails(postDiscrimPhases(phNum)).phaseLengthInFrames;
                    end
                end
            else
                postDiscrimStim = [];
            end
            
            details.postDiscrimDetails = postDiscrimDetails;
            
            interTrialStim.duration = interTrialDuration;
            details.interTrialDuration = interTrialDuration;
            details.stimManagerClass = class(stimulus);
            details.trialManagerClass = trialManagerClass;
            details.scaleFactor = scaleFactor;
            
            if strcmp(trialManagerClass,'nAFC') && details.correctionTrial
                text='correction trial!';
            else
                text=sprintf('thresh: %g',stimulus.thresh);
            end
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
                sca;
                keyboard
            end
            
            % clear the gratingtex from vram
            Screen('Close',gratingtex);
        end % end function
        
        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
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
                case 'linearizedDefault'
                    
                    %WARNING:  need to get gamma from measurements of BCore workstation with NEC monitor and new graphics card
                    
                    
                    LUTBitDepth=8;
                    
                    %sample from lower left of triniton, pmm 070106
                    %sent=       [0      0.0667    0.1333    0.2000    0.2667    0.3333    0.4000    0.4667    0.5333  0.6000    0.6667    0.7333    0.8000    0.8667    0.9333    1.0000];
                    %measured_R= [0.0052 0.0058    0.0068    0.0089    0.0121    0.0167    0.0228    0.0304    0.0398  0.0510    0.065     0.080     0.097     0.117     0.139     0.1645];
                    %measured_G= [0.0052 0.0053    0.0057    0.0067    0.0085    0.0113    0.0154    0.0208    0.0278  0.036     0.046     0.059     0.073     0.089     0.107     0.128 ];
                    %measured_B= [0.0052 0.0055    0.0065    0.0077    0.0102    0.0137    0.0185    0.0246    0.0325  0.042     0.053     0.065     0.081     0.098     0.116     0.138];
                    
                    %sample values from FE992_LM_Tests2_070111.smr: (actually logged them: pmm 070403) -used physiology graphic card
                    sent=       [0      0.0667    0.1333    0.2000    0.2667    0.3333    0.4000    0.4667    0.5333  0.6000    0.6667    0.7333    0.8000    0.8667    0.9333    1.0000];
                    measured_R= [0.0034 0.0046    0.0077    0.0128    0.0206    0.0309    0.0435    0.0595    0.0782  0.1005    0.1260    0.1555    0.189     0.227     0.268     0.314 ];
                    measured_G= [0.0042 0.0053    0.0073    0.0110    0.0167    0.0245    0.0345    0.047     0.063   0.081     0.103     0.127     0.156     0.187     0.222     0.260 ];
                    measured_B= [0.0042 0.0051    0.0072    0.0105    0.0160    0.0235    0.033     0.0445    0.0595  0.077     0.097     0.120     0.1465    0.176     0.208     0.244 ];
                    
                    %oldCLUT = Screen('LoadNormalizedGammaTable', w, linearizedCLUT,1);
                case 'useThisMonitorsUncorrectedGamma'
                    
                    LUTBitDepth=8;
                    numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID);
                    ramp=[0:fraction:1];
                    grayColors= [ramp;ramp;ramp]';
                    %maybe ask for red / green / blue gun only
                    uncorrected=grayColors;
                    useUncorrected=1;
                    
                case 'localCalibStore'
                    try
                        temp = load(fullfile(BCoreUtil.getBCorePath,'monitorCalibration','tempCLUT.mat'));
                        uncorrected = temp.linearizedCLUT;
                        useUncorrected=1;
                    catch ex
                        disp('did you store local calibration details at all????');
                        rethrow(ex)
                    end
                    
                case 'calibrateNow'
                    
                    %[measured_R measured_G measured_B] measureRGBscale()
                    method
                    error('that method for getting a LUT is not defined');
                otherwise
                    method
                    error('that method for getting a LUT is not defined');
            end
            
            if useUncorrected
                linearizedCLUT=uncorrected;
            else
                linearizedCLUT=zeros(2^LUTBitDepth,3);
                if plotOn
                    subplot([311]);
                end
                [linearizedCLUT(:,1) g.R]=fitGammaAndReturnLinearized(sent, measured_R, linearizedRange, 2^LUTBitDepth,plotOn);
                
                if plotOn
                    subplot([312]);
                end
                [linearizedCLUT(:,2) g.G]=fitGammaAndReturnLinearized(sent, measured_G, linearizedRange, 2^LUTBitDepth,plotOn);
                
                if plotOn
                    subplot([313]);
                end
                [linearizedCLUT(:,3) g.B]=fitGammaAndReturnLinearized(sent, measured_B, linearizedRange, 2^LUTBitDepth,plotOn);
            end
            
            s.LUT=linearizedCLUT;
        end
        
        function s=flushLUT(s)
            %method to flush the look up table, see fillLUT
            
            s.LUT=[];
            s.LUTbits=0;
        end
        
        function out = getDetails(sm,stim,what)
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
        
        function [out s updateSM]=getLUT(s,bits)
            if isempty(s.LUT) || s.LUTbits~=bits
                updateSM=true;
                s.LUTbits=bits;
                b = BCoreUtil.getMACaddressSafely;
                if ismember(b,{'7CD1C3E5176F',... balaji Macbook air
                        '180373337162',...
                        })
                    s=fillLUT(s,'useThisMonitorsUncorrectedGamma');
                else
                    s=fillLUT(s,'localCalibStore');
                end
                
            else
                updateSM=false;
            end
            out=s.LUT;
        end
        
        function out = getType(sm,stim)
            sweptParameters = getDetails(sm,stim,'sweptParameters');
            n= length(sweptParameters);
            switch n
                case 0
                    out = 'afcGratingsPDP_noSweep';
                case 1
                    % sweep of a single datatype
                    switch sweptParameters{1}
                        case {'pixPerCycs','spatialFrequencies'}
                            out = 'afcGratingsPDP_sfSweep';
                        case 'driftfrequencies'
                            out = 'afcGratingsPDP_tfSweep';
                        case 'orientations'
                            out = 'afcGratingsPDP_orSweep';
                        case 'phases'
                            out = 'afcGratingsPDP_phaseSweep';
                        case 'contrasts'
                            out = 'afcGratingsPDP_cntrSweep';
                        case 'maxDuration'
                            out = 'afcGratingsPDP_durnSweep';
                        case 'radii'
                            out = 'afcGratingsPDP_radSweep';
                        case 'annuli'
                            out = 'afcGratingsPDP_annSweep';
                        otherwise
                            out = 'undefinedGratings';
                    end
                case 2
                    if all(ismember(sweptParameters,{'contrasts','radii'}))
                        out = 'afcGratingsPDP_cntrXradSweep';
                    elseif all(ismember(sweptParameters,{'contrasts','pixPerCycs'}))
                        out = 'afcGratingsPDP_cntrXsfSweep';
                    elseif all(ismember(sweptParameters,{'phases','maxDuration'}))
                        out = 'afcGratingsPDP_durationSweep_Stat';
                    elseif all(ismember(sweptParameters,{'phases','contrasts'}))
                        out = 'afcGratingsPDP_contrastSweep_Stat';
                    elseif all(ismember(sweptParameters,{'phases','pixPerCycs'}))
                        out = 'afcGratingsPDP_sfSweep_Stat';
                    elseif all(ismember(sweptParameters,{'phases','orientations'}))
                        out = 'afcGratingsPDP_orSweep_Stat';
                    elseif all(ismember(sweptParameters,{'maxDuration','phases'}))
                        out = 'afcGratingsPDP_durSweep_Stat';
                    elseif all(ismember(sweptParameters,{'contrasts','maxDuration'}))
                        out = 'afcGratingsPDP_cntrXdurSweep_Stat';
                    else
                        sweptParameters
                        error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                    end
                case 3
                    if all(ismember(sweptParameters,{'contrasts','pixPerCycs','driftFrequencies'}))
                        out = 'afcGratingsPDP_cntrXsfXtfSweep';
                    elseif all(ismember(sweptParameters,{'contrasts','pixPerCycs','phases'}))
                        out = 'afcGratingsPDP_cntrXsfStationary';
                    elseif all(ismember(sweptParameters,{'maxDuration','phases','contrasts'}))
                        out = 'afcGratingsPDP_cntrXdurSweep_Stat';
                    else
                        sweptParameters
                        error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                    end
                case 4
                    if all(ismember(sweptParameters,{'contrasts','pixPerCycs','driftfrequencies','orientations'}))
                        out = 'afcGratingsPDP_cntrXsfXtfXorSweep';
                    else
                        sweptParameters
                        error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                    end
                otherwise
                    error('unsupported type. if you want this make a name for it');
            end
        end
        
        function out=stimMgrOKForTrialMgr(sm,tm)
            if isa(tm,'trialManager')
                switch class(tm)
                    case 'freeDrinks'
                        out=0;
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

