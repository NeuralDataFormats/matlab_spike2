classdef marker < ced.channel.channel
    %
    %   Class:
    %   ced.channel.marker
    %
    %   What is the marker?
    %
    %   What is the difference between a marker and an event rise or fall?
    %
    %
    %   CEDS64ReadEvents
    %   CEDS64ReadMarkers
    %
    %   See Also
    %   --------
    %   ced.channel.adc
    %   ced.channel.text_mark

    properties

    end

    methods
        function obj = marker(h,chan_id,parent)
            obj@ced.channel.channel(h,chan_id,parent);

            obj.fs = 1/parent.time_base;
            obj.max_time = obj.n_ticks/obj.fs;
        end
        function s = getData(obj,in)
            %
            %
            %   Outputs
            %   -------
            %   s : struct
            %       if 'collapse_struct' is true:
            %           .times
            %           .c1
            %           .c2
            %           .c3
            %           .c4
            %       if 'collapse_struct' is false:
            %           .time
            %           .c1
            %           .c2
            %           .c3
            %           .c4
            %
            %
            %   Optional Inputs
            %   ---------------
            %   to_char
            %   collapse_struct : default true
            %   max_events : default 1e6
            %   time_range : default [0 obj.max_time]
            %   n_init : default 1000
            %   growth_rate : default 2
            %
            %
            %
            %   Improvements
            %   ------------
            %   1. throw warning, but make optional?
            %

            arguments
                obj ced.channel.marker
                in.collapse_struct = true
                in.to_char = obj.name == "Keyboard"
                in.time_range (1,2) {mustBeNumeric} = [0 obj.max_time]
                in.n_init (1,1) {mustBeNumeric}= 1000
                in.growth_rate (1,1) {mustBeNumeric} = 2
                in.max_events = 1e6
            end

            %in = ced.sl.in.processVarargin(in,varargin);

            sample_range = round(in.time_range*obj.fs);
            %Bounds check ...
            if sample_range(1) < 0
                error('error, invalid time requested')
            end
            if sample_range(2) > obj.n_ticks
                error('error, invalid time requested')
            end

            %Request is non-inclusive at the end so to be inclusive we
            %add 1 to the sample count
            sample_range(2) = sample_range(2) + 1;

            t1 = sample_range(1);
            t2 = sample_range(2);
            h2 = obj.h.h;

            %tic
            [n_read,s] = ced.utils.readMarkersFast(...
                h2,obj.chan_id,in.max_events,t1,t2,in.n_init,in.growth_rate);
            %toc
            %{
            tic
            for i = 1:100
            [ iRead, cMarkers ] = CEDS64ReadMarkers( h2, obj.chan_id,100000,0);
            end
            toc/100
            %}

            if n_read < 0
                %TODO: Provide more documentation on the error code
                error('Error reading times')
            end

            if in.collapse_struct
                s2 = struct;
                s2.times = [s.m_Time]/obj.fs;
                s2.c1 = [s.m_Code1];
                s2.c2 = [s.m_Code2];
                s2.c3 = [s.m_Code3];
                s2.c4 = [s.m_Code4];
                if in.to_char
                    s2.c1 = char(s2.c1);
                    s2.c2 = char(s2.c2);
                    s2.c3 = char(s2.c3);
                    s2.c4 = char(s2.c4);
                end
                s = s2;
            else

                %https://www.mathworks.com/matlabcentral/answers/273955-how-do-i-rename-fields-of-a-structure-array
                old_names = {'m_Time','m_Code1','m_Code2','m_Code3','m_Code4'};
                new_names = {'time','c1','c2','c3','c4'};
                N = numel(s);
                for k = 1:numel(old_names)
                    old_name = old_names{k};
                    new_name = new_names{k};
                    if k == 1
                        temp = {s.(old_name)};
                        temp2 = cellfun(@(x) x/obj.fs,temp,'un',0);
                        [s2(1:N).(new_name)] = deal(temp2{:});
                    else
                        if in.to_char
                            temp = {s.(old_name)};
                            temp2 = cellfun(@char,temp,'un',0);
                            [s2(1:N).(new_name)] = deal(temp2{:});
                        else
                            [s2(1:N).(new_name)] = deal(s.(old_name));
                        end
                    end
                end
                s = s2;
            end

            %This is the naive call
            %-----------------------------------------
            % tic
            % iN = 1e4; %How many to allocate
            % i64From = 0;
            %
            % [n_reads, cMarkers ] = CEDS64ReadMarkers(h2, obj.chan_id, ...
            %     iN, i64From);
            % toc
        end
    end
end

function h__

end



%{
function [ iRead, i64Times ] = CEDS64ReadEvents( fhand, iChan, iN, i64From, i64To, maskh )
%CEDS64READEVENTS Reads the first iN events from channel iChan between i64From and i64To
%   [ iRead, i64Times ] = CEDS64ReadEvents( fhand, iChan, iN, i64From {, i64To {, maskh}} )
%   Inputs
%   fhand - An integer handle to an open file
%   iChan - A channel number for a Waveform or Realwave channel
%   iN - The maximum number of events to read
%   i64From - The time in ticks of the earliest time you want to read
%   i64To - (Optional) The time in ticks of the latest time you want to
%   read. If not set or set to -1, read to the end of the channel
%   maskh - (Optional) An integer handle to a marker mask
%   Outputs
%   iRead - The number of events points read or a negative error code
%   i64Times - An array of 64-bit integers conatining the times in ticks of the events
%}

%{
function [ iRead, cMarkers ] = CEDS64ReadMarkers( fhand, iChan, iN, i64From, i64To, maskh )
%CEDS64READMARKERS Reads marker data from a marker or extended marker channels
%   [ iRead, cMarkers ] = CEDS64ReadMarkers( fhand, iChan, iN, i64From {, i64To {, maskh}} )
%   Inputs
%   fhand - An integer handle to an open file
%   iChan - A channel number for an event or extended event channel
%   iN - The maximum number of data points to read
%   i64From - The time in ticks of the earliest time you want to read
%   i64To - (Optional) The time in ticks of the latest time you want to
%   read. If not set or set to -1, read to the end of the channel
%   maskh - (Optional) An integer handle to a marker mask
%   Outputs
%   iRead - The number of data points read
%   cMarkers - An array of CED64Markers
%}
