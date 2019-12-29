

%% HEADER
exercise.exercise_id = 'SCS372SHA774';
exercise.lesson_id = 1;
exercise.blair_code = 'Introduction';

%% LEARNING AIMS
% Science and engineering practises
exercise.practises(1).str = 'basics';
exercise.practises(2).str = 'start your neurorobot and app';
exercise.practises(3).str = 'connect to your neurorobot (wifi)';
exercise.practises(4).str = 'add neurons';
exercise.practises(5).str = 'connect sensory input';
exercise.practises(6).str = 'transmit motor output';

% Disciplinary core ideas
exercise.coreideas(1).str = 'neurons';
exercise.coreideas(2).str = 'synapses';
exercise.coreideas(3).str = 'directed flow of signals in the brain';
exercise.coreideas(4).str = 'braitenberg vehicle';
exercise.coreideas(5).str = 'vision';
exercise.coreideas(6).str = 'distance sensor';
exercise.coreideas(7).str = 'motors'; % cool hardware pics?

% 
exercise.crosscuttingconcepts(1).str = 'patterns';
exercise.crosscuttingconcepts(1).str = 'causation';
exercise.crosscuttingconcepts(1).str = 'scale';
exercise.crosscuttingconcepts(1).str = 'systems';
exercise.crosscuttingconcepts(1).str = 'energy';
exercise.crosscuttingconcepts(1).str = 'structure & function';
exercise.crosscuttingconcepts(1).str = 'stability & change';

exercise.text(1).str = 'Design a brain...';
exercise.text(2).str = '   1. ... with one neuron that responds to seeing the color red...';
exercise.text(3).str = '   2. ... by moving the robot forward.';
exercise.text(4).str = '   3. ... has a second neuron that is activated by the distance sensor...';
exercise.text(5).str = '   4. ... and makes the robot move backward.';
exercise.text(6).str = '   5. ... that spins around if it sees green.';
exercise.text(7).str = '   6. ... that follows red objects.';

save('Newbie.mat', 'exercise')