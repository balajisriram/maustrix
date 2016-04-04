function s=checkForUpdate
% This function performs all svn-related code updating/maintenance on both server and client side
% This should only be called in BCoreServer and bootstrap
% If there is an update.mat file, then check the arguments there and update code as necessary
% If there is no update file, then check that the current revision/path is valid
% In both cases, we use the function checkTargetRevision (which holds the minRev and path constraints)
% getSVNRevisionForPath and getSVNPropertiesFromXML are used in checkTargetRevision

f = [getBCorePath 'update.mat'];


% If the file exists run the update
if exist(f) == 2
    try
        fprintf('Attempting to update BCore code\n');

        rPath=getBCorePath
        [runningSVNversion repositorySVNversion url]=getSVNRevisionFromXML(rPath)

        target=load(f);
        [targetSVNurl targetRevNum] =checkTargetRevision({target.targetURL,target.targetRevNum})

        svnPath = GetSubversionPath;

        if rPath(end)==filesep
            rPath=rPath(1:end-1) %windows svn requires no trailing slash
        end

        [status result]=system([svnPath 'svn cleanup ' '"' rPath '"']);
        if status~=0
            result
            'bad svn cleanup of BCore code'
        end
        
        rPath

        % Must remove the directories from Matlab's path, so they can be
        % deleted if needed
        %rPath=getBCorePath; % Store it so it is not forgotten
        rmpath(RemoveSVNPaths(genpath(rPath)));

        if isempty(targetRevNum)
            revNumStr='HEAD';
        else
            revNumStr=num2str(targetRevNum);
        end
        rPath
        %cmdStr=[svnPath 'svn switch "' targetSVNurl '"@' revNumStr ' "' rPath '" && ' svnPath 'svn cleanup "' rPath '"']
        cmdStr=[svnPath 'svn switch "' targetSVNurl '" -r ' revNumStr ' "' rPath '" && ' svnPath 'svn cleanup "' rPath '"']
        [status result]=system(cmdStr);

        % Generate a new list of directories
        addpath(RemoveSVNPaths(genpath(rPath)));

        if status~=0 %|| any(strfind(result,'skip'))
            result
            'error updating BCore code'
        else
            result
            [runningSVNversion repositorySVNversion url]=getSVNRevisionFromXML(getBCorePath);
            if ((isempty(targetRevNum)&& repositorySVNversion==runningSVNversion)||...
                    (~isempty(targetRevNum)&&runningSVNversion==targetRevNum)) && strcmp(url,targetSVNurl)
                delete(f);
                fprintf('BCore code update appeared to succeed\n');
            else
                runningSVNversion
                targetRevNum
                url
                targetSVNurl
                'failed svn update -- leaving update file'
            end
        end

        updatePsychtoolboxIfNecessary

    catch ex
        disp(['CAUGHT ERROR: ' getReport(ex,'extended')])
        error('failure in checkForUpdate')
    end
    pause(3);
    quit
else
    % no update file, check current revision
    fprintf('Not updating BCore code - checking current revision\n');
    svnProperties = getSVNPropertiesForPath('', {'revision', 'url'});
    [targetSVNurl targetRevNum] = checkTargetRevision({svnProperties.url, svnProperties.revision});
%     targetSVNurl
%     targetRevNum
end