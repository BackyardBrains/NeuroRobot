
% clear classes
% m = py.importlib.import_module('ai');
% py.importlib.reload(m);

pathToAI = fileparts(which('ai2.py'))
if count(py.sys.path, pathToAI) == 0
    insert(py.sys.path, int32(0), pathToAI)
end