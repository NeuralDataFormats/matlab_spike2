classdef file
    %
    %   ced.file

    %{
        root = 'D:\Data\Mickle';
        file_name = '03192024_20single_20void_20stimulation.smrx';
        file_path = fullfile(root,file_name);
        file = ced.file(file_path);
    %}

    properties
        h
        version
        file_size
        n_ticks
        n_seconds
        start_date
        time_base

        chan_types
        chan_names

        waveforms
        markers
        text_markers
        t
    end

    methods
        function obj = file(file_path)
            obj.h = ced.son.file_handle(file_path);
            obj.version = ced.son.version(obj.h);
            h2 = obj.h.h;

            %obj.n_ticks = CEDS64ChanMaxTime( fhand1, 1 )
            %
            %- short string for an app, normally app name that created file
            %CEDS64AppID( fhand {, IDIn } )
            %
            %- comment for each channel
            %CEDS64ChanComment
            %
            %CEDS64FileSize
            %
            %5 comments allowed
            %CEDS64FileComment
            %
            %next free chan
            %   CEDS64GetFreeChan(

            %temp = CEDS64GetFreeChan(obj.h.h)

            obj.n_ticks = CEDS64MaxTime(h2);

            [~,t] = CEDS64TimeDate(h2);
            t(1) = t(1)/10;
            t = t(end:-1:1);
            t = num2cell(t);
            obj.start_date = datetime(t{:});
            obj.time_base = CEDS64TimeBase(h2);

            obj.n_seconds = obj.n_ticks*obj.time_base;

            n_chans_max = CEDS64MaxChan(h2);
            chan_type = zeros(n_chans_max,1);

            objs = cell(n_chans_max,1);
            chan_name = cell(n_chans_max,1);

            %TODO: If negative throw errror
            for i = 1:n_chans_max
                chan_type(i) = CEDS64ChanType(h2,i);  

                t = struct('name','unusued');
                switch chan_type(i)
                    case 0 %unused
                    case 1 %ADC - Waveform
                        t = ced.channel.adc(obj.h,i);
                    case 2 %EventFall

                    case 3 %EventRise

                    case 4 %EventBoth

                    case 5 %Marker
                        t = ced.channel.marker(obj.h,i);
                    case 6 %WaveMark

                    case 7 %RealMark

                    case 8 %TextMark
                        t = ced.channel.text_mark(obj.h,i);
                end
                objs{i} = t;
                chan_name{i} = t.name;

                %{
iType Either the channel type or a negative error code. Channel types are: 0=channel unused, 1=Adc,
2=EventFall, 3=EventRise, 4=EventBoth, 5=Marker, 6=WaveMark, 7=RealMark, 8=TextMark,
9=RealWave.
                %}
            end

            chan_id = (1:n_chans_max)';
            mask = chan_type ~= 0;
            chan_name = chan_name(mask);
            chan_type = chan_type(mask);
            chan_id = chan_id(mask);
            objs = objs(mask);
            obj.t = table(chan_name,chan_type,chan_id);

            obj.chan_types = chan_type;
            obj.chan_names = chan_name;

            temp = objs(chan_type == 1);
            obj.waveforms = [temp{:}];

            temp = objs(chan_type == 5);
            obj.markers = [temp{:}];

            temp = objs(chan_type == 8);
            obj.text_markers = [temp{:}];


        end
    end
end