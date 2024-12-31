classdef channel < handle
    %
    %   Class:
    %   ced.channel.channel

    %{
    Calls not yet handled
    ---------------------
    %- comment for each channel
    %CEDS64ChanComment

    %}

    properties
        parent ced.file
        h ced.son.file_handle
        h2
        chan_id
        n_ticks
        max_time

        name
        units
        comment

        fs
        offset
        scale

        %Time divisor from main clock to this clock
        chan_div
        y_range
    end

    methods
        function obj = channel(h,chan_id,parent)

            obj.parent = parent;
            obj.h = h;
            h2 = h.h;
            obj.h2 = h2;
            obj.chan_id = chan_id;

            %Is this samples or time? answer: samples
            obj.n_ticks = CEDS64ChanMaxTime(h2,chan_id);

            [~,obj.name] = CEDS64ChanTitle(h2,chan_id);
            [~,obj.units] = CEDS64ChanUnits(h2,chan_id);
            obj.units = strtrim(obj.units);
            [~,obj.comment] = CEDS64ChanComment(h2,chan_id);

            %No error message output option, single output
            chan_div = CEDS64ChanDiv(h2,chan_id);
            obj.chan_div = chan_div;
            time_base = parent.time_base;

            

            %From documentation:
            %SampleRateInHz =                     1.0
            %                 ---------------------------------------
            %                 (CEDS64ChanDiv(fhand, 1)*CEDS64TimeBase(fhand));

            
            obj.fs = 1/(chan_div*time_base);

            
            

            obj.max_time = parent.n_seconds; %obj.n_ticks/obj.fs;

            [~,chan_offset] = CEDS64ChanOffset(h2,chan_id);
            obj.offset = chan_offset;
            [~,chan_scale] = CEDS64ChanScale(h2,chan_id);
            obj.scale = chan_scale;

            [~,ylo,yhigh] = CEDS64ChanYRange(h2,chan_id);

            obj.y_range = [ylo yhigh];


            %{
TODO: CEDS64ChanComment   Get or set a channel comment
SKIPPING CEDS64ChanDelete    Delete a channel
DONE CEDS64ChanDiv       Get the waveform rate divisor (determines the waveform rate)
DONE CEDS64ChanMaxTime   Get last item time in a channel
DONE CEDS64ChanOffset    Get or set the wave scaling offset value
DONE CEDS64ChanScale     Get or set the wave scaling scale value
DONE CEDS64ChanTitle     Get or set the channel title
SKIPPING CEDS64ChanType      Get the type of a channel
DONE CEDS64ChanUnits     Get or set the channel units
SKIPPING CEDS64ChanUndelete  Undelete a channel that has been deleted but not reused
DONE CEDS64ChanYRange    Get or set two values that can be used for a channel range
SKIPPING CEDS64EditMarker    Modify data attached to a Marker or extended Marker channel
SKIPPING CEDS64GetExtMarkInfo Get information from an extended Marker channel



            %}
        end
    end
end