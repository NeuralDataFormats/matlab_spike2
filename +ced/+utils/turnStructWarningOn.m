function state = turnStructWarningOn()
%
%   state = ced.utils.turnStructWarningOn
%   
%   ced.utils.restoreWarningState(state);

state = warning;
warning('off','MATLAB:structOnObject');

end