
    
nE= 160; % N excitatory neurons                 
nI= 40; % N inhibitory neurons

re = rand(nE,1);
ri = rand(nI,1);

a = [0.02 * ones(nE,1); 0.02 + 0.08 * ri];
b = [0.17 * ones(nE,1); 0.17-0.05*ri];
c = [-65 + 15 * re.^2; -65 * ones(nI,1)];
d = [8 - 6 * re.^2; 2 * ones(nI,1)];

connectome = [0.5*rand(nE+nI,nE), -rand(nE+nI,nI)]*3;

% x = randperm(numel(connectome));
% x(1:length(x)*0.5) = [];
% connectome(x) = 0;
% connectome = connectome/2;
% connectomex = reshape(connectome(randperm(numel(connectome))),size(connectome));

v=-65*ones(nE+nI,1);    
u=b.*v;                 
firings=[];             

for t=1:100000            
  I=[5*randn(nE,1);2*randn(nI,1)]; 
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
set(gcf, 'color', 'w', 'position', [200 200 800 300])
plot(firings(:,1),firings(:,2),'.');
xlabel('Time (ms)')
ylabel('Neuron')
% title('nE = 800, nI = 200')

%%
% export_fig(gcf, 'fig1_800_200', '-r150', '-jpg', '-nocrop')

% %%
% figure(2);
% clf
% set(gcf, 'color', 'w', 'position', [200 200 400 300])
% imagesc(connectome, [-1 0.5])
% ylabel('Presynaptic');
% xlabel('Postsynaptic');
% title('');
% colorbar
% 
% %%
% export_fig(gcf, 'fig2_cx', '-r150', '-jpg', '-nocrop')


