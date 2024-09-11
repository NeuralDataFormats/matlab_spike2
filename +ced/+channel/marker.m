classdef marker < ced.channel.channel
    %
    %   Class:
    %   ced.channel.marker
    %
    %   What is the marker?
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
        function times = getTimes(obj,varargin)
            %
            %
            %   Optional Inputs
            %   ---------------
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

            in.max_events = 1e6;
            in.time_range = [0 obj.max_time];
            in.n_init = 1000;
            in.growth_rate = 2;
            in = ced.sl.in.processVarargin(in,varargin);

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
            
            if n_read < 0
                %TODO: Provide more documentation on the error code
                error('Error reading times')
            end
            
            %toc

            %keyboard

            times = [s.m_Time];
            %TODO: At some point we may want to expose the codes

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
