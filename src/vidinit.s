; ***********************************************************************************
; Welcome to the Motorola 68K Assembler source code for 'Tempest 2000' by Jeff Minter.
;
;                                                                                                                 
;                =============                         =============                                              
;               =================                   =================                                             
;             ====  ====     ======               ======    =====  ===                                            
;            ===      =====   ========         ========   =====     ====                                          
;           ===         =====  === =============== ===  =====         ===                                         
;          ===            =====  === ==      === ===  =====            ===                                        
;        ====               ===== === ==     == === =====               ===                                       
;       ===                   ===========   ==========                    ===                                     
;       ===========             =====================             ===========                                     
;       ====================  ===     =========    ===   ====================                                     
;       ==         =============                     =============         ==                                     
;       ==                  ===                      ====                  ==                                     
;       ==                   ==                      ==                    ==                                     
;       ==            ==========                     ==========            ==                                     
;       ==   ====================      =======      ====================   ==                                     
;       ==============         ======================          ==============                                     
;       =====                  ==========   ==========                  =====                                     
;        ===                 ==== === ==     == === ====                 ===                                      
;         ===              ====  === ===     === ===  ====             ====                                       
;           ===          ====   === ============= ===   ====          ===                                         
;            ===       ====   =========================   ====       ===                                          
;             ===   =====    =======             =======    ====    ===                                           
;              ========     =====                  ======     =======                                             
;                ==============                       ==============                                              
;                 ==========                             ==========                                               
;                                                                                                                 
; Fig 1. Ascii rendering of the 'dumb-bell' web used in level 7 of Tempest 2000.
;                                                                                                                 
; This source code was originally 'leaked' by 'JaySmith2000' in August 2008,
; who sold it on CD as part of a release entitled the 'Jaguar Sector II Source Code
; Collection':
;  https://web.archive.org/web/20131117222232/http://www.jaysmith2000.com/Jagpriceguide.htm
;
; This is a cleaned-up and commented version of the source code file 'vidinit.s'.
;
; No code has been changed, so this source file can be used to create a build
; of Tempest 2000 that is byte-for-byte identical to the original 1994 release.
;
; All original variable and routine names are preserved.
; The changes include:
;   - Fixed up indentation.
;   - Added comments and routine headers.
;
; The home of this file and the rest of the Tempest 2000 source code is:
;    https://github.com/mwenge/tempest2k 
;
; vidinit.s contains routines to set up video, e.g. NTSC/PAL.
; ***********************************************************************************
.include        'jaguar.inc'

        .globl  VideoIni
        .globl  n_vde
        .globl  n_vdb
        .globl  pal

; The size of the horizontal and vertical active areas
; are based on a given center position and then built
; as offsets of half the size off of these.

; In the horizontal direction this needs to take into
; account the variable resolution that is possible.

; THESE ARE THE NTSC DEFINITIONS
ntsc_width      equ     1409
ntsc_hmid       equ     823

ntsc_height     equ     241
ntsc_vmid       equ     266

; THESE ARE THE PAL DEFINITIONS
pal_width       equ     1381
pal_hmid        equ     843

pal_height      equ     287
pal_vmid        equ     322


; *******************************************************************
; VideoIni
; Check if NTSC or PAL
; For now assume NTSC
; *******************************************************************
VideoIni:

        movem.l d0-d6,-(sp)
        clr pal

        move.w  BASE+$14002,d0          ;CONFIG
        and.w   #$10,d0
        beq     ispal

        move.w  #ntsc_hmid,d2
        move.w  #ntsc_width,d0

        move.w  #ntsc_vmid,d6
        move.w  #ntsc_height,d4

        bra     doit

ispal:
        move.w  #pal_hmid,d2
        move.w  #pal_width,d0

        move.w  #pal_vmid,d6
        move.w  #pal_height,d4
        move #1,pal

doit:
        move.w  d0,width
        move.w  d4,height

        move.w  d0,d1
        asr     #1,d1                   ; Max width/2

        sub.w   d1,d2                   ; middle-width/2
        add.w   #4,d2                   ; (middle-width/2)+4
        
        sub.w   #1,d1                   ; Width/2-1
        or.w    #$400,d1                ; (Width/2-1)|$400

        move.w  d1,a_hde
        move.w  d1,HDE

        move.w  d2,a_hdb
        move.w  d2,HDB1
        move.w  d2,HDB2

        move.w  d6,d5
        sub.w   d4,d5                   ; already in half lines
        move.w  d5,n_vdb

        add.w   d4,d6
        move.w  d6,n_vde

;       move.w  n_vdb,VDB
        move.w  #$FFFF,VDE

; Also lets set up some default colors

        move.w  #$0,BG
        move.l  #$0,BORD1

        movem.l (sp)+,d0-d6
        rts

.bss

height:
        ds.w    1
n_vdb:
        ds.w    1
n_vde:
        ds.w    1
pal:
        ds.w    1


width:
        ds.w    1
a_hdb:
        ds.w    1
a_hde:
        ds.w    1



; vim:ft=asm68k ts=2
