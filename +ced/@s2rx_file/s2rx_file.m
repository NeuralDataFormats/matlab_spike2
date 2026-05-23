classdef s2rx_file < handle
    %
    %   Class:
    %   ced.s2rx_file
    %

    properties
        file_path
        x_info
    end

    methods
        function obj = s2rx_file(file_path)
            %
            %   obj = ced.s2rx_file(file_path)
            %x = xmlread(file_path);
            x = readstruct(file_path,'FileType','xml');
            try
                x_info = x.DocTime.View.XInfo;
            catch
                x_info = [];
            end
            if length(x_info) > 1
                %TODO: Warning
                x_info = x_info(1);
            end
            if ~isempty(x_info)
                obj.x_info = ced.s2rx.XInfo(x_info);
            end
        end
        function t = getVerticalCursorPositions(obj)
            t = [];
            if ~isempty(obj.x_info) && ~isempty(obj.x_info.vcursor)
                t = obj.x_info.vcursor.data;
            end
        end
    end
end

%{
CEDResources
    DocTime
        ChanProc
        View
            WPlace
            Font
            Chan
                FitParam
                    C
            XInfo
                VCur: id, LabMode, LabPos, Num, AMod
                ActC: id
                HCur: id, Pos, LabMode, LabPos, Num
            ChOrder
            CursVals
            CursRegs
            OvDraw3d


%}