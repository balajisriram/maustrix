classdef box
    properties
        id = '';
        path = '';
    end
    
    methods
        function b = box(varargin)
            switch nargin
                case 0
                    % pass
                case 2
                    if varargin{1}>0 && isscalar(varargin{1}) && isinteger(varargin{1})
                        b.id=varargin{1};
                    else
                        error('id must be positive scalar integer')
                    end
                    
                    if checkPath(varargin{2})
                        b.path=varargin{2};
                    else
                        error('path check failed. must provide fully resolved path to box for temporary storage of subjects'' trial data')
                    end
            end
        end
        
        function clearSubjectDataDir(b)
            %subPath = [b.path 'subjectData' filesep]; %used to have an additional filesep before subjectData?
            subPath = getSubjectDataDir(b);
            files=dir(subPath);
            
            if ~isempty(files)
                disp(sprintf('found old subjectData files for box, backing up'))
                timestamp = datestr(now,30);
                
                [success,message,msgid] = movefile(subPath,fullfile(b.path, ['oldSubjectData.' timestamp]));
                if ~success
                    message
                    msgid
                    error('could not create backup dir')
                end
            end
        end
        
        function d=disp(b)
            d=['box id: ' num2str(b.id) '\tpath: ' strrep(b.path,'\','\\')];
            d=sprintf(d);
        end
        
        function subPath=getBoxPathForSubjectID(b,sID,r)
            if isa(r,'BCore')
                if getBoxIDForSubjectID(r,sID)==b.id
                    subPath=fullfile(getSubjectDataDir(b),sID);  %[b.path 'subjectData' filesep sID filesep];
                else
                    error('subject not in this box')
                end
            else
                error('BCore does not contain subject')
            end
        end
        
        function out=getPath(b)
            out=b.path;
        end
        
        function trialRecords=getTrialRecordsForSubjectID(b,sID,r)
            disp(sprintf('loading records for %s (from box)',sID))
            startTime=GetSecs();
            if isa(r,'BCore')
                subPath=getBoxPathForSubjectID(b,sID,r);
                trialRecords=loadMakeOrSaveTrialRecords(subPath);
            else
                error('need BCore object')
            end
            disp(sprintf('done loading records for %s: %g s elapsed',sID,GetSecs()-startTime))
        end
        
        function out = testBoxSubjectDir(box,sub)
            out=0;
            if isa(sub,'subject')
                testDir = fullfile(getSubjectDataDir(box),sub.id); %['subjectData' filesep getID(sub) filesep];
                
                warning('off','MATLAB:MKDIR:DirectoryExists')
                [success,message,msgid] = mkdir(testDir);
                warning('on','MATLAB:MKDIR:DirectoryExists')
                
                if success
                    out=1;
                else
                    error('could not make or find box''s directory for this subject: %s, %s, %s',testDir,message,msgid)
                end
            else
                error('didn''t get subject argument')
            end
        end
        
        function updateTrialRecordsForSubjectID(b,sID,trialRecords,r)
            disp(sprintf('saving records for %s (from box)',sID))
            startTime=GetSecs();
            if isa(r,'BCore')
                subPath=getBoxPathForSubjectID(b,sID,r);
                loadMakeOrSaveTrialRecords(subPath,trialRecords);
            else
                error('need BCore object')
            end
            disp(sprintf('done saving records for %s: %g s elapsed',sID,GetSecs()-startTime))
        end
    end
    
    methods(Access=private)
        function out=getSubjectDataDir(b)
            out=fullfile(b.path,'subjectData');
            checkPath(out);
        end
    end
end