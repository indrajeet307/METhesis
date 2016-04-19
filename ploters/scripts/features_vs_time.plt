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
V_lab_data ="../data/after_modified_features_lab_device.data"
V_my_data  ="../data/after_modified_features_my_device.data"
V_prev_data="../data/before_modified_features.data"
V_out_file = "../plots/features_vs_time_taken.jpeg"
set term jpeg size 1080,640 fontscale 
set output V_out_file
set grid
set title "Number of Features Vs Time Taken"
set xlabel "Number of Features(opcodes)"
set ylabel "Time(milisecs)"
set yrange [0:600]
set xrange [10:1820]
plot V_lab_data using 1:2 title "Parallel" with lines, V_lab_data using 1:3 title "Sequential" with lines, V_my_data using 1:2 title "my_device_parallel" with lines, V_my_data using 1:3 title "my_device_seq" with lines , V_prev_data using 1:2 title "Parallel_before_feature" with lines, V_prev_data using 1:3 title "Seq_before_feature" with lines
# join above two lines to get the previous results

