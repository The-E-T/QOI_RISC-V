#!/usr/bin/python3

ifname = "simulation_output.dat"
ofname = "simumation_output.qoi"

ifh = open(ifname, "r")
ofh = open (ofname, "wb")


for line in ifh:
    line = line.rstrip()
    line_int = int(line, 2)
    
    ofh.write(line_int.to_bytes(1,byteorder='big'))

ifh.close()
ofh.close()