classdef orientedGaborsFreeDrinks<orientedGabors
    % ORIENTEDGABORSFREEDRINKS subclass of orientedGabors for free Drinks 
    properties
    end
    
    methods
        function s=orientedGaborsFreeDrinks(pixPerCycs,targetOrientations,distractorOrientations,mean,radius,contrasts,thresh, ...
                yPositionPercent,maxWidth,maxHeight,scaleFactor,interTrialLuminance,waveform,normalizedSizeMethod)
            % ORIENTEDGABORSFREEDRINKS  class constructor.
            % s = orientedGabors([pixPerCycs],[targetOrientations],[distractorOrientations],mean,radius,contrasts,thresh,yPositionPercent,maxWidth,maxHeight,scaleFactor,interTrialLuminance,[waveform],[normalizedSizeMethod])
            % orientations in radians
            % mean, contrasts, yPositionPercent normalized (0 <= value <= 1)
            % radius is the std dev of the enveloping gaussian, (by default in normalized units of the diagonal of the stim region)
            % thresh is in normalized luminance units, the value below which the stim should not appear
            s=s@orientedGabors(pixPerCycs,targetOrientations,distractorOrientations,mean,radius,contrasts,thresh, ...
                yPositionPercent,maxWidth,maxHeight,scaleFactor,interTrialLuminance,waveform,normalizedSizeMethod);
        end
        
        function [sm,updateSM,resInd,stimList,LUT,targetPorts,distractorPorts,details,text,indexPulses,imagingTasks,ITL] =...
                calcStim(sm,tm,st,tR,~)
            % see BCorePath\documentation\stimManager.calcStim.txt for argument specification (applies to calcStims of all stimManagers)
            % 1/3/0/09 - trialRecords now includes THIS trial
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
            interTrialLuminance = sm.interTrialLuminance;
            interTrialDuration = sm.interTrialDuration;
            
            details.pctCorrectionTrials=tm.percentCorrectionTrials;
            
            if ~isempty(tR) && length(tR)>=2
                lastRec=tR(end-1);
            else
                lastRec=[];
            end
            
            [targetPorts, distractorPorts, details] = tm.assignPorts(details,lastRec,responsePorts);
            % freeDrinks Alternate needs two records

            numFreqs=length(sm.pixPerCycs);
            details.pixPerCyc=sm.pixPerCycs(ceil(rand*numFreqs));
            
            numTargs=length(sm.targetOrientations);
            % fixes 1xN versus Nx1 vectors if more than one targetOrientation
            if size(sm.targetOrientations,1)==1 && size(sm.targetOrientations,2)>1
                targetOrientations=sm.targetOrientations';
            else
                targetOrientations=sm.targetOrientations;
            end
            if size(sm.distractorOrientations,1)==1 && size(sm.distractorOrientations,2)>1
                distractorOrientations=sm.distractorOrientations';
            else
                distractorOrientations=sm.distractorOrientations;
            end
            
            details.orientations = targetOrientations(ceil(rand(length(targetPorts),1)*numTargs));
            
            numDistrs=length(sm.distractorOrientations);
            if numDistrs>0
                numGabors=length(targetPorts)+length(distractorPorts);
                details.orientations = [details.orientations; distractorOrientations(ceil(rand(length(distractorPorts),1)*numDistrs))];
                distractorLocs=distractorPorts;
            else
                numGabors=length(targetPorts);
                distractorLocs=[];
            end
            details.phases=rand(numGabors,1)*2*pi;
            
            xPosPcts = [linspace(0,1,st.numPorts+2)]';
            xPosPcts = xPosPcts(2:end-1);
            details.xPosPcts = xPosPcts([targetPorts'; distractorLocs']);
            
            details.contrast=sm.contrasts(ceil(rand*length(sm.contrasts))); % pick a random contrast from list
            
            
            
            params = [repmat([sm.radius details.pixPerCyc],numGabors,1) details.phases details.orientations repmat([details.contrast sm.thresh],numGabors,1) details.xPosPcts repmat([sm.yPosPct],numGabors,1)];
            out(:,:,1)=computeGabors(params,sm.mean,min(width,sm.maxWidth),min(height,sm.maxHeight),sm.waveform, sm.normalizedSizeMethod,0);
            
            if strcmp(class(tm),'nAFC') && details.correctionTrial
                text='correction trial!';
            else
                text=sprintf('pixPerCyc: %g',details.pixPerCyc);
            end
            
            
            discrimStim=[];
            discrimStim.stimulus=out;
            discrimStim.stimType='loop';
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            fdLikelihood = tm.freeDrinkLikelihood;
            autoTrigger = {};
            for i = 1:length(responsePorts)
                autoTrigger{end+1} = fdLikelihood;
                autoTrigger{end+1} = responsePorts(i);
            end
            discrimStim.autoTrigger = autoTrigger;
            discrimStim.punishResponses=false;
            discrimStim.framesUntilTimeout=inf; % #### hard coded here is this the right strategy?
            discrimStim.ledON = [false false];
            discrimStim.soundPlayed = [];
            
            preRequestStim=[];
            
            preResponseStim=[];
            
            postDiscrimStim = [];
            
            interTrialStim.interTrialLuminance = sm.interTrialLuminance;
            interTrialStim.duration = sm.interTrialDuration;
            interTrialStim.soundPlayed = [];
            
            ITL = interTrialLuminance;
            details.interTrialDuration = interTrialDuration;
            
            stimList = {...
                'preRequestStim',preRequestStim;...
                'discrimStim',discrimStim;...
                'postDiscrimStim',postDiscrimStim;...
                'preResponseStim',preResponseStim;...
                'interTrialStim',interTrialStim};


        end % end function
        
        function out=stimMgrOKForTrialMgr(sm,tm)
            assert(isa(tm,'trialManager'),'orientedGabors:stimMgrOKForTrialMgr:incorrectType','need a trialManager object');
            switch class(tm)
                case {'freeDrinks','freeDrinksCenterOnly','freeDrinksSidesOnly','freeDrinksAlternate'}
                    out=true;
                otherwise
                    out=false;
            end
        end
        
    end
    
end