classdef subject
    
    properties
        id
        gender
        protocol
        trainingStepNum
        protocolVersion
        
        reward %ul or ms as required
        timeout % ms as required
        puff
    end
    
    methods
        function s=subject(id,gender)
            % SUBJECT  class constructor.
            % s = subject(id,species,strain,gender,birthDate,receivedDate,litterID,supplier)
            s.id = id;
            s.gender = gender;

%             switch nargin
%                 case 0
%                     if no input arguments, create a default object
%                     
%                 case 1
%                     if single argument of this class type, return it
%                     if (isa(varargin{1},'subject'))
%                         s = varargin{1};
%                     else
%                         error('Input argument is not a subject object')
%                     end
%                 case 8
%                     create object using specified values
% 
%                     s.id=lower(varargin{1});
%                     if (strcmpi(varargin{2},'rat') && strcmpi(varargin{3},'long-evans')) || ...
%                             (strcmpi(varargin{2},'squirrel') && strcmpi(varargin{3},'wild caught')) || ...
%                             (strcmpi(varargin{2},'mouse') && (strcmpi(varargin{3},'c57bl/6j') || strcmpi(varargin{3},'dba/2j') || strcmpi(varargin{3},'b6d2f1/j') )) || ...
%                             (strcmpi(varargin{2},'degu') && strcmpi(varargin{3},'none')) || ...
%                             (strcmpi(varargin{2},'human') && strcmpi(varargin{3},'none'))
%                         s.species=varargin{2};
%                         s.strain=varargin{3};
%                     else
%                         error('species must be ''rat'' (strain ''long-evans''), ''squirrel'' (strain ''wild''), ''mouse'' (strains ''c57bl/6j'' ''dba/2j'' ''B6D2F1/J''), ''degu'' (strain ''none''), or ''human'' (strain ''none'')')
%                     end
% 
%                     if strcmpi(varargin{4},'male') || strcmpi(varargin{4},'female')
%                         s.gender=varargin{4};
%                     else
%                         error('gender must be male or female')
%                     end
% 
%                     dtb = datevec(varargin{5},'mm/dd/yyyy');
%                     if ~strcmpi(varargin{6},'unknown')
%                         dtr = datevec(varargin{6},'mm/dd/yyyy');
%                     else
%                         dtr=varargin{6};
%                     end
%                     if dtb(1)>=2005 && dtb(4) == 0 && dtb(5) == 0 && dtb(6) == 0 && (strcmp(dtr,'unknown') || (dtr(1)>=2005 && dtr(4) == 0 && dtr(5) == 0 && dtr(6) == 0))
%                         s.birthDate=dtb;
%                         s.receivedDate=dtr;
%                     else
%                         error('dates must be supplied as mm/dd/yyyy and no earlier than 2005 (acq date may be ''unknown'')')
%                     end
% 
%                     s.litterID=varargin{7};
%                     if strcmpi(s.litterID,'unknown') || (isstrprop(s.litterID(1), 'alpha') && isstrprop(s.litterID(1), 'lower') && s.litterID(2)==' ' && all(varargin{5}==s.litterID(3:end)))
%                         nothing
%                     else
%                         ['''' s.litterID '''']
%                         error('litterID must be ''unknown'' or supplied as ''[single lower case letter] DOB(mm/dd/yyyy -- must match DOB supplied)'' -- ex: ''a 01/01/2007''')
%                     end
% 
%                     if ismember(varargin{8},{'wild caught','Jackson Laboratories','Harlan Sprague Dawley'})
%                         s.supplier=varargin{8};
%                     else
%                         error('supplier must be ''wild caught'' or ''Jackson Laboratories'' or ''Harlan Sprague Dawley''')
%                     end
% 
%                     s.protocol=[];
%                     s.trainingStepNum=0;
%                     s.protocolVersion.manualVersion=0;
%                  
%                 case 10 % created to save mouse genetic details
%                     create object using specified values
% 
%                     s.id=lower(varargin{1});
%                     if (strcmpi(varargin{2},'rat') && strcmpi(varargin{3},'long-evans')) || ...
%                             (strcmpi(varargin{2},'squirrel') && strcmpi(varargin{3},'wild caught')) || ...
%                             (strcmpi(varargin{2},'mouse') && (strcmpi(varargin{3},'c57bl/6j') || strcmpi(varargin{3},'dba/2j') || strcmpi(varargin{3},'b6d2f1/j') )) || ...
%                             (strcmpi(varargin{2},'degu') && strcmpi(varargin{3},'none')) || ...
%                             (strcmpi(varargin{2},'human') && strcmpi(varargin{3},'none')) || ...
%                             (strcmpi(varargin{2},'virtual'))
%                         s.species=varargin{2};
%                         s.strain=varargin{3};
%                     else
%                         keyboard
%                         error('species must be ''rat'' (strain ''long-evans''), ''squirrel'' (strain ''wild''), ''mouse'' (strains ''c57bl/6j'' ''dba/2j'' ''B6D2F1/J''), ''degu'' (strain ''none''), ''human'' (strain ''none''), or ''virtual'' (strain ''none'',''N/A'','''')')
%                     end
% 
%                     if strcmpi(varargin{4},'male') || strcmpi(varargin{4},'female')
%                         s.gender=varargin{4};
%                     elseif strcmp(varargin{2},'virtual') % for virtuals, dont check anything
%                         s.gender = varargin{4};
%                     else
%                         error('gender must be male or female')
%                     end
% 
%                     dtb = datevec(varargin{5},'mm/dd/yyyy');
%                     if ~strcmp(varargin{6},'unknown')
%                         dtr = datevec(varargin{6},'mm/dd/yyyy');
%                     else
%                         dtr=varargin{6};
%                     end
%                     if dtb(1)>=2005 && dtb(4) == 0 && dtb(5) == 0 && dtb(6) == 0 && (strcmp(dtr,'unknown') || (dtr(1)>=2005 && dtr(4) == 0 && dtr(5) == 0 && dtr(6) == 0))
%                         s.birthDate=dtb;
%                         s.receivedDate=dtr;
%                     else
%                         error('dates must be supplied as mm/dd/yyyy and no earlier than 2005 (acq date may be ''unknown'')')
%                     end
% 
%                     s.litterID=varargin{7};
%                     if strcmp(s.litterID,'unknown') || (isstrprop(s.litterID(1), 'alpha') && isstrprop(s.litterID(1), 'lower') && s.litterID(2)==' ' && all(varargin{5}==s.litterID(3:end)))
%                         nothing
%                     else
%                         ['''' s.litterID '''']
%                         error('litterID must be ''unknown'' or supplied as ''[single lower case letter] DOB(mm/dd/yyyy -- must match DOB supplied)'' -- ex: ''a 01/01/2007''')
%                     end
% 
%                     if ismember(varargin{8},{'wild caught','Jackson Laboratories','Harlan Sprague Dawley','Bred In-house'})
%                         s.supplier=varargin{8};
%                     else
%                         error('supplier must be ''wild caught'' or ''Jackson Laboratories'' or ''Harlan Sprague Dawley''')
%                     end
% 
%                     if ischar(varargin{9})
%                         s.geneticBackground = varargin{9};
%                     else
%                         error('geneticBackground needs to be a string');
%                     end
% 
%                     if ischar(varargin{10})
%                         s.geneticModification = varargin{10};
%                     else
%                         error('geneticModification needs to be a string');
%                     end
%                     s.protocol=[];
%                     s.trainingStepNum=0;
%                     s.protocolVersion.manualVersion=0;
%                     
% 
%                 otherwise
%                     error('Wrong number of input arguments')
%             end
        end

        function [subject, r] = changeAllPercentCorrectionTrials(subject,newValue,r,comment,auth)
            
            validateattributes(r,{'BCore'},{'nonempty'});
            assert(~isempty(getSubjectFromID(r,subject.id)));
            
            for i=1:subject.protocol.numTrainingSteps
                sm = subject.protocol.trainingSteps{i}.stimManager;
                updatable =hasUpdatablePercentCorrectionTrial(sm);
                if updatable
                    sm=setPercentCorrectionTrials(sm,newValue);
                    ts=setStimManager(ts,sm);
                end
                subject.protocol.trainingSteps{i}=ts;
            end
            
            [subject, r]=setProtocolAndStep(subject,subject.protocol.getName(steps),0,1,0,subject.trainingStepNum,r,comment,auth);
        end
        
        function [subject, r] = setReinforcementParam(subject,param,val,stepNums,r,comment,auth)
            validateattributes(r,{'BCore'},{'nonempty'});
            assert(~isempty(getSubjectFromID(r,subject.id)));
            switch param
                case 'reward'
                    subject.reward = val;
                case 'timeout'
                    subject.timeout = val;
                case 'puff'
                    subject.puff = val;
                otherwise
                    switch stepNums
                        case 'all'
                            steps=uint8(1:subject.protocol.numTrainingSteps);
                        case 'current'
                            steps=subject.trainingStepNum;
                        otherwise
                            if isvector(stepNums) && isNearInteger(stepNums) && all(stepNums>0 & stepNums<=subject.protocol.numTrainingSteps)
                                steps=uint8(stepNums);
                            else
                                error('stepNums must be ''all'', ''current'', or an integer vector of stepnumbers between 1 and numSteps')
                            end
                    end
                    
                    for i=steps
                        ts=subject.protocol.trainingSteps{i};
                        
                        ts=ts.setReinforcementParam(param,val);
                        [subject, r]=changeProtocolStep(subject,ts,r,comment,auth,i);
                    end
            end
            
        end
        
        function [subject, r] = changeProtocolStep(subject,ts,r,comment,auth,stepNum)
            
            validateattributes(ts,{'trainingStep'},{'nonempty'});
            validateattributes(r,{'BCore'},{'nonempty'});
            
            assert(~isempty(getSubjectFromID(r,subject.id)));
            
            if ~exist('stepNum','var')||isempty(stepNum)
                stepNum=subject.trainingStepNum;
            end
            
            if ~isempty(subject.protocol) && isscalar(stepNum) && isinteger(stepNum) && stepNum>0 && stepNum<=length(subject.protocol.trainingSteps)
                if r.authorCheck(auth)
                    newProtocol = changeStep(subject.protocol, ts, stepNum);
                    
                    [subject, r]=setProtocolAndStep(subject,newProtocol,0,1,0,subject.trainingStepNum,r,comment,auth);
                else
                    error('author failed authentication')
                end
            else
                error('subject does not have a protocol, or stepNum is not a valid index of trainingSteps in the protocol')
            end
            
        end
        
        function s = decache(s)
            if ~isempty(s.protocol)
                s.protocol=decache(s.protocol);
            end
        end
        
        function out = disp(s, str)
            if ~exist('str','var')
                str = '';
            end
            out = sprintf('%s\tid:\t\t%s\ngender:\t\t%s\n',str,s.id,s.gender);
            %         if strcmp(s.receivedDate,'unknown')
            %             rd=s.receivedDate;
            %         else
            %             rd=datestr(s.receivedDate,'mm/dd/yyyy');
            %         end
            %             out=sprintf('id:\t\t%s\nspecies:\t%s\nstrain:\t\t%s\ngender:\t\t%s\nbirth:\t\t%s\nacquired:\t%s\nlitterID:\t%s\nsupplier:\t%s',...
            %                          s.id,s.species,s.strain,s.gender,datestr(s.birthDate,'mm/dd/yyyy'),rd,s.litterID,s.supplier);
        end
        
        function [sub, r, keepWorking, secsStateFlip, tR, st] = doTrial(sub,r,st,rn,tR,sessNum,cR)
            % [subject, BCore, keepWorking, secondsTilStateFlip, trialRecord, station] = ...
            %      doTrial(subject,BCore,station,rnet,trialRecords,sessionNumber,compiledRecords)
            validateattributes(r,{'BCore'},{'nonempty'});
            validateattributes(st,{'station'},{'nonempty'});
            if ~isempty(rn)
                validateattributes(rn,{'rnet'},{'nonempty'});
            end
            
            p = sub.protocol;
            t = sub.trainingStepNum;
            
            if t>0
                ts=p.trainingSteps{t};
                
                [graduate, keepWorking, secsStateFlip, sub, r, tR, st, manualTs]=doTrial(ts,st,sub,r,rn,tR,sessNum,cR);

                if manualTs
                    proto = sub.protocol;
                    validTs=[1:p.numTrainingSteps];
                    validInputs{1}=validTs;
                    type='manual ts';
                    typeParams.currentTsNum=currentTsNum;
                    typeParams.trainingStepNames={};
                    for i=validTs
                        typeParams.trainingStepNames{end+1}=generateStepName(proto.trainingStep{i},'','');
                    end
                    newTsNum = userPrompt(st.window,validInputs,type,typeParams);
                    tR(end).result=[tR(end).result ' ' num2str(newTsNum)];
                    if newTsNum~=currentTsNum
                        [sub r]=setStepNum(sub,newTsNum,r,sprintf('manually setting to %d',newTsNum),'BCore');
                    end
                    keepWorking=1;
                end
                
                if graduate && ~manualTs
                    if p.numTrainingSteps>=t+1
                        [sub, r]=setStepNum(sub,t+1,r,'graduated!','BCore');
                    else
                        if p.isLooped
                            [sub, r]=setStepNum(sub,uint16(1),r,'looping back to 1','BCore'); % for looped protocols, the step is sent back to 1
                        else
                            [sub, r]=setStepNum(sub,t,r,'can''t graduate because no more steps defined!','BCore');
                        end
                    end
                end
            elseif t==0
                keepWorking=0;
                secsStateFlip=-1;
                newStep=[];
                updateStep=0;
            else
                error('training step is negative')
            end
        end
        
        function s=setProtocolVersion(s,protocolVersion)
            validateattributes(protocolVersion,{'uint8','scalar'})
            s.protocolVersion=protocolVersion;
        end
        
        function [s, r]=setStepNum(s,i,r,comment,auth)
            validateattributes(r,{'BCore'},{'nonempty'});
            assert(~isempty(getSubjectFromID(r,s.id)));
            assert(~subjectIDRunning(r,s.id));
            
            p = s.protocol;
            assert(isPositiveIntegerValuedNumeric(i) && i<=p.numTrainingSteps,...
                'i needs to be positive scalar < numTrainingSteps');
            assert(r.authCheck(auth),'author check failed')
            
            [s, r]=setProtocolAndStep(s,p,0,0,1,i,r,comment,auth);
        end
        
        function [s, r]=setProtocolAndStep(s,p,thisIsANewProtocol,thisIsANewTrainingStep,thisIsANewStepNum,i,r,comment,auth)
            % INPUTS
            %   s                       subject object
            %   p                       protocol (eg from setProtocol)
            %   thisIsANewProtocol  	if FALSE, does not rewrite protocol descr to log
            %   thisIsANewTrainingStep  if FALSE, does not rewrite trainingstep descr to log
            %   thisIsANewStepNum       if FALSE, does not log setting of new step number
            %   i                       index of training step
            %   r                       BCore object
            %   comment                 string that will be saved to log file
            %   auth                    string which must be an authorized user id
            %                           (see BCore.authorCheck)
            % OUTPUTS
            % s     subject object
            % r     BCore object
            %
            % example call
            %     [subj r]=setProtocolAndStep(subj,p,1,0,1,1,r,'first try','edf');
            validateattributes(p,{'protocol'},{'nonempty'});
            validateattributes(r,{'BCore'},{'nonempty'});
            assert(~isempty(getSubjectFromID(r,s.id)),'subject not found in BCore');
            assert(~r.subjectIDRunning(s.id),'subject should not be  running');
            
            assert(isPositiveIntegerValuedNumeric(i) && i<=p.numTrainingSteps,...
                'i needs to be positive scalar < numTrainingSteps');
            assert(r.authorCheck(auth),'author check failed')
            
            s.protocol=p;
            s.trainingStepNum=uint8(i);
            
            if strcmp(auth,'BCore')
                s.protocolVersion.autoVersion=s.protocolVersion.autoVersion+1;
            else
                s.protocolVersion.autoVersion=1;
                try
                    s.protocolVersion.manualVersion=s.protocolVersion.manualVersion+1;
                catch
                    s.protocolVersion.manualVersion = 1;
                end
            end
            s.protocolVersion.date=datevec(now);
            s.protocolVersion.author=auth;
            
            r=updateSubjectProtocol(r,s,comment,auth,thisIsANewProtocol,thisIsANewTrainingStep,thisIsANewStepNum); 
        end
        
    end
end