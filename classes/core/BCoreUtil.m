classdef BCoreUtil
    properties (Constant = true)
        EXPERIMENTER = 'sbalaji1984@gmail.com';
    end
    methods (Static)
        %% get paths
        function BCorePath=getBCorePath()
            [pathstr, ~, ~] = fileparts(mfilename('fullpath'));
            [pathstr, ~, ~] = fileparts(pathstr);
            BCorePath = fileparts(pathstr);
        end
        
        function BasePath = getBasePath()
            p = BCoreUtil.getBCorePath();
            [BasePath, ~, ~] = fileparts(p);
        end
        
        function ServerDataPath = getServerDataPath()
            p = BCoreUtil.getBasePath();
            p = fullfile(p,'BCoreData');
            ServerDataPath = fullfile(p,'ServerData');
        end
        
        function dataPath = getBCoreDataPath()
            p = BCoreUtil.getBasePath();
            dataPath = fullfile(p,'BCoreData');
        end
        
        function [success, mac]=getMACaddress()
            success=false;
            switch computer
                case {'PCWIN64','PCWIN32'}
                    macidcom = fullfile(PsychtoolboxRoot,'PsychContributed','macid');
                    [rc, mac] = system(macidcom);
                    mac=mac(~isstrprop(mac,'wspace'));
                    if rc==0 && isMACaddress(mac)
                        success=true;
                    end
                case {'GLNXA64','MACI64'}
                    warning('BCoreUtil:getMACAddress:unsupportedSystem','This system: %s is not supported', computer);
                    compinfo = Screen('Computer');
                    if isfield(compinfo, 'MACAddress')
                        mac = compinfo.MACAddress;
                        % Remove the : that are a part of the string
                        mac = mac(mac~=':');
                        if isMACaddress(mac)
                            success = true;
                        end
                    end
                otherwise
                    error('BCoreUtil:getMACAddress:unsupportedSystem','In getMACaddress() unknown OS');
            end
        end
        
        function mac = getMACaddressSafely()
            try
                [success, mac]=BCoreUtil.getMACaddress();
                if ~success
                    mac='000000000000';
                end
            catch
                mac='000000000000';
            end
        end
        %% default objects
        function sm = makeStandardSoundManager()
            sm=soundManager({soundClip('correctSound','allOctaves',400,20000), ...
                soundClip('keepGoingSound','allOctaves',300,20000), ...
                soundClip('trySomethingElseSound','gaussianWhiteNoise'), ...
                soundClip('wrongSound','tritones',[300 400],20000),...
                soundClip('trialStartSound','empty')});
        end
        
        function rm = makeStandardReinforcementManager()
            rewardSizeULorMS          =50;
            requestRewardSizeULorMS   =10;
            requestMode               ='first';
            msPenalty                 =1000;
            fractionOpenTimeSoundIsOn =1;
            fractionPenaltySoundIsOn  =1;
            msAirpuff                 =msPenalty;
            
            rm=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,msPenalty,msAirpuff,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,requestMode);
        end
        
        function tm = makeStandardTrialManager()
            % Create Sound Manager
            sm = BCoreUtil.makeStandardSoundManager();
            
            % Reward Manager
            rm = BCoreUtil.makeStandardReinforcementManager();
            
            
            dropFrames=false;
            percentCorrectionTrials = 0.5;
            frameDropCorner={'off'};
            saveDetailedFrameDrops = false;
            reqPort = 'center';
            customDescription = 'trialNAFC';
            showText = 'off';
            
            tm=nAFC(sm,rm,noDelay,frameDropCorner,dropFrames,reqPort,saveDetailedFrameDrops,customDescription,[1 inf],showText,percentCorrectionTrials);
        end
        
        function rx = createDefaultBCore()
            % create base BCore
            remake = true;
            rx = BCore(BCoreUtil.getServerDataPath,remake);
            
            % create station
            id = '1U';
            mac=BCoreUtil.getMACaddressSafely();
            physicalLocation = uint8([1 1 1]);
            stationPath = fullfile(BCoreUtil.getBCoreDataPath,'Stations','station1');
            st = makeDefaultStation(id,stationPath,mac,physicalLocation);
            
            % create and add box; add station to box.
            boxes=box(int8(1),fullfile(BCoreUtil.getBCoreDataPath,'Boxes','box1'));
            rx=addBox(rx,boxes);
            rx=addStationToBoxID(rx,st,boxes.id);
            
            % set perm storage;
            permStorePath=fullfile(BCoreUtil.getBCoreDataPath,'PermanentTrialRecordStore');
            warning off; mkdir(permStorePath); warning on; % sets the already exists warning off
            rx.standAlonePath=permStorePath;
            fprintf('created new BCore\n')
        end
        
        %% standard protocol List
        function r = setProtocolDEMO(r,subjIDs)
            assert(isa(r,'BCore'),'BCoreUtil:setProtocolDEMO:invalidInput','need a BCore object. You sent object of class %s',class(r));
            % TrialManager
            tm = BCoreUtil.makeStandardTrialManager();
            
            ts = BCoreUtil.createDEMOTrainingStep(tm, repeatIndefinitely(),noTimeOff(), 'easyAFC');
            
            descriptiveString='DEMO protocol 4/5/2016';
            
            pElementaryVision100915 = protocol(descriptiveString,...
                {ts});
            stepNum = 1;
            %%%%%%%%%%%%
            for i=1:length(subjIDs)
                subj=getSubjectFromID(r,subjIDs{i});
                [~, r]=setProtocolAndStep(subj,pElementaryVision100915,true,false,true,stepNum,r,'call to setProtocolMIN','bas');
            end
            
        end
        
        function ts = createDEMOTrainingStep(trialManager, performanceCrit, sch, stepName)
            % makes a basic, easy drifting grating training step
            % correct response = side toward which grating drifts?
            
            numDots = {100,100};                            % Number of dots to display
            bkgdNumDots = {0,0};                            % task irrelevant dots
            dotCoherence = {0.8, 0.8};                      % Percent of dots to move in a specified direction
            bkgdCoherence = {0.2, 0.2};                     % percent of bkgs dots moving in the specified direction
            dotSpeed = {2,2};                               % How fast do our little dots move (dotSize/sec)
            bkgdSpeed = {0.9,0.9};                          % speed of bkgd dots
            dotDirection = {pi,0};                          % 0 is to the right. pi is to the left
            bkgdDirection = {0:pi/4:2*pi,0:pi/4:2*pi};      % 0 is to the right. pi is to the left
            dotColor = {[1 1 1 0.5],[1 1 1 0.5]};           % can be a single number< 1 (used as a gray scale value); a single row of 3/4 (RGB/RGBA) ; or many rows o4 the above number sets in which case randomly chosen
            bkgdDotColor = {[1 0 1 0.5],[1 0 1 0.5]};       % can be a single number< 1 (used as a gray scale value); a single row of 3/4 (RGB/RGBA) ; or many rows o4 the above number sets in which case randomly chosen
            dotSize = {60,60};                              % Width of dots in pixels
            bkgdSize = {30,30};                             % Width in pixels
            dotShape = {{'circle'},{'circle'}};             % 'circle' or 'rectangle'
            bkgdShape = {{'square'},{'square'}};            % 'circle' or 'square'
            renderMode = {'flat'};                          % {'flat'} or {'perspective',[renderDistances]}{'perspective',[1 5]};
            % renderDistance = NaN;                           % is 1 for flat and is a range for perspective
            maxDuration = {inf, inf};                       % in seconds (inf is until response)
            background = 0;                                 % black background
            maxWidth=1920;
            maxHeight=1080;
            scaleFactor=0;
            interTrialLuminance={.5,120};
            doCombos = true;
            doPostDiscrim=false;
            
            AFCDOTS = afcCoherentDots(numDots,bkgdNumDots, dotCoherence,bkgdCoherence, dotSpeed,bkgdSpeed, dotDirection,bkgdDirection,...
                dotColor,bkgdDotColor, dotSize,bkgdSize, dotShape,bkgdShape, renderMode, maxDuration,background,...
                maxWidth,maxHeight,scaleFactor,interTrialLuminance, doCombos,doPostDiscrim);
            
            % training step using other objects as passed in
            ts = trainingStep(trialManager, AFCDOTS, performanceCrit, sch,stepName);
        end
        
        %% trial processing
        function replicateTrialRecords(paths,deleteOnSuccess)
            % This function transforms the raw, local trialRecords file into the formatted permanent-store trialRecords file.
            % Does the following:
            %   1) calls collectTrialRecords to format from {tr1,tr2,tr3,etc} to vectorized format
            %   2) does LUT processing
            %   3) Copy the trial records stored in the (local) BCoreData directory to the
            %       set of paths given in paths. Typically, paths is a location on the fileserver (ie each subject's permanent store path).
            
            input_paths = paths;
            
            subDirs=struct([]); % cannot pre allocate - number of subject files is unknown
            boxesDirs=fullfile(BCoreUtil.getBasePath,'BCoreData','Boxes');
            boxDirsToCheck=BCoreUtil.cleandir(boxesDirs);
            for b=1:length(boxDirsToCheck)
                subjectDirs=fullfile(boxesDirs,boxDirsToCheck(b).name,'subjectData');
                subjectDirsToCheck=BCoreUtil.cleandir(subjectDirs);
                for s=1:length(subjectDirsToCheck)
                    subName=subjectDirsToCheck(s).name;
                    subDir=fullfile(subjectDirs,subName);
                    if length(dir(fullfile(subDir,'trialRecords.mat')))==1
                        subDirs(end+1).dir=subDir;
                        subDirs(end).name=subName;
                        subDirs(end).file='trialRecords.mat';
                    end
                end
            end
            
            for f=1:length(subDirs)
                subjectName=subDirs(f).name;
                filePath=subDirs(f).dir;
                fileName=subDirs(f).file;
                
                % most likely failure mode is corrupt files
                [~,fn,fe]=fileparts(fileName);
                try
                    tr=load(fullfile(filePath,fileName)); %this is safe cuz it's local
                catch ME
                    switch ME.identifier
                        case 'MATLAB:load:unableToReadMatFile'
                            warning('BCoreUtil:replicateTrialPaths:corruptFile','can''t load file %s, renaming',fullfile(filePath,fileName))
                            tr.trialRecords=[];
                            movefile(fullfile(filePath,fileName),fullfile(filePath,['corrupt.' fileName '.' datestr(now,30) '.corrupt']));
                        otherwise
                            disp(['CAUGHT ERROR: ' getReport(ME,'extended')])
                            error('BCoreUtil:replicateTrialPaths:unknownError','unknown load problem');
                    end
                end
                
                % collection process
                trialRecords = collectTrialRecords(tr);
                trialNums=[trialRecords.trialNumber];
                
                % 3/17/09 - do the 'collection' and LUTizing here, then resave to local trialRecords.mat
                % because the replicate processes uses movefile instead of matlab save
                sessionLUT={};
                fieldsInLUT={};
                
                % 5/5/09 - lets try splitting the processFields according to trainingStepNum
                tsNums=double([trialRecords.trainingStepNum]);
                tsIntervals=[];
                tsIntervals(:,1)=[tsNums(find(diff(tsNums))) tsNums(end)]';
                tsIntervals(:,2)=[1 find(diff(tsNums))+1];
                tsIntervals(:,3)=[find(diff(tsNums)) length(tsNums)];
                
                for i=1:size(tsIntervals,1) % for each interval, process
                    fields=fieldnames([trialRecords(tsIntervals(i,2):tsIntervals(i,3))]);
                    % do not process the 'result' or 'type' fields because they will mess up LUT handling
                    % both fields could potentially contain strings and numerics mixed (bad for LUT indexing!)
                    fields(find(strcmp(fields,'result')))=[];
                    fields(find(strcmp(fields,'type')))=[];
                    [sessionLUT, fieldsInLUT, trialRecords(tsIntervals(i,2):tsIntervals(i,3))] = ...
                        processFields(fields,sessionLUT,fieldsInLUT,trialRecords(tsIntervals(i,2):tsIntervals(i,3)));
                end
                
                save(fullfile(filePath,fileName),'trialRecords','sessionLUT','fieldsInLUT');
                
                newFileName=[fn '_' num2str(trialNums(1)) '-' num2str(trialNums(end)) '_' ...
                    datestr(trialRecords(1).date,30) '-' datestr(trialRecords(end).date,30) fe];
                
                success = false(1,length(paths));
                for j=1:length(paths)
                    
                    [success(j), ~, messageID]=mkdir(fullfile(paths{j},subjectName));
                    switch messageID
                        case {'','MATLAB:MKDIR:DirectoryExists'}
                            d=BCoreUtil.cleandir(fullfile(paths{j},subjectName));
                            %not safe cuz of windows networking/filesharing bug -- but will just result in overwriting existing trialRecord file in case of name collision, should never happen -- ultimately just compare against filenames in oracle
                            fileAlreadyExists = ismember({d.name},newFileName);
                            if any(fileAlreadyExists)
                                % move the file to '.old'
                                dt=datevec(now);
                                frac=dt(6)-floor(dt(6));
                                successM=movefile(fullfile(paths{j},subjectName,newFileName),fullfile(paths{j},subjectName,['old.' newFileName '.old.' datestr(dt,30) '.' sprintf('%03d',floor(frac*1000))]));
                                success(j)=success(j) && successM;
                                
                                if success(j)
                                    paths{j} = fullfile(paths{j},subjectName);
                                    successC=copyfile(fullfile(filePath,fileName),fullfile(paths{j},newFileName));
                                    if ~successC
                                        error('couldn''t copy file')
                                    end
                                    success(j)=success(j) && successC;
                                end
                            end
                        case 'MATLAB:MKDIR:OSError'
                            warning('BCoreUtil:replicateTrialRecords:UnableToAccess','file path is not accessible');
                            % ## need to find ways to check if file
                            % path is remote and if so make success
                            % "true" again. this happens only when
                            % ethernet is gone
                    end
                end
                
                if deleteOnSuccess && all(success)
                    delete(fullfile(filePath,fileName));
                    % no sending data to back up bullshit!!
                elseif ~all(success)
                    BCoreUtil.notify(BCoreUtil.EXPERIMENTER,'BCoreUtil:replicateTrialRecords:IncompleteProcessing',paths(~success));
                end
            end
            
        end
        
        function trialRecords = getTrialRecordsFromPermanentStore(permanentStorePath, subjectID, filter, trustOsRecordFiles, subjectSpecificPermStore, serverDataPath)
            % r,sID, {filterType filterParameters}
            % {'dateRange',<dateFromInclusive dateToInclusive>} -- valid input for date num and length==2
            % {'lastNTrials', numTrials}
            % {'all'}
            %
            % 9/30/08 - added serverDataPath argument to getTrialRecordsFromPermanentStore call for location of temp.mat file
            
            
            trialRecords = [];
            
            if isempty(permanentStorePath)
                return
            end
            
            % Make the directory all the way down to the subject
            if subjectSpecificPermStore
                subjPath = permanentStorePath;
            else
                subjPath = fullfile(permanentStorePath,subjectID);
            end
            if ~isdir(subjPath) %not a problem if this fails due to windows filesharing/networking bug, cuz mkdir just noops with warning if dir exists
                [succ msg msgid]=mkdir(fullfile(permanentStorePath,subjectID)); %9/17/08 - dont need to depend on subjectSpecificPermStore flag cuz it wont happen in that case
                if ~succ
                    msg
                    msgid
                    permanentStorePath
                    error('couldn''t access permanent store')
                end
            end
            
            if ~trustOsRecordFiles
                %use oracle to get trailRecordFiles
                
                conn=dbConn();
                fileNames=getTrialRecordFiles(conn,subjectID);
                s = getSubject(conn,subjectID);
                closeConn(conn);
                
                % Only if the subject is not a test rat should we load files from the permanent store
                if s.test
                    'subjectID'
                    subjectID
                    warning(['Found a test subject not loading trial records']);
                    return
                end
            else
                %getTrialRecordFiles from the Os... less reliable if server is taxed...
                %but okay on local computer and has less dependency on the oracle db
                if subjectSpecificPermStore
                    fullFileNames=getTrialRecordFiles(permanentStorePath);
                else
                    fullFileNames=getTrialRecordFiles(fullfile(permanentStorePath,subjectID));
                end
                if ~isempty(fullFileNames)
                    for i=1:length(fullFileNames)
                        [filePath fileName fileExt]=fileparts(fullFileNames{i});
                        fileNames{i,1}=[fileName fileExt];
                    end %fileNames are chronological if using OS, but not necessarily if using conn to db... think it's okay because they're sorted in a few lines - pmm 08/06/26
                else
                    fileNames=[];
                end
            end
            
            if length(fileNames) <= 0
                % Normally this function is never allowed to return empty
                % the only exception is where there are no files listed in the db for
                % this subject
                warning('No records recovered from permanent store');
                return
            end
            
            
            goodRecs=getRangesFromTrialRecordFileNames(fileNames);
            
            % if ~isempty(goodRecs)
            %     [garbage sortIndices]=sort([goodRecs.trialStart],2);
            %     sortedRecs = goodRecs(sortIndices);
            %     if ~all([sortedRecs.trialStart]-[0 sortedRecs(1:end-1).trialStop])
            %         [sortedRecs.trialStart; sortedRecs.trialStop]
            %         error('ranges don''t follow consecutively')
            %     end
            %
            %     if sortedRecs(1).trialStart ~= 1
            %         [sortedRecs.trialStart; sortedRecs.trialStop]
            %         error('first verifiedHistoryFile doesn''t start at 1')
            %     end
            %     if max(max([sortedRecs.trialStart]),max([sortedRecs.trialStop])) ~= sortedRecs(end).trialStop
            %         [sortedRecs.trialStart; sortedRecs.trialStop]
            %         error('didn''t find max at bottom right corner of ranges')
            %     end
            % end
            
            [files lowestTrialNum highestTrialNum]=applyTrialFilter(goodRecs,filter);
            if iscell(filter)
                filterType=filter{1};
            else
                error('filter must be a cell array');
            end
            
            if length(files) <= 0
                error('Files listed in db, but no records recovered')
            end
            
            % Sort the trial record files
            [garbage sortIndices]=sort([files.trialStart]);
            files = files(sortIndices);
            
            
            for i=1:length(files)
                %'*****'
                completed=false;
                nAttempts=0;
                while ~completed
                    nAttempts = nAttempts+1;
                    try
                        %             tmpFile='C:\temp.mat';
                        % 9/29/08 - changed to be cross-platform; use top-level BCoreData folder for temp.mat
                        tmpFile = fullfile(fileparts(serverDataPath), 'temp.mat');
                        [success message messageid]=copyfile(fullfile(subjPath,files(i).name),tmpFile);
                        if ~success
                            message
                            error('Unable to copy trial records from remote store to local drive')
                        end
                        tr=load(tmpFile);
                        completed=true;
                    catch  ex
                        % Why are we doing this?  Because we don't want all of the
                        % computers to load the file from the remote store at the same
                        % time.  To cut down on the chance of this, we are
                        % (faux) nondeterministically waiting between loads
                        numSecsForLoad=GetSecs();
                        numSecsForLoad=fliplr(num2str(numSecsForLoad-floor(numSecsForLoad),'%.9g'));
                        % Take 2 off for the '0.' of the str.
                        lenSecs=length(numSecsForLoad)-2;
                        numSecsForLoad=str2num(numSecsForLoad)/10^lenSecs*10; % Up to 10 seconds between tries
                        pause(numSecsForLoad);
                        if exist('tr','var')
                            tr
                        else
                            permanentStorePath
                            subjectSpecificPermStore
                            subjectID
                            'I don''t have a tr'
                        end
                    end
                    
                end
                if ~completed
                    ple(ex)
                    rethrow(ex)
                end
                %'******'
                
                switch(filterType)
                    case 'dateRange'
                        dates = [];
                        for j=1:length(tr.trialRecords)
                            dates(end+1) = datenum(tr.trialRecords(j).date);
                        end
                        recIndices=intersect(find(dates>dateStart),find(dates < dateStop));
                        newTrialRecords = tr.trialRecords(recIndices);
                    case 'lastNTrials'
                        % NOTE: I'm only checking start, since once we hit the start
                        % value everything higher is included
                        if lowestTrialNum > files(i).trialStart
                            startIndex=find([tr.trialRecords.trialNumber]==lowestTrialNum)
                            if length(startIndex) ~= 1
                                error('trialRecords have multiple trials with the same trialNumber!')
                            end
                        else
                            startIndex = 1;
                        end
                        newTrialRecords = tr.trialRecords(startIndex:end);
                    case 'all'
                        newTrialRecords = tr.trialRecords;
                    otherwise
                        error('Unsupported filter type')
                end
                % Add the trial records
                
                
                %
                %         trialRecords
                %         newTrialRecords
                %         class(trialRecords)
                %         class(newTrialRecords)
                %         size(trialRecords)
                %         size(newTrialRecords)
                if ~isempty(trialRecords) && ~isempty(newTrialRecords)
                    f = fieldnames(trialRecords);
                    newf = fieldnames(newTrialRecords);
                    temp = f;
                    temp(end+1: end+length(newf)) = newf;
                    bothF = unique(temp);
                    
                    for i = 1: length(bothF)
                        oldHasIt(i)= ismember(bothF(i), f);
                        newHasIt(i)= ismember(bothF(i), newf);
                    end
                    
                    for oldNeedsIt=find(~oldHasIt)
                        fprintf(' old records need field: %s\n',bothF{oldNeedsIt})
                        [trialRecords(:).(bothF{oldNeedsIt})]=deal([]);
                    end
                    
                    for newNeedsIt=find(~newHasIt)
                        fprintf(' new records need field: %s\n',bothF{newNeedsIt})
                        [newTrialRecords(:).(bothF{newNeedsIt})]=deal([]);
                    end
                end
                
                trialRecords = [ trialRecords newTrialRecords];
                
                
                
            end
        end

        function [sessionLUT, fieldsInLUT, trialRecords] = processFields(fields,sessionLUT,fieldsInLUT,trialRecords,prefix)
            
            % if prefix is defined, then use it for fieldsInLUT
            if ~exist('prefix','var')
                prefix='';
            end
            
            for ii=1:length(fields)
                fn = fields{ii};
                try
                    if ~isempty(prefix)
                        fieldPath = [prefix '.' fn];
                    else
                        fieldPath = fn;
                    end
                    if ischar(trialRecords(1).(fn))
                        % this field is a char - use LUT
                        [indices sessionLUT] = addOrFindInLUT(sessionLUT,{trialRecords.(fn)});
                        for i=1:length(indices)
                            trialRecords(i).(fn) = indices(i);
                        end
                        if ~ismember(fieldPath,fieldsInLUT)
                            fieldsInLUT{end+1}=fieldPath;
                        end
                    elseif isstruct(trialRecords(1).(fn)) && ~isempty(trialRecords(1).(fn)) && ~strcmp(fn,'errorRecords')...
                            && ~strcmp(fn,'responseDetails') && ~strcmp(fn,'phaseRecords') && ~strcmp(fn,'trialDetails') ...
                            && ~strcmp(fn,'stimDetails') % check not an empty struct
                        % 12/23/08 - note that this assumes that all fields are the same structurally throughout this session
                        % this doesn't work in the case of errorRecords, which is empty sometimes, and non-empty other times
                        % this is a struct - recursively call processFields on all fields of the struct
                        thisStructFields = fieldnames((trialRecords(1).(fn)));
                        % now call processFields recursively - pass in fn as a prefix (so we know how to store to fieldsinLUT)
                        [sessionLUT fieldsInLUT theseStructs] = processFields(thisStructFields,sessionLUT,fieldsInLUT,[trialRecords.(fn)],fieldPath);
                        % we have to return a temporary 'theseStructs' and then manually reassign in trialRecords unless can figure out correct indexing
                        for j=1:length(trialRecords)
                            trialRecords(j).(fn)=theseStructs(j);
                        end
                    elseif iscell(trialRecords(1).(fn))
                        % if a simple cell (all entries are strings), then do LUT stuff
                        % otherwise, we should recursively look through the entries, but this is complicated and no easy way to track in fieldsInLUT
                        % because the places where you might find struct/cell in the cell array is not consistent across trials
                        % keeping track of each exact location in fieldsInLUT will result in trialRecords.stimDetails.imageDetails{i} for all i in trialRecords
                        % this kills the point of using a LUT! - for now, just don't handle complicated cases (leave as is)
                        addToLUT=false;
                        for trialInd=1:length(trialRecords)
                            thisRecordCell=[trialRecords(trialInd).(fn)];
                            if all(cellfun('isclass',thisRecordCell,'char') | cellfun('isreal',thisRecordCell)) % 3/3/09 - should change to if all(ischar or isscalar)
                                [indices sessionLUT] = addOrFindInLUT(sessionLUT,thisRecordCell);
                                trialRecords(trialInd).(fn)=indices;
                                addToLUT=true;
                            end
                        end
                        if addToLUT && ~ismember(fieldPath,fieldsInLUT)
                            fieldsInLUT{end+1}=fieldPath;
                        end
                    elseif ismember(fieldPath,fieldsInLUT)
                        % 5/5/09 - if this field was LUTized in a prior training step interval, ALWAYS LUTize it here!
                        % just do basic processing on this field (fails for char -> struct/cell conversions)
                        [indices sessionLUT] = addOrFindInLUT(sessionLUT,{trialRecords.(fn)});
                        for i=1:length(indices)
                            trialRecords(i).(fn) = indices(i);
                        end
                    end
                catch ex
                    disp(['CAUGHT EX: ' getReport(ex)]);
                    warning('LUT processing of trialRecords failed! - probably due to manual training step switching.');
                end
            end
            
        end
        
        function out = cleandir(d)
            d = dir(d);
            out = d(~ismember({d.name},{'.','..'}));
        end
        
        function trialRecords = collectTrialRecords(tr)
            % tr should be a struct with fields 'tr0', 'tr1', 'tr2', etc
            % where tr0 is a blank (empty to create the trialRecords.mat file)
            % and subsequent trN fields are the trialRecord for each the N-th trial
            %
            % we should return a struct array of trialRecords in our customary format
            % and also do some sanity checking
            
            fields=fieldnames(tr);
            unsortedRecords=[];
            order=[];
            
            for i=1:length(fields)
                [match, tokens] = regexpi(fields{i},'tr(\d+)','match','tokens');
                if ~isempty(match) && ~strcmp(match,'tr0')
                    order=[order str2double(tokens{1}{1})];
                    unsortedRecords=[unsortedRecords tr.(fields{i})];
                end
            end
            
            [~, ind]=sort(order);
            trialRecords=unsortedRecords(ind);
            if isempty(trialRecords) % when would this happen?
                return;
            end
            
            % sanity checks
            if any([trialRecords.trialNumber]~=trialRecords(1).trialNumber:trialRecords(end).trialNumber)
                error('BCoreUtil:collectTrialRecords:incorrectValue','trialNumber not monotonically increasing');
            end
            
            if length(unique([trialRecords.sessionNumber]))>1
                error('BCoreUtil:collectTrialRecords:incorrectValue','more than one unique sessionNumber');
            end
            
            if length(unique([trialRecords.subjectsInBox]))>1
                error('BCoreUtil:collectTrialRecords:incorrectValue','more than one unique subjectInBox');
            end
            
        end
        
        function notify(WHO,SUBJECT,PARAMS)
            assert(ischar(SUBJECT),'BCoreUtil:notify:invalidInput','SUBJECT needs to be a char. instead is : %s',class(SUBJECT));
            assert(ischar(PARAMS)||iscell(PARAMS),'BCoreUtil:notify:invalidInput','PARAMS needs to be a char or cell. instead is : %s',class(PARAMS));
            switch WHO
                case BCoreUtil.EXPERIMENTER
                    BCoreUtil.mail(BCoreUtil.EXPERIMENTER,SUBJECT,PARAMS);
                case BCoreUtil.SWAPPER
                case 'all'
            end
        end
        
        function mail(address,subject,message,attachment)
            if ~exist('attachment','var') || isempty(attachment)
                attachment = '';
            end
            if ~exist('address','var')
                error('BCoreUtil:mail:variableRequired','address is missing');
            end
            if ~exist('subject','var')
                error('BCoreUtil:mail:variableRequired','subject is missing');
            end
            if ~exist('message','var')
                warning('BCoreUtil:mail:variablePreferred','message is missing.using default message');
                message = '';
            end
            % Define these variables appropriately:
            mail = 'ghoshlab@gmail.com'; %Your GMail email address
            password = 'visualcortex'; %Your GMail password
            
            % Then this code will set up the preferences properly:
            setpref('Internet','E_mail',mail);
            setpref('Internet','SMTP_Server','smtp.gmail.com');
            setpref('Internet','SMTP_Username',mail);
            setpref('Internet','SMTP_Password',password);
            props = java.lang.System.getProperties;
            props.setProperty('mail.smtp.auth','true');
            props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
            props.setProperty('mail.smtp.socketFactory.port','465');
            
            % Send the email
            if ~isempty(attachment)
                sendmail(address,subject,message,attachment);
            else
                sendmail(address,subject,message);
            end
        end
        
    end
end