function writeSVNUpdateCommand(targetURL,targetRevNum)
checkTargetRevision({targetURL,targetRevNum});

save([getBCorePath 'update.mat'],'targetURL','targetRevNum');

'updating to version:'
targetURL
targetRevNum