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

if len(argv) != 2:
    print("ERROR:\n  Usage: python3 parse_imulation.py <simulation-output-file>")
    exit(1)


fname = argv[1]
if not path.isfile(fname):
    print("ERROR:\n  Usage: python3 parse_imulation.py <simulation-output-file>")
    exit(1)


print ("## OUTPUT OF THE RISC-V ########################################################")
with open(fname, "r") as fh:
    for line in fh:
        line = line.rstrip()
        line_int = int(line,2)
        # print("%c <%d>" % (chr(line_int),line_int))
        if line_int == 10:
            print("\n", end='')
        elif line_int == 13:
            print("\n", end='')
        elif line_int == 32:
            print(" ", end='')
        elif (line_int > 32) and (line_int < 126):
            print(chr(line_int), end='')
        else:
            print("€", end='')
print("\n## END "+ "#"*73)