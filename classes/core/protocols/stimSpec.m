classdef stimSpec
    
    properties
        % fields in the stimSpec object
        stimulus
        transitions
        stimType
        startFrame
        framesUntilTransition
        autoTrigger
        scaleFactor
        isFinalPhase
        hz
        phaseType
        phaseLabel
        isStim
        indexPulses
        lockoutDuration
        ledON = false;
        ledPulses
        punishResponses
    end
    
    methods
        function spec=stimSpec(stimulus,transitions,stimType,startFrame,framesUntilTransition,autoTrigger,...
                scaleFactor,isFinalPhase,hz,phaseType,phaseLabel,punishResponses,isStim,indexPulses,ledPulses)
            % stimSpec  class constructor.
            % spec=stimSpec(stimulus,transitions,stimType,startFrame,framesUntilTransition,
            %	autoTrigger,scaleFactor,isFinalPhase,hz,phaseType,phaseLabel,punishResponses,isStim,indexPulses)
            %
            % INPUTS
            % stimulus                  the stimulus frames to show, or expert-mode parameters struct (equivalent to non-phased 'out')
            % transitions               a cell array of the format {port1 target1 port2 target2 ...} where triggering port1 will cause a phase transition to
            %                               the phase specified by target1, triggering port2 will cause a phase transition to the phase specified by target2, etc.
            %                               the port values are a subset of all ports and the target values are indices into the array of stimSpec objects.
            %                               if the port value is empty ([]), then there is no phase transition by port triggering (instead, this is the special 'frame timeout' transition, see below)
            %                               this 'frame timeout' transition is also used even if framesUntilTransition is empty, but if the stimType is 'cache'
            %                               or 'timedFrames' with a nonzero end, and we finish showing the stimulus for the specified duration.
            % stimType                  must be one of the non-phased values for stimManager.calcStim()'s 'type' output, with the same properties
            %                               ('static', {'trigger',toggleStim}, 'cache', 'loop', {'timedFrames', [frameTimes]}, {'indexedFrames', [frameIndices]}, or 'expert') - default is loop
            %                               this is effectively a phase-specific type, instead of trial-specific
            % startFrame                what frame of the stimulus to start this phase at; if 'loop' mode, automatically start at first frame after looping through once
            %                               set to zero to start at the beginning
            % framesUntilTransition     length of the frame timeout (if we have shown this phase for framesUntilTransition frames with no transition by port selection,
            %                               then advance to the next phase as specified by the criterion automatically)
            %                           	if framesUntilTransition is greater than the length of the stimulus and the stimType is 'cache' or
            %                               'timedFrames' with nonzero end, then we will throw an error during the validation process.
            %                               advances to the special 'frame timeout' phase - see above
            %                               if empty, then hold this phase indefinitely until a port transition is triggered
            %                               or we transition due to the strategy of 'cache' or 'timedFrames'.
            % autoTrigger               a cell array of values {pA, portA, pB, portB,...} where pA specifies the probability of stochastically triggering
            %                            	portA, and pB specifies the probability of triggering portB, etc
            %                           	this is done for every frame of the stimulus (loop of runRealTimeLoop), and the execution order is whatever comes first
            %                               in this cell array (ie pA is tried, then pB, and so forth)
            % scaleFactor               the scaleFactor associated with this phase - see stimManager.calcStim()'s scaleFactor output for details
            % isFinalPhase              a flag if this is the final phase of the trial (defaults to zero)
            % hz                        if trialManager.displayMethod = 'ptb':
            %                               value is ignored (the resolution is set by stimManager.calcStim()'s resolutionIndex for the whole trial, it is not phase-specific)
            %                               for non-expert phase types, phaseify happens to set this value to stimManager.calcStim()'s requested screen Hz, but it is still ignored
            %                           if trialManager.displayMethod = 'LED'
            %                               non-expert phase types:
            %                                   stimManager.calcStim() returns a desired Hz for the LED as its resolutionIndex output
            %                                   this value is passed to trialManager.runRealTimeLoop() via stimSpec.hz so that the analogoutput can be configured to the desired Hz for each phase
            %                               expert phase types:
            %                                   set this value to your desired value for each phase (stimManager.calcStim()'s resolutionIndex output is ignored)
            %                           even when ignored, value must be scalar >0 (on mac, can be 0, and is ignored because Screen('Resolutions') and Screen('Resolution') return 0hz -- macs do not have the data acquisition toolbox and therefore cannot have trialManager.displayMethod='LED' anyway)
            % phaseType                 one of {'reinforced', ''} -- reinforced will ask the reinforcement manager how much water/airpuff to deliver at the beginning of the phase
            %                               a reward that extends beyond the end of the phase is cut off.
            % phaseLabel                a text label for the given phase to be stored in phaseRecords
            % punishResponses			a boolean indicating what to do with responses during this phase - either punish or ignore
            %								(ignore actually could mean "accept" during discrim phase - just means do not punish)
            % isStim                    a boolean indicating whether to set the station's stim pin high during this phase (usually during discriminanda) [defaults to false]
            % indexPulses               a boolean vector same length as stimulus indicating what to output on the station's indexPin during each frame (defaults to all false)
            % ledON                     vector of booleans length = number of LEDs

            % stimulus
            spec.stimulus = stimulus;
            
            % transitions
            validateattributes(transitions,{'cell'},{'nonempty'});
            assert(all(cellfun(@isnumeric,transitions)),'stimSpec:stimSpec:incorrectValue','transitions should contain a sequence of numbers');
            spec.transitions = transitions;
            
            % stimType
            assert1 = ischar(stimType) && (strcmp(stimType,'loop')||strcmp(stimType,'cache')||strcmp(stimType,'expert'));
            assert2 = iscell(stimType) && (...
                strcmp(stimType{1},'timedFrames')||...
                strcmp(stimType{1},'indexedFrames')||...
                (strcmp(stimType{1},'trigger')&& size(spec.stimulus,3) == 2 && islogical(stimType{2}))...
                );
            assert(assert1||assert2,'stimSpec:stimSpec:incorrectValue','stimType must be trigger, loop, cache, timedFrames, indexedFrames, or expert with correct specification');
            spec.stimType = stimType;
            
            % startFrame
            assert(isscalar(startFrame) && startFrame>=0,'stimSpec:stimSpec:incorrectValue','startFrame should be a positive scalar');
            spec.startFrame=startFrame;
                
            % framesUntilTransition
            assert(isscalar(framesUntilTransition) && framesUntilTransition>=0 || isempty(framesUntilTransition),'stimSpec:stimSpec:incorrectValue','framesUntilTransition should be a positive scalar');
            if ~isinf(framesUntilTransition)
                assert(any(cellfun(@isempty,spec.transitions)),'stimSpec:stimSpec:incompatibleValue','framesUntilTransition provided without a timeout phase target');
            end
            spec.framesUntilTransition=framesUntilTransition;
            
            % autoTrigger
            assert(iscell(autoTrigger)||isempty(autoTrigger),'stimSpec:stimSpec:incorrectInput','autoTrigger of the wrong class');
            if ~isempty(autoTrigger) && isreal(autoTrigger{1}) && autoTrigger{1} >= 0 && autoTrigger{1} < 1 && isvector(autoTrigger{2})
                spec.autoTrigger = autoTrigger;
            else
                spec.autoTrigger = [];
            end

            % scaleFactor
            assert((length(scaleFactor)==2 && all(scaleFactor>0)) || (length(scaleFactor)==1 && scaleFactor==0) || isempty(scaleFactor),'stimSpec:stimSpec:incorrectValue','');
            spec.scaleFactor=scaleFactor;
            
            % isFinalPhase
            assert(isscalar(isFinalPhase) && islogical(isFinalPhase),'stimSpec:stimSpec:incorrectValue','isFinalPhase should be a logical value');
            spec.isFinalPhase = isFinalPhase;
            
            % hz
            assert(isscalar(hz) && hz>0 && isreal(hz),'stimSpec:stimSpec:incorrectValue','hz should be a positive real number');
            spec.hz=hz;
                
            % phaseType - we need this so that runRealTimeLoop knows whether or not this phase should do a reward/airpuff, etc
            potentialPhaseTypes = {'reinforced','pre-request','pre-response','discrim','post-discrim','itl','earlyPenalty'};
            assert(any(~cellfun(@isempty,strfind(potentialPhaseTypes,phaseType))),'stimSpec:stimSpec:incorrectValue',...
                'phaseType must be ''reinforced'', ''pre-request'', ''pre-response'', ''discrim'', ''itl'', ''earlyPenalty''')
                spec.phaseType=phaseType;
            
            
            % phaseLabel
            assert(ischar(phaseLabel))
            spec.phaseLabel=phaseLabel;
            
            % punishResponses
            assert(islogical(punishResponses) && isscalar(punishResponses))
            spec.punishResponses=punishResponses;
            
            % isStim
            assert(islogical(isStim) && isscalar(isStim))
            spec.isStim=isStim;
            
            % ledPulses
            assert(all(islogical(ledPulses)))
            spec.ledPulses=ledPulses;
            
            
            if (isempty(spec.scaleFactor) || isempty(spec.stimulus)) && ~strcmp(spec.phaseType,'reinforced')  && ~strcmp(spec.phaseType,'earlyPenalty') && ~strcmp(spec.phaseType,'itl')
                error('empty scaleFactor and stimulus allowed only for reinforced phaseType');
            end
            
            stimLen=size(spec.stimulus,3);
            if ~isempty(indexPulses)
                spec.indexPulses=indexPulses;
            else
                spec.indexPulses=false(1,stimLen);
            end
            if isvector(spec.indexPulses) && islogical(spec.indexPulses) && length(spec.indexPulses)==stimLen
                %pass
            else
                sca;keyboard
                error('indexPulses must be logical vector same length as stimulus')
            end
        end
        
        function out=getIndexPulse(s,i)
            if exist('i','var') && ~isempty(i) && i
                out=s.indexPulses(i);
            else
                out=s.indexPulses;
            end
        end
        

        function spec=setStim(spec,stim)
            origSize=size(spec.stimulus);
            newSize=size(stim);
            if (length(origSize)==length(newSize) && all(size(stim)==size(spec.stimulus)))
                %do nothing -- keep same indexPulses cuz they're the right size
            elseif isempty(spec.stimulus)
                spec.indexPulses=false(1,size(stim,3)); %dynamically creating error/reward stim
            else
                struct(spec)
                error('dont know how to dynamically make these indexPulses -- someone already made them with incompatible size');
            end
            spec.stimulus = stim;
        end
 
        
    end
    
end

