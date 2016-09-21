classdef orientedGabors<stimManager
    % ORIENTEDGABORS presents gabors of 
    % "targetOrientations" in targetPorts and 
    % "distractorOrientations" in distractorPorts
    properties
        pixPerCycs = [];
        targetOrientations = [];
        distractorOrientations = [];
        
        mean = 0;
        radius = 0;
        contrasts = 0;
        thresh = 0;
        yPosPct = 0;
        
        LUT =[];
        LUTbits=0;
        waveform='square';
        normalizedSizeMethod='normalizeDiagonal';
    end
    
    methods
        function s=orientedGabors(pixPerCycs,targetOrientations,distractorOrientations,mean,radius,contrasts,thresh, ...
                yPositionPercent,maxWidth,maxHeight,scaleFactor,interTrialLuminance,waveform,normalizedSizeMethod)
            % ORIENTEDGABORS  class constructor.
            % s = orientedGabors([pixPerCycs],[targetOrientations],[distractorOrientations],mean,radius,contrasts,thresh,yPositionPercent,maxWidth,maxHeight,scaleFactor,interTrialLuminance,[waveform],[normalizedSizeMethod])
            % orientations in radians
            % mean, contrasts, yPositionPercent normalized (0 <= value <= 1)
            % radius is the std dev of the enveloping gaussian, (by default in normalized units of the diagonal of the stim region)
            % thresh is in normalized luminance units, the value below which the stim should not appear
            s=s@stimManager(maxWidth, maxHeight, scaleFactor, interTrialLuminance);
            
            % create object using specified values
            assert(all(pixPerCycs)>0,'orientedGabors:orientedGabors:incorrectType','pixPerCycs must all be > 0');
            s.pixPerCycs=pixPerCycs;
            
            assert(all(isnumeric(targetOrientations)) && all(isnumeric(distractorOrientations)),...
                'orientedGabors:orientedGabors:incorrectType','targetOrientations and distractorOrientations must all be numeric');
            s.targetOrientations=targetOrientations;
            s.distractorOrientations=distractorOrientations;
            
            assert(mean >= 0 && mean<=1,'orientedGabors:orientedGabors:incorrectValue','mean must all be > 0 and < 1');
            s.mean=mean;
            
            assert(radius >= 0,'orientedGabors:orientedGabors:incorrectValue','radius must all be >=0');
            s.radius=radius;
            
            
            assert(isnumeric(contrasts),'orientedGabors:orientedGabors:incorrectType','contrasts must all be numeric');
            s.contrasts=contrasts;
            
            assert(thresh>=0,'orientedGabors:orientedGabors:incorrectValue','thresh must be >0');
            s.thresh=thresh;
            
            assert(isnumeric(yPositionPercent),'orientedGabors:orientedGabors:incorrectType','yPositionPercent must be numeric');
            s.yPosPct=yPositionPercent;
            
            
            assert(ismember(waveform,{'sine', 'square', 'none'}),'orientedGabors:orientedGabors:incorrectValue',...
                'waveform must be one of ''sine'', ''square'', or ''none''');
            s.waveform = waveform;
            
            assert(ismember(normalizedSizeMethod,{'normalizeVertical', 'normalizeHorizontal', 'normalizeDiagonal' , 'none'}),...
                'orientedGabors:orientedGabors:incorrectValue',...
                'normalizeMethod must be ''normalizeVertical'', ''normalizeHorizontal'', or ''normalizeDiagonal'', or ''none''');
            s.normalizedSizeMethod = normalizedSizeMethod;
            
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
            interTrialLuminance = sm.interTrialLuminance();
            interTrialDuration = sm.interTrialDuration;
            
            details.pctCorrectionTrials=tm.percentCorrectionTrials;
            
            if ismember(class(tm),{'biasedNAFC'})
                details.bias = tm.bias;
            end
            
            if ~isempty(tR) && length(tR)>=2
                lastRec=tR(end-1);
            else
                lastRec=[];
            end
            
            [targetPorts, distractorPorts, details] = tm.assignPorts(details,lastRec,responsePorts);
            % freeDrinks Alternate needs two records

            type = sm.getStimType(tm);

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
            if iscell(type) && strcmp(type{1},'trigger')
                out(:,:,2)=sm.mean;
            end
            
            if strcmp(class(tm),'nAFC') && details.correctionTrial
                text='correction trial!';
            else
                text=sprintf('pixPerCyc: %g',details.pixPerCyc);
            end
            
            
            discrimStim=[];
            discrimStim.stimulus=out;
            discrimStim.stimType=type;
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            switch class(tm)
                case {'freeDrinks','freeDrinksCenterOnly','freeDrinksSidesOnly','freeDrinksAlternate'}
                    fdLikelihood = tm.freeDrinkLikelihood;
                    autoTrigger = {};
                    for i = 1:length(responsePorts)
                        autoTrigger{end+1} = fdLikelihood;
                        autoTrigger{end+1} = responsePorts(i);
                    end
                    discrimStim.autoTrigger = autoTrigger;
                case {'nAFC','autopilot','goNoGo'}
                    discrimStim.autoTrigger=[];
            end
            discrimStim.punishResponses=false;
            discrimStim.framesUntilTimeout=inf; % #### hard coded here is this the right strategy?
            discrimStim.ledON = [false false];
            discrimStim.soundPlayed = [];
            
            preRequestStim=[];
            preRequestStim.stimulus=interTrialLuminance;
            preRequestStim.stimType='loop';
            preRequestStim.scaleFactor=0;
            preRequestStim.startFrame=0;
            preRequestStim.autoTrigger=[];
            preRequestStim.punishResponses=false;
            preRequestStim.framesUntilTimeOut=NaN;
            preRequestStim.ledON = [false false];
            
            preResponseStim=discrimStim;
            preResponseStim.punishResponses=false;
            preResponseStim.ledON = [false false];
            
            postDiscrimStim = [];
            
            interTrialStim.duration = interTrialDuration;
            details.interTrialDuration = interTrialDuration;
            ITL = interTrialLuminance;

            stimList = {...
                'preRequestStim',preRequestStim;...
                'discrimStim',discrimStim;...
                'postDiscrimStim',postDiscrimStim;...
                'preResponseStim',preResponseStim;...
                'interTrialStim',interTrialStim};


        end % end function
        
        function type = getStimType(sm,tm)
            switch class(tm)
                case {'freeDrinks','freeDrinksCenterOnly','freeDrinksSidesOnly','freeDrinksAlternate'}
                    type='loop';
                case 'nAFC'
                    type={'trigger',true};
                case 'autopilot'
                    type='loop';
                case 'goNoGo'
                    type={'trigger',true};
                otherwise
                    error('unsupported trialManagerClass');
            end
        end
        
        function d=display(s)
            d=['orientedGabors (n target, m distractor gabors, randomized phase, equal spatial frequency, p>=n+m horiz positions)\n'...
                '\t\t\tpixPerCycs:\t[' num2str(s.pixPerCycs) ...
                ']\n\t\t\ttarget orientations:\t[' num2str(s.targetOrientations) ...
                ']\n\t\t\tdistractor orientations:\t[' num2str(s.distractorOrientations) ...
                ']\n\t\t\tmean:\t' num2str(s.mean) ...
                '\n\t\t\tradius:\t' num2str(s.radius) ...
                '\n\t\t\tcontrast:\t' num2str(s.contrast) ...
                '\n\t\t\tthresh:\t' num2str(s.thresh) ...
                '\n\t\t\tpct from top:\t' num2str(s.yPosPct)];
            d=sprintf(d);
        end
        
        function [out, newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            newLUT=LUTparams.compiledLUT;
            
            nAFCindex = find(strcmp(LUTparams.compiledLUT,'nAFC'));
            if isempty(nAFCindex) || (~isempty(nAFCindex) && ~all([basicRecords.trialManagerClass]==nAFCindex))
                warning('only works for nAFC trial manager')
                out=struct;
            else
                
                try
                    stimDetails=[trialRecords.stimDetails];
                    [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                    [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                    [out.pixPerCyc newLUT] = extractFieldAndEnsure(stimDetails,{'pixPerCyc'},'none',newLUT);
                    [out.orientations newLUT] = extractFieldAndEnsure(stimDetails,{'orientations'},'none',newLUT);
                    [out.phases newLUT] = extractFieldAndEnsure(stimDetails,{'phases'},'none',newLUT);
                    [out.xPosPcts newLUT] = extractFieldAndEnsure(stimDetails,{'xPosPcts'},'none',newLUT);
                    [out.contrast newLUT] = extractFieldAndEnsure(stimDetails,{'contrast'},'scalar',newLUT);
                    
                    % 12/16/08 - this stuff might be common to many stims
                    % should correctionTrial be here in compiledDetails (whereas it was originally in compiledTrialRecords)
                    % or should extractBasicRecs be allowed to access stimDetails to get correctionTrial?
                    
                catch ex
                    out=handleExtractDetailFieldsException(sm,ex,trialRecords);
                    verifyAllFieldsNCols(out,length(trialRecords));
                    return
                end
                
            end
            verifyAllFieldsNCols(out,length(trialRecords));
        end
        
        function s=fillLUT(s,method,linearizedRange,plotOn)
            %function s=fillLUT(s,method,linearizedRange [,plotOn]);
            %stim=fillLUT(stim,'linearizedDefault');
            %note:
            % PR added method 'hardwiredLinear' (hardwired linearized lut range 0-1)
            %   note, this could also be loaded from file
            if ~exist('plotOn','var')
                plotOn=0;
            end
            
            useUncorrected=0;
            
            switch method
                case 'hardwiredLinear' % added PR 5/5/09
                    uncorrected=makelinearlutPR;
                    useUncorrected=1;
                case 'mostRecentLinearized' % not supported
                    
                    method
                    error('that method for getting a LUT is not defined');
                    
                case 'linearizedDefault' %
                    
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
                    
                    sensorValues = [measured_R, measured_G, measured_B];
                    sensorRange = [min(sensorValues), max(sensorValues)];
                    gamutRange = [min(sent), max(sent)];
                    %oldCLUT = Screen('LoadNormalizedGammaTable', w, linearizedCLUT,1);
                case 'useThisMonitorsUncorrectedGamma'
                    
                    LUTBitDepth=8;
                    numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID);
                    ramp=[0:fraction:1];
                    grayColors= [ramp;ramp;ramp]';
                    %maybe ask for red / green / blue gun only
                    uncorrected=grayColors;
                    useUncorrected=1;
                case 'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5'
                    conn=dbConn();
                    mac = BCoreUtil.getMACaddressSafely;
                    
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
                            a = dir(getBCorePath);
                            if any(ismember({a.name},'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat')) && ...
                                    datenum(a(ismember({a.name},'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat')).date)>floor(now)
                                temp = load(fullfile(getBCorePath,'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat'));
                                uncorrected = temp.cal.linearizedCLUT;
                                useUncorrected=1; % its already corrected
                                downloadCLUT = false;
                            end
                        end
                        if downloadCLUT
                            timeRange=[datenum('05-15-2011 00:01','mm-dd-yyyy HH:MM') datenum('05-15-2011 23:59','mm-dd-yyyy HH:MM')];
                            cal=getCalibrationData(conn,mac,timeRange);
                            closeConn(conn)
                            uncorrected = cal.linearizedCLUT;
                            useUncorrected=1; % its already corrected
                            % now save cal
                            filename = fullfile(getBCorePath,'WestinghouseL2410NM_May2011_255RGBBoxInterpBkgnd.5.mat');
                            save(filename,'cal');
                        end
                    end
                case 'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5'
                    conn=dbConn();
                    mac = BCoreUtil.getMACaddressSafely;
                    
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
                            a = dir(getBCorePath);
                            if any(ismember({a.name},'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat')) && ...
                                    datenum(a(ismember({a.name},'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat')).date)>floor(now)
                                temp = load(fullfile(getBCorePath,'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat'));
                                uncorrected = temp.cal.linearizedCLUT;
                                useUncorrected=1; % its already corrected
                                downloadCLUT = false;
                            end
                        end
                        if downloadCLUT
                            timeRange=[datenum('03-19-2011 00:01','mm-dd-yyyy HH:MM') datenum('03-19-2011 15:00','mm-dd-yyyy HH:MM')];
                            cal=getCalibrationData(conn,mac,timeRange);
                            closeConn(conn)
                            uncorrected = cal.linearizedCLUT;
                            useUncorrected=1; % its already corrected
                            % now save cal
                            filename = fullfile(getBCorePath,'ViewSonicPF790-VCDTS21611_Mar2011_255RGBBoxInterpBkgnd.5.mat');
                            save(filename,'cal');
                        end
                    end
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
                [linearizedCLUT(:,1), g.R]=fitGammaAndReturnLinearized(sent, measured_R, linearizedRange, sensorRange, gamutRange, 2^LUTBitDepth,plotOn);
                
                if plotOn
                    subplot([312]);
                end
                [linearizedCLUT(:,2), g.G]=fitGammaAndReturnLinearized(sent, measured_G, linearizedRange, sensorRange, gamutRange, 2^LUTBitDepth,plotOn);
                
                if plotOn
                    subplot([313]);
                end
                [linearizedCLUT(:,3), g.B]=fitGammaAndReturnLinearized(sent, measured_B, linearizedRange, sensorRange, gamutRange, 2^LUTBitDepth,plotOn);
            end
            
            s.LUT=linearizedCLUT;
            
        end
        
        function s=flushLUT(s)
            %method to flush the look up table, see fillLUT
            
            s.LUT=[];
            s.LUTbits=0;
        end
        
        function [out, s, updateSM]=getLUT(s,bits)
            if isempty(s.LUT) || s.LUTbits~=bits
                updateSM=true;
                s.LUTbits=bits;
                %     s=fillLUT(s,'useThisMonitorsUncorrectedGamma');
                % s=fillLUT(s,'linearizedDefault',[0 1],false);
                %     s=fillLUT(s,'hardwiredLinear',[0 1],false);
                b = BCoreUtil.getMACaddressSafely;
                
                if ismember(b,{'7CD1C3E5176F','F8BC128444CB'... balaji Macbook air, robert analysis comp #####
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
        
        function out=stimMgrOKForTrialMgr(sm,tm)
            assert(isa(tm,'trialManager'),'orientedGabors:stimMgrOKForTrialMgr:incorrectType','need a trialManager object');
            switch class(tm)
                case 'nAFC'
                    out=true;
                case 'goNoGo'
                    out=true;
                otherwise
                    out=false;
            end
        end
        
    end
    
end