function succ = ping(dataIP)
if ispc
    pingStr = sprintf('ping -n 3 %s',dataIP);
    a = dos(pingStr);
    succ = ~a;
elseif IsOSX || IsLinux
    warning('not yet');
    succ = false;
end
end