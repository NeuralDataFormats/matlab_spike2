classdef text_mark < ced.channel.channel
    %
    %   Class:
    %   ced.channel.text_mark
    %
    %   A Text Marker channel contains discrete points in times. Each point
    %   in time contains:
    %   - the time value itself
    %   - a string (e.g., a comment)
    %   - 4 codes - ??? What are these?

    properties

    end

    methods
        function obj = text_mark(h,chan_id,parent)
            %
            %   t = ced.channel.text_mark(h,chan_id,parent)

            obj@ced.channel.channel(h,chan_id,parent); 

            obj.fs = 1/parent.time_base;
            obj.max_time = obj.n_ticks/obj.fs;
        end
        function t = getData(obj,varargin)
            %CEDS64ReadExtMarks
            %{

            function [ iRead, ExtMarkers ] = CEDS64ReadExtMarks( fhand, iChan, iN,  i64From, i64To, maskh )
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
            %}

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

            %This call is really slow. Why doesn't the file track 
            % state = ced.utils.turnStructWarningOn;
            % tic
            % [a,b] = CEDS64ReadExtMarks(obj.h2,obj.chan_id,in.max_events,t1,t2);
            % toc
            % ced.utils.restoreWarningState(state);

            %New code
            %----------------------------------
            % tic
            [n_reads,s] = ced.utils.readTextMarkersFast(obj.h2,obj.chan_id,...
                in.max_events,t1,t2,in.n_init,in.growth_rate);
            % toc
            if n_reads < 0
                error_code = n_reads;
                %TODO: Provide more info on the error code
                error('An error occurred when trying to read the Text Marker data, failed with error code: %d',error_code)
            end
            
            t = struct2table(s);
            t.time = t.time./obj.fs;

        end
    end
end