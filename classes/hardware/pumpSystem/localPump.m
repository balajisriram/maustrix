classdef localPump
    
    properties
        const = [];

        rezValveDIO=[];
        rezValvePin=0;
        eqDelay=0;
        valveDelay=0;
        station=[];
        pump=[];
        inited=false;
    end
    
    methods
        function s=localPump(varargin)
            % LOCALPUMP  class constructor.
            % s = localPump(pump,rezValvePin,eqDelay,valveDelay)


            % at first matlab would not see the beambreak signals on the control register even though it
            % could on the status register.  the voltages were within TTL spec (low= 0-0.8V, hi= 2-5V), but were not as
            % nice as normal (0.6V-3.9V rather than the 0-5V we typically get).
            % finally i tried switching to SPP (standard mode) in the BIOS, instead of
            % ECP (the default).  that fixed it...  i think part of the mode definitions
            % are the electrical specs of the pins and the control port, which is
            % bidirectional.  there's something about tristating for bidirectional use
            % of pins that i don't understand.

            % daq toolbox will only address standard builtin parallel port at addr 0378!
            % you can always read from a line configured for output
            %
            % % pins 1, 11, 14, and 17 are hardware inverted
            % % port 0, pins 2-9                - Eight I/O lines, with pin 9 being the most significant bit (MSB).
            % % port 1, pins 10-13, and 15      - Five input lines used for status
            % % port 2, pins 1, 14, 16, and 17  - Four I/O lines used for control
            %
            % % L/C/R detectors are on pins 13/10/12
            % % L/C/R valves are on pins 4/3/2



            %to read from the control register, the parallel port MUST be set to "SPP" in the BIOS,
            %rather than "ECP," which is the typical default on modern machines.
            %this is weird, because you are supposed to be able to use the "extended control register"
            %at (base address) + 402h to put an ECP port into fully SPP compatible mode (by setting the MSB's to '000' or '001').
            %i tried both settings to no avail.
            %
            %this is somewhat verified by the fact that all my pci add-on parallel
            %ports seem to only be able to run in SPP mode, and for a long time those
            %were the only ones i could get to read from the control register (i hadn't been setting the builtin parallel port to SPP)
            %
            %even in SPP, in order to read from the control register, you have to put the pin into the high impedance state,
            %by writing a zero or one to it, depending on whether it is hardware inverted.
            %since digitalio on the parallelport requires each port to be set completely to read or completely to write,
            %there is no convenient way to write to the pins before reading from the pins (you need two separate dio objects,
            %one with the control port set to read, one set to write).
            %
            %references:
            %http://www.beyondlogic.org/spp/parallel.htm
            %http://www.beyondlogic.org/ecp/ecp.htm
            %http://www.fapo.com/files/ecp_reg.pdf
            %
            %i want to be able to read the address of the LPT port from the "BIOS Data Area"
            %rather than having to look it up in the device manager -- this is presumably how the data acq toolbox finds the address,
            %(the device-specific property "PortAddress").  there is c code at the link above that does this,
            %but i am unable to use mex to compile it because it uses the "far" keyword:
            %
            %unsigned int far *ptraddr;
            %unsigned int address;
            %ptraddr=(unsigned int far *)0x00000408;
            %address = *ptraddr;
            %
            %i know this code works when i use the "far" keyword, but if i remove it in order to get mex to compile it,
            %then it crashes all of matlab when it tries to dereference ptraddr in the fourth line, i'm assuming
            %because this is in protected memory.


            %from matlab support
            % >>> In response to your second question, MATLAB uses the WinIO kernel driver
            % >>> and associated DLL to directly access the parallel port under Windows.
            % >>> It determines the port address using the "GetPhysLong" function provided
            % >>> by WinIO. This function allows you to read from the protected area of
            % >>> memory which contains the BIOS data. For instance, to determine the
            % >>> first parallel port base address, you would use the following command:
            % >>>
            % >>> bresult = GetPhysLong((PBYTE)0x0408, &port);
            % >>>
            % >>> WinIO can be downloaded from the following website:
            % >>>
            % >>> http://www.internals.com/utilities_main.htm
            % >>>
            % >>> The code that you supplied would not work unless it was in a device
            % >>> driver running in ring 0 because that area of memory is protected by
            % >>> Windows. WinIO includes a Windows driver which runs in ring 0 and
            % >>> provides functions to access protected memory.


            s.const.valveOff = int8(0);
            s.const.valveOn = int8(1);

            s.rezValveDIO=[];
            s.rezValvePin=0;
            s.eqDelay=0;
            s.valveDelay=0;
            s.station=[];
            s.pump=[];
            s.inited=false;

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'localPump'))
                        s = varargin{1};
                    else
                        error('Input argument is not a localPump object')
                    end

                case 4
                    if isa(varargin{1},'pump')
                        s.pump=varargin{1};
                    else
                        error('local pump requires a pump object')
                    end

                    if isinteger(varargin{2}) && varargin{2}>=2 && varargin{2}<=9
                        s.rezValvePin=varargin{2};
                    else
                        error('rezValvePin must be integer 2-9')
                    end

                    if isscalar(varargin{3}) && varargin{3}>=0
                        s.eqDelay=varargin{3};
                    else
                        error('eqDelay must be scalar >= 0')
                    end

                    if isscalar(varargin{4}) && varargin{4}>=0
                        s.valveDelay=varargin{4};
                    else
                        error('valveDelay must be scalar >= 0')
                    end

                    

                otherwise
                    error('Wrong number of input arguments')
            end


            % CONTROL_PORT=3;
            % ls=hwinfo.Port(CONTROL_PORT) ;
            % lines = addline(d,ls.LineIDs,ls.ID,'in'); %beambreaks go on control port
            % infTooFarBit=find(strcmp(lines.LineName,['Pin' num2str(infTooFarPin)]));
            % wdrTooFarBit=find(strcmp(lines.LineName,['Pin' num2str(wdrTooFarPin)]));
            %
            % if length(infTooFarBit) ~=1 || length(wdrTooFarBit) ~=1 || any(isnan([infTooFarBit wdrTooFarBit]))
            %     error('didn''t find correct inf/wdr too far in lines')
            % end
            %
            % portval = getvalue(d.Line([infTooFarBit wdrTooFarBit]))
            %
            %
            % dh=digitalio('parallel','LPT1');
            % hwinfo=daqhwinfo(dh);
            % lh=hwinfo.Port(CONTROL_PORT) ;
            % lines = addline(dh,lh.LineIDs,lh.ID,'out');
            % putvalue(dh,[0 0 1 0]) %this should happen before each read from d!  sets pins 1 14 16 17 to hi impedence for reading.



            % STATUS_PORT=2;
            % ls=hwinfo.Port(STATUS_PORT) ;
            % lines = addline(di,ls.LineIDs,ls.ID,'in');%motor running is on status port
            % motorRunningBit=find(strcmp(lines.LineName,['Pin' num2str(motorRunningPin)]));
            %
            % if length(motorRunningBit) ~=1 || isnan(motorRunningBit)
            %     error('didn''t find correct inf/wdr too far in lines')
            % end
            %
            % portval = getvalue(di.Line(motorRunningBit))
        end
        
        function s=closeLocalPump(s)
            if ~s.inited
                error('localPump not inited')
            end

            s=resetPosition(s);

            s.pump=closePump(s.pump);
            setRezValve(s,s.const.valveOff);

        end
        
        function s=doReward(s,mlVol,valves,dontReset)

            if ~s.inited
                error('localPump not inited')
            end

            if ~isempty(find(valves))

                if isa(s.station,'station')
                    verifyValvesClosed(s.station);
                else
                    error('not inited')
                end

                setRezValve(s,s.const.valveOff);

                if outsidePositionBounds(s.pump)
                    s=resetPosition(s);
                end

                numPumps=ceil(mlVol/getMlMaxSinglePump(s.pump));
                volPerPump=mlVol/numPumps;

                if volPerPump>0
                    setValves(s.station, valves);
                    WaitSecs(s.valveDelay);
                    for i=1:numPumps
                        try
                            [durs t s.pump]=doAction(s.pump,volPerPump,'infuse');
                        catch ex
                            if ~isempty(findstr(ex.message,'request will put pump outside max/min position -- reset pump position first'))
                                setValves(s.station, 0*valves);
                                WaitSecs(s.valveDelay);
                                s=resetPosition(s);
                                setValves(s.station, valves);
                                WaitSecs(s.valveDelay);
                                [durs t s.pump]=doAction(s.pump,volPerPump,'infuse');
                            else
                                rethrow(ex)
                            end
                        end
                    end
                    setValves(s.station, 0*valves);
                    WaitSecs(s.valveDelay);

                    if ~dontReset
                        s=resetPosition(s);
                    end
                end
            else
                error('valves must have a nonzero entry')
            end
        end
        
        function s=initLocalPump(s,st,pportaddr)

            if ~ispc
                error('pump systems only supported on pc')
            end

            if isa(st,'station')
                s.station=st;
            else
                error('need a station')
            end

            if ischar(pportaddr) && hex2dec(pportaddr)==hex2dec('0378')
                %pass
            else
                error('local pump only works for parallel port address 0378')
            end



            daqreset; %probably a bad idea
            s.rezValveDIO=digitalio('parallel');
            pa=get(s.rezValveDIO,'PortAddress');
            if ~strcmp(pa(1:2),'0x') || str2num(pa(3:end)) ~= str2num(pportaddr)
                pa
                error('bad port address from digitalio(''parallel'')')
            end

            hwinfo=daqhwinfo(s.rezValveDIO);
            DATA_PORT=1;
            ls=hwinfo.Port(DATA_PORT) ;
            lines = addline(s.rezValveDIO,ls.LineIDs,ls.ID,'out');

            gotOne=false;
            dels=[];
            for i=1:length(s.rezValveDIO.line)
                if ~strcmp(s.rezValveDIO.line(i).LineName,['Pin' num2str(s.rezValvePin)])
                    dels=[dels i];
                else
                    if gotOne
                        error('more than one matching line for that pin')
                    else
                        gotOne=true;
                    end
                end
            end
            delete(s.rezValveDIO.line([dels]));
            if ~gotOne || length(s.rezValveDIO.line)~=1
                error('couldn''t find matching line for that pin')
            end
            %s.rezValveDIO.line


            s.inited=true;


            setRezValve(s,s.const.valveOff);
            [s.pump durs]=openPump(s.pump);


            s=resetPosition(s);
        end
        
        function s=resetPosition(s)

            if ~s.inited
                error('localPump not inited')
            end

            if isa(s.station,'station')
                verifyValvesClosed(s.station);
            else
                error('not inited')
            end

            setRezValve(s,s.const.valveOn);
            [dursTemp t s.pump]=doAction(s.pump,0,'reset position');
            WaitSecs(s.eqDelay);
            setRezValve(s,s.const.valveOff);
        end
        
        function setRezValve(s,state)

            if ~s.inited
                error('localPump not inited')
            end

            if ismember(state,[s.const.valveOff s.const.valveOn])
            putvalue(s.rezValveDIO,state); %appears to not overwrite other lines!  nice.
            WaitSecs(s.valveDelay);
            else
                error('bad state')
            end
        end
        
        
        
    end
    
end

