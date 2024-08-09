classdef file_handle < handle
    %
    %   Class:
    %   ced.son.file_handle

    %{
        root = 'D:\Data\Mickle';
        file_name = '03192024_20single_20void_20stimulation.smrx';
        file_path = fullfile(root,file_name);
        fh = ced.son.file_handle(file_path);
    %}

    properties
        h
    end

    methods
        function obj = file_handle(file_path)

        %CEDS64OPEN Opens an exiting SON file
        %   [ fhand ] = CEDS64Open( sFileName {, iMode} )
        %   Inputs
        %   sFileName - String contain the path and file of the file we wish to
        %   iMode - (Optional) 1= read only, 0 = read and write, -1 try to open as
        %   read write, if that fails try to open a read only open
        %   Outputs
        %   fhand - An integer handle for the file, otherwise a negative error code.
        
            obj.h = CEDS64Open(file_path);
        end
        function delete(obj)
            try
                response = CEDS64Close(obj.h); %#ok<NASGU>
                %disp(response);
            end
        end
    end
end