
fid=fopen(file_name,'r');
ChanList = SONChanList(fid);
TChannel = SONChannelInfo(fid,1);
[x_raw,h]=SONGetChannel(fid,1);
fclose(fid);
x=double(x_raw)/(2^16/10)*h.scale+h.offset;
n=length(x);
t=1e-6*(h.start+h.sampleinterval*double(0:(n-1))');  % us->s