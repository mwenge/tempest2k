
	include "jaguar.inc"
	include "blit.inc"
	include "gpu.inc"

;
;	PUBLIC SYMBOLS
;

	.globl	gpuload
	.globl	gpurun
	.globl	gpuwait
	.globl	fastvector
	.globl 	xvector
	.globl 	demons
	.globl	parrot
	.globl	xparrot
	.globl	texter
	.globl  bovine
	.globl  equine
	.globl  equine2


;*======================================================================*
;* gpuload()	- load a GPU program into GPU RAM
;*
;*	input:
;*		a0	- 68000 address of GPU program
;*
;*	preserved:
;*		d0-d1
;*		a0-a1
;*======================================================================*
gpuload:
	
	movem.l	d0-d2/a0-a1,-(sp)		; save GPU address for restore


	move.l lastloaded,d0
	move.l a0,d1
	cmp.l d0,d1
	beq qrts				;no need to load if already done
	move.l d1,lastloaded


; 	moveq #8,d0
;	swap d0
	clr.l d0
	move.l d0,G_CTRL	;make sure the GPU is stopped

	; This code will load a gpu program into the Blitter at the address
	; specified in the header 

	move.l	#PITCH1|PIXEL16|WID256|XADDPHR,d0
	move.l	d0,A1_FLAGS
	move.l	d0,A2_FLAGS
	
	; Point A1BASE to the destination
	; Read destination from header of file
	; Phrase align and find remainder

	move.l	(a0)+,d0
	move.l	d0,d1
	and.l	#$fffffff8,d0
	sub.l	d0,d1
	move.l	d0,A1_BASE

	; Set the pixel pointer to the offset in d1

	asr.l	#1,d1		; Convert to pixels
	move.l	d1,A1_PIXEL

	; Find size of data to load

	move.l	(a0)+,d0
	asr.l	#1,d0		; Convert to words
	or.l	#$10000,d0	; Set 1 outer loop
	move.l	d0,B_COUNT

	; Set up Counters register to number of words

	; Point A2BASE to the source
	; a0 now points to the data
	; Phrase align and find remainder

	move.l	a0,d0
	move.l	d0,d2
	and.l	#$fffffff8,d0
	sub.l	d0,d2
	move.l	d0,A2_BASE

	; Set the pixel pointer to the offset in d1

	asr.l	#1,d2		; Convert to pixels
	move.l	d2,A2_PIXEL

	; Now Turn IT ON !!!!!!!!!!!!!

	; DESTINATION = SOURCE
	; NO OUTER LOOP

;	cmp.l	d1,d2
;	bpl.s	.aligned
	or.l	d1,d2
	beq.s	.aligned

	move.l	#SRCEN|SRCENX|LFU_AN|LFU_A,d0
	bra.s	.blit_go
.aligned:
	move.l	#SRCEN|LFU_AN|LFU_A,d0
.blit_go:
	move.l	d0,B_CMD
;
;	NOTE: No Wait for BLTTER Idle - I have yet to be overrun but WARNING
;

wblit:	move.l B_CMD,d0
	btst #0,d0
	beq wblit

qrts:	movem.l	(sp)+,d0-d2/a0-a1
	rts

;*======================================================================*
;* gpurun()	- tell the GPU to begin execution
;*
;*	input:
;*		a0	- 68000 address of GPU program
;*
;*	preserved:
;*		d0-d1
;*		a0
;*======================================================================*
gpurun:	bsr gpuload			;load if not already loaded

	movem.l	d0-d1/a0,-(sp)		; save GPU address for restore

	move.l	(a0)+,G_PC		; load GPU PC

	move.l	#$11,G_CTRL		; Turn on the GPU

	movem.l	(sp)+,a0/d0-d1		; restore GPU address
	rts

;*======================================================================*
;* gpuwait()	- wait for the GPU to finish executing
;*
;*	input:
;*		None
;*
;*	preserved:
;*		d0
;*		a0
;*======================================================================*
gpuwait: movem.l	a0/d0,-(sp)

	lea	G_CTRL,a0
.gpuwt:				; wait for GPU to finish
	move.l	(a0),d0
	btst	#0,d0
	bne .gpuwt

	movem.l	(sp)+,a0/d0
	rts



;
;	CONSTANT DATA (GPU PROGRAMS)
;
fastvector:
	.include	"llama.dat"
xvector:
	.include 	"goat.dat"
demons:
	.include	"antelope.dat"
parrot:
	.include	"camel.dat"
xparrot:
	.include	"xcamel.dat"
texter:
	.include 	"stoat.dat"
bovine:
	.include	"ox.dat"
equine:
	.include 	"horse.dat"
equine2:
	.include 	"donky.dat"

.data

lastloaded: dc.l 0

;*======================================================================*
;*                                 EOF                                  *
;*======================================================================*

