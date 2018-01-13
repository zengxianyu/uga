%clear;
%dataset = 'ECSSD';
function stage1_vgg(dataset)
img_root = sprintf('/home/zeng/data/datasets/saliency_Dataset/%s/images/images', dataset);
mat_root = sprintf('/home/zeng/data/datasets/saliency_Dataset/%s/gop', dataset);
mat_root2 = sprintf('/home/zeng/data/datasets/saliency_Dataset/%s/vgg', dataset);
output_root = sprintf('/home/zeng/data/datasets/saliency_Dataset/%s/Ours17vgg', dataset);
img_name_list = dir([img_root, '/*', 'jpg']);
system(sprintf('mkdir %s', output_root));
system(sprintf('rm %s/*', output_root));
theta = 10;
Ns = [100, 150, 200, 250];
parfor i_img = 1:numel(img_name_list)
    disp(i_img);
    img_name = img_name_list(i_img).name;
    img = imread([img_root, '/', img_name]);
    img_obj = load(sprintf('%s/%s_masks.mat', mat_root, img_name(1:end-4)));
    img_obj = mean(img_obj.masks, 3);
    img_feat = load(sprintf('%s/%s.mat', mat_root2, img_name(1:end-4)));
    img_feat = double(img_feat.feat);
    sal_map = 1;
    rlbmap = 1;
    [m, n, ~] = size(img);
    img_feat = imresize(img_feat, [m, n]);
    [~, ~, k] = size(img_feat);
    img_feat = reshape(img_feat, m*n, k);
    img_feat = (img_feat-min(img_feat)) ./ (max(img_feat)-min(img_feat)+eps);
    for i_ns = 1:length(Ns)
        %% superpixel segmentation
        [sp_label, sp_num] = segment_superpixel(double(img), Ns(i_ns));
        % superpixel level feature
        sp_feat = zeros(sp_num, k);
        sp_pos = zeros(sp_num, 2);
        sp_obj = zeros(sp_num, 1);
        sp_lab = zeros(sp_num, 3);
        for i = 1:sp_num
            sp_feat(i, :) = mean(img_feat(sp_label==i, :), 1);
            sp_obj(i) = mean(img_obj(sp_label==i));
            [y, x] = find(sp_label==i);
            sp_pos(i, 1) = mean(x);
            sp_pos(i, 2) = mean(y);
        end
        sp_pos = (sp_pos - min(sp_pos)) ./ (max(sp_pos) - min(sp_pos));
        sp_pos = exp(-1 * sqrt(sum((sp_pos - 0.5) .^ 2, 2)) );
        sp_pos = (sp_pos - min(sp_pos)) ./ (max(sp_pos) - min(sp_pos));
        sp_obj = (sp_obj - min(sp_obj)) / (max(sp_obj)-min(sp_obj));
        %% graph
        bst=unique(sp_label(1,:));
        bsd=unique(sp_label(end,:));
        bsr=unique(sp_label(:,1));
        bsl=unique(sp_label(:,end));
        bd = [bst';bsd';bsl;bsr];
        bd = unique(bd);
        
        edges = make_graph(sp_label, bd);
        dh = sqrt(sum((sp_feat(edges(:, 1), :)-sp_feat(edges(:, 2), :)).^2, 2));
        dh = (dh-min(dh)) / (max(dh)-min(dh));
        w = exp(-dh*theta);
        Wh = sparse([edges(:, 1); edges(:, 2)],...
            [edges(:, 2), edges(:, 1)],...
            [w, w],...
            sp_num, sp_num);
        
        sal = superpixel_saliency(Wh,bd,sp_obj, sp_pos,2.1e-7,9e-8,0.1, sp_num); 
        
        rlbmap = lbmap_from_sp(sal, sp_label);
        sal_map = sal_map * (i_ns-1.0)/i_ns + rlbmap * 1.0/i_ns;
    end
    sal_map = (sal_map-min(sal_map(:))) / (max(sal_map(:)) - min(sal_map(:)));
    imwrite(sal_map, sprintf('%s/%s.png', output_root, img_name(1:end-4)), 'png');
end
end
