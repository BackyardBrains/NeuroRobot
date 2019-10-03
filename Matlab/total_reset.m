
% Clear command window:
clc;
% Close figures:
try
  close('all', 'hidden');
catch  % do nothing
end
% Closing figures might fail if the CloseRequestFcn of a figure
% blocks the execution. Fallback:
AllFig = allchild(0);
if ~isempty(AllFig)
   set(AllFig, 'CloseRequestFcn', '', 'DeleteFcn', '');
   delete(AllFig);
end
% Clear loaded functions:
% (I avoid "clear all" here for educational reasons)
clear('functions');
clear('classes');
clear('java');
clear('global');
% clear('import');  % Not from inside a function!
clear('variables');
% Stop and delete timers:
AllTimer = timerfindall;
if ~isempty(AllTimer)  % EDITED: added check
   stop(AllTimer);
   delete(AllTimer);
end
% Unlock M-files:
LoadedM = inmem;
for iLoadedM = 1:length(LoadedM)
   % EDITED: Use STRTOK to consider OO methods:
   aLoadedM = strtok(LoadedM{iLoadedM}, '.'); 
   if ~strcmp(aLoadedM, 'opaque')
   munlock(aLoadedM);
   clear(aLoadedM);
   end
end   
% Close open files:
fclose('all');
% Reset the warning status   EDITED:
warning('on', 'all');
lasterror('reset');
lastwarn('');
% Remove <Default>Properties from root:
prop = get(0, 'default');
propname = fieldnames(prop);
for iprop = 1:length(propname)
   set(0, propname{iprop}, 'remove');
end
% EDITED: Change to 1st user path to find "startup.m":
cd(strtok(userpath, pathsep));
% Restore original <Default>Properties of root,
% load default PATH, run STARTUP.m:
matlabrc;
% EDITED: No PACK even in scripts

cd 'C:\Users\Christopher Harris\NeuroRobot\Matlab'

neurorobot