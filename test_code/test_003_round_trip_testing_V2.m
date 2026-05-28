function results = test_003_round_trip_testing_V2()
%TEST_CREATE_AND_READ  Round-trip write/read tests for the ced.file library
%
%   results = test_create_and_read()
%
%   Creates .smrx files with known data using the low-level CED API, then
%   reads them back through ced.file and verifies correctness across all
%   channel types and various edge cases.
%
%   Outputs
%   -------
%   results : struct
%       .n_pass   - number of passed tests
%       .n_fail   - number of failed tests
%       .failures - cell array of failure descriptions
%
%   Requirements
%   ------------
%   - CED CEDS64ML library must be on the MATLAB path
%   - Windows (32-bit or 64-bit)
%
%   See Also
%   --------
%   ced.file

    results.n_pass = 0;
    results.n_fail = 0;
    results.failures = {};

    %% Setup: ensure library is loaded and create temp directory
    ced.utils.loadLibraryIfNeeded();

    p = which('test_002__round_trip_testing');
    root = fileparts(p);

    temp_dir = fullfile(root, 'ced_test_files');
    if ~exist(temp_dir, 'dir')
        mkdir(temp_dir);
    end
    cleanup = onCleanup(@() h__cleanupTempDir(temp_dir));

    %% Run all test groups
    fprintf('\n========================================\n');
    fprintf('  matlab_spike2 Round-Trip Test Suite\n');
    fprintf('========================================\n\n');

    results = test_basic_file_properties(results, temp_dir);
    results = test_adc_channel(results, temp_dir);
    results = test_adc_data_formats(results, temp_dir);
    results = test_adc_time_range(results, temp_dir);
    results = test_adc_sample_range(results, temp_dir);
    results = test_adc_with_pause(results, temp_dir);
    results = test_event_fall_channel(results, temp_dir);
    results = test_event_rise_channel(results, temp_dir);
    results = test_event_both_channel(results, temp_dir);
    results = test_marker_channel(results, temp_dir);
    results = test_text_marker_channel(results, temp_dir);
    results = test_real_marker_channel(results, temp_dir);
    results = test_wave_marker_channel(results, temp_dir);
    results = test_real_wave_channel(results, temp_dir);
    results = test_multiple_channels(results, temp_dir);
    results = test_empty_channels(results, temp_dir);
    results = test_file_comments(results, temp_dir);
    results = test_file_datetime(results, temp_dir);
    results = test_channel_metadata(results, temp_dir);
    results = test_getChannels_method(results, temp_dir);
    results = test_getTypeSummary(results, temp_dir);
    results = test_string_vs_char_path(results, temp_dir);
    results = test_large_waveform(results, temp_dir);
    results = test_single_sample_waveform(results, temp_dir);
    results = test_marker_time_range(results, temp_dir);
    results = test_event_both_return_formats(results, temp_dir);

    %% Summary
    fprintf('\n========================================\n');
    fprintf('  RESULTS: %d passed, %d failed\n', ...
        results.n_pass, results.n_fail);
    fprintf('========================================\n');
    if results.n_fail > 0
        fprintf('\nFailures:\n');
        for i = 1:length(results.failures)
            fprintf('  [FAIL] %s\n', results.failures{i});
        end
    end
    fprintf('\n');
end

%% ========================================================================
%  HELPER: Create a fresh .smrx file and return its handle
%  ========================================================================
function [fhand, file_path] = h__createFile(temp_dir, name, time_base)
    if nargin < 3
        time_base = 1e-6; % 1 microsecond default
    end
    file_path = fullfile(temp_dir, [name '.smrx']);
    if exist(file_path, 'file')
        delete(file_path);
    end
    fhand = CEDS64Create(file_path);
    if fhand <= 0
        error('Failed to create test file: %s', name);
    end
    CEDS64TimeBase(fhand, time_base);
end

%% ========================================================================
%  HELPER: Close file, read it back with ced.file
%  ========================================================================
function f = h__closeAndReopen(fhand, file_path)
    CEDS64Close(fhand);
    f = ced.file(file_path);
end

%% ========================================================================
%  HELPER: Assert with tracking
%  ========================================================================
function results = h__assert(results, condition, test_name)
    if condition
        results.n_pass = results.n_pass + 1;
        fprintf('  [PASS] %s\n', test_name);
    else
        results.n_fail = results.n_fail + 1;
        results.failures{end+1} = test_name;
        fprintf('  [FAIL] %s\n', test_name);
    end
end

%% ========================================================================
%  HELPER: Assert approximate equality (for floating-point comparisons)
%  ========================================================================
function results = h__assertApprox(results, actual, expected, tol, test_name)
    if isempty(actual) && isempty(expected)
        cond = true;
    elseif isempty(actual) || isempty(expected)
        cond = false;
    else
        cond = all(abs(actual(:) - expected(:)) < tol, 'all');
    end
    results = h__assert(results, cond, test_name);
end

%% ========================================================================
%  HELPER: Cleanup temp directory
%  ========================================================================
function h__cleanupTempDir(temp_dir)
    try
        CEDS64CloseAll();
    catch
    end
    if exist(temp_dir, 'dir')
        rmdir(temp_dir, 's');
    end
end

%% ========================================================================
%  TEST: Basic file properties (time_base, version, file_size, n_seconds)
%  ========================================================================
function results = test_basic_file_properties(results, temp_dir)
    fprintf('--- Basic File Properties ---\n');

    time_base = 1e-5;
    [fhand, fp] = h__createFile(temp_dir, 'basic_props', time_base);

    % Write a short ADC channel so file has some duration
    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, chan, 100, 1, 1000);
    data = randi([-30000 30000], 1000, 1, 'int16');
    sTime = CEDS64SecsToTicks(fhand, 0);
    CEDS64WriteWave(fhand, chan, data, sTime);

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        abs(f.time_base - time_base) < 1e-12, ...
        'time_base matches written value');

    results = h__assert(results, ...
        f.version.value >= 256, ...
        'version >= 256 for 64-bit smrx files');

    results = h__assert(results, ...
        f.file_size > 0, ...
        'file_size is positive');

    results = h__assert(results, ...
        f.n_seconds > 0, ...
        'n_seconds is positive');

    results = h__assert(results, ...
        f.n_ticks > 0, ...
        'n_ticks is positive');

    clear f;
end

%% ========================================================================
%  TEST: ADC (waveform) channel round-trip
%  ========================================================================
function results = test_adc_channel(results, temp_dir)
    fprintf('--- ADC Channel Round-Trip ---\n');

    time_base = 1e-5;
    [fhand, fp] = h__createFile(temp_dir, 'adc_basic', time_base);

    chan = CEDS64GetFreeChan(fhand);
    chan_div = 100; % sample rate = 1/(100*1e-5) = 1000 Hz
    CEDS64SetWaveChan(fhand, chan, chan_div, 1, 1000);
    CEDS64ChanTitle(fhand, chan, 'TestADC');
    CEDS64ChanUnits(fhand, chan, 'mV');
    CEDS64ChanScale(fhand, chan, 6553.6); % scale so user value = int16 val
    CEDS64ChanOffset(fhand, chan, 0);

    n_samples = 5000;
    data_written = randi([-30000 30000], n_samples, 1, 'int16');
    sTime = CEDS64SecsToTicks(fhand, 0);
    CEDS64WriteWave(fhand, chan, data_written, sTime);

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        length(f.waveforms) == 1, ...
        'ADC: one waveform channel found');

    w = f.waveforms(1);
    results = h__assert(results, ...
        strcmp(w.name, 'TestADC'), ...
        'ADC: channel name matches');

    results = h__assert(results, ...
        strcmp(w.units, 'mV'), ...
        'ADC: channel units match');

    expected_fs = 1 / (chan_div * time_base);
    results = h__assert(results, ...
        abs(w.fs - expected_fs) < 0.01, ...
        'ADC: sample rate matches expected');

    d = w.getData('return_format', 'double', 'time_format', 'numeric');
    results = h__assert(results, ...
        length(d) == 1, ...
        'ADC: single segment returned (no pauses)');

    results = h__assert(results, ...
        d(1).n_samples == n_samples, ...
        'ADC: sample count matches written data');

    % With scale=6553.6 and offset=0, double(int16)*scale/6553.6+0 = double(int16)
    expected_double = double(data_written);
    results = h__assertApprox(results, ...
        d(1).data(:), expected_double(:), 0.01, ...
        'ADC: data values match after round-trip');

    results = h__assert(results, ...
        ~isempty(d(1).time), ...
        'ADC: time array returned with numeric format');

    results = h__assert(results, ...
        length(d(1).time) == n_samples, ...
        'ADC: time array length matches sample count');

    clear f;
end

%% ========================================================================
%  TEST: ADC data format options (int16, single, double)
%  ========================================================================
function results = test_adc_data_formats(results, temp_dir)
    fprintf('--- ADC Data Formats ---\n');

    [fhand, fp] = h__createFile(temp_dir, 'adc_formats');

    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, chan, 100, 1, 1000);
    CEDS64ChanScale(fhand, chan, 6553.6);
    CEDS64ChanOffset(fhand, chan, 0);
    data_written = randi([-1000 1000], 500, 1, 'int16');
    CEDS64WriteWave(fhand, chan, data_written, int64(0));

    f = h__closeAndReopen(fhand, fp);
    w = f.waveforms(1);

    % int16 format
    d_int = w.getData('return_format', 'int16');
    results = h__assert(results, ...
        isa(d_int(1).data, 'int16'), ...
        'ADC formats: int16 returns int16 class');
    results = h__assert(results, ...
        isequal(d_int(1).data(:), data_written(:)), ...
        'ADC formats: int16 data is exact match');

    % single format
    d_single = w.getData('return_format', 'single');
    results = h__assert(results, ...
        isa(d_single(1).data, 'single'), ...
        'ADC formats: single returns single class');

    % double format
    d_double = w.getData('return_format', 'double');
    results = h__assert(results, ...
        isa(d_double(1).data, 'double'), ...
        'ADC formats: double returns double class');

    % single and double should agree closely
    results = h__assertApprox(results, ...
        double(d_single(1).data), d_double(1).data, 1e-3, ...
        'ADC formats: single and double agree');

    clear f;
end

%% ========================================================================
%  TEST: ADC with time_range selection
%  ========================================================================
function results = test_adc_time_range(results, temp_dir)
    fprintf('--- ADC Time Range ---\n');

    time_base = 1e-5;
    chan_div = 100; % fs = 1000 Hz
    [fhand, fp] = h__createFile(temp_dir, 'adc_time_range', time_base);

    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, chan, chan_div, 1, 1000);
    CEDS64ChanScale(fhand, chan, 6553.6);
    CEDS64ChanOffset(fhand, chan, 0);

    n_total = 10000; % 10 seconds at 1000 Hz
    data_written = randi([-5000 5000], n_total, 1, 'int16');
    CEDS64WriteWave(fhand, chan, data_written, int64(0));

    f = h__closeAndReopen(fhand, fp);
    w = f.waveforms(1);

    % Request the middle 2 seconds (from 4.0 to 6.0 s)
    d = w.getData('time_range', [4.0 6.0], 'return_format', 'double');
    n_expected = round(2.0 * 1000); % 2 seconds * 1000 Hz
    results = h__assert(results, ...
        abs(d(1).n_samples - n_expected) <= 2, ...
        'ADC time_range: sample count approximately correct');

    results = h__assert(results, ...
        d(1).start_time >= 3.99, ...
        'ADC time_range: start_time >= 3.99s');

    % Test error on invalid range (t1 > t2 would error)
    caught = false;
    try
        w.getData('time_range', [6.0 4.0]);
    catch
        caught = true;
    end
    results = h__assert(results, caught, ...
        'ADC time_range: error on t1 > t2');

    clear f;
end

%% ========================================================================
%  TEST: ADC with sample_range selection
%  ========================================================================
function results = test_adc_sample_range(results, temp_dir)
    fprintf('--- ADC Sample Range ---\n');

    [fhand, fp] = h__createFile(temp_dir, 'adc_sample_range');

    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, chan, 100, 1, 1000);
    CEDS64ChanScale(fhand, chan, 6553.6);
    CEDS64ChanOffset(fhand, chan, 0);

    n_total = 5000;
    data_written = randi([-5000 5000], n_total, 1, 'int16');
    CEDS64WriteWave(fhand, chan, data_written, int64(0));

    f = h__closeAndReopen(fhand, fp);
    w = f.waveforms(1);

    % Request samples 101:200 (1-based, inclusive)
    d = w.getData('sample_range', [101 200], 'return_format', 'int16');
    results = h__assert(results, ...
        d(1).n_samples == 100, ...
        'ADC sample_range: 100 samples returned');

    results = h__assert(results, ...
        isequal(d(1).data(:), data_written(101:200)), ...
        'ADC sample_range: data matches expected slice');

    % Edge: requesting first sample only
    d1 = w.getData('sample_range', [1 1], 'return_format', 'int16');
    results = h__assert(results, ...
        d1(1).n_samples == 1, ...
        'ADC sample_range: single sample returned');
    results = h__assert(results, ...
        d1(1).data == data_written(1), ...
        'ADC sample_range: first sample value matches');

    % Edge: requesting last sample only
    d_last = w.getData('sample_range', [n_total n_total], 'return_format', 'int16');
    results = h__assert(results, ...
        d_last(1).n_samples == 1, ...
        'ADC sample_range: last sample returned');
    results = h__assert(results, ...
        d_last(1).data == data_written(n_total), ...
        'ADC sample_range: last sample value matches');

    % Error on s1 > s2
    caught = false;
    try
        w.getData('sample_range', [200 100]);
    catch
        caught = true;
    end
    results = h__assert(results, caught, ...
        'ADC sample_range: error on s1 > s2');

    clear f;
end

%% ========================================================================
%  TEST: ADC with pause (gap) in data
%  ========================================================================
function results = test_adc_with_pause(results, temp_dir)
    fprintf('--- ADC With Pause ---\n');

    time_base = 1e-5;
    chan_div = 100; % fs = 1000 Hz
    [fhand, fp] = h__createFile(temp_dir, 'adc_pause', time_base);

    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, chan, chan_div, 1, 1000);

    % Write a first chunk starting at 0 seconds
    data1 = randi([-5000 5000], 1000, 1, 'int16');
    sTime1 = CEDS64SecsToTicks(fhand, 0);
    CEDS64WriteWave(fhand, chan, data1, sTime1);

    % Write a second chunk starting at 5 seconds (gap from ~1s to 5s)
    data2 = randi([-5000 5000], 1000, 1, 'int16');
    sTime2 = CEDS64SecsToTicks(fhand, 5);
    CEDS64WriteWave(fhand, chan, data2, sTime2);

    f = h__closeAndReopen(fhand, fp);
    w = f.waveforms(1);

    d = w.getData('return_format', 'int16');

    results = h__assert(results, ...
        length(d) == 2, ...
        'ADC pause: two segments returned');

    if length(d) >= 2
        results = h__assert(results, ...
            d(1).n_samples == 1000, ...
            'ADC pause: first segment has 1000 samples');

        results = h__assert(results, ...
            d(2).n_samples == 1000, ...
            'ADC pause: second segment has 1000 samples');

        results = h__assert(results, ...
            isequal(d(1).data(:), data1(:)), ...
            'ADC pause: first segment data matches');

        results = h__assert(results, ...
            isequal(d(2).data(:), data2(:)), ...
            'ADC pause: second segment data matches');

        % The gap should be visible in start times
        results = h__assert(results, ...
            d(2).start_time > d(1).start_time + 1, ...
            'ADC pause: second segment starts later');
    end

    clear f;
end

%% ========================================================================
%  TEST: EventFall channel
%  ========================================================================
function results = test_event_fall_channel(results, temp_dir)
    fprintf('--- EventFall Channel ---\n');

    time_base = 1e-5;
    [fhand, fp] = h__createFile(temp_dir, 'event_fall', time_base);

    chan = CEDS64GetFreeChan(fhand);
    % type=2 means EventFall
    CEDS64SetEventChan(fhand, chan, 1000, 2);
    CEDS64ChanTitle(fhand, chan, 'FallEvents');
    CEDS64ChanUnits(fhand, chan, 'sec');

    % Write event times: 1, 2, 3, ... 50 seconds
    n_events = 50;
    event_times_sec = (1:n_events)';
    event_ticks = zeros(n_events, 1, 'int64');
    for i = 1:n_events
        event_ticks(i) = CEDS64SecsToTicks(fhand, event_times_sec(i));
    end
    CEDS64WriteEvents(fhand, chan, event_ticks);

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        length(f.event_falls) == 1, ...
        'EventFall: one channel found');

    ef = f.event_falls(1);
    results = h__assert(results, ...
        strcmp(ef.name, 'FallEvents'), ...
        'EventFall: name matches');

    times = ef.getTimes();
    results = h__assert(results, ...
        length(times) == n_events, ...
        'EventFall: correct number of events');

    results = h__assertApprox(results, ...
        times(:), event_times_sec(:), 1e-4, ...
        'EventFall: event times match');

    clear f;
end

%% ========================================================================
%  TEST: EventRise channel
%  ========================================================================
function results = test_event_rise_channel(results, temp_dir)
    fprintf('--- EventRise Channel ---\n');

    time_base = 1e-5;
    [fhand, fp] = h__createFile(temp_dir, 'event_rise', time_base);

    chan = CEDS64GetFreeChan(fhand);
    % type=3 means EventRise
    CEDS64SetEventChan(fhand, chan, 1000, 3);
    CEDS64ChanTitle(fhand, chan, 'RiseEvents');

    n_events = 100;
    event_times_sec = sort(rand(n_events, 1) * 100);
    event_ticks = zeros(n_events, 1, 'int64');
    for i = 1:n_events
        event_ticks(i) = CEDS64SecsToTicks(fhand, event_times_sec(i));
    end
    CEDS64WriteEvents(fhand, chan, event_ticks);

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        length(f.event_rises) == 1, ...
        'EventRise: one channel found');

    er = f.event_rises(1);
    results = h__assert(results, ...
        er.type == "rise", ...
        'EventRise: type is "rise"');

    times = er.getTimes();
    results = h__assert(results, ...
        length(times) == n_events, ...
        'EventRise: correct event count');

    % Verify within tick resolution
    results = h__assertApprox(results, ...
        times(:), event_times_sec(:), time_base + 1e-6, ...
        'EventRise: event times match within tolerance');

    % Test time_range subselection
    times_sub = er.getTimes('time_range', [20 40]);
    expected_count = sum(event_times_sec >= 20 & event_times_sec <= 40);
    results = h__assert(results, ...
        abs(length(times_sub) - expected_count) <= 2, ...
        'EventRise: time_range subselection count approximately correct');

    clear f;
end

%% ========================================================================
%  TEST: EventBoth (level) channel
%  ========================================================================
function results = test_event_both_channel(results, temp_dir)
    fprintf('--- EventBoth Channel ---\n');

    time_base = 1e-5;
    [fhand, fp] = h__createFile(temp_dir, 'event_both', time_base);

    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetLevelChan(fhand, chan, 1000);
    CEDS64SetInitLevel(fhand, chan, 0); % starts low
    CEDS64ChanTitle(fhand, chan, 'LevelChan');

    % Transitions at 1, 2, 3, ... 20 seconds
    n_transitions = 20;
    trans_ticks = zeros(n_transitions, 1, 'int64');
    for i = 1:n_transitions
        trans_ticks(i) = CEDS64SecsToTicks(fhand, i);
    end
    CEDS64WriteEvents(fhand, chan, trans_ticks);

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        length(f.event_both) == 1, ...
        'EventBoth: one channel found');

    eb = f.event_both(1);
    results = h__assert(results, ...
        strcmp(eb.name, 'LevelChan'), ...
        'EventBoth: name matches');

    s = eb.getTimes('return_format', 'times');
    results = h__assert(results, ...
        length(s.times) == n_transitions, ...
        'EventBoth: correct number of transitions');

    expected_times = (1:n_transitions)';
    results = h__assertApprox(results, ...
        s.times(:), expected_times(:), 1e-4, ...
        'EventBoth: transition times match');

    clear f;
end

%% ========================================================================
%  TEST: Marker channel
%  ========================================================================
function results = test_marker_channel(results, temp_dir)
    fprintf('--- Marker Channel ---\n');

    time_base = 1e-5;
    [fhand, fp] = h__createFile(temp_dir, 'markers', time_base);

    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetMarkerChan(fhand, chan, 1000, 5);
    CEDS64ChanTitle(fhand, chan, 'TestMarker');

    n_markers = 200;
    markerbuffer(n_markers, 1) = CEDMarker();
    for m = 1:n_markers
        markerbuffer(m).SetTime(CEDS64SecsToTicks(fhand, m * 0.5));
        markerbuffer(m).SetCode(1, uint8(mod(m, 256)));
        markerbuffer(m).SetCode(2, uint8(mod(m + 10, 256)));
        markerbuffer(m).SetCode(3, uint8(mod(m + 20, 256)));
        markerbuffer(m).SetCode(4, uint8(mod(m + 30, 256)));
    end
    CEDS64WriteMarkers(fhand, chan, markerbuffer);

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        length(f.markers) == 1, ...
        'Marker: one channel found');

    mk = f.markers(1);
    s = mk.getData('to_char', false);

    results = h__assert(results, ...
        length(s.times) == n_markers, ...
        'Marker: correct count');

    expected_times = (1:n_markers)' * 0.5;
    results = h__assertApprox(results, ...
        s.times(:), expected_times(:), 1e-4, ...
        'Marker: times match');

    expected_c1 = mod((1:n_markers)', 256);
    results = h__assert(results, ...
        isequal(double(s.c1(:)), expected_c1), ...
        'Marker: code1 values match');

    clear f;
end

%% ========================================================================
%  TEST: TextMark channel
%  ========================================================================
function results = test_text_marker_channel(results, temp_dir)
    fprintf('--- TextMark Channel ---\n');

    time_base = 1e-5;
    [fhand, fp] = h__createFile(temp_dir, 'text_marks', time_base);

    chan = CEDS64GetFreeChan(fhand);
    max_text_len = 60;
    CEDS64SetExtMarkChan(fhand, chan, 1000, 8, max_text_len, 1, 0);
    CEDS64ChanTitle(fhand, chan, 'TextMarks');

    n_marks = 50;
    tmarkerbuffer(n_marks, 1) = CEDTextMark();
    written_strings = cell(n_marks, 1);
    for m = 1:n_marks
        tmarkerbuffer(m).SetTime(CEDS64SecsToTicks(fhand, m * 2));
        tmarkerbuffer(m).SetCode(1, uint8(mod(m, 256)));
        tmarkerbuffer(m).SetCode(2, uint8(0));
        tmarkerbuffer(m).SetCode(3, uint8(0));
        tmarkerbuffer(m).SetCode(4, uint8(0));
        txt = sprintf('Event_%03d_at_%ds', m, m * 2);
        tmarkerbuffer(m).SetData(txt);
        written_strings{m} = txt;
    end
    CEDS64WriteExtMarks(fhand, chan, tmarkerbuffer);

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        length(f.text_markers) == 1, ...
        'TextMark: one channel found');

    tm = f.text_markers(1);
    t = tm.getData();

    results = h__assert(results, ...
        height(t) == n_marks, ...
        'TextMark: correct number of entries');

    expected_times = (1:n_marks)' * 2;
    results = h__assertApprox(results, ...
        t.time(:), expected_times(:), 1e-4, ...
        'TextMark: times match');

    % Check first and last text strings
    results = h__assert(results, ...
        contains(char(t.text(1,:)), 'Event_001'), ...
        'TextMark: first text matches');

    results = h__assert(results, ...
        contains(char(t.text(end,:)), sprintf('Event_%03d', n_marks)), ...
        'TextMark: last text matches');

    clear f;
end

%% ========================================================================
%  TEST: RealMark channel
%  ========================================================================
function results = test_real_marker_channel(results, temp_dir)
    fprintf('--- RealMark Channel ---\n');

    time_base = 1e-5;
    [fhand, fp] = h__createFile(temp_dir, 'real_marks', time_base);

    chan = CEDS64GetFreeChan(fhand);
    n_real_values = 10; % each marker carries 10 floats
    n_traces = 1;
    CEDS64SetExtMarkChan(fhand, chan, 1000, 7, n_real_values, n_traces, 0);
    CEDS64ChanTitle(fhand, chan, 'RealMarks');

    n_marks = 30;
    rmarkerbuffer(n_marks, 1) = CEDRealMark();
    written_data = cell(n_marks, 1);
    for m = 1:n_marks
        rmarkerbuffer(m).SetTime(CEDS64SecsToTicks(fhand, m));
        rmarkerbuffer(m).SetCode(1, uint8(mod(m, 128)));
        rmarkerbuffer(m).SetCode(2, uint8(0));
        rmarkerbuffer(m).SetCode(3, uint8(0));
        rmarkerbuffer(m).SetCode(4, uint8(0));
        d = rand(n_real_values, n_traces, 'single');
        rmarkerbuffer(m).SetData(d);
        written_data{m} = d;
    end
    CEDS64WriteExtMarks(fhand, chan, rmarkerbuffer);

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        length(f.real_markers) == 1, ...
        'RealMark: one channel found');

    rm = f.real_markers(1);
    s = rm.getData('return_format', 'struct');

    results = h__assert(results, ...
        length(s) == n_marks, ...
        'RealMark: correct number of entries');

    % Check first marker's data
    results = h__assertApprox(results, ...
        double(s(1).data), double(written_data{1}), 1e-5, ...
        'RealMark: first marker data matches');

    % Check struct2 format
    s2 = rm.getData('return_format', 'struct2');
    results = h__assert(results, ...
        length(s2.time) == n_marks, ...
        'RealMark struct2: correct number of times');

    clear f;
end

%% ========================================================================
%  TEST: WaveMark channel
%  ========================================================================
function results = test_wave_marker_channel(results, temp_dir)
    fprintf('--- WaveMark Channel ---\n');

    time_base = 1e-5;
    [fhand, fp] = h__createFile(temp_dir, 'wave_marks', time_base);

    chan = CEDS64GetFreeChan(fhand);
    n_waveform_pts = 32;
    n_traces = 4; % tetrode
    CEDS64SetExtMarkChan(fhand, chan, 1000, 6, n_waveform_pts, n_traces, 1000);
    CEDS64ChanTitle(fhand, chan, 'WaveMarks');
    CEDS64ChanScale(fhand, chan, 6553.6);
    CEDS64ChanOffset(fhand, chan, 0);

    n_marks = 25;
    wmarkerbuffer(n_marks, 1) = CEDWaveMark();
    written_data = cell(n_marks, 1);
    for m = 1:n_marks
        wmarkerbuffer(m).SetTime(CEDS64SecsToTicks(fhand, m));
        wmarkerbuffer(m).SetCode(1, uint8(mod(m, 256)));
        wmarkerbuffer(m).SetCode(2, uint8(0));
        wmarkerbuffer(m).SetCode(3, uint8(0));
        wmarkerbuffer(m).SetCode(4, uint8(0));
        d = int16(randi([-15000 15000], n_waveform_pts, n_traces));
        wmarkerbuffer(m).SetData(d);
        written_data{m} = d;
    end
    CEDS64WriteExtMarks(fhand, chan, wmarkerbuffer);

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        length(f.wave_markers) == 1, ...
        'WaveMark: one channel found');

    wm = f.wave_markers(1);
    s = wm.getData('return_format', 'struct');

    results = h__assert(results, ...
        length(s) == n_marks, ...
        'WaveMark: correct number of entries');

    % With scale=6553.6, offset=0:
    %   user_value = int16_value * 6553.6/6553.6 + 0 = double(int16_value)
    results = h__assertApprox(results, ...
        s(1).data, double(written_data{1}), 0.01, ...
        'WaveMark: first snippet data matches');

    % Test matrix1 format
    s_m1 = wm.getData('return_format', 'matrix1');
    results = h__assert(results, ...
        length(s_m1.data) == n_traces, ...
        'WaveMark matrix1: correct number of traces');

    results = h__assert(results, ...
        size(s_m1.data{1}, 2) == n_marks, ...
        'WaveMark matrix1: correct number of events per trace');

    % Test matrix2 format
    s_m2 = wm.getData('return_format', 'matrix2');
    results = h__assert(results, ...
        isequal(size(s_m2.data), [n_waveform_pts n_traces n_marks]), ...
        'WaveMark matrix2: correct 3D shape');

    clear f;
end

%% ========================================================================
%  TEST: RealWave channel
%  ========================================================================
function results = test_real_wave_channel(results, temp_dir)
    fprintf('--- RealWave Channel ---\n');

    time_base = 1e-5;
    chan_div = 100; % fs = 1000 Hz
    [fhand, fp] = h__createFile(temp_dir, 'real_wave', time_base);

    chan = CEDS64GetFreeChan(fhand);
    % type=9 is RealWave
    CEDS64SetWaveChan(fhand, chan, chan_div, 9, 1000);
    CEDS64ChanTitle(fhand, chan, 'RealWaveChan');
    CEDS64ChanUnits(fhand, chan, 'V');

    n_samples = 3000;
    data_written = rand(n_samples, 1);
    sTime = CEDS64SecsToTicks(fhand, 1.0); % start at 1 second
    CEDS64WriteWave(fhand, chan, data_written, sTime);

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        length(f.real_waves) == 1, ...
        'RealWave: one channel found');

    rw = f.real_waves(1);
    results = h__assert(results, ...
        strcmp(rw.name, 'RealWaveChan'), ...
        'RealWave: name matches');

    d = rw.getData('return_format', 'double');
    results = h__assert(results, ...
        d(1).n_samples == n_samples, ...
        'RealWave: sample count matches');

    % RealWave stores native floats, so precision should be good
    results = h__assertApprox(results, ...
        d(1).data(:), data_written(:), 1e-5, ...
        'RealWave: data matches within float tolerance');

    clear f;
end

%% ========================================================================
%  TEST: Multiple channels in one file
%  ========================================================================
function results = test_multiple_channels(results, temp_dir)
    fprintf('--- Multiple Channels ---\n');

    time_base = 1e-5;
    [fhand, fp] = h__createFile(temp_dir, 'multi_chan', time_base);

    % ADC channel 1
    ch_adc1 = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, ch_adc1, 100, 1, 1000);
    CEDS64ChanTitle(fhand, ch_adc1, 'EEG');
    data_adc1 = randi([-1000 1000], 2000, 1, 'int16');
    CEDS64WriteWave(fhand, ch_adc1, data_adc1, int64(0));

    % ADC channel 2
    ch_adc2 = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, ch_adc2, 200, 1, 1000); % different rate
    CEDS64ChanTitle(fhand, ch_adc2, 'EMG');
    data_adc2 = randi([-2000 2000], 1000, 1, 'int16');
    CEDS64WriteWave(fhand, ch_adc2, data_adc2, int64(0));

    % EventRise channel
    ch_ev = CEDS64GetFreeChan(fhand);
    CEDS64SetEventChan(fhand, ch_ev, 1000, 3);
    CEDS64ChanTitle(fhand, ch_ev, 'Stim');
    ev_ticks = zeros(10, 1, 'int64');
    for i = 1:10
        ev_ticks(i) = CEDS64SecsToTicks(fhand, i);
    end
    CEDS64WriteEvents(fhand, ch_ev, ev_ticks);

    % Marker channel
    ch_mk = CEDS64GetFreeChan(fhand);
    CEDS64SetMarkerChan(fhand, ch_mk, 1000, 5);
    CEDS64ChanTitle(fhand, ch_mk, 'Keyboard');
    mkbuf(5, 1) = CEDMarker();
    for i = 1:5
        mkbuf(i).SetTime(CEDS64SecsToTicks(fhand, i * 3));
        mkbuf(i).SetCode(1, uint8(65 + i - 1)); % 'A','B','C',...
        mkbuf(i).SetCode(2, uint8(0));
        mkbuf(i).SetCode(3, uint8(0));
        mkbuf(i).SetCode(4, uint8(0));
    end
    CEDS64WriteMarkers(fhand, ch_mk, mkbuf);

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        length(f.waveforms) == 2, ...
        'MultiChan: two ADC channels');

    results = h__assert(results, ...
        length(f.event_rises) == 1, ...
        'MultiChan: one EventRise channel');

    results = h__assert(results, ...
        length(f.markers) == 1, ...
        'MultiChan: one Marker channel');

    % Verify different sample rates
    results = h__assert(results, ...
        abs(f.waveforms(1).fs - f.waveforms(2).fs) > 1, ...
        'MultiChan: waveforms have different sample rates');

    % Verify all_chan_objects
    results = h__assert(results, ...
        length(f.all_chan_objects) == 4, ...
        'MultiChan: all_chan_objects has 4 entries');

    % Verify chan_names
    results = h__assert(results, ...
        length(f.chan_names) == 4, ...
        'MultiChan: chan_names has 4 entries');

    clear f;
end

%% ========================================================================
%  TEST: File with no data in certain channel types (empty arrays)
%  ========================================================================
function results = test_empty_channels(results, temp_dir)
    fprintf('--- Empty Channels ---\n');

    [fhand, fp] = h__createFile(temp_dir, 'empty_chans');

    % Create an ADC channel with data so file is valid
    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, chan, 100, 1, 1000);
    data = randi([-1000 1000], 500, 1, 'int16');
    CEDS64WriteWave(fhand, chan, data, int64(0));

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        isempty(f.event_falls), ...
        'Empty: no event_falls when none created');

    results = h__assert(results, ...
        isempty(f.event_rises), ...
        'Empty: no event_rises when none created');

    results = h__assert(results, ...
        isempty(f.event_both), ...
        'Empty: no event_both when none created');

    results = h__assert(results, ...
        isempty(f.markers), ...
        'Empty: no markers when none created');

    results = h__assert(results, ...
        isempty(f.wave_markers), ...
        'Empty: no wave_markers when none created');

    results = h__assert(results, ...
        isempty(f.real_markers), ...
        'Empty: no real_markers when none created');

    results = h__assert(results, ...
        isempty(f.text_markers), ...
        'Empty: no text_markers when none created');

    results = h__assert(results, ...
        isempty(f.real_waves), ...
        'Empty: no real_waves when none created');

    clear f;
end

%% ========================================================================
%  TEST: File comments
%  ========================================================================
function results = test_file_comments(results, temp_dir)
    fprintf('--- File Comments ---\n');

    [fhand, fp] = h__createFile(temp_dir, 'comments');

    CEDS64FileComment(fhand, 1, 'Comment One');
    CEDS64FileComment(fhand, 2, 'Comment Two');
    CEDS64FileComment(fhand, 3, '');  % empty comment
    CEDS64FileComment(fhand, 4, 'Comment Four');

    % Write minimal data
    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, chan, 100, 1, 1000);
    CEDS64WriteWave(fhand, chan, int16(zeros(100, 1)), int64(0));

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        ~isempty(f.file_comments), ...
        'Comments: file_comments is non-empty');

    % Non-empty comments should be present
    all_comments = strjoin(f.file_comments, ' ');
    results = h__assert(results, ...
        contains(all_comments, 'Comment One'), ...
        'Comments: Comment One found');

    results = h__assert(results, ...
        contains(all_comments, 'Comment Four'), ...
        'Comments: Comment Four found');

    clear f;
end

%% ========================================================================
%  TEST: File start datetime
%  ========================================================================
function results = test_file_datetime(results, temp_dir)
    fprintf('--- File DateTime ---\n');

    [fhand, fp] = h__createFile(temp_dir, 'datetime');

    % Set a known date/time: 2024-03-15 10:30:45.50
    % CEDS64TimeDate format: [hundredths, s, min, h, day, month, year]
    time_date = [50, 45, 30, 10, 15, 3, 2024];
    CEDS64TimeDate(fhand, time_date);

    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, chan, 100, 1, 1000);
    CEDS64WriteWave(fhand, chan, int16(zeros(100, 1)), int64(0));

    f = h__closeAndReopen(fhand, fp);

    results = h__assert(results, ...
        ~isnat(f.start_datetime), ...
        'DateTime: valid datetime returned');

    if ~isnat(f.start_datetime)
        results = h__assert(results, ...
            f.start_datetime.Year == 2024, ...
            'DateTime: year is 2024');

        results = h__assert(results, ...
            f.start_datetime.Month == 3, ...
            'DateTime: month is March');

        results = h__assert(results, ...
            f.start_datetime.Day == 15, ...
            'DateTime: day is 15');

        results = h__assert(results, ...
            f.start_datetime.Hour == 10, ...
            'DateTime: hour is 10');
    end

    clear f;
end

%% ========================================================================
%  TEST: Channel metadata (offset, scale, y_range, chan_div)
%  ========================================================================
function results = test_channel_metadata(results, temp_dir)
    fprintf('--- Channel Metadata ---\n');

    time_base = 1e-5;
    [fhand, fp] = h__createFile(temp_dir, 'chan_meta', time_base);

    chan = CEDS64GetFreeChan(fhand);
    chan_div = 50; % fs = 1/(50*1e-5) = 2000 Hz
    CEDS64SetWaveChan(fhand, chan, chan_div, 1, 1000);
    CEDS64ChanTitle(fhand, chan, 'Pressure');
    CEDS64ChanUnits(fhand, chan, 'cmH2O');
    CEDS64ChanScale(fhand, chan, 100.0);
    CEDS64ChanOffset(fhand, chan, 5.0);
    CEDS64ChanComment(fhand, chan, 'Bladder pressure sensor');
    CEDS64ChanYRange(fhand, chan, -10, 50);

    CEDS64WriteWave(fhand, chan, int16(zeros(100, 1)), int64(0));

    f = h__closeAndReopen(fhand, fp);
    w = f.waveforms(1);

    results = h__assert(results, ...
        strcmp(w.name, 'Pressure'), ...
        'Metadata: name matches');

    results = h__assert(results, ...
        strcmp(w.units, 'cmH2O'), ...
        'Metadata: units match');

    results = h__assert(results, ...
        strcmp(w.comment, 'Bladder pressure sensor'), ...
        'Metadata: comment matches');

    results = h__assert(results, ...
        abs(w.scale - 100.0) < 1e-6, ...
        'Metadata: scale matches');

    results = h__assert(results, ...
        abs(w.offset - 5.0) < 1e-6, ...
        'Metadata: offset matches');

    expected_fs = 1 / (chan_div * time_base);
    results = h__assert(results, ...
        abs(w.fs - expected_fs) < 0.1, ...
        'Metadata: fs matches expected 2000 Hz');

    results = h__assert(results, ...
        w.chan_div == chan_div, ...
        'Metadata: chan_div matches');

    results = h__assert(results, ...
        w.y_range(1) == -10 && w.y_range(2) == 50, ...
        'Metadata: y_range matches');

    clear f;
end

%% ========================================================================
%  TEST: getChannels method with various options
%  ========================================================================
function results = test_getChannels_method(results, temp_dir)
    fprintf('--- getChannels Method ---\n');

    [fhand, fp] = h__createFile(temp_dir, 'get_chans');

    ch1 = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, ch1, 100, 1, 1000);
    CEDS64ChanTitle(fhand, ch1, 'EEG_Frontal');
    CEDS64WriteWave(fhand, ch1, int16(zeros(100, 1)), int64(0));

    ch2 = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, ch2, 100, 1, 1000);
    CEDS64ChanTitle(fhand, ch2, 'EEG_Parietal');
    CEDS64WriteWave(fhand, ch2, int16(zeros(100, 1)), int64(0));

    ch3 = CEDS64GetFreeChan(fhand);
    CEDS64SetEventChan(fhand, ch3, 1000, 3);
    CEDS64ChanTitle(fhand, ch3, 'Stim_Trigger');
    ev_tick = CEDS64SecsToTicks(fhand, 1);
    CEDS64WriteEvents(fhand, ch3, int64(ev_tick));

    f = h__closeAndReopen(fhand, fp);

    % Case-insensitive partial match (default)
    chans = f.getChannels('eeg');
    results = h__assert(results, ...
        ~isempty(chans{1}), ...
        'getChannels: case-insensitive partial finds EEG');

    % Multiple names
    chans = f.getChannels({'eeg_frontal', 'stim'});
    results = h__assert(results, ...
        ~isempty(chans{1}) && ~isempty(chans{2}), ...
        'getChannels: multiple names work');

    % Exact match (should fail for lowercase)
    caught = false;
    try
        f.getChannels('eeg_frontal', ...
            'case_sensitive', true, ...
            'partial_match', false, ...
            'missing', 'error');
    catch
        caught = true;
    end
    results = h__assert(results, caught, ...
        'getChannels: exact case-sensitive fails for wrong case');

    % Missing channel with warning mode
    chans = f.getChannels('NonExistent', 'missing', 'warning');
    results = h__assert(results, ...
        isempty(chans{1}), ...
        'getChannels: missing channel returns [] with warning');

    % Partial match at start
    chans = f.getChannels('EEG', 'partial_match', 'start');
    results = h__assert(results, ...
        ~isempty(chans{1}), ...
        'getChannels: partial_match=start works');

    clear f;
end

%% ========================================================================
%  TEST: getTypeSummary method
%  ========================================================================
function results = test_getTypeSummary(results, temp_dir)
    fprintf('--- getTypeSummary ---\n');

    [fhand, fp] = h__createFile(temp_dir, 'type_summary');

    % 2 ADC channels
    for i = 1:2
        ch = CEDS64GetFreeChan(fhand);
        CEDS64SetWaveChan(fhand, ch, 100, 1, 1000);
        CEDS64WriteWave(fhand, ch, int16(zeros(100, 1)), int64(0));
    end

    % 1 EventRise
    ch = CEDS64GetFreeChan(fhand);
    CEDS64SetEventChan(fhand, ch, 1000, 3);
    CEDS64WriteEvents(fhand, ch, int64(CEDS64SecsToTicks(fhand, 1)));

    f = h__closeAndReopen(fhand, fp);
    t = f.getTypeSummary();

    results = h__assert(results, ...
        t.adc == 2, ...
        'TypeSummary: adc count is 2');

    results = h__assert(results, ...
        t.event_rise == 1, ...
        'TypeSummary: event_rise count is 1');

    results = h__assert(results, ...
        t.event_fall == 0, ...
        'TypeSummary: event_fall count is 0');

    results = h__assert(results, ...
        t.marker == 0, ...
        'TypeSummary: marker count is 0');

    clear f;
end

%% ========================================================================
%  TEST: String vs char file_path input
%  ========================================================================
function results = test_string_vs_char_path(results, temp_dir)
    fprintf('--- String vs Char Path ---\n');

    [fhand, fp] = h__createFile(temp_dir, 'path_test');
    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, chan, 100, 1, 1000);
    CEDS64WriteWave(fhand, chan, int16(zeros(100, 1)), int64(0));
    CEDS64Close(fhand);

    % Open with char array (standard)
    f_char = ced.file(fp);
    results = h__assert(results, ...
        ~isempty(f_char.waveforms), ...
        'Path: char path opens successfully');
    clear f_char;

    % Open with string
    f_str = ced.file(string(fp));
    results = h__assert(results, ...
        ~isempty(f_str.waveforms), ...
        'Path: string path opens successfully');
    clear f_str;

    % Open with struct (dir output style)
    [folder, name, ext] = fileparts(fp);
    d_struct.folder = folder;
    d_struct.name = [name ext];
    f_struct = ced.file(d_struct);
    results = h__assert(results, ...
        ~isempty(f_struct.waveforms), ...
        'Path: struct (dir-style) opens successfully');
    clear f_struct;
end

%% ========================================================================
%  TEST: Large waveform (stress test for memory allocation)
%  ========================================================================
function results = test_large_waveform(results, temp_dir)
    fprintf('--- Large Waveform ---\n');

    [fhand, fp] = h__createFile(temp_dir, 'large_wave');

    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, chan, 10, 1, 1000);
    CEDS64ChanScale(fhand, chan, 6553.6);
    CEDS64ChanOffset(fhand, chan, 0);

    % Write 100,000 samples
    n_samples = 100000;
    data_written = randi([-30000 30000], n_samples, 1, 'int16');
    CEDS64WriteWave(fhand, chan, data_written, int64(0));

    f = h__closeAndReopen(fhand, fp);
    w = f.waveforms(1);
    d = w.getData('return_format', 'int16');

    results = h__assert(results, ...
        d(1).n_samples == n_samples, ...
        'LargeWave: 100k samples returned');

    results = h__assert(results, ...
        isequal(d(1).data(:), data_written(:)), ...
        'LargeWave: data integrity maintained');

    clear f;
end

%% ========================================================================
%  TEST: Single sample waveform (minimal edge case)
%  ========================================================================
function results = test_single_sample_waveform(results, temp_dir)
    fprintf('--- Single Sample Waveform ---\n');

    [fhand, fp] = h__createFile(temp_dir, 'single_sample');

    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetWaveChan(fhand, chan, 100, 1, 1000);
    CEDS64ChanScale(fhand, chan, 6553.6);
    CEDS64ChanOffset(fhand, chan, 0);

    data_written = int16(12345);
    CEDS64WriteWave(fhand, chan, data_written, int64(0));

    f = h__closeAndReopen(fhand, fp);
    w = f.waveforms(1);
    d = w.getData('return_format', 'int16');

    results = h__assert(results, ...
        d(1).n_samples == 1, ...
        'SingleSample: one sample returned');

    results = h__assert(results, ...
        d(1).data == data_written, ...
        'SingleSample: value matches');

    clear f;
end

%% ========================================================================
%  TEST: Marker with time_range subselection
%  ========================================================================
function results = test_marker_time_range(results, temp_dir)
    fprintf('--- Marker Time Range ---\n');

    time_base = 1e-5;
    [fhand, fp] = h__createFile(temp_dir, 'marker_range', time_base);

    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetMarkerChan(fhand, chan, 1000, 5);
    CEDS64ChanTitle(fhand, chan, 'TestMK');

    n_markers = 100;
    markerbuffer(n_markers, 1) = CEDMarker();
    for m = 1:n_markers
        markerbuffer(m).SetTime(CEDS64SecsToTicks(fhand, m));
        markerbuffer(m).SetCode(1, uint8(m));
        markerbuffer(m).SetCode(2, uint8(0));
        markerbuffer(m).SetCode(3, uint8(0));
        markerbuffer(m).SetCode(4, uint8(0));
    end
    CEDS64WriteMarkers(fhand, chan, markerbuffer);

    f = h__closeAndReopen(fhand, fp);
    mk = f.markers(1);

    % Get all markers
    s_all = mk.getData('to_char', false);
    results = h__assert(results, ...
        length(s_all.times) == n_markers, ...
        'MarkerRange: all 100 markers retrieved');

    % Get markers between 20-30 seconds
    s_sub = mk.getData('time_range', [20 30], 'to_char', false);
    expected = sum((1:n_markers) >= 20 & (1:n_markers) <= 30);
    results = h__assert(results, ...
        abs(length(s_sub.times) - expected) <= 1, ...
        'MarkerRange: time_range [20,30] returns ~11 markers');

    % Verify returned times are within range
    if ~isempty(s_sub.times)
        results = h__assert(results, ...
            all(s_sub.times >= 19.9 & s_sub.times <= 30.1), ...
            'MarkerRange: all returned times within range');
    end

    % Get un-collapsed struct format
    s_nocollapse = mk.getData('collapse_struct', false, 'to_char', false);
    results = h__assert(results, ...
        length(s_nocollapse) == n_markers, ...
        'MarkerRange: uncollapsed struct array has correct length');

    clear f;
end

%% ========================================================================
%  TEST: EventBoth return_format variations
%  ========================================================================
function results = test_event_both_return_formats(results, temp_dir)
    fprintf('--- EventBoth Return Formats ---\n');

    time_base = 1e-5;
    [fhand, fp] = h__createFile(temp_dir, 'eb_formats', time_base);

    chan = CEDS64GetFreeChan(fhand);
    CEDS64SetLevelChan(fhand, chan, 1000);
    CEDS64SetInitLevel(fhand, chan, 0); % starts low

    % Transitions at 1,2,3,...10 seconds
    n_trans = 10;
    trans_ticks = zeros(n_trans, 1, 'int64');
    for i = 1:n_trans
        trans_ticks(i) = CEDS64SecsToTicks(fhand, i);
    end
    CEDS64WriteEvents(fhand, chan, trans_ticks);

    f = h__closeAndReopen(fhand, fp);
    eb = f.event_both(1);

    % times format
    s_times = eb.getTimes('return_format', 'times');
    results = h__assert(results, ...
        isfield(s_times, 'times') && isfield(s_times, 'start_level'), ...
        'EB formats: times format has times and start_level');

    % time_series1 format
    s_ts1 = eb.getTimes('return_format', 'time_series1');
    results = h__assert(results, ...
        isfield(s_ts1, 'x') && isfield(s_ts1, 'y'), ...
        'EB formats: time_series1 has x and y');
    results = h__assert(results, ...
        length(s_ts1.x) == length(s_ts1.y), ...
        'EB formats: time_series1 x and y same length');

    % time_series2 format (for direct plotting)
    s_ts2 = eb.getTimes('return_format', 'time_series2');
    results = h__assert(results, ...
        isfield(s_ts2, 'x') && isfield(s_ts2, 'y'), ...
        'EB formats: time_series2 has x and y');
    results = h__assert(results, ...
        length(s_ts2.x) == length(s_ts2.y), ...
        'EB formats: time_series2 x and y same length');
    results = h__assert(results, ...
        length(s_ts2.x) == 2 * n_trans + 2, ...
        'EB formats: time_series2 has 2*n_trans+2 points');

    % switch_times format
    s_sw = eb.getTimes('return_format', 'switch_times');
    results = h__assert(results, ...
        isfield(s_sw, 'rise_times') && isfield(s_sw, 'fall_times'), ...
        'EB formats: switch_times has rise_times and fall_times');
    results = h__assert(results, ...
        length(s_sw.rise_times) + length(s_sw.fall_times) == n_trans, ...
        'EB formats: total rise+fall equals n_transitions');

    % starts_and_stops format
    s_ss = eb.getTimes('return_format', 'starts_and_stops');
    results = h__assert(results, ...
        all(isfield(s_ss, {'start_high','stop_high','start_low','stop_low'})), ...
        'EB formats: starts_and_stops has all fields');

    clear f;
end