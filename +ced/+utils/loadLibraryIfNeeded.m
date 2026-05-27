function loadLibraryIfNeeded()
%
%   ced.utils.loadLibraryIfNeeded();

if ~libisloaded('ceds64int') || ~exist('CEDMarker','class')
    ced.utils.loadLibrary();
end

end