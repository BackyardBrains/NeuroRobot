function [brain_vector, fval, exitFlag] = generate_brain(approach)


get_nneurons


%% Starting point in brain space
start_brain = zeros(nneurons + 4, nneurons);
start_brain(1,:) = repmat(0.02, [nneurons, 1]);
start_brain(2,:) = repmat(0.1, [nneurons, 1]);
start_brain(3,:) = repmat(-65, [nneurons, 1]);
start_brain(4,:) = repmat(2, [nneurons, 1]);
start_brain_vector = reshape(start_brain, [(nneurons + 4) * nneurons, 1]);


%% Bounds
lb = zeros(nneurons + 4, nneurons);
lb(1,:) = 0;
lb(2,:) = 0;
lb(3,:) = -90;
lb(4,:) = 0;
lb(5:nneurons+4,:) = -30;
lb_vector = reshape(lb, [(nneurons + 4) * nneurons, 1]);

ub = zeros(nneurons + 4, nneurons);
ub(1,:) = 0.15;
ub(2,:) = 0.4;
ub(3,:) = -30;
ub(4,:) = 10;
ub(5:nneurons+4,:) = 30;
ub_vector = reshape(ub, [(nneurons + 4) * nneurons, 1]);


%% Search brain space
if strcmp(approach, 'fmincon')
    disp(approach)
    options = optimoptions('fmincon','Display','iter');
    [brain_vector,fval,exitFlag] = fmincon(@brainSim2, start_brain, [], [], [], [], lb_vector, ub_vector, [], options);
    
elseif strcmp(approach, 'patternsearch')
    disp(approach)
    options = optimoptions('patternsearch','Display','iter');
    [brain_vector,fval,exitFlag] = patternsearch(@brainSim2, start_brain, [], [], [], [], lb_vector, ub_vector, [], options);  
    
elseif strcmp(approach, 'particleswarm')
    disp(approach)
    options = optimoptions('particleswarm', 'Display', 'iter','SwarmSize', 200, 'InitialSwarmMatrix', start_brain_vector','HybridFcn',@fmincon);
    nvars = length(start_brain_vector);
    [brain_vector,fval,exitFlag] = particleswarm(@brainSim2,nvars,lb_vector,ub_vector,options); 
    
elseif strcmp(approach, 'ga')
    disp(approach)
    options = optimoptions('ga','Display','iter','PlotFcn',@gabestf, 'InitialPopulationMatrix', start_brain_vector);
    nvars = length(start_brain_vector);
    [brain_vector,fval,exitFlag] = ga(@brainSim2, nvars, start_brain, [], [], [], [], lb_vector, ub_vector, [], options);   
    
else
    disp('Unknown approach')
end


