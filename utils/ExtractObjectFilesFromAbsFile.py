#!/usr/bin/env python3

"""
Extract the binary components from the linked abs file created by `make`
"""

import sys
import os
from itertools import chain

d = open("ourrom/details.txt", 'w')

f = open("../t2k.abs", 'rb')
bs = f.read()

o = open("ourrom/romheader.bin", 'wb')
o.write(bs[:0xa4])

o = open("ourrom/yak.o", 'wb')
o.write(bs[0xa8:0x18440])

o = open("ourrom/vidinit.o", 'wb')
o.write(bs[0x18440:0x184F8])

o = open("ourrom/yakgpu.o", 'wb')
o.write(bs[0x184f8:0x1e138])

s = 0x1e138
l = [0x1f400 - 0x90, 0x1f400, 0x25800, 0x14000,0x1f400,0x1f400]
for i in range(3,9):
    o = open("ourrom/beasty" + str(i) + ".cry", 'wb')
    e = s + l[i-3]
    o.write(bs[s:e])
    print("ourrom/beasty" + str(i) + ".cry",hex(s),hex(e), file=d)
    s = e

fs = ["tune13.mod", "tune7.mod", "tune1.mod", "tune3.mod", "rave4.mod", "tune5.mod", "tune12.mod"]     
for f in fs:
    nb = os.path.getsize("../src/sounds/" + f)
    e = s+nb
    ob = bs[s:e] + b'\x00\x00\x00\x00'
    print(f,hex(s),hex(e), file=d)
    o = open("ourrom/" + f, 'wb')
    o.write(ob)
    s = e + 4

s += 4
fs = ["smp.bin"]     
for f in fs:
    nb = os.path.getsize("../src/" + f)
    e = s+nb
    ob = bs[s:e]
    o = open("ourrom/" + f, 'wb')
    o.write(ob)
    print(f, hex(s), hex(e), file=d)
    s = e

l = chain(range(1,4), range(6,31), [15])
for f in [("0"+str(i))[-2:] for i in l]:
    nb = os.path.getsize("../src/sounds/samples/" + f)
    e = s+nb
    ob = bs[s:e] + b'\x00\x00\x00\x00'
    print(f,hex(s),hex(e), file=d)
    o = open("ourrom/" + f, 'wb')
    o.write(ob)
    s = e + 4

s += 4
print(hex(s), file=d)
o = open("ourrom/paddingaftersamples.bin", 'wb')
o.write(bs[s:])

