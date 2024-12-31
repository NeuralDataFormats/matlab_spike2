function [n_read,s] = readWaveMarkersFast(fhand,chan_id,n_max,tick1,tick2,n_init,growth_rate)
%
%
%
%   See Also
%   ---------
%   CEDWaveMark
%   ced.channel.wave_mark


%CEDS64READEXTMARKS Reads extended marker data from a extended marker channels
%   [ iRead, ExtMarkers ] = CEDS64ReadExtMarks( fhand, iChan, iN,  i64From {, i64To {, maskh}} )
%   Inputs
%   fhand - An integer handle to an open file
%   iChan - A channel number for an extended event channel
%   iN - The maximum number of data points to read
%   i64From - The time in ticks of the earliest time you want to read
%   i64To - (Optional) The time in ticks of the latest time you want to
%   read. If not set or set to -1, read to the end of the channel
%   maskh -  (Optional) An integer handle to a marker mask
%   Outputs
%   iRead - The number of data points read or a negative error code
%   ExtMarkers - An array of CED64Markers


% Type = calllib('ceds64int', 'S64ChanType', fhand, chan_id);
Size = calllib('ceds64int', 'S64ItemSize', fhand, chan_id);
current_tick_time = int64(tick1);
Count = 0;
if (Size < 0)
    return;
end

maskcode = -1;

[iOk,Rows,Cols] = CEDS64GetExtMarkInfo(fhand,chan_id);
if iOk < 0
    return
end

s = h__getStruct(n_init);

Wave = Rows * Cols;
InMarker = ced.utils.getCEDMarkerStruct(1);
% InMarker = struct(CEDMarker());
singleptr = zeros(Wave,1,'int16');
% ExtMarkers(iN,1) = CEDWaveMark(); % resize in one operation
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


    [iRead,s3,i16Wave] = calllib('ceds64int', 'S64Read1WaveMark', ...
        fhand, chan_id, InMarker, singleptr, current_tick_time, tick2, maskcode);

    if (iRead > 0)
        Count = Count + 1;
        s(n).time = s3.m_Time;
        s(n).code1 = s3.m_Code1;
        s(n).code2 = s3.m_Code2;
        s(n).code3 = s3.m_Code3;
        s(n).code4 = s3.m_Code4;
        %Didn't think too much about this
        %
        %Can this be optimized as a 3-d array?
        s(n).data = transpose(reshape(i16Wave, Cols, Rows));
        current_tick_time = s3.m_Time + 1;
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
time_cell = num2cell(zeros(n,1));

%TODO: we may want to do a growth strategy ... - yes we need to
%
%Especially if we set no max ...
s = struct('data',[],'time',time_cell,'code1',0,'code2',0,...
    'code3',0,'code4',0);

end