classdef XInfo < handle
    %
    %   Class:
    %   ced.s2rx.XInfo

    properties
        vcursor
    end

    methods
        function obj = XInfo(s)
            %
            %   obj = ced.s2rx.XInfo(s)

            if ~isempty(s.VCur)
                obj.vcursor = ced.s2rx.xinfo.Vcursor(s.VCur);
            end

        end
    end
end