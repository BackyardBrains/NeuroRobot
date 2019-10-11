function [ax, bx, cx, dx, connectomex, this_error] = brainGen(intended_activity, nneurons)

nsteps = size(intended_activity, 1);
b_range = 0.1 : 0.02 : 0.25;
weight_range = 0 : 2 : 20;
probability_range_1 = 0.1 : 0.2 : 1;
probability_range_2 = 0.1 : 0.2 : 1;

% Search parameter space
nsearches = length(b_range) * length(weight_range) * length(probability_range_1) * length(probability_range_2);
nsearch = 0;
min_error = Inf;
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
                brain_vector = zeros(nneurons + 4, nneurons);
                brain_vector(1,:) = a;
                brain_vector(2,:) = b;
                brain_vector(3,:) = c;
                brain_vector(4,:) = d;
                for nneuron = 1:nneurons
                    brain_vector(4+nneuron,:) = connectome(nneuron,:);
                end
                
                % Simulate brain
                this_error = brainSim2(brain_vector);

                % If correlation is highest ever save parameters
                if this_error < min_error
                    min_error = this_error;
                    disp(horzcat('Lowest error so far: ', num2str(min_error)))

                    % Save parameters
                    ax = a;
                    bx = b;
                    cx = c;
                    dx = d;
                    connectomex = connectome;

                end
                
                disp(horzcat('nsearch = ', num2str(nsearch), ' of ', num2str(nsearches), ', search time = ', num2str(toc), ', error = ', num2str(this_error), ', lowest = ', num2str(num2str(min_error))))
                
            end
        end
    end
end
