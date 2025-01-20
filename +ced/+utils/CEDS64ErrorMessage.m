function [errmsg] = CEDS64ErrorMessage(iErrorCode)
%
%   errmsg = ced.utils.CEDS64ErrorMessage(iErrorCode)
%
%   The CEDS64ErrorMessage in the library throws a warning message
%   rather than returning a string. This version returns the string.
%
%

switch iErrorCode
    case -1
        errmsg = ['NO_FILE: Attempt to use when file not open, or use of an' ...
            ' invalid file handle, or no spare file handle'];
    case -2
        errmsg = ['NO_BLOCK: Failed to allocate a disk block when writing to' ...
            'the file. The disk is probably full, or there was a disk error.'];
    %case -3

    %case -5

    case -9
        errmsg = 'NO_CHANNEL: A channel does not exist.';
    case -10
        errmsg = 'CHANNEL_USED: Attempt to reuse a channel that already exists.';
    case -13
        errmsg = '-13 WRONG_FILE Attempt to open wrong file type. This is not a SON file.';
    case -21
        errmsg = 'READ_ONLY: Failed to open a read-only file for writing';
    otherwise
        error('unrecognized error code')
end

return

%-------------------------------------
%       Early exit due to bug
%-------------------------------------


%CEDS64ERRORMESSAGE This function converts integer error codes into warnings
%describing the errors in plain english.
%   [ ] = CEDS64ErrorMessage( iErrorCode )
%   Inputs
%   iErrorCode - An negative integer code.
%   Outputs nothing, just generates a warning
if (isnumeric(iErrorCode) && iErrorCode < 0)
    %step 1 find out how big the title is is
    dummystring = blanks(1);
    [iSize] = calllib('ceds64int', 'S64GetErrorMessage', iErrorCode, dummystring, -1);
    %step 2 create a string buffer of the correct size
    errmsg = blanks(iSize+1);
    calllib('ceds64int', 'S64GetErrorMessage', iErrorCode, errmsg, 0);
    %???????????????????????
    %??? Why is this not working?

    %step 3 generate the warning message
    %warning(errmsg);
else
    %
    error('Unexpected error code: %d',iErrorCode)
end



end

%{

0 S64_OK There was no error
-1 NO_FILE Attempt to use when file not open, or use of an invalid file handle, or no spare
file handle. Some functions that return a time will return -1 to mean nothing
found, so this is not necessarily an error. Check the function description.
-2 NO_BLOCK Failed to allocate a disk block when writing to the file. The disk is probably full,
or there was a disk error.
-3 CALL_AGAIN This is a long operation, call again. If you see this, something has gone wrong
as this if for internal SON library use, only.
-5 NO_ACCESS This operation was not allowed. Bad access (privilege violation), file in use by
another process.
-8 NO_MEMORY Out of memory reading a 32-bit son file.
-9 NO_CHANNEL A channel does not exist.
-10 CHANNEL_USED Attempt to reuse a channel that already exists.
-11 CHANNEL_TYPE The channel cannot be used for this operation.
-12 PAST_EOF Read past the end of the file. This probably means that the file is damaged or
that there was an internal library error.
-13 WRONG_FILE Attempt to open wrong file type. This is not a SON file.
-14 NO_EXTRA A request to read user data is outside the extra data region.
-17 BAD_READ A read error (disk error) was detected. This is an operating system error.
-18 BAD_WRITE Something went wrong writing data. This is an operating system error.
-19 CORRUPT_FILE The file is bad or an attempt to write corrupted data.
-20 PAST_SOF An attempt was made to access data before the start of the file. This probably
means that the file is damaged, or there was an internal library error.
-21 READ_ONLY Attempt to write to a read only file.
-22 BAD_PARAM A bad parameter to a call into the SON library.
-23 OVER_WRITE An attempt was made to over-write data when not allowed.
-24 MORE_DATA A file is bigger than the header says; maybe not closed correctly. Use S64Fix on
it.

%}