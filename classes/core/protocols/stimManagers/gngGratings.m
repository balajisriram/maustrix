classdef gngGratings<afcGratings
    properties
    end
    
    methods
        function s=gngGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,radiusType, annuli,location,...
                waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos, doPostDiscrim, phaseDetails, LEDParams)
            % GNGGRATINGS  class constructor.
            % 
            % s = gngGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,annuli,location,
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
            s = s@afcGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,radiusType, annuli,location,...
                waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos, doPostDiscrim, phaseDetails, LEDParams);
            
            assert(~isinf(maxDuration),'gngGratings:gngGratings:improperValue','maxDuration cannot be infinity');
            
        end
        
        
        function [sm,updateSM,resInd,stimList,LUT,targetPorts,distractorPorts,details,text,indexPulses,imagingTasks,ITL] =...
                calcStim(sm,tm,st,tR,~)
            
            assert(isa(tm,'goNoGo'),'gngGratings:calcStim:incompatibleType','gngGratimgs requires a goNoGo tm. You gave %s',class(tm));
            resolutions = st.resolutions;
            LUTbits = st.getLUTBits();
            responsePorts = tm.responsePorts;
            targetPorts = tm.targetPorts;
            distractorPorts = [];
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
            [targetStim, details] = tm.assignStim(details,lastRec);
            
            % set up params for computeGabors
            height = min(height,sm.maxHeight);
            width = min(width,sm.maxWidth);
            
            % lets save some of the details for later
            details.afcGratingType = sm.getType(structize(sm));
            
            % whats the chosen stim?
            if strcmp(targetStim,'go')
                chosenStimIndex = 1;
            elseif strcmp(targetStim,'noGo')
                chosenStimIndex = 2;
            else
                error('cannot support this here')
            end
            
            stim = [];
            
            stim.height = height;
            stim.width = width;
            stim.rngMethod = sm.ordering.method;
            if isempty(sm.ordering.seed)
                stim.seedVal = sum(100*clock);
            end
            
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
                    stim.location           = chooseFrom(sm.location{chosenStimIndex});
                    stim.maxDuration        = round(chooseFrom(sm.maxDuration{chosenStimIndex})*hz);
                    stim.waveform           = sm.waveform;
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
            details.pixPerCycs          = stim.pixPerCycs;
            details.driftfrequencies    = stim.driftfrequencies;
            details.orientations        = stim.orientations;
            details.phases              = stim.phases;
            details.contrasts           = stim.contrasts;
            details.maxDuration         = stim.maxDuration;
            details.radii               = stim.radii;
            details.annuli              = stim.annuli;
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
                    type = 'static';
                    grating = sm.computeGabor(stim); % #### new                    
            end

            timeout=stim.maxDuration;

            % LEDParams
            %[details, stim] = setupLED(details, stim, sm.LEDParams,arduinoCONN);
            
            discrimStim=[];
            switch type
                case 'expert'
                    discrimStim.stimulus=stim;
                case 'static'
                    discrimStim.stimulus=grating;
            end
            
            discrimStim.stimType=type;
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            discrimStim.autoTrigger=[];
            discrimStim.punishResponses=false;
            discrimStim.framesUntilTimeout=timeout;
            discrimStim.ledON = false; % #### presetting here
            discrimStim.soundPlayed = {'stimOn',50}; % #### need to incorporate this in stimSpec
            
            preRequestDelay = 100;
            preRequestStim=[];
            preRequestStim.stimulus=sm.getInterTrialLuminance();
            preRequestStim.stimType='loop';
            preRequestStim.scaleFactor=0;
            preRequestStim.startFrame=0;
            preRequestStim.autoTrigger=[];
            preRequestStim.punishResponses=true;
            preRequestStim.framesUntilTimeout=preRequestDelay;
            preRequestStim.ledON = false; % #### presetting here
            preRequestStim.soundPlayed = {'trialStartSound',50};
            
            postDiscrimStim = preRequestStim;
            postDiscrimStim.framesUntilTimeout = tm.responseLockoutMs/1000*hz;
            postDiscrimStim.punishResponses = punish;
            
            interTrialStim.interTrialLuminance = sm.getInterTrialLuminance();
            interTrialStim.duration = sm.getInterTrialDuration();
            ITL = sm.getInterTrialLuminance();
            
            
            details.interTrialDuration = sm.getInterTrialDuration();
            details.stimManagerClass = class(sm);
            details.trialManagerClass = class(tm);
            details.scaleFactor = scaleFactor;
            details.preRequestDelay = preRequestDelay;
            
            if strcmp(trialManagerClass,'nAFC') && details.correctionTrial
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
    end
end