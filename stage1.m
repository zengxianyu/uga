clear;
img_root = './images';
mat_root = './gop';
output_root = './output_color';
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
    img_lab = colorspace('Lab<-', img);
    sal_map = 1;
    rlbmap = 1;
    [m, n, ~] = size(img_lab);
    img_lab = reshape(img_lab, m*n, 3);
    img_lab = (img_lab-min(img_lab)) ./ (max(img_lab)-min(img_lab)+eps);
    Q_lab = quantify_color(img_lab);
    for i_ns = 1:length(Ns)
        %% superpixel segmentation
        [sp_label, sp_num] = segment_superpixel(double(img), Ns(i_ns));
        % superpixel level feature
        sp_hist = zeros(sp_num, 512);
        sp_pos = zeros(sp_num, 2);
        sp_obj = zeros(sp_num, 1);
        for i = 1:sp_num
            sp_obj(i) = mean(img_obj(sp_label==i));
            [y, x] = find(sp_label==i);
            sp_pos(i, 1) = mean(x);
            sp_pos(i, 2) = mean(y);
            sp_hist(i, :) = hist( Q_lab(sp_label==i), 1:512)';
            sp_hist(i, :) = sp_hist(i, :) / max( sum(sp_hist(i, :)), eps );
        end
        sp_pos = (sp_pos - min(sp_pos)) ./ (max(sp_pos) - min(sp_pos)+eps);
        sp_pos = exp(-1 * sqrt(sum((sp_pos - 0.5) .^ 2, 2)) );
        sp_pos = (sp_pos - min(sp_pos)) ./ (max(sp_pos) - min(sp_pos)+eps);
        sp_obj = (sp_obj-min(sp_obj)) / (max(sp_obj)-min(sp_obj)+eps);
        %% graph
        bst=unique(sp_label(1,:));
        bsd=unique(sp_label(end,:));
        bsr=unique(sp_label(:,1));
        bsl=unique(sp_label(:,end));
        bd = [bst';bsd';bsl;bsr];
        bd = unique(bd);
        
        edges = make_graph(sp_label, bd);
        dh=0.5 * sum((sp_hist(edges(:,1),:)...
            - sp_hist(edges(:,2),:)).^2 ./ (sp_hist(edges(:,1),:) + ...
            sp_hist(edges(:,2),:) + eps),2);
        dh = (dh-min(dh)) / (max(dh)-min(dh)+eps);
        w = exp(-dh*theta);
        Wh = sparse([edges(:, 1); edges(:, 2)],...
            [edges(:, 2), edges(:, 1)],...
            [w, w],...
            sp_num, sp_num);
        
        sal = superpixel_saliency(Wh,bd,sp_obj, sp_pos,2.1e-7,9e-8,0.007, sp_num); 
        
        rlbmap = lbmap_from_sp(sal, sp_label);
        sal_map = sal_map * (i_ns-1.0)/i_ns + rlbmap * 1.0/i_ns;
    end
    sal_map = (sal_map-min(sal_map(:))) / (max(sal_map(:)) - min(sal_map(:)));
    imwrite(sal_map, sprintf('%s/%s.png', output_root, img_name(1:end-4)), 'png');
end
