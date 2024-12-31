classdef file
    %
    %   Class:
    %   ced.file

    %{
        root = 'D:\Data\Mickle';
        file_name = '03192024_20single_20void_20stimulation.smrx';
        file_path = fullfile(root,file_name);
        file = ced.file(file_path);

        name = 'Demo_Jim.smrx';
        root = 'D:\Data\Mickle\sample_files';
        file = ced.file(fullfile(root,name));

        w = file.waveforms(1);
        d = w.getData();
    %}

    %{
    Signal Types Status
    ------------------------
    ADC: ced.channel.adc
    EventFall: ced.channel.event_rise_or_fall
    EventRise: ced.channel.event_rise_or_fall
    EventBoth: ced.channel.event_both
    Marker: ced.channel.marker
    WaveMark: ced.channel.wave_mark
    RealMark: 

    %}

    properties (Constant, Hidden)
        TYPE_NAME_MAP = {'ADC','EventFall','EventRise','EventBoth',...
                'Marker','WaveMark','RealMark','TextMark'};
    end

    properties
        file_name

        h

        %short string for an app, normally app name that created file
        app_id

        %ced.son.version
        version
        %NYI
        file_size
        %NYI
        file_comments
        n_ticks
        n_seconds
        start_datetime

        %This is the finest unit of time that the file supports
        %
        %Every sample or time point is some multiple of this time
        time_base

        chan_type_numeric
        chan_type_string
        chan_names

        waveforms ced.channel.adc
        markers ced.channel.marker
        event_falls
        event_rises
        event_both
        wave_markers ced.channel.wave_mark
        real_markers
        text_markers
        all_chan_objects
        
        t
    end

    methods
        function obj = file(file_path)
            %
            %   f = ced.file(file_path)

            %Load the necessary library if not yet loaded
            %-----------------------------------------------------
            if ~libisloaded('ceds64int')
                ced.utils.loadLibrary();
            end

            if isstring(file_path)
                %calls to library don't support strings, only char array
                file_path = char(file_path);
            end

            [~,obj.file_name] = fileparts(file_path);

            obj.h = ced.son.file_handle(file_path);
            obj.version = ced.son.version(obj.h);
            h2 = obj.h.h;

            obj.app_id = CEDS64AppID(h2);

            %CEDS64FileSize
            obj.file_size = CEDS64FileSize(h2);
            
            %5 comments allowed
            file_comments = cell(1,8);
            for i = 1:8
                [iOk,temp] = CEDS64FileComment(h2,i);
                %TODO: Check iOk
                file_comments{i} = temp;
            end
            mask = cellfun('isempty',file_comments);
            obj.file_comments = file_comments(~mask);
            
            obj.n_ticks = CEDS64MaxTime(h2);

            %Format is:
            %hundreths, s, min, h, day, month, year
            [~,t] = CEDS64TimeDate(h2);
            if all(t == 0)
                obj.start_datetime = NaT;
            else
                t(1) = t(1)/10; %converting to ms
                t = t(end:-1:1); %reverse for input into datetime
                t = num2cell(t);
                obj.start_datetime = datetime(t{:});
            end
            obj.time_base = CEDS64TimeBase(h2);

            obj.n_seconds = obj.n_ticks*obj.time_base;

            n_chans_max = CEDS64MaxChan(h2);
            chan_type_numeric = zeros(n_chans_max,1);

            objs = cell(n_chans_max,1);
            chan_name = cell(n_chans_max,1);

            %   Note, not all channels are actually used. It appears from
            %   the documentation that the "generic" loading approach
            %   is to iterate through all (i.e., can't skip to specific
            %   channels that are in use)
            for i = 1:n_chans_max
                chan_type_numeric(i) = CEDS64ChanType(h2,i);  

                t = struct('name','unusued');
                switch chan_type_numeric(i)
                    case 0 %unused
                    case 1 %ADC - Waveform
                        t = ced.channel.adc(obj.h,i,obj);
                    case 2 %EventFall
                        is_rise = false;
                        t = ced.channel.event_rise_or_fall(obj.h,i,obj,is_rise);
                    case 3 %EventRise
                        is_rise = true;
                        t = ced.channel.event_rise_or_fall(obj.h,i,obj,is_rise);
                    case 4 %EventBoth
                        t = ced.channel.event_both(obj.h,i,obj);
                    case 5 %Marker
                        t = ced.channel.marker(obj.h,i,obj);
                    case 6 %WaveMark
                        t = ced.channel.wave_mark(obj.h,i,obj);
                    case 7 %RealMark
                        t = ced.channel.real_mark(obj.h,i,obj);
                    case 8 %TextMark
                        t = ced.channel.text_mark(obj.h,i,obj);
                    otherwise
                        error('Unexpected channel type: %d',chan_type_numeric(i))
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
            obj.chan_type_string = chan_type;

            %Filtering out specicic channel types into properties
            %--------------------------------------------
            temp = objs(chan_type_numeric == 1);
            obj.waveforms = [temp{:}];

            temp = objs(chan_type_numeric == 2);
            obj.event_falls = [temp{:}];

            temp = objs(chan_type_numeric == 3);
            obj.event_rises = [temp{:}];

            temp = objs(chan_type_numeric == 4);
            obj.event_both = [temp{:}];

            temp = objs(chan_type_numeric == 5);
            obj.markers = [temp{:}];

            temp = objs(chan_type_numeric == 6);
            obj.wave_markers = [temp{:}];

            temp = objs(chan_type_numeric == 7);
            obj.real_markers = [temp{:}];

            temp = objs(chan_type_numeric == 8);
            obj.text_markers = [temp{:}];

            obj.all_chan_objects = objs(chan_type_numeric ~= 0);
        end
    end
end