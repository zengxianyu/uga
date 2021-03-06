%clear;
%dataset = 'ECSSD';
%42.941
function main(dataset)
img_root = sprintf('/home/zeng/data/datasets/saliency_Dataset/%s/images/images', dataset);
mat_root = sprintf('/home/zeng/data/datasets/saliency_Dataset/%s/gop', dataset);
mat_root2 = sprintf('/home/zeng/data/datasets/saliency_Dataset/%s/vgg', dataset);
output_root = sprintf('/home/zeng/data/datasets/saliency_Dataset/%s/Ours17', dataset);
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
    [m, n, ~] = size(img);
    sal_map = 1;
    img_feat = imresize(img_feat, [m, n]);
    [~, ~, k] = size(img_feat);
    img_feat = reshape(img_feat, m*n, k);
    img_feat = (img_feat-min(img_feat)) ./ (max(img_feat)-min(img_feat)+eps);
    img_lab = colorspace('Lab<-', img);
    img_lab = reshape(img_lab, m*n, 3);
    img_lab = (img_lab-min(img_lab)) ./ (max(img_lab)-min(img_lab)+eps);
    Q_lab = quantify_color(img_lab);
    for i_ns = 1:length(Ns)
        %% superpixel segmentation
        [sp_label, sp_num] = segment_superpixel(double(img), Ns(i_ns));
        % superpixel level feature
        sp_hist = zeros(sp_num, 512);
        sp_feat = zeros(sp_num, k);
        sp_pos = zeros(sp_num, 2);
        sp_obj = zeros(sp_num, 1);
        for i = 1:sp_num
            sp_feat(i, :) = mean(img_feat(sp_label==i, :), 1);
            sp_obj(i) = mean(img_obj(sp_label==i));
            [y, x] = find(sp_label==i);
            sp_pos(i, 1) = mean(x);
            sp_pos(i, 2) = mean(y);
            sp_hist(i, :) = hist( Q_lab(sp_label==i), 1:512)';
            sp_hist(i, :) = sp_hist(i, :) / max( sum(sp_hist(i, :)), eps );
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
        Whd = pdist2(sp_hist, sp_hist, @ChiSq);
        Whd = (Whd-min(Whd(:))) / (max(Whd(:))-min(Whd(:)));
        Whd = exp(-Whd * theta);
        Wh = zeros(sp_num, sp_num);
        Adj = sparse([edges(:, 1); edges(:, 2)], [edges(:, 2), edges(:, 1)], ones(length(edges)*2, 1), sp_num, sp_num);
        Wh(Adj==1) = Whd(Adj==1);
        
        Wdd = pdist2(sp_feat, sp_feat, 'euclidean');
        Wdd = (Wdd-min(Wdd(:))) / (max(Wdd(:))-min(Wdd(:)));
        Wdd = exp(-Wdd * theta);
        Wd = zeros(sp_num, sp_num);
        Wd(Adj==1) = Wdd(Adj==1);
        %% stage 1
        sp_sal_c = superpixel_saliency(Wh,bd,sp_obj, sp_pos,2.1e-7,9e-8,0.007, sp_num); 
        
        sp_sal_d = superpixel_saliency(Wd,bd,sp_obj, sp_pos,2.1e-7,9e-8,0.1, sp_num); 
        
        %% stage 2
        Wh = Wh + eye(sp_num,sp_num);
        Wd = Wd + eye(sp_num,sp_num);
        
        Wh = Wh ./ sum(Wh,2);
        Whd = Whd ./ sum(Whd, 2);
        Wd = Wd ./ sum(Wd, 2);
        Wdd = Wd ./ sum(Wdd, 2);
        
        for tt = 1:5
            %% random walk (in fcn pooling5 space, use his-map to generate seed)
            Whd = Wd*Whd*Wd' + eye(sp_num,sp_num);
            Wdd = Wh*Wdd*Wh' + eye(sp_num,sp_num);
            tempC = propagate1(Whd-diag(diag(Whd)), sp_sal_d, sp_num, 1);
            tempD = propagate1(Wdd-diag(diag(Wdd)), sp_sal_c, sp_num, 1);
            sp_sal_d = tempD; sp_sal_c = tempC;
        end
        for tt = 1:15
            %% random walk (in fcn pooling5 space, use his-map to generate seed)
            Whd = Wd*Whd*Wd' + eye(sp_num,sp_num);
            Wdd = Wh*Wdd*Wh' + eye(sp_num,sp_num);
            tempC = propagate2(Whd-diag(diag(Whd)), sp_sal_d, sp_num, 1);
            tempD = propagate2(Wdd-diag(diag(Wdd)), sp_sal_c, sp_num, 1);
            sp_sal_d = tempD; sp_sal_c = tempC;
        end
        % accumulate incumbent map in average
        rlbmap = lbmap_from_sp(0.7*sp_sal_d+0.3*sp_sal_c, sp_label);
        sal_map = sal_map * (i_ns-1.0)/i_ns + rlbmap * 1.0/i_ns;
    end
    sal_map = (sal_map-min(sal_map(:))) / (max(sal_map(:)) - min(sal_map(:)));
    imwrite(sal_map, sprintf('%s/%s.png', output_root, img_name(1:end-4)), 'png');
end
end
