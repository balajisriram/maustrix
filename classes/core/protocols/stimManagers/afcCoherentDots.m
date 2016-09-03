classdef afcCoherentDots<stimManager
    
    properties
        numDots = {100,100};                      % Number of dots to display
        bkgdNumDots = {0,0};                      % task irrelevant dots
        dotCoherence = {0.8, 0.8};                % Percent of dots to move in a specified direction
        bkgdCoherence = {0.8, 0.8};               % percent of bkgs dots moving in the specified direction
        dotSpeed = {1,1};                         % How fast do our little dots move (dotSize/sec)
        bkgdSpeed = {0.1,0.1};                    % speed of bkgd dots
        dotDirection = {[0],[pi]};                % 0 is to the right. pi is to the left
        bkgdDirection = {[0],[pi]};               % 0 is to the right. pi is to the left
        dotColor = {0,0};                         % can be a single number< 1 (used as a gray scale value); a single row of 3/4 (RGB/RGBA) ; or many rows o4 the above number sets in which case randomly chosen
        bkgdDotColor = {0,0};                     % can be a single number< 1 (used as a gray scale value); a single row of 3/4 (RGB/RGBA) ; or many rows o4 the above number sets in which case randomly chosen
        dotSize = {[9],[9]};                      % Width of dots in pixels
        bkgdSize = {[3],[3]};                     % Width in pixels
        dotShape = {{'circle'},{'circle'}};       % 'circle' or 'rectangle'
        bkgdShape = {{'rectangle'},{'rectangle'}};% 'circle' or 'rectangle'
        renderMode = {'flat'};                    % {'flat'} or {'perspective',[renderDistances]}
        renderDistance = NaN;                     % is 1 for flat and is a range for perspective
        maxDuration = {inf, inf};                 % in seconds (inf is until response)
        background = 0;                           % black background
        
        LUT =[];
        LUTbits = 0;
        doCombos=true;
        ordering;
        doPostDiscrim = false;
        
        LEDParams;
    end
    
    methods
        function s=afcCoherentDots(numDots,bkgdNumDots, dotCoherence,bkgdCoherence, dotSpeed,bkgdSpeed, dotDirection,bkgdDirection,...
                dotColor,bkgdDotColor, dotSize,bkgdSize, dotShape,bkgdShape, renderMode, maxDuration,background,...
                maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos, doPostDiscrim)
            % AFCCOHERENTDOTS  class constructor.
            % this class is specifically designed for behavior.
            % s = afcCoherentDots(numDots,bkgdNumDots, dotCoherence,bkgdCoherence, dotSpeed,bkgdSpeed, dotDirection,bkgdDirection,...
            %       dotColor,bkgdColor, dotSize,bkgdSize, dotShape,bkgdShape, renderMode, maxDuration,background...
            %       maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos, doPostDiscrim, LEDParams)
            %   numDots - number of dots to draw
            %   coherence - an array of numeric values >0 and <1
            %   speed - an array of positive numbers in units of dotSize/second
            %   direction - the direction the coheret dots move it. non coherent dots
            %         will do some kind of jiggle in all directions
            %   color - can be a single number< 1 (used as a gray scale value); a single row of 3/4 (RGB/RGBA) ; or many rows o4 the above number sets in which case randomly chosen
            %   dotSize - size in pixels of each dot (square)
            %   dotShape - 'circle or 'rectangle'
            %   renderMode - 'perspective' or 'flat'
            %   maxDuration - length of the movie in seconds. particularly useful for
            %          stimli with specific time....
            %   screenZoom - scaleFactor argument passed to stimManager constructor
            %   interTrialLuminance - (optional) defaults to 0
            %   doCombos - whether to do combos or not...
            
            s=s@stimManager(maxWidth, maxHeight, scaleFactor, interTrialLuminance);
            
            eps = 0.0000001;
            s.ordering.method = 'twister';
            s.ordering.seed = [];
            s.LEDParams.active = false;
            s.LEDParams.numLEDs = 0;
            s.LEDParams.IlluminationModes = {};
            
            
            % create object using specified values
            
            % doCombos
            validateattributes(doCombos,{'logical','cell'},{'nonempty'}); % either true or {true,{'twister',seed#}};
            switch class(doCombos)
                case 'logical'
                    s.doCombos = doCombos;
                case 'cell'
                    s.doCombos = doCombos{1};
                    s.ordering.method = doCombos{2}{1};
                    s.ordering.seed = doCombos{2}{2};
            end
            %% numDots
            % numDots
            assert(iscell(numDots) && length(numDots)==2 && isnumeric(numDots{1}) && all(numDots{1}>=0) && isnumeric(numDots{2}) && all(numDots{2}>=0),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','numDots not in the right format');
            s.numDots = numDots;
            L1 = length(numDots{1});
            L2 = length(numDots{2});

            % bkgdNumDots
            assert(iscell(bkgdNumDots) && length(bkgdNumDots)==2 && isnumeric(bkgdNumDots{1}) && all(bkgdNumDots{1}>=0) && isnumeric(bkgdNumDots{2}) && all(bkgdNumDots{2}>=0),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','bkgdNumDots not in the right format');
            assert(doCombos || length(bkgdNumDots{1})==L1 && length(bkgdNumDots{2})==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.bkgdNumDots = bkgdNumDots;
            
            %% coherence
            % dotCoherence
            assert(iscell(dotCoherence) && length(dotCoherence)==2 && ...
                isnumeric(dotCoherence{1}) && all(dotCoherence{1}>=0) && all(dotCoherence{1}<=1) && ...
                    isnumeric(dotCoherence{2}) && all(dotCoherence{2}>=0) && all(dotCoherence{2}<=1),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','dotCoherence not in the right format');
            assert(doCombos || length(dotCoherence{1})==L1 && length(dotCoherence{2})==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.dotCoherence = dotCoherence;
            
            % bkgdCoherence
            assert(iscell(bkgdCoherence) && length(bkgdCoherence)==2 && ...
                isnumeric(bkgdCoherence{1}) && all(bkgdCoherence{1}>=0) && all(bkgdCoherence{1}<=1) && ...
                    isnumeric(bkgdCoherence{2}) && all(bkgdCoherence{2}>=0) && all(bkgdCoherence{2}<=1),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','bkgdCoherence not in the right format');
            assert(doCombos || length(bkgdCoherence{1})==L1 && length(bkgdCoherence{2})==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.bkgdCoherence = bkgdCoherence;
            
            %% speed
            % dotSpeed
            assert(iscell(dotSpeed) && length(dotSpeed)==2 && ...
                    isnumeric(dotSpeed{1}) && all(dotSpeed{1}>=0) && ...
                    isnumeric(dotSpeed{2}) && all(dotSpeed{2}>=0),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','dotSpeed not in the right format');
            assert(doCombos || length(dotSpeed{1})==L1 && length(dotSpeed{2})==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.dotSpeed = dotSpeed;
            
            % bkgdSpeed
            assert(iscell(bkgdSpeed) && length(bkgdSpeed)==2 && ...
                    isnumeric(bkgdSpeed{1}) && all(bkgdSpeed{1}>=0) && ...
                    isnumeric(bkgdSpeed{2}) && all(bkgdSpeed{2}>=0),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','bkgdSpeed not in the right format');
            assert(doCombos || length(bkgdSpeed{1})==L1 && length(bkgdSpeed{2})==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.bkgdSpeed = bkgdSpeed;
            
            %% direction
            % dotDirection
            assert(iscell(dotDirection) && length(dotDirection)==2 && ...
                    isnumeric(dotDirection{1}) && ...
                    isnumeric(dotDirection{2}),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','dotDirection not in the right format');
            assert(doCombos || length(dotDirection{1})==L1 && length(dotDirection{2})==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.dotDirection = dotDirection;
            
            % bkgdDirection
            assert(iscell(bkgdDirection) && length(bkgdDirection)==2 && ...
                    isnumeric(bkgdDirection{1}) && ...
                    isnumeric(bkgdDirection{2}),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','bkgdDirection not in the right format');
            assert(doCombos || length(bkgdDirection{1})==L1 && length(bkgdDirection{2})==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.bkgdDirection = bkgdDirection;
            
            %% color
            % dotColor
            assert(iscell(dotColor) && length(dotColor)==2 && ...
                isnumeric(dotColor{1}) &&  length(size(dotColor{1}))<=2 && ... % a 2-D array
                all(all(dotColor{1}>=0)) && all(all(dotColor{1}<=1)) && ... % of the right values
                ismember(size(dotColor{1},2),[1,3,4]) && ...  % and the right size (a column of gray values, a column of RGB values or a column of RGBA values)
                isnumeric(dotColor{2}) &&  length(size(dotColor{2}))<=2 && ... % a 2-D array
                all(all(dotColor{2}>=0)) && all(all(dotColor{2}<=1)) && ... % of the right values
                ismember(size(dotColor{2},2),[1,3,4]),... % and the right size (a column of gray values, a column of RGB values or a column of RGBA values)
                'afcCoherentDots:afcCoherentDots:incorrectValue','dotColor not in right format');
            assert(doCombos || size(dotColor{1},1)==L1 && size(dotColor{2},1)==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.dotColor = dotColor;
            
            
            % bkgdDotColor
            assert(iscell(bkgdDotColor) && length(bkgdDotColor)==2 && ...
                isnumeric(bkgdDotColor{1}) &&  length(size(bkgdDotColor{1}))<=2 && ... % a 2-D array
                all(all(bkgdDotColor{1}>=0)) && all(all(bkgdDotColor{1}<=1)) && ... % of the right values
                ismember(size(bkgdDotColor{1},2),[1,3,4]) && ...  % and the right size (a column of gray values, a column of RGB values or a column of RGBA values)
                isnumeric(bkgdDotColor{2}) &&  length(size(bkgdDotColor{2}))<=2 && ... % a 2-D array
                all(all(bkgdDotColor{2}>=0)) && all(all(bkgdDotColor{2}<=1)) && ... % of the right values
                ismember(size(bkgdDotColor{2},2),[1,3,4]),... % and the right size (a column of gray values, a column of RGB values or a column of RGBA values)
                'afcCoherentDots:afcCoherentDots:incorrectValue','bkgdColor not in right format');
            assert(doCombos || size(bkgdDotColor{1},1)==L1 && size(bkgdDotColor{2},1)==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.bkgdDotColor = bkgdDotColor;
            
            %% size
            % dotSize
            assert(iscell(dotSize) && length(dotSize)==2 && ...
                isnumeric(dotSize{1}) && all(dotSize{1}>0) && ...
                isnumeric(dotSize{2}) && all(dotSize{2}>0),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','dotSize not in the right format'); 
            assert(doCombos || length(dotSize{1})==L1 && length(dotSize{2})==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.dotSize = dotSize;
            
            % bkgdSize
            assert(iscell(bkgdSize) && length(bkgdSize)==2 && ...
                isnumeric(bkgdSize{1}) && all(bkgdSize{1}>0) && ...
                isnumeric(bkgdSize{2}) && all(bkgdSize{2}>0),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','bkgdSize not in the right format'); 
            assert(doCombos || length(bkgdSize{1})==L1 && length(bkgdSize{2})==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.bkgdSize = bkgdSize;
            
            %% shape
            % dotShape
            assert(iscell(dotShape) && length(dotShape)==2 && ...
                iscell(dotShape{1}) && all(ismember(dotShape{1}, {'circle','square'})) && ...
                iscell(dotShape{2}) && all(ismember(dotShape{2}, {'circle','square'})),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','dotShape not in the right format');
            assert(doCombos || length(dotShape{1})==L1 && length(dotShape{2})==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.dotShape = dotShape;
            
            % bkgdShape
            assert(iscell(bkgdShape) && length(bkgdShape)==2 && ...
                iscell(bkgdShape{1}) && all(ismember(bkgdShape{1}, {'circle','square'})) && ...
                iscell(bkgdShape{2}) && all(ismember(bkgdShape{2}, {'circle','square'})),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','bkgdShape not in the right format');
            assert(doCombos || length(bkgdShape{1})==L1 && length(bkgdShape{2})==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.bkgdShape = bkgdShape;
            %% other
            % renderMode
            assert(iscell(renderMode) && ischar(renderMode{1}) && ismember(renderMode{1},{'flat','perspective'}),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','renderMode not in the right format');
            s.renderMode = renderMode{1};
            switch renderMode{1}
                case 'flat'
                    s.renderDistance = NaN;
                case 'perspective'
                    assert(length(renderMode)==2 && isnumeric(renderMode{2}) && length(renderMode{2})==2 && all(renderMode{2}>0),...
                        'afcCoherentDots:afcCoherentDots:incorrectValue','for ''perspective'', renderMode{2} should be a 2 numeric positive number');
                    s.renderDistance = renderMode{2};
            end
            
            % maxDuration
            assert(iscell(maxDuration) && length(maxDuration)==2 && ...
                isnumeric(maxDuration{1}) && all(maxDuration{1}>0) && ...
                isnumeric(maxDuration{2}) && all(maxDuration{2}>0),...
                'afcCoherentDots:afcCoherentDots:incorrectValue','maxDuration not in the right format');
            assert(doCombos || length(maxDuration{1})==L1 && length(maxDuration{2})==L2,'afcCoherentDots:afcCoherentDots:incompatibleValues','the lengths don''t match.');
            s.maxDuration = maxDuration;
            
            % background
            assert(isnumeric(background),'afcCoherentDots:afcCoherentDots:incorrectValue','background not in the right format');
            s.background = background;
            
            
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
            
            if nargin==24
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
            end
            
        end

        function [sm,updateSM,resInd,stimList,LUT,targetPorts,distractorPorts,details,text,indexPulses,imagingTasks,ITL] =...
                calcStim(sm,tm,st,tR,~) % cR not used
            
            resolutions = st.resolutions;
            displaySize = st.getDisplaySize();
            LUTbits = st.getLUTbits();
            responsePorts = tm.getResponsePorts(st.numPorts);
            
            indexPulses=[];
            imagingTasks=[];
            [LUT, sm, updateSM]=getLUT(sm,LUTbits);
            
            [resInd, height, width, hz] = st.chooseLargestResForHzsDepthRatio(resolutions,[60],32,sm.maxWidth,sm.maxHeight);
            
            if isnan(resInd)
                resInd=1;
            end
            
            scaleFactor=sm.scaleFactor; % dummy value since we are phased anyways; the real scaleFactor is stored in each phase's stimSpec
            
            
            details.pctCorrectionTrials=tm.percentCorrectionTrials;
            if ~isempty(tR) && length(tR)>=2
                lastRec=tR(end-1);
            else
                lastRec=[];
            end
            [targetPorts, distractorPorts, details]=tm.assignPorts(details,lastRec,responsePorts);
            
            
            type='expert';
            
            % set up params for computeGabors
            height = min(height,sm.maxHeight);
            width = min(width,sm.maxWidth);
            
            % lets save some of the details for later
            details.afcCoherentDotsType  = sm.getType(structize(sm));
            
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
            stim.rngMethod = sm.ordering.method;
            if isempty(sm.ordering.seed)
                stim.seedVal = sum(100*clock);
            end
            
            switch sm.doCombos
                case true
                    stim.numDots        = chooseFrom(sm.numDots{chosenStimIndex});
                    stim.bkgdNumDots    = chooseFrom(sm.bkgdNumDots{chosenStimIndex});
                    stim.dotCoherence   = chooseFrom(sm.dotCoherence{chosenStimIndex});
                    stim.bkgdCoherence  = chooseFrom(sm.bkgdCoherence{chosenStimIndex});
                    stim.dotSpeed       = chooseFrom(sm.dotSpeed{chosenStimIndex});
                    stim.bkgdSpeed      = chooseFrom(sm.bkgdSpeed{chosenStimIndex});
                    stim.dotDirection   = chooseFrom(sm.dotDirection{chosenStimIndex});
                    stim.bkgdDirection  = chooseFrom(sm.bkgdDirection{chosenStimIndex});
                    stim.dotColor       = chooseFrom(sm.dotColor{chosenStimIndex});
                    stim.bkgdDotColor   = chooseFrom(sm.bkgdDotColor{chosenStimIndex});
                    stim.dotSize        = chooseFrom(sm.dotSize{chosenStimIndex});
                    stim.bkgdSize       = chooseFrom(sm.bkgdSize{chosenStimIndex});
                    stim.dotShape       = chooseFrom(sm.dotShape{chosenStimIndex});
                    stim.bkgdShape      = chooseFrom(sm.bkgdShape{chosenStimIndex});
                    stim.maxDuration    = round(chooseFrom(sm.maxDuration{chosenStimIndex})*hz);

                    stim.renderMode = sm.renderMode;
                    stim.background = sm.background;
                    stim.doCombos = sm.doCombos;
                case false
                    % numDots
                    tempVar = randperm(length(sm.numDots{chosenStimIndex}));
                    which = tempVar(1);
                    
                    stim.numDots = sm.numDots{chosenStimIndex}(which);
                    stim.bkgdNumDots = sm.bkgdNumDots{chosenStimIndex}(which);
                    stim.dotCoherence = sm.dotCoherence{chosenStimIndex}(which);
                    stim.bkgdCoherence = sm.bkgdCoherence{chosenStimIndex}(which);
                    stim.dotSpeed = sm.dotSpeed{chosenStimIndex}(which);
                    stim.bkgdSpeed = sm.bkgdSpeed{chosenStimIndex}(which);
                    stim.dotDirection = sm.dotDirection{chosenStimIndex}(which);
                    stim.bkgdDirection = sm.bkgdDirection{chosenStimIndex}(which);
                    stim.dotColor = sm.dotColor{chosenStimIndex}(which,:);
                    stim.bkgdDotColor = sm.bkgdDotColor{chosenStimIndex}(which,:);
                    stim.dotSize = sm.dotSize{chosenStimIndex}(which);
                    stim.bkgdSize = sm.bkgdSize{chosenStimIndex}(which);
                    stim.dotShape = sm.dotShape{chosenStimIndex}(which);
                    stim.bkgdShape = sm.bkgdShape{chosenStimIndex}(which);
                    stim.maxDuration = round(sm.maxDuration{chosenStimIndex}(which)*hz);
                    
                    stim.renderMode = sm.renderMode;
                    stim.background = sm.background;
                    stim.doCombos = sm.doCombos;
            end
            
            
            % have a version in ''details''
            details.doCombos       = sm.doCombos;
            details.numDots        = stim.numDots;
            details.bkgdNumDots    = stim.bkgdNumDots;
            details.dotCoherence   = stim.dotCoherence;
            details.bkgdCoherence  = stim.bkgdCoherence;
            details.dotSpeed       = stim.dotSpeed;
            details.bkgdSpeed      = stim.bkgdSpeed;
            details.dotDirection   = stim.dotDirection;
            details.bkgdDirection  = stim.bkgdDirection;
            details.dotColor       = stim.dotColor;
            details.bkgdDotColor   = stim.bkgdDotColor;
            details.dotSize        = stim.dotSize;
            details.bkgdSize       = stim.bkgdSize;
            details.dotShape       = stim.dotShape;
            details.bkgdShape      = stim.bkgdShape;
            details.renderMode     = stim.renderMode;
            details.maxDuration    = stim.maxDuration;
            details.background     = stim.background;
            details.rngMethod      = stim.rngMethod;
            details.seedVal        = stim.seedVal;
            details.height         = stim.height;
            details.width          = stim.width;
            
            
            if isinf(stim.maxDuration)
                timeout=inf;
            else
                timeout=stim.maxDuration;
            end
            
            switch stim.renderMode
                case 'perspective'
                    % lets make the render distances work here
                    stim.dotsRenderDistance = sm.renderDistance(1) + rand(stim.numDots,1)*(sm.renderDistance(2) - sm.renderDistance(1));
                    stim.bkgdRenderDistance = sm.renderDistance(1) + rand(stim.bkgdNumDots,1)*(sm.renderDistance(2) - sm.renderDistance(1));
                    
                    details.dotsRenderDistance = stim.dotsRenderDistance;
                    details.bkgdRenderDistance = stim.bkgdRenderDistance;
                case 'flat'
                    % lets make the render distances work here
                    stim.dotsRenderDistance = ones(stim.numDots,1);
                    stim.bkgdRenderDistance = ones(stim.bkgdNumDots,1);
                    
                    details.dotsRenderDistance = stim.dotsRenderDistance;
                    details.bkgdRenderDistance = stim.bkgdRenderDistance;
            end
            
            % LEDParams
%            [details, stim] = setupLED(details, stim, sm.LEDParams,arduinoCONN);
            
            
            discrimStim=[];
            discrimStim.stimulus=stim;
            discrimStim.stimType=type;
            discrimStim.scaleFactor=scaleFactor;
            discrimStim.startFrame=0;
            discrimStim.autoTrigger=[];
            discrimStim.punishResponses=false;
            discrimStim.framesUntilTimeout=timeout;
            discrimStim.ledON = false; %% #### presetting here
            
            preRequestStim=[];
            preRequestStim.stimulus=sm.interTrialLuminance;
            preRequestStim.stimType='loop';
            preRequestStim.scaleFactor=0;
            preRequestStim.startFrame=0;
            preRequestStim.autoTrigger=[];
            preRequestStim.punishResponses=false;
            preRequestStim.ledON = false; %% presetting here
            
           
            if sm.doPostDiscrim
                postDiscrimStim = preRequestStim;
            else
                postDiscrimStim = [];
            end
            
           
            interTrialStim.interTrialLuminance = sm.interTrialLuminance;            
            interTrialStim.duration = sm.interTrialDuration;
            ITL = sm.interTrialLuminance();
            
            details.interTrialDuration = sm.interTrialDuration;
            details.stimManagerClass = class(sm);
            details.trialManagerClass = class(tm);
            details.scaleFactor = scaleFactor;
            
            if strcmp(class(tm),'nAFC') && details.correctionTrial
                text='correction trial!';
            else
                text=sprintf('coh: %g',stim.dotCoherence);
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
            
            % expertCache will have the current state of the system
            if isempty(expertCache)
                expertCache.previousXYDots=[];
                expertCache.previousXYBkgd=[];
                expertCache.nextVelDots=[];
                expertCache.nextVelBkgd=[];
            end
            
            black=0.0;
            white=1.0;
            gray = (white-black)/2;
            
            try
                if i ==1
                    % for the first frame we will set nextVel to 0
                    expertCache.nextVelDots=zeros(stim.numDots,2);
                    expertCache.nextVelBkgd=zeros(stim.bkgdNumDots,2);
                    
                    % save current state
                    try
                        prevState = rng;
                    catch
                        prevState = rand('seed');
                    end
                    % seed the random number generator with available values (peppered with
                    % the current frame number
                    try
                        rng(stim.seedVal,stim.rngMethod);
                    catch
                        rand('seed',stim.seedVal);
                    end
                    
                    
                    currentXYDots = rand(stim.numDots,2).*repmat([stim.width,stim.height],stim.numDots,1);
                    currentXYBkgd = rand(stim.bkgdNumDots,2).*repmat([stim.width,stim.height],stim.bkgdNumDots,1);
                    
                    expertCache.previousXYDots=currentXYDots;
                    expertCache.previousXYBkgd=currentXYBkgd;
                    
                    try
                        rng(prevState);
                    catch
                        rand('seed',prevState);
                    end
                end
                
                % get previous positions. this is same as the random positions chosen for
                % the first frame
                oldXYDots=expertCache.previousXYDots;
                oldXYBkgd=expertCache.previousXYBkgd;
                
                % get velocities calculated from previous frame. no change in velocity for
                % first frame
                currentXYDots=oldXYDots+expertCache.nextVelDots;
                currentXYBkgd=oldXYBkgd+expertCache.nextVelBkgd;
                
                % there needs to be code here that checks for out of boundedness
                dotsX = currentXYDots(:,1);
                dotsY = currentXYDots(:,2);
                currentXYDots((dotsX<0),1) = dotsX(dotsX<0)+stim.width;
                currentXYDots((dotsX>stim.width),1) = dotsX(dotsX>stim.width)-stim.width;
                currentXYDots((dotsY<0),2) = dotsY(dotsY<0)+stim.height;
                currentXYDots((dotsY>stim.height),1) = dotsY(dotsY>stim.height)-stim.height;
                
                
                bkgdX = currentXYBkgd(:,1);
                bkgdY = currentXYBkgd(:,2);
                currentXYBkgd((bkgdX<0),1) = bkgdX(bkgdX<0)+stim.width;
                currentXYBkgd((bkgdX>stim.width),1) = bkgdX(bkgdX>stim.width)-stim.width;
                currentXYBkgd((bkgdY<0),2) = bkgdY(bkgdY<0)+stim.height;
                currentXYBkgd((bkgdY>stim.height),1) = bkgdY(bkgdY>stim.height)-stim.height;
                
                % find dotSize from stim.dotsRenderDistance and stim.bkdgRenderDistance
                dotSize = stim.dotSize./stim.dotsRenderDistance;
                bkgdSize = stim.bkgdSize./stim.bkgdRenderDistance;
                
                % find dotColor
                dotColor = repmat(stim.dotColor,stim.numDots,3);
                bkgdColor = repmat(stim.bkgdDotColor, stim.bkgdNumDots,3);
                
                % fill up the background to start with
                Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                Screen('FillRect', window,255*stim.background);
                % now the background dots
                hasBkgd = ~isempty(currentXYBkgd);
                if hasBkgd
                    Screen('DrawDots',window,currentXYBkgd',bkgdSize',255*bkgdColor');
                end
                % and the actual dots
                Screen('DrawDots',window,currentXYDots',dotSize',255*dotColor');
                
                % good now these positions go into the expertCache
                expertCache.previousXYDots = currentXYDots;
                expertCache.previousXYBkgd = currentXYBkgd;
                
                % done with the drawing for this frame - we need to worry about drawing the
                % next frame now
                
                % figure out the speeds of the individual dots
                dotSpeed = stim.dotSpeed./stim.dotsRenderDistance; % units of dotSize/sec
                bkgdSpeed = stim.bkgdSpeed./stim.bkgdRenderDistance; % units of bkgdSize/sec
                
                % choose the coherent ones
                try
                    prevState = rng;
                    rng(stim.seedVal+i,stim.rngMethod);
                catch
                    prevState = rand('seed');
                    rand('seed',stim.seedVal+i);
                end
                whichCoherentDots = rand(stim.numDots,1)<stim.dotCoherence;
                whichCoherentBkgd = rand(stim.bkgdNumDots,1)<stim.bkgdCoherence;
                try
                    rng(prevState);
                catch
                    rand('seed',prevState);
                end
                % choose the chosen stim angle for the coherentOnes
                dotDirection = stim.dotDirection.*double(whichCoherentDots);
                bkgdDirection = stim.bkgdDirection.*double(whichCoherentBkgd);
                
                % get the x and y velocities by doing the trigonometric transformations
                expertCache.nextVelDots = [dotSpeed.*cos(dotDirection) -dotSpeed.*sin(dotDirection)]*stim.dotSize*ifi;
                expertCache.nextVelBkgd = [bkgdSpeed.*cos(bkgdDirection) -bkgdSpeed.*sin(bkgdDirection)]*stim.bkgdSize*ifi;
                
                % for the non coherent ones, set velocity to zero. set position to random
                expertCache.nextVelDots(~whichCoherentDots,:) = repmat([0 0],sum(double(~whichCoherentDots)),1);
                expertCache.nextVelBkgd(~whichCoherentBkgd,:) = repmat([0 0],sum(double(~whichCoherentBkgd)),1);
                expertCache.previousXYDots(~whichCoherentDots,:) = repmat([0 0],sum(double(~whichCoherentDots)),1);
                expertCache.previousXYBkgd(~whichCoherentBkgd,:) = repmat([0 0],sum(double(~whichCoherentBkgd)),1);
                expertCache.previousXYDots = expertCache.previousXYDots + rand(stim.numDots,2).*repmat([stim.width,stim.height],stim.numDots,1).*double([~whichCoherentDots ~whichCoherentDots]);
                expertCache.previousXYBkgd = expertCache.previousXYBkgd + rand(stim.bkgdNumDots,2).*repmat([stim.width,stim.height],stim.bkgdNumDots,1).*double([~whichCoherentBkgd ~whichCoherentBkgd]);
                
            catch ex
                getReport(ex)
                sca;
                keyboard
            end
            
        end % end function
        
        function [out, newLUT]=extractDetailFields(sm,~,trialRecords,LUTparams)
            newLUT=LUTparams.compiledLUT;
            
            try
                stimDetails=[trialRecords.stimDetails];
                [out.correctionTrial, newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                [out.pctCorrectionTrials, newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                [out.doCombos, newLUT] = extractFieldAndEnsure(stimDetails,{'doCombos'},'scalar',newLUT);
                
                [out.numDots, newLUT] = extractFieldAndEnsure(stimDetails,{'numDots'},'scalar',newLUT);
                [out.bkgdNumDots, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdNumDots'},'scalar',newLUT);
                
                [out.dotCoherence, newLUT] = extractFieldAndEnsure(stimDetails,{'dotCoherence'},'scalar',newLUT);
                [out.bkgdCoherence, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdCoherence'},'scalar',newLUT);
                
                [out.dotSpeed, newLUT] = extractFieldAndEnsure(stimDetails,{'dotSpeed'},'scalar',newLUT);
                [out.bkgdSpeed, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdSpeed'},'scalar',newLUT);
                
                [out.dotDirection, newLUT] = extractFieldAndEnsure(stimDetails,{'dotDirection'},'scalar',newLUT);
                [out.bkgdDirection, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdDirection'},'scalar',newLUT);
                
                [out.dotColor, newLUT] = extractFieldAndEnsure(stimDetails,{'dotColor'},'equalLengthVects',newLUT);
                [out.bkgdDotColor, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdDotColor'},'equalLengthVects',newLUT);
                
                [out.dotSize, newLUT] = extractFieldAndEnsure(stimDetails,{'dotSize'},'scalar',newLUT);
                [out.bkgdSize, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdSize'},'scalar',newLUT);
                
                [out.dotShape, newLUT] = extractFieldAndEnsure(stimDetails,{'dotShape'},'scalarLUT',newLUT);
                [out.bkgdShape, newLUT] = extractFieldAndEnsure(stimDetails,{'bkgdShape'},'scalarLUT',newLUT);
                
                [out.maxDuration, newLUT] = extractFieldAndEnsure(stimDetails,{'maxDuration'},'scalar',newLUT);
                [out.background, newLUT] = extractFieldAndEnsure(stimDetails,{'background'},'scalar',newLUT);
                
                [out.height, newLUT] = extractFieldAndEnsure(stimDetails,{'height'},'scalar',newLUT);
                [out.width, newLUT] = extractFieldAndEnsure(stimDetails,{'width'},'scalar',newLUT);
                
                [out.seedVal, newLUT] = extractFieldAndEnsure(stimDetails,{'seedVal'},'scalar',newLUT);
                
                [out.rngMethod, newLUT] = extractFieldAndEnsure(stimDetails,{'rngMethod'},'scalarLUT',newLUT);
                
                [out.renderMode, newLUT] = extractFieldAndEnsure(stimDetails,{'renderMode'},'scalarLUT',newLUT);
                
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
                    [out.correctionTrial, newLUT] = extractFieldAndEnsure(stimDetails,{'correctionTrial'},'scalar',newLUT);
                    [out.pctCorrectionTrials, newLUT] = extractFieldAndEnsure(stimDetails,{'pctCorrectionTrials'},'scalar',newLUT);
                    [out.doCombos, newLUT] = extractFieldAndEnsure(stimDetails,{'doCombos'},'scalar',newLUT);
                    
                    [out.pixPerCycsCenter, newLUT] = extractFieldAndEnsure(stimDetails,{'pixPerCycs'},'scalar',newLUT);
                    [out.driftfrequenciesCenter, newLUT] = extractFieldAndEnsure(stimDetails,{'driftfrequencies'},'scalar',newLUT);
                    [out.orientationsCenter, newLUT] = extractFieldAndEnsure(stimDetails,{'orientations'},'scalar',newLUT);
                    [out.phasesCenter, newLUT] = extractFieldAndEnsure(stimDetails,{'phases'},'scalar',newLUT);
                    [out.contrastsCenter, newLUT] = extractFieldAndEnsure(stimDetails,{'contrasts'},'scalar',newLUT);
                    [out.radiiCenter, newLUT] = extractFieldAndEnsure(stimDetails,{'radii'},'scalar',newLUT);
                    
                    [out.maxDuration, newLUT] = extractFieldAndEnsure(stimDetails,{'maxDuration'},'scalar',newLUT);
                    [out.afcGratingType, newLUT] = extractFieldAndEnsure(stimDetails,{'afcGratingType'},'scalarLUT',newLUT);
                else
                    out=handleExtractDetailFieldsException(sm,ex,trialRecords);
                    verifyAllFieldsNCols(out,length(trialRecords));
                    return
                end
            end
            
            verifyAllFieldsNCols(out,length(trialRecords));
        end
        
        function out = getType(sm,stim)
            sweptParameters = sm.getDetails('sweptParameters');
            n= length(sweptParameters);
            switch n
                case 0
                    out = 'afcGratings_noSweep';
                case 1
                    % sweep of a single datatype
                    switch sweptParameters{1}
                        case 'numDots'
                            out = 'afcCoherentDots_numDots';
                        case 'bkgdNumDots'
                            out = 'afcCoherentDots_bkgdNumDots';
                        case 'dotCoherence'
                            out = 'afcCoherentDots_dotCoherence';
                        case 'bkgdCoherence'
                            out = 'afcCoherentDots_bkgdCoherence';
                        case 'dotSpeed'
                            out = 'afcCoherentDots_dotSpeed';
                        case 'bkgdSpeed'
                            out = 'afcCoherentDots_bkgdSpeed';
                        case 'dotDirection'
                            out = 'afcCoherentDots_dotDirection';
                        case 'bkgdDirection'
                            out = 'afcCoherentDots_bkgdDirection';
                        case 'dotColor'
                            out = 'afcCoherentDots_dotColor';
                        case 'bkgdDotColor'
                            out = 'afcCoherentDots_bkgdDotColor';
                        case 'dotSize'
                            out = 'afcCoherentDots_dotSize';
                        case 'bkgdSize'
                            out = 'afcCoherentDots_bkgdSize';
                        case 'dotShape'
                            out = 'afcCoherentDots_dotShape';
                        case 'bkgdShape'
                            out = 'afcCoherentDots_bkgdShape';
                        case 'maxDuration'
                            out = 'afcCoherentDots_maxDuration';
                        otherwise
                            out = 'undefinedGratings';
                    end
                case 2
                    error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                case 3
                    error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                case 4
                    error('if you want to get this working, you are gonna have to create a name for it. look at the previous line for a format');
                otherwise
                    error('unsupported type. if you want this make a name for it');
            end
        end
        
        function out = getDetails(stim,what)
            switch what
                case 'sweptParameters'
                    if stim.doCombos
                        sweepnames={'numDots','dotCoherence','dotSpeed','dotDirection','dotSize','dotShape','maxDuration'};
                        
                        which = [false false false false false false false];
                        for i = 1:length(sweepnames)
                            if length(stim.(sweepnames{i}){1})>1 || length(stim.(sweepnames{i}){2})>1
                                which(i) = true;
                            end
                        end
                        out1=sweepnames(which);
                        
                        if stim.bkgdNumDots{1}>0 || stim.bkgdNumDots{2}>0
                            sweepnames={'bkgdNumDots','bkgdCoherence','bkgdSpeed','bkgdDirection','bkgdSize','bkgdShape'};
                            which = [false false false false false false];
                            for i = 1:length(sweepnames)
                                if length(stim.(sweepnames{i}){1})>1 || length(stim.(sweepnames{i}){2})>1
                                    which(i) = true;
                                end
                            end
                            out2=sweepnames(which);
                        else
                            out2 = {};
                        end
                        
                        out = {out1{:},out2{:}};
                        
                        if size(stim.dotColor{1},1)>1 || size(stim.dotColor{2},1)>1
                            out{end+1} = 'dotColor';
                        end
                        
                        if size(stim.bkgdDotColor{1},1)>1 || size(stim.bkgdDotColor{2},1)>1
                            out{end+1} = 'bkgdDotColor';
                        end
                    else
                        error('unsupported');
                    end
                otherwise
                    error('unknown what');
            end
        end
        
    end
    
    methods(Static)
        function out = stimMgrOKForTrialMgr(tm)
            assert(isa(tm,'trialManager'),'afcCoherentDots:stimMgrOKForTrialMgr:incorrectType','need a trialManager object');
            switch class(tm)
                case {'goNoGo','nAFC','autopilot','reinforcedAutopilot'}
                    out=true;
                otherwise
                    out=false;
            end
        end
    end
    
end

