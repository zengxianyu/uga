function sal = propagate1(W,pre,spnum, beta)
W = (W-min(W(:)))/(max(W(:))-min(W(:)));
dd = sum(W);
D = sparse(1:spnum,1:spnum,dd);
L = D - 0.99*W;
sal = (L+beta*eye(spnum,spnum))^-1 * pre;
sal = (sal-min(sal))/(max(sal)-min(sal));