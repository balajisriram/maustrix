classdef coherentDots<stimManager
    
    properties
        screen_width = 100;         % for matrix
        screen_height = 100;        % for matrix
        num_dots = 100;             % Number of dots to display
        coherence = .8;             % Percent of dots to move in a specified direction
        speed = 1;                  % How fast do our little dots move
        contrast = 1;               % contrast of the dots
        dot_size = 9;              % Width of dots in pixels
        movie_duration = 2;         % in seconds
        pctCorrectionTrials=.5;
        replayMode='loop';
        
        LUT=[];
        LUTbits=0;
        
        LEDParams;
    end
    
    methods
        function s=coherentDots(screen_width,screen_height,num_dots,coherence,speed,contrast, ...
                dot_size,movie_duration,scaleFactor,maxWidth,maxHeight,pctCorrectionTrials,replayMode,interTrialLuminance)
            % COHERENTDOTS  class constructor.
            % s=coherentDots(screen_width,screen_height,num_dots,coherence,speed,contrast,
            %   dot_size,movie_duration,screen_zoom,maxWidth,maxHeight,pctCorrectionTrials,[replayMode,interTrialLuminance])
            %   screen_width - width of sourceRect (determines size of texture to make)
            %   screen_height - height of sourceRect (determines size of texture to make)
            %   num_dots - number of dots to draw
            %   coherence - either a single coherence value, or a cell with 2-element array
            %       specifying a range of coherence values from which to draw randomly
            %       every trial {[loVal hiVal], 'selectWithin'}, or a cell {[values], 'selectFrom'}
            %   speed - either a single speed value, or a 2-element array specifying a
            %       range to randomly draw from every trial {[loVal hiVal], 'selectWithin'},
            %       or a cell {[values], 'selectFrom'}
            %   contrast - either a single contrast value, or a 2-element array
            %       specifying a range to randomly draw from every trial {[loVal hiVal], 'selectWithin'},
            %       or a cell {[values], 'selectFrom'}
            %   dot_size - size in pixels of each dot (square) """ similar to
            %       coherence """
            %   movie_duration - length of the movie in seconds """ similar to
            %       coherence """
            %   screen_zoom - scaleFactor argument passed to stimManager constructor
            %   interTrialLuminance - (optional) defaults to 0
            %
            
            s=s@stimManager(maxWidth, maxHeight, scaleFactor, interTrialLuminance);
            eps = 0.0000001;
            
            screen_zoom = [6 6];
            
            s.LEDParams.active = false;
            s.LEDParams.numLEDs = 0;
            s.LEDParams.IlluminationModes = {};
            
            
            
            % screen_width
            if (floor(screen_width) - screen_width < eps)
                s.screen_width = screen_width;
            else
                disp(screen_width);
                error('screen_width must be an integer')
            end
            
            % screen_height
            if (floor(screen_height) - screen_height < eps)
                s.screen_height = screen_height;
            else
                error('screen_height must be an integer')
            end
            
            % num_dots
            if (floor(num_dots) - num_dots < eps)
                s.num_dots = num_dots;
            else
                error('num_dots must be an integer')
            end
            
            % coherence
            if (isfloat(coherence))
                s.coherence = 1;
                if (length(coherence) == 1)
                    if (coherence >= 0 && coherence <= 1)
                        s.coherence = coherence;
                    else
                        error('Coherence must be between 0 and 1')
                    end
                elseif (length(coherence) == 2)
                    if (coherence(1) >= 0 && coherence(1) <= 1 && coherence(2) >= 0 && coherence(2) <= 1 && (coherence(2) - coherence(1) > 0))
                        s.coherence=coherence;
                    else
                        error('Coherence must be between 0 and 1, with max > min')
                    end
                else
                    error ('Coherence must be either a 1x2 or 1x1 set of floats')
                end
            elseif iscell(coherence)
                if strcmp(coherence{2},'selectWithin') && (length(coherence{1})==2) && (all(coherence{1}>=0)) && (all(coherence{1}<=1))
                    s.coherence = coherence;
                elseif strcmp(coherence{2},'selectFrom') && all(isnumeric(coherence{1})) && (all(coherence{1}>=0)) && (all(coherence{1}<=1))
                    s.coherence = coherence;
                else
                    error('if you pass a cell, it should be of the type selectWithin or selectFrom');
                end
            else
                error('Coherence level must be a 1x1 or 1x2 array between 0 and 1 or a cell of the appropriate type')
            end
            
            % speed
            if (isfloat(speed)) && (isscalar(speed) || length(speed)==2)
                if (length(speed)==2) && ~(speed(1)<=speed(2))
                    error('range of speed must be [min max]');
                end
                s.speed = speed;
            elseif iscell(speed)
                if strcmp(speed{2},'selectWithin') && (length(speed{1})==2) && (all(speed{1}>=0))
                    s.speed = speed;
                elseif strcmp(speed{2},'selectFrom') && all(isnumeric(speed{1})) && (all(speed{1}>=0))
                    s.speed = speed;
                else
                    error('if you pass a cell, it should be of the type selectWithin or selectFrom');
                end
            else
                error('speed (pixels/frame) must be a double or a 2-element array specifying a range or a cell of the appropriate type')
            end
            
            % contrast
            if (length(contrast)==1 || length(contrast)==2) && all(isnumeric(contrast)) && ...
                    all(contrast >=0) && all(contrast <=1)
                if length(contrast)==2 && ~(contrast(1)<=contrast(2))
                    error('range of contrast must be [min max]');
                end
                s.contrast = contrast;
            elseif iscell(contrast)
                if strcmp(contrast{2},'selectWithin') && (length(contrast{1})==2) && (all(contrast{1}>=0)) && (all(contrast{1}<=1))
                    s.contrast = contrast;
                elseif strcmp(contrast{2},'selectFrom') && all(isnumeric(contrast{1})) && (all(contrast{1}>=0)) && (all(contrast{1}<=1))
                    s.contrast = contrast;
                else
                    error('if you pass a cell, it should be of the type selectWithin or selectFrom');
                end
            else
                error('contrast must be >=0 and <=1 and be a single number or a 2-element array specifying a range or a cell of the appropriate type');
            end
            
            % dot_size
            if length(dot_size)==1 && (floor(dot_size) - dot_size < eps)
                s.dot_size = dot_size;
            elseif length(dot_size)==2 && all(floor(dot_size) - dot_size < eps) && dot_size(1)<=dot_size(2)
                s.dot_size = dot_size;
            elseif iscell(dot_size)
                if strcmp(dot_size{2},'selectWithin') && (length(dot_size{1})==2) && (all(dot_size{1}>=0))
                    s.dot_size = dot_size;
                elseif strcmp(dot_size{2},'selectFrom') && all(isnumeric(dot_size{1})) && (all(dot_size{1}>=0))
                    s.dot_size = dot_size;
                else
                    error('if you pass a cell, it should be of the type selectWithin or selectFrom');
                end
            else
                error('dot_size must be an integer or a 2-element array specifying a valid range')
            end
            
            % movie_duration
            if (floor(movie_duration) - movie_duration < eps)
                s.movie_duration = movie_duration;
            elseif length(movie_duration)==2 && all(floor(movie_duration) - movie_duration < eps) && movie_duration(1)<=movie_duration(2)
                s.movie_duration = movie_duration;
            elseif iscell(movie_duration)
                if strcmp(movie_duration{2},'selectWithin') && (length(movie_duration{1})==2) && (all(movie_duration{1}>=0))
                    s.movie_duration = movie_duration;
                elseif strcmp(movie_duration{2},'selectFrom') && all(isnumeric(movie_duration{1})) && (all(movie_duration{1}>=0))
                    s.movie_duration = movie_duration;
                else
                    error('if you pass a cell, it should be of the type selectWithin or selectFrom');
                end
            else
                error('movie_duration must be an integer or a 2-element array specifying a valid range or a cell of the appropriate type')
            end
            
            % screen_zoom
            if (length(screen_zoom) == 2 && isnumeric(screen_zoom))
                screen_zoom = screen_zoom;
            else
                error('screen_zoom must be a 1x2 array with integer values')
            end
            
            % pctCorrectionTrials
            if isscalar(pctCorrectionTrials) && pctCorrectionTrials<=1 && pctCorrectionTrials>=0
                s.pctCorrectionTrials=pctCorrectionTrials;
            else
                error('pctCorrectionTrials must be a scalar between 0 and 1');
            end
            
            % replayMode
            if ~isempty(replayMode)
                if ischar(replayMode) && (strcmp(replayMode,'loop') || strcmp(replayMode,'once'))
                    s.replayMode=replayMode;
                else
                    error('replay mode must be ''loop'' or ''once''');
                end
            else
                s.replayMode='loop';
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
            
            
            % maxWidth, maxHeight, scale factor, intertrial luminance
            if isempty(interTrialLuminance)
                
            else
                % check intertrial luminance
                if interTrialLuminance >=0 && interTrialLuminance <= 1
                    
                else
                    error('interTrialLuminance must be <=1 and >=0 - will be converted to a uint8 0-255');
                end
            end
            
        end
        
        function [stimulus,updateSM,resolutionIndex,stimList,LUT,targetPorts,distractorPorts,...
                details,interTrialLuminance,text,indexPulses,imagingTasks] = ...
                calcStim(stimulus,trialManager,allowRepeats,resolutions,displaySize,LUTbits,...
                responsePorts,totalPorts,trialRecords,compiledRecords,arduinoCONN)
            % 1/30/09 - trialRecords now includes THIS trial
            trialManagerClass=class(trialManager);
            s = stimulus;
            indexPulses=[];
            imagingTasks=[];
            %LUT = Screen('LoadCLUT', 0);
            %LUT=LUT/max(LUT(:));
            
            % TODO:  Change this
            % out = 1;
            
            % LUTBitDepth=8;
            % numColors=2^LUTBitDepth; maxColorID=numColors-1; fraction=1/(maxColorID);
            % ramp=[0:fraction:1];
            % LUT= [ramp;ramp;ramp]';
            [LUT stimulus updateSM]=getLUT(stimulus,LUTbits);
            mac = BCoreUtil.getMACaddressSafely;
            switch mac
                case {'A41F7278B4DE','A41F729213E2','A41F726EC11C' } %gLab-Behavior rigs 1,2,3
                    [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
                case {'7845C4256F4C', '7845C42558DF','A41F729211B1'} %gLab-Behavior rigs 4,5,6
                    [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
                otherwise
                    [resolutionIndex height width hz]=chooseLargestResForHzsDepthRatio(resolutions,[60],32,getMaxWidth(stimulus),getMaxHeight(stimulus));
            end
            if isnan(resolutionIndex)
                resolutionIndex=1;
            end
            
            
            % updateSM=0;     % For intertrial dependencies
            % isCorrection=0;     % For correction trials to force to switch sides
            
            scaleFactor = getScaleFactor(stimulus);
            interTrialLuminance = getInterTrialLuminance(stimulus);
            interTrialDuration = getInterTrialDuration(stimulus);
            
            details.pctCorrectionTrials=trialManager.percentCorrectionTrials;
            details.bias = getRequestBias(trialManager);
            
            if ~isempty(trialRecords) && length(trialRecords)>=2
                lastRec=trialRecords(end-1);
            else
                lastRec=[];
            end
            [targetPorts distractorPorts details]=assignPorts(details,lastRec,responsePorts,trialManagerClass,allowRepeats);
            
            if length(targetPorts)==1
                if targetPorts == 1
                    % animal should go left
                    dotDirection = pi
                elseif targetPorts == 3
                    dotDirection = 0
                else
                    error('Zah?  This should never happen!')
                end
                static=false;
                if iscell(s.movie_duration)
                    switch s.movie_duration{2}
                        case 'selectWithin'
                            selectedDuration = s.movie_duration{1}(1) + rand(1)*(s.movie_duration{1}(2)-s.movie_duration{1}(1));
                        case 'selectFrom'
                            selectedDuration = s.movie_duration{1}(randi(length((s.movie_duration{1}))));
                    end
                else
                    if length(s.movie_duration)==2
                        selectedDuration = s.movie_duration(1) + rand(1)*(s.movie_duration(2)-s.movie_duration(1));
                    else
                        selectedDuration = s.movie_duration;
                    end
                end
            else
                % if more than one target port, then we can only have a static image!
                warning('more than one target port found by coherentDots calcStim - calculating a static dots image ONLY!');
                static=true;
                dotDirection=-1;
                selectedDuration=1/hz;
            end
            
            num_frames = floor(hz * selectedDuration);
            
            alldotsxy = [rand(s.num_dots,1)*(s.screen_width-1)+1 ...
                rand(s.num_dots,1)*(s.screen_height-1)+1];
            dot_history = zeros(s.num_dots,2,num_frames);
            
            dots_movie = uint8(zeros(s.screen_height, s.screen_width, num_frames));
            
            % ===================================================================================
            % 11/20/08 - fli
            % do all random picking here (from coherence, size, contrast, speed as necessary)
            %   s.coherence -> selectedCoherence
            %   s.dot_size -> selectedDotSize
            %   s.contrast -> selectedContrast
            %   s.speed -> selectedSpeed
            % coherence
            if iscell(s.coherence)
                switch s.coherence{2}
                    case 'selectWithin'
                        selectedCoherence = s.coherence{1}(1) + rand(1)*(s.coherence{1}(2)-s.coherence{1}(1));
                    case 'selectFrom'
                        selectedCoherence = s.coherence{1}(randi(length((s.coherence{1}))));
                end
            else
                if length(s.coherence)==2
                    selectedCoherence = s.coherence(1) + rand(1)*(s.coherence(2)-s.coherence(1));
                else
                    selectedCoherence = s.coherence;
                end
            end
            
            % dot_size
            if iscell(s.dot_size)
                switch s.dot_size{2}
                    case 'selectWithin'
                        selectedDotSize = s.dot_size{1}(1) + rand(1)*(s.dot_size{1}(2)-s.dot_size{1}(1));
                    case 'selectFrom'
                        selectedDotSize = s.dot_size{1}(randi(length((s.dot_size{1}))));
                end
            else
                if length(s.dot_size)==2
                    selectedDotSize = round(s.dot_size(1) + rand(1)*(s.dot_size(2)-s.dot_size(1)));
                else
                    selectedDotSize = s.dot_size;
                end
            end
            
            % contrast
            if iscell(s.contrast)
                switch s.contrast{2}
                    case 'selectWithin'
                        selectedContrast = s.contrast{1}(1) + rand(1)*(s.contrast{1}(2)-s.contrast{1}(1));
                    case 'selectFrom'
                        selectedContrast = s.contrast{1}(randi(length((s.contrast{1}))));
                end
            else
                if length(s.contrast)==2
                    selectedContrast = s.contrast(1) + rand(1)*(s.contrast(2)-s.contrast(1));
                else
                    selectedContrast = s.contrast;
                end
            end
            
            % speed
            if iscell(s.speed)
                switch s.speed{2}
                    case 'selectWithin'
                        selectedSpeed = s.speed{1}(1) + rand(1)*(s.speed{1}(2)-s.speed{1}(1));
                    case 'selectFrom'
                        selectedSpeed = s.speed{1}(randi(length((s.speed{1}))));
                end
            else
                if length(s.speed)==2
                    selectedSpeed = s.speed(1) + rand(1)*(s.speed(2)-s.speed(1));
                else
                    selectedSpeed = s.speed;
                end
            end
            % ===================================================================================
            %shape = zeros(dot_size,2);
            % Make a square shape
            shape = ones(selectedDotSize);
            
            %% Draw those dots!
            
            frame = zeros(s.screen_height,s.screen_width);
            frame(sub2ind(size(frame),floor(alldotsxy(:,2)),floor(alldotsxy(:,1)))) = 1;
            frame = conv2(frame,shape,'same');
            frame(frame > 0) = 255;
            dot_history(:,:,1) = alldotsxy;
            dots_movie(:,:,1) = uint8(frame);
            % alldotsxy(:,1);
            % alldotsxy(:,2);
            
            if ~static
                
                vx = selectedSpeed*cos(dotDirection);
                vy = selectedSpeed*sin(dotDirection);
                
                for i=1:num_frames
                    frame = zeros(s.screen_height,s.screen_width);
                    try
                        frame(sub2ind(size(frame),ceil(alldotsxy(:,2)),ceil(alldotsxy(:,1)))) = 1;
                    catch
                        min(floor(alldotsxy(:,2)))
                        min(floor(alldotsxy(:,1)))
                        max(floor(alldotsxy(:,2)))
                        max(floor(alldotsxy(:,1)))
                        sca;
                        keyboard
                    end
                    frame = conv2(frame,shape,'same');
                    frame(frame > 0) = 255;
                    dots_movie(:,:,i) = uint8(frame);
                    dot_history(:,:,i) = alldotsxy;
                    
                    % Randomly find who's going to be coherent and who isn't
                    move_coher = rand(s.num_dots,1) < selectedCoherence;
                    move_randomly = ~move_coher;
                    
                    num_out = sum(move_randomly);
                    
                    if (num_out ~= s.num_dots)
                        alldotsxy(move_coher,1) = alldotsxy(move_coher,1) + vx;
                        alldotsxy(move_coher,2) = alldotsxy(move_coher,2) + vy;
                    end
                    if (num_out)
                        alldotsxy(move_randomly,:) = [rand(num_out,1)*(s.screen_width-1)+1 ...
                            rand(num_out,1)*(s.screen_height-1)+1];
                    end
                    
                    % all that are beyond the right
                    overboard = alldotsxy(:,1) > s.screen_width;
                    num_out = sum(overboard);
                    if (num_out)
                        alldotsxy(overboard,1) = alldotsxy(overboard,1)- s.screen_width + 1;
                    end
                    
                    % all that are before the left
                    overboard = alldotsxy(:,1) < 0;
                    num_out = sum(overboard);
                    if (num_out)
                        alldotsxy(overboard,1) = s.screen_width + alldotsxy(overboard,1) ;
                    end
                    
                    % all that are below the bottom
                    overboard = alldotsxy(:,2) > s.screen_height;
                    num_out = sum(overboard);
                    if (num_out)
                        alldotsxy(overboard,2) = alldotsxy(overboard,2)- s.screen_height + 1;
                    end
                    
                    % all that are above the top
                    overboard = floor(alldotsxy(:,2)) <= 0;
                    num_out = sum(overboard);
                    if (num_out)
                        alldotsxy(overboard,2) = s.screen_height + alldotsxy(overboard,2);
                    end
                end
            else
                for i = 1:num_frames
                    dots_movie(:,:,i) = frame;
                end
            end
            
            out = dots_movie*selectedContrast;
            if strcmp(stimulus.replayMode,'loop')
                type='loop';
            elseif strcmp(stimulus.replayMode,'once')
                type='cache';
                out(:,:,end+1)=0;
            else
                error('unknown replayMode');
            end
            
            % details.stimStruct = structize(stimulus);
            details.dotDirection = dotDirection;
            details.dotxy = alldotsxy;
            details.coherence = s.coherence;
            details.dot_size = s.dot_size;
            details.contrast = s.contrast;
            details.speed = s.speed;
            
            details.selectedCoherence = selectedCoherence;
            details.selectedDotSize = selectedDotSize;
            details.selectedContrast = selectedContrast;
            details.selectedSpeed = selectedSpeed;
            details.selectedDuration = selectedDuration;
            
            discrimStim=[];
            discrimStim.stimulus=out;
            discrimStim.stimType=type;
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            discrimStim.autoTrigger=[];
            
            preRequestStim=[];
            preRequestStim.stimulus=interTrialLuminance;
            preRequestStim.stimType='loop';
            preRequestStim.scaleFactor=0;
            preRequestStim.startFrame=0;
            preRequestStim.autoTrigger=[];
            preRequestStim.punishResponses=false;
            
            preResponseStim=discrimStim;
            preResponseStim.punishResponses=false;
            
            postDiscrimStim = [];
            
            interTrialStim.duration = interTrialDuration;
            details.interTrialDuration = interTrialDuration;
            
            if (strcmp(trialManagerClass,'nAFC') || strcmp(trialManagerClass,'goNoGo')) && details.correctionTrial
                text='correction trial!';
            else
                text=sprintf('coherence: %g dot_size: %g contrast: %g speed: %g',selectedCoherence,selectedDotSize,selectedContrast,selectedSpeed);
            end
        end
        
        function d=display(s)
            d=['coherentDots (n target, m distractor gabors, randomized phase, equal spatial frequency, p>=n+m horiz positions)\n'...
                '\t\t\tpixPerCycs:\t[' num2str(1) ...
                ']\n\t\t\ttarget orientations:\t[' num2str(1) ...
                ']\n\t\t\tdistractor orientations:\t[' num2str(1) ...
                ']\n\t\t\tmean:\t' num2str(1) ...
                '\n\t\t\tradius:\t' num2str(1) ...
                '\n\t\t\tcontrast:\t' num2str(1) ...
                '\n\t\t\tthresh:\t' num2str(1) ...
                '\n\t\t\tpct from top:\t' num2str(1)];
            d=sprintf(d);
            
            %%% TODO:  change this
            %%% num2str(s.pixPerCycs)
        end
        
        function [out scale] = errorStim(stimManager,numFrames)
            scale=0;
            
            out = uint8(zeros(1,1,numFrames));
        end
        
        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            newLUT=LUTparams.compiledLUT;
            
            nAFCindex = find(strcmp(LUTparams.compiledLUT,'nAFC'));
            if ~isempty(nAFCindex) && ~all([basicRecords.trialManagerClass]==nAFCindex)
                warning('only works for nAFC trial manager')
                out=struct;
            else
                
                try
                    stimDetails=[trialRecords.stimDetails];
                    [out.correctionTrial newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                    [out.pctCorrectionTrials newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                    [out.dotDirection newLUT] = extractFieldAndEnsure(stimDetails,{'dotDirection'},'scalar',newLUT);
                    [out.coherence newLUT] = extractFieldAndEnsure(stimDetails,{'coherence'},'equalLengthVects',newLUT);
                    [out.dot_size newLUT] = extractFieldAndEnsure(stimDetails,{'dot_size'},'equalLengthVects',newLUT);
                    [out.contrast newLUT] = extractFieldAndEnsure(stimDetails,{'contrast'},'equalLengthVects',newLUT);
                    [out.speed newLUT] = extractFieldAndEnsure(stimDetails,{'speed'},'equalLengthVects',newLUT);
                    
                    [out.selectedCoherence newLUT] = extractFieldAndEnsure(stimDetails,{'selectedCoherence'},'scalar',newLUT);
                    [out.selectedDotSize newLUT] = extractFieldAndEnsure(stimDetails,{'selectedDotSize'},'scalar',newLUT);
                    [out.selectedContrast newLUT] = extractFieldAndEnsure(stimDetails,{'selectedContrast'},'scalar',newLUT);
                    [out.selectedSpeed newLUT] = extractFieldAndEnsure(stimDetails,{'selectedSpeed'},'scalar',newLUT);
                    [out.selectedDuration newLUT] = extractFieldAndEnsure(stimDetails,{'selectedDuration'},'scalar',newLUT);
                    
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
        
        function s=fillLUT(s,method,linearizedRange,plotOn);
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
                    
                case 'localCalibStore'
                    try
                        temp = load(fullfile(getBCorePath,'monitorCalibration','tempCLUT.mat'));
                        uncorrected = temp.linearizedCLUT;
                        useUncorrected=1;
                    catch ex
                        disp('did you store local calibration details at all????');
                        rethrow(ex)
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
                [linearizedCLUT(:,1) g.R]=fitGammaAndReturnLinearized(sent, measured_R, linearizedRange, sensorRange, gamutRange, 2^LUTBitDepth,plotOn);
                
                if plotOn
                    subplot([312]);
                end
                [linearizedCLUT(:,2) g.G]=fitGammaAndReturnLinearized(sent, measured_G, linearizedRange, sensorRange, gamutRange, 2^LUTBitDepth,plotOn);
                
                if plotOn
                    subplot([313]);
                end
                [linearizedCLUT(:,3) g.B]=fitGammaAndReturnLinearized(sent, measured_B, linearizedRange, sensorRange, gamutRange, 2^LUTBitDepth,plotOn);
            end
            
            s.LUT=linearizedCLUT;
        end
        
        function s=flushLUT(s)
            %method to flush the look up table, see fillLUT
            
            s.LUT=[];
            s.LUTbits=0;
        end
        
        function [out s updateSM]=getLUT(s,bits)
            if isempty(s.LUT) || s.LUTbits~=bits
                updateSM=true;
                s.LUTbits=bits;
                %     s=fillLUT(s,'useThisMonitorsUncorrectedGamma');
                % s=fillLUT(s,'linearizedDefault',[0 1],false);
                %     s=fillLUT(s,'hardwiredLinear',[0 1],false);
                s=fillLUT(s,'localCalibStore',[0 1],false);
                
            else
                updateSM=false;
            end
            out=s.LUT;
        end
        
        function out=stimMgrOKForTrialMgr(sm,tm)
            if isa(tm,'trialManager')
                switch class(tm)
                    case 'freeDrinks'
                        out=1;
                    case 'nAFC'
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

