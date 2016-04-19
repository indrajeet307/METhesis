# used to plot graph for accuracy vs frequency
# 1st column should be number of features
# 2nd column should be accuracy
# example
# 20  0.582142 
# 30  0.593358 
# 40  0.633165 
# 50  0.653178 
# 60  0.654937 
# 70  0.652738 
# 80  0.648999 
# 90  0.653398 
# 100 0.644821 
set term jpeg size 1080,640 fontscale 1.2
set output "accuracy_vs_features.jpeg"
set grid
set title "Number of Features Vs Accuracy"
set xlabel "Number of Features"
set ylabel "Accuracy/100"
plot "res" using 1:2 title "Accuracy" with lines
