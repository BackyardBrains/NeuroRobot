
% This script creates a continuous reinforcement learning agent for SpikerBots

nstate_dims = 500;
nactions = 10;

% define a useful state space for SpikerBot navigating the livingroom
obsInfo = rlNumericSpec([nstate_dims 1]);
actInfo = rlFiniteSetSpec(1:nactions);

net = [featureInputLayer(nstate_dims,'Normalization','none','Name','myobs') 
       fullyConnectedLayer(nactions,'Name','value')];

critic = rlQValueRepresentation(net,obsInfo,actInfo,'Observation',{'myobs'});

% % observation path layers
% obsPath = [featureInputLayer(nstate_dims, 'Normalization','none','Name','myobs') 
%     fullyConnectedLayer(1,'Name','obsout')];
% 
% % action path layers
% actPath = [featureInputLayer(nactions, 'Normalization','none','Name','myact') 
%     fullyConnectedLayer(1,'Name','actout')];
% 
% % common path to output layers
% comPath = [additionLayer(2,'Name', 'add')  fullyConnectedLayer(1, 'Name', 'output')];
% 
% % add layers to network object
% net = addLayers(layerGraph(obsPath),actPath); 
% net = addLayers(net,comPath);
% 
% % connect layers
% net = connectLayers(net,'obsout','add/in1');
% net = connectLayers(net,'actout','add/in2');

% plot network
% plot(net)

% critic = rlQValueRepresentation(net,obsInfo,actInfo, 'Observation',{'myobs'},'Action',{'myact'});

% opt = rlQAgentOptions;
opt = rlDQNAgentOptions;
% agent = rlQAgent(critic,opt);
agent = rlDQNAgent(critic, opt);

