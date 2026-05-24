file_root = 'E:\repos\data\spike2_example_files\files';

fp = fullfile(file_root,'demo1.smr');

f = ced.file(fp);

w = f.waveforms;

d = w.getData('return_format','double');

clf
hold on
for i = 1:length(d)
    plot(d(i).time,d(i).data)
end
hold off