classdef adc < ced.channel.channel
    %
    %   Class:
    %   ced.channel.adc

    properties
        
    end

    methods
        function obj = adc(h,chan_id,parent)
            obj@ced.channel.channel(h,chan_id,parent); 

            %Is this only true for waveform?
            %Floor? ceil? round?
            obj.n_ticks = ceil(parent.n_ticks/obj.chan_div);
        end
        function [data,time] = getData(obj,varargin)
            %
            %
            %
            %   Output
            %   ------
            %   data_format
            %       - 'int16'
            %       - 'single'
            %       - 'double'
            %       - 'data'
            %   time_format:
            %       - 'datetime'
            %       - 'numeric'
            %
            %   Improvements
            %   ------------
            %   

            in.data_format = 'data';
            in.time_format = 'datetime';
            in.time_range = [];
            in = ced.sl.in.processVarargin(in,varargin);

            if in.data_format == "data"
                if isempty(which('sci.time_series.data'))
                    in.data_format = 'double';
                end
            end

            %From the PDF documentation
            %user value = (16-bit value) * scale /6553.6 + offset

            %CEDS64ReadWaveS Read waveform data as 16-bit integers
            %CEDS64ReadWaveF Read waveform

            %n_samples = ceil(obj.max_time*obj.fs);
            n_samples = obj.n_ticks;

            if ~isempty(in.time_range)
                %TODO: Verify time range
                s1 = round(in.time_range(1)*obj.fs);
                if s1 < 0 
                    error('Invalid time range requested')
                end
                %Add 1 to make time inclusive - call to 
                %their function is not inclusive
                s2 = round(in.time_range(2)*obj.fs) + 1;
                if s2 > obj.n_ticks
                    error('Invalid time range requested')
                end
                if s1 > s2
                    error('Invalid time range requested')
                end
            else
                s1 = 0;
                s2 = n_samples;
            end

            s1_in = s1*obj.chan_div;
            s2_in = s2*obj.chan_div;

            %Data call
            %-------------------------
            %
            %Request is in ticks, which is not samples
            %thus the scaling above by chan_div
            %
            %Output is of type int16
            [n_read,data,start_tick] = CEDS64ReadWaveS(obj.h2,obj.chan_id,...
                n_samples,s1_in,s2_in);

            %- Not using this ... see below for why
            %- Leaving this in place for testing if desired
            % [n_read,data,start_time] = CEDS64ReadWaveF(obj.h2,obj.chan_id,...
            %     n_samples,s1,s2);

            start_sample = start_tick/obj.chan_div;
            start_time = double(start_sample/obj.fs);
            dt = double(1/obj.fs);

            %Verification, just in case ...
            if s1 ~= start_sample
                error('Unexpected start time given request')
            end
            if n_read ~= (s2 - s1)
                error('Unexpected # of samples returned given request')
            end
            if n_read ~= length(data)
                error('Unexpected # of samples returned given request')
            end

            switch in.data_format
                case 'int16'
                    %Done
                case 'single'
                    %For this we could use CEDS64ReadWaveF but I found
                    %it to be a bit slower
                    data = single(data)*(obj.scale/6553.6) + obj.offset;
                case 'double'
                    %Note, we are not using CEDS64ReadWaveF here because
                    %the output value is single, and the single to double
                    %conversion is worse than the conversion from
                    %int16 to double
                    data = double(data)*(obj.scale/6553.6) + obj.offset;
                case 'data'
                    data = double(data)*(obj.scale/6553.6) + obj.offset;
                    
                    time = sci.time_series.time(dt,n_read,'start_offset',start_time);
                    data = sci.time_series.data(data,time,'units',obj.units,'y_label',obj.name);
                otherwise
                    %TODO: Move this check earlier
                    error('Unrecognized "data_format" option')
            end

            if nargout == 2
                %JAH: At this point ...
                time = [];
                switch in.time_format
                    case 'datetime'
                    
                    case 'numeric'

                    otherwise
                        %TODO: Move this check earlier
                        error('Unrecognized "data_format" option')
                end
            end
        end
    end
end