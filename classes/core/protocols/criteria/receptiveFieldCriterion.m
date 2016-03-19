classdef receptiveFieldCriterion<criterion

    properties
        alpha = 0.05;
        dataRecordsPath = '\\Reinagel-lab.AD.ucsd.edu\RLAB\Rodent-Data\Fan\datanet';
        numberSpotsAllowed = 1;
        medianFilter = ones(3,3);
        atLeastNPixels=3;
    end
    
    methods
        function s=receptiveFieldCriterion(alpha,dataRecordsPath,numberSpotsAllowed,medianFilter,atLeastNPixels)
            % RECEPTIVEFIELDCRITERION  class constructor.  
            % s=receptiveFieldCriterion(alpha,dataRecordsPath,numberSpotsAllowed)
            %   alpha - confidence bounds for receptive field
            %   dataRecordsPath - path for spikeRecords and stimRecords files
            %   numberSpotsAllowed - number of spots allowed on the denoised receptive field to be eligible for graduation
            s=s@criterion();
            
            % alpha
            if isscalar(alpha)
                s.alpha = alpha;
            else
                error('alpha must be a scalar');
            end
            % dataRecordsPath
            if ischar(dataRecordsPath) && isdir(dataRecordsPath)
                s.dataRecordsPath = dataRecordsPath;
            else
                error('dataRecordsPath must be a valid directory');
            end
            % numberSpotsAllowed
            if isscalar(numberSpotsAllowed)
                s.numberSpotsAllowed = numberSpotsAllowed;
            else
                error('numberSpotsAllowed must be a scalar');
            end
            % medianFilter
            if ischar(medianFilter)
                switch medianFilter
                    case {'box','b'}
                        x=logical(ones(3));
                    case {'cross','c'}
                        x=logical([0 1 0; 1 1 1; 0 1 0]);
                end
            else
                x=medianFilter;
            end
            if islogical(x) & all(size(x)==[3 3])
                s.medianFilter = x;
            else
                error('medianFilter must logicals the size [3 3]');
            end

            % atLeastNPixels
            if iswholenumber(atLeastNPixels) & atLeastNPixels>0
                s.atLeastNPixels = atLeastNPixels;
            else
                error('numberSpotsAllowed must be a scalar');
            end

      
        end
        
        function [graduate, details] = checkCriterion(c,subject,trainingStep,trialRecords, compiledRecords)
            % this criterion will graduate if we have found a receptive field given the analysis and stimRecord
            % maybe add confident pixels and bounded region support to RFestimators...
            % then just use one of those in here

            %init
            details=[];
            graduate=false;

            % try to load the most recent analysis file and corresponding stimRecord
            if ~strcmp(trialRecords(end).stimManagerClass,'whiteNoise')
                error('this crierion is only supported for spatial white noise')
            else
                getRecordOfType='spatialWhiteNoise';
            end

            %Failure mode: if you get a RFestimate from a previous run... force it to be this session
            trialsThisSession=sum([trialRecords.sessionNumber]==trialRecords(end).sessionNumber);
            filter={'lastNTrials',trialsThisSession-1};
            % sca
            % keyboard
            %filter={'dateRange',[now-100 now]}; % only for testing
            [data success]=getPhysRecords(fullfile(c.dataRecordsPath,getID(subject)),filter,{'stim','analysis'},getRecordOfType);
            if ~success
                warning('no analysis records found - will not be able to graduate');
            else
                if any(data.analysisdata.cumulativeSTA(:)>1) && ~any(data.analysisdata.cumulativeSTA(:)>255)
                    whiteVal=255;
                    mean=whiteVal*data.stimulusDetails.meanLuminance;
                    contrast=whiteVal*data.stimulusDetails.std;
                    % our estimate is conservative, b/c we know there are cropped tail
                    % of the gaussian, the "horns"
                    %adjustedContrast=std(double(uint8((randn(1,10000)*contrast)+mean)))
                else
                    error('what''s the white value of this data?')
                    whiteVal=1;
                    mean=whiteVal*data.stimulusDetails.meanLuminance;
                    contrast=whiteVal*data.stimulusDetails.std;
                end

                [bigSpots sigSpots sigSpots3D]=getSignificantSTASpots(data.analysisdata.cumulativeSTA,data.analysisdata.cumulativeNumSpikes,mean,contrast,c.medianFilter,c.atLeastNPixels,c.alpha);
                if (nargout > 1)
                    details.bigSpots=bigSpots;
                    details.sigSpots=sigSpots;
                    details.sigSpots3D = sigSpots3D;
                end

                if length(setdiff(unique(bigSpots),[0]))<= c.numberSpotsAllowed
                    graduate=true;
                end


            end

            %play graduation tone

            if graduate
                beep;
                pause(.2);
                beep;
                pause(.2);
                beep;
            end
        end
        
        
    end
    
end

