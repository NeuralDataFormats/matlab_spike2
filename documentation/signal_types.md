# signal types #

# ADC #

These are signals sampled at a fixed rate. Somewhat surprisingly, at least to me, these signals may not be continuous (i.e., there may be gaps). Whether the signal is continuous or not is not evident, at least to me, until after reading the data. Thus, unfortunately, I am not able to offer two different interfaces, one for a channel with no gaps, and another for a channel with gaps.

An example response structure. Note if there are gaps there will be more than one structure entry (i.e., a structure array), where you would access the second entry (after a gap) by indexing into the structure array (e.g., s(2)), rather than indexing the fields (i.e., not s.data{2}).

```
               data: [12093×1 double]
    first_sample_id: 1
     last_sample_id: 12093
         start_time: 0.0100
          n_samples: 12093
               time: [1×12093 double]
```

# Marker #

A marker consists of a time and four codes. A common marker appears to be the "keyboard" marker which can log a single character. Note in the example below we've translated the marker codes to characters.

```
    time: 2.5549
      c1: 't'
      c2: ' '
      c3: ' '
      c4: ' '
```

# Event Rise, Event Fall, and Event Both #

These signals consist of event times, whether they are triggered by a rising edge signal, a falling edge signal, or both. Unlike the marker they do not have a code associated with them.

For rise and fall signals, the returned result is just times. For the "both" data type there are multiple possible formats.

Shown below is the 'time_series1' result from the 'return_format' option. In addition to documenting the times of the events ('x') it also documents the values of the events ('y', whether rising, 1, or falling, 0).
```
    hit_event_max: 0
                x: [1×753 double]
                y: [1×753 double]
```

# Wave Marker #

Wave markers are short snippets of data collected when an event occurs. I believe this was originally designed for recording action potential snippets. The number of samples collected per event is fixed. Somewhat surprisingly multiple snippets can be collected per event (what looks to be individual channels within a single "signal").

# Text Marker #

A Text Marker is similar to a Marker, but in addition to the time and codes it also contains a string for each entry. The current default is to return this as a table:

```
                     text                      time     code1    code2    code3    code4
    ______________________________________    ______    _____    _____    _____    _____

    {'Start decrease of output amplitude'}    2.0639      6        0        0        0  
    {'Start Increase of output amplitude'}    8.7413      1        0        0        0  
    {'Start Increase of output frequency'}    14.083      2        0        0        0  
    {'Start decrease of output amplitude'}    35.329      6        0        0        0  
    {'Start Increase of output amplitude'}    51.719      1        0        0        0  
```

# Real Marker #

The purpose of this marker type is a bit unclear to me. In addition to a time and codes it contains data, so in some sense this could be viewed as a sparse time/data class, as oppossed to ADC which samples more consistently. The confusing part is the shape of the data. In my example file I am seeing two samples per time, even though one of those two samples is always zero. I do not know if this is a bug and/or whether the shape of the data returned will ever vary between times.

Example data. Note this is one element of a structure array.

```
     data: [2×1 single]
     time: 0.8585
    code1: 2
    code2: 0
    code3: 0
    code4: 0
```

