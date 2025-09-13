#!/usr/bin/env python3
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.

from sys import argv
from os import path

# Validate arguments
if len(argv) != 4:
    print("ERROR:\n  Usage: python3 makevhd.py <hex-file> <vhd-file> <template-file>")
    exit(1)

hexfile = argv[1]
if not path.isfile(hexfile):
    print("ERROR:\n    hex-file not found")
    print("Usage:\n  python3 makevhd.py <hex-file> <vhd-file>")
    exit(1)


# Construct file names
vhd_file = argv[2]
template_file = argv[3]
ofh = open(vhd_file, "w")

# Copy part alpha of template
ifh_template = open(template_file, "r")
for line in ifh_template:
    if "@template_alpha" in line:
        break
    else:
        ofh.write(line)



# Write the inititialisation in the lower half of the memory
vhdl_line = ""
inner_counter = 0
outer_counter = 0

ifh_hex = open(hexfile, "r")
for line in ifh_hex:
    line = line.rstrip()
    vhdl_line = line + vhdl_line;
    if inner_counter == 7:
        header = "        INIT_%02X => X\"" % outer_counter
        ofh.write(header+vhdl_line+"\",\n")
        inner_counter = 0
        outer_counter += 1
        vhdl_line = ""
    else:
        inner_counter += 1
    
    if outer_counter == 128:
        break


# Copy part beta of template
for line in ifh_template:
    if "@template_beta" in line:
        break
    else:
        ofh.write(line)

# Write the inititialisation in the higher half of the memory
vhdl_line = ""
inner_counter = 0
outer_counter = 0
for line in ifh_hex:
    line = line.rstrip()
    vhdl_line = line + vhdl_line;
    if inner_counter == 7:
        header = "        INIT_%02X => X\"" % outer_counter
        ofh.write(header+vhdl_line+"\",\n")
        inner_counter = 0
        outer_counter += 1
        vhdl_line = ""
    else:
        inner_counter += 1

ifh_hex.close()  

    
# Copy part beta of template
for line in ifh_template:
    ofh.write(line)


ifh_template.close()  
ofh.close()
