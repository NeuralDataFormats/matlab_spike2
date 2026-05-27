function results = test_002__round_trip_testing()
%TEST_CED_ROUNDTRIP_ALL_SUPPORTED
%
% Creates a synthetic CED/Spike2 .smrx file exercising the channel types
% currently supported by NeuralDataFormats/matlab_spike2, then reads it back
% using ced.file and verifies the data.
%
%   
%   ISSUES
%   --------
%   - ced.utils.readRealMarkersFast
%   - CEDS64WriteExtMarks

ced.utils.loadLibraryIfNeeded();

p = which('test_002__round_trip_testing');
root = fileparts(p);

out_file = fullfile(root,'test_002_file.smrx');

if isfile(out_file)
    delete(out_file);
end

fixture = createCedFixture(out_file);
results = readAndVerifyCedFixture(out_file, fixture);

fprintf("CED round-trip test passed: %s\n", out_file);

end

function fixture = createCedFixture(outFile)

% Create a 64-bit .smrx file.
% CEDS64Create(file, nChans, iType), where iType 2 = 64-bit .smrx.
fhand = CEDS64Create(char(outFile), 16, 2);
assert(fhand >= 0, "CEDS64Create failed with code %d", fhand);

cleanup = onCleanup(@() safeClose(fhand));

% Synthetic data fixture.
fixture.file = char(outFile);
fixture.timeBase = CEDS64TimeBase(fhand);

% Use integer ticks directly. Most event-like read methods in the repo
% convert ticks to seconds by dividing by fs = 1 / file.time_base.
eventTicks = int64([1000 2000 3000 4000 5000])';

% Channel IDs.
CH_ADC       = 1;
CH_EVENT_F   = 2;
CH_EVENT_R   = 3;
CH_LEVEL     = 4;
CH_MARKER    = 5;
CH_WAVEMARK  = 6;
CH_REALMARK  = 7;
CH_TEXTMARK  = 8;
CH_REALWAVE  = 9;

% ADC / waveform channel.
adcDiv = int64(10);
fixture.adc.raw = int16(round(12000 * sin((0:999) * 2*pi/100)));
fixture.adc.chan = CH_ADC;
fixture.adc.div = double(adcDiv);
fixture.adc.scale = 2.5;
fixture.adc.offset = -0.25;
fixture.adc.expectedDouble = double(fixture.adc.raw) * fixture.adc.scale / 6553.6 + fixture.adc.offset;

mustOk(CEDS64SetWaveChan(fhand, CH_ADC, adcDiv, 1, 0), "CEDS64SetWaveChan ADC");
setChanText(fhand, CH_ADC, "adc_sine", "mV", "ADC sine test");
setWaveScaling(fhand, CH_ADC, fixture.adc.scale, fixture.adc.offset, [-3 3]);
endTick = CEDS64WriteWave(fhand, CH_ADC, fixture.adc.raw, int64(0));
assert(endTick > 0, "CEDS64WriteWave failed with code %d", endTick);

% Event fall.
fixture.eventFall.chan = CH_EVENT_F;
fixture.eventFall.ticks = eventTicks;
mustOk(CEDS64SetEventChan(fhand, CH_EVENT_F, 0, 2), "CEDS64SetEventChan fall");
setChanText(fhand, CH_EVENT_F, "event_fall", "", "falling edge events");
mustOk(CEDS64WriteEvents(fhand, CH_EVENT_F, eventTicks), "CEDS64WriteEvents fall");

% Event rise.
fixture.eventRise.chan = CH_EVENT_R;
fixture.eventRise.ticks = eventTicks + int64(250);
mustOk(CEDS64SetEventChan(fhand, CH_EVENT_R, 0, 3), "CEDS64SetEventChan rise");
setChanText(fhand, CH_EVENT_R, "event_rise", "", "rising edge events");
mustOk(CEDS64WriteEvents(fhand, CH_EVENT_R, fixture.eventRise.ticks), "CEDS64WriteEvents rise");

% Level / EventBoth.
fixture.level.chan = CH_LEVEL;
fixture.level.ticks = int64([750 1750 2750 3750])';
fixture.level.initial = 0;
mustOk(CEDS64SetMarkerChan(fhand, CH_LEVEL, 0, 4), "CEDS64SetMarkerChan level");
mustOk(CEDS64SetInitLevel(fhand, CH_LEVEL, fixture.level.initial), "CEDS64SetInitLevel");
setChanText(fhand, CH_LEVEL, "level_both", "", "level transition events");
mustOk(CEDS64WriteLevels(fhand, CH_LEVEL, fixture.level.ticks), "CEDS64WriteLevels");

% Marker channel.
fixture.marker.chan = CH_MARKER;
fixture.marker.ticks = int64([600 1600 2600])';
fixture.marker.codes = uint8([65 66 67; 1 2 3; 10 20 30; 100 101 102]); % rows = code1..code4
mustOk(CEDS64SetMarkerChan(fhand, CH_MARKER, 0, 5), "CEDS64SetMarkerChan marker");
setChanText(fhand, CH_MARKER, "Keyboard", "", "keyboard marker test");

markers(1, numel(fixture.marker.ticks)) = CEDMarker();
for i = 1:numel(fixture.marker.ticks)
    markers(i) = CEDMarker( ...
        fixture.marker.ticks(i), ...
        fixture.marker.codes(1,i), ...
        fixture.marker.codes(2,i), ...
        fixture.marker.codes(3,i), ...
        fixture.marker.codes(4,i));
end
mustOk(CEDS64WriteMarkers(fhand, CH_MARKER, markers), "CEDS64WriteMarkers");

% WaveMark channel.
fixture.waveMark.chan = CH_WAVEMARK;
fixture.waveMark.rows = 16;
fixture.waveMark.cols = 2;
fixture.waveMark.div = int64(5);
fixture.waveMark.ticks = int64([1100 2100 3100]);
fixture.waveMark.scale = 1.25;
fixture.waveMark.offset = 0.5;
mustOk(CEDS64SetExtMarkChan(fhand, CH_WAVEMARK, 0, 6, ...
    fixture.waveMark.rows, fixture.waveMark.cols, fixture.waveMark.div), ...
    "CEDS64SetExtMarkChan wavemark");
setChanText(fhand, CH_WAVEMARK, "wave_mark", "uV", "wave marker snippets");
setWaveScaling(fhand, CH_WAVEMARK, fixture.waveMark.scale, fixture.waveMark.offset, [-2 2]);

waveMarks(1, numel(fixture.waveMark.ticks)) = CEDWaveMark();
fixture.waveMark.raw = cell(1, numel(fixture.waveMark.ticks));
for i = 1:numel(fixture.waveMark.ticks)
    raw = int16(reshape(1:(fixture.waveMark.rows * fixture.waveMark.cols), ...
        fixture.waveMark.rows, fixture.waveMark.cols) + 100*i);
    fixture.waveMark.raw{i} = raw;
    waveMarks(i) = CEDWaveMark(fixture.waveMark.ticks(i), i, i+1, i+2, i+3, raw);
end
mustOk(CEDS64WriteExtMarks(fhand, CH_WAVEMARK, waveMarks), "CEDS64WriteExtMarks wavemark");

% RealMark channel.
fixture.realMark.chan = CH_REALMARK;
fixture.realMark.rows = 10;
fixture.realMark.cols = 2;
fixture.realMark.ticks = int64(10:100:2000)';
mustOk(CEDS64SetExtMarkChan(fhand, CH_REALMARK, 0, 7, ...
    fixture.realMark.rows, fixture.realMark.cols), ...
    "CEDS64SetExtMarkChan realmark");
setChanText(fhand, CH_REALMARK, "real_mark", "", "real marker data");

realMarks(1, numel(fixture.realMark.ticks)) = CEDRealMark();
fixture.realMark.data = cell(1, numel(fixture.realMark.ticks));
for i = 1:numel(fixture.realMark.ticks)
    r = fixture.realMark.rows;
    c = fixture.realMark.cols;
    data = (reshape(1:(r*c),r,c) + 10*i)/10;
    %data = single(reshape())
    %data = single(reshape((1:6) + 10*i, fixture.realMark.rows, fixture.realMark.cols) / 10);
    fixture.realMark.data{i} = data;
    realMarks(i) = CEDRealMark(fixture.realMark.ticks(i), i, i+1, i+2, i+3, data);
end
mustOk(CEDS64WriteExtMarks(fhand, CH_REALMARK, realMarks), "CEDS64WriteExtMarks realmark");

% TextMark channel.
fixture.textMark.chan = CH_TEXTMARK;
fixture.textMark.maxLen = 64;
fixture.textMark.ticks = int64([1300 2300 3300])';
fixture.textMark.text = ["alpha", "beta", "gamma"];
mustOk(CEDS64SetTextMarkChan(fhand, CH_TEXTMARK, 0, fixture.textMark.maxLen), ...
    "CEDS64SetTextMarkChan");
setChanText(fhand, CH_TEXTMARK, "text_mark", "", "text marker test");

textMarks(1, numel(fixture.textMark.ticks)) = CEDTextMark();
for i = 1:numel(fixture.textMark.ticks)
    textMarks(i) = CEDTextMark(fixture.textMark.ticks(i), i, i+1, i+2, i+3, char(fixture.textMark.text(i)));
end
mustOk(CEDS64WriteExtMarks(fhand, CH_TEXTMARK, textMarks), "CEDS64WriteExtMarks textmark");


% RealWave / floating-point waveform channel.
realWaveDiv = int64(20);
fixture.realWave.chan = CH_REALWAVE;
fixture.realWave.div = double(realWaveDiv);
fixture.realWave.data = single(cos((0:499) * 2*pi/50) * 3.25 + 0.75)';

mustOk(CEDS64SetWaveChan(fhand, CH_REALWAVE, realWaveDiv, 9, 0), ...
    "CEDS64SetWaveChan RealWave");
setChanText(fhand, CH_REALWAVE, "realwave_cosine", "V", "RealWave cosine test");

endTick = CEDS64WriteWave(fhand, CH_REALWAVE, fixture.realWave.data, int64(0));
assert(endTick > 0, "CEDS64WriteWave failed with code %d", endTick);


% Some file-level metadata.
try
    CEDS64AppID(fhand, "MATTEST");
catch
    % Older CED wrapper versions can be picky about AppID input.
end

try
    CEDS64FileComment(fhand, 1, "Created by test_ced_roundtrip_all_supported");
catch
end

CEDS64Close(fhand);
delete(cleanup);

end

function results = readAndVerifyCedFixture(outFile, fixture)

f = ced.file(outFile);

results.file = f;
results.typeSummary = f.getTypeSummary();

% Type summary.
assert(results.typeSummary.adc == 1, "Expected one ADC channel.");
assert(results.typeSummary.event_fall == 1, "Expected one EventFall channel.");
assert(results.typeSummary.event_rise == 1, "Expected one EventRise channel.");
assert(results.typeSummary.event_both == 1, "Expected one EventBoth/level channel.");
assert(results.typeSummary.marker == 1, "Expected one Marker channel.");
assert(results.typeSummary.wave_marker == 1, "Expected one WaveMark channel.");
assert(results.typeSummary.real_marker == 1, "Expected one RealMark channel.");
assert(results.typeSummary.text_marker == 1, "Expected one TextMark channel.");

% Channel lookup functionality.
ch = f.getChannels(["adc_sine", "realwave_cosine", "event_fall", "event_rise", ...
                    "level_both", "Keyboard", "wave_mark", "real_mark", ...
                    "text_mark"], ...
                    partial_match = false);
assert(numel(ch) == 9, "getChannels did not return nine channels.");

% ADC read.
adc = f.waveforms(1);
adcData = adc.getData(return_format = "double", time_format = "numeric");
assert(numel(adcData) == 1, "Expected contiguous ADC read.");
assertAlmostEqual(adcData.data(:), fixture.adc.expectedDouble(:), 1e-10, "ADC scaled data mismatch.");

adcRaw = adc.getData(return_format = "int16", time_format = "none");
assert(isequal(adcRaw.data(:), fixture.adc.raw(:)), "ADC int16 data mismatch.");

% Event fall/rise.
fall = f.event_falls(1).getTimes();
rise = f.event_rises(1).getTimes();
assertAlmostEqual(fall(:), ticksToSeconds(fixture.eventFall.ticks, f), 1e-12, "EventFall times mismatch.");
assertAlmostEqual(rise(:), ticksToSeconds(fixture.eventRise.ticks, f), 1e-12, "EventRise times mismatch.");

% EventBoth / level channel.
level = f.event_both(1).getTimes(return_format = "times");
assertAlmostEqual(level.times(:), ticksToSeconds(fixture.level.ticks, f), 1e-12, "Level transition times mismatch.");
assert(level.start_level == fixture.level.initial, "Initial level mismatch.");

sw = f.event_both(1).getTimes(return_format = "switch_times");
assert(isfield(sw, "rise_times") && isfield(sw, "fall_times"), "switch_times missing fields.");

ss = f.event_both(1).getTimes(return_format = "starts_and_stops");
assert(isfield(ss, "start_high") && isfield(ss, "stop_low"), "starts_and_stops missing fields.");

% Marker channel.
m = f.markers(1).getData(collapse_struct = true, to_char = false);
assertAlmostEqual(m.times(:), ticksToSeconds(fixture.marker.ticks, f), 1e-12, "Marker times mismatch.");
assert(isequal(uint8(m.c1(:))', fixture.marker.codes(1,:)), "Marker code1 mismatch.");
assert(isequal(uint8(m.c2(:))', fixture.marker.codes(2,:)), "Marker code2 mismatch.");
assert(isequal(uint8(m.c3(:))', fixture.marker.codes(3,:)), "Marker code3 mismatch.");
assert(isequal(uint8(m.c4(:))', fixture.marker.codes(4,:)), "Marker code4 mismatch.");

% WaveMark channel.
wmStruct = f.wave_markers(1).getData(return_format = "struct");
assert(numel(wmStruct) == numel(fixture.waveMark.ticks), "WaveMark count mismatch.");
for i = 1:numel(wmStruct)
    expected = double(fixture.waveMark.raw{i}) * fixture.waveMark.scale / 6553.6 + fixture.waveMark.offset;
    assertAlmostEqual(wmStruct(i).data, expected, 1e-10, "WaveMark scaled data mismatch.");
end

wmMatrix2 = f.wave_markers(1).getData(return_format = "matrix2");
assert(size(wmMatrix2.data, 3) == numel(fixture.waveMark.ticks), "WaveMark matrix2 event dimension mismatch.");

% RealMark channel.
rm = f.real_markers(1).getData(return_format = "struct2");
assertAlmostEqual(rm.time(:), ticksToSeconds(fixture.realMark.ticks, f), 1e-12, "RealMark times mismatch.");
for i = 1:numel(fixture.realMark.ticks)
    assertAlmostEqual(rm.data(:,:,i), fixture.realMark.data{i}, 1e-6, "RealMark data mismatch.");
end

% TextMark channel.
tm = f.text_markers(1).getData();
assert(height(tm) == numel(fixture.textMark.ticks), "TextMark count mismatch.");
assertAlmostEqual(tm.time(:), ticksToSeconds(fixture.textMark.ticks, f), 1e-12, "TextMark times mismatch.");
assert(all(strcmp(string(tm.text), fixture.textMark.text(:))), "TextMark text mismatch.");


assert(results.typeSummary.real_wave == 1, "Expected one RealWave channel.");

% RealWave read.
rw = f.real_waves(1);

rwData = rw.getData(return_format = "single", time_format = "numeric");
assert(numel(rwData) == 1, "Expected contiguous RealWave read.");
assertAlmostEqual(rwData.data(:), fixture.realWave.data(:), 1e-6, ...
    "RealWave single data mismatch.");

rwDouble = rw.getData(return_format = "double", time_format = "none");
assertAlmostEqual(rwDouble.data(:), double(fixture.realWave.data(:)), 1e-12, ...
    "RealWave double data mismatch.");

rwPartial = rw.getData( ...
    return_format = "double", ...
    time_format = "numeric", ...
    sample_range = [11 30]);

assert(numel(rwPartial.data) == 20, "RealWave partial sample count mismatch.");
assertAlmostEqual(rwPartial.data(:), double(fixture.realWave.data(11:30)), 1e-12, ...
    "RealWave partial sample data mismatch.");




results.adc = adcData;
results.marker = m;
results.waveMark = wmStruct;
results.realMark = rm;
results.textMark = tm;
results.realWave = rwData;

end

function sec = ticksToSeconds(ticks, f)
sec = double(ticks) .* f.time_base;
end

function setChanText(fhand, chan, titleText, unitsText, commentText)
try
    CEDS64ChanTitle(fhand, chan, char(titleText));
catch
end

try
    CEDS64ChanUnits(fhand, chan, char(unitsText));
catch
end

try
    CEDS64ChanComment(fhand, chan, char(commentText));
catch
end
end

function setWaveScaling(fhand, chan, scale, offset, yRange)
try
    CEDS64ChanScale(fhand, chan, scale);
catch
end

try
    CEDS64ChanOffset(fhand, chan, offset);
catch
end

try
    CEDS64ChanYRange(fhand, chan, yRange(1), yRange(2));
catch
end
end

function mustOk(code, label)
assert(code >= 0, "%s failed with code %d", label, code);
end

function assertAlmostEqual(actual, expected, tol, msg)
actual = double(actual);
expected = double(expected);
assert(isequal(size(actual), size(expected)), ...
    "%s Size mismatch. actual=%s expected=%s", ...
    msg, mat2str(size(actual)), mat2str(size(expected)));

err = max(abs(actual(:) - expected(:)));
assert(err <= tol, "%s Max abs err = %g, tol = %g", msg, err, tol);
end

function safeClose(fhand)
try
    CEDS64Close(fhand);
catch
end
end