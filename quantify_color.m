function [ Q ] = quantify_color( img_lab )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
Lab_bins = [8, 8, 8];
L = img_lab(:,1);
a = img_lab(:,2);
b = img_lab(:,3);
ll = min(floor(L/(1/Lab_bins(1))) + 1, Lab_bins(1));
aa = min(floor((a)/(1/Lab_bins(2))) + 1, Lab_bins(2));
bb = min(floor((b)/(1/Lab_bins(3))) + 1, Lab_bins(3));
Q = (ll-1) * Lab_bins(2) * Lab_bins(3) + ...
    (aa-1) * Lab_bins(3) + ...
    bb + 1;

end

