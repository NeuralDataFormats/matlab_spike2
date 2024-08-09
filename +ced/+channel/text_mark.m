classdef text_mark < ced.channel.channel
    %
    %   Class:
    %   ced.channel.text_mark

    properties

    end

    methods
        function obj = text_mark(h,chan_id)
            %
            %   t = ced.channel.text_mark(h,chan_id)

            obj@ced.channel.channel(h,chan_id); 
            %cols does not appear to be useful
            %rows is supposed to be max string length but this 
            %   seems like max possible, not max actual
            %[iOk,Rows,Cols] = CEDS64GetExtMarkInfo( obj.h2, chan_id);

        end
        function t = getData(obj)
            %CEDS64ReadExtMarks
            %{

            function [ iRead, ExtMarkers ] = CEDS64ReadExtMarks( fhand, iChan, iN,  i64From, i64To, maskh )
            %CEDS64READEXTMARKS Reads extended marker data from a extended marker channels
            %   [ iRead, ExtMarkers ] = CEDS64ReadExtMarks( fhand, iChan, iN,  i64From {, i64To {, maskh}} )
            %   Inputs
            %   fhand - An integer handle to an open file
            %   iChan - A channel number for an extended event channel
            %   iN - The maximum number of data points to read
            %   i64From - The time in ticks of the earliest time you want to read
            %   i64To - (Optional) The time in ticks of the latest time you want to
            %   read. If not set or set to -1, read to the end of the channel
            %   maskh -  (Optional) An integer handle to a marker mask
            %   Outputs
            %   iRead - The number of data points read or a negative error code
            %   ExtMarkers - An array of CED64Markers
            %}

            in.max_events = 1e6;
            in.time_range = [0 obj.max_time+1];
            
            t1 = in.time_range(1);
            t2 = in.time_range(2);

            %state = ced.utils.turnStructWarningOn;


            %This call is really slow. Why doesn't the file track 
            %[a,b] = CEDS64ReadExtMarks(obj.h2,obj.chan_id,in.max_events,t1,t2);
            [~,s] = ced.utils.readTextMarkersFast(obj.h2,obj.chan_id,in.max_events,t1,t2);

            %ced.utils.restoreWarningState(state);

            t = struct2table(s);

            % msg = {b.m_Data}';
            % time = [b.m_Time]';
            % code1 = [b.m_Code1]';
            % code2 = [b.m_Code2]';
            % code3 = [b.m_Code3]';
            % code4 = [b.m_Code4]';
            % t = table(msg,time,code1,code2,code3,code4);

        end
    end
end