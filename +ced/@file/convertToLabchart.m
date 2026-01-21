function convertToLabchart(obj)

    WRITE_SIZE = 30; %seconds

    cur_file_path = obj.file_path;

    [root,name] = fileparts(cur_file_path);
    new_file_path = fullfile(root,[name '.adidat']);

    fw = adi.createFile(new_file_path);

    %Channel info gathering
    %---------------------------------------------------------
    n_chans = length(obj.waveforms);
    chan_objects = cell(1,n_chans);
    max_times = zeros(1,n_chans);
    last_samples = zeros(1,n_chans);
    fs = zeros(1,n_chans);
    for i = 1:n_chans
        cur_waveform = obj.waveforms(i);
        %TODO: Offer remapping option
        chan_name = cur_waveform.name;
        chan_units = cur_waveform.units;
        chan_fs = cur_waveform.fs;
        chan = fw.addChannel(i,chan_name,chan_fs,chan_units);
        chan_objects{i} = chan;

        max_times(i) = cur_waveform.max_time;
        fs(i) = cur_waveform.fs;
        last_samples(i) = cur_waveform.n_ticks-1;
    end

    %For now we assume one big long record ....
    %
    %   Perhaps we could eventually support pauses as records
    fw.startRecord('trigger_time',obj.start_datetime);

    %Note, this helps me to ensure each sample is 1 for 1 with other
    %samples since we can't skip writing samples in LabChart
    %
    %Currently I pad with the first value
    all_data = cell(1,n_chans);
    for i = 1:n_chans
        s = obj.waveforms(i).getData();
        %We currently don't support pauses
        if length(s) > 1
            error('Not yet supported')
        end
        n_missing = s.first_sample_id-1;
        pad_data = s.data(1)*ones(n_missing,1);
        all_data{i} = [pad_data; s.data];
    end

    % for j = 1:n_chans
    %     starts = 1:1e5:y1.n_samples;
    %     stops = [starts(2:end)-1 y1.n_samples];
    %     for i = 1:length(starts)
    %         I1 = starts(i);
    %         I2 = stops(i);
    %         s = obj.waveforms(j).getData(...
    %             "sample_range",[I1 I2],...
    %             'time_format','none');
    %         I1s = s.first_sample_id;
    %         I2s = s.last_sample_id;
    %         if ~isequal(s.data,all_data{j}(I1s:I2s))
    %             error('mismatch: %d,%d',i,j)
    %         end
    %     end
    % end

    cur_write_time = 0;
    last_samples_written = zeros(1,n_chans);
    done = false(1,n_chans);
    write_count = 0;
    while ~all(done)
        cur_write_time = cur_write_time + WRITE_SIZE;
        write_count = write_count+1;
        fprintf('writing to: %g, %d\n',cur_write_time,write_count)
        for i = 1:n_chans
            if done(i)
                break
            end

            cur_waveform = obj.waveforms(i);
            %Adjust samples
            
            I2 = round(cur_write_time*fs(i));
            if I2 > last_samples(i)
                I2 = last_samples(i);
            end

            I1 = last_samples_written(i)+1;
            if I1 > I2
                done(i) = true;
                break
            end

            r1 = 100*I1/last_samples(i);
            r2 = 100*I2/last_samples(i);
            fprintf('%d: %d:%d %0.1f:%0.1f\n',i,I1,I2,r1,r2);

            %s = cur_waveform.getData("sample_range",[I1 I2],'time_format','none');
            %?? What do we do if not at the sample we requested?

            temp_data = all_data{i}(I1:I2);
            %TODO: Check I1 and I2 that are returned
            cur_chan = chan_objects{i};
            cur_chan.addSamples(temp_data);

            last_samples_written(i) = I2;
            if I2 == last_samples(i)
                done(i) = true;
            end
        end
    end

    fw.stopRecord();

    for i = 1:length(obj.text_markers)
        text_marker = obj.text_markers(i);
        comments = text_marker.getData();
        strings = comments.text;
        times = comments.time;
        for j = 1:length(strings)
            comment_time = times(j);
            comment_string = strings{j};
            record = -1; %-1 is current record (or last record if stopped)
            comment_channel = -1;
            fw.addComment(record,comment_time,comment_string,'channel',comment_channel);
        end
    end

    %TODO: Support other markers ...

    fw.save();
    fw.close();

end

%{
file_path = 'D:\repos\test.adidat';
      fw = adi.createFile(file_path); %fw : file_writer
    
      fs1 = 100;
      chan = 1;
      pres_chan = fw.addChannel(chan,'pressure',fs1,'cmH20');
    
      fs2 = 1000;
      chan = 2;
      emg_chan = fw.addChannel(chan,'emg',fs2,'mV');
    
      start_date_time = datenum(2023,7,19,18,0,0);
      fw.startRecord('trigger_time',start_date_time);
    
      y1 = [1:1/fs1:10 10:-1/fs1:1 1:1/fs1:10 10:-1/fs1:1];
      pres_chan.addSamples(y1);
      
      %Note record gets truncated to shortest channel
      t = (1:length(y1)*(fs2/fs1)).*1/fs2;
      y2 = sin(2*pi*1/10*t);
      emg_chan.addSamples(y2);
    
      fw.stopRecord();
	  
	  %Repeat startRecord and stopRecord if you want to add more
    
      comment_time = 2;
      comment_string = 'Best EMG signal ever!';
      record = -1; %-1 is current record (or last record if stopped)
      comment_channel = 2;
      fw.addComment(record,comment_time,comment_string,'channel',comment_channel);
    
      comment_time = 9;
      comment_string = 'Best time ever';
      record = -1; %-1 is current record (or last record if stopped)
      comment_channel = -1;
      fw.addComment(record,comment_time,comment_string,'channel',comment_channel);
      fw.save();
      fw.close();
	  
	  %Or this should work
      %fw.saveAndClose();
%}