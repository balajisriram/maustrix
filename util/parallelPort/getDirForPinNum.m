function out=getDirForPinNum(pinNum,dir)
spec=getBitSpecForPinNum(pinNum);

switch dir
    case 'read'
        out=true;
    case 'write'
        out=ismember(spec(2),[0 2]);
    otherwise
        error('dir must be ''read'' or ''write''')
end