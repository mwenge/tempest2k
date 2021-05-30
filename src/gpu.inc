;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Header File: GPU.INC
;              Jaguar GPU Equates
;
; NOTICE: This file has been incorporated into JAGUAR.INC. This file
;         is for compatibility reasons only.
;
	
	.include        "jaguar.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; WARNING!!! The following EQU's exist here for compatibility only.
;;; Do not use them. There are more EQUs with better names in JAGUAR.INC
;;; These EQUs - Including this whole include file will go away in the next
;;; release
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		IF      COMPAT

G_ZERO          EQU     $00000001       ; ALU zero flag
G_CARRY         EQU     $00000002       ; ALU carry flag
G_NEGATIVE      EQU     $00000004       ; ALU negative flag
G_IMASK         EQU     $00000008       ; Interrupt mask
G_INTEN0        EQU     $00000010       ; Interrupt enable bits
G_INTEN1        EQU     $00000020       ; Interrupt enable bits
G_INTEN2        EQU     $00000040       ; Interrupt enable bits
G_INTEN3        EQU     $00000080       ; Interrupt enable bits
G_INTEN4        EQU     $00000100       ; Interrupt enable bits
G_INTCLR0       EQU     $00000200       ; Interrupt disable bits
G_INTCLR1       EQU     $00000400       ; Interrupt disable bits
G_INTCLR2       EQU     $00000800       ; Interrupt disable bits
G_INTCLR3       EQU     $00001000       ; Interrupt disable bits
G_INTCLR4       EQU     $00002000       ; Interrupt disable bits
G_REGPAGE       EQU     $00004000       ; Register Bank
G_DMAEN         EQU     $00008000       ; GPU Load and Store at DMA priority

GPUM3x1         EQU     $00000003       ; [ 3x1] matrix
GPUM4x1         EQU     $00000004       ; [ 4x1] matrix
GPUM5x1         EQU     $00000005       ; [ 5x1] matrix
GPUM6x1         EQU     $00000006       ; [ 6x1] matrix
GPUM7x1         EQU     $00000007       ; [ 7x1] matrix
GPUM8x1         EQU     $00000008       ; [ 8x1] matrix
GPUM9x1         EQU     $00000009       ; [ 9x1] matrix
GPUM10x1        EQU     $0000000A       ; [10x1] matrix
GPUM11x1        EQU     $0000000B       ; [11x1] matrix
GPUM12x1        EQU     $0000000C       ; [12x1] matrix
GPUM13x1        EQU     $0000000D       ; [13x1] matrix
GPUM14x1        EQU     $0000000E       ; [14x1] matrix
GPUM15x1        EQU     $0000000F       ; [15x1] matrix

GPUMROW         EQU     $00000000       ; Row Major matrix
GPUMCOL         EQU     $00000010       ; Column Major matrix

GPU_CPUINT      EQU     $00000002       ; Allow GPU to interrupt CPU
GPUINT0         EQU     $00000004       ; generate a GPU type 0 interrupt
INT_LAT0        EQU     $00000040       ; Interrupt latch 0
INT_LAT1        EQU     $00000080       ; Interrupt latch 1
INT_LAT2        EQU     $00000100       ; Interrupt latch 2
INT_LAT3        EQU     $00000200       ; Interrupt latch 3
INT_LAT4        EQU     $00000400       ; Interrupt latch 4

		ENDIF
