function [n_read,s] = readTextMarkersFast(fhand,chan_id,n_max,tick1,tick2,n_init,growth_rate)
%x Extracts data from Text Marker channels
%
%   [n_read,s] = readTextMarkersFast(fhand,chan_id,n_max,tick1,tick2,n_init,growth_rate)
%
%   Rewrite of CEDS64ReadExtMarks. That function uses MATLAB objects for
%   each item and is PAINFULLY slow. Additionally, we've added the ability
%   to grow the structure in a way that helps with memory allocation and
%   speed. For my one example of roughly 43 events this took the read
%   time from 2.4 seconds to 5 ms.
%
%   Inputs
%   ------
%   fhand
%   chan_id
%   n_max
%   tick1
%   tick2
%   n_init
%   growth_rate
%
%   Outputs
%   -------
%   
%   See Also
%   --------
%   ced.channel.text_mark.getData
%
%   Warnings
%   --------
%   If the library changes this function may break


if growth_rate <= 1
    error('Invalid growth rate, needs to be > 1')
end

%What is Size????
Size = calllib('ceds64int', 'S64ItemSize', fhand, chan_id);
current_tick_time = int64(tick1);
Count = 0;
if (Size < 0)
    n_read = -22;
    s = struct;
    return;
end


[iOk,Rows,Cols] = CEDS64GetExtMarkInfo(fhand,chan_id);
if (iOk < 0 || Cols ~= 1)
    %Note, not sure what Cols is ...
    return
end

%??? What is Rows?
string_length = (Rows); % calculate the length of the string

%***********
%   The format here may be critical. This comes from:
%       struct(CEDMarker)
%
%I've hardcoded to avoid the struct warning silencing

InMarker = ced.utils.getCEDMarkerStruct(1);

stringptr =  blanks(string_length+8);

s = h__getStruct(n_init);

maskcode = -1;
for n=1:n_max
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

    %Actual library call
    %------------------------------
    [n_read,s3,sText] = ...
        calllib('ceds64int', 'S64Read1TextMark', fhand, chan_id, InMarker,...
            stringptr, current_tick_time, tick2, maskcode);

    %Logging
    %------------------------------
    if (n_read > 0)
        Count = Count + 1;
        s(n).time = s3.m_Time;
        s(n).code1 = s3.m_Code1;
        s(n).code2 = s3.m_Code2;
        s(n).code3 = s3.m_Code3;
        s(n).code4 = s3.m_Code4;
        s(n).text = sText;
        %I think this is a starting point to look in the function
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
s = struct('text','','time',time_cell,'code1',0,'code2',0,...
    'code3',0,'code4',0);

end
