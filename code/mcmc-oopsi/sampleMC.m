function [Xr,xr]=sampleMC(P,X,Y,funcPY,funcPXX)
%Forward-backward procedure for conditioned samples in discrete HMM.
% [Xr,xr]=sampleMC(p,X,Yr,@PY,@PXX) computes chain of states conditioned 
% on observations Yr in HMM specified by observation probabilities PY and 
% transition probabilities PXX. See help for sample spPY and spPXX for 
% definition of the functions setting HMM. X is a cell-array of length T 
% of NxM matrices specifying at each time t the N M-dimensional states in 
% discrete states-space. Yr is cell-array of T observations. Xr is the chain
% of states, xr is the chain of integer references identifying Xr in X. 
% "p" is a structure of parameters to be passed onto PY and PXX. 
% Yuriy Mishchenko 2009 Columbia Un

T  = length(Y);
N  = size(X{1},1);      %max grid size
for t=2:T N=max(N,size(X{t},1)); end 
p  = zeros(N,T);
pf = zeros(N,T);

%INITIALIZE STATES P(x_1|Y_1)=p(y_1|x_1)p(x_1)/Z
nh=size(X{1},1);
p(1:nh,1)=funcPY(P,Y{1},X{1},1).*funcPXX(P,X{1}); %P(x_1|Y_1)
p(1:nh,1)=p(1:nh,1)/sum(p(1:nh,1));               %Normalization


%FORWARD PASS - P(x_t|Y_t)
for t=2:T
  nh=size(X{t},1); 
  nhprev=size(X{t-1},1);
  x=find(isnan(p(:,t-1)));
  if(~isempty(x))
    x=x;
  end
  
  %P(x_t|Y_t)=P(y_t|x_t)*int\dx_{t-1}P(x_t|x_{t-1})P(x_{t-1}|Y_{t-1})/Z 
  % pf(1:nh,t)=funcPXX(P,X{t},X{t-1},t-1)*p(1:nhprev,t-1);
  %PRECONDITIONED on p(:,t-1) [to get rid of large constants]
  P.prc=repmat(p(1:nhprev,t-1)',[nh 1]);
  pf(1:nh,t)=sum(funcPXX(P,X{t},X{t-1},t-1),2);

  p(1:nh,t)=funcPY(P,Y{t},X{t},t).*pf(1:nh,t);
  Z=sum(p(1:nh,t));     %Normalization constant
  if(Z==0)              %check for problems in forward field
    fprintf('Error: degenerate forward field (impossible O)!\n'); 
    Xr=[]; xr=[]; return;
  end  
  p(1:nh,t)=p(1:nh,t)/Z; %normalize, P(x_t|Y_t)
end


%BACKWARD PASS
P.prc=[];
ph=cumsum(p(:,T))/sum(p(:,T)); 
i=find(rand<ph,1);      %produce s(x_T|Y_T)
Xr=cell(1,T); Xr{T}=X{T}(i,:);%sample state vector
xr=zeros(1,T); xr(T)=i;       %sample state id
for t=T-1:-1:1
  nh=size(X{t},1);
  nhnext=size(X{t+1},1);
  if(pf(xr(t+1),t+1)==0)      %check for problems in trans prob 
    fprintf('Error: degenerate backward field (impossible O)!\n'); 
    Xr=[]; xr=[]; return;
  end
  
  %s(x_t|Y_T,x_{t+1},...)=P(x_t|Y_t)*P(x_{t+1}|x_t)/P(x_{t+1}|Y_t) 
  % ph=p(1:nh,t).*funcPXX(P,Xr{t+1},X{t},t)'/pf(xr(t+1),t+1);
  %PRECONDITIONED on p(:,t) [to get rid of large constants]
  % P.prc=p(1:nh,t)'/pf(xr(t+1),t+1);
  P.prc=p(1:nh,t)';
  ph=funcPXX(P,Xr{t+1},X{t},t)';
  
  if(sum(ph)==0)              %check for problems in backward field
    fprintf('Error: degenerate backward field (impossible O)!\n'); 
    Xr=[]; xr=[]; return;
  end
  
  ph=cumsum(ph)/sum(ph);   
  i=find(rand<ph,1);          %sample s(x_t|Y_T,x_{t+1},...)  
  xr(t)=i; Xr{t}=X{t}(i,:);
end
