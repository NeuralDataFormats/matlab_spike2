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
        function d = getData(obj,in)
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
            %   data_format: default 'double'
            %       - 'int16'
            %       - 'single'
            %       - 'double'
            %       - 'data_object' - return data object if code is available
            %                  otherwise return double
            %   time_format: default ''
            %       - ''         - no time returned
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

            arguments
                obj ced.channel.adc
                in.n_init (1,1) {mustBeNumeric} = 1e4
                in.growth_rate (1,1) {mustBeNumeric} = 2
                in.time_range (:,:) {h__sizeCheck(in.time_range)} = []
                in.sample_range (:,:) {h__sizeCheck(in.sample_range)} = []
                in.time_format {mustBeMember(in.time_format,{'none','numeric','datetime'})} = 'numeric'
                in.return_format {mustBeMember(in.return_format,{'int16','single','double','data_object'})} = 'double'    
            end

            if in.return_format == "data_object" && isempty(which('sci.time_series.data'))
                in.return_format = 'double';
            end

            n_samples = obj.n_ticks;

            if ~isempty(in.time_range)
                s1 = round(in.time_range(1)*obj.fs);
                if s1 < 0
                    error('Invalid time range requested, t1 too early')
                end

                %Add 1 to make time inclusive - call to
                %their function is not inclusive
                %
                %   requesting 0 to 10 returns 0 to 9
                s2 = round(in.time_range(2)*obj.fs)-1;
                if s2 >= obj.n_ticks
                    error('Invalid time range requested, t2 too late')
                end
                if s1 > s2
                    error('Invalid time range requested, t1 > t2')
                end
            elseif ~isempty(in.sample_range)
                s1 = in.sample_range(1);
                s2 = in.sample_range(2);
                if s1 < 1
                    error('Invalid time range requested, s1 too early')
                end
                %Fix inclusivity request, add 1
                %s2 = s2 + 1;
                if s2 > obj.n_ticks
                    error('Invalid sample range requested, s2 too late')
                end
                if s1 > s2
                    error('Invalid sample range requested, s1 > s2')
                end
                s1 = s1-1;
                s2 = s2-1;
            else
                s1 = 0;
                s2 = n_samples-1;
            end

            %s1 - first sample to get, 0 based
            %s2 - stop sample id (0 based)
            %       - or last sample to get (1 based)


            %Note, waveforms can have pauses. Whether there are pauses in
            %the data is not obvious based on any header information. Thus 
            %we ready the requested range. If any pauses are encountered
            %this is handled. 
            % 
            %I believe if we request data over the range of a pause it
            %returns only the data up to the pause. If our first sample
            %is in a pause, it advances to the next sample. Thus for
            %example you might have something like this:
            %
            %   data  xxxxx   xxxxxxx  xxxxxxx
            %         1                            2 (1 start, 2 stop)
            %   returned
            %         xxxxx
            %   next       1                       2
            %   returned
            %                 xxxxxxx
            %   next                 1             2
            %   returned
            %                          xxxxxxx
            %   next                          1    2
            %   returned - no data, must be done

            output = cell(1,in.n_init);
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

            d = [output{1:I}];

        end
    end
end
function h__sizeCheck(var)
if ~(isequal(size(var),[1 2]) || isempty(var))
    error('Variable must be empty or have size [1 x 2]')
end
end

function s = h__DataRetrieval(obj,s1,s2,in,n_samples)

%Conversion from samples to ticks
s1_in = s1*obj.chan_div;
s2_in = s2*obj.chan_div;

%Request may not be inclusive
s2_in = s2_in + 1;

%Data call
%-------------------------
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
start_sample = double(start_tick/obj.chan_div) + 1;
last_sample = double(start_sample + length(data)-1);
start_time = start_sample/obj.fs;
dt = double(1/obj.fs);
n_samples_out = length(data);

%From the PDF documentation
%user value = (16-bit value) * scale /6553.6 + offset

%CEDS64ReadWaveS Read waveform data as 16-bit integers
%CEDS64ReadWaveF Read waveform

switch in.return_format
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
    case 'data_object'
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

if in.time_format == "none" || in.return_format == "data_object"
    s.time = [];
    %- If returning a data object, part of the point of the object is to 
    % not return a second array of time points (i.e., to save memory)
    %- "" means 
else
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