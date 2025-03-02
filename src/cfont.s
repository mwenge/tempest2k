; **************************************************************************************
; Welcome to the Motorola 68K Assembler source code for 'Tempest 2000' by Jeff Minter.
;
;                 ===============                   ===============                                               
;              =====================             =====================                                            
;            =====   =====      ======         ======      ====    =====                                          
;         ======       =====     == =====   ===== ==     ====        =====                                        
;       =====            =====    ==  =========  ==    =====            =====                                     
;       =======            =====  ===   ====    ==   =====            =======                                     
;       ============         =====  ==   ==    ==  =====         ============                                     
;        ==    ==========      ========= ==  =========      ==========    ==                                      
;        ===        ========== ======================= ==========        ==                                       
;         ===           =========      ======      =========            ===                                       
;          ==                ===                     ==                 ==                                        
;          ===                ===                   ==                 ===                                        
;           ==            ========                 ========           ===                                         
;            =======================             =======================                                          
;            =============        =====       =====        =============                                          
;             =====             =====================            =====                                            
;                =====       =====    ========    ======       =====                                              
;                  =====   =====       ==   ==       =====  ======                                                
;                     =======         ==    ===        ========                                                   
;                       =====         ==     ==         =====                                                     
;                          =====     ==      ===     =====                                                        
;                            =====   ==       ==   =====                                                          
;                              =======        =======                                                             
;                                 =================                                                               
;                                    ===========                                                                  
;                                                                                                                                                   
;                   Fig 1. Ascii rendering of the 'kiss of death' web.
;                                                                                                                 
; This source code was originally 'leaked' by 'JaySmith2000' in August 2008,
; who sold it on CD as part of a release entitled the 'Jaguar Sector II Source Code
; Collection':
;     https://web.archive.org/web/20131117222232/http://www.jaysmith2000.com/Jagpriceguide.htm
;
; This is a cleaned-up and commented version of the source code file 'afont.s'.
;
; No code has been changed, so this source file can be used to create a build
; of Tempest 2000 that is byte-for-byte identical to the original 1994 release.
;
; All original variable and routine names are preserved. The changes include:
;   - Fixed up indentation.
;   - Added comments and routine headers.
;
; The home of this file and the rest of the Tempest 2000 source code is:
;     https://github.com/mwenge/tempest2k 
;
; cfont.s consists of addresses into the data in pic. pic contains a spritesheet
; of characters for the font.
; **************************************************************************************
*
*
* Page 1 font, 8x8, by Joby

cfont:
  ; beasty3-trunc.cry
  dc.l pic
	dc.l $00080008

 	dc.l $b50137	;Space
	dc.l $9e0026	;!
	dc.l $b50137	;"
	dc.l $b50137	;#
	dc.l $b50137	;$
	dc.l $b50137	;%
	dc.l $b50137	;&
	dc.l $9e0047	;'
	dc.l $9e0052	;(
	dc.l $9e005d	;)
	dc.l $b50137	;*
	dc.l $b50137	;+
	dc.l $9e003c	;,
	dc.l $9e0068	;-
	dc.l $9e001b	;.
	dc.l $b50137	;/
	dc.l $a9001b	;0
	dc.l $a90026	;1
	dc.l $a90031	;2
	dc.l $a9003c	;3
	dc.l $a90047	;4
	dc.l $a90052	;5
	dc.l $a9005d	;6
	dc.l $a90068	;7
	dc.l $a90073	;8
	dc.l $a9007e	;9
	dc.l $9e0031	;:
	dc.l $9b0031	;;
	dc.l $b50137	;<
	dc.l $b50137	;=
	dc.l $b50137	;>
	dc.l $b50137	;?
	dc.l $b50137	;@
	dc.l $b5001b	;A
	dc.l $b50026	;B
	dc.l $b50031	;C
	dc.l $b5003c	;D
	dc.l $b50047	;E
	dc.l $b50052	;F
	dc.l $b5005d	;G
	dc.l $b50068	;H
	dc.l $b50073	;I
	dc.l $b5007e	;J
	dc.l $b50089	;K
	dc.l $b50094	;L
	dc.l $b5009f	;M
	dc.l $b500aa	;N
	dc.l $b500b5	;O
	dc.l $b500c0	;P
	dc.l $b500cb	;Q
	dc.l $b500d6	;R
	dc.l $b500e1	;S
	dc.l $b500ec	;T
	dc.l $b500f7	;U
	dc.l $b50102	;V
	dc.l $b5010d	;W
	dc.l $b50118	;X
	dc.l $b50123	;Y
	dc.l $b5012e	;Z
	dc.l $b50137	;[
	dc.l $b50137	;\
	dc.l $b50137	;]
	dc.l $b50137	;^
	dc.l $b50137	;_
	dc.l $b50137	;`
	dc.l $bf001b	;A
	dc.l $bf0026	;B
	dc.l $bf0031	;C
	dc.l $bf003c	;D
	dc.l $bf0047	;E
	dc.l $bf0052	;F
	dc.l $bf005d	;G
	dc.l $bf0068	;H
	dc.l $bf0073	;I
	dc.l $bf007e	;J
	dc.l $bf0089	;K
	dc.l $bf0094	;L
	dc.l $bf009f	;M
	dc.l $bf00aa	;N
	dc.l $bf00b5	;O
	dc.l $bf00c0	;P
	dc.l $bf00cb	;Q
	dc.l $bf00d6	;R
	dc.l $bf00e1	;S
	dc.l $bf00ec	;T
	dc.l $bf00f7	;U
	dc.l $bf0102	;V
	dc.l $bf010d	;W
	dc.l $bf0118	;X
	dc.l $bf0123	;Y
	dc.l $bf012e	;Z
	dc.l $b50137	;{
	dc.l $b50137	;|
	dc.l $b50137	;}
	dc.l $b50137	;~
	dc.l $b50137	;DEL
; vim:ft=asm68k ts=2
