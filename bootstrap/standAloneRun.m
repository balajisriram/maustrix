function standAloneRun(subjectID,BCorePath,setupFile)
%standAloneRun([BCorePath],[setupFile],[subjectID],[recordInOracle],[backupToServer])
%
% BCorePath (optional, string path to preexisting BCore 'db.mat' file)
% defaults to checking for db.mat in ...\<BCore install directory>\..\BCoreData\ServerData\
% if none present, makes new BCore located there, with a dummy subject
%
% setupFile (optional, name of a setProtocol file on the path, typically in the setup directory)
% defaults to 'setProtocolDEMO'
% if subject already exists in BCore and has a protocol, default is no action
%
% subjectID (optional, must be string id of subject -- will add to BCore if not already present)
% default is some unspecified subject in BCore (you can't depend on which
% one unless there is only one)
%
%
setupEnvironment;

if exist('BCorePath','var') && ~isempty(BCorePath)
    if isdir(BCorePath)
        rx=BCore(BCorePath,0);
    else
        BCorePath
        error('if BCorePath supplied, it must be a path to a preexisting BCore ''db.mat'' file')
    end
else
    dataPath=fullfile(fileparts(fileparts(getBCorePath)),'BCoreData',filesep);
    defaultLoc=fullfile(dataPath, 'ServerData');
    d=dir(fullfile(defaultLoc, 'db.mat'));

    if length(d)==1
        rx=BCore(defaultLoc,0);
        fprintf('loaded BCore from default location\n')
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
        rx=createBCoreWithDefaultStations(machines,dataPath,'localTimed');
        permStorePath=fullfile(dataPath,'PermanentTrialRecordStore');
        mkdir(permStorePath);
        rx.standAlonePath=permStorePath;
        fprintf('created new BCore\n')
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
        isSubjectInBCore=getSubjectFromID(rx,subjectID);
    catch ex
        if ~isempty(strfind(ex.message,'request for subject id not contained in BCore'))
            
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
