classdef BCoreUtil
    properties
    end
    
    methods (Static)
                
        function BCorePath=getBCorePath()
            [pathstr, ~, ~] = fileparts(mfilename('fullpath'));
            [pathstr, ~, ~] = fileparts(pathstr);
            BCorePath = fileparts(pathstr);
            BCorePath = [BCorePath filesep];
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
        
        function rx = createDefaultBCore()
            try
                [success, mac]=getMACaddress();
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
                    error('BCoreUtil:getMACAddress:unsupportedSystem','This system: %s is not supported', computer);
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
end