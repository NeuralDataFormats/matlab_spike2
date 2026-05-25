# Spike2 Interface for MATLAB #

This code loads Spike2 files into MATLAB. It is a wrapper around the [spike2matson](https://ced.co.uk/upgrades/spike2matson) library provided by CED and is meant to provide a nicer interface to that library.

**Note, work on this code was supported by a grant from the NIH NIDDK ([grant: R21DK140694](https://reporter.nih.gov/project-details/11232104))**

# Remaining TODOs #

- finish documentation
- create some testing framework ...
- There are a ton of places where we should be checking for errors but don't yet. The underlying mex returns error codes rather than directly throwing errors

# Installation Steps #

The folder that contains this file should be added to the MATLAB path.

More info on that here:
https://www.mathworks.com/help/matlab/matlab_env/add-remove-or-reorder-folders-on-the-search-path.html

Note, I personally add the path at startup using my *startup.m* file

Do not add the '+ced' folder to the path, or any of its sub-folders, just the root folder.

Example:
```
addpath('C:\repos\matlab\matlab_spike2')
```

# Example Files #

For testing purposes I've created a repository of example files that I've found around the internet. They can be found in this repo:

https://github.com/JimHokanson/spike2_example_files

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

%Note, d is a structure and possibly a structure array if pauses exist (see demo1.smr in example files)
d = w.getData();

%Plot the data
hold on
for i = 1:length(d)
    plot(d(i).time,d(i).data)
end
hold off
ylabel(sprintf('%s (%s)',w.name,w.units))

```


