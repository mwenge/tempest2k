#!/usr/bin/env python3
import sys
import os

if len(sys.argv) < 2:
    print("No filename given")
    exit()

fn = sys.argv[1]
if not os.path.isfile(fn):
    print(fn + " does not exist")
    exit()

f = open(fn, 'rb')

on = sys.argv[2]
o = open(on, 'w')

if len(sys.argv) == 4:
    start = sys.argv[3]
    f.read(int(start))

line = []
while True:
    bs = "$" + f.read(4).hex().upper()
    if len(bs) == 1:
        break
    line.append(bs)
    if len(line) < 4:
        continue
    o.write("DC.L  " + ','.join(line) + '\n')
    line = []
if line:
    o.write("DC.L  " + ','.join(line) + '\n')

