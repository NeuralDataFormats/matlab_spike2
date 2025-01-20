classdef wave_mark < ced.channel.channel
    %
    %   TODO: consider inheriting from an event channel
    %   
    %   Class:
    %   ced.channel.wave_mark
    %
    %   A Wave Marker consists of events and snippets (sampled data over
    %   a brief time window)
    %
    %   See Also
    %   --------
    %   ced.channel.marker
    %   

    properties

    end

    methods
        function obj = wave_mark(h,chan_id,parent)
            %
            %   t = ced.channel.wave_mark(h,chan_id,parent)

            obj@ced.channel.channel(h,chan_id,parent); 

            obj.fs = 1/parent.time_base;
            obj.max_time = obj.n_ticks/obj.fs;
        end
        function s = getData(obj,in)
            %
            %
            %
            %   Outputs
            %   -------
            %   t
            %
            %   Optional Inputs
            %   ---------------
            %   return_format :
            %       - struct
            %       - matrix1 - each trace is in its own matrix
            %       - matrix2 - [samples x trace x time]
            %
            %   Improvements
            %   ------------
            %   Handle returning codes ...
            %
            %   See Also
            %   --------
            %   ced.channel.marker

            arguments
                obj ced.channel.wave_mark
                in.return_format {mustBeMember(in.return_format,{'struct','matrix1','matrix2'})} = 'struct';
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
            [n_read,s] = ced.utils.readWaveMarkersFast(h2,obj.chan_id,in.max_events,t1,t2,in.n_init,in.growth_rate);

            %{
            %format: [ iRead, vMObj ] = CEDS64ReadExtMarks( fhand, iChan, iN, i64From{, i64To{, maskh}} )
            tic
            [ iRead, ExtMarkers ] = CEDS64ReadExtMarks( h2, obj.chan_id, in.max_events,  t1, t2 )
            toc
            %}

            %toc

            %{
            %Example response:
                data: [32×4 int16]
                time: 105100
               code1: 0
               code2: 0
               code3: 0
               code4: 0 
            %}

            if n_read < 0
                %TODO: Provide more details
                error('Read error from ced.utils.readWaveMarkersFast')
            end

            %From the PDF documentation
            %user value = (16-bit value) * scale /6553.6 + offset
            temp_data = {s.data};
            switch in.return_format
                case 'struct'
                    %Scale output
                    %do nothing
                    sc2 = obj.scale/6553.6;
                    off = obj.offset;
                    scaled_data = cellfun(@(x) double(x)*sc2 + off,temp_data,'un',false);
                    [s.data] = deal(scaled_data{:});
                case 'matrix1'
                    sc2 = obj.scale/6553.6;
                    off = obj.offset;
                    n_traces = size(s(1).data,2);
                    d = cell(1,n_traces);
                    
                    for i = 1:n_traces
                        temp = cellfun(@(x) double(x(:,i))*sc2 + off,temp_data,'un',false);
                        d{i} = [temp{:}];
                    end

                    s2 = struct;
                    s2.data = d;
                    s2.times = [s.time];
                    s = s2;
                case 'matrix2'
                    temp_data = {s.data};
                    data = cat(3,temp_data{:});
                    scaled_data = double(data)*obj.scale/6553.6 + obj.offset;
                    s2 = struct;
                    s2.data = scaled_data;
                    s2.times = [s.time];
                    s = s2;
            end
        end
    end
end