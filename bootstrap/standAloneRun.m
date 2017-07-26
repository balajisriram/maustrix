function standAloneRun(subjectID,BCoreServerPath,setup)
%standAloneRun([BCorePath],[setupFile],[subjectID])
%
% BCorePath (optional, string path to preexisting BCore 'db.mat' file)
% defaults to checking for db.mat in ...\<BCore install directory>\..\BCoreData\ServerData\
% if none present, makes new BCore located there, with a dummy subject
%
% setup (optional, name of a setProtocol file on the path, typically in the setup directory)
% defaults to 'setProtocolDEMO'
% if subject already exists in BCore and has a protocol, default is no action
%
% subjectID (optional, must be string id of subject -- will add to BCore if not already present)
% default is some unspecified subject in BCore (you can't depend on which
% one unless there is only one)


setupEnvironment;

% create ratrix if necessary
if exist('BCorePath','var') && ~isempty(BCoreServerPath)
    assert(isdir(BCoreServerPath),'standAloneRun:incorrectValue','if BCorePath supplied, it must be a path to a preexisting BCore ''db.mat'' file')
	rx=BCore(BCoreServerPath,0);
else
    d=dir(fullfile(BCoreUtil.getServerDataPath, 'db.mat'));
    switch length(d)
        case 0
            rx = BCoreUtil.createDefaultBCore();
        case 1
            rx=BCore(BCoreUtil.getServerDataPath,0,fullfile(BCoreUtil.getBCoreDataPath,'PermanentTrialRecordStore'));
        otherwise
            error('standAloneRun:unknownError','either a single db.mat exists or none exist. We found %d. Clean your database',length(d));
    end
end



% should we add the subject to the ratrix?
if ~exist('subjectID','var') || isempty(subjectID)
    subjectID='demo1';
end

% current author is bas
auth = 'bas';

% add subject if not in BCore
switch rx.subjectIDInBCore(lower(subjectID))
    case true
        sub = rx.getSubjectFromID(subjectID);
    case false
        sub = virtual(subjectID, 'unknown');
        sub.reward = 100;
        sub.timeout = 10000;
        sub.puff = 0;
        rx=rx.addSubject(sub,auth);
end

if ~exist('setup','var') || isempty(setup)
    setup=@BCoreUtil.setProtocolDEMO;
elseif ~isa(setup,'function_handle')
    error('standAloneRun:incompatibleInput','you input setupFile thats not a function handle');
end
rx=setup(rx,{subjectID});

try
    % make sure all the previous data gets shifted to the appropriate place
    boxIDs=getBoxIDs(rx);
    rx=putSubjectInBox(rx,subjectID,boxIDs(1),auth);    
    b=getBoxIDForSubjectID(rx,sub.id);
    st=getStationsForBoxID(rx,b);
    maxTrialsPerSession = Inf;
    exitByFinishingTrialQuota = true;
    while exitByFinishingTrialQuota
        [rx,exitByFinishingTrialQuota]=st.doTrials(rx,maxTrialsPerSession,[]);
        deleteOnSuccess = true;
        BCoreUtil.replicateTrialRecords({rx.standAlonePath},deleteOnSuccess);
    end
    [~, ~] = emptyAllBoxes(rx,'done running trials in standAloneRun',auth);
    %BCoreUtil.compileDetailedRecords
    cleanup;
catch ex
    disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
    
    c = clock;
    message = {sprintf('Failed for subject::%s at time::%d:%d on %d-%d-%d',subjectID,c(4),c(5),c(2),c(3),c(1)),getReport(ex,'extended','hyperlinks','off')};
    BCoreUtil.notify(BCoreUtil.EXPERIMENTER,'Error in Rig',message);
    deleteOnSuccess = true;
    [~, ~] = emptyAllBoxes(rx,'done running trials in standAloneRun',auth);
    cleanup;
    BCoreUtil.replicateTrialRecords({rx.standAlonePath},deleteOnSuccess);
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
