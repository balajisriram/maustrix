function r=init
[pathstr, name, ext, versn] = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(pathstr)),'bootstrap'));
setupEnvironment
dataPath=fullfile(fileparts(fileparts(getBCorePath)),'BCoreData',filesep);
r=BCore(fullfile(dataPath, 'ServerData'),0); %load from file