classdef station
    
    properties
        id
        path
        MACAddress
        physicalLocation
    end
    
    methods
        function s = station(id,path,MAC,physLoc)
            s.id = id;
            s.path = path;
            s.MACAddress = MAC;
            s.physicalLocation = physLoc;
        end
        
        function out=dis(s)
            out='';
            for i=1:length(s)
                b=s(i);
                
                d=['station id: ' b.id '\tports: ' num2str(b.numPorts) '\tresponseMethod: ' b.responseMethod '\tpath: ' strrep(b.path,'\','\\')];
                if ~isempty(out)
                    out=sprintf('%s\n%s',out,sprintf(d));
                else
                    out=sprintf(d);
                end
            end
        end

        function sub=getCurrentSubject(s,r)
            validateattributes(r,{'BCore'},{'nonempty'})
            subs=getSubjectsForStationID(r,s.id);
            if length(subs)==1
                sub=subs{1};
            else
                error('only implemented for stations in boxes with exactly one subject -- later will use RFID for group housing')
            end
        end
    end
    
    methods (Static)
        function out = allImagingTasksSame(oldTasks,newTasks)
            % compare the two lists of imaging tasks and return if they are the same or not
            out=true;
            % do they have same # of tasks?
            if ~all(size(oldTasks)==size(newTasks))
                out=false;
                return
            end
            % check that each task is the same...what about if they are in diff order?
            % for now, enforce that the tasks must be in same order as well
            % ie [4 5 6] is not equal to [5 4 6]
            for i=1:length(oldTasks)
                a=oldTasks{i};
                b=newTasks{i};
                if length(a)~=length(b)
                    out=false;
                    return
                end
                for j=1:length(a)
                    if strcmp(class(a{j}),class(b{j})) % same class, now check that they are equal
                        if ischar(a{j})
                            if strcmp(a{j},b{j})
                                %pass
                            else
                                out=false;
                                return
                            end
                        elseif isnumeric(a{j})
                            if a{j}==b{j}
                                %pass
                            else
                                out=false;
                                return
                            end
                        else
                            error('found an argument that was neither char nor numeric');
                        end
                    else
                        out=false; % args have diff class
                        return
                    end
                end
            end
        end % end function
        
        function out = numPorts
            out = 0;
        end
    end
end