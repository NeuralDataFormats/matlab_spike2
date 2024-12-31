function [n_read,c_markers] = readMarkersFast(fhand,chan_id,n_max,tick1,tick2,n_init,growth_rate)
%
%   [n_read,c_markers] - ced.utils.readMarkersFast   
%           (fhand,chan_id,n_max,tick1,tick2,n_init,growth_rate)
%
%
%   See Also
%   --------
%   ced.channel.marker
%   CEDS64ReadMarkers

if growth_rate <= 1
    error('Invalid growth rate, needs to be > 1')
end

marker_output = ced.utils.getCEDMarkerStruct(n_init);

%Unlike similar functions this does a bunch of reads at once
%rather than reading one element
%
%   This probably restricts our read size
lib_buffer = ced.utils.getCEDMarkerStruct(n_init);
outmarkerpointer = libpointer('S64Marker', lib_buffer);

%We may eventually adjust this ...
maskcode = -1;

% n_read = calllib('ceds64int', 'S64ReadMarkers', fhand, chan_id, ...
%     outmarkerpointer , n_init, tick1, tick2, maskcode);

%{
outmarkerpointer
- plus - adjusts which value you are indexing
- value - gets the value
%}

n_add = n_init;
count = 0;
current_tick_time = tick1;

for n=1:n_max
    if (current_tick_time >= tick2)
        break;
    end

    %Grow structure if we are going to exceed allocated size
    %------------------------------
    if count > length(marker_output)
        n_new = ceil(growth_rate*length(s));
        n_add = n_new - length(s);
        if n_add < 10
            %Ideally this code is never run, but just in case ...
            n_add = 10;
        end
        s2 = ced.utils.getCEDMarkerStruct(n_add);
        marker_output = [marker_output; s2]; %#ok<AGROW>

        temp_buffer = ced.utils.getCEDMarkerStruct(n_add);
        outmarkerpointer = libpointer('S64Marker', temp_buffer);
    end

    %Actual library call
    %------------------------------
    n_read = calllib('ceds64int', 'S64ReadMarkers', fhand, chan_id, ...
        outmarkerpointer , n_add, current_tick_time, tick2, maskcode);


    %outmarkerpointer : lib.pointer    

    % [n_read,s3,sText] = ...
    %     calllib('ceds64int', 'S64Read1TextMark', fhand, chan_id, InMarker,...
    %         stringptr, current_tick_time, tick2, maskcode);

    %Logging
    %------------------------------

    i1 = 0;
    i2 = n_read-1;

    if (n_read > 0)
        for m = i1:i2
            count = count + 1;
            temp = (outmarkerpointer + m);
            %temp : lib.pointer
            %temp.value -> yields a structure with fields:
            %m_Time
            %m_Code1
            %m_Code2
            %m_Code3
            %m_Code4
        
            %Note, we could do the renaming here:
            %temp2 = temp.value
            %s.time = temp2.m_Time
            %s.code1 = temp2.m_Code1
            %etc. 

            marker_output(count) = temp.value;
        end
        current_tick_time = marker_output(count).m_Time + 1;
    else
        break;
    end
end

marker_output(count+1:end) = [];

c_markers = marker_output;

end

function s = h__getStruct(n)
time_cell = num2cell(zeros(n,1));

%TODO: we may want to do a growth strategy ... - yes we need to
%
%Especially if we set no max ...
s = struct('text','','time',time_cell,'code1',0,'code2',0,...
    'code3',0,'code4',0);

end

