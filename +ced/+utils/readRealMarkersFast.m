function [n_read,s] = readRealMarkersFast(fhand,chan_id,n_max,tick1,tick2,n_init,growth_rate)
%
%   [n_read,s] = readRealMarkersFast(fhand,chan_id,n_max,tick1,tick2,n_init,growth_rate)
%
%   See Also
%   --------
%   ced.channel.real_mark
%   CEDS64ReadExtMarks


%Type = calllib('ceds64int', 'S64ChanType', fhand, iChan);
Size = calllib('ceds64int', 'S64ItemSize', fhand, chan_id);
current_tick_time = int64(tick1);
Count = 0;
if (Size < 0)
    return;
end

if (nargin < 5 || tick2 < 0)
    i64Upto = -1;
    tick2 = CEDS64MaxTime(fhand) +1;
else
    i64Upto = tick2;
end

maskcode = -1;

[iOk,Rows,Cols] = CEDS64GetExtMarkInfo( fhand, chan_id );
if iOk < 0
    return
end

Reals = Rows * Cols;
%Confirmed, realmarker uses same structure as Marker
%
%   InMarker = struct(CEDMarker());
%
%This way of doing it avoids the warning issues
InMarker = ced.utils.getCEDMarkerStruct(1);

floatptr = zeros(Reals,1,'single');

s = h__getStruct(n_init);

for n = 1:n_max
    if (current_tick_time >= tick2)
        break;
    end

    %Grow structure if we are going to exceed allocated size
    %------------------------------
    if n > length(s)
        n_new = ceil(growth_rate*length(s));
        n_add = n_new - length(s);
        if n_add < 10
            %Ideally this code is never run, but just in case ...
            n_add = 10;
        end
        s = [s; h__getStruct(n_add)]; %#ok<AGROW>
    end

    [ n_read, OutMarker, dReal ] = calllib('ceds64int', 'S64Read1RealMark', ...
        fhand, chan_id, InMarker, floatptr, current_tick_time, i64Upto, maskcode);
    
    if (n_read > 0)
        Count = Count + 1;
        s(n).time = OutMarker.m_Time;
        s(n).code1 = OutMarker.m_Code1;
        s(n).code2 = OutMarker.m_Code2;
        s(n).code3 = OutMarker.m_Code3;
        s(n).code4 = OutMarker.m_Code4;
        s(n).data = reshape(dReal, Rows, Cols);
        current_tick_time = OutMarker.m_Time + 1;
    else
        break;
    end
end

if Count > 0
    s(Count+1:end) = [];
else
    s = [];
end

n_read = Count;

end

function s = h__getStruct(n)
%
%   This is the output format struct

time_cell = num2cell(zeros(n,1));
s = struct('data',[],'time',time_cell,'code1',0,'code2',0,...
    'code3',0,'code4',0);

end

