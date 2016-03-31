function out = chooseFrom(in)
validateattributes(in,{'numeric','cell'},{'nonempty'});
l = length(in);
which = randperm(l);

if isnumeric(in)
        out = in(which(1));
elseif iscell(in)
        out = in{which(1)};
end

end