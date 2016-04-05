function rx = getOrMakeDefaultBCore(makeNew,startEyelinkIfAvail)
% gets the default BCore OR if doesn't exist, makes a default
% flag 'makeNew' forces creation of new BCore object

if ~exist('makeNew','var') || isempty(makeNew)
    makeNew=false;
end

dataPath=fullfile(fileparts(fileparts(BCoreUtil.getBCorePath)),'BCoreData',filesep);
defaultLoc=fullfile(dataPath, 'ServerData');
d=dir(fullfile(defaultLoc, 'db.mat'));

if length(d)==1 && ~makeNew
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
    if strcmp(mac,'BC305BD38BFB')
        machines = {{'1U',mac,[1 1 1]}}; % GLab EPhys rig
    else
        machines={{'1U',mac,[1 1 1]}};
    end
    rx=createBCoreWithDefaultStations(machines,dataPath,'localTimed',startEyelinkIfAvail);
    permStorePath=fullfile(dataPath,'PermanentTrialRecordStore');
    mkdir(permStorePath);
    rx.standAlonePath=permStorePath;
    fprintf('created new BCore\n')
end