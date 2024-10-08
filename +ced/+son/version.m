classdef version < handle
    %
    %   Class:
    %   ced.son.version

    properties
        value
    end

    methods
        function obj = version(file_handle)
            %
            %   v = ced.son.version(file_handle)
            
            %CEDS64VERSION Get the file version number
            %   [ version ] = CEDS64Version( fhand )
            %   Inputs
            %   fhand - An integer handle to an open file
            %   Outputs
            %   iVersion -  The version number of the file. Versions 1 to 8 are 32-bit
            %   files with a maximum size of 2 GB. Version 9 is a 32-bit file with a
            %   maximum size of 1 TB. Versions 256 and later are 64-bit files.

            obj.value = CEDS64Version(file_handle.h);
        end
    end
end