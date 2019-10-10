function [ax, bx, cx, dx, connectomex, max_corr] = brainGen(intended_activity, nneurons)

% Get duration
nsteps = size(intended_activity, 1);

% Define parameter space
b_range = 0.1 : 0.02 : 0.25;
weight_range = 0 : 1 : 20;
probability_range_1 = 0.1 : 0.1 : 1;
probability_range_2 = 0.1 : 0.1 : 1;

% Search parameter space (brute force)
nsearches = length(b_range) * length(weight_range) * length(probability_range_1) * length(probability_range_2);
nsearch = 0;
max_corr = 0;
for iib = b_range
    for iiw = weight_range
        for iip = probability_range_1
            for iip2 = probability_range_2
        
                tic
                nsearch = nsearch + 1;

                % Create brain
                a = zeros(nneurons, 1);
                b = zeros(nneurons, 1);
                c = zeros(nneurons, 1);
                d = zeros(nneurons, 1);
                connectome = zeros(nneurons, nneurons);

                for nneuron = 1:nneurons
                    a(nneuron, 1) = 0.02;
                    b(nneuron, 1) = iib;
                    c(nneuron, 1) = -65;
                    d(nneuron, 1) = 2;
                    if rand < iip
                        for nneuron2 = 1:nneurons
                            if rand < iip
                                connectome(nneuron, nneuron2) = iiw;
                            end
                        end
                    end
                    if rand < iip2
                        for nneuron2 = 1:nneurons
                            if rand < iip2
                                connectome(nneuron, nneuron2) = -iiw;
                            end
                        end
                    end                
                end

                % Convert brain parameters to single vector
                x = zeros(nneurons + 4, nneurons);
                x(1,:) = a;
                x(2,:) = b;
                x(3,:) = c;
                x(4,:) = d;
                for nneuron = 1:nneurons
                    x(4+nneuron,:) = connectome(nneuron,:);
                end
                
                % Simulate brain
                r = brainSim2(x);
                r = 1/r;

%                 % Correlate with intended network activity
%                 mean_activity = mean(spike_log);
%                 mean_activity = mean_activity - min(mean_activity);
%                 mean_activity = mean_activity / max(mean_activity);
% %                 r = corr(mean_activity', intended_activity);
%                 r = 1 / sum(abs(mean_activity' - intended_activity));


                % If correlation is highest ever save parameters
                if r > max_corr
                    max_corr = r;
                    disp(num2str(r))

                    % Save parameters
                    ax = a;
                    bx = b;
                    cx = c;
                    dx = d;
                    connectomex = connectome;

                end
                
                disp(horzcat('nsearch = ', num2str(nsearch), ' of ', num2str(nsearches), ', search time = ', num2str(toc)))
                
            end
        end
    end
end
