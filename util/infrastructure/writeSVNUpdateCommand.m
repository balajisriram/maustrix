function writeSVNUpdateCommand(targetURL,targetRevNum)
checkTargetRevision({targetURL,targetRevNum});

save([BCoreUtil.getBCorePath 'update.mat'],'targetURL','targetRevNum');

'updating to version:'
targetURL
targetRevNum