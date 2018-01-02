function [ sp_label, sp_num]  = segment_superpixel( img, n_segment )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
[m, n, ~] = size(img);
ImgVecR = reshape( img(:,:,1)', m*n, 1);
ImgVecG = reshape( img(:,:,2)', m*n, 1);
ImgVecB = reshape( img(:,:,3)', m*n, 1);
ImgProp = [m, n, n_segment, 20, m*n];
[ raw_label, ~, ~, ~, sp_num ] = SLIC(ImgVecR,ImgVecG,ImgVecB,ImgProp);
sp_label = reshape(raw_label,n,m);
sp_label = sp_label' + 1;
sp_num = sp_num;
end