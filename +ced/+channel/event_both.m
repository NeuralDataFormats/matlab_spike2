classdef event_both < ced.channel.channel
    %
    %   Class:
    %   ced.channel.event_both
    %
    %   This is basically an oscillatory signal

    properties
        ideal_rate
    end

    %?????
    %
    %   Check what n_ticks means for this type of event
    %
    %       - I think it points to the last switching time
    

    methods
        function obj = event_both(h,chan_id,parent)
            obj@ced.channel.channel(h,chan_id,parent);

            obj.fs = 1/parent.time_base;

            %I think this is the last time
            obj.max_time = obj.n_ticks/obj.fs;

            h2 = obj.h.h;
            obj.ideal_rate = CEDS64IdealRate(h2,obj.chan_id);
        end
        function s = getTimes(obj,varargin)
            %
            %
            %   Outputs
            %   -------
            %   return_format:
            %       - 'times'
            %           - .times : times of all events
            %           - .start_level 
            %               Note this is the rawest form of returning
            %               the data.
            %       - 'time_series1'
            %           - .x
            %           - .y
            %               In addition to the times the level of the new
            %               value is returned.
            %       - 'time_series2'
            %           - .x
            %           - .y
            %                Each is replicated so that you can do plot(x,y)
            %       - 'switch_times'
            %           - .rise_times
            %           - .fall_times
            %       - 'starts_and_stops'
            %           - .start_high
            %           - .stop_high
            %           - .start_low
            %           - .stop_low
            %           - .output_trimmed - this indicates that we may not
            %                   have the full picture 
            %        

            in.return_format = 'times';
            in.max_events = 1e6;
            in.time_range = [];
            in.n_init = 1000;
            in.growth_rate = 2;
            in = ced.sl.in.processVarargin(in,varargin);

            if isempty(in.time_range)
                %
                %   Note, I think obj.max_time is
                %   the last event time
                in.time_range = [0 obj.max_time];
                end_time = obj.parent.n_seconds;
            else
                end_time = obj.time_range(2);
            end

            sample_range = round(in.time_range*obj.fs);
            %Bounds check ...
            if sample_range(1) < 0 
                error('error, invalid time requested')
            end
            
            %TODO: This is an unfair check (I think) if we ask
            %for a long period of time and we have few events early on
            %
            %i.e., this seems to only be valid for the last event, but
            %the user shouldn't need to first check if there time window
            %is within range of the last event
            if sample_range(2) > obj.n_ticks
                error('error, invalid time requested')
            end

            %Request is non-inclusive at the end so to be inclusive we
            %add 1 to the sample count
            sample_range(2) = sample_range(2) + 1;
            
            t1 = sample_range(1);
            t2 = sample_range(2);
            h2 = obj.h.h;

            %[ iRead, vi64T, iLevel ] = CEDS64ReadLevels( fhand, iChan, iN, i64From{i64UpTo} )
            %
            %   TODO: rewrite for better allocation
            [iRead,vi64T,iLevel] = CEDS64ReadLevels(h2,obj.chan_id,in.max_events,t1,t2);

            iLevel = double(iLevel);
            if iRead < 0
                %TODO: Provide more documentation on the error code
                error('Error reading times')
            end

            %Conversion from ticks to sampling rate
            times = double(vi64T)./obj.fs;
            n_events = length(times);

            %Note, if you want to know stop time, the stop time may 
            %not be valid if we quit early due to maxing out the # of
            %events
            if n_events == in.max_events
                hit_event_max = true;
                end_time = times(end);
            else
                hit_event_max = false;
            end

            odd_number_events = mod(n_events,2) == 1;
            
            s = struct;
            s.hit_event_max = hit_event_max;
            switch in.return_format
                case 'times'
                    s.times = times;
                    s.start_level = iLevel;
                case 'time_series1'
                    s.x = times';
                    n_full = floor(length(times)/2);
                    n_extra = length(times) - n_full*2;
                    y2 = [1-iLevel iLevel];
                    if n_extra == 1
                        s.y = [repmat(y2,1,n_full) y2(1)];
                    else
                        s.y = repmat(y2,1,n_full);
                    end
                case 'time_series2'
                    %# of events is
                    %
                    % - each time is 2x
                    % - first and last is another 2x
                    n_xy = 2*length(times) + 2;
                    x = zeros(1,n_xy);
                    y = zeros(1,n_xy);
                    x(1) = in.time_range(1);
                    y(1) = iLevel;
                    j = 2;
                    y2 = [iLevel 1-iLevel];
                    %TODO: Does this work if we have no times?
                    for i = 1:length(times)
                        x(j:j+1) = times(i);
                        y(j:j+1) = y2;
                        y2 = 1 - y2;
                        j = j + 2;
                    end
                    x(end) = end_time;
                    y(end) = y(end-1);
                    s.x = x;
                    s.y = y;
                case 'switch_times'
                    if iLevel == 1
                        s.rise_times = times(2:2:end);
                        s.fall_times = times(1:2:end);
                    else
                        s.rise_times = times(1:2:end);
                        s.fall_times = times(2:2:end);
                    end
                case 'starts_and_stops'
                    if iLevel == 1
                        %if odd, ends low
                        %if even, ends high
                        if odd_number_events
                            low_last = end_time;
                            high_last = [];
                        else
                            low_last = [];
                            high_last = end_time;
                        end
                    else
                        %if odd, ends high
                        %if even, ends low
                        if odd_number_events
                            low_last = [];
                            high_last = end_time;
                        else
                            low_last = end_time;
                            high_last = [];
                        end
                    end

                    if iLevel == 1
                        s.start_high = [in.time_range(1); times(2:2:end)];
                        s.stop_high = [times(1:2:end); high_last];
                        s.start_low = times(1:2:end);
                        s.stop_low = [times(2:2:end); low_last];
                    else
                        s.start_high = [times(1:2:end)];
                        s.stop_high = [times(2:2:end); high_last];
                        s.start_low = [in.time_range(1); times(2:2:end)];
                        s.stop_low = [times(1:2:end); low_last];
                    end
            end
        end
    end
end