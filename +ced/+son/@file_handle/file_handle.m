classdef file_handle < handle
    %
    %   Class:
    %   ced.son.file_handle
    %
    %   All this does is hold onto the handle so that when
    %   this class is deleted the handle to the underling C library
    %   is deleted.

    %{
        root = 'D:\Data\Mickle';
        file_name = '03192024_20single_20void_20stimulation.smrx';
        file_path = fullfile(root,file_name);
        fh = ced.son.file_handle(file_path);
    %}

    properties
        %This is the raw C handle that needs to be passed
        %to the library functions.
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

            % 1: read only
            % 0: read and write
            % -1: try to open and read/write, if not use read-only


            %JAH: 2026-03-14 - It is not clear to me that this mode
            %actually works since I can't open read-only when the file
            %is open in Spike2
            %
            %   ??? Does -1 work? No, and the error message is strange:
            %
            %   :-------- READ ONLY  ------------:
            %   READ_ONLY: Failed to open a read-only file for writing
            %
            %   :-------- RW or on failure READ ONLY ------------:
            %   NO_FILE: Attempt to use when file not open, or use of an invalid file
            %   handle, or no spare file handle
            %
            %
            %
            %read only


            %Note, for some reason some .smr files that open in Spike2
            %fail to open with this code and throw an error -13, saying
            %that the file is not a valid SON file.

            MODE = 1;

            obj.h = CEDS64Open(file_path,MODE);
            if obj.h < 0
                %JAH 2026-05-23: What if we are trying to write? OK to be
                %missing? Check if folder exists?
                if ~exist(file_path,'file')
                   error('CED:file_handle:missing_file','Unable to open requested file:\n"%s"\nreason from CED lib:\n%s',file_path,msg) 
                end
                msg = ced.utils.CEDS64ErrorMessage(obj.h);
                error('CED:file_handle:open_failure','Unable to open requested file:\n"%s"\nreason from CED lib:\n%s',file_path,msg)
            end
        end
        function delete(obj)
            try
                response = CEDS64Close(obj.h); %#ok<NASGU>
                %disp(response);
            end
        end
    end
end