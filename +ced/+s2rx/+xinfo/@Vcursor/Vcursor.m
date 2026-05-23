classdef Vcursor < handle
    %
    %   Class:
    %   ced.s2rx.xinfo.Vcursor

    properties
        data
    end

    methods
        function obj = Vcursor(s)
            %
            %   obj = ced.s2rx.xinfo.Vcursor(s)

            id = [s.idAttribute]';
            lab_mode = [s.LabModeAttribute]';
            lab_pos = [s.LabPosAttribute]';
            num = [s.NumAttribute]';
            pos = [s.PosAttribute]';
            a_mode = [s.AModeAttribute]';

            obj.data = table(id,lab_mode,lab_pos,num,pos,a_mode);
        end
    end
end