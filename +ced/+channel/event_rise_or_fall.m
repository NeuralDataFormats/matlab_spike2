classdef event_rise_or_fall < ced.channel.channel
    %
    %   Class:
    %   ced.channel.event_rise_or_fall

    %{
        Functions for EventFall and EventRise channels.
        CEDS64IdealRate     Get or set the expected sustained maximum rate
        CEDS64PrevNTime     Search backwards N events
        CEDS64ReadEvents    Read event times as ticks
        CEDS64SetEventChan  Create a new event channel
        CEDS64WriteEvents   Write event times
    %}

    properties
        type
        ideal_rate
    end

    methods
        function obj = event_rise_or_fall(h,chan_id,parent,is_rise)

            obj@ced.channel.channel(h,chan_id,parent);

            obj.fs = 1/parent.time_base;
            obj.max_time = obj.n_ticks/obj.fs;

            if is_rise
                obj.type = "rise";
            else
                obj.type = "fall";
            end
            
            
            %??? CEDS64IdealRate
            %
            %   - this appears to be a buffer setting so
            %   that there is some estimate of how much data will
            %   be coming in

            h2 = obj.h.h;
            obj.ideal_rate = CEDS64IdealRate(h2,obj.chan_id);
        end
        function times = getTimes(obj,varargin)
            %
            %
            %   Optional Inputs
            %   ---------------
            %   max_events : 1e6
            %   time_range : default is entire range
            %   n_init : default 1000
            %       Initial guess for # of events
            %   growth_rate : default 2
            %       If the # of events exceeds our guess, we grow the
            %       output array by this step size.
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

            %This needs to be rewritten for better allocation - low
            %priority
            [n_read,times] = CEDS64ReadEvents(h2,obj.chan_id,in.max_events,t1,t2);

            if n_read < 0
                %TODO: Provide more documentation on the error code
                error('Error reading times')
            end

            times = double(times)/obj.fs;

        end
    end
end