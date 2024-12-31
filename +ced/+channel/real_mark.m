classdef real_mark < ced.channel.channel
    %
    %   Class:
    %   ced.channel.real_mark

    properties
        
    end

    methods
        function obj = real_mark(h,chan_id,parent)
            %
            %   t = ced.channel.wave_mark(h,chan_id,parent)

            obj@ced.channel.channel(h,chan_id,parent); 

            obj.fs = 1/parent.time_base;
            obj.max_time = obj.n_ticks/obj.fs;
        end
        function s = getData(obj,varargin)
            %
            %   Outputs
            %   -------
            %   t

            in.wave_format = 'struct';
            %   - matrix
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
            [n_read,s] = ced.utils.readRealMarkersFast(h2,obj.chan_id,in.max_events,t1,t2,in.n_init,in.growth_rate);
            %toc


            %plot(t,wtf(1,:))

            %Fix time
            
            if n_read < 0
                %TODO: Provide more details
                error('Read error from ced.utils.readWaveMarkersFast')
            end

            switch in.wave_format
                case 'struct'
                    %do nothing
                case 'matrix'
            end

            keyboard
            %{
            tic
            [n_read,s] = CEDS64ReadExtMarks(h2,obj.chan_id, 1e6, 0);
            toc
            %}

                        %{
            [ iRead, vMObj ] = CEDS64ReadExtMarks( fhand, iChan, iN, i64From{, i64To{,
            maskh}} )
            %}


        end
    end
end