


data_nsmall = zeros(100, 2);
data_bof = zeros(100, 2);
data_nmedium = zeros(100, 2);
data_ustates = zeros(100, 2);
data_minsize = zeros(100, 2);

for ls = 1:2

    if ls == 1
        learn_speed = 1;
    else
        learn_speed = 0.1;
    end

    counter = 0;

    for ntuples = 10000:10000:1000000
    
        counter = counter + 1;

        nsmall = round((0.001 * ntuples + 1000) * learn_speed);
        bof_branching = round((0.0003 * ntuples + 200) * learn_speed);
        nmedium = round((0.005 * ntuples + 1000) * learn_speed);
        init_n_unique_states = round(0.000075 * ntuples * learn_speed) + 15;
        min_size = round(0.000075 * ntuples * learn_speed) + 15;
        
        data_nsmall(counter, ls) = nsmall;
        data_bof(counter, ls) = bof_branching;
        data_nmedium(counter, ls) = nmedium;
        data_ustates(counter, ls) = init_n_unique_states;
        data_minsize(counter, ls) = min_size;        
            
    end

end

figure(1)
clf

subplot(2,3,1)
plot(data_nsmall(:,1))
hold on
plot(data_nsmall(:,2))
legend('slow', 'fast')

subplot(2,3,2)
plot(data_bof(:,1))
hold on
plot(data_bof(:,2))
legend('slow', 'fast')

subplot(2,3,3)
plot(data_nmedium(:,1))
hold on
plot(data_nmedium(:,2))
legend('slow', 'fast')

subplot(2,3,4)
plot(data_ustates(:,1))
hold on
plot(data_ustates(:,2))
legend('slow', 'fast')

subplot(2,3,5)
plot(data_minsize(:,1))
hold on
plot(data_minsize(:,2))
legend('slow', 'fast')
