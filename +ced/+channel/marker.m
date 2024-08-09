classdef marker < ced.channel.channel
    %
    %   Class:
    %   ced.channel.marker

    properties
        
    end

    methods
        function obj = marker(h,chan_id,parent)
            obj@ced.channel.channel(h,chan_id,parent); 
        end
    end
end