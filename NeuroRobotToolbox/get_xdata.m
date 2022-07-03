
xdata = nan(nstates, 3);

for nstate = 1:nstates

    this_state = states(nstate);
    
        % tv
    if this_state == 25
        xdata(nstate, :) = [1 1 1];
    elseif this_state == 26
        xdata(nstate, :) = [1 1 2];
    elseif this_state == 27
        xdata(nstate, :) = [1 1 3];
    elseif this_state == 28
        xdata(nstate, :) = [1 1 4];

    elseif this_state == 29
        xdata(nstate, :) = [2 1 1];
    elseif this_state == 30
        xdata(nstate, :) = [2 1 2];
    elseif this_state == 31
        xdata(nstate, :) = [2 1 3];
    elseif this_state == 32
        xdata(nstate, :) = [2 1 4];

    elseif this_state == 33
        xdata(nstate, :) = [3 1 1];
    elseif this_state == 34
        xdata(nstate, :) = [3 1 2];
    elseif this_state == 35
        xdata(nstate, :) = [3 1 3];
    elseif this_state == 36
        xdata(nstate, :) = [3 1 4];

    elseif this_state == 37
        xdata(nstate, :) = [4 1 1];
    elseif this_state == 38
        xdata(nstate, :) = [4 1 2];
    elseif this_state == 39
        xdata(nstate, :) = [4 1 3];
    elseif this_state == 40
        xdata(nstate, :) = [4 1 4];

    elseif this_state == 41
        xdata(nstate, :) = [5 1 1];
    elseif this_state == 42
        xdata(nstate, :) = [5 1 2];
    elseif this_state == 43
        xdata(nstate, :) = [5 1 3];
    elseif this_state == 44
        xdata(nstate, :) = [5 1 4];

        % mid
    elseif this_state == 45
        xdata(nstate, :) = [1 2 1];
    elseif this_state == 46
        xdata(nstate, :) = [1 2 2];
    elseif this_state == 47
        xdata(nstate, :) = [1 2 3];
    elseif this_state == 48
        xdata(nstate, :) = [1 2 4];

    elseif this_state == 49
        xdata(nstate, :) = [2 2 1];
    elseif this_state == 50
        xdata(nstate, :) = [2 2 2];
    elseif this_state == 51
        xdata(nstate, :) = [2 2 3];
    elseif this_state == 52
        xdata(nstate, :) = [2 2 4];

    elseif this_state == 53
        xdata(nstate, :) = [3 2 1];
    elseif this_state == 54
        xdata(nstate, :) = [3 2 2];
    elseif this_state == 55
        xdata(nstate, :) = [3 2 3];
    elseif this_state == 56
        xdata(nstate, :) = [3 2 4];

    elseif this_state == 57
        xdata(nstate, :) = [4 2 1];
    elseif this_state == 58
        xdata(nstate, :) = [4 2 2];
    elseif this_state == 59
        xdata(nstate, :) = [4 2 3];
    elseif this_state == 60
        xdata(nstate, :) = [4 2 4];

    elseif this_state == 1
        xdata(nstate, :) = [5 2 1];
    elseif this_state == 2
        xdata(nstate, :) = [5 2 2];
    elseif this_state == 3
        xdata(nstate, :) = [5 2 3];
    elseif this_state == 4
        xdata(nstate, :) = [5 2 4];

        % sofa
    elseif this_state == 5
        xdata(nstate, :) = [1 3 1];
    elseif this_state == 6
        xdata(nstate, :) = [1 3 2];
    elseif this_state == 7
        xdata(nstate, :) = [1 3 3];
    elseif this_state == 8
        xdata(nstate, :) = [1 3 4];

    elseif this_state == 9
        xdata(nstate, :) = [2 3 1];
    elseif this_state == 10
        xdata(nstate, :) = [2 3 2];
    elseif this_state == 11
        xdata(nstate, :) = [2 3 3];
    elseif this_state == 12
        xdata(nstate, :) = [2 3 4];

    elseif this_state == 13
        xdata(nstate, :) = [3 3 1];
    elseif this_state == 14
        xdata(nstate, :) = [3 3 2];
    elseif this_state == 15
        xdata(nstate, :) = [3 3 3];
    elseif this_state == 16
        xdata(nstate, :) = [3 3 4];

    elseif this_state == 17
        xdata(nstate, :) = [4 3 1];
    elseif this_state == 18
        xdata(nstate, :) = [4 3 2];
    elseif this_state == 19
        xdata(nstate, :) = [4 3 3];
    elseif this_state == 20
        xdata(nstate, :) = [4 3 4];

    elseif this_state == 21
        xdata(nstate, :) = [5 3 1];
    elseif this_state == 22
        xdata(nstate, :) = [5 3 2];
    elseif this_state == 23
        xdata(nstate, :) = [5 3 3];
    elseif this_state == 24
        xdata(nstate, :) = [5 3 4];
    end

end


