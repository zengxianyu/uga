function sal = superpixel_saliency(Wc,seed,sp_obj, sp_pos, lambda1, lambda2,alpha,sp_num)
    const = 0.1;
    Wc = (Wc-min(Wc(:)))/(max(Wc(:))-min(Wc(:)));
    %% margin boundary
    W = zeros(sp_num+length(seed), sp_num+length(seed));
    W(1:sp_num, 1:sp_num) = Wc;
    for i = 1:length(seed)
        W(sp_num+i,seed(i)) = 1;
        W(seed(i),sp_num+i) = 1;
    end
    sp_num = sp_num + length(seed);
    sp_pos = [sp_pos; sp_pos(seed)];
    sp_obj = [sp_obj; sp_obj(seed)];
    
    %% replicator dynamics
    D12 = diag((sum(W,2)).^-0.5);
    S = D12*W*D12;
    dummy = mean(S,2);
    S = bsxfun(@minus,S,alpha*dummy);
    S = S - diag(diag(S));
    
%     sp_pos = [sp_pos, 1-sp_pos];
    pc = 0.5*ones(sp_num,2);
    pcnew = pc;
    for i=1:30
        % Eqn.8, 9
        payoff = S*pc+[lambda1*sp_pos+lambda2*sp_obj, ...
            lambda1*(1-sp_pos)+lambda2*(1-sp_obj)];
        dummy = sum(pc.*payoff,2);
        pcnew(:,1) = ( (payoff(:,1)+const)./(dummy+const) ) .* pc(:,1);
        pcnew(:,2) = ( (payoff(:,2)+const)./(dummy+const) ) .* pc(:,2);
        pc = pcnew;
    end
    sal = pc(1:sp_num-length(seed),1);
end