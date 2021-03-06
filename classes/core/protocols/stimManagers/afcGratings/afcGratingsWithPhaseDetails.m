classdef afcGratingsWithPhaseDetails<afcGratings
    % AFCGRATINGSWITHPHASEDETAILS
    % Extension of afcGratings - 
    
    properties
        phaseDetails % will include LED details
    end
    
    methods
        function s=afcGratingsWithPhaseDetails(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,radiusType, annuli,location,...
                waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos, doPostDiscrim, phaseDetails)
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
            
            s=s@afcGratings(pixPerCycs,driftfrequencies,orientations,phases,contrasts,maxDuration,radii,radiusType, annuli,location,...
                waveform,normalizationMethod,mean,thresh,maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos, doPostDiscrim);
            
            % phaseDetails
            assert(stimManager.verifyPhaseDetailsOK(phaseDetails),'afcGratings:afcGratings:invalidInput','phaseDetails not OK! Look at stimManager.verifyPhaseDetailsOK for details');
            s.phaseDetails = phaseDetails;
            
            % some sanity checks about the phaseDetails
            
            % 1. phaseDetails cannot have set post-discrim duration while
            % doPostDiscrim is false
            if ~doPostDiscrim && any(ismember({phaseDetails.phaseType},{'postDiscrimStim'}))
                error('afcGratings:afcGratings:invalidInput','provided postDiscrimStim in phaseDetails while doPostDiscrim is false');
            end
            
            % 2. discrimStim phase duration has to be NaN
            which = ismember({phaseDetails.phaseType},'discrimStim');
            if any(which)
                discrimDetails = phaseDetails(which);
                if length(discrimDetails) ~=1 || ~isnan(discrimDetails.phaseLengthInFrames)
                    error('afcGratings:afcGratings:invalidInput','too many discrim stims or discrim stim wasnt nan');
                end
            end
            
            % 3. preRequestStim phase duration has to be NaN
            which = ismember({phaseDetails.phaseType},'preRequestStim');
            if any(which)
                preRequestDetails = phaseDetails(which);
                if length(preRequestDetails) ~=1 || ~isnan(preRequestDetails.phaseLengthInFrames)
                    error('afcGratings:afcGratings:invalidInput','too many preRequest stims or preRequest stim wasnt nan');
                end
            end
        end
        
        function [sm,updateSM,resInd,stimList,LUT,targetPorts,distractorPorts,details,text,indexPulses,imagingTasks,ITL] =...
                calcStim(sm,tm,st,tR,~)
            
            [sm,updateSM,resInd,stimList,LUT,targetPorts,distractorPorts,details,text,indexPulses,imagingTasks,ITL] =...
                calcStim@afcGratings(sm,tm,st,tR);
            
            phDetails = sm.phaseDetails;

            % now deal with the information in phaseDetails
            %preRequestStim
            whichInDetails = ismember({phDetails.phaseType},'preRequestStim');
            if any(whichInDetails)
                whichInStimList = ismember(stimList(:,1),'preRequestStim');
                if phDetails(whichInDetails).LEDON
                    stimList(whichInStimList,2) = afcGratingsWithPhaseDetails.fillIn(stimList(whichInStimList,2),phDetails(whichInDetails));
                end
            end
            
            % discrimStim
            whichInDetails = ismember({phDetails.phaseType},'discrimStim');
            if any(whichInDetails)
                whichInStimList = ismember(stimList(:,1),'discrimStim');
                if phDetails(whichInDetails).LEDON
                    stimList(whichInStimList,2) = afcGratingsWithPhaseDetails.fillIn(stimList(whichInStimList,2),phDetails(whichInDetails));
                end
            end
            
            
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
        function [out, newLUT]=extractDetailFields(basicRecords,trialRecords,LUTparams)
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
        
        function stim = fillIn(stim,phaseDetail)
            
        end
    end
    
end