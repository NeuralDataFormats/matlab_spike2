classdef adc < ced.channel.channel
    %
    %   Class:
    %   ced.channel.adc

    properties
        
    end

    methods
        function obj = adc(h,chan_id)
            obj@ced.channel.channel(h,chan_id); 
        end
        function [data,time] = getData(obj,varargin)

            in.read_raw = false;
            in.time_range = [];
            in = ced.sl.in.processVarargin(in,varargin);

            %user value = (16-bit value) * scale /6553.6 + offset

            %CEDS64ReadWaveS Read waveform data as 16-bit integers
            %CEDS64ReadWaveF Read waveform

            keyboard
            n_samples = obj.max_time*obj.fs;
            [n_read,data,start_time] = CEDS64ReadWaveF(obj.h2,obj.chan_id,n_samples,0);


            %{
                function [ iRead, fVals, i64Time ] = CEDS64ReadWaveF( fhand, iChan, iN, i64From, i64To, maskh )
                %CEDS64READWAVE32 Reads wave data from a waveform or realwave channel as singles (32-bit floats).
                %   [ iRead, fVals, i64Time ] = CEDS64ReadWaveF( fhand, iChan, iN, i64From {, i64To {, maskh} } )
                %   Inputs
                %   fhand - An integer handle to an open file
                %   iChan - A channel number for a Waveform or Realwave channel
                %   iN - The maximum number of data points  to copy
                %   i64From - The time in ticks of the earliest time you want to read
                %   i64To - (Optional) The time in ticks of the latest time you want to
                %   read. If not set or set to -1, read to the end of the channel
                %   maskh - (Optional) An integer handle to a marker mask (only used when reading wavemarkers)
                %   Outputs
                %   iRead - The number of data points read
                %   fVals - An array of floats conatining the data points
                %   i64Time - The time in ticks of the first data point

            %}
        end
    end
end