% Copyright: (C) 2012-2016 POETICON++, European Commission FP7 project ICT-288382
% CopyPolicy: Released under the terms of the GNU GPL v2.0.
% Copyright: (C) 2015 VisLab, Institute for Systems and Robotics,
%                Instituto Superior Técnico, Universidade de Lisboa, Lisbon, Portugal
% Author: Pedro Vicente, Atabak Dehban, Afonso Gonçalves, João Abrantes, Giovanni Saponaro
% CopyPolicy: Released under the terms of the GNU GPL v2.0


function [score] = pcaTrain2N3C
%%
%PCA - Rede bayesiana com 5 nos
%faz o pca com os valores continuos
data = load('../Data+combinator/affData_03_23_16.txt'); 
train_rows=size(data,1); % 100% of the data
training_data=data(1:train_rows,:);

%test_data=load('testData.txt');

featuresT = training_data(:,1:5);
featuresO = training_data(:,6:10);
[latentT,pcT]=pca(featuresT);
[latentO,pcO]=pca(featuresO);
% %explained variance
% cumsum(latent)/sum(latent) % 2 pc explain everything
% plot(1:length(latent),cumsum(latent)/sum(latent)*100,'.-b');
% xlim([1 length(latent)]);
% ylabel('Variance Explained (%)');
% xlabel('Number of components');

components = 3;
values = [3,3,3]; %discretize in how many values?
SCORE = featuresT*pinv(pcT(:,1:components)');
SCORE2 = featuresO*pinv(pcO(:,1:components)');


%compute bin ranges to discretize
ranges = getRanges([values values],[SCORE(:,1:components) SCORE2(:,1:components)]);

% % original_cpd_size = 3^12*4*5;
% % cpd_size = 4*5;
% % for c = 1:components
% %     cpd_size = cpd_size*values(c);
% % end

% fprintf('Com esta structure a cpd agora tem %d elementos.\n',cpd_size);
% fprintf('Reducao de %.3f por cento.\n',(cpd_size-original_cpd_size)/original_cpd_size*100);

%%
%build network
% Nodes indexes:
comp1   =  1; %tool
comp2   =  2; %tool
comp3   =  3; %obj
comp4   =  4; %obj
comp5   =  5;
comp6   =  6;
action  =  7;%3;
effectX =  8;%4;
effectY =  9;%5;
% Number of nodes:
nnodes  =   9;%5
% Number of states per node:
nstates = [values values 2 5 5];

% Adjacency matrix ( G(parent, [sons])=1 ), defines structure of BN:
dag = zeros(nnodes, nnodes);
dag(comp1,   [effectX effectY]) = 1;
dag(comp2,   [effectX effectY]) = 1;
dag(comp3,   [effectX effectY]) = 1;
dag(comp4,   [effectX effectY]) = 1;
dag(comp5,   [effectX effectY]) = 1;
dag(comp6,   [effectX effectY]) = 1;
dag(action,  [effectX effectY]) = 1;

names=  {'Component1', 'Component2', 'Component3','Component4','Component5','Component6', 'Action','EffectX', 'EffectY'};
BN = dgmCreate(dag, mkRndTabularCpds(dag, nstates(1:nnodes)),...
    'nodeNames', names,'infEngine', 'varelim');
% drawNetwork('-adjMatrix', BN.G);
%%
%train data
% data = load('Data_af.txt');

%discretize train_data
featuresT=training_data(:,1:5);
featuresO=training_data(:,6:10);
score=[ featuresT*pinv(pcT(:,1:components)') featuresO*pinv(pcO(:,1:components)')];
score = discretize(score,ranges);
effects = training_data(:,12:end);
% values2 = [5 5];
%ranges2 = getRanges(values2,effects);
ranges2 = cell(2,1);
ranges2{1,1} = [-.05 -0.02 0.02 0.05 1];
ranges2{2,1} = [-.05 -0.02 0.02 0.05 1];
% ranges2{1,1} = [.05 0.02 -0.02 -0.05 -1];
% ranges2{2,1} = [.05 0.02 -0.02 -0.05 -1];

effects = discretize(effects, ranges2);
training_data_9nodes = [score training_data(:,11) effects];
BN = dgmTrainFullyObs(BN, training_data_9nodes);
save('../Networks+listener/pca_2n_3C.mat','BN','ranges','pcT','pcO','components');
%%
%test data
%discretize features
% features=test_data(:,1:12);
% 
% score=features*pinv(pc(:,1:components)');
% score = discretize(score,ranges);
% 
% test_data=[score test_data(:,13:end)];

% Descomentar o score a ser utilizado.
%%
% % %Gambling Score
% prior_nodes=1:3;
% score=0;
% random = 0;
% for r = 1:size(test_data,1)
%     prior_values=test_data(r,1:3);
%     tex=test_data(r,4);
%     tey=test_data(r,5);
%     posterior=[4];
%     clamped = sparsevec(prior_nodes, prior_values, BN.nnodes);
%     prob = dgmInferQuery(BN, posterior, 'clamped', clamped,'doSlice', false);
%     [~,i]=max(prob.T);
%     if (sum(prob.T)~=0)
%         if (i==tex)
%             score=score+4;
%         else
%             score=score-1;
%         end
%     else
%         random = random+1;
%     end 
%     posterior=[5];
%     clamped = sparsevec(prior_nodes, prior_values, BN.nnodes);
%     prob = dgmInferQuery(BN, posterior, 'clamped', clamped,'doSlice', false);
%     [~,i]=max(prob.T);
%     if (sum(prob.T)~=0)
%         if (i==tey)
%             score=score+4;
%         else
%             score=score-1;
%         end
%     else
%         random = random+1;
%     end
% end
% fprintf('Escolhi aleatoriamente %.2f percent vezes!\n',100*random/((size(test_data,1)*2)));
% % fprintf('Score obtained:%.2f/%d\n',score,size(test_data,1)*4*2);
% % fprintf('%.3f per cent\n',score/(size(test_data,1)*4*2)*100);
% score=score/(size(test_data,1)*4*2)*100;
%%
% %ACCURACY
% prior_nodes=1:3;
% score=0;
% random = 0;
% for r = 1:size(test_data,1)
%     prior_values=test_data(r,1:3);
%     tex=test_data(r,4);
%     tey=test_data(r,5);
%     posterior=[4];
%     clamped = sparsevec(prior_nodes, prior_values, BN.nnodes);
%     prob = dgmInferQuery(BN, posterior, 'clamped', clamped,'doSlice', false);
%     [~,i]=max(prob.T);
%     if (sum(prob.T)~=0)
%         if (i==tex)
%             score=score+1;
%         end
%     else
%         score=score+1/5.;
%         random = random+1;
%     end 
%     posterior=[5];
%     clamped = sparsevec(prior_nodes, prior_values, BN.nnodes);
%     prob = dgmInferQuery(BN, posterior, 'clamped', clamped,'doSlice', false);
%     [~,i]=max(prob.T);
%     if (sum(prob.T)~=0)
%         if (i==tey)
%             score=score+1;
%         end
%     else
%         score=score+1/5.;
%         random = random+1;
%     end 
% end
% fprintf('Escolhi aleatoriamente %.2f percent vezes!\n',100*random/((size(test_data,1)*2)));
% % fprintf('Score obtained:%.2f/%d\n',score,size(test_data,1)*4*2);
% % fprintf('%.3f per cent\n',score/(size(test_data,1)*4*2)*100);
% score=score/(size(test_data,1)*2)*100;
%%
%DISTANCE
% prior_nodes=1:3;
% score=0;
% random = 0;
% for r = 1:size(test_data,1)
%     prior_values=test_data(r,1:3);
%     tex=test_data(r,4);
%     tey=test_data(r,5);
%     posterior=[4];
%     clamped = sparsevec(prior_nodes, prior_values, BN.nnodes);
%     prob = dgmInferQuery(BN, posterior, 'clamped', clamped,'doSlice', false);
%     [~,i]=max(prob.T);
%     if (sum(prob.T)~=0)
%         score=score+abs(i-tex);
%     else
%         score = score + 1.6;
%         random=random + 1;
%     end
%     posterior=[5];
%     clamped = sparsevec(prior_nodes, prior_values, BN.nnodes);
%     prob = dgmInferQuery(BN, posterior, 'clamped', clamped,'doSlice', false);
%     [~,i]=max(prob.T);
%     if (sum(prob.T)~=0)
%         score=score+abs(i-tey);
%     else
%         score = score + 1.6;
%         random=random + 1;
%     end
% end
% fprintf('Escolhi aleatoriamente %.2f percent vezes!\n',100*random/((size(test_data,1)*2)));
% % fprintf('Score obtained:%.2f/%d\n',score,size(test_data,1)*4*2);
% % fprintf('%.3f per cent\n',score/(size(test_data,1)*4*2)*100);
% score=score/(size(test_data,1)*2*4)*100;
