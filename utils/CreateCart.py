#!/usr/bin/env python3

"""
Extract the binary components from the original t2k rom
"""

import sys
import os

if len(sys.argv) < 2:
    print("Not enough filenames given")
    exit()

romname = sys.argv[1]
rom = open(romname, 'wb')

args = len(sys.argv)

for fn in sys.argv[1:]:
    if not os.path.isfile(fn):
        print(fn + " does not exist")
        exit()
    f = open(fn, 'rb')
    rom.write(f.read())


