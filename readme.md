# Spike2 Interface for MATLAB #

This code loads Spike2 files into MATLAB. It is a wrapper around the
spike2matson library provided by CED and is meant to provide a slightly
nicer interface to that library.

**Note, this is a work in progress**

# Remaining TODOs #

- finish data loading for all waveform types - only a couple are currently supported
- create repo with just example files
- move spike2matson code into this library and change installation accordingly
- finish documentation
- create some testing framework ...
- There are a ton of places where we should be checking for errors but don't yet. The underlying mex returns error codes rather than directly throwing errors

# Installation Steps #

Work in Progress

1. Download and install [this code](https://ced.co.uk/upgrades/spike2matson). Be sure to note the install location.
2. 

# Usage #

```
%Load the file
%-------------------------
file = ced.file(file_path);

%Get some data
%-------------------------
%(1) simply gets the first waveform channel. Note this may not by channel==1
%   as channel==1 may not exist or may be a different type
w = file.waveforms(1);
d = w.getData();

%Plot the data
hold on
for i = 1:length(d)
    plot(d(i).time,d(i).data)
end
hold off
ylabel(sprintf('%s (%s)',w.name,w.units))

```


