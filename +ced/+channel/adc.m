classdef adc < ced.channel.channel
    %
    %   Class:
    %   ced.channel.adc
    %
    %   See Also
    %   --------
    %   ced.file

    properties

    end

    methods
        function obj = adc(h,chan_id,parent)
            obj@ced.channel.channel(h,chan_id,parent);

            %Is this only true for waveform?
            %Floor? ceil? round?
            obj.n_ticks = ceil(parent.n_ticks/obj.chan_div);
        end
        function d = getData(obj,varargin)
            %
            %
            %
            %   Output
            %   ------
            %   s : structure array
            %       .data
            %       .first_sample
            %       .last_sample
            %       .start_time
            %       .n_samples
            %       .time - Note this is only returned if
            %               'return_time_arrays' is true
            %           
            %   Note, a channel can have multiple gaps. Unfortunately the
            %   only way to determine if there is a gap is to read the data
            %   and to find gaps. 
            %
            %   Because gaps exist we return the data as a structure array.
            %   If there are no gaps then your structure array will always
            %   have a single element.
            %
            %
            %   Optional Inputs
            %   ---------------
            %   data_format: default 'data'
            %       - 'int16'
            %       - 'single'
            %       - 'double'
            %       - 'data' - return data object if code is available
            %                  otherwise return double
            %   time_format: default 'datetime'
            %       - 'datetime' - Note if the file does not have a valid
            %                      starting datetime this will return data
            %                      in the format of a duration array
            %       - 'numeric'  - the returned array will be a numeric
            %                      array with units of seconds. 
            %
            %   Note, if 'datetime' is selected and returning a data object
            %   the starting datetime in that object will be of MATLAB type
            %   'datetime' rather than numeric.
            %
            %   time_range
            %
            %   Improvements
            %   ------------
            %   - complete documentation

            %{
            Example 1
            ---------
            

            Example 2
            ---------
            %Has multiple waveforms ...
            name = 'Demo1.smr';
            root = "D:\Data\Mickle\sample_files";
            file = ced.file(fullfile(root,name));
    
            d = file.waveforms(1).getData();
            clf
            hold on
            for i = 1:length(d)
                plot(d(i).time,d(i).data)
            end
            hold off



            %}

            in.n_snips_init = 1e4;
            in.n_snips_growth_rate = 2; %NYI
            in.return_time_arrays = true;
            in.data_format = 'double';
            in.time_format = 'datetime';
            in.time_range = [];
            in = ced.sl.in.processVarargin(in,varargin);

            if in.data_format == "data"
                if isempty(which('sci.time_series.data'))
                    in.data_format = 'double';
                end
            end
            if in.return_time_arrays
                %Early check that the format is allowed
                switch in.time_format
                    case 'datetime'
                    case 'numeric'
                    otherwise
                        error('Unrecognized "time_format" option: %s',in.time_format)
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

            %s1 - first sample to get, 0 based
            %s2 - stop sample id (0 based)
            %       - or last sample to get (1 based)

            output = cell(1,in.n_snips_init);
            I = 0;
            while true
                s = h__DataRetrieval(obj,s1,s2,in,n_samples);
                if s.n_samples == 0
                    %No more data left, stop asking!!
                    break
                else
                    %Save the data we extracted, but keep in mind
                    %we may have read all that we asked for
                    I = I + 1;

                    %Grow the output array if needed
                    %----------------------------------
                    if I > length(output)
                        new_length = ceil(length(output) * in.growth_rate);
                        if new_length <= length(output)
                            %Hack on growth ...
                            new_length = length(output) + 10;
                        end
                        output{new_length} = []; % Expanding cell array
                    end
                    
                    %Data storage and check for completeness
                    %-----------------------------------------
                    output{I} = s;
                    s1 = s.last_sample_id;
                    if s1 >= s2
                        break
                    end
                end
            end

            %TODO: We may want to do structure copies rather than
            %concetantion of scalars
            %
            %   output(I) = s  %Where output is a structure array
            %
            %   rather than this - not sure of efficiency here
            d = [output{1:I}];

        end
    end
end

function s = h__DataRetrieval(obj,s1,s2,in,n_samples)

%Conversion from samples to ticks
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

%Note, ints generally cause bugs in MATLAB so let's convert to double
%
%   ASSUMES: we don't have super large data > 9e15 elements
start_sample = double(start_tick/obj.chan_div + 1);
last_sample = double(start_sample + length(data)-1);
start_time = start_sample/obj.fs;
dt = double(1/obj.fs);
n_samples_out = length(data);

%From the PDF documentation
%user value = (16-bit value) * scale /6553.6 + offset

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
        %Note, we have a check earlier that switches the 'data_format'
        %if this library does not exist
        data = double(data)*(obj.scale/6553.6) + obj.offset;
        if in.time_format == "datetime"
            start_datetime = obj.parent.start_datetime;
            if isnat(start_datetime)
                start_datetime = 0;
            end
        else
            %TODO: Could be datenum as well ...
            start_datetime = 0;
        end

        time = sci.time_series.time(dt,n_read,...
            'start_offset',start_time,...
            'start_datetime',start_datetime);

        data = sci.time_series.data(data,time,'units',obj.units,'y_label',obj.name);
    otherwise
        %TODO: Move this check earlier
        error('Unrecognized "data_format" option')
end

s.data = data;
s.first_sample_id = start_sample;
s.last_sample_id = last_sample;
s.start_time = start_time;
s.n_samples = n_samples_out;

if in.return_time_arrays
    s.time = (start_sample:last_sample)./obj.fs;
    switch in.time_format
        case 'datetime'
            start_datetime = obj.parent.start_datetime;
            if isnat(start_datetime)
                s.time = seconds(s.time);
            else
                s.time = start_datetime + seconds(s.time);
            end
        case 'numeric'
            %
            %s.time = (start_sample:last_sample)./obj.fs;
        otherwise
            %Check is earlier so getting here indicates a bug in my code
            error("Unrecognized 'time_format' option - bug in Jim's code")
    end
end

end