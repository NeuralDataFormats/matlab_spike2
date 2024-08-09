classdef marker < ced.channel.channel
    %
    %   ced.channel.marker

    properties
        
    end

    methods
        function obj = marker(h,chan_id)
            obj@ced.channel.channel(h,chan_id); 
        end
    end
end