
    
Ne = 800; % N excitatory neurons                 
Ni = 200; % N inhibitory neurons

re = rand(Ne,1);
ri = rand(Ni,1);

a = [0.02 * ones(Ne,1); 0.02 + 0.08 * ri];
b = [0.2 * ones(Ne,1); 0.25-0.05*ri];
c = [-65 + 15 * re.^2; -65 * ones(Ni,1)];
d = [8 - 6 * re.^2; 2 * ones(Ni,1)];

connectome = [0.5*rand(Ne+Ni,Ne), -rand(Ne+Ni,Ni)];
connectomex = reshape(S(randperm(numel(connectome))),size(connectome));

v=-65*ones(Ne+Ni,1);    
u=b.*v;                 
firings=[];             

for t=1:1000            
  I=[5*randn(Ne,1);2*randn(Ni,1)]; 
  fired=find(v>=30);    
  firings=[firings; t+0*fired,fired];
  v(fired)=c(fired);
  u(fired)=u(fired)+d(fired);
  I=I+sum(connectome(:,fired),2);
  v=v+0.5*(0.04*v.^2+5*v+140-u+I); 
  v=v+0.5*(0.04*v.^2+5*v+140-u+I); 
  u=u+a.*(b.*v-u);                 
end

%%
figure(1)
clf
set(gcf, 'color', 'w', 'position', [200 200 900 500])
plot(firings(:,1),firings(:,2),'.');
xlabel('Time (ms)')
ylabel('Neuron')
title('Spiking Network Activity')

%%
export_fig(1, 'fig1', '-r150', '-jpg', '-nocrop')

