

x = ntuples/4;

mov_in = data1(1:x);
mov_in = mov_in/max(mov_in);

mov_out = sum(abs(data2(1:x,:)), 2);
mov_out = mov_out/max(mov_out);

figure(4)
clf
plot(mov_in)
hold on
plot(mov_out)
legend('mov in', 'mov out')
