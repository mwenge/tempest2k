.incbin "images/beasty3-trunc.cry"
.incbin "images/beasty4.cry"
.incbin "images/beasty5.cry"
.incbin "images/beasty6.cry"
.incbin "images/beasty7.cry"
.incbin "images/beasty8.cry"

modbase      EQU $8d6800

modtable:
.dc.l modbase + $100   ; tune13.mod
.dc.l modbase + $18d2c ; tune7.mod
.dc.l modbase + $37a04 ; tune1.mod
.dc.l modbase + $5bd7c ; tune3.mod
.dc.l modbase + $80b22 ; rave4.mod
.dc.l modbase + $99d72 ; tune5.mod
.dc.l modbase + $b0a50 ; tune12.mod
.dc.l 0

; This is a fragment of data from beasty8.cry.
; It must have ended up here and not been overwritten somehow.
; This is what it looks like in beasty8.cry, starting at position
; 0xf466 in that file:
; 0000f460: 0000 0000 0000 e37b 0000 e37b fbab fb97  .......{...{....
; 0000f470: f05f f053 f053 f053 f047 f047 f047 f03f  ._.S.S.S.G.G.G.?
; 0000f480: f03f f03f f033 f033 f033 f027 f027 f027  .?.?.3.3.3.'.'.'
; 0000f490: f01f f01f f01f f013 f013 f013 f00b fcbb  ................
; 0000f4a0: ebcb 0000 0000 0000 0000 0000 e37b 0000  .............{..
; 0000f4b0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
; 0000f4c0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
; 0000f4d0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
; 0000f4e0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
; 0000f4f0: 0000 0000 0000 0000 0000 0000 0000 0000  ................

.dc.l $e37b0000, $e37b0f1b, $f953fa63, $fa63fd5b
.dc.l $fd4ff943, $f053f047, $f03ff03f, $f03ff033
.dc.l $f033f033, $f027f027, $f027f01f, $f01ff943
.dc.l $fd4ffc57, $fc57fd5b, $fc3f0f1b, $00000000
.dc.l $00000000, $0000e37b, $0000e37b, $fbabfb97
.dc.l $f05ff053, $f053f053, $f047f047, $f047f03f
.dc.l $f03ff03f, $f033f033, $f033f027, $f027f027
.dc.l $f01ff01f, $f01ff013, $f013f013, $f00bfcbb
.dc.l $ebcb0000, $00000000, $00000000, $e37b0000
.dc.l $00000000, $00000000, $00000000, $00000000
.dc.l $00000000, $00000000, $00000000, $00000000
.dc.l $00000000, $00000000, $00000000, $00000000
.dc.l $00000000, $00000000, $00000000, $00000000
.dc.l $00000000, $00000000, $00000000, $00000000

; modbase starts here.
.incbin "sounds/tune13.mod"
.DC.L $0000
.incbin "sounds/tune7.mod"
.DC.L $0000
.incbin "sounds/tune1.mod"
.DC.L $0000
.incbin "sounds/tune3.mod"
.DC.L $0000
.incbin "sounds/rave4.mod"
.DC.L $0000
.incbin "sounds/tune5.mod"
.DC.L $0000
.incbin "sounds/tune12.mod"
.DC.L $0000

; This contains fragments of tune12.mod, tune7.mod, and tune6.mod.
; The data is the 'sample' date from each mod file since that tends to take
; up most of each file and appear towards the end. It tells us that at one
; time tune6.mod was included in the build.
; Bytes 0     - 3192   tune12.mod
; Bytes 3192  - 23176  tune7.mod
; Bytes 23176 - end    tune6.mod
.incbin "incbin/paddingbetweentunesandsmp.bin"

; This is a table containing metadata for the samples. Pseucode representation below:
;                              Prio-                             Ze   Repeat     Repeat
;      Name                    rity   Period Start      Length   ro   Start      Length      
;      ----------------------  -----  ------ ---------  -------  --   ---------  ---------
; dc.b 'Engine Noise 1      ', $0001, $01ac, $009acd00, $0011a0, $00, $009acd02, $00119e, $00
; dc.b 'Player Shot Normal 2', $0002, $01ac, $009adea4, $0008e8, $00, $009adea4, $000000, $00
; dc.b 'Engine Noise        ', $0003, $01ac, $009ae290, $003378, $00, $009aee9e, $002594, $00
; dc.b 'Player Death        ', $0004, $00d6, $00000000, $00549a, $00, $00000000, $000000, $00
; dc.b 'Player Death 2      ', $0005, $01ac, $00000000, $002458, $00, $00000000, $000000, $00
; dc.b 'Player Shot Normal  ', $0006, $01ac, $009b160c, $0007a4, $00, $009b160c, $000000, $00
; dc.b 'Player Jump         ', $0007, $01ac, $009b1db4, $0018de, $00, $009b1db4, $000000, $00
; dc.b 'Crackle             ', $0008, $00d6, $009b3696, $004594, $00, $009b3696, $000000, $00
; dc.b 'Cleared Level       ', $0009, $01ac, $009b7c2e, $0037a2, $00, $009b7c2e, $000000, $00
; dc.b 'Warp                ', $000a, $0238, $009bb3d4, $006ec8, $00, $009bb3d4, $000000, $00
; dc.b 'Large Explosion     ', $000b, $01ac, $009c22a0, $0050c2, $00, $009c22a0, $000000, $00
; dc.b 'Powered Up Shot     ', $000c, $01ac, $009c7366, $001976, $00, $009c7366, $000000, $00
; dc.b 'Get Power Up        ', $000d, $01ac, $009c8ce0, $001aea, $00, $009c8ce0, $000000, $00
; dc.b 'Tink For Spike      ', $000e, $00fe, $009ca7ce, $00040e, $00, $009ca7ce, $000000, $00
; dc.b 'NME At Top Of Web   ', $000f, $01ac, $009cabe0, $00001e, $00, $009cabe0, $000000, $00
; dc.b 'Pulse For Pulsar    ', $0010, $0358, $009cac02, $0019fe, $00, $009cac02, $000000, $00
; dc.b 'Normal Explosion    ', $0011, $00d6, $009cc604, $002ab6, $00, $009cc604, $000000, $00
; dc.b 'Extra Explosion     ', $0012, $0358, $009cf0be, $0018ca, $00, $009cf0be, $000000, $00
; dc.b 'Static or Pulsar    ', $0013, $011c, $009d098c, $003fe4, $00, $009d098c, $000000, $00
; dc.b 'Pulsar Pulse        ', $0014, $0358, $009d4974, $000f0c, $00, $009d4974, $000000, $00
; dc.b 'Off Shielded NME    ', $0015, $00aa, $009d5884, $0027ca, $00, $009d5884, $000000, $00
; dc.b 'Excellent           ', $0016, $0200, $009d8052, $005976, $00, $009d8052, $000000, $00
; dc.b 'Superzapper Recharge', $0016, $0200, $009dd9cc, $00a958, $00, $009dd9cc, $000000, $00
; dc.b 'yes                 ', $0018, $0200, $009e8328, $005a6c, $00, $009e832a, $005a6a, $00
; dc.b 'oneup               ', $0019, $0200, $009edd98, $0043ae, $00, $009edd98, $000000, $00
; dc.b 'screeeam            ', $001a, $0200, $009f214a, $004568, $00, $009f214a, $000000, $00
; dc.b 'sexy yes 1          ', $001b, $0200, $009f66b6, $002c54, $00, $009f66b6, $000000, $00
; dc.b 'sexy yes 2          ', $001c, $0200, $009f9362, $003236, $00, $009f9362, $000000, $00
; dc.b 'tink                ', $001e, $0200, $009fc59c, $0005ce, $00, $009fc59c, $000000, $00
; dc.b 'zero                ', $001f, $0200, $009fcb6e, $000008, $00, $009fcb6e, $000000, $00
; dc.b 'dummy               ', $0020, $0200, $009fcb7a, $00a1d8, $00, $009fcb7a, $000000, $00
.incbin "incbin/sound_samples_table.bin"

.incbin "sounds/samples/01"
.DC.L $0000
.incbin "sounds/samples/02"
.DC.L $0000
.incbin "sounds/samples/03"
.DC.L $0000
.incbin "sounds/samples/06"
.DC.L $0000
.incbin "sounds/samples/07"
.DC.L $0000
.incbin "sounds/samples/08"
.DC.L $0000
.incbin "sounds/samples/09"
.DC.L $0000
.incbin "sounds/samples/10"
.DC.L $0000
.incbin "sounds/samples/11"
.DC.L $0000
.incbin "sounds/samples/12"
.DC.L $0000
.incbin "sounds/samples/13"
.DC.L $0000
.incbin "sounds/samples/14"
.DC.L $0000
.incbin "sounds/samples/15"
.DC.L $0000
.incbin "sounds/samples/16"
.DC.L $0000
.incbin "sounds/samples/17"
.DC.L $0000
.incbin "sounds/samples/18"
.DC.L $0000
.incbin "sounds/samples/19"
.DC.L $0000
.incbin "sounds/samples/20"
.DC.L $0000
.incbin "sounds/samples/21"
.DC.L $0000
.incbin "sounds/samples/22"
.DC.L $0000
.incbin "sounds/samples/23"
.DC.L $0000
.incbin "sounds/samples/24"
.DC.L $0000
.incbin "sounds/samples/25"
.DC.L $0000
.incbin "sounds/samples/26"
.DC.L $0000
.incbin "sounds/samples/27"
.DC.L $0000
.incbin "sounds/samples/28"
.DC.L $0000
.incbin "sounds/samples/29"
.DC.L $0000
.incbin "sounds/samples/30"
.DC.L $0000
.incbin "sounds/samples/15"

; This contains fragments of sample data.
; sample 28
.incbin "incbin/paddingaftersamples.bin"
