

nbrains = 5;

for nbrain = 1:nbrains

    create_from_algorithm

    print_brain

    disp(horzcat('genenrated and printed brain ', num2str(nbrain), ' of ', num2str(nbrains)))

end

