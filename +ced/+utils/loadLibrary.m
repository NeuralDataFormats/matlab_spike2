function loadLibrary()
%
%   ced.utils.loadLibrary()
%
%   Note this is called by ced.file if the library is not loaded
%
%   Below is a rewrite of:
%   CEDS64LoadLib
%
%   It has not been tested with 32bit MATLAB
%
%   Note, this function modifies your MATLAB path
%
%
%   Paths that get added:
%   1) CEDS64ML folder
%   2) The x64 or x32 folder (inside CEDS64ML)

%Handle pathing
%------------------------------------------
p = which('CEDS64LoadLib');
if isempty(p)
    file_path = which('ced.utils.loadLibrary');
    repo_root = fileparts(fileparts(fileparts(file_path)));
    ced_code_root = fullfile(repo_root,'ced_provided_code','CEDS64ML');
    %I moved the loadLibrary() function and this happened. Adding this
    %check just in case.
    if ~exist(ced_code_root,'dir')
        error('Internal code error, CED folder is missing')
    end
    addpath(ced_code_root);
    switch mexext
        case 'mexw64'
            mex_root = fullfile(ced_code_root,'x64');
        case 'mexw32'
            mex_root = fullfile(ced_code_root,'x32');
        otherwise
            error('Code only supported for 32 and 64 bit Windows')
    end
    addpath(mex_root)
end

%Unload if already loaded
%-------------------------------------------
if libisloaded('ceds64int')
    CEDS64CloseAll(); % ...close all open SON files...
    unloadlibrary ceds64int;   % ...unload the library...
end

%Load the library
%-------------------------------------------------
switch mexext
    case 'mexw32'
        loadlibrary('ceds64int.dll', @ceds32Prot); %...load it
    case 'mexw64'
        loadlibrary('ceds64int', @ceds64Prot); %...load it
    otherwise
        error('Code only supported for 32 and 64 bit Windows')
end


end
