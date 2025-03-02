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
; afont.s consists of addresses into the data in pic2. pic2 contains a spritesheet
; of characters for the font.
; **************************************************************************************
*
*
* Page 2 font, by Joby

afont:	
  dc.l pic2
	dc.l $0012000f

 	dc.l $b6011e	;Space
	dc.l $b600d2	;!
	dc.l $a40001	;"
	dc.l $a40001	;#
	dc.l $a40001	;$
	dc.l $a40001	;%
	dc.l $a40001	;&
	dc.l $a40001	;'
	dc.l $9100a5	;(
	dc.l $9100ba	;)
	dc.l $a40001	;*
	dc.l $a40001	;+
	dc.l $b600f8	;,
	dc.l $b6010b	;-
	dc.l $b600c2	;.
	dc.l $a40001	;/
	dc.l $910000	;0
	dc.l $910010	;1
	dc.l $910020	;2
	dc.l $910030	;3
	dc.l $910040	;4
	dc.l $910050	;5
	dc.l $910060	;6
	dc.l $910070	;7
	dc.l $910080	;8
	dc.l $910090	;9
	dc.l $b600e5	;:
	dc.l $a40001	;;
	dc.l $a40001	;<
	dc.l $a40001	;=
	dc.l $a40001	;>
	dc.l $a40001	;?
	dc.l $a40001	;@
	dc.l $a40001	;A
	dc.l $a40014	;B
	dc.l $a40027	;C
	dc.l $a4003a	;D
	dc.l $a4004d	;E
	dc.l $a40060	;F
	dc.l $a40073	;G
	dc.l $a40086	;H
	dc.l $a40099	;I
	dc.l $a400ac	;J
	dc.l $a400bf	;K
	dc.l $a400d2	;L
	dc.l $a400e5	;M
	dc.l $a400f8	;N
	dc.l $a4010b	;O
	dc.l $a4011e	;P
	dc.l $b60001	;Q
	dc.l $b60014	;R
	dc.l $b60027	;S
	dc.l $b6003a	;T
	dc.l $b6004d	;U
	dc.l $b60060	;V
	dc.l $b60073	;W
	dc.l $b60086	;X
	dc.l $b60099	;Y
	dc.l $b600ac	;Z
	dc.l $a40001	;[
	dc.l $a40001	;\
	dc.l $a40001	;]
	dc.l $a40001	;^
	dc.l $a40001	;_
	dc.l $a40001	;`
	dc.l $a40001	;a
	dc.l $a40014	;b
	dc.l $a40027	;c
	dc.l $a4003a	;d
	dc.l $a4004d	;e
	dc.l $a40060	;f
	dc.l $a40073	;g
	dc.l $a40086	;h
	dc.l $a40099	;i
	dc.l $a400ac	;j
	dc.l $a400bf	;k
	dc.l $a400d2	;l
	dc.l $a400e5	;m
	dc.l $a400f8	;n
	dc.l $a4010b	;o
	dc.l $a4011e	;p
	dc.l $b60001	;q
	dc.l $b60014	;r
	dc.l $b60027	;s
	dc.l $b6003a	;t
	dc.l $b6004d	;u
	dc.l $b60060	;v
	dc.l $b60073	;w
	dc.l $b60086	;x
	dc.l $b60099	;y
	dc.l $b600ac	;z
	dc.l $a40001	;{
	dc.l $a40001	;|
	dc.l $a40001	;}
	dc.l $a40001	;~
	dc.l $a40001	;DEL
; vim:ft=asm68k ts=2
