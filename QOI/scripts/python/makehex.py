#!/usr/bin/env python3
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.

from sys import argv, exit
from os import path

if len(argv) != 3:
    print("ERROR:\n  Usage: python3 makehex.py <bin-file> <imem size in bytes>")
    exit(1)

binfile = argv[1]
if not path.isfile(binfile):
    print("ERROR:\n    bin-file not found")
    print("Usage:\n  python3 makehex.py <bin-file> <imem size in bytes>")
    exit(1)

with open(binfile, "rb") as f:
    bindata = f.read()    

if len(bindata) % 4:
    while(len(bindata) % 4):
        bindata = bindata + b'\x00'

nwords = int(argv[2])

if len(bindata) >= nwords:
    print("ERROR:\n    memory size is insufficient")
    exit(1)

ofname_imem = binfile[0:-4]+"_imem.hex"
ofh_imem = open(ofname_imem, "w")

ofname_dmem = binfile[0:-4]+"_dmem.hex"
ofh_dmem = open(ofname_dmem, "w")

for i in range(len(bindata)//4):
    w = bindata[4*i : 4*i+4]

    if i < 2048:
        ofh_imem.write("%02x%02x%02x%02x\n" % (w[3], w[2], w[1], w[0]))
    else:
        ofh_dmem.write("%02x%02x%02x%02x\n" % (w[3], w[2], w[1], w[0]))
    
for i in range((nwords - len(bindata))//4):
    if (len(bindata)//4+i) < 2048:
        ofh_imem.write("00000000\n")
    else:
        ofh_dmem.write("00000000\n")

ofh_imem.close()
ofh_dmem.close()

