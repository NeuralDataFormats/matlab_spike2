function s = getCEDMarkerStruct(n)
%
%   s = ced.utils.getCEDMarkerStruct
%
%***********
%   The format here may be critical. This comes from:
%       struct(CEDMarker)
%
%I've hardcoded to avoid the struct warning silencing

c = num2cell(repmat(int64(0),n,1));

s = struct('m_Time',c,'m_Code1',uint8(0),'m_Code2',uint8(0),...
    'm_Code3',uint8(0),'m_Code4',uint8(0));

end