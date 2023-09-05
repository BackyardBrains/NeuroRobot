function timeout(fExpr, fTimeout)
% TIMEOUT Interrupt execution of script of function after specified period of time
%
%   fExpr - MATLAB expression, function or script to run
%   fTimeout - timeout in seconds
%
%   This function uses undocumented command window method to
%   programatically send Ctrl+C after specified period of time.
%
%   There are other ways of sending Ctrl+C programmatically, including Java
%   Robot or SIGINT on Linux, but they require changes to the script or
%   function that want to interrupt.
%
%   This submission serves as a PoC and demonstration. Adapt to your
%   specific needs if necessary.
%
%   Usage examples
%   Run the 'longComputations' script no more than 5 seconds:
%   >> timeout('longComputations',5)
%   Interrupt execution of infinite pause after 3 seconds:
%   >> timeout('pause(inf)',3)

% Set up single-shot timer to fire interrupt after specified amount of time
t = timer('TimerFcn','com.mathworks.mde.cmdwin.CmdWinMLIF.getInstance().processKeyFromC(2,67,''C'')','StartDelay',fTimeout);
start(t);
% Evaluate expression
eval(fExpr);
