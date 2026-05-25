function err_msg = CEDS64ErrorMessage(iErrorCode)
%
%   err_msg = ced.utils.CEDS64ErrorMessage(iErrorCode)
%
%   The CEDS64ErrorMessage in the library throws a warning message
%   rather than returning a string. This version returns the string.
%
%   Improvements
%   ------------
%   1) 

if ~(isnumeric(iErrorCode) && isscalar(iErrorCode) && isfinite(iErrorCode))
    error('iErrorCode must be a finite numeric scalar.')
end

iErrorCode = double(iErrorCode);

switch iErrorCode
    case 0
        err_msg = 'S64_OK: There was no error.';
    case -1
        err_msg = ['NO_FILE: Attempt to use when file not open, or use of an ' ...
            'invalid file handle, or no spare file handle. Some functions that ' ...
            'return a time will return -1 to mean nothing found, so this is not ' ...
            'necessarily an error. Check the function description.'];
    case -2
        err_msg = ['NO_BLOCK: Failed to allocate a disk block when writing to ' ...
            'the file. The disk is probably full, or there was a disk error.'];

    case -3
        err_msg = ['CALL_AGAIN: This is a long operation, call again. If you see ' ...
            'this, something has gone wrong as this is for internal SON library use only.'];

    case -5
        err_msg = ['NO_ACCESS: This operation was not allowed. Bad access ' ...
            '(privilege violation), file in use by another process.'];

    case -8
        err_msg = 'NO_MEMORY: Out of memory reading a 32-bit SON file.';

    case -9
        err_msg = 'NO_CHANNEL: A channel does not exist.';

    case -10
        err_msg = 'CHANNEL_USED: Attempt to reuse a channel that already exists.';

    case -11
        err_msg = 'CHANNEL_TYPE: The channel cannot be used for this operation.';

    case -12
        err_msg = ['PAST_EOF: Read past the end of the file. This probably means ' ...
            'that the file is damaged or that there was an internal library error.'];

    case -13
        err_msg = 'WRONG_FILE: Attempt to open wrong file type. This is not a SON file.';

    case -14
        err_msg = 'NO_EXTRA: A request to read user data is outside the extra data region.';

    case -17
        err_msg = 'BAD_READ: A read error was detected. This is an operating system error.';

    case -18
        err_msg = 'BAD_WRITE: Something went wrong writing data. This is an operating system error.';

    case -19
        err_msg = 'CORRUPT_FILE: The file is bad or an attempt to write corrupted data.';

    case -20
        err_msg = ['PAST_SOF: An attempt was made to access data before the start ' ...
            'of the file. This probably means that the file is damaged, or there ' ...
            'was an internal library error.'];

    case -21
        err_msg = 'READ_ONLY: Attempt to write to a read only file.';

    case -22
        err_msg = 'BAD_PARAM: A bad parameter to a call into the SON library.';

    case -23
        err_msg = 'OVER_WRITE: An attempt was made to over-write data when not allowed.';

    case -24
        err_msg = ['MORE_DATA: A file is bigger than the header says; maybe not ' ...
            'closed correctly. Use S64Fix on it.'];

    otherwise
        error('Unrecognized CEDS64 error code: %d', iErrorCode)
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