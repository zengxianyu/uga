function [ edges ] = make_graph( sp_label, bd)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
sp_num = max(sp_label(:))+1;
Adj = zeros(sp_num,sp_num);
[m,n] = size(sp_label);
for i = 1:m-1
    for j = 1:n-1
        if(sp_label(i,j)~=sp_label(i,j+1))
            Adj(sp_label(i,j),sp_label(i,j+1)) = 1;
            Adj(sp_label(i,j+1),sp_label(i,j)) = 1;
        end
        if(sp_label(i,j)~=sp_label(i+1,j))
            Adj(sp_label(i,j),sp_label(i+1,j)) = 1;
            Adj(sp_label(i+1,j),sp_label(i,j)) = 1;
        end
        if(sp_label(i,j)~=sp_label(i+1,j+1))
            Adj(sp_label(i,j),sp_label(i+1,j+1)) = 1;
            Adj(sp_label(i+1,j+1),sp_label(i,j)) = 1;
        end
        if(sp_label(i+1,j)~=sp_label(i,j+1))
            Adj(sp_label(i+1,j),sp_label(i,j+1)) = 1;
            Adj(sp_label(i,j+1),sp_label(i+1,j)) = 1;
        end
    end
end  
%connect boundary nodes
for i=1:length(bd)
    for j=i+1:length(bd)
        Adj(bd(i),bd(j))=1;
        Adj(bd(j),bd(i))=1;
    end
end
edges=[];
for i=1:sp_num
    indext=[];
    ind=find(Adj(i,:)==1);
    for j=1:length(ind)
        indj=find(Adj(ind(j),:)==1);
        indext=[indext,indj];
    end
    indext=[indext,ind];
    indext=indext((indext>i));
    indext=unique(indext);
    if(~isempty(indext))
        ed=ones(length(indext),2);
        ed(:,2)=i*ed(:,2);
        ed(:,1)=indext;
        edges=[edges;ed];
    end
end

end

