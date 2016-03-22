function standAloneRun(subjectID,ratrixPath,setupFile)
%standAloneRun([ratrixPath],[setupFile],[subjectID],[recordInOracle],[backupToServer])
%
% ratrixPath (optional, string path to preexisting ratrix 'db.mat' file)
% defaults to checking for db.mat in ...\<ratrix install directory>\..\ratrixData\ServerData\
% if none present, makes new ratrix located there, with a dummy subject
%
% setupFile (optional, name of a setProtocol file on the path, typically in the setup directory)
% defaults to 'setProtocolDEMO'
% if subject already exists in ratrix and has a protocol, default is no action
%
% subjectID (optional, must be string id of subject -- will add to ratrix if not already present)
% default is some unspecified subject in ratrix (you can't depend on which
% one unless there is only one)
%
%
setupEnvironment;

if exist('ratrixPath','var') && ~isempty(ratrixPath)
    if isdir(ratrixPath)
        rx=ratrix(ratrixPath,0);
    else
        ratrixPath
        error('if ratrixPath supplied, it must be a path to a preexisting ratrix ''db.mat'' file')
    end
else
    dataPath=fullfile(fileparts(fileparts(getRatrixPath)),'ratrixData',filesep);
    defaultLoc=fullfile(dataPath, 'ServerData');
    d=dir(fullfile(defaultLoc, 'db.mat'));

    if length(d)==1
        rx=ratrix(defaultLoc,0);
        fprintf('loaded ratrix from default location\n')
    else
        try
            [success mac]=getMACaddress();
            if ~success
                mac='000000000000';
            end
        catch
            mac='000000000000';
        end

        machines={{'1U',mac,[1 1 1]}};
        rx=createRatrixWithDefaultStations(machines,dataPath,'localTimed');
        permStorePath=fullfile(dataPath,'PermanentTrialRecordStore');
        mkdir(permStorePath);
        rx.standAlonePath=permStorePath;
        fprintf('created new ratrix\n')
    end
end

needToAddSubject=false;
needToCreateSubject=false;
if ~exist('subjectID','var') || isempty(subjectID)
    ids=getSubjectIDs(rx);
    if length(ids)>0
        subjectID=ids{1};
    else
        subjectID='demo1';
        needToCreateSubject=true;
        needToAddSubject=true;
    end
else
    subjectID=lower(subjectID);
    try
        isSubjectInRatrix=getSubjectFromID(rx,subjectID);
    catch ex
        if ~isempty(strfind(ex.message,'request for subject id not contained in ratrix'))
            
            needToCreateSubject=true;
            needToAddSubject=true;
        else
            rethrow(ex)
        end
    end
end

if needToCreateSubject
    warning('creating dummy subject')
    sub = rat(subjectID, 'male', 'long-evans', datetime(2005,05,10), datetime(2006,05,10), 'unknown', 'wild caught');
end
auth='bas';

if needToAddSubject
    rx=addSubject(rx,sub,auth);
end

if (~exist('setupFile','var') || isempty(setupFile)) && ~isa(getProtocolAndStep(getSubjectFromID(rx,subjectID)),'protocol')
    setupFile='setProtocolMINBS';
end

if exist('setupFile','var') && ~isempty(setupFile)
    x=what(fileparts(which(setupFile)));
    if isempty(x) || isempty({x.m}) || ~any(ismember(lower({setupFile,[setupFile '.m']}),lower(x.m)))
        setupFile
        error('if setupFile supplied, it must be the name of a setProtocol file on the path (typically in the setup directory)')
    end

    su=str2func(setupFile); %weird, str2func does not check for existence!
    rx=su(rx,{subjectID});
    %was:  r=feval(setupFile, r,{getID(sub)});
    %but edf notes: eval is bad style
    %http://www.mathworks.com/support/tech-notes/1100/1103.html
    %http://blogs.mathworks.com/loren/2005/12/28/evading-eval/
end

%[isExperimentSubject, xtraExptBackupPath, experiment] = identifySpecificExperiment(subjectID);

try
    deleteOnSuccess = true; 
    backupToServer = false;
    if backupToServer
        if isExperimentSubject
            replicationPaths={getStandAlonePath(rx),xtraServerBackupPath};
            for z = 1:length(xtraExptBackupPath)
                replicationPaths{end+1}=xtraExptBackupPath{z};
            end
        else
            replicationPaths={getStandAlonePath(rx),xtraServerBackupPath};
        end
    else
        replicationPaths={getStandAlonePath(rx)};
    end
recordInOracle = false;
    replicateTrialRecords(replicationPaths,deleteOnSuccess, recordInOracle);

    s=getSubjectFromID(rx,subjectID);

    [rx ids] = emptyAllBoxes(rx,'starting trials in standAloneRun',auth);
    boxIDs=getBoxIDs(rx);
    rx=putSubjectInBox(rx,subjectID,boxIDs(1),auth);    
    b=getBoxIDForSubjectID(rx,s.id);
    st=getStationsForBoxID(rx,b);
    %struct(st(1))
    maxTrialsPerSession = 250;
    exitByFinishingTrialQuota = true;
    while exitByFinishingTrialQuota
        [rx,exitByFinishingTrialQuota]=doTrials(st(1),rx,maxTrialsPerSession,[],~recordInOracle);
        replicateTrialRecords(replicationPaths,deleteOnSuccess, recordInOracle);
    end
    [rx ids] = emptyAllBoxes(rx,'done running trials in standAloneRun',auth);
    if ~testMode
        compilePath=fullfile(fileparts(getStandAlonePath(rx)),'CompiledTrialRecords');
        mkdir(compilePath);
        dailyAnalysisPath = fullfile(fileparts(getStandAlonePath(rx)),'DailyAnalysis');
        mkdir(dailyAnalysisPath);
        compileDetailedRecords([],{subjectID},[],getStandAlonePath(rx),compilePath);
        
        selection.type = 'animal status';
        selection.filter = 'all';
        selection.filterVal = [];
        selection.filterParam = [];
        selection.titles = {sprintf('subject %s',subjectID)};
        selection.subjects = {subjectID};
        fs=analysisPlotter(selection,compilePath,true);
%         subjectAnalysis(compilePath);
    end
    cleanup;
    % testing
    clear all
catch ex
    disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
    
    [~, b] = getMACaddress();
    c = clock;
    message = {sprintf('Failed for subject::%s at time::%d:%d on %d-%d-%d',subjectID,c(4),c(5),c(2),c(3),c(1)),getReport(ex,'extended','hyperlinks','off')};
    switch b
        case 'A41F7278B4DE' %gLab-Behavior1
            gmail('sbalaji1984@gmail.com','Error in Rig 1',message);
            gmail('ashgutierrez11@gmail.com','Error in Rig 1',message);
            gmail('madeleineciobanu@gmail.com','Error in Rig 1',message);
        case 'A41F729213E2' %gLab-Behavior2
            gmail('sbalaji1984@gmail.com','Error in Rig 1',message);
            gmail('ashgutierrez11@gmail.com','Error in Rig 1',message);
            gmail('madeleineciobanu@gmail.com','Error in Rig 1',message);
        case 'A41F726EC11C' %gLab-Behavior3
            gmail('sbalaji1984@gmail.com','Error in Rig 1',message);
            gmail('ashgutierrez11@gmail.com','Error in Rig 1',message);
            gmail('madeleineciobanu@gmail.com','Error in Rig 1',message);
        case '7845C4256F4C' %gLab-Behavior4
            gmail('sbalaji1984@gmail.com','Error in Rig 1',message);
            gmail('ashgutierrez11@gmail.com','Error in Rig 1',message);
            gmail('madeleineciobanu@gmail.com','Error in Rig 1',message);
        case '7845C42558DF' %gLab-Behavior5
            gmail('sbalaji1984@gmail.com','Error in Rig 1',message);
            gmail('ashgutierrez11@gmail.com','Error in Rig 1',message);
            gmail('madeleineciobanu@gmail.com','Error in Rig 1',message);
        case 'A41F729211B1' %gLab-Behavior6
            gmail('sbalaji1984@gmail.com','Error in Rig 1',message);
            gmail('ashgutierrez11@gmail.com','Error in Rig 1',message);
            gmail('madeleineciobanu@gmail.com','Error in Rig 1',message);
        case 'BC305BD38BFB' %gLab-Behavior6
            gmail('sbalaji1984@gmail.com','Error in Rig 1',message);
            gmail('ashgutierrez11@gmail.com','Error in Rig 1',message);
            gmail('madeleineciobanu@gmail.com','Error in Rig 1',message);
        case 'F8BC128444CB' %robert-analysis
            disp('no backup');
        otherwise
            warning('not sure which computer you are using. add that mac to this step. delete db and then continue. also deal with the other createStep functions.');
            keyboard;
    end
%     replicateTrialRecords(replicationPaths,deleteOnSuccess, recordInOracle);
    cleanup;
    rethrow(ex)
end
end
function cleanup
sca
FlushEvents('mouseUp','mouseDown','keyDown','autoKey','update');
ListenChar(0)
ShowCursor(0)
end
