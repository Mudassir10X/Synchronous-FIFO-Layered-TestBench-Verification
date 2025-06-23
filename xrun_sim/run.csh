#!/bin/csh

source ~/cshrc
clear
xrun -access +rwc -64bit -top top -f file.f -timescale 1ns/1ns -run -SVSEED 2 #-l ./aa/xrun.log -nolog

# Check if the success count matches the expected count
# set expected_count = `cat xrun.log | grep -c "\[DRIVER\].*r_en=1.*"`  # Set your expected number here
# set success_count = `cat xrun.log | grep -Ec "(\[SCOREBOARD\]: Read data matches memory\.|\[SCOREBOARD\]: Memory is empty, cannot read data\.)"`

# if ($success_count == $expected_count) then
#     echo "SUCCESS: Number of matches ($success_count) equals expected ($expected_count)."
# else
#     echo "FAILURE: Number of matches ($success_count) does not equal expected ($expected_count)."
# endif

# Run with GUI and restore settings
# xrun -access +rwc -64bit -top top -f file.f -timescale 1ns/1ns -gui -input restore.tcl
