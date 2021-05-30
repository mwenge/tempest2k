#!/usr/bin/env python3

"""
Extract the binary components from the original t2k rom
"""

import sys
import os
from itertools import chain



o = open("../t2k.rom", 'wb')

f = open("originalrom/romheader.bin", 'rb')
o.write(f.read())
f = open("../T2000.TX", 'rb')
o.write(f.read())
f = open("originalrom/paddingaftersamples.bin", 'rb')
o.write(f.read())
