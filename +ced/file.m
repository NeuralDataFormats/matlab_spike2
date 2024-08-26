classdef file
    %
    %   Class:
    %   ced.file

    %{
        root = 'D:\Data\Mickle';
        file_name = '03192024_20single_20void_20stimulation.smrx';
        file_path = fullfile(root,file_name);
        file = ced.file(file_path);

        %Where are the test files?
        %D:\Data\Mickle\sample_files

        name = 'example2.smr';
        root = "D:\Data\Mickle\sample_files";
        file = ced.file(fullfile(root,name));


        %  data.smr - Only ADC & Marker
        %  Demo.smr - ADC, Marker, EventFall
        %  Demo1.smr - ADC, EventRise
        %  Demo2.smr - ADC, Marker
        %  example_unprocessed.smrx - Only ADC & Marker
        %  example1.smr - invalid
        %  example2.smr - invalid

    %}

    properties (Constant)
        TYPE_NAME_MAP = {'ADC','EventFall','EventRise','EventBoth',...
                'Marker','WaveMark','RealMark','TextMark'};
    end

    properties
        h
        version
        file_size
        n_ticks
        n_seconds
        start_date
        time_base

        chan_type_numeric
        chan_type_string
        chan_names

        waveforms
        markers
        text_markers
        t
    end

    methods
        function obj = file(file_path)
            %
            %   f = ced.file(file_path)

            if isstring(file_path)
                file_path = char(file_path);
            end

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
            chan_type_numeric = zeros(n_chans_max,1);

            objs = cell(n_chans_max,1);
            chan_name = cell(n_chans_max,1);

            %TODO: If negative throw the specific errror
            %
            %   Note, not all channels are actually used. It appears from
            %   the documentation that the "generic" loading approach
            %   is to iterate through all (i.e., can't skip to specific
            %   channels that are in use)
            %

            
            for i = 1:n_chans_max
                chan_type_numeric(i) = CEDS64ChanType(h2,i);  

                t = struct('name','unusued');
                switch chan_type_numeric(i)
                    case 0 %unused
                    case 1 %ADC - Waveform
                        t = ced.channel.adc(obj.h,i,obj);
                    case 2 %EventFall

                    case 3 %EventRise

                    case 4 %EventBoth

                    case 5 %Marker
                        t = ced.channel.marker(obj.h,i,obj);
                    case 6 %WaveMark

                    case 7 %RealMark

                    case 8 %TextMark
                        t = ced.channel.text_mark(obj.h,i,obj);
                end
                objs{i} = t;
                chan_name{i} = t.name;
            end

            %Filtering to used only channels
            %---------------------------------------------
            chan_id = (1:n_chans_max)';
            mask = chan_type_numeric ~= 0;
            chan_name = chan_name(mask);
            chan_type_numeric = chan_type_numeric(mask);
            chan_id = chan_id(mask);
            chan_type = obj.TYPE_NAME_MAP(chan_type_numeric)';
            objs = objs(mask);
            obj.t = table(chan_name,chan_type,chan_id);
            obj.chan_type_numeric = chan_type_numeric;
            obj.chan_names = chan_name;

            %Filtering out specicic channel types into properties
            %--------------------------------------------
            temp = objs(chan_type_numeric == 1);
            obj.waveforms = [temp{:}];

            temp = objs(chan_type_numeric == 5);
            obj.markers = [temp{:}];

            temp = objs(chan_type_numeric == 8);
            obj.text_markers = [temp{:}];


        end
    end
end