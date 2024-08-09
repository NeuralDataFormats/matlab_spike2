function loadLibrary()
%
%   ced.loadLibrary()

p = which('CEDS64LoadLib');
if isempty(p)
    error('Unable to find SON library')
    %Available at:
    %https://ced.co.uk/upgrades/spike2matson
    %
    %Installs by default to:
    %addpath('C:\CEDMATLAB\CEDS64ML');
    %
    %
end

% lib_root = fileparts(p);

%???? What about ceds32int - will that show up if installed on 32 bit
%machine?

if libisloaded('ceds64int')
    CEDS64CloseAll(); % ...close all open SON files...
    unloadlibrary ceds64int;   % ...unload the library...
end

%JAH: what might really matter is the MATLAB bit version, not
%the processor ...
switch lower(computer('arch'))
    case 'win32'
        %JAH: User needs to add path on startup, not doing path management
        %here
        %
        % libpath = strcat(sPath, '\x86');
        % addpath(libpath);
        loadlibrary ('ceds64int.dll', @ceds32Prot); %...load it
    case 'win64'
        % libpath = strcat(sPath, '\x64');
        % addpath(libpath);
        loadlibrary ('ceds64int', @ceds64Prot); %...load it
    otherwise
        error('Code only supported for 32 and 64 bit Windows')
end


end
