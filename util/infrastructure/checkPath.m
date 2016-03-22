function out=checkPath(p)
out = false;
assert(ischar(p),'checkPath:incorrectValue','bad path format');
warning('off','MATLAB:MKDIR:DirectoryExists');
[out,~,~] = mkdir(p);
warning('on','MATLAB:MKDIR:DirectoryExists');
end