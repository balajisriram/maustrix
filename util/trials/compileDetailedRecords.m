

function a=concatAllFields(a,b)
if isempty(a) && isscalar(b) && isstruct(b)
    a=b;
    return
end
if isscalar(a) && isscalar(b) && isstruct(a) && isstruct(b)
    fn=fieldnames(a);
    if all(ismember(fieldnames(b),fn)) && all(ismember(fn,fieldnames(b)))
        for k=1:length(fn)
            try
                numRowsBNeeds=size(a.(fn{k}),1)-size(b.(fn{k}),1);
            catch
                ple
                keyboard
            end
            if iscell(b.(fn{k}))
                if ~iscell(a.(fn{k})) && all(isnan(a.(fn{k})))
                    a.(fn{k})=cell(1,length(a.(fn{k})));
                    
                    %turn nans into a cell
                    %a.(fn{k});
                    %warning('that point where its slow')
                    %[x{1:length(a.(fn{k}))}]=deal(nan);  nan filling is slow, but empty filling is fast
                    %a.(fn{k})=x;
                    %keyboard
                    %[a.(fn{k}){:,end+1:end+size(b.(fn{k}),2)}]=deal(b.(fn{k}));
                    
                    % %                     %other way
                    % %                     temp=cell(1,length(a.(fn{k}))+size(b.(fn{k}),2));
                    % %                     [temp{end-size(b.(fn{k}),2)+1:end}]=deal(b.(fn{k}){:});
                    % %                     a.(fn{k})=temp;
                    
                    
                else
                    if numRowsBNeeds~=0
                        error('nan padding cells not yet implemented')
                    end
                    
                end
                [a.(fn{k}){:,end+1:end+size(b.(fn{k}),2)}]=deal(b.(fn{k}));
            elseif ~iscell(a.(fn{k})) && ~iscell(b.(fn{k})) %anything else to check?  %isarray(a.(fn{k})) && isarray(b.(fn{k}))
                if numRowsBNeeds>0
                    b.(fn{k})=[b.(fn{k});nan*zeros(numRowsBNeeds,size(b.(fn{k}),2))];
                elseif numRowsBNeeds<0
                    a.(fn{k})=[a.(fn{k});nan*zeros(-numRowsBNeeds,size(a.(fn{k}),2))];
                end
                a.(fn{k})=[a.(fn{k}) b.(fn{k})];
            else
                (fn{k})
                error('only works if both are cells or both are arrays')
            end
        end
    else
        % 4/10/09 - added 'actualTargetOnSecs', 'actualTargetOffSecs', 'actualFlankerOnSecs', and 'actualFlankerOffSecs' to compiledDetails
        % for ifFeature, which were not there previously.
        % now, instead of erroring here, we should just fill w/ nans in a and recall concatAllFields
        warning('a and b do not match in fields - padding with nans')
        fieldsToNan=setdiff(fieldnames(b),fn);
        numToNan=length(a.(fn{1}));
        for k=1:length(fieldsToNan)
            a.(fieldsToNan{k})=nan*ones(1,numToNan);
        end
        fieldsToNan=setdiff(fn,fieldnames(b));
        numToNan=length(b.(fn{1}));
        for k=1:length(fieldsToNan)
            b.(fieldsToNan{k})=nan*ones(1,numToNan);
        end
        a=concatAllFields(a,b);
    end
else
    a
    b
    error('a and b have to both be scalar struct')
end

end


function recsToUpdate=getIntersectingFields(fieldsInLUT,recs)
recsToUpdate={};
for i=1:length(fieldsInLUT)
    pathToThisField = regexp(fieldsInLUT{i},'\.','split');
    thisField=recs;
    canAdd=true;
    for nn=1:length(pathToThisField)
        if isfield(thisField,pathToThisField{nn})
            thisField=thisField.(pathToThisField{nn});
        else
            canAdd=false;
            break;
        end
    end
    if canAdd
        recsToUpdate{end+1}=fieldsInLUT{i};
    end
end

end
