%AbcXyz
%CEDS64ChanType
%
%CEDS64AbcXyz
%
%

%{
However we strongly advise against this, as it will often require you to
pass blocks of memory between MATLAB® and the library. If any of these
blocks are the wrong sizes it can crash the program, and potentially
corrupt your data. The CEDS64AbcXyz() functions calculate the required size
of the memory blocks and should be safe. Further, we may wish to modify the
details of the DLL interface; if you make direct calls your code could be
broken if we make any changes.
%}