function [ iRead, s ] = readTextMarkersFast(fhand, iChan, n_max, s1, s2, n_init, growth_rate)
%
%   ced.utils.readTextMarkersFast
%
%   rewrite of CEDS64ReadExtMarks

if growth_rate <= 1
    error('Invalid growth rate, needs to be >1')
end

%What is this????
Size = calllib('ceds64int', 'S64ItemSize', fhand, iChan);
Time = int64(s1);
Count = 0;
if (Size < 0)
    iRead = -22;
    s = struct;
    return;
end

if (nargin < 5 || s2 < 0)
    i64Upto = -1;
    s2 = CEDS64MaxTime(fhand) + 1;
else
    i64Upto = s2;
end

[iOk,Rows,Cols] = CEDS64GetExtMarkInfo(fhand,iChan);
if ( (iOk < 0) || (Cols ~= 1) ), return; end

StrLen = (Rows); % calculate the length of the string
%InMarker = struct(CEDMarker());

InMarker = struct('m_Time',int64(0),'m_Code1',uint8(0),'m_Code2',uint8(0),'m_Code3',uint8(0),'m_Code4',uint8(0));

stringptr =  blanks(StrLen+8);
%s(iN,1) = CEDTextMark();               % resize in one operation

s = h__getStruct(n_init);

maskcode = -1;
for n=1:n_max
    if (Time >= s2)
        break;
    end
    if n > length(s)
        n_total = ceil(growth_rate*length(s));
        n_add = n_total - length(s);
        s = [s; h__getStruct(n_add)]; %#ok<AGROW>
    end
    [iRead,s3,sText] = ...
        calllib('ceds64int', 'S64Read1TextMark', fhand, iChan, InMarker, stringptr, Time, i64Upto, maskcode);
    if (iRead > 0)
        Count = Count + 1;
        s(n).time = s3.m_Time;
        s(n).code1 = s3.m_Code1;
        s(n).code2 - s3.m_Code2;
        s(n).code3 = s3.m_Code3;
        s(n).code4 = s3.m_Code4;
        s(n).text = sText;
        %??????
        Time = s3.m_Time + 1;
    else
        break;
    end
end

if Count > 0
    s(Count+1:end) = [];
else
    s = [];
end
    
iRead = Count;
end

function s = h__getStruct(n)
time_cell = num2cell(zeros(n,1));

%TODO: we may want to do a growth strategy ... - yes we need to
%
%Especially if we set no max ...
s = struct('text','','time',time_cell,'code1',0,'code2',0,...
    'code3',0,'code4',0);

end
