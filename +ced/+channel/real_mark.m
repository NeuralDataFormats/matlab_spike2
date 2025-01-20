classdef real_mark < ced.channel.channel
    %
    %   Class:
    %   ced.channel.real_mark
    %
    %   See Also
    %   --------
    %   ced.channel.marker
    %   ced.channel.wave_mark

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
        function s = getData(obj,in)
            %
            %   Outputs
            %   -------
            %   s 
            %
            %   Optional Inputs
            %   ---------------
            %   
            %
            %   See Also
            %   --------
            %   ced.channel.marker

            arguments
                obj ced.channel.real_mark
                in.return_format {mustBeMember(in.return_format,{'struct','struct2'})} = 'struct';
                in.max_events (1,1) {mustBeNumeric} = 1e6
                in.time_range (1,2) {mustBeNumeric} = [0 obj.max_time]
                in.n_init (1,1) {mustBeNumeric} = 1000
                in.growth_rate (1,1) {mustBeNumeric} = 2
            end

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

            %{
            %Original version
            %-----------------
            %           CEDS64ReadExtMarks( fhand, iChan, iN,  i64From, i64To, maskh )
            [n_read2,s2] = CEDS64ReadExtMarks(h2,obj.chan_id,in.max_events,t1,t2)
            %}

            if n_read < 0
                %TODO: Provide more details
                error('Read error from ced.utils.readWaveMarkersFast')
            end

            %- No data scaling needed
            %- Time scaling
            temp = {s.time};
            temp2 = cellfun(@(x) x/obj.fs,temp,'un',0);
            [s.time] = deal(temp2{:});
            
            switch in.return_format
                case 'struct'
                    %do nothing
                case 'struct2'
                    s2 = struct;
                    temp = {s.data};
                    %Do we ever have a matrix? Why is our example [2 x 1]
                    %and not a scalar?
                    %
                    %Do we ever have more than one column?
                    s2.data = cat(3,temp{:});
                    s2.time = [s.time];
                    s2.code1 = [s.code1];
                    s2.code2 = [s.code2];
                    s2.code3 = [s.code3];
                    s2.code4 = [s.code4];
                    s = s2;
                otherwise
                    error('Unrecognized option')
            end

        end
    end
end