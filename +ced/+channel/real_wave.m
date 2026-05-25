classdef real_wave < ced.channel.channel
    %
    % Class:
    %   ced.channel.real_wave
    %
    % RealWave channels are continuous waveform channels stored as
    % floating-point values rather than int16 ADC values.
    %
    % See Also
    % --------
    % ced.channel.adc
    % ced.file

    properties
        n_samples
    end

    methods
        function obj = real_wave(h, chan_id, parent)
            %
            % obj = ced.channel.real_wave(h, chan_id, parent)

            obj@ced.channel.channel(h, chan_id, parent);

            % Same convention as adc:
            % obj.n_ticks is the channel max time in file ticks.
            % obj.chan_div converts sample index <-> file ticks.
            obj.n_ticks = ceil(parent.n_ticks / obj.chan_div);
            obj.n_samples = obj.n_ticks;
        end

        function d = getData(obj, in)
            %
            % d = obj.getData()
            % d = obj.getData(name=value)
            %
            % Outputs
            % -------
            % d : structure array
            %   .data
            %   .first_sample_id
            %   .last_sample_id
            %   .start_time
            %   .n_samples
            %   .time
            %
            % Optional Inputs
            % ---------------
            % time_format:
            %   'none'
            %   'numeric'
            %   'datetime'
            %
            % return_format:
            %   'single'
            %   'double'
            %   'data_object'
            %
            % time_range:
            %   [start stop] in seconds
            %
            % sample_range:
            %   [start stop], 1-based inclusive sample indices
            %
            % Notes
            % -----
            % RealWave values are already floating-point user values, so
            % unlike adc.m, no int16 scale/offset conversion is applied.

            arguments
                obj ced.channel.real_wave
                in.n_init (1,1) {mustBeNumeric} = 1e4
                in.growth_rate (1,1) {mustBeNumeric} = 2
                in.time_range (:,:) {h__sizeCheck_real_wave(in.time_range)} = []
                in.sample_range (:,:) {h__sizeCheck_real_wave(in.sample_range)} = []
                in.time_format {mustBeMember(in.time_format, {'none','numeric','datetime'})} = 'numeric'
                in.return_format {mustBeMember(in.return_format, {'single','double','data_object'})} = 'double'
            end

            if in.return_format == "data_object" && isempty(which('sci.time_series.data'))
                in.return_format = 'double';
            end

            if ~isempty(in.time_range)
                s1 = round(in.time_range(1) * obj.fs);

                if s1 < 0
                    error('Invalid time range requested, t1 too early')
                end

                % Make requested stop inclusive.
                % CED read call uses a non-inclusive upper bound.
                s2 = round(in.time_range(2) * obj.fs) - 1;

                if s2 >= obj.n_samples
                    error('Invalid time range requested, t2 too late')
                end

                if s1 > s2
                    error('Invalid time range requested, t1 > t2')
                end

            elseif ~isempty(in.sample_range)
                s1 = in.sample_range(1);
                s2 = in.sample_range(2);

                if s1 < 1
                    error('Invalid sample range requested, s1 too early')
                end

                if s2 > obj.n_samples
                    error('Invalid sample range requested, s2 too late')
                end

                if s1 > s2
                    error('Invalid sample range requested, s1 > s2')
                end

                % Convert 1-based MATLAB samples to 0-based CED samples.
                s1 = s1 - 1;
                s2 = s2 - 1;

            else
                s1 = 0;
                s2 = obj.n_samples - 1;
            end

            output = cell(1, in.n_init);
            I = 0;

            while true
                s = h__DataRetrieval_real_wave(obj, s1, s2, in, obj.n_samples);

                if s.n_samples == 0
                    break
                end

                I = I + 1;

                if I > length(output)
                    new_length = ceil(length(output) * in.growth_rate);

                    if new_length <= length(output)
                        new_length = length(output) + 10;
                    end

                    output{new_length} = [];
                end

                output{I} = s;

                % Continue after the last sample returned. This handles gaps.
                s1 = s.last_sample_id + 1;

                if s1 >= s2
                    break
                end
            end

            d = [output{1:I}];
        end
    end
end

function h__sizeCheck_real_wave(var)
if ~(isequal(size(var), [1 2]) || isempty(var))
    error('Variable must be empty or have size [1 x 2]')
end
end

function s = h__DataRetrieval_real_wave(obj, s1, s2, in, n_samples)

% Convert sample numbers to file ticks.
s1_in = s1 * obj.chan_div;
s2_in = s2 * obj.chan_div;

% CED upper bound is non-inclusive.
s2_in = s2_in + 1;

% For RealWave channels, read floating-point waveform data.
[n_read, data, start_tick] = CEDS64ReadWaveF( ...
    obj.h2, ...
    obj.chan_id, ...
    n_samples, ...
    s1_in, ...
    s2_in);

if n_read < 0
    error('CEDS64ReadWaveF failed with error code: %d', n_read)
end

% If no data were returned, produce an empty segment.
if n_read == 0 || isempty(data)
    s.data = [];
    s.first_sample_id = [];
    s.last_sample_id = [];
    s.start_time = [];
    s.n_samples = 0;
    s.time = [];
    return
end

% Note:
%   For ADC channels, start_tick / chan_div gives zero-based sample index.
%   MATLAB-facing sample IDs in adc.m are 1-based. Keep same convention here.
start_sample = double(start_tick / obj.chan_div) + 1;
last_sample = double(start_sample + length(data) - 1);
start_time = start_sample / obj.fs;
dt = double(1 / obj.fs);
n_samples_out = length(data);

switch in.return_format
    case 'single'
        data = single(data);

    case 'double'
        data = double(data);

    case 'data_object'
        data = double(data);

        if in.time_format == "datetime"
            start_datetime = obj.parent.start_datetime;

            if isnat(start_datetime)
                start_datetime = 0;
            end
        else
            start_datetime = 0;
        end

        time = sci.time_series.time( ...
            dt, ...
            n_read, ...
            'start_offset', start_time, ...
            'start_datetime', start_datetime);

        data = sci.time_series.data( ...
            data, ...
            time, ...
            'units', obj.units, ...
            'y_label', obj.name);

    otherwise
        error('Unrecognized return_format option')
end

s.data = data;
s.first_sample_id = start_sample;
s.last_sample_id = last_sample;
s.start_time = start_time;
s.n_samples = n_samples_out;

if in.time_format == "none" || in.return_format == "data_object"
    s.time = [];
else
    s.time = (start_sample:last_sample) ./ obj.fs;

    switch in.time_format
        case 'datetime'
            start_datetime = obj.parent.start_datetime;

            if isnat(start_datetime)
                s.time = seconds(s.time);
            else
                s.time = start_datetime + seconds(s.time);
            end

        case 'numeric'
            % Already numeric seconds.

        otherwise
            error("Unrecognized 'time_format' option")
    end
end
end