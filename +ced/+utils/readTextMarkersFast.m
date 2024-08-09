function [ iRead, s ] = readTextMarkersFast( fhand, iChan, iN,  i64From, i64To, maskh )
%
%   ced.utils.readTextMarkersFast
%
%   rewrite of CEDS64ReadExtMarks

if (nargin < 4)
    iRead = -22;
    return;
end

%What is this????
Size = calllib('ceds64int', 'S64ItemSize', fhand, iChan);
Time = int64(i64From);
Count = 0;
if (Size < 0)
    iRead = -22;
    s = struct;
    return;
end

if (nargin < 5 || i64To < 0)
    i64Upto = -1;
    i64To = CEDS64MaxTime(fhand) + 1;
else
    i64Upto = i64To;
end

if (nargin < 6)
    maskcode = -1;
else
    maskcode = maskh;
end

[iOk,Rows,Cols] = CEDS64GetExtMarkInfo(fhand,iChan);
if ( (iOk < 0) || (Cols ~= 1) ), return; end

StrLen = (Rows); % calculate the length of the string
InMarker = struct(CEDMarker());
stringptr =  blanks(StrLen+8);
%s(iN,1) = CEDTextMark();               % resize in one operation

time_cell = num2cell(zeros(iN,1));

%TODO: we may want to do a growth strategy ... - yes we need to
%
%Especially if we set no max ...
s = struct('text','','time',time_cell,'code1',0,'code2',0,...
    'code3',0,'code4',0);

for n=1:iN
    if (Time >= i64To)
        break;
    end
    [iRead,s2,sText] = ...
        calllib('ceds64int', 'S64Read1TextMark', fhand, iChan, InMarker, stringptr, Time, i64Upto, maskcode);
    if (iRead > 0)
        Count = Count + 1;
        s(n).time = s2.m_Time;
        s(n).code1 = s2.m_Code1;
        s(n).code2 - s2.m_Code2;
        s(n).code3 = s2.m_Code3;
        s(n).code4 = s2.m_Code4;
        s(n).text = sText;
        %??????
        Time = s2.m_Time + 1;
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

