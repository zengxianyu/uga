# My2017
code for the paper "An unsupervised game-theoretic approach to saliency detection"

## Stage1: Saliency Game
run stage1.m (gop proposals should be provided as .mat file, run stage1_nogop.m for the one without gop proposals.)

run stage1_vgg.m for the one use deep features, e.g., VGG features. Deep features should be provided as .mat file. 

## stage2: Iterative Random Walk
run stage2.m to fuse the results using deep features and the results using color features. 
