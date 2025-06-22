#!/bin/csh

source ~/cshrc
clear
xrun -access +rwc -64bit -top top -f file.f -timescale 1ns/1ns
set expected_count = `cat xrun.log | grep -c "\[DRIVER\].*r_en=1.*"`  # Set your expected number here
set success_count = `cat xrun.log | grep -Ec "(\[SCOREBOARD\]: Read data matches memory\.|\[SCOREBOARD\]: Memory is empty, cannot read data\.)"`

if ($success_count == $expected_count) then
    echo "SUCCESS: Number of matches ($success_count) equals expected ($expected_count)."
else
    echo "FAILURE: Number of matches ($success_count) does not equal expected ($expected_count)."
endif
# xrun -access +rwc -64bit -top top -f file.f -timescale 1ns/1ns #-gui -input restore.tcl
# xrun -access +rwc -64bit -top top -l xrun.log -timescale 1ns/1ns ../fifo3.sv ../fifo_test.sv ../top.sv -input restore.tcl
