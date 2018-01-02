function [ rlbmap ] = lbmap_from_sp(sp_lbmap, sp_label)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
rlbmap = zeros(size(sp_label));
for i = 1:length(sp_lbmap)
    rlbmap(sp_label==i) = sp_lbmap(i);
end
