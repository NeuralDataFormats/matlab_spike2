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

            n_entries = length(s);
            id = [s.idAttribute]';
            lab_mode = [s.LabModeAttribute]';
            lab_pos = [s.LabPosAttribute]';
            num = [s.NumAttribute]';

            try
                pos = [s.PosAttribute]';
            catch
                pos = NaN(n_entries,1);
            end

            try
                a_mode = [s.AModeAttribute]';
            catch
                a_mode = NaN(n_entries,1);
            end

            obj.data = table(id,lab_mode,lab_pos,num,pos,a_mode);
        end
    end
end