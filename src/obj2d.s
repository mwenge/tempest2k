s_flipper: 
  dc.l 4		;4 faces in this object, a shaded solid Flipper

	dc.w $f0		;Face colour - RED
	dc.w 3,$8000		;vertex ptr and i
	dc.w 1,$c000		;vertex ptr and i
	dc.w 0,$ff00		;vertex ptr and i
	dc.w 0

	dc.w $f4		;Face colour - Blueish
	dc.w 4,$4000		;vertex ptr and i
	dc.w 2,$8000		;vertex ptr and i
	dc.w 0,$c000		;vertex ptr and i
	dc.w 0

	dc.w $f4		;Face colour - RED
	dc.w 5,$8000		;vertex ptr and i
	dc.w 1,$c000		;vertex ptr and i
	dc.w 0,$ff00		;vertex ptr and i
	dc.w 0

	dc.w $f0		;Face colour - Blueish
	dc.w 6,$4000		;vertex ptr and i
	dc.w 2,$8000		;vertex ptr and i
	dc.w 0,$c000		;vertex ptr and i
	dc.w 0

fverts: dc.w 9,9,5,9,13,9,1,0,17,0,1,18,17,18

s_fliptank: dc.l 12

	dc.w $92		;Pink, for this is a Pink Thang
	dc.w 3,$f000
	dc.w 0,$8000
	dc.w 7,$4000
	dc.w 0

	dc.w $93
	dc.w 7,$f000
	dc.w 4,$8000
	dc.w 0,$4000
	dc.w 0

	dc.w $92		;Pink, for this is a Pink Thang
	dc.w 0,$f000
	dc.w 1,$8000
	dc.w 4,$4000
	dc.w 0

	dc.w $93
	dc.w 4,$f000
	dc.w 5,$8000
	dc.w 1,$4000
	dc.w 0

	dc.w $92		;Pink, for this is a Pink Thang
	dc.w 1,$f000
	dc.w 2,$8000
	dc.w 5,$4000
	dc.w 0

	dc.w $93
	dc.w 5,$f000
	dc.w 6,$8000
	dc.w 2,$4000
	dc.w 0

	dc.w $92		;Pink, for this is a Pink Thang
	dc.w 2,$f000
	dc.w 3,$8000
	dc.w 6,$4000
	dc.w 0

	dc.w $93
	dc.w 6,$f000
	dc.w 7,$8000
	dc.w 3,$4000
	dc.w 0			;Here endeth the Standard Tanker Header

	dc.w $f0		;Face colour - RED
	dc.w 8,$8000		;vertex ptr and i
	dc.w 12,$c000		;vertex ptr and i
	dc.w 14,$ff00		;vertex ptr and i
	dc.w 0

	dc.w $30		;Face colour - Blueish
	dc.w 9,$4000		;vertex ptr and i
	dc.w 13,$6000		;vertex ptr and i
	dc.w 14,$8f00		;vertex ptr and i
	dc.w 0

	dc.w $30		;Face colour - RED
	dc.w 10,$8000		;vertex ptr and i
	dc.w 12,$c000		;vertex ptr and i
	dc.w 14,$ff00		;vertex ptr and i
	dc.w 0

	dc.w $f0		;Face colour - Blueish
	dc.w 11,$4000		;vertex ptr and i
	dc.w 13,$6000		;vertex ptr and i
	dc.w 14,$8f00		;vertex ptr and i
	dc.w 0

ftankverts: dc.w 9,1,17,9,9,17,1,9,9,4,14,9,9,14,4,9		;standard Tanker frame
	dc.w 6,7,12,7,6,11,12,11,7,9,11,9,9,9			;Flipper in the middle of it

s_fliptank2: dc.l 12		;12 faces in this object, a shaded solid Flipper Tanker

	dc.w $88
	dc.w $9,$8000
	dc.w $4,$4000
	dc.w 0,$ffff
	dc.w 0

	dc.w $88
	dc.w 6,$4000
	dc.w 10,$6000
	dc.w 0,$ffff
	dc.w 0

	dc.w $88
	dc.w 12,$4000
	dc.w 5,$8000
	dc.w 0,$ffff
	dc.w 0

	dc.w $88
	dc.w 3,$8000
	dc.w 11,$8000
	dc.w 0,$ffff
	dc.w 0


	dc.w $f0		;Face colour - RED
	dc.w 3,$8000		;vertex ptr and i
	dc.w 1,$c000		;vertex ptr and i
	dc.w 0,$ff00		;vertex ptr and i
	dc.w 0

	dc.w $30		;Face colour - Blueish
	dc.w 4,$4000		;vertex ptr and i
	dc.w 2,$6000		;vertex ptr and i
	dc.w 0,$8f00		;vertex ptr and i
	dc.w 0

	dc.w $30		;Face colour - RED
	dc.w 5,$8000		;vertex ptr and i
	dc.w 1,$c000		;vertex ptr and i
	dc.w 0,$ff00		;vertex ptr and i
	dc.w 0

	dc.w $f0		;Face colour - Blueish
	dc.w 6,$4000		;vertex ptr and i
	dc.w 2,$6000		;vertex ptr and i
	dc.w 0,$8f00		;vertex ptr and i
	dc.w 0

	dc.w $f4		;Face colour - RED
	dc.w 9,$8000		;vertex ptr and i
	dc.w 7,$c000		;vertex ptr and i
	dc.w 0,$ff00		;vertex ptr and i
	dc.w 0

	dc.w $34		;Face colour - Blueish
	dc.w 8,$4000		;vertex ptr and i
	dc.w 10,$6000		;vertex ptr and i
	dc.w 0,$8f00		;vertex ptr and i
	dc.w 0

	dc.w $34		;Face colour - RED
	dc.w 11,$8000		;vertex ptr and i
	dc.w 7,$c000		;vertex ptr and i
	dc.w 0,$ff00		;vertex ptr and i
	dc.w 0

	dc.w $f4		;Face colour - Blueish
	dc.w 12,$4000		;vertex ptr and i
	dc.w 8,$6000		;vertex ptr and i
	dc.w 0,$8f00		;vertex ptr and i
	dc.w 0


ft2verts: dc.w 9,9,5,9,13,9,-7,5,25,5,-7,13,25,13
	dc.w 9,5,9,13,13,1,13,17,5,1,5,17


fbpiece1: dc.l 2		;Two faces, this object is one leg of a Fuseball

	dc.w $2c
	dc.w 0,$4000
	dc.w 1,$8000
	dc.w 2,$6000
	dc.w 0

	dc.w $2e
	dc.w 3,$ffff
	dc.w 1,$8000
	dc.w 2,$6000
	dc.w 0

ft2v:	dc.w 1,9,5,6,5,8,9,9

fbpiece2: dc.l 2		;Two faces, this object is one leg of a Fuseball

	dc.w $2c
	dc.w 0,$4000
	dc.w 1,$8000
	dc.w 2,$6000
	dc.w 0

	dc.w $2e
	dc.w 3,$ffff
	dc.w 1,$8000
	dc.w 2,$6000
	dc.w 0

ft2v2:	dc.w 1,9,5,12,5,10,9,9


spuls1: dc.l 6		;Six faces

	dc.w $ff
	dc.w 0,$ffff
	dc.w 1,$ffff
	dc.w 2,$ffff
	dc.w 0

	dc.w $ff
	dc.w 1,$ffff
	dc.w 2,$ffff
	dc.w 3,$ffff
	dc.w 0

	dc.w $ff
	dc.w 3,$ffff
	dc.w 4,$ffff
	dc.w 5,$ffff
	dc.w 0

	dc.w $ff
	dc.w 4,$ffff
	dc.w 5,$ffff
	dc.w 6,$ffff
	dc.w 0

	dc.w $ff
	dc.w 6,$ffff
	dc.w 7,$ffff
	dc.w 8,$ffff
	dc.w 0

	dc.w $ff
	dc.w 7,$ffff
	dc.w 8,$ffff
	dc.w 9,$ffff
	dc.w 0

spv1: dc.w 0,9,3,15,3,13,6,9,9,3,9,5,12,9,15,15,15,13,18,9

spuls2: dc.l 6		;Six faces

	dc.w $fd
	dc.w 0,$8000
	dc.w 1,$c000
	dc.w 2,$c000
	dc.w 0

	dc.w $fe
	dc.w 1,$c000
	dc.w 2,$c000
	dc.w 3,$ffff
	dc.w 0

	dc.w $ff
	dc.w 3,$ffff
	dc.w 4,$ffff
	dc.w 5,$ffff
	dc.w 0

	dc.w $ff
	dc.w 4,$ffff
	dc.w 5,$ffff
	dc.w 6,$ffff
	dc.w 0

	dc.w $fe
	dc.w 6,$ffff
	dc.w 7,$c000
	dc.w 8,$c000
	dc.w 0

	dc.w $fd
	dc.w 7,$c000
	dc.w 8,$c000
	dc.w 9,$8000
	dc.w 0

spv2: dc.w 0,9,3,14,3,12,6,9,9,4,9,6,12,9,15,14,15,12,18,9

spuls3: dc.l 6		;Six faces

	dc.w $fb
	dc.w 0,$6000
	dc.w 1,$a000
	dc.w 2,$a000
	dc.w 0

	dc.w $fd
	dc.w 1,$a000
	dc.w 2,$a000
	dc.w 3,$e000
	dc.w 0

	dc.w $ff
	dc.w 3,$e000
	dc.w 4,$ffff
	dc.w 5,$ffff
	dc.w 0

	dc.w $ff
	dc.w 4,$ffff
	dc.w 5,$ffff
	dc.w 6,$e000
	dc.w 0

	dc.w $fd
	dc.w 6,$e000
	dc.w 7,$a000
	dc.w 8,$a000
	dc.w 0

	dc.w $fb
	dc.w 7,$a000
	dc.w 8,$a000
	dc.w 9,$6000
	dc.w 0

spv3: dc.w 0,9,3,13,3,11,6,9,9,5,9,7,12,9,15,13,15,11,18,9

spuls4: dc.l 6		;Six faces

	dc.w $f9
	dc.w 0,$4000
	dc.w 1,$8000
	dc.w 2,$8000
	dc.w 0

	dc.w $fc
	dc.w 1,$8000
	dc.w 2,$8000
	dc.w 3,$c000
	dc.w 0

	dc.w $ff
	dc.w 3,$c000
	dc.w 4,$ffff
	dc.w 5,$ffff
	dc.w 0

	dc.w $ff
	dc.w 4,$ffff
	dc.w 5,$ffff
	dc.w 6,$c000
	dc.w 0

	dc.w $fc
	dc.w 6,$c000
	dc.w 7,$8000
	dc.w 8,$8000
	dc.w 0

	dc.w $f9
	dc.w 7,$8000
	dc.w 8,$8000
	dc.w 9,$4000
	dc.w 0

spv4: dc.w 0,9,3,12,3,10,6,9,9,6,9,8,12,9,15,12,15,10,18,9

spuls5: dc.l 6		;Six faces

	dc.w $f7
	dc.w 0,$4000
	dc.w 1,$8000
	dc.w 2,$8000
	dc.w 0

	dc.w $fb
	dc.w 1,$8000
	dc.w 2,$8000
	dc.w 3,$c000
	dc.w 0

	dc.w $ff
	dc.w 3,$c000
	dc.w 4,$ffff
	dc.w 5,$ffff
	dc.w 0

	dc.w $ff
	dc.w 4,$ffff
	dc.w 5,$ffff
	dc.w 6,$c000
	dc.w 0

	dc.w $fb
	dc.w 6,$c000
	dc.w 7,$8000
	dc.w 8,$8000
	dc.w 0

	dc.w $f7
	dc.w 7,$8000
	dc.w 8,$8000
	dc.w 9,$4000
	dc.w 0

spv5: dc.w 0,9,3,11,3,9,6,9,9,7,9,9,12,9,15,11,15,9,18,9

spuls6: dc.l 6		;Six faces

	dc.w $f5
	dc.w 0,$4000
	dc.w 1,$8000
	dc.w 2,$8000
	dc.w 0

	dc.w $fa
	dc.w 1,$8000
	dc.w 2,$8000
	dc.w 3,$c000
	dc.w 0

	dc.w $ff
	dc.w 3,$c000
	dc.w 4,$ffff
	dc.w 5,$ffff
	dc.w 0

	dc.w $ff
	dc.w 4,$ffff
	dc.w 5,$ffff
	dc.w 6,$c000
	dc.w 0

	dc.w $fa
	dc.w 6,$c000
	dc.w 7,$8000
	dc.w 8,$8000
	dc.w 0

	dc.w $f5
	dc.w 7,$8000
	dc.w 8,$8000
	dc.w 9,$4000
	dc.w 0

spv6: dc.w 0,9,3,10,3,8,6,9,9,8,9,10,12,9,15,10,15,8,18,9


chevron: dc.l 2

	dc.w $44
	dc.w 2,$c000
	dc.w 1,$ffff
	dc.w 0,$4000
	dc.w 0

	dc.w $cc
	dc.w 3,$c000
	dc.w 1,$ffff
	dc.w 0,$4000
	dc.w 0

chevvert: dc.w 1,9,4,9,5,8,5,10


chev: dc.l 1

	dc.w $44
	dc.w 2,$c000
	dc.w 1,$ffff
	dc.w 0,$4000
	dc.w 0

goatverts: dc.w 1,9,4,8,4,10


pshot: dc.l 4

	dc.w $aa
	dc.w 1,$6000
	dc.w 2,$2000
	dc.w 0,$ffff
	dc.w 0

	dc.w $aa
	dc.w 3,$6000
	dc.w 4,$2000
	dc.w 0,$ffff
	dc.w 0

	dc.w $aa
	dc.w 5,$6000
	dc.w 6,$2000
	dc.w 0,$ffff
	dc.w 0

	dc.w $aa
	dc.w 7,$6000
	dc.w 8,$2000
	dc.w 0,$ffff
	dc.w 0

pshotverts: dc.w 9,9,5,7,7,5,11,5,13,7,13,11,11,13,7,13,5,11

pwrlaser: dc.l 2

	dc.w $8a
	dc.w 0,$8000
	dc.w 1,$c000
	dc.w 2,$ffff
	dc.w 0

	dc.w $8a
	dc.w $3,$8000
	dc.w 4,$c000
	dc.w 5,$ffff
	dc.w 0

pwrlsverts: dc.w 7,9,12,1,12,9,13,9,9,17,9,9


g1: dc.l 2

	dc.w $8c
	dc.w 2,$c000
	dc.w 1,$ffff
	dc.w 0,$4000
	dc.w 0

	dc.w $8f
	dc.w 3,$c000
	dc.w 1,$ffff
	dc.w 0,$4000
	dc.w 0

g1vert: dc.w 1,9,4,9,5,6,5,12

g2: dc.l 2

	dc.w $62
	dc.w 2,$c000
	dc.w 1,$ffff
	dc.w 0,$4000
	dc.w 0

	dc.w $66
	dc.w 3,$c000
	dc.w 1,$ffff
	dc.w 0,$4000
	dc.w 0

 dc.w 1,9,4,9,5,6,5,12


arr: dc.l 3

	dc.w $ef
	dc.w 0,$ffff
	dc.w 1,$8000
	dc.w 2,$ffff
	dc.w 0

	dc.w $ef
	dc.w 3,$ffff
	dc.w 4,$ffff
	dc.w 5,$c000
	dc.w 0

	dc.w $ef
	dc.w 4,$ffff
	dc.w 5,$c000
	dc.w 6,$c000
	dc.w 0

arrvert: dc.w 5,7,9,3,13,7,7,7,11,7,7,13,11,13

dchev: dc.l 4

	dc.w $36
	dc.w 0,$ffff
	dc.w 1,$8000
	dc.w 2,$8000
	dc.w 0

	dc.w $39
	dc.w 0,$ffff
	dc.w 3,$8000
	dc.w 4,$8000
	dc.w 0

	dc.w $36
	dc.w 5,$ffff
	dc.w 6,$8000
	dc.w 7,$8000
	dc.w 0

	dc.w $39
	dc.w 5,$ffff
	dc.w 8,$8000
	dc.w 9,$8000
	dc.w 0

dchevvert: dc.w 9,5,5,9,7,9,11,9,13,9,9,9,5,13,7,13,11,13,13,13

epyr: dc.l 3

	dc.w $fc
	dc.w 1,$6000
	dc.w 2,$6000
	dc.w 0,$ffff
	dc.w 0

	dc.w $fc
	dc.w 2,$6000
	dc.w 3,$6000
	dc.w 0,$ffff
	dc.w 0

	dc.w $fc
	dc.w 3,$6000
	dc.w 1,$6000
	dc.w 0,$ffff
	dc.w 0


epyrvert: dc.w 9,13,9,1,17,17,1,17

xbit: dc.l 2

	dc.w $f4
	dc.w 0,$6000
	dc.w 3,$ffff
	dc.w 2,$c000
	dc.w 0

	dc.w $f4
	dc.w 1,$6000
	dc.w 3,$ffff
	dc.w 2,$c000
	dc.w 0

	dc.w -7,5,-7,13,-1,9,5,9

mirr:  dc.l 6

	dc.w $88
	dc.w 0,$ff
	dc.w 1,$ff
	dc.w 6,$ff
	dc.w 0

	dc.w $87
	dc.w 1,$ff
	dc.w 2,$c0
	dc.w 6,$ff
	dc.w 0

	dc.w $86
	dc.w 2,$c0
	dc.w 3,$80
	dc.w 6,$ff
	dc.w 0

	dc.w $85
	dc.w 3,$80
	dc.w 4,$80
	dc.w 6,$ff
	dc.w 0

	dc.w $86
	dc.w 4,$80
	dc.w 5,$c0
	dc.w 6,$ff
	dc.w 0

	dc.w $87
	dc.w 5,$c0
	dc.w 0,$ff
	dc.w 6,$ff
	dc.w 0

	dc.w 1,5,9,1,15,5,15,13,9,17,1,13,9,9


h2hshot1: dc.l 6

	dc.w $fd
	dc.w 0,$8000
	dc.w 1,$c000
	dc.w 9,$ff00
	dc.w 0

	dc.w $fe
	dc.w 1,$c000
	dc.w 2,$a000
	dc.w 9,$ff00
	dc.w 0

	dc.w $fd
	dc.w 3,$a000
	dc.w 4,$c000
	dc.w 9,$ff00
	dc.w 0

	dc.w $fe
	dc.w 4,$c000
	dc.w 5,$a000
	dc.w 9,$ff00
	dc.w 0

	dc.w $fd
	dc.w 6,$a000
	dc.w 7,$c000
	dc.w 9,$ff00
	dc.w 0

	dc.w $fe
	dc.w 7,$c000
	dc.w 8,$8000
	dc.w 9,$ff00
	dc.w 0

	dc.w 7,1,9,5,11,3,15,13,13,13,13,17,3,11,5,9,1,7,9,9

h2hshot2: dc.l 6

	dc.w $8d
	dc.w 0,$8000
	dc.w 1,$c000
	dc.w 9,$ff00
	dc.w 0

	dc.w $8e
	dc.w 1,$c000
	dc.w 2,$a000
	dc.w 9,$ff00
	dc.w 0

	dc.w $8d
	dc.w 3,$a000
	dc.w 4,$c000
	dc.w 9,$ff00
	dc.w 0

	dc.w $8e
	dc.w 4,$c000
	dc.w 5,$a000
	dc.w 9,$ff00
	dc.w 0

	dc.w $8d
	dc.w 6,$a000
	dc.w 7,$c000
	dc.w 9,$ff00
	dc.w 0

	dc.w $8e
	dc.w 7,$c000
	dc.w 8,$8000
	dc.w 9,$ff00
	dc.w 0

	dc.w 7,1,9,5,11,3,15,13,13,13,13,17,3,11,5,9,1,7,9,9


leaf: dc.l 2

	dc.w $60
	dc.w 0,$ff00
	dc.w 1,$c000
	dc.w 2,$8000
	dc.w 0

	dc.w $40
	dc.w 0,$8000
	dc.w 3,$6000
	dc.w 2,$4000
	dc.w 0

	dc.w 7,9,4,7,-1,9,5,11

blueflipper: dc.l 4		;4 faces in this object, a shaded solid Flipper

	dc.w $04		;Face colour - RED
	dc.w 3,$8000		;vertex ptr and i
	dc.w 1,$c000		;vertex ptr and i
	dc.w 0,$ff00		;vertex ptr and i
	dc.w 0

	dc.w $08		;Face colour - Blueish
	dc.w 4,$8000		;vertex ptr and i
	dc.w 2,$c000		;vertex ptr and i
	dc.w 0,$ff00		;vertex ptr and i
	dc.w 0

	dc.w $08		;Face colour - RED
	dc.w 5,$8000		;vertex ptr and i
	dc.w 1,$c000		;vertex ptr and i
	dc.w 0,$ff00		;vertex ptr and i
	dc.w 0

	dc.w $04		;Face colour - Blueish
	dc.w 6,$8000		;vertex ptr and i
	dc.w 2,$c000		;vertex ptr and i
	dc.w 0,$ff00		;vertex ptr and i
	dc.w 0

 dc.w 9,9,5,9,13,9,1,0,17,0,1,18,17,18

s_flip1: dc.l 4

	dc.w $44
	dc.w 0,$ff00
	dc.w 1,$8000
	dc.w 2,$c000
	dc.w 0

	dc.w $66
	dc.w 5,$ff00
	dc.w 4,$8000
	dc.w 2,$c000
	dc.w 0

	dc.w $44
	dc.w 0,$ff00
	dc.w 1,$8000
	dc.w 3,$c000
	dc.w 0

	dc.w $66
	dc.w 5,$ff00
	dc.w 4,$8000
	dc.w 3,$c000
	dc.w 0

	dc.w 1,9,5,9,9,5,9,13,13,9,17,9

s_flip2: dc.l 6

	dc.w $cc
	dc.w 6,$ff00
	dc.w 1,$4000
	dc.w 4,$4000
	dc.w 0

	dc.w $cc
	dc.w 7,$ff00
	dc.w 1,$4000
	dc.w 4,$4000
	dc.w 0

	dc.w $44
	dc.w 0,$ff00
	dc.w 1,$8000
	dc.w 2,$c000
	dc.w 0

	dc.w $66
	dc.w 5,$ff00
	dc.w 4,$8000
	dc.w 2,$c000
	dc.w 0

	dc.w $44
	dc.w 0,$ff00
	dc.w 1,$8000
	dc.w 3,$c000
	dc.w 0

	dc.w $66
	dc.w 5,$ff00
	dc.w 4,$8000
	dc.w 3,$c000
	dc.w 0

	dc.w 1,9,5,9,9,5,9,13,13,9,17,9,9,3,9,15

hornm1: dc.l 8

	dc.w $88
	dc.w 0,$8000
	dc.w 1,$4000
	dc.w 2,$4000
	dc.w 0

	dc.w $88
	dc.w 0,$8000
	dc.w 2,$4000
	dc.w 3,$8000
	dc.w 0

	dc.w $88
	dc.w 0,$8000
	dc.w 7,$6000
	dc.w 4,$6000
	dc.w 0

	dc.w $88
	dc.w 0,$8000
	dc.w 3,$8000
	dc.w 4,$6000
	dc.w 0

	dc.w $88
	dc.w 7,$6000
	dc.w 6,$4000
	dc.w 4,$6000
	dc.w 0

	dc.w $88
	dc.w 6,$4000
	dc.w 5,$4000
	dc.w 4,$6000
	dc.w 0

	dc.w $f0
	dc.w 8,$c000
	dc.w 9,$f000
	dc.w 10,$8000
	dc.w 0

	dc.w $f0
	dc.w 11,$c000
	dc.w 12,$f000
	dc.w 13,$8000
	dc.w 0

	dc.w 3,7,7,5,11,5,15,7,15,11,11,13,7,13,3,11,5,7,7,7,7,9,13,7,11,7,11,9


hornm2: dc.l 4

	dc.w $bb
	dc.w 0,$f000
	dc.w 1,$f000
	dc.w 2,$c000
	dc.w 0

	dc.w $bc
	dc.w 1,$f000
	dc.w 2,$c000
	dc.w 3,$a000
	dc.w 0

	dc.w $cc
	dc.w 2,$c000
	dc.w 3,$a000
	dc.w 4,$a000
	dc.w 0

	dc.w $66
	dc.w 5,$a000
	dc.w 6,$c000
	dc.w 7,$ffff
	dc.w 0

	dc.w -7,-11,-7,1,-3,-3,-3,5,5,1,17,13,13,13,13,25

hornm3: dc.l 4

	dc.w $bb
	dc.w 0,$f000
	dc.w 1,$f000
	dc.w 2,$c000
	dc.w 0

	dc.w $bc
	dc.w 1,$f000
	dc.w 2,$c000
	dc.w 3,$a000
	dc.w 0

	dc.w $cc
	dc.w 2,$c000
	dc.w 3,$a000
	dc.w 4,$a000
	dc.w 0

	dc.w $66
	dc.w 5,$a000
	dc.w 6,$c000
	dc.w 7,$ffff
	dc.w 0

	dc.w 25,-11,25,1,21,-3,21,5,13,1,1,13,5,13,5,25

adroid: dc.l 8

	dc.w $55
	dc.w 0,$ff00
	dc.w 1,$c000
	dc.w 4,$c000
	dc.w 0

	dc.w $5b
	dc.w 1,$c000
	dc.w 2,$8000
	dc.w 5,$8000
	dc.w 0

	dc.w $bb
	dc.w 2,$8000
	dc.w 3,$c000
	dc.w 6,$4000
	dc.w 0

	dc.w $b5
	dc.w 3,$c000
	dc.w 0,$ff00
	dc.w 7,$8000
	dc.w 0

	dc.w $56
	dc.w 4,$c000
	dc.w 5,$8000
	dc.w 1,$c000
	dc.w 0

	dc.w $5c
	dc.w 5,$8000
	dc.w 6,$4000
	dc.w 2,$8000
	dc.w 0

	dc.w $bc
	dc.w 6,$4000
	dc.w 7,$8000
	dc.w 3,$c000
	dc.w 0

	dc.w $b6
	dc.w 7,$8000
	dc.w 4,$c000
	dc.w 0,$f000
	dc.w 0

	dc.w 1,1,17,1,17,17,1,17,5,5,13,5,13,13,5,13

sclaw4: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 6,4,1,9,3,9,9,12,9,15,15,9,17,9,12,4

sclaw5: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 4,5,2,13,4,11,11,12,11,15,15,8,17,8,12,4

sclaw6: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 3,8,4,14,6,13,12,13,13,16,15,7,17,6,11,3

sclaw7: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 4,11,10,16,10,14,14,13,16,15,15,6,17,4,10,3

sclaw0: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 8,3,1,4,3,6,4,13,1,15,8,14,8,16,14,11

sclaw1: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 7,3,1,6,3,7,6,13,4,16,12,13,14,14,15,8

sclaw2: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 6,4,1,8,3,8,7,12,7,15,14,11,16,12,14,5

sclaw3: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 6,4,1,9,3,9,8,12,8,15,15,10,17,10,13,4

gsclaw4: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 6,4,1,9,3,9,9,12,9,15,15,9,17,9,12,4

gsclaw5: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 4,5,2,13,4,11,11,12,11,15,15,8,17,8,12,4

gsclaw6: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 3,8,4,14,6,13,12,13,13,16,15,7,17,6,11,3

gsclaw7: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 4,11,10,16,10,14,14,13,16,15,15,6,17,4,10,3

gsclaw0: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 8,3,1,4,3,6,4,13,1,15,8,14,8,16,14,11

gsclaw1: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 7,3,1,6,3,7,6,13,4,16,12,13,14,14,15,8

gsclaw2: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 6,4,1,8,3,8,7,12,7,15,14,11,16,12,14,5

gsclaw3: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 6,4,1,9,3,9,8,12,8,15,15,10,17,10,13,4




