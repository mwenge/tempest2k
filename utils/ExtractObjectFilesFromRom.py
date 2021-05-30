#!/usr/bin/env python3

"""
Extract the binary components from the original t2k rom
"""

import sys
import os
from itertools import chain

d = open("originalrom/details.txt", 'w')

f = open("../orig/t2k.jag", 'rb')
bs = f.read()

o = open("originalrom/romheader.bin", 'wb')
o.write(bs[:0x2000])

o = open("originalrom/yak.o", 'wb')
o.write(bs[0x2000:0x1a398])

o = open("originalrom/obj2dat.o", 'wb')
o.write(bs[0x181ea:0x197fa])

o = open("originalrom/vidinit.o", 'wb')
o.write(bs[0x1a398:0x1a450])

o = open("originalrom/yakgpu.o", 'wb')
o.write(bs[0x1a450:0x20090])

# Extract the gpu binaries
s = 0x1a450 + 0xd6 
# antelope has 0xe48 in the header but is actually 0xe4a long
# ox has 0xa3c in the header but is actually 0xa3e long
fs = [("llama.o",0xa82, 8), ("goat.o",0xc46, 8), ("antelope.o",0xe4a, 8), ("camel.o",0x68a, 8),
        ("xcamel.o",0xd32, 8), ("stoat.o",0x2f6, 8), ("ox.o",0xa3e, 8), ("horse.o",0xb4a, 8), ("donky.o",0x9e0, 8)]     
for f, nb, skip in fs:
    print("DC.L " + "$" + bs[s:s+skip].hex()[:8], ", $" + bs[s:s+skip].hex()[8:], file=d)
    s += skip
    e = s + nb
    ob = bs[s:e-2]
    print(f,hex(s),hex(e), file=d)
    o = open("originalrom/" + f, 'wb')
    o.write(ob)
    s = e - 2

# the first image has the first 0x90 bytes chopped off for some reason, probably accidental.
s = 0x20090
l = [0x1f400 - 0x90, 0x1f400, 0x25800, 0x14000,0x1f400,0x1f400 + 0x100]
for i in range(3,9):
    o = open("originalrom/beasty" + str(i) + ".cry", 'wb')
    e = s + l[i-3]
    o.write(bs[s:e])
    print("originalrom/beasty" + str(i) + ".cry",hex(s),hex(e), file=d)
    s = e

o = open("originalrom/paddingbetweencryandmod.bin", 'wb')
o.write(bs[0xd6800:0xd6900])

s = 0xd6900
fs = ["tune13.mod", "tune7.mod", "tune1.mod", "tune3.mod", "rave4.mod", "tune5.mod", "tune12.mod"]     
for f in fs:
    nb = os.path.getsize("../src/sounds/" + f)
    e = s+nb
    ob = bs[s:e] + b'\x00\x00\x00\x00'
    print(f,hex(s),hex(e), file=d)
    o = open("originalrom/" + f, 'wb')
    o.write(ob)
    s = e + 4

o = open("originalrom/paddingbetweentunesandsmp.bin", 'wb')
o.write(bs[s:0x1ac800])

s = 0x1ac800
fs = ["smp.bin"]     
for f in fs:
    nb = os.path.getsize("../src/" + f)
    e = s+nb
    ob = bs[s:e]
    o = open("originalrom/" + f, 'wb')
    o.write(ob)
    print(f, hex(s), hex(e), file=d)
    s = e

o = open("originalrom/paddingbetweensmpandsamples.bin", 'wb')
o.write(bs[s:0x1acd00])

s = 0x1acd00
l = chain(range(1,4), range(6,31), [15])
for f in [("0"+str(i))[-2:] for i in l]:
    nb = os.path.getsize("../src/sounds/samples/" + f)
    e = s+nb
    ob = bs[s:e] + b'\x00\x00\x00\x00'
    print(f,hex(s),hex(e), file=d)
    o = open("originalrom/" + f, 'wb')
    o.write(ob)
    s = e + 4

s -= 4
print(hex(s), file=d)
o = open("originalrom/paddingaftersamples.bin", 'wb')
o.write(bs[s:])

