% this returns the path to the directory above this directory
function BCorePath=getBCorePath()
% DO U SEE ME?
[pathstr, ~, ~] = fileparts(mfilename('fullpath'));
    BCorePath = fileparts(pathstr);
    BCorePath = [BCorePath filesep];