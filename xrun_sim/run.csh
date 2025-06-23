#!/bin/csh

source ~/cshrc

xrun -access +rwc -64bit -top top -f file.f -timescale 1ns/1ns -run -SVSEED 2 