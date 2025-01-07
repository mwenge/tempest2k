; *******************************************************************
; yak.s
; This is a cleaned-up and commented version of the main source code
; file for Tempest 2000.
; *******************************************************************
        .include  'jaguar.inc'
        .extern  VideoIni

;  .extern GPUSTART  ;From the ALLSYNT object code
;  .extern GPUEND
;  .extern DSPORG



;  .globl ENABLETIMER
;  .globl DISABLETIMER

        INIT_SOUND    EQU  $4040  ;jump table for the SFX/Tunes module
        NT_VBL        EQU   $4046
        PT_MOD_INIT   EQU  $404c
        START_MOD     EQU  $4052
        STOP_MOD      EQU  $4058
        PLAYFX2       EQU  $405e
        CHANGE_VOLUME EQU  $4064
        SET_VOLUME    EQU  $406a
        NOFADE        EQU  $4070
        FADEUP        EQU  $4076
        FADEDOWN      EQU  $407c
        ENABLE_FX     EQU  $4082
        DISABLE_FX    EQU  $4088
        CHANGEFX      EQU  $409a  ;new in syn6
        HALT_DSP      EQU  $408e
        RESUME_DSP    EQU  $4094
        intmask       EQU  $40a0

        .extern pal    ;set =1 by VIDINIT if pal is detected

        .extern  gpuload    ;from my GPU stuff
        .extern  gpurun
        .extern  gpuwait
        .extern  fastvector
        .extern xvector
        .extern demons
        .extern parrot
        .extern xparrot
        .extern  texter
        .extern bovine
        .extern equine
        .extern equine2

        .extern n_vde
        .extern n_vdb

        xcent  EQU (G_RAM+$efc)
        ycent  EQU (G_RAM+$ef8)

        screensize   EQU $34800    ;was $2d000 for old 240-pixel-high screens
        TIMERINTBIT  equ 3
        samtab       EQU $9ac800
        modbase      EQU $8d6800
        tune1        EQU $8e6900
        allbutts     EQU $22002000
        allkeys      EQU $000f00ff
        acheat       EQU $000a000a
        a147         EQU $200e0000
        six          EQU $00000004
        abutton      EQU $20000000
        bbutton      EQU $02000000
        cbutton      EQU $00002000
        pausebutton  EQU $10000000
        optionbutton EQU $00000200
        view1        EQU $000e0000
        view2        EQU $000000e0
        view3        EQU $0000000e
        allpad       EQU $00f00000
        somepad      EQU $00300000
        bigreset     EQU $00010001
        page2        EQU $100000  ;position of ram page 2
        videomode    equ $6c1
        width        EQU 384
        height       EQU 240
        centx        EQU width/2
        centy        EQU height/2
        ; beasty3-trunc.cry
        pic          EQU $820000
        ; beasty4.cry
        pic2         EQU pic+$1f400
        ; beasty5.cry
        pic3         EQU pic2+$1f400
        ; beasty6.cry
        pic4         EQU pic3+$25800
        ; beasty7.cry
        pic5         EQU pic4+(640*128)
        ; beasty8.cry
        pic6         EQU pic5+(640*200)
        vpang        equ G_RAM+$f00  ; viewpoint angles

        digits       EQU pic2+92800  ;start address of zero digit
        p_sines      equ $30000
        field1       equ $31000  ;space for the starfield
        gpu_sem      EQU $30100
        gpu_mode     EQU G_RAM+$ffc
        gpu_screen   EQU G_RAM+$ff8
        scaler       EQU G_RAM+$fd4  ; Scale of XY 2-D point
        screen1      equ page2  ;a 16bit screen 384x200 at start of DRAM bank 1
        screen2      equ screen1+screensize  ;same again
        screen3      equ $50000
        screen4      equ screen1+$16800  ;a 256-colour screensworth
        rmwcursor    equ screen2+screensize  ;to make a RMW object, size is 48x30 16-bit pixels,
        scoreimj     equ rmwcursor+$b40
        livesimj     equ scoreimj+4608
        screen5      equ livesimj+$100
        xsample      equ screen5+screensize
        z_max        EQU (G_RAM+$fd8)  ; Distance along Z-axis at which depth cue intensity is zero
        z_top        EQU (G_RAM+$fdc)  ; Intensity value at z=1
        webz         EQU 110
        in_buf       equ G_RAM+$f60
        INTPOS       equ (260*2)+11
        TOP          equ 60    ;top of screen in halflines  (60=NTSC)
        SIDE         equ -8
        source_flags EQU (G_RAM+$ff4)
        dest_flags   EQU (G_RAM+$ff0)  ; Blitter flags 4 source+dest
        backg        EQU (G_RAM+$fec)
        _sysflags    EQU (G_RAM+$fd0)  ;Thick vector flags etc


.text
; *******************************************************************
; Initialisation starts here.
; *******************************************************************
        move.l #$70007,G_END  ;NEW mode
        move.l #$70007,D_END  ;NEW mode
        move #$100,$f14000  ;audio on
        move #1,INT1
        move.l #dumint,$100
        move.l #stack,a7
        jsr VideoIni
        jsr InitLists
        move.l ddlist,d0    ;put a list on the OLP
        move.w #0,ODP
        swap d0
        move.l d0,OLP

        lea romstart,a0    ; clear RAM; initialise RAM-based variables
        lea copstart,a1
        move #(romend-romstart),d0
        lsr #2,d0      ;moving longs
crom:
        move.l (a0)+,(a1)+    ;copy var defaults to ram
        dbra d0,crom
        lea zerstart,a0
        move.l #(zerend-zerstart),d0
        lsr.l #2,d0
cram:
        clr.l (a0)+
        sub.l #1,d0
        bpl cram      ;zero out RAM


        move #32,afree
        move.b #9,intmask
        move #0,auto
        move #3,joby
        move #15,t2k_max
        move #15,trad_max
        jsr INIT_SOUND    ;NEW Synth module
        clr.l d0
        move #1,d1
        jsr SET_VOLUME
        clr.l d0
        move #0,d1
        jsr SET_VOLUME
        jsr InitBeasties  ;list of active windows
        move #-1,db_on    ;double buffering flag - not on
        clr modnum    ;set no tune pending
        clr lastmod  
        clr screen_ready
        move.l #-1,gpu_sem  ;GPU idle semaphore
        move.l #$03e70213,pit0
        move.l #rrts,routine
        move.l #rrts,fx

        ; Set up interupts
        jsr scint    ;set intmask according to controller prefs
        move.l #Frame,$100
        move.w n_vde,d0
        or #1,d0
        move d0,VI
        move pit0,PIT0
        clr d0
        move.b intmask,d0
        move.w  d0,INT1    ;enable frame int
        move.w  sr,d0
        and.w  #$f8ff,d0
        move.w  d0,sr    ;interrupts on

        jsr eepromload    ;get eeprom settings
        jsr scint
        bsr setfires    ;set up fire buttons that were saved
        jsr xkeys
        lea hscom1,a0    ;and expand both score tables
        jsr xscoretab
        lea sines,a0
        lea p_sines,a1    ;make a positive-only sine table
        move #255,d0    ;for use by the gpu
mpstab:
        move.b (a0)+,d1
        ext d1
        add #$80,d1
        move.b d1,(a1)+
        dbra d0,mpstab

        tst.b vols
        bne mu_on
        move #1,modstop
        move.b #$80,oldvol
mu_on:
        jsr initobjects
        jsr initprior    ;priority list for sorting poly objects
        jsr zscore
        jsr setlives
        jsr iv      ;initialise vector ram pointers 

        clr CLUT
        clr CLUT+8
        move #$ffff,CLUT+10

        move #$88ff,CLUT+2

        move.w  #videomode,VMODE    ; Turn on the display

        move.l #screen1,a0
        jsr clrscreen
        move.l #screen2,a0
        jsr clrscreen
        move.l #screen3,a0
        jsr clrscreen

        jsr iv
        bsr make_claws
        bsr make_webs
        bsr make_bits    ;construct v-objects
        move #1,sf_on
        move #1,wave_speed

        move.l #screen1,gscreen
        move.l #0,gpu_sem
        move.l #it,_demo
        clr cweb
        clr cwave
        move.l #$ff00,z_top    ;top intensity (z=1) **16 bits**
        move.l #1300,z_max

; *******************************************************************
; rreset
; *******************************************************************
rreset:
        tst wson
        beq nnnn
        jsr zzoomoff
nnnn:
        jsr flushfx
;  jsr DISABLE_FX    ;any SFX to off
;  jsr ENABLE_FX  
        tst z
        beq nrstlvl
        clr cwave
        clr cweb    ;Key players, always reset the level
        move #15,t2k_max
        move #15,t2k_high
        move #15,trad_max
        move #15,trad_high
nrstlvl:
        move.b vols+1,d0
        and.l #$ff,d0
        move #1,d1
        jsr SET_VOLUME    ;set current FX volume
        jsr spall
        move.l #$f80000,delta_i
        move.l #screen1,a0
        jsr clrscreen
        move.l #screen2,a0
        jsr clrscreen    ;clear off gunj
        move.l #screen3,a0
        jsr clrscreen
        move #1,modnum    ;request theme tune
brdb:
        move.l pad_now,d0
        or.l pad_now+4,d0
        move.l d0,d1
        and.l #bigreset|optionbutton,d1
        cmp.l #bigreset|optionbutton,d1
        beq clearee
        and.l #bigreset,d0
        bne brdb    ;debounce any 'big' reset  
        clr tblock
        clr z
        clr h2h
        move.l #$2000,roconsens
        move.l #$2000,roconsens+4
        move #1,sf_on
        move #-1,holiday
        clr drawhalt
        clr l_soltarg
        clr l_solidweb
        clr mfudj
        clr solidweb
        clr conswap
        clr noxtra
        clr warped
        clr _pauen
        clr pauen
        clr pawsed
        clr.l s_routine
        clr.l msg
        clr inf_zap
        clr beastly
        clr gb
        move keyplay,d0
        bmi dntrstl
        clr cwave
        clr cweb    ;Key players, always reset the level
        move #15,t2k_max
        move #15,t2k_high
        move #15,trad_max
        move #15,trad_high  

        ; Manage title screen, attract mode, version screen.
dntrstl:move #-1,keyplay
        bsr lsel    ;do attract/demo/lselect
        tst z
        bne rreset

        ; Start a game
        move.l #skore,score
        move.l score,a0
        clr.l (a0)+
        clr.l (a0)+    ;reset score
        move #3,lives
        move #3,lastlives
        move #2,warpy
        clr bolev1
        clr bolev2
        clr bolev3

; *******************************************************************
; dloop
; *******************************************************************
dloop:
        clr.l vp_x
        clr.l vp_y
        clr.l vp_z    ;Camera viewpoint as 16:16 fracs
ego:
        move.l _demo,a0
        move #1,pauen
        clr finished
        jsr (a0)

        clr _pauen
        tst gb
        bne dobeastly
        tst auto
        bne zreset
        tst z
        bne zreset
        tst h2h
        bne h2hover
        tst finished
        bne treset
        bra dloop

; *******************************************************************
; Set up the NTSC/PAL options.
; *******************************************************************
spall:
        btst.b #6,sysflags
        beq slopt
        move.l #o2s3,option2+16
slopt:
        clr palside
        clr paltop
        bclr.b #5,sysflags
        tst pal
        beq notpal1
        move #6,palside
        move #10,paltop
        move #40,palfix1
        move #20,palfix2
        move.l #$140000,palfix3
        bset.b #5,sysflags  ;gpu can use bit 5 as a pal flag
notpal1: rts

; *******************************************************************
; h2hover
; Head to Head game is over
; *******************************************************************
h2hover:
        move.l #screen3,a0
        move.l gpu_screen,a1
        move #0,d0
        move #0,d1
        move #384,d2
        move #32,d3
        move #0,d4
        move #0,d5
        jsr pmfade
        move.l #screen1,a0
        jsr clrscreen
        move.l #screen2,a0
        jsr clrscreen
        move.l #screen3,a0
        jsr clrscreen
        tst practise
        bne rreset
        tst rounds
        bpl nxtround
        clr h2h
        bra rreset

nxtround:
        clr sync
        move.l #screen3,a0
        move.l a0,gpu_screen
        jsr clrscreen
        move p1wins,d0
        add.b #'0',d0
        move.b d0,rndmsg+11
        move p2wins,d0
        add.b #'0',d0
        move.b d0,rndmsg+26
        lea rndmsg,a0
        lea cfont,a1
        move #50,d0
        jsr centext
        lea nxrmsg,a0
        move #-1,flock
        sub #1,rounds
        bpl godoit
        lea fnlmsg,a0
godoit:
        lea cfont,a1
        move #170,d0
        jsr centext
        tst rounds
        bpl raww
        move #100,flock
        move.b rndmsg+11,d0
        and #$ff,d0
        move.b rndmsg+26,d1
        and #$ff,d1
        move.b #'1',d2
        cmp d0,d1
        blt zaqw
        move.b #'2',d2
zaqw: move.b d2,wonmsg+7    ;set who won...
        lea wonmsg,a0
        lea afont,a1
        move #110,d0
        jsr centext      ;display it
        

raww:
        jsr settrue3
        move #1,mfudj
        move.l #$f70000,delta_i
        move.l #glopyr,demo_routine
        move.l #rrts,routine
        jsr attract
        tst z
        bmi z1
        bne rreset
z1:
        clr z
        jsr fade
        tst z
        bmi z2
        bne rreset
z2:
        clr z
        tst rounds
        bmi rreset
        jsr initobjects
        add #1,cwave
        and #$0f,cwave
        move cwave,cweb
        move.l #gamefx,fx
        bra ego

; *******************************************************************
; dobeastly
; *******************************************************************
dobeastly: 
        move.l #screen3,a0
        move.l a0,gpu_screen
        jsr clrscreen
        lea conm1,a0
        lea cfont,a1
        move #20,d0
        jsr centext
        lea victpage,a5
        tst beastly
        beq stvpa
        lea victpage2,a5
stvpa:
        move #40,d0
        move #40,d1
        jsr pager
        jsr premess
        jsr settrue3
        move.l #$ff0000,delta_i
        move.l #glocube,demo_routine
        move.l #rrts,routine
        move.l #rrts,fx
        move #$20,polspd1
        move #$30,polspd2
        move #0,pongphase
        move #0,pongphase2
        move #0,pongscale
        move #160,d4
        move #88,d5
        tst pal
        beq certnotpal
        add palfix2,d5
certnotpal: move #63,d0
        move #63,d1
        bsr ppolysi
        bset.b #2,sysflags
        move #-1,lives
        move #8000,attime
        jsr attr
        jsr fade
        clr gb
        bra dloop

; *******************************************************************
; glocube
; A 'demo_routine' routine
; *******************************************************************
glocube:
        move #7000,attime
        move.l #(PITCH1|PIXEL16|WID384),d0
        move.l d0,source_flags
        move.l d0,dest_flags
        lea in_buf,a0
        move.l cscreen,(a0)    ;source screen is already-displayed screen
        move.l #384,4(a0)
        move.l #240,d0
        add palfix1,d0
        move.l d0,8(a0)    ;X and Y dest rectangle size
        move.l #$1ec,12(a0)
        move.l #$1ec,16(a0)    ;X and Y scale as 8:8 fractions
        move.l #0,20(a0)      ;initial angle in brads
        move.l #$c00000,24(a0)    ;source x centre in 16:16
        move.l #$780000,d0
        add.l palfix3,d0
        move.l d0,28(a0)    ;y centre the same
        move.l #$0,32(a0)    ;offset of dest rectangle
        move.l delta_i,36(a0)    ;change of i per increment
        move.l #2,gpu_mode    ;op 2 of this module is Scale and Rotate
        move.l #demons,a0
        jsr gpurun      ;do it
        jsr gpuwait    
        move frames,d0
        lea sines,a0
        lsr #2,d0
        and #$ff,d0
        move.b 0(a0,d0.w),d0
        ext d0
        asl #1,d0
        move d0,polspd2
        jmp ppolydemo2

; *******************************************************************
; dumint
; *******************************************************************
dumint: move #$0101,INT1
        move #$0101,INT2
        rte

; *******************************************************************
; glopyr
; A 'demo_routine' routine
; *******************************************************************
glopyr:
        lea sines,a0
        move frames,d0
        and #$ff,d0
        move.b 0(a0,d0.w),d6
        ext d6
        asr #5,d6
        and.l #$ff,d6

        move.l #(PITCH1|PIXEL16|WID384),d0
        move.l d0,source_flags
        move.l d0,dest_flags
        lea in_buf,a0
        move.l cscreen,(a0)    ;source screen is already-displayed screen
        move.l #384,4(a0)
        move.l #240,d0
        add palfix1,d0
        move.l d0,8(a0)    ;X and Y dest rectangle size
        move.l #$1ec,12(a0)
        move.l #$1ec,16(a0)    ;X and Y scale as 8:8 fractions
        move.l d6,20(a0)      ;initial angle in brads
        move.l #$c00000,24(a0)    ;source x centre in 16:16
        move.l #$780000,d0
        add.l palfix3,d0
        move.l d0,28(a0)    ;y centre the same
        move.l #$0,32(a0)    ;offset of dest rectangle
        move.l delta_i,36(a0)    ;change of i per increment
        move.l #2,gpu_mode    ;op 2 of this module is Scale and Rotate
        move.l #demons,a0
        jsr gpurun      ;do it
        jsr gpuwait

        lea sines,a0
        move frames,d0
        and #$ff,d0
        move.b 0(a0,d0.w),d6
        ext d6
        asr #1,d6
        move #64,d0      ;glowing pyramid (selector?)
        move #80,d1  
        add #192,d6
        move #120,d7
        tst flock
        bmi echck
        sub #1,flock
        bra dop
echck:
        move.l pad_now+4,d2
        and.l #allbutts,d2
        beq dop
        move #-1,attime
        bra dop

; *******************************************************************
; clearee
; *******************************************************************
clearee:
        move.l #rrts,routine
dbonce:
        move.l pad_now,d0
        and.l #bigreset,d0
        bne dbonce
        clr z
        move.l #optiondraw,demo_routine
        clr.l pongx
        clr.l pongy
        clr.l pongz
        clr.l pc_1
        clr.l pc_2
        move.l #option11,the_option
        clr selected
        move #1,selectable
        jsr do_choose
        tst selected
        beq rreset
        lea defaults,a0    ;reset defaults
        lea hscom1,a1
        move #57,d0
crset:
        move (a0)+,(a1)+    ;copy var defaults to ram
        dbra d0,crset
        jsr spall      ;(makesure PAL bit is set)

        jsr eepromsave      ;save the defaults back to eeprom
        lea hscom1,a0    ;and expand both score tables
        jsr xscoretab
        jsr xkeys
        jsr setfires
        jsr scint      ;actually reset stuff that changed
        jsr intune
        bra rreset      ;go away

treset:
        bsr gameover
        bra rreset

zreset: jsr fade
        bra rreset

eeek:
        add #$1923,d0
        move d0,BG
        bra eeek


; *******************************************************************
; lsel
; Manage title screen, attract mode, version screen.
; *******************************************************************
lsel:
        clr _auto
        clr dnt
        tst misstit
        beq dtiti
        clr misstit
        bra stropt

dtiti:
        bsr spall
        bsr versionscreen
        move #1,auto
        tst z
        bmi atra1
        bne rrrts
        bra stropt
atra1:
        clr z
        bsr showscores
        tst z
        bmi atra2
        bne rrrts
        beq stropt
atra2:
        clr z
        bsr yakscreen  ; title screen with yak
        tst z
        bmi setauto
        bne rrrts
        beq stropt
stropt:
        jsr DISABLE_FX    ;any SFX to off
        jsr ENABLE_FX

        bsr optionscreen  ; screen with game start options
        clr auto
        tst z
        beq gselg
        bmi setauto
        bra rrrts

setauto: clr z
        clr cwave
        clr cweb
        move #15,t2k_max
        move #15,t2k_high
        move #15,trad_max
        move #15,trad_high    ;always reset these after attract mode
        move #1,auto
        move #1,_auto
        move #3,lives
        move #3,lastlives
        move #2,selected
        bsr selsa
        jsr rannum
        and #$0f,d0
        add #7,d0
        move d0,cwave
        move d0,cweb
        move.l #screen3,a0
        jsr clrscreen
        bra lvlset

gselg:
        move solidweb,-(a7)
        move #-1,lives
        clr solidweb
        bsr getlvl
        move #3,lives
        move #3,lastlives
        move (a7)+,solidweb
        rts

lvlset:
        move #1,players
        move #$1c,bulland
        move #7,bullmax
        move #1,entities
        clr pawsed
        clr.l paws
        clr noxtra
;  move #-1,db_on
        move.l #gamefx,fx
        bsr setweb
        bra circa



; *******************************************************************
; getlvl
; Select Level screen
; *******************************************************************
getlvl:
        clr pawsed
        clr.l paws
        clr noxtra
        move.l #rrts,routine
        clr sync
        move #1,screen_ready

        move t2k_max,d0
        and #$fe,d0
        add #1,d0
        move d0,topsel
        cmp #15,d0
        bgt keepset
        move #0,d0
keepset:
        tst t2k
        bne not2k

        tst h2h
        bne sh2h
        move trad_max,d0
        move d0,topsel
        cmp #15,d0
        bgt not2k
        move #0,d0 
        bra not2k

sh2h:
        move #15,topsel
        clr d0

not2k:
        move d0,cwave
        move d0,cweb
        lea beasties,a0      ;the main screen
;  move.l #screen1,d2
        move.l gpu_screen,d2
        move #SIDE,d0
        sub palside,d0
        move #TOP-16,d1
        add paltop,d1
        swap d0
        swap d1
        move #0,d5
        move #$24,d3
        move #$24,d4
        jsr makeit_trans

        move.l #screen3,gpu_screen
        jsr clearscreen

        tst h2h
        bne nbmsg
        lea afont,a1
        clr.l csmsg
nbmsg:
        lea cfont,a1
        lea csmsg2,a0  
        move #36,d0
        jsr centext

        lea beasties+64,a0
        move.l #screen3,d2
        move #SIDE,d0
        sub palside,d0
        move #TOP,d1
        add paltop,d1
        move #1,mfudj
        swap d0
        swap d1
        move #8,d5
        move #$24,d3
        move #$24,d4
        jsr makeit_trans    ;put up some TC screen for status display

;  tst h2h
;  bne nbmsg
;  bsr setcsmsg      ;set the CS message
;  lea afont,a1
;  move.l csmsg,a0  
;  move #20,d0
;  jsr centext
;  clr.l csmsg
;nbmsg:  lea cfont,a1
;  lea csmsg2,a0  
;  move #36,d0
;  jsr centext

        jsr clvp

        move.l #$ff00,z_top
        move.l #1100,z_max

        move #26,warp_add  ;Set stuff unique to this Mode
        move.l #4,warp_count  ;A good stiff starf with big streaks
        move.l #$60000,vp_sfs  ;fast starfield
        tst cwave
        beq alrzero
        sub #1,cwave
        bclr.b #0,cwave+1
        move cwave,cweb
alrzero:
        jsr initobjects
        bsr setweb
        bsr circa
        lea _web,a0
        move.l #300+webz,d0
        swap d0
        move.l d0,12(a0)  ;initial Z is further away than the usual
        move.l #draw_oo,mainloop_routine
        move.l #zoomto,routine
        move.l #gamefx,fx
        clr db_on
        clr sync
        move #1,screen_ready
        jsr mainloop
        jmp fade

draw_oo:
        bsr draw_o
        btst.b #2,sysflags
        beq rrrts
        tst h2h
        bne rrrts
        lea bstymsg,a0
        lea cfont,a1
        move #180,d0
        tst pal
        beq gnopal2
        add palfix2,d0
gnopal2: jmp centext

; *******************************************************************
; draw_o
; *******************************************************************
draw_o: cmp #1,webcol
        bne do_2
        add #1,wpt
        and #7,wpt
        bne do_1
        bsr swebpsych
        bra do_2
do_1:
;  cmp #1,wpt
;  bne do_2
;  bsr swebcol
do_2:
        jsr draw_objects
        tst.l csmsg
        beq rrrts
        move.l #screen3,gpu_screen

        move #0,d0
        move #84,d1
        move #384,d2
        move #32,d3
        move #0,d4
        move #0,d5
        move.l #screen3,a0
        move.l #screen3,a1
        jsr ecopy    ;just blit a clear bit


        lea afont,a1
        move.l csmsg,a0  
        clr.l csmsg
        tst h2h
        bne rrrts
        move #20,d0
        jmp centext

; *******************************************************************
; Populate the bonus score, e.g. BONUS 00001000
; *******************************************************************
setcsmsg:
        lea csmsg1,a0
        move.l score,a1
        move #7,d0
sstb:
        move.b (a1)+,d1
        bne gotadig
        move.b #'0',(a0)+
        dbra d0,sstb
        lea -2(a0),a0
        move.l a0,csmsg
        move.b #'n',(a0)
        rts
gotadig:
        move.l a0,csmsg
gadig:
         add.b #'0',d1
        move.b d1,(a0)+
        move.b (a1)+,d1
        dbra d0,gadig
        rts


; *******************************************************************
; zoomto
; A 'routine' routine.
; *******************************************************************
zoomto:
        lea _web,a0
        add #2,30(a0)
        add #1,32(a0)
        sub #1,12(a0)
        add.b #1,29(a0)
        bne rrrts
        move.l #waitfor,routine
rrrts:
        rts

; *******************************************************************
; waitfor
; A 'routine' routine.
; *******************************************************************
waitfor:
        lea _web,a0
        add #1,28(a0)
        btst.b #3,sysflags
        beq ojoj
        move.b pad_now,d0
        rol.b #3,d0      ;get button A as low bit
        and #1,d0
        move.b pad_now+2,d1
        rol.b #4,d1
        and #2,d1
        or d1,d0      ;combine buttons a and c for up/down
        btst #0,d0
        bne zforward
        btst #1,d0
        bne zbackward
        bra not2p

ojoj:
        btst.b #5,pad_now+1
        bne zforward
        btst.b #4,pad_now+1
        bne zbackward
not2p:
        btst.b #2,sysflags
        beq nobeastyy
        tst h2h
        bne nobeastyy
        move.l pad_now,d0
        and.l #optionbutton,d0
        beq nobeastyy
        move #1,beastly
        bra gooff
nobeastyy: move.l #allbutts,d0
        and.l pad_now,d0
        beq noxxo
        clr beastly
gooff:
        clr _pauen
        clr pauen
        move.l #rrts,routine
        move #1,term
        move #1,startbonus
        rts

noxxo:
        tst h2h
        bne rrrts  
        btst.b #3,sysflags
        bne rrrts

        btst.b #6,pad_now+1
        beq wfor
        cmp #-$50,vp_x
        ble oro
        sub.l #$11000,vp_x
oro:
        add #1,30(a0)
        rts
wfor:
        btst.b #7,pad_now+1
        beq rrrts
        cmp #$50,vp_x
        bge oro2
        add.l #$11000,vp_x
oro2:
        sub #1,30(a0)
        rts

zforward:
        move cwave,d0
        move #2,d1
        sub h2h,d1
        sub d1,d0
        bpl zff
        rts
zff:
         move.l #zprev,routine
        clr 24(a0)
        rts
zbackward:
        move cwave,d0
        move #2,d1
        sub h2h,d1
        add d1,d0
        cmp topsel,d0
        ble gzn  
        rts
gzn:
         move.l #znext,routine
        clr 24(a0)
        rts

; *******************************************************************
; zprev
; A 'routine' routine.
; *******************************************************************
zprev:  lea _web,a0
        bsr ccent
        add.l #$40000,12(a0)
        add #2,28(a0)
        add #1,24(a0)
        cmp #50,24(a0)
        blt rrrts
        move #2,d0
        sub h2h,d0
        sub d0,cwave
        sub d0,cweb
        bpl zprev_1
        clr cwave
        clr cweb
zprev_1: bsr sweb
        move.l #$ffffffff,warp_flash
        bsr circa
        lea _web,a0
        move.l #webz+44-200,d0
        swap d0
        move.l d0,12(a0)
        move #4,26(a0)
        move.l #zshow,routine
        rts

; *******************************************************************
; znext
; A 'routine' routine.
; *******************************************************************
znext:
        lea _web,a0
        bsr ccent
        sub.l #$40000,12(a0)
        sub #2,28(a0)
        add #1,24(a0)
        cmp #50,24(a0)
        blt rrrts
        move #2,d0
        sub h2h,d0
        add d0,cwave
        add d0,cweb
        bsr sweb
        move.l #$ffffffff,warp_flash
        bsr circa
        lea _web,a0
        move.l #webz+44+200,d0
        swap d0
        move.l d0,12(a0)
        move #-4,26(a0)
        move.l #zshow,routine
        rts

; *******************************************************************
; zshow
; A 'routine' routine.
; *******************************************************************
zshow:
        lea _web,a0
        move 26(a0),d0
        swap d0
        clr d0
        add.l d0,12(a0)
        sub #1,24(a0)
        bne rrrts
        move.l #waitfor,routine
        rts

; *******************************************************************
; dowf
; Do warp flash
; *******************************************************************
dowf:
        move.l warp_flash,BG
        tst.l warp_flash
        beq zsho1
        sub.l #$11111111,warp_flash
zsho1:
        rts

; *******************************************************************
; ccent
; *******************************************************************
ccent:
         move 30(a0),d0
        and #$fc,d0
        beq ccnt2
        cmp #127,d0
        blt ccnt1
        add #4,d0
        move d0,30(a0)
        bra ccnt2
ccnt1:
        sub #4,d0
        move d0,30(a0)
ccnt2:
        move vp_x,d0
        and #$fffc,d0
        beq rrrts
        bpl ccnt3
        add #4,d0
        move d0,vp_x
        rts
ccnt3: sub #4,d0
        move d0,vp_x
        rts

; *******************************************************************
; mandy
;
; do Mandelbrot-sets and stuff; the Pause Mode demos
; *******************************************************************
mandy:
settrue3:
        move #TOP,d1
settrue33:
        lea beasties+64,a0
        move.l #screen3,d2
        move #SIDE,d0
        sub palside,d0
        swap d0
        add paltop,d1
        swap d1
        clr d1
        move #0,d5
        move #$24,d3
        move #$24,d4
        jsr makeit_trans
        move.l #rrts,fx
        rts

; *******************************************************************
; settrue
; Unused code
; *******************************************************************
settrue:
        lea beasties,a0    ;set main screen to 16-bit
        move.l #screen2,d2
        move.l d2,gpu_screen
strue:
        move #TOP,d1
stru:
        move #SIDE,d0
        sub palside,d0
        swap d0
        add paltop,d1
        swap d1
        clr d1
        move #0,d5
        move #$24,d3
        move #$24,d4
        jsr makeit_trans
        move.l #rrts,fx
        rts

; *******************************************************************
; sthang
; Unused code
; *******************************************************************

sthang:
;  lea parrot,a0
;  jsr gpuload
        bsr settrue
        clr pongx
        move #60,pongxv
        move #10,pongyv
        move #$0404,pongzv
        move.l #sthiing,demo_routine
        bra mp_demorun

sthiing: move.l #0,gpu_mode
        move.l #(PITCH1|PIXEL16|WID384|XADDPHR),dest_flags  ;screen details for CLS
        move.l #$0,backg
        lea fastvector,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait

        lea chev,a1
        lea p_sines,a4
        clr.l d2
        clr.l d3
        move #63,d7
        move pongx,d4
sthng: move d7,-(a7)
        and #$ff,d4
        move.b 0(a4,d4.w),d1
        and.l #$ff,d1
        move d1,d7
        add #48,d1
        swap d1
        lsr.l #4,d1
        bsr pulser
        move d6,8(a1)
        move (a7)+,d7
        move d7,d0
        lsl #2,d0
        and.l #$ff,d0
        move d4,-(a7)
        bsr drawsolid
        move (a7)+,d4
        move pongxv,d5
        add d5,d4
        dbra d7,sthng
        move pongyv,d0
        add d0,pongx
        sub.b #1,pongzv
        bpl rrrts
        move.b pongzv+1,pongzv

        lea ainc,a0
        lea adec,a1
        lea binc,a2
        lea bdec,a3
        bra gjoy

; *******************************************************************
; stunnel
; Unused code
; *******************************************************************
stunnel:
        bsr settrue
        clr pongx
        clr pongy
        clr pongz
        move.l #stunl,demo_routine
        move ranptr,rpcopy
        bra mp_demorun

; *******************************************************************
; stunl
; A 'demo_routine' routine
; Unused code
; *******************************************************************
stunl:
         move.l #0,gpu_mode
        move.l #(PITCH1|PIXEL16|WID384|XADDPHR),dest_flags  ;screen details for CLS
        move.l #$0,backg
        lea fastvector,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait

        move pongz,d1
        and.l #$0f,d1
        bsr xork

        add #1,pongx
        move pongz,d1
        and.l #$0f,d1
        bne zkit
        sub #1,rpcopy
zkit:
        sub #1,pongz
        rts

xork:
        move rpcopy,ranptr
        add.l #$60,d1    ;dist of first ring
        swap d1
        clr d1
        move #7,d7
tunn:
        move d7,-(a7)
        lea chevron,a1
        move.l d1,d7
        swap d7
        bsr pulser
        move d6,8(a1)
        eor #$ff,d6
        move d6,24(a1)
        jsr rannum
        and #$03,d0
        add #2,d0
        move.l #$100,d6
        divu d0,d6
        sub #1,d0
        move d0,d7
        move.l d1,d4
        swap d4
        add frames,d4
        lea sines,a0
        and #$ff,d4
        move.b 0(a0,d4.w),d3
        ext d3
        swap d3
        clr d3
        asr.l #4,d3
        clr.l d2
;  clr.l d3
        move.l #$680000,d0
        sub.l d1,d0
        swap d0
        move d0,d4
        mulu d4,d0
        lsr.l #5,d0
        and.l #$ff,d0
        move.l d1,-(a7)
        asr.l #2,d1
        cmp.l #$10000,d1
        blt notar
        move.l #9,d4
        move.l #9,d5
        bsr s_multi
notar:
        move.l (a7)+,d1
        move (a7)+,d7
        sub.l #$100000,d1
;  add.b #$08,d0
        dbra d7,tunn
        rts


; *******************************************************************
; sflipper
; Unused code
; *******************************************************************
sflipper:
        lea beasties,a0    ;set main screen to 16-bit
        move.l #screen2,d2
        move.l d2,gpu_screen
        move #SIDE,d0
        sub palside,d0
        move #TOP,d1
        swap d0
        add paltop,d1
        swap d1
        move #0,d5
        move #$24,d3
        move #$24,d4
        jsr makeit
        move.l #rrts,fx
        move.l #sflip,demo_routine
        clr pongx
        move #9,pongz
        bra mp_demorun


; *******************************************************************
; sflip
; A 'demo_routine' routine
; *******************************************************************
sflip:
         move.l #0,gpu_mode
        move.l #(PITCH1|PIXEL16|WID384|XADDPHR),dest_flags  ;screen details for CLS
;  move.l #$0,backg
        lea fastvector,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait

        lea prevshape,a0
        lea nextshape,a1
        lea away,a2
        lea towards,a3
        bsr gjoy

        move frames,d0
        and.l #$ff,d0
        move pongz,d1
        and #$1ff,d1
        swap d1
        clr d1
        lsr.l #1,d1
        add.l #$10000,d1 
        move frames,pucnt    ;simulate pucnt in game

        move pongx,d2
        lsr #2,d2
        and #$fc,d2
        lea shapes,a2
        move.l 0(a2,d2.w),d2
        bpl shok
        clr pongx
        move.l #draw_sflipper,d2
shok:
        move.l d2,a2
        clr.l d2
        clr.l d3
        move.l #9,d4
        move.l #9,d5
        jmp (a2)

shapes: dc.l draw_sflipper,draw_sfliptank,draw_sfuseball,draw_spulsar,draw_sfusetank,draw_spulstank,s_shot,draw_spshot,s_sattest
        dc.l -1

; *******************************************************************
; draw_h2hgen
; A member of the solids list.
; *******************************************************************
draw_h2hgen:
        lea leaf,a1
        move #7,d7
        move #$20,d6
        bra s_multi

; *******************************************************************
; s_shot
; A member of the solids list.
; *******************************************************************
s_shot:
        lea chevron,a1
        move #2,d7
        move #$55,d6
;  clr.l d2
;  clr.l d3
s_multi:
        movem.l d0-d1/a1,-(a7)
        bsr drawsolidxy
        jsr gpuwait
        movem.l (a7)+,d0-d1/a1
        add.b d6,d0
        dbra d7,s_multi
        rts

prevshape:
        tst pongx
        beq rrrts
        sub #1,pongx
        rts
nextshape:
        add #1,pongx
        rts
away:
        add #1,pongz
        rts
towards:
        sub #1,pongz
        rts


; *******************************************************************
; draw_h2hshot
; A member of the solids list.
; *******************************************************************
draw_h2hshot:
        tst 36(a6)
        bpl cringbull
        bra gringbull

supf1:
        lea s_flip1,a1
        bra ccdraw

supf2:
        lea s_flip2,a1
        bra ccdraw

draw_blueflip:
        lea blueflipper,a1
        bra ccdraw

; *******************************************************************
; draw_adroid
; A member of the solids list.
; *******************************************************************
draw_adroid:
        cmp #2,20(a6)  ;check for are we zapping someone
        bne dadr
        movem.l d0-d5,-(a7)
        move.l #192,xcent
        move.l #120,d6
        add palfix2,d6
        move.l d6,ycent
        lea in_buf,a0      ;set up func/linedraw
        move.l d2,(a0)+
        move.l d3,(a0)+
;  add.l #$f0000,d1
        move #webz+80,d6
        swap d6  
        move.l d6,(a0)+  ;XYZ source
        move.l d2,(a0)+
        move.l d3,(a0)+
;  sub.l #$f0000,d1
        move.l d1,(a0)+  ;XYZ dest
        move frames,d0
        and.l #$0f,d0
        or #$80,d0
        move.l d0,(a0)+  ;colour
        move.l #32,(a0)+  ;# segs
        move frames,d0
        and.l #$ff,d0
        or #$01,d0
        move.l d0,(a0)+    ;rnd seed
        move.l #0,gpu_mode
        move.l #bovine,a0
        jsr gpurun    ;do it
        jsr gpuwait
        jsr WaitBlit
        movem.l (a7)+,d0-d5
dadr:
        lea adroid,a1
        bra drawsolidxy

dr_beast3:
        lea hornm3,a1
        bra drawsolidxy

dr_beast2:
        lea hornm2,a1
        bra drawsolidxy

; *******************************************************************
; draw_beast
; A member of the solids list.
; *******************************************************************
draw_beast:
        move #0,d6
        move 46(a6),d7
        and #3,d7
        cmp #1,24(a6)  ;is it in Flipto mode?
        bne dntdbl
        lsl #1,d0  ;angle x2 
dntdbl:
        lea beastybits,a0
drbeast:
        move.l (a0)+,a1
        movem.l d0-d7/a0,-(a7)
        bsr ccdraw
        jsr gpuwait
        movem.l (a7)+,d0-d7/a0
        add #1,d6
        cmp d7,d6    ;check Level
        ble drbeast
        rts

beastybits:
        dc.l hornm1,hornm2,hornm3,hornm3

; *******************************************************************
; cdraw_sflipper
; A member of the solids list.
; *******************************************************************
cdraw_sflipper:
        lea s_flipper,a1
ccdraw:
        move #9,d4
        tst h2hor    ;if this is set, reverse the centering
        beq stcnt
        add 36(a6),d4
        bra cntdne
stcnt:
        sub 36(a6),d4
cntdne:
        ext.l d4    ;get x-centre
        move.l #9,d5
        bra drawsolidxy

; *******************************************************************
; draw_sflipper
; A member of the 'shapes' list
; *******************************************************************
draw_sflipper:
        lea s_flipper,a1
        bra drawsolidxy


; *******************************************************************
; draw_mirr
; A member of the solids list.
; *******************************************************************
draw_mirr:
        lea mirr,a1
        bra drawsolidxy


; *******************************************************************
; draw_spshot
; A member of the 'shapes' list
; *******************************************************************
draw_spshot:
        lea pshot,a1
        bra drawsolidxy

; *******************************************************************
; draw_pup1
; A member of the solids list.
; *******************************************************************
draw_pup1:
        tst 48(a6)
        bpl opupring
        cmp #$0a,44(a6)
        bne pupring
        movem.l d1-d3,-(A7)
        lea pwrlaser,a1
        move.l d1,d0
        clr d0
        swap d0
        bsr drawsolidxy
        jsr gpuwait
        movem.l (a7)+,d1-d3
        bra pupring

; *******************************************************************
; draw_spulsar
; A member of the solids list.
; *******************************************************************
draw_spulsar:
        cmp #3,34(a6)  ;check for flipper-mode
        bne upulsa
        move #9,d4
        sub 36(a6),d4
        ext.l d4    ;get x-centre
        move.l #9,d5
upulsa:
        move pucnt,d6
        lea spulsars,a0
        and #$0f,d6
        lsl #2,d6
        move.l 0(a0,d6.w),a1
        bra drawsolidxy

; *******************************************************************
; draw_spulstank
; A member of the solids list.
; *******************************************************************
draw_spulstank:
        move pucnt,d2
        move frames,d6
        add.b d6,d0
        lea spulsars,a0
        and #$0f,d2
        lsl #2,d2
        move.l 0(a0,d2.w),a1
        movem.l d0-d1/a1,-(a7)
        bsr drawsolidxy
        jsr gpuwait
        movem.l (a7)+,d0-d1/a1
        add.b #$80,d0
        bra drawsolidxy

; *******************************************************************
; draw_sfuseball
; A member of the solids list.
; *******************************************************************
draw_sfuseball:
        move ranptr,-(a7)
        move frames,d7
        lsr #2,d7
        move d7,ranptr
        lea fbcols,a6
        move #4,d7

fleg:
        move.l d0,-(a7)
        lea fbpiece1,a1
        jsr rannum
        btst #0,d0
        bne dsfb1
        lea fbpiece2,a1
dsfb1:
        move.l (a7)+,d0
        move.b 0(a6,d7.w),d6
        move.b d6,5(a1)
        move.b d6,21(a1)  ;colour leg of fuseball   
        movem.l d0-d1,-(A7)
        jsr drawsolidxy
        jsr gpuwait
        movem.l (a7)+,d0-d1
        add.b #$33,d0
        dbra d7,fleg
        move (a7)+,ranptr
        rts

; *******************************************************************
; draw_sfusetank
; A member of the solids list.
; *******************************************************************
draw_sfusetank:
        lea fbcols,a6
        move #4,d7
        move frames,d6
        add.b d6,d0
futank:
        lea fbpiece2,a1
        move.b 0(a6,d7.w),d6
        move.b d6,5(a1)
        move.b d6,21(a1)  ;colour leg of fuseball   
        movem.l d0-d1,-(A7)
        bsr drawsolidxy
        jsr gpuwait
        movem.l (a7)+,d0-d1
        movem.l d0-d1,-(a7)
        lea fbpiece1,a1
        move.b 0(a6,d7.w),d6
        move.b d6,5(a1)
        move.b d6,21(a1)  ;colour leg of fuseball   
        bsr drawsolidxy
        jsr gpuwait
        movem.l (a7)+,d0-d1
        add.b #$33,d0
        dbra d7,futank
        rts

s_sattest:
        lea fbcols,a6
        move #15,d7
        move frames,d6
        asr #1,d6
        and #$ff,d6
ssat:
        move d7,-(a7)
        and #$03,d7
        lea fbpiece2,a1
        move.b 0(a6,d7.w),d2
        move.b d2,9(a1)
        move.b d2,25(a1)  ;colour leg of fuseball   
        movem.l d0-d1,-(A7)
        bsr drawsolid
        jsr gpuwait
        movem.l (a7)+,d0-d1
        movem.l d0-d1,-(a7)
        lea fbpiece1,a1
        move.b 0(a6,d7.w),d2
        move.b d2,9(a1)
        move.b d2,25(a1)  ;colour leg of fuseball   
        bsr drawsolid
        jsr gpuwait
        movem.l (a7)+,d0-d1
        add.b d6,d0
        move (a7)+,d7
        dbra d7,ssat
        rts


; *******************************************************************
; draw_sfliptank
; A member of the solids list.
; *******************************************************************
draw_sfliptank:
        lea s_fliptank2,a1
        move frames,d7
        asl #2,d7
        add.b d7,d0
        move.l d5,-(a7)
        bsr pulser
        move.l (a7)+,d5
        move d6,4(a1)
        move d6,20(a1)
        move d6,36(a1)
        move d6,52(a1)
        bra drawsolidxy

; *******************************************************************
; pulser
;
; enter with d7=counter, return pulse colour in d6, uses d5-7 and a2
; *******************************************************************
pulser:

        and #$ff,d7
        lea sines,a2
        move.b 0(a2,d7.w),d5
        ext d5
        add.b #$40,d7
        move.b 0(a2,d7.w),d6
        sub.b #$40,d7
        ext d6
        add #$80,d5
        add #$80,d6
        and #$f0,d5
        lsr #4,d6
        and #$0f,d6
        or d5,d6
        rts

; *******************************************************************
; drawsolid
;
; draw a solid Tempest enemy, enter with a1=poly shape address, d0=angle, d1=Z-position
; d2-d3=XY, d4-d5=Centre position
; *******************************************************************
drawsolid:
 
        clr.l d2
        clr.l d3
        move.l #9,d4
        move.l #9,d5

; *******************************************************************
; drawsolidxy
; *******************************************************************
drawsolidxy:
        lea in_buf,a0
        move.l a1,(a0)+
        move.l d2,(a0)+
        move.l d3,(a0)+
        move.l d1,(a0)+
        move.l d4,(a0)+
        move.l d5,(a0)+
        move.l d0,(a0)

        move.l #0,gpu_mode
        lea equine,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        rts

; *******************************************************************
; gameover
; Game Over sequence.
;
; The game over graphical effect.
;
; *******************************************************************
gameover:
        move.l #rrts,routine
        clr _pauen
        clr pauen
;  move #-1,db_on
        move #1,modnum
        tst h2h
        bne ddthis
        tst auto
        bne ddthis
        move cwave,d0
        cmp #98,d0
        ble imaxx
        move #98,d0    ;max possibl saved lvl
imaxx:
        lea t2k_max,a0
        tst t2k
        bne yty
        lea trad_max,a0
yty:
        move (a0),d1
        cmp d1,d0
        ble ddthat    ;Do not update if this was llarger
        move d0,(a0)    ;save the highest wave we ever reached
ddthat:
        move d0,2(a0)    ;save where we got to this game
ddthis:
        move.l #gofeed,demo_routine
        move #0,pongx
        clr.l pongz
        move #10,timer
        bsr gogame
        cmp #1,z
        beq rrrts
        jsr dohiscores
        jmp eepromsave

; *******************************************************************
; gofeed
; A 'demo_routine' routine
; *******************************************************************
gofeed:
        move.l #(PITCH1|PIXEL16|WID384),d0
        move.l d0,source_flags
        move.l d0,dest_flags
        lea in_buf,a0
        add.l #$2000,pongz
        move pongz,d0
        and.l #$0f,d0
        sub.l #$07,d0
        move.l cscreen,(a0)    ;source screen is already-displayed screen
        move.l #384,4(a0)
        move.l #240,d1
        add palfix1,d1
        move.l d1,8(a0)    ;X and Y dest rectangle size
        move.l #$1f4,12(a0)
        move.l #$1f4,16(a0)    ;X and Y scale as 8:8 fractions
        move.l d0,20(a0)      ;initial angle in brads
        move.l #$c00000,24(a0)    ;source x centre in 16:16
        move.l #$780000,d0
        add.l palfix3,d0
        move.l d0,28(a0)    ;y centre the same
        move.l #$0,32(a0)    ;offset of dest rectangle
        move.l delta_i,36(a0)    ;change of i per increment
        move.l #2,gpu_mode    ;op 2 of this module is Scale and Rotate
        move.l #demons,a0
        jsr gpurun      ;do it
        jsr gpuwait



        move.l #4,gpu_mode  ;Multiple images stretching towards you in Z
        lea p_sines,a0
        move pongx,d0
        move pongy,d3
        add #15,pongx
        add #17,pongy
        and #$ff,d0
        and #$ff,d3
        move.b 0(a0,d0.w),d1
        move.b 0(a0,d3.w),d2
        and.l #$ff,d1
        and.l #$ff,d2
        lsl.l #6,d2
        lsl.l #6,d1
        add.l #$8000,d1
        add.l #$8000,d2

 
        ; Game Over 
        lea in_buf,a0
        move.l #pic2,(a0)+  ;srce screen for effect
        move.l #$150094,(a0)+  ;srce start pixel address
        move.l #$440091,(a0)+  ;srce size
        move.l d1,(a0)+    ;x-scale
        move.l d2,(a0)+    ;y-scale
        move.l #0,(a0)+    ;shearx
        move.l #0,(a0)+    ;sheary
        move.l #1,(a0)+    ;Mode 1 = Centered
        move.l #0,d0
        move.l d0,(a0)+
        move.l d0,(a0)+
        move.l #$600000,d0
        move.l d0,(a0)+  ;Dest x,y,z
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait

        tst timer
        bmi babb
        sub #1,timer
        bpl rrrts

babb:
        move.l pad_now,d0
        and.l #allbutts,d0
        beq rrrts
        move #50,timer
        move.l #clearfeed,demo_routine
        move.l #$1f4,pongx
        rts

; *******************************************************************
; clearfeed
; A 'demo_routine' routine
; *******************************************************************
clearfeed:
        move.l #(PITCH1|PIXEL16|WID384),d0
        move.l d0,source_flags
        move.l d0,dest_flags
        lea in_buf,a0
        move.l cscreen,(a0)    ;source screen is already-displayed screen
        move.l #384,4(a0)
        move.l #240,d0
        add palfix1,d0
        move.l d0,8(a0)    ;X and Y dest rectangle size
        move.l pongx,d0
        move.l d0,12(a0)
        move.l d0,16(a0)    ;X and Y scale as 8:8 fractions
        move.l #3,20(a0)      ;initial angle in brads
        move.l #$c00000,24(a0)    ;source x centre in 16:16
        move.l #$780000,d0
        add.l palfix3,d0
        move.l d0,28(a0)    ;y centre the same
        move.l #$0,32(a0)    ;offset of dest rectangle
        move.l delta_i,36(a0)
        move.l #2,gpu_mode    ;op 2 of this module is Scale and Rotate
        move.l #demons,a0
        jsr gpurun      ;do it
        jsr gpuwait

        move #10,d1
        jsr rand
        move d0,d2
        move #10,d1
        jsr rand
        move d2,d1

        add #186,d0
        add #114,d1
        move #3,d2
        move #3,d3
        clr.l d4
        move.l dscreen,a0
        jsr BlitBlock

        sub.l #$02,pongx
        sub #1,timer
        bpl rrrts
        move #1,x_end
        rts

; *******************************************************************
; versionscreen
; Draws the main title screen.
; *******************************************************************
versionscreen:
        move.l #rrts,routine
        jsr InitBeasties
        lea beasties,a0    ;set main screen to 16-bit
        move.l #screen2,d2
        move.l d2,gpu_screen
        move #TOP-16,d1
        bsr stru

        move.l #screen3,gpu_screen
        jsr clearscreen  


        move #4,d0
        move #84,d1
        move #197,d2
        move #65,d3
        move #92,d4
        move #120-15,d5
        tst pal
        beq mypal
        add #10,d5
mypal:
        move.l #pic5,a0
        move.l #screen3,a1
        jsr CopyBlock  

        lea afont,a1
        lea ataricop1,a0  
        move #190-8,d0
        add palfix2,d0
        jsr centext
        lea afont,a1
        lea ataricop2,a0  
        move #207-5,d0
        add palfix2,d0
        jsr centext

        lea cfont,a1
        lea llamacop,a0  
        move #40-10,d0
        jsr centext


        move #TOP-16,d1
        jsr settrue33

        move.l #$f80000,delta_i

        move.l #v_ersion,demo_routine
        clr.l pc_1
        clr.l pc_2
        clr.l pongz
        clr pongzv
        clr.l pongx
        clr.l pongy
        move #1,v_on
        move #1,l_on
        clr.l d7
        move #250,attime
        bsr attr
        bra fade

; *******************************************************************
; v_ersion
; *******************************************************************
v_ersion:
 move pongxv,d0
        and #$ff,d0
        lea sines,a0
        move.b 0(a0,d0.w),d7
        ext d7
        ext.l d7
        asr.l #5,d7

; *******************************************************************
; versiondraw
; *******************************************************************
versiondraw:
        move.l cscreen,a5
        move.l #(PITCH1|PIXEL16|WID384),d0    ;Feedback
        move.l d0,source_flags
        move.l d0,dest_flags
        lea in_buf,a0
        move.l a5,(a0)    ;source screen is already-displayed screen
        move.l #384,4(a0)
        move.l #240,d0
        add palfix1,d0
        move.l d0,8(a0)    ;X and Y dest rectangle size
        move.l #$1ee,12(a0)
        move.l #$1ee,16(a0)    ;X and Y scale as 8:8 fractions
        move.l d7,20(a0)      ;initial angle in brads
        move pongzv,d0
        add #1,pongzv
        and #$ff,d0
        lea sines,a2
        move.b 0(a2,d0.w),d1
        ext d1
        swap d1
        clr d1

        move frames,d0
        and #$ff,d0
        move.b 0(a2,d0.w),d2
        ext d2
        swap d2
        clr d2  
        asr.l #5,d1
        asr.l #4,d2
        add.l #$c10000,d1
        add.l #$7c0000,d2
        add.l palfix2,d2
        move.l d1,24(a0)    ;source x centre in 16:16
        move.l d2,28(a0)    ;y centre the same
        move.l #$0,32(a0)    ;offset of dest rectangle
        move.l delta_i,36(a0)
        move.l #2,gpu_mode    ;op 2 of this module is Scale and Rotate
        move.l #demons,a0
        jsr gpurun      ;do it
        jsr gpuwait
        jsr WaitBlit

        tst v_on
        beq dopyr      ;allows Excellent voctory thang to get @ it

        bsr ssys
        jmp rexfb

dopyr:
        move #64,d0      ;glowing pyramid (selector?)
        move #80,d1  
        move #192,d6
        move #120,d7
; *******************************************************************
; dop
; *******************************************************************
dop:
        add.l #$40000,pc_1
        add.l #$60100,pc_2
        bsr makepyr

; *******************************************************************
; ppyr
; *******************************************************************
ppyr:
        move.l #2,gpu_mode
        move.l #pypoly1,in_buf
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        move.l #pypoly2,in_buf
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        move.l #pypoly3,in_buf
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jmp gpuwait


; *******************************************************************
; centext
; Display centred text on the screen.
; *******************************************************************
centext:
        move.l a0,d2
        lea in_buf,a0
        move.l d2,(a0)    ;Set up texter: address of text $
        move.l a1,4(a0)    ;font data structure
        move.l #0,8(a0)
        move.l #0,12(a0)    ;dropshadow vector
        move.l #$10000,16(a0)
        move.l #$10000,20(a0)    ;text scale
        move.l #0,24(a0)
        move.l #0,28(a0)    ;text shear
        move.l #0,36(a0)
        bsr g_textlength
        lsr #1,d7
        neg d7
        add #192,d7
        swap d0
        move d7,d0
        move.l d0,32(a0)    ;set text origin
        lea texter,a0
        jsr gpurun
        jmp gpuwait

; *******************************************************************
; setfires
; *******************************************************************
setfires:
        lea fire_2,a0
        lea firea,a1
        lea fires,a2
        lea o4s1,a3    ;option select messages here
        move #2,d0
sfres:
        move (a1)+,d1
        move d1,d2
        add #65,d2    ;is ASCII of button choice
        move.b d2,12(a3)  ;put it in message
        asl #2,d1
        move.l 0(a2,d1.w),(a0)+
        lea 16(a3),a3
        dbra d0,sfres
        rts

; *******************************************************************
; firesel
; *******************************************************************
firesel:
        bsr setfires
        move.l #option4,the_option
        move #3,selectable
        clr selected
fslp:
        bsr do_choose
        tst z
        bne firsend
        cmp #3,selected
        beq firsend    ;user selected exit
        lea fires,a0
        move.l selbutt,d0  ;get button(s) used for select
        move #0,d7
whb:
        move.l (a0)+,d1    ;button mask
        and.l d0,d1    ;check button
        bne bpressed    ;got one
        addq #1,d7
        cmp #3,d7    ;if not matched by here...
        blt whb
        bra fslp    ;..must be illegal (should never occur)
bpressed:
        lea firea,a0    ;now <selected> is func #, d7 is what button
        move #0,d6
fndwhr:
        cmp (a0)+,d7    ;find where that value is at now
        beq gotwhr
        add #1,d6
        bra fndwhr
gotwhr:
        cmp selected,d6
        beq fslp    ;it's the same as usual, leave it
        move selected,d5
        lsl #1,d5
        lea firea,a0
        move 0(a0,d5.w),d4  ;get old setting into d4
        move d7,0(a0,d5.w)  ;put requested setting in
        lsl #1,d6
        move d4,0(a0,d6.w)  ;put old setting of selected button here
        bsr setfires    ;update the actual fire settings
        bra fslp    ;loop until end selected

firsend:
        jmp eepromsave


; *******************************************************************
; rotset
; *******************************************************************
rotset:
        move.l #option5,the_option

        bsr sconopt

        move #-1,blanka
        move #2,selectable
        clr selected
bglp:
        bsr do_choose
        tst z
        bne fago
        cmp #2,selected
        beq firsend    ;go save any changed controller shit
        cmp #1,selected
        beq con2chg
        bchg.b #3,sysflags
        bsr sconopt
        bra bglp
con2chg:
        bchg.b #4,sysflags
        bsr sconopt
        bra bglp


; *******************************************************************
; sconopt
; *******************************************************************
sconopt:
        move.l #o5s10,d0
        btst.b #3,sysflags
        beq scono1
        move.l #o5s11,d0
scono1:
        move.l d0,option5+8
        move.l #o5s20,d0
        btst.b #4,sysflags
        beq scono2
        move.l #o5s21,d0
scono2:
        move.l d0,option5+12
scint:

        move.b sysflags,d0
        and #$18,d0
        beq sintoff
        move pit1,d0
        lsr #3,d0
        move d0,PIT1
        move d0,ppit1
        move #1,roconon
        rts
sintoff:
        move pit1,PIT1
        move pit1,ppit1
        clr roconon
        rts

; *******************************************************************
; optionscreen
; Select game type screen, e.g. classic, duel, etc.
; *******************************************************************
optionscreen:
        move.l #rrts,routine
;  move #-1,db_on
        move.l #optiondraw,demo_routine
        clr.l pongx
        clr.l pongy
        clr.l pongz
        clr.l pc_1
        clr.l pc_2
dcc:
        tst z
        bne rrrts
        move.l #option1,the_option
        move #2,selected
        clr t2k
        clr webbase
        move #$0f,weband
        move #3,selectable
        bsr do_choose
        tst z
        bne fago
        tst optpress
        bne gameopt
        cmp #3,selected      ;do we do second Options screen?
        bne selse

        clr selected      ;get setup for H2H mode
        move #2,selectable
        move.l #option6,the_option
        bsr do_choose
        tst z
        bne fago
        cmp #2,selected
        beq dcc        ;#2, was Exit, back to main title
        move selected,practise    ;0=full 2-player, 1=practise
        move #1,h2h      ;select h2h mode
        clr rounds
        tst practise
        bne fago
        clr selected
        move #2,selectable
        move.l #option10,the_option
        bsr do_choose
        move selected,d0
        lsl #1,d0
        move d0,rounds
        clr p1wins
        clr p2wins
fago:
        bsr fade
        clr selected
        move #1,players
        move #$1c,bulland
        move #7,bullmax
        move #1,entities
        bra xsel1      ;go start up with h2h asserted...

; *******************************************************************
; Display the Game Options, Select Dude Menu.
; *******************************************************************
gameopt:
        clr selected      ;this does game option menu
        move #1,selectable
        move.l #option2,the_option
        bsr do_choose
        tst z
        bne fago
        jsr eepromsave
        move selected,d0
        beq dispop
        cmp #1,d0
        bne nxtsl
        bsr firesel
        tst z
        bne fago
        bra dcc
nxtsl:
        cmp #2,d0
        bne dcc
        bsr rotset
        bra optionscreen

dispop:
        bsr fade      ;going to do option on top of a displayed Web
        bsr sopt3
        move.l #option3,the_option
        move #2,selectable
        clr selected      ;selector is set up...
        move #1,tblock

        move #26,warp_add  ;Set up starfield stuff
        move.l #4,warp_count
        move.l #$60000,vp_sfs
        jsr clvp
        move cweb,-(a7)
        move #14,cweb    ;set Yaks head web  
        jsr initobjects
        bsr setweb
        bsr circa    ;init circular *field
        move.l #gamefx,fx  ;(so *f moves)
        lea _web,a0
        move.l #webz,d0
        swap d0
        move.l d0,12(a0)  ;initial Z is further away than the usual
        move #1,34(a0)
        move.l #vecoptdraw,demo_routine
dcc2:
        bsr do_choose
        clr tblock
        tst z
        bne dcc3
        move selected,d0
        bne vop11
        bchg.b #0,sysflags
voe:
        bsr sopt3
        bra dcc2
vop11:
        cmp #1,d0
        bne dcc3
        bchg.b #1,sysflags
        bra voe
dcc3:
        jsr eepromsave
        bsr fade
        move (a7)+,cweb
        bra optionscreen

; *******************************************************************
; vecoptdraw
; A 'demo_routine' routine
; *******************************************************************
vecoptdraw:
        lea _web,a0
        add #3,28(a0)
        add #1,30(a0)
        bsr draw_o
        bra opts


; *******************************************************************
; sopt3
; *******************************************************************
sopt3:
        move.l #o3s10,d0    ;set correct optionlist for screen params
        btst.b #0,sysflags
        beq dweeb1
        move.l #o3s11,d0
dweeb1:
        move.l d0,option3+8
        move.l #o3s20,d0    ;set correct optionlist for screen params
        btst.b #1,sysflags
        beq dweeb2
        move.l #o3s21,d0
dweeb2:
        move.l d0,option3+12
        rts
        
; *******************************************************************
; selse
; *******************************************************************
selse:
        move #1,players
        move #$1c,bulland
        move #7,bullmax
        move #1,entities
          cmp #2,selected
        beq npling
        tst selected
        beq opling      ;no Droidy or 2pl in trad Tempest
        move selected,-(a7)
        clr selected
        move #2,selectable
        move.l #option7,the_option
        bsr do_choose

        move selected,d0
        beq stdstrt
        cmp #2,d0
        beq set22
        move #1,players
        move #$3c,bulland  ;for test droid mode
        move #15,bullmax
        move #2,entities
        bra stdstrt
set22:
        move #2,players    ;start 2-player simul mode
        move #2,entities
        move #$3c,bulland
        move #15,bullmax
        clr dying
stdstrt:
        move (a7)+,selected
        bra opling

npling:
        move #-1,keyplay
        tst akeys    ;get active keys
        bmi opling
        move selected,-(a7)

        move #1,selected
        move #1,selectable
        move.l #option9,the_option
        bsr do_choose
        tst selected
        bne nonkey

        clr selected
        move akeys,selectable
        move.l #option8,the_option
        bsr do_choose
        move selected,keyplay
        move selected,d0
        asl #2,d0
        lea keys,a0
        move.b 3(a0,d0.w),d0
        and #$ff,d0
        add #1,d0
        cmp #99,d0
        ble isoka
        move #99,d0
isoka:
        move d0,t2k_max
nonkey:
        move (a7)+,selected

opling:
        bsr fade
; *******************************************************************
; selsa
; *******************************************************************
selsa:
        clr blanka
        tst selected
        bne xsel1
        move #0,view
        rts

; *******************************************************************
; xsel1
; *******************************************************************
xsel1:
        move #-1,blanka
        move #0,view
        cmp #2,selected
        bne rrrts
        move #-1,t2k
        move #1,solidweb
        move #$10,webbase
        move #$1f,weband
        rts

; *******************************************************************
; do_choose
; *******************************************************************
do_choose:
        move.l #oselector,routine
        clr.l rot_cum
        bsr attract
        move #27,sfx
        move #101,sfx_pri
        jmp fox

; *******************************************************************
; oselector
; Process selection of options in the option screen.
; A 'routine' routine.
; *******************************************************************
oselector:
        cmp.l #option1,the_option
        bne selector      ;from the main game screen you get to the options screen..

        move.l pad_now,d0 ; Get pressed buttons.
        and.l #a147,d0    ; Check for cheat combo.
        cmp.l #a147,d0    ; Cheat combo selected?
        bne nchen         ; No, skip.
        tst chenable      ; Is cheating enabled?
        bne nchen         ; No, skip.
        move #1,chenable  ; Enable cheating!
        jsr sayex    ;say Excellent for cheat-enable

nchen:  btst.b #1,pad_now+2  ;loop for Option pressed
        beq selector
        move #1,optpress
        move.l #rrts,routine
        rts
selector:
        cmp.l #option2,the_option
        bne selector2
        btst.b #6,sysflags
        bne sopt2
        btst.b #4,pad_now
        beq selector2
        btst.b #4,pad_now+4
        beq selector2
        bset.b #6,sysflags
        jsr sayex
sopt2:
        move.l #o2s3,option2+16
        move #2,selectable
selector2:
        move #1000,attime

        move.b pad_now+1,d0
        or.b pad_now+5,d0
        tst roconon
        beq jcononly
        tst.l rot_cum
        beq jcononly
        bpl stup
        bset #4,d0
        clr.l rot_cum
        bra jcononly
stup:
        bset #5,d0  
        clr.l rot_cum
jcononly:
        and #$30,d0
        beq rrrts
        move selected,d1
        move selectable,d2
        btst #4,d0
        bne decsel
        cmp d1,d2
        bne incsel
        clr selected
        bra selend
incsel:
        add #1,selected
selend:
        move.l #seldb,routine
        move #21,sfx
        move #101,sfx_pri
;  move #$ff,sfx_vol
        jsr fox
        rts
decsel:
        tst d1
        bne decsel1
        move d2,selected
        bra selend
decsel1:
        sub #1,selected
        bra selend

; *******************************************************************
; seldb
; *******************************************************************
seldb:
        move.l pad_now,d0
        or.l pad_now+4,d0
        and.l #somepad,d0
        bne rrrts
        move.l #oselector,routine
        rts

; *******************************************************************
; ssys
; *******************************************************************
ssys:
        move.b sysflags,d0
        and.l #$ff,d0
        move.l d0,_sysflags
        rts
; *******************************************************************
; optiondraw
; *******************************************************************
optiondraw:
        move.l #1,gpu_mode
        bsr ssys
        move.l #(PITCH1|PIXEL16|WID320),d0
        move.l d0,source_flags
        move.l #(PITCH1|PIXEL16|WID384),d0
        move.l d0,dest_flags    ;inform GPU of source/dest screentypes
        lea in_buf,a0
        move.l pongx,4(a0)      ;L Phase init 0
        move.l #$4000,8(a0)    ;L Amp
        move.l pongy,12(a0)      ;R Phase
        move.l #$4000,16(a0)    ;R Amp
        move.l #$10000,20(a0)    ;L step
        move.l #$10000,24(a0)    ;R step
        move.l #pic3+(640*11),(a0)    ;Input from pic buffer 3
        add.l #$10000,pongx
        add.l #$12000,pongy
        jsr WaitBlit
        lea demons,a0
        jsr gpurun      ;do horizontal ripple warp
        jsr gpuwait

; *******************************************************************
; opts
; Show 'Press option for game options'
; *******************************************************************
opts:
        cmp.l #option1,the_option  ;see if other options are available
        bne ntarnt      ;no they arent
        lea optmsg,a0
        lea cfont,a1
        move #15+8,d0
        jsr centext      ;say about pressing option
ntarnt:
        move #25,d0
        move #40,d1
        move #25+32,d6
        move selected,d7
        mulu #30,d7
        add #105,d7
        tst pal
        beq dopdop
        add #20,d7
dopdop:
        bsr dop

        move.l the_option,a4

drawopts:
        bsr text_setup    ;do generic text setup

        move #1,d7
        move #40+8,d5
        tst pal
        beq dropts
        add #10,d5
dropts:
        move.l (a4)+,d6
        beq nxopts
        move.l d6,a3
        move.l d6,(a0)
        bsr textlength      ;returns length of $ (a3) in pixels in d0
        lsr #1,d0
        neg d0
        add #196,d0
        swap d0
        move d5,d0
        swap d0
        move.l d0,32(a0)
        lea texter,a0
        jsr gpurun
        jsr gpuwait
        lea in_buf,a0
nxopts:
        add #20,d5
        dbra d7,dropts

        move #4,d7
        move #100,d5
        tst pal
        beq dropts2
        add #20,d5
dropts2:
        move.l (a4)+,d6
        beq rrrts
        move.l d6,(a0)
        move d5,d0
        swap d0
        move #$60,d0
        move.l d0,32(a0)
        lea texter,a0
        jsr gpurun
        jsr gpuwait
        lea in_buf,a0
        add #30,d5
        dbra d7,dropts2
        rts  

; *******************************************************************
; text2_setup
; *******************************************************************
text2_setup:
        lea in_buf,a0
        move.l #bfont,4(a0)
        bra tsu

; *******************************************************************
; text_setup
; *******************************************************************
text_setup:
        lea in_buf,a0
        move.l #afont,4(a0)    ;font data structure
tsu:
        move.l #0,8(a0)
        move.l #0,12(a0)    ;dropshadow vector
        move.l #$10000,d0
        move.l d0,16(a0)
        move.l d0,20(a0)    ;text scale
        move.l #0,24(a0)
        move.l #0,28(a0)    ;text shear
        move.l #0,36(a0)    ;text mode 1 (With Dropshadow)
        rts

; *******************************************************************
; textlength
; *******************************************************************
textlength:
        move.l a3,a2
        move #0,d0
tlengt:
        move.b (a2)+,d1
        beq rrrts
        add #17,d0
        bra tlengt

; *******************************************************************
; g_textlength
; *******************************************************************
g_textlength:
        move.l d2,a2  ;d2.l points to 0term text
        move #0,d7
        move 6(a1),d6
        add #2,d6
g_tlengt:
        move.b (a2)+,d5
        beq g_otit
        add d6,d7
        bra g_tlengt
g_otit:
        lsr #1,d6
        sub d6,d7
        rts

; *******************************************************************
; init_tbb
;
; init 16-position circular trailback buffer. Store x.l, y.l, z.l, ang.l.
; *******************************************************************
init_tbb:

        lea screen5,a0    ;use it, spare ram is all
        move #31,d0
itbb:
        clr.l (a0)+    ;Z FIRST (zero Z means no data!)
        clr.l (a0)+
        clr.l (a0)+
        clr.l (a0)+
        dbra d0,itbb
        clr tbbptr    ;trailback buffer ptr
        rts

; *******************************************************************
; run_tbb
; *******************************************************************
run_tbb:
        tst pawsed
        bne rrrts
        move tbbptr,d0
        bsr get_tbb
        move.l d1,(a3)+
        move.l d2,(a3)+
        move.l d3,(a3)+
        move.l d4,(a3)+
        add #1,tbbptr
        rts

; *******************************************************************
; get_tbb
; *******************************************************************
get_tbb:
        and #$1f,d0
        asl #4,d0
        lea screen5,a3
        lea 0(a3,d0.w),a3
        rts

; *******************************************************************
; tuntest
; Unused code
; *******************************************************************
tuntest:
        move.l #rrts,routine
        jsr InitBeasties
        bsr settrue

; *******************************************************************
; _tunn
; Initialize and run the bonus level where we fly through space with a
; crosshair and navigating through wormholes/tunnels.
; *******************************************************************
_tunn:
        clr sync
        clr.l iacon+4
        clr.l rot_cum
        move #200,psmsgtim
        move #4,modnum
        clr.l pongyv
        move bolev2,d0
        move d0,d1  ;get diff level
        and #$07,d1
        lsl #2,d1
        lea tunnels,a0
        move.l 0(a0,d1.w),pongx  ;set course no.
        and #$30,d0
        lsr #4,d0
        move d0,pongyv
        add #1,bolev2

        jsr itunnel
        clr.l pongzv
        move #-1,pongxv
        move #-1,victree
        clr.l iacon
        clr.l iacon+4
        clr.l vp_x
        clr.l vp_y
        clr.l vp_z
        clr.l vp_xtarg
        clr.l vp_ytarg
        clr.l vp_ztarg
        bsr init_tbb
        move.l #$30000,ltail
        clr pgenphase
        clr tunadd
        move #63,tuncnt
        move #1,noxtra
        move.l #tunrun,routine
        move.l #tundraw,demo_routine
        move pauen,_pauen
        bsr gogame
        clr noxtra
        move #-1,beasties+140
        tst z
        bne rrrts
        bsr ofade
        
        move.l #$ffffffff,warp_flash
        rts
 
; *******************************************************************
; tunrun
; A 'routine' routine.
; Is this for managing a player doing a full roll of the tunnel in some way?
; *******************************************************************
tunrun:
        btst.b #3,sysflags  ;look for ro-con
        beq sjoycon
        move.l rot_cum,d0
        clr.l rot_cum
        add.l d0,iacon+4
        move.l iacon+4,d0
        add.l d0,iacon
        bra weewee
        
sjoycon:
        move.b pad_now+1,d0
        rol.b #2,d0
        and #$03,d0
        lea iacon,a0
        jsr inertcon    ;control roll of tunnel on jpad
weewee:
        bsr run_pgens    ;run the sidewall pattern generators
        tst victree
        bmi vpxfo
        clr.l vp_x
        clr.l vp_y
vpxfo:
        jmp vp_xform

run_pgens:
        sub #1,pgenctr
        bpl rpg1
        move #800,pgenctr
        lea pgens,a0
        move #1,d7
        tst victree
        bmi rndpgs
        addq #1,d7
rndpgs:
        jsr rannum
        and #$f,d0
        add #1,d0
        asl #2,d0
        move d0,2(a0)
        jsr rannum
        and #$7,d0
        add #1,d0
        asl #2,d0
        move d0,6(a0)
        jsr rannum
        lsl #1,d0
        move d0,10(a0)
        jsr rannum
        and #$7f,d0
        add #$10,d0
        move d0,14(a0)
        lea 16(a0),a0
        dbra d7,rndpgs

rpg1:
        move tunadd,d0
        add d0,pgenphase
        lea pgens,a0
        move #1,d7    ;2 blocks of these
        tst victree
        bmi r_pgens    ;(could be threee)...
        addq #1,d7
r_pgens:
        move (a0),d0
        move 2(a0),d1
        add d1,d0
        bmi bnc1
        cmp #$fff,d0
        ble nbnc1
bnc1:
        neg d1
        add d1,d0
nbnc1:
        move d0,(a0)
        move d1,2(a0)    ;run colour vector 1
        move 4(a0),d0
        move 6(a0),d1
        add d1,d0
        bmi bnc2
        cmp #$fff,d0
        blt nbnc2
bnc2:
        neg d1
        add d1,d0
nbnc2:
        move d0,4(a0)
        move d1,6(a0)    ;colour vector 2
        move 10(a0),d0
        add d0,8(A0)    ;phasechange
        move 14(a0),d0
        add d0,12(a0)    ;#pixelchange
        lea 16(a0),a0
        dbra d7,r_pgens
        rts


; *******************************************************************
; tundraw
; Draw the bonus level tunnel and crosshair.
; *******************************************************************

tundraw:
        move.l #0,gpu_mode
        move.l #(PITCH1|PIXEL16|WID384|XADDPHR),dest_flags  ;screen details for CLS
        move.l #$0,backg
        lea fastvector,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait

        lea in_buf,a0      ;This is Starplane code
        move.l #32,(a0)      ;no. of stars
        move.l #84,20(a0)    ;seed Y
        move.l #1,gpu_mode

        move sfyo,d7
        move sfxo,d3
        move #15,d6
        move d7,d5
        move d3,d2
        move.l #$70,d4
stalp:
        move d7,d0
        lsr #5,d0
        and.l #$1ff,d0
        add d5,d7
        move.l d0,12(a0)
        move d3,d0
        lsr #5,d0
        and.l #$1ff,d0
        add d2,d3
        move.l d0,8(a0)
        move d6,d0
        addq #1,d0
        move.l d0,16(a0)
        movem.l d4-d7,-(a7)
        move d5,d7
        lsl #2,d6
        add d6,d7
        bsr pulser
        lsl #8,d6
        or d6,d4
        move.l d4,4(a0)
        movem.l (a7)+,d4-d7
        add #$08,d4
        move.l a0,-(a7)
        lea equine2,a0
        jsr gpurun      ;do starplane
        jsr gpuwait
        move.l (a7)+,a0
        dbra d6,stalp


        move pongyv,d6

inst:
        move pongzv,d0      ;get current CB pointer
        and #$3f,d0      ;limit to the buffer
        move d0,d4
        asl #4,d0      ;point at structures 16 bytes long
        lea field1,a1      ;they start at field1
        lea 0(a1,d0.w),a1    ;pointing to new furthest-seg
        lea 4(a1),a1      ;skip global pos/phase
        lea pgens,a2      ;point to pgen data
        move #1,d7
        move #0,d6      ;do two lots of...
        tst victree
        bmi xpgdat
        move #2,d7
        move #$80,d6
xpgdat:
        move (a2),d0
        move.b d6,3(a1)
        clr d6
        move 4(a2),d1      ;get x and y colourspace vector
        lsr #8,d0
        lsr #4,d1
        and #$f0,d1
        or d0,d1      ;combine these vectors
        move.b d1,2(a1)      ;set pattern colour
        move.b 8(a2),(a1)    ;set current phase
        move.b 12(a2),d0    ;get #-pixels
        and #$3f,d0
        sub #$1f,d0
        bpl dingy
        neg d0
dingy:
        add #$10,d0
        move.b d0,1(a1)      ;set #-pixels
        lea 4(a1),a1
        lea 16(a2),a2
        dbra d7,xpgdat      ;loop for both pg's  

        tst pawsed
        bne nomo

        tst victree
        bpl over

        move.b pgenphase,3(a1)
        move pongzv,d0
        and #$0f,d0
        move #$8f,d1
        cmp #$0d,d0
        ble sttoat
        move #$f0,d1
        cmp #$0f,d0
        bne sttoat
        add.l #$800,pongyv
        move.l pongx,a3
        move.b (a3)+,d0
        ext d0
        move.l a3,pongx
        asl #6,d0
        move d0,tunadd
        sub #1,tuncnt
        bpl sttoat
        move #300,victree
        jsr sayex    ;say Excellent

        cmp #90,cwave
        bge sttoat      ;Warp not after l90
        add #4,cwave
        add #4,cweb      ;Warp 4 levels
        movem.l d0-d7/a0-a6,-(a7)
        move.l gpu_screen,d0
        move.l d0,-(a7)
        move.l #screen3,a0
        move #64,d1
        move #384,d2
        move #48,d3
        move #$000,d4
        jsr BlitBlock    ;clear the crosshair that was already there
        move.l #screen3,gpu_screen
        lea warpytxt,a0
        lea afont,a1
        move #75,d0
        jsr centext    ;display msg 'Warp 5 Levels'
        lea beasties+128,a0
        move.l #screen3+(768*64),d2
        move #SIDE,d0
        sub palside,d0
        move #TOP+202+180,d1
        add paltop,d1
        swap d0
        swap d1
        move #8,d5
        move #$24,d3
        move #$24,d4
        jsr makeit_trans
        move.l (a7)+,d0
        move.l d0,gpu_screen
        movem.l (a7)+,d0-d7/a0-a6

sttoat:
        move.b d1,2(a1)
        move #$e240,(a1)

        tst pongxv
        bpl over

        add #8,d4
        and #$3f,d4
        lsl #4,d4
        lea field1,a1
        lea 12(a1,d4.w),a1    ;should be seg we're over

        move.b 3(a1),d0      ;get track position
        neg.b d0
        and #$ff,d0
        move iacon,d1      ;get current loc
        neg d1
        and #$ff,d1
        sub d0,d1      ;get distance between
        bpl xono
        neg d1        ;(absolute)
xono:
        cmp #$7f,d1
        ble xono2
        move #$7f,d2
        sub #$80,d1      ;hack for circular wrap
        sub d1,d2
        move d2,d1
xono2:
        cmp #$20,d1
        bgt notover  

        move.b #0,2(a1)      ;change colour of track
        move #$dc20,(a1)

        move ltail,d0
        lsr #3,d0
        add #7,d0
        jsr doscore


        move.l ltail,d0
        add.l #$8000,d0
        cmp.l #$1fffff,d0
        bgt over
        move.l d0,ltail
        bra over
notover:
        move.l ltail,d0
        sub.l #$10000,d0
        bmi odeer
        move.l d0,ltail
        bra over
odeer:
         move #$20,pongxv
        clr.l vp_xtarg
        clr.l vp_ytarg
over:
        add.l #$10000,pongzv
        
        dbra d6,inst

skippit:
nomo:
        lea in_buf,a0
        move.l #field1,(a0)    ;circ buffer base
        move.l #0,d0
        move.l d0,4(a0)      ;global Phase

        
        move.l pongzv,8(a0)
        move.l vp_x,12(a0)
        move.l vp_y,16(a0)
        move.l #2,gpu_mode
        jsr ssys
        lea bovine,a0
        jsr gpurun      ;do star tunnel
        jsr gpuwait

        tst pawsed
        bne restuff

        tst victree
        bpl restuff0


        move pongxv,d1
        bmi restuff  
        lea field1,a0
        move #$3f,d0
claps:
        move.b d1,3(a0)
        lea 16(a0),a0
        dbra d0,claps
        sub #1,pongxv
        bpl rrrts
        move #-1,x_end
        rts  

restuff0:
        add #6,iacon
        clr.l iacon+4
        move #$1f,ltail
restuff:

        move iacon,d0
        neg d0
        and.l #$ff,d0
        move #$ff,d3
        sub d0,d3
        move #webz-80,d1
        swap d1
        clr d1
        lea sines,a1
        move.b 0(a1,d3.w),d2
        add.b #$40,d3
        move.b 0(a1,d3.w),d3
        ext d2
        ext d3
        asr #3,d2
        asr #3,d3
        swap d2
        swap d3
        clr d2
        clr d3
        move.l #9,d4
        move.l #9,d5
        lea epyr,a1
        asr.l #1,d2
        move.l d2,d6
        neg.l d6
        move.l d6,vp_xtarg
        cmp.l #pausing,routine
        beq nmoo1
        add.l d6,sfxo
nmoo1:
        asr.l #1,d3
        move.l d3,d6
        neg.l d6
        move.l d6,vp_ytarg
        cmp.l #pausing,routine
        beq nmoo2
        add.l d6,sfyo
nmoo2:
        move.l d1,-(a7)
        move.l d2,-(a7)
        move.l d3,-(a7)
        move.l d0,-(a7)
;  bsr drawsolidxy
        move.l (a7)+,d4
        move.l (a7)+,d3
        move.l (a7)+,d2
        move.l (A7)+,d1
        bsr run_tbb    ;store position in the tbb

        lea in_buf,a0


        move.l #3,gpu_mode
        move.l #0,d4
        move tbbptr,d0
        sub #1,d0
        move frames,d7
pobjs:
        move.l d1,12(a0)
        move d0,-(a7)
        bsr get_tbb
        move (a7)+,d0
        move.l (a3),d2
        beq nxtox
        move.l 4(a3),4(a0)
        move.l 8(a3),8(a0)
        move.l 12(a3),32(a0)
        move.l a0,-(a7)
        bsr pulser
        and.l #$ff,d6
        move.l d6,28(a0)
        move.l #pobj,(a0)  ;Particle Object draw - pointer to p.obj data struct
        tst victree
        bmi xxxooo
        move.l #pobj3,(a0)
xxxooo:
        move.l #3,16(a0)  ;XYZ scales
        move.l #3,20(a0)
        move.l #3,24(a0)
        cmp #0,d4
        bne snoxy
        move.l #pobj2,(a0)
        move d0,d2
        jsr rannum
        and.l #$07,d0
        add #1,d0
        move.l d0,16(a0)
        move.l d0,20(a0)
        move.l d0,24(a0)
        jsr rannum
        and.l #$1f,d0
        move.l d0,32(a0)
        move.l #$88,28(a0)  
        move d2,d0
snoxy:
        lea bovine,a0
        jsr gpurun
        jsr gpuwait
        move.l (a7)+,a0
nxtox:
        addq #1,d4
        sub.l #$10000,d1
        sub.b #$08,d7
        sub #1,d0  
        cmp ltail,d4
        ble pobjs
        tst psmsgtim
        beq xam
        lea warp2msg,a0
        lea cfont,a1
        move #180,d0
        tst pal
        beq gnopal
        add palfix2,d0
gnopal:
        jsr centext
        sub #1,psmsgtim

xam:
        tst victree
        bmi ddonki

        bsr bobo

        tst pawsed
        bne ddonki
        sub #1,victree
        bpl ddonki
        move #1,x_end
ddonki:
        jmp donki


; *******************************************************************
; nxtpage
; Unused code
; *******************************************************************
nxtpage:
        move.l #screen3,gpu_screen
        jsr clearscreen
        move #40,d0
        move #20,d1
        jsr pager
        move d7,-(a7)
        bsr premess
        jsr settrue3
        bsr wnb
        move.l #text_o_run,routine
        move (a7)+,d7
        rts

; *******************************************************************
; premess
; *******************************************************************
premess:
        lea premes1,a0
        lea cfont,a1
        move #200,d0
        tst pal
        beq defnotpal
        add #10,d0
defnotpal:
        tst d7
        bne centext
        lea premes2,a0
        jmp centext

; *******************************************************************
; text_o_run
; A 'routine' routine.
; *******************************************************************
text_o_run:
        move.l grndvel,d0
        add.l d0,grnd
        move.l pad_now,d0
        and.l #allbutts,d0
        beq rrrts
        move.l d0,butty
        move.l #rrts,routine
        move #1,x_end
        rts



; *******************************************************************
; text_o_draw
; Unused code
; *******************************************************************
text_o_draw:
        move.l #0,gpu_mode
        move.l #(PITCH1|PIXEL16|WID384|XADDPHR),dest_flags  ;screen details for CLS
        move.l #$0,backg
        lea fastvector,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait

        move m7y,d1
        and #$1ff,d1
        sub #$ff,d1
        bpl todr1
        neg d1
todr1:
        sub #$7f,d1
        add #$a0,d1
        swap d1
        clr d1
        

        move.l #1,gpu_mode
        lea in_buf,a0
        move.l #pic4,(a0)+
        move.l m7z,(a0)+
        move grnd,d0
        and.l #$1ff,d0
        swap d0
        move.l d0,(a0)+
        move.l m7x,d0
        move.l d0,(a0)+
        move.l #0,(a0)+
        move.l d1,(a0)+
        move frames,d0
        and.l #$ff,d0
        move.l d0,(a0)+
        lea bovine,a0
        jsr gpurun      ;do mode7 screen
        jsr gpuwait

        lea in_buf,a0
        move.l m7x,d0
        neg.l d0
        move.l d0,12(a0)
        lea bovine,a0
        jsr gpurun      ;do mode7 screen
        jsr gpuwait

        add #1,m7y

        rts

; *******************************************************************
; Do a bonus game?
; *******************************************************************
m7test2:
        move #1,psycho
        move.l #$ff0000,delta_i
        move #$03,pongz
        move.l #$a000,grndvel
        move #3,rocnt
        move bolev3,d0  
        add #1,bolev3
        bra m7go

; *******************************************************************
; Do a bonus game?
; *******************************************************************
m7scr:
        clr psycho
        move #1,pongz
        move.l #$e90000,delta_i
        move.l #$8000,grndvel
        move bolev1,d0
        add #1,bolev1
m7go:
        move.l #$200,yespitch
        move #1,mfudj
        clr.l rot_cum
        clr.l ixcon+4
        clr.l roach
        move #1,yesnum
;  move #-1,db_on
        clr sync
        move #3,modnum
        move d0,d1  ;get diff level
        and #$07,d1
        lsl #2,d1
        lea courses,a0
        move.l 0(a0,d1.w),cg_ptr  ;set course no.
        lsl #1,d0
        lsl #8,d0
        and.l #$ffff,d0
        add.l d0,grndvel    ;speed up in levels  


        jsr initobjects
        jsr initprior

        move.l #m7test,demo_routine
        move.l #gamefx,fx
        jsr rs400
        move #26,warp_add  ;Set stuff unique to this Mode
        move.l #5,warp_count  ;A good stiff starf with big streaks
        move.l #$30000,vp_sfs

        move.l #$40000,m7x
        move.l #$a00000,m7y
        move.l #$400000,m7yv
        move.l #$140000,m7z
        move.l #$80000,iycon
        move.l #$80000,iycon+4

        move.l #screen3,a0
        clr d0
        move #64,d1
        move #384,d2
        move #48,d3
        move #$000,d4
        jsr BlitBlock
        jsr clearscreen
        lea beasties+128,a0
        move.l #screen3+(768*64),d2
        move #SIDE,d0
        sub palside,d0
        move #TOP+202,d1
        add paltop,d1
        tst pal
        beq nopalll
        add #26,d1
nopalll:
        swap d0
        swap d1
        move #8,d5
        move #$24,d3
        move #$24,d4
        jsr makeit_trans    ;put up some TC screen for cross hair display

        move #250,d0
        move #110,d1
        move #40,d2
        move #39,d3
        move #172,d4
        move #64,d5
        move.l #pic2,a0
        move.l #screen3,a1
        jsr CopyBlock


        clr.l vp_x
        move.l #$4000,vp_y
        

        clr.l vp_z

        clr cg_tim    ;turn on course generator
        move.l #m7run,routine
        move pauen,_pauen
        bsr gogame
        move #-1,beasties+140
        tst z
        bne rrrts  
        move.l #$ffffffff,warp_flash
        move.l #2,warp_count
        clr.l vp_x
        clr.l vp_y
        clr.l vp_z
        clr _pauen
        tst x_end
        bmi rrrts    ;return -1 means we failed

        move.l #screen3,a0
        move #64,d1
        move #384,d2
        move #48,d3
        move #$000,d4
        jsr BlitBlock    ;clear the crosshair that was already there
        
        jsr sayex    ;say Excellent

        move.l #screen3,gpu_screen
        lea warpytxt,a0
        lea afont,a1
        move #75,d0
        jsr centext    ;display msg 'Warp 5 Levels'
        cmp #90,cwave
        bge sttoat2      ;Warp not after l90
        add #4,cwave
        add #4,cweb  

        lea beasties+128,a0
        move.l #screen3+(768*64),d2
        move #SIDE,d0
        sub palside,d0
        move #TOP+202+180,d1
        add paltop,d1
        swap d0
        swap d1
        move #8,d5
        move #$24,d3
        move #$24,d4
        jsr makeit_trans
sttoat2:

        move #11,d0
        jsr doscore    ;give player 20,000
        move.l #vicbon,demo_routine  ;display Victory Bonus screen
        move.l #vicrun,routine
        clr pongxv
        clr v_on
        clr l_on
        move #400,pongx
        move pauen,_pauen
        bsr gogame
        move #-1,beasties+140
        tst z
        bne rrrts
        bsr ofade
        move.l #$ffffffff,warp_flash
        move.l #2,warp_count
        rts

; *******************************************************************
; Display the victory bonus?
; *******************************************************************
vicbon:
        move frames,d7
        lsr #2,d7
        and #$7f,d7
        sub #$3f,d7
        bpl vicbon1
        neg d7
vicbon1:
        sub #$1f,d7
        and.l #$ff,d7  ;angle for this
        bsr versiondraw    ;gets us the pyramid and feedback
        move.l #$220000,pongz
        add.b #1,pongxv
        move.b pongxv,d0
        add.b #$40,d0
        move.b d0,pongxv+1
bobo:
        lea pic,a2
        move.l #$6e0089,d0
        move.l #$4400b2,d1
        move.l #$6000,d5
        move frames,d6
        and #$ff,d6
        lea sines,a0
        move.b 0(a0,d6.w),d2
        add.b #$40,d6
        move.b 0(a0,d6.w),d3
        ext d2
        ext d3
        ext.l d2
        ext.l d3
        asl.l #5,d2
        asl.l #6,d3
        move.l d2,d6
        asl.l #1,d6
        add.l d6,d5
        move.l d5,d4
        move.l #$220000,d6
        move.l #$e50000,delta_i
        bsr yh
        rts

vicrun:
        tst pawsed
        bne rrrts
        sub #1,pongx
        bpl rrrts
        move #-1,x_end
        rts


; *******************************************************************
; m7run
; A 'routine' routine.
; Control the movement in some way
; *******************************************************************
m7run:
        btst.b #3,sysflags    ;are we on the rotary controller?
        beq wjoy

        move.l rot_cum,d0
        clr.l rot_cum
        lea ixcon,a0
        add.l d0,roach
        jsr iii        ;do x control off the rotary thang
        move.l (a0),d0
        move.l d0,m7y
        sub.l #$a00000,d0
        move.l d0,vp_x
        move.b pad_now,d0
        rol.b #3,d0      ;get button A as low bit
        and #1,d0
        move.b pad_now+2,d1
        rol.b #4,d1
        and #2,d1
        or d1,d0      ;combine buttons a and c for up/down
;  bra do_yy
        lea iycon,a0
        jsr inertcon
        move.l (a0),d0
        move.l d0,d1
        asr.l #3,d1
        move.l d1,vp_y
        neg.l d0
        move.l d0,m7x  
        move.b pad_now+5,d0
        rol.b #2,d0
        and #$03,d0
        lea ixcon,a0
        jsr inertcon
        move.l (a0),d0
        move.l d0,m7y
        sub.l #$a00000,d0
        move.l d0,vp_x
        move.b pad_now+5,d0
        bra do_yy


wjoy:
         move.b pad_now+1,d0
        rol.b #2,d0
        and #$03,d0
        lea ixcon,a0
        jsr inertcon
        move.l (a0),d0
        move.l d0,m7y
        sub.l #$a00000,d0
        move.l d0,vp_x  ;Inertial-control of X

        move.b pad_now+1,d0
do_yy:
        rol.b #4,d0
        and #$03,d0
        lea iycon,a0
        jsr inertcon
        move.l (a0),d0
        move.l d0,d1
        asr.l #3,d1
        move.l d1,vp_y
        neg.l d0
        move.l d0,m7x  ;Inertial-control of Y

        move.l grndvel,d0
        add.l d0,grnd
        bsr dowf
        jsr rob
        bsr cg
        tst psycho
        beq rrrts
        cmp #$f0,delta_i
        beq rrrts
        move.l delta_i,d0
        sub.l #$c000,d0
        and.l #$ffffff,d0
        move.l d0,delta_i
        rts

; *******************************************************************
; cg
; *******************************************************************
cg:
        move.l grndvel,d0
        sub.l d0,cg_cnt
        bpl rrrts
;  add #$10,cg_cnt
        add #$0c,cg_cnt
        tst cg_tim
        bmi rrrts    ;check for cg turned off
        sub #1,cg_tim
        bpl rrrts
        move.l cg_ptr,a5
        move.b (a5)+,d0
        and #$ff,d0
        move d0,cg_tim  ;get time to next gap
        move.b (a5)+,d0
        move.b (a5)+,d1  ;get x and y
        ext d0
        ext d1    ;make them signed
        tst psycho
        beq nflippit
        neg d0
        move #8,cg_tim  ;psycho courses are never as clost together as ring ones
nflippit:
        swap d0
        swap d1
        clr d0
        clr d1    ;make signed 16:16 XY co-ordinates
        move.b (a5)+,d2  ;get type in d2
        bpl slegg
        move #-1,cg_tim  ;shutdown; end of wave
        rts
slegg:
        and #$ff,d2
        move.l a5,cg_ptr  ;save pointer
        move.l freeobjects,a6  ;get pointer to a new Thang
        move.l #-11,(a6)  ;Polyo DRAW_GATE
        move.l d0,4(a6)
        move.l d1,8(a6)    ;X and Y position
        move.l #$ff0000,12(a6)  ;z=255
        move d2,42(a6)
        move #1,34(a6)
        clr 50(a6)
        move #27,54(a6)    ;type is run-gate
        clr 20(a6)
        move.l a6,a0
        sub #1,tunc
        bpl isso
        move #1,20(a6)
        move #2,tunc
isso:
        jmp insertobject  ;make it

; *******************************************************************
; run_gate
; A member of the draw_vex list.
; *******************************************************************
run_gate:
        add #1,28(a6)
        move.l grndvel,d0
        sub.l d0,12(a6)
        cmp #2,12(a6)
        bgt rrrts
        move vp_x,d0
;  neg d0
        sub 4(a6),d0
        bpl lamag1
        neg d0
lamag1:
        cmp #8,d0
        bpl mist
        move d0,d1
        move vp_y,d0
;  neg d0
        sub 8(a6),d0
        bpl lamag2
        neg d0
lamag2:
        cmp #8,d0
        bpl mist 
        add d1,d0
        move d0,-(a7)
        move #$20,d1
        jsr rannum
        btst #0,d0
        bne lnpt
        neg d1
lnpt:
        lea gatefx,a0
        move 42(a6),d0
        asl #2,d0
        move.l 0(a0,d0.w),a0
        jsr (a0)
        move yesnum,d0
        add #26,d0
        move d0,sfx
        move.l yespitch,sfx_pitch
        move #100,sfx_pri
        jsr fox
        move.l yespitch,d0
;  add.l #2,d0
        move.l d0,sfx_pitch
        move #100,sfx_pri
        jsr fox
        tst psycho
        beq nanna
        move.l #$1c0000,delta_i
        add #1,rocnt
        move rocnt,d0
        and #$07,d0
        sub #3,d0
        move d0,pongz
        move (a7)+,d0
        lsr #2,d0
        add #4,d0
        jsr doscore
        bra ennd
nanna:
        move.l a6,-(a7)
        move.l a6,a5
        move.l freeobjects,a6  ;make a score Thang
        move.l 4(a5),4(a6)
        add d1,4(a6)    ;random displace score Thang to L or R
        move.l 8(a5),8(a6)
        move.l 12(a5),12(a6)
        clr 50(a6)
        add #$ff,12(a6)
        move.l a6,a0
        jsr insertobject
        move.l (a7)+,a0
        move (a7)+,d0
        move.l a0,-(a7)
        lsr #2,d0
        cmp #2,d0
        ble llaleg
        move #2,d0
llaleg:
        neg d0
        add #2,d0
        bsr xbon 
;  bsr xbonx
        move.l (A7)+,a6
        bra ennd
mist:
;  bra ennd
        clr _pauen
        move.l #failfade,demo_routine
        move.l #failcount,routine
        move #150,pongx
        move #1,pongz
        move.l #$f80000,delta_i
ennd:
        move #1,50(a6)
        clr 54(a6)
        rts


; *******************************************************************
; fade
;
; go into FADE after merging screen3 to current screen and turning off BEASTIES+64
; *******************************************************************
fade:

        tst beasties+76
        bmi ofade
        move.l #screen3,a0
        move.l gpu_screen,a1
        moveq #0,d0
        moveq #0,d1
        move #384,d2
        move #240,d3
        add palfix1,d3
        moveq #0,d4
        moveq #0,d5
        tst mfudj
        beq pmf2
        sub #8,d3
pmfade:
        tst mfudj
        beq pmf2 
        add #8,d5
        clr mfudj
pmf2:
        jsr MergeBlock
        move #-1,beasties+76

; *******************************************************************
; ofade
; *******************************************************************
ofade:
;  move pauen,-(a7)
        clr _pauen      ;can't pause in fade
        move.l #ffade,demo_routine
        move.l #failcount,routine
        move #150,pongx
        jsr rannum
        and #$7,d0
        sub #$03,d0
        and #$ff,d0
        move d0,pongz
;  clr pongz
        move.l #$f80000,delta_i
        move z,-(a7)
        clr z
        bsr gogame
        move.l #screen3,a0
        jsr clrscreen
        move (a7)+,z
;  move #-1,db_on
;  move #1,screen_ready
        move #1,sync
;  move (a7)+,pauen
        rts

gatefx:
        dc.l rrts,zup,zdn,spup,vicend

zup:
        move.l #-$80000,iycon+4
        rts
zdn:
        move.l #$80000,iycon+4
        rts
spup:
        move.l d1,-(a7)
        add.l #5,yespitch
        eor #1,yesnum
        move.l grndvel,d0
        asr.l #3,d0
        add.l d0,grndvel
        tst psycho
        bne agagg
        lea m7msg1,a0
        clr.l d0
        move.l #$8000,d1
        jsr setmsg
agagg:
        move.l (a7)+,d1
        rts
vicend:
        move.l #failfade,demo_routine
        move.l #viccount,routine
        move #150,pongx
        clr.l pongz
        move.l #$f80000,delta_i
        rts


; *******************************************************************
; draw_gate
; A member of the solids list.
; *******************************************************************
draw_gate:
        tst psycho
        bne dopsy
        move 8(a6),d4
        move vp_y,d5
        and #$8000,d4
        and #$8000,d5  ;extract sign bits
        cmp d4,d5
        bne rrrts  ;do not draw objects 'underneath'

dopsy:
        move 42(a6),d4  ;get Type
        beq noicon  ;Type zero has no icon
        lea icondraws,a0
        asl #2,d4
        move.l 0(a0,d4.w),a0
        movem.l d0-d3,-(a7)
        jsr (a0)
        movem.l (a7)+,d0-d3
        bra noicon  ;call icon draw routine

icondraws:
        dc.l rrts,arup,ardn,zappy,pyrri
ardn:
         move.l #$80,d0
        bra rup
arup:
        clr.l d0
rup:
        lea arr,a1
zqz:
        move.l #9,d4
        move.l #9,d5
        bsr drawsolidxy
        jmp gpuwait

zappy:
        clr d6  
        lea dchev,a1
        clr.l d0
        bra zqz
pyrri:
         lea epyr,a1
        clr.l d0
        bra zqz  

; *******************************************************************
; dsclaw
; A member of the draw_vex list.
; *******************************************************************
dsclaw:
        move.l 4(a6),d2
        sub.l vp_x,d2
        move.l 8(a6),d3
        sub.l vp_y,d3
        move.l 12(a6),d1
        sub.l vp_z,d1
        move 28(a6),d0
        and.l #$ff,d0
        move.l 16(a6),d6
        lsl.l #3,d6
        swap d6
        and #$07,d6
        cmp #95,40(a6)
        bne snop2
        add #8,d6
snop2:
        lsl #2,d6
        lea sclaws,a1
        move.l 0(a1,d6.w),a1
        bra zqz

; *******************************************************************
; noicon
; *******************************************************************
noicon:
        tst psycho
        beq polygate

        move.l #$130000,d4
        move.l #128,d3
        move.l #6,gpu_mode
        lea in_buf,a0
        move.l d3,(a0)+    ;# pixels per ring
        move.l 4(A6),d0
        sub.l vp_x,d0
        move.l d0,(a0)+
        move.l 8(a6),d0
        sub.l vp_y,d0
        move.l d0,(a0)+
        move.l 12(a6),d0
        sub.l vp_z,d0
        move.l d0,(a0)+  ;XYZ position
        move frames,d7
        asl #1,d7
        bsr pulser
        and.l #$0f,d6
        move.l d6,(A0)+  ;colour
        move.l d4,(a0)+  ;radius 16:16
        clr d0
        swap d0
        move.l d0,(a0)+    ;phase
        lea xparrot,a0
        jsr gpurun      ;do clear screen
        jmp gpuwait

polygate:
        move.l #18,d4
        move.l #9,d5
        lea gibbits,a1
        move 20(A6),d6
        asl #2,d6
        move.l 0(a1,d6.w),a1
        move #7,d7
        move #$20,d6
        bra s_multi

gibbits:
        dc.l g1,g2  


; *******************************************************************
; viccount
; A 'routine' routine
; *******************************************************************
viccount:
        sub #1,pongx
        bpl rrrts
        move #1,x_end
        move #1,screen_ready
        rts

; *******************************************************************
; failcount
; A 'routine' routine
; *******************************************************************
failcount:
        sub #1,pongx
        bpl rrrts
        move #-1,x_end
        move #1,screen_ready
        rts

; *******************************************************************
; ffade
; A demo_routine
; *******************************************************************
ffade:
        add #1,pongy
        move pongy,d0
        and #$03,d0
        bne failfade
        tst.b pongz+1
        beq failfade
        bmi ffinc
        sub.b #2,pongz+1
ffinc:
        add.b #1,pongz+1
failfade:
        move.l #(PITCH1|PIXEL16|WID384),d0
        move.l d0,source_flags
        move.l d0,dest_flags
        lea in_buf,a0
        move pongz,d0
        and.l #$ff,d0
        move.l cscreen,(a0)    ;source screen is already-displayed screen
        move.l #384,4(a0)
        move.l #240,d1
        add palfix1,d1
        move.l d1,8(a0)    ;X and Y dest rectangle size
        move.l #$1f4,12(a0)
        move.l #$1f4,16(a0)    ;X and Y scale as 8:8 fractions
        move.l d0,20(a0)      ;initial angle in brads
        move.l #$c00000,24(a0)    ;source x centre in 16:16
        move.l #$780000,d0
        add.l palfix3,d0
        move.l d0,28(a0)    ;y centre the same
        move.l #$0,32(a0)    ;offset of dest rectangle
        move.l delta_i,36(a0)    ;change of i per increment
        move.l #2,gpu_mode    ;op 2 of this module is Scale and Rotate
        move.l #demons,a0
        jsr gpurun      ;do it
        jmp gpuwait

; *******************************************************************
; m7test
; *******************************************************************
m7test:
        tst psycho
        beq npsu1

        move.l #(PITCH1|PIXEL16|WID384),d0
        move.l d0,source_flags
        move.l d0,dest_flags
        lea in_buf,a0
        move pongz,d0
        and.l #$ff,d0
        move.l cscreen,(a0)    ;source screen is already-displayed screen
        move.l #384,4(a0)
        move.l #240,d1
        add palfix1,d1
        move.l d1,8(a0)    ;X and Y dest rectangle size
        move.l #$1d4,12(a0)
        move.l #$1e4,16(a0)    ;X and Y scale as 8:8 fractions
        move.l d0,20(a0)      ;initial angle in brads
        move.l #$c00000,24(a0)    ;source x centre in 16:16
        move.l #$780000,d0
        add.l palfix3,d0
        move.l d0,28(a0)    ;y centre the same
        move.l #$0,32(a0)    ;offset of dest rectangle
        move.l delta_i,36(a0)    ;change of i per increment
        move.l #2,gpu_mode    ;op 2 of this module is Scale and Rotate
        move.l #demons,a0
        jsr gpurun      ;do it
        jsr gpuwait


        lea in_buf,a0
        move.l #0,(a0)
        move.l #0,4(a0)
        move.l #$400000,8(a0)
        move frames,d7
        and #$7f,d7
        sub #$3f,d7
        bpl haha1
        neg d7
haha1:
        add #4,d7
        and.l #$ff,d7
        move.l d7,12(a0)  ;rad
        move.l #0,16(a0)  ;phase 1
        move frames,d7
        and.l #$ff,d7
        move.l d7,20(a0)  ;phase 2
        move.l #$80,24(a0)  ;pixels/ring
        move.l #$10,28(a0)  ;rings/sphere
        move.l #$2,32(a0)  ;pixel spacing
        move.l #$8,36(a0)  ;twist per ring
;  asl #1,d7  
        bsr pulser
        and.l #$f0,d6

        move.l d6,40(a0)  ;colour
        move frames,d0
        and #$7f,d0
        sub #$3f,d0
        bpl wwear
        neg d0
wwear:
        and.l #$ff,d0
        move.l d0,44(a0)
        move.l #4,gpu_mode
        lea bovine,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        jmp dob
        
        
; *******************************************************************
; npsu1
; *******************************************************************
npsu1:
         move.l #0,gpu_mode
        move.l #(PITCH1|PIXEL16|WID384|XADDPHR),dest_flags  ;screen details for CLS
        move.l #$0,backg
        lea fastvector,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait


        move.l #3,gpu_mode  ;mode 3 is starfield1
;  move.l vp_x,in_buf+4
;  move.l vp_y,in_buf+8
        clr.l in_buf+4
        clr.l in_buf+8
        move.l vp_z,d0
        add.l vp_sf,d0
        move.l d0,in_buf+12    ;pass viewpoint to GPU
        move.l #field1,d0
        move.l d0,in_buf+16  ;address off the starfield data structure
        move.l warp_count,in_buf+20
        move.l warp_add,in_buf+24
        lea fastvector,a0
        jsr gpurun    ;do gpu routine
        jsr gpuwait



        move.l #1,gpu_mode
        lea in_buf,a0
        move.l #pic4,(a0)+
        move.l m7z,(a0)+
        move grnd,d0
        and.l #$1ff,d0
        swap d0
        move.l d0,(a0)+
        move.l m7x,d0
        move.l d0,(a0)+
        move.l #0,(a0)+
        move.l m7y,(a0)+
        move frames,d0
        and.l #$ff,d0
        move.l d0,(a0)+
        lea bovine,a0
        jsr gpurun      ;do mode7 screen
        jsr gpuwait

        jmp dob      ;draw objects

        rts

; *******************************************************************
; Unused code
; *******************************************************************
;  move #$FF,d0
;  sub grnd,d0
;  and.l #$ff,d0
;  move.l d0,d1
;  swap d1
;  clr.l d2
;  sub.l vp_x,d2
;  move.l #$100000,d3
;  sub.l vp_y,d3
;  move.l #18,d4
;  move.l #9,d5
;  lea chevron,a1
;  move #7,d7
;  move #$20,d6
;  bsr s_multi


;  bra joyz
        rts

        lea in_buf,a0
        move.l #pic3,(a0)+
        move.l #$d0000,(a0)+
        move frames,d0
        and.l #$ff,d0
        swap d0
        move.l d0,(a0)+
        move.l #$770000,d1
        sub.l m7x,d1
        neg.l d1
        move.l d1,(a0)+
        move.l #0,(a0)+
        move.l m7y,(a0)+
        lea bovine,a0
        jsr gpurun      ;do mode7 screen
        jsr gpuwait

joyz:
        btst.b #5,pad_now
        beq skankzz
        lea m7yinc,a0
        lea m7ydec,a1
        lea m7zinc,a2
        lea m7zdec,a3
        bra gjoy


skankzz:
        lea m7incy,a0
        lea m7decy,a1
        lea rrts,a2
        lea rrts,a3
        bra gjoy

m7incx:
        cmp #$17f,m7y
        bgt rrrts
        add.l #$40000,m7y
        add.l #$40000,vp_x
        rts

m7decx:
        tst m7y
        bmi rrrts
        sub.l #$40000,m7y
        sub.l #$40000,vp_x
        rts

m7incy:
; cmp #$ef,m7x
;  bgt rrrts
        add #4,m7x
        sub.l #$4000,vp_y
        rts
m7decy:
; tst m7x
;  bmi rrrts
        sub #4,m7x
        add.l #$4000,vp_y
        rts
        
m7yinc:
        add #4,m7yv
        rts
m7ydec:
        sub #4,m7yv
        rts

m7zinc:
        add #4,m7z
        rts
m7zdec:
        sub #4,m7z
        rts

; *******************************************************************
; rndbox
; Unused code
; *******************************************************************
rndbox:
        move #300,d1
        jsr rand
        move d0,d2
        move #200,d1
        jsr rand
        move d0,d3
        move #319,d1
        sub d2,d1
        jsr rand
        add #1,d0
        move d0,d4
        move #255,d1
        sub d3,d1
        jsr rand
        add #1,d0
        move d0,d5
        movem d2-d5,-(a7)
        jsr rannum
        move #$44,d4
        lsl #8,d4
        move frames,d5
        and #$ff,d5
        or d5,d4
        movem (a7)+,d0-d3
        move.l #screen5,a0
        jmp fxBlock



swebtest:
;
; Check the current score for a HS, do text entries as necessary and display HST


; *******************************************************************
; dohiscores
; Do the hight scores.
; *******************************************************************
dohiscores:
        clr ud_score
        tst t2k
        beq showscores    ;only t2k gets here

        move.l score,a0
        jsr score2num

        lea hscom1,a0      ;point at compressed HS table
        clr d1        ;count of current scores
hiscch1:
        cmp.l (a0),d0    ;check against score
        bpl gotscore    ;he got a hiscore
        lea 8(a0),a0    ;next score slot
        addq #1,d1
        cmp #10,d1
        beq nohiscore    ;tuff titty, no HS
        bra hiscch1

gotscore:
        cmp #9,d1
        beq setscore    ;It is the bottom score, just replace it.
        lea hscom1+64,a1    ;Point to penultimate score
shftscore:
        move.l (a1),8(A1)
        move.l 4(a1),12(a1)  ;move it down
        cmp.l a1,a0    ;are we now pointed at where we wanna go?
        beq setscore
        lea -8(a1),a1
        bra shftscore    ;no so loop until we are

setscore:
        move.l d0,(a0)+  ;set us a new score
        movem.l d1/a0,-(a7)
        bsr getinitials
        movem.l (a7)+,d1/a0  ;get player initials
        tst z
        bne rrrts    ;abort if player did reset
        lea entxt,a1
        move (a1)+,(a0)+
        move.b (a1)+,(a0)+
        move t2k_high,d4
        move.b d4,(a0)+    ;this will be level got to

        tst d1
        bne setdsplay    
        bsr getbrag

        lea hscom1,a0
        lea 80(a0),a0
        move #9,d1
        lea entxt,a1
xntxx:
        move.b (a1)+,(a0)+
        dbra d1,xntxx


setdsplay:
        jsr eepromsave
        lea hscom1,a0
        jsr xscoretab
        jsr xkeys
        tst z
        bne rrrts
        bsr showscores
        rts
getinitials:
        move keyplay,d4  ;was player using a Key?
        bmi stditals    ;no
okey:
        lsl #2,d4
        lea keys,a0
        lea entxt,a1
        move #2,d5
        lea 0(a0,d4.w),a0  ;point at Key
grabkey:
        move.b (a0)+,(a1)+
        dbra d5,grabkey
        move.b #0,(a1)+    ;get player's Key signature
        move.b t2k_max+1,d0
        sub #1,d0
        bclr #0,d0
        move.b d0,(a0)    ;set player's Key level if it changed
        jmp xkeys    ;go update Key Table

nohiscore:
        cmp #15,t2k_max
        ble showscores    ;<15, no possibility of a Key
        move keyplay,d4
        bpl okey    ;Player was already using a Key, go update it
        move akeys,d0  ;No hi score but may get key
        cmp #3,d0
        blt newkey    ;Key available, ask for initials
        lea keys,a0
        move t2k_max,d0
        sub #1,d0
        bclr #0,d0
        move #3,d7
chkbig:
        move.b 3(a0),d1
        and #$ff,d1
        cmp d0,d1
        bmi newkey    ;Bigger, can replace
        lea 4(a0),a0
        dbra d7,chkbig
        bra setdsplay    ;Unlucky, nothin doin

newkey:
        move #3,ennum
        move #3,fw_sphere
        move.l #nkeym1,enl1
        move.l #nkeym2,enl2
        move.l #nkeym3,enl3
        bsr initgo  
        bra setdsplay
        
stditals:
        move #3,ennum
        move #3,fw_sphere
        move.l #conm1,enl1
        move.l #conm2,enl2
        move.l #conm3,enl3
initgo:
        bsr txenter
        cmp #16,t2k_max    ;Perhaps we were eligable to be given a Key.
        ble rrrts    ;No way dude! Come back when you can play!
        move akeys,d0    ;Get # of active keys.
        cmp #3,d0
        beq deerdeer    ;Tut tut. Full.
        bsr fplace    ;Find new place OR where you already were...
        tst d4
        beq setkey    ;New table place. Use SETKEY.
gakey:
        move.b 3(a0),d5
        and #$ff,d5
        cmp t2k_max,d5    ;Check level reached
        bmi setkey    ;Was greater so go and overwrite
        rts

setkey:
        move #2,d4
skey:
        move.b (a1)+,(a0)+  ;a1/a0 already set by FPLACE
        dbra d4,skey
        move.b t2k_max+1,d0
        sub.b #1,d0
        bclr #0,d0
        move.b d0,(a0)    ;set/renew Level
        jmp xkeys

deerdeer:
        bsr fplace    ;Look for possible Key already existing
        tst d4
        bmi gakey    ;You were lucky.
        lea keys,a0
        move #3,d4    ;Were we high enough to bop someone else?
        move #100,d3
lfbop:
        move.b 3(a0),d5
        and #$ff,d5
        cmp d5,d3    ;Look for lower
        bmi lfbop1
        move d5,d3
        move.l a0,a2    ;save address of lowest
        move d5,d6    ;save level of lowest
lfbop1:
        lea 4(a0),a0
        dbra d4,lfbop    ;look at all levels
        cmp #100,d3
        beq rrrts    ;No way, nothing lower than 100!
        cmp t2k_max,d3
        bpl rrrts    ;Unlucky, not good enough
        move.l a2,a0
        bra setkey    ;Got one, enter me in the Table O dudey


; *******************************************************************
; fplace
; *******************************************************************
fplace:
        lea keys,a0    ;Happy, happy, joy, joy.  You got an easy Key.
        lea entxt,a1
lkey0:
        move #2,d4
        move.l a1,a2
        move.l a0,a3
lkeys:
        move.b (a2)+,d5
        cmp.b (a3)+,d5
        bne snextk
        dbra d4,lkeys    ;If you fall out of here you already on the table.
        rts      ;return -1 in d4, a0
snextk:
        tst d0
        bpl lkey1    ;If you fall out of here a0 points to where you wanted and d4 is 0.
        clr d4
        rts
lkey1:
        sub #1,d0
        lea 4(a0),a0
        bra lkey0

; *******************************************************************
; getbrag
; *******************************************************************
getbrag:
        move #5,ennum
        move #2,fw_sphere
        move.l #conm4,enl1
        move.l #conm5,enl2
        move.l #conm6,enl3

; *******************************************************************
; txenter
; Enter some text
; *******************************************************************
txenter:
        move.l #rrts,routine
;  move #-1,db_on
        clr sync
        bsr wnb
;  bsr InitBeasties
        jsr initobjects
;  bsr hisettrue
        move #1,mfudj

        move ennum,enmax

        lea entxt,a0
        move.l a0,pongxv
        move ennum,d0    ;<<< no. of letters to enter this time
clent:
        move.b #'.',(a0)+
        subq #1,d0
        bne clent
        move.b #0,(a0)
        clr.l pongx    ;use as offset into legal text $

        move.l #screen3,gpu_screen
        jsr clearscreen  

        lea afont,a1
        move.l enl1,a0  
        move #40,d0
        jsr centext
        move.l enl2,a0  
        move #60,d0
        jsr centext
        lea cfont,a1
        move.l enl3,a0  
        move #80,d0
        jsr centext

        lea cfont,a1
        move.l #enlm1,a0  
        move #180,d0
        jsr centext

        move.l #enlm2,a0  
        move #190,d0
        jsr centext

        move.l #enlm3,a0  
        move #200,d0
        jsr centext

        lea fw_test,a0
        jsr init_fw

        jsr settrue3
        move.l #txendraw,demo_routine
        move.l #txen,routine
        bsr gogame
        bra fade

wnb:
        move.l pad_now,d0
        or.l pad_now+4,d0
        and.l #allbutts,d0
        bne wnb  
        rts

txen:
        jsr fw_run
        jsr rob      ;run f/w

        move.l pad_now,d0
        btst.b #3,sysflags
        beq flann
        move.l pad_now+4,d0
flann:
        and.l #allbutts,d0
        beq jtxen
        
        move pongx+2,d0
        lsr #6,d0
        and #$1f,d0  
        cmp #30,d0    ;this is DEL
        beq doolete
        cmp #31,d0
        bne ischaa  
        move.l pongxv,a0
        move.b #0,(a0)
        bra xxen

doolete:
        move ennum,d0
        cmp enmax,d0
        beq jtxen    ;if = cant delete nomore
        move.l pongxv,a0
        move.b #'.',(a0)  ;del the char displayed
        sub.l #1,pongxv
        add #1,ennum
        bra ddb

ischaa:
        sub #1,ennum
        bne nnnum
xxen:
        move #1,x_end
        move.l #rrts,routine
        rts
nnnum:
        add.l #1,pongxv
ddb:
        move #0,pongy
        bra inc_aa

jtxen:
        move.l #rrts,a0
        move.l a0,a1
        move.l #inchar,a2
        move.l #dechar,a3
        btst.b #3,sysflags
        bne up2e
        jmp gjoy
up2e:
        move.b pad_now+5,d0
        bra ggjj

inchar:
        move #4,pongy
inc_aa:
        move #16,pongz
        move.l #tgoto,routine
        rts
dechar:
        move #-4,pongy
        bra inc_aa
tgoto:
        jsr fw_run
        jsr rob    
        move pongy,d0
        ext.l d0
        add.l d0,pongx
        and.l #$7ff,pongx
        sub #1,pongz
        bne rrts
        move.l #txen,routine
        rts

; *******************************************************************
; txendraw
; *******************************************************************
txendraw:
        move.l #0,gpu_mode
        move.l #(PITCH1|PIXEL16|WID384|XADDPHR),dest_flags  ;screen details for CLS
        move.l #$0,backg
        lea fastvector,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        bsr WaitBlit

        jsr dob      ;draw Objects

        move #$1c,d5
        lea legal,a2    ;get legal chars
        move.l #192,d7
        sub.l pongx,d7    ;start position to draw chars
        sub.l #$100,d7
        lea bfont,a1    ;font to draw chars in
        move.l 4(a1),d1    ;char size
        move.l (a1),d2    ;char screen base      
sletloop:
        move.l d7,d0
        bmi sletooo
        cmp.l #384,d0
        bgt sletend
        move #192,d3
        sub d0,d3
        bpl slet01
        neg d3
slet01:
        swap d3
        clr d3
        lsr.l #5,d3
        add.l #$10000,d3
        move.b 0(a2,d5.w),d0  ;get char
        beq sletend
        and #$ff,d0
        sub #32,d0
        lsl #2,d0
        move.l 8(a1,d0.w),d0  ;get char address
        lea in_buf,a0
        move.l d2,(a0)    ;char base
        move.l d0,4(a0)    ;start pixel
        move.l d1,8(a0)    ;size
        move.l #$10000,12(a0)  ;xscale
        move.l d3,16(a0)  ;yscale
        move.l #0,20(a0)  ;xshear
        move.l #0,24(a0)  ;yshear
        move.l #1,28(a0)  ;centered mode
        move.l d7,d0
        sub.l #8,d0
        move.l d0,32(a0)  ;x
        move.l #$6a,d0
        tst pal
        beq hnotpal
        add.l #10,d0
hnotpal:
        move.l d0,36(a0)  ;y
        move.l #4,gpu_mode
        lea xparrot,a0    ;xparrot is REX w/o 3D
        jsr gpurun    ;do pixex draw
        jsr gpuwait
sletooo:
        add.l #$40,d7
        add #1,d5
        and #$1f,d5
        bra sletloop
sletend:
        cmp.l #rrts,routine
        beq stettin
        
        move.l pongxv,a0
        move pongx+2,d0
        lsr #6,d0
        and #$1f,d0
        move.b 0(a2,d0.w),(a0)  ;currently selected char to entered text slot

stettin:
        lea entxt,a0
        lea bfont,a1
        move #150,d0
        jmp centext

; *******************************************************************
; clvp
; *******************************************************************
clvp:
        clr.l vp_z
        clr.l vp_ztarg
clvpx:
        clr.l vp_x
        clr.l vp_y
        clr.l vp_xtarg
        clr.l vp_ytarg
        rts

; *******************************************************************
; hisettrue
; *******************************************************************
hisettrue:
        lea beasties,a0    ;set main screen to 16-bit
        move.l #screen2,d2
        move.l d2,gpu_screen
        move #TOP-16,d1
        bsr stru

hisettrue3:
        move #TOP-16,d1
        bra settrue33

; *******************************************************************
; showscores
; Display the high score table
; *******************************************************************
showscores:
        move.l #rrts,routine
        clr sync
        bsr InitBeasties
        bsr hisettrue
        move.l #screen3,gpu_screen
        jsr clearscreen      ;clear screen to be overlaid
        clr mfudj

        ; Paint the 'Top Guns' graphic
        move.l #pic5,a0  ; file images/beasty7.cry
        move.l #screen3,a1
        move #1,d0 ; x position in pic5
        move #1,d1 ; y position in pic5
        move #223,d2 ; width of block to copy
        move #79,d3  ; height of block to copy 
        move #70,d4  ; x pos of destination
        move #10+8,d5 ; y pos of destination
        jsr CopyBlock

        ; The high score table template
        lea hstab1,a4      ;get HS table to display

        lea cfont,a1
        move.l a4,a0      ;point at winners msg
        move #100+3,d0
        tst pal
        beq nnnpal
        add #10,d0
nnnpal:
        jsr centext

        lea cfont,a1
        lea 64(a4),a0
        move #8,d3
        move #120,d0
        tst pal
        beq ctl
        add #20,d0
ctl:
        movem.l d0/a0,-(a7)
        jsr centext
        movem.l (a7)+,d0/a0
        lea 64(a0),a0
        add #10,d0
        dbra d3,ctl
        bsr clvp


        move #$0f,weband
        clr webbase
        move cweb,-(a7)
        clr sf_on
        move #14,cweb    ;set Yaks head web  
        jsr initobjects
        move #1,tblock
        bsr setweb
        lea _web,a0
        move.l #webz,d0
        swap d0
        move.l d0,12(a0)
        move #1,34(a0)
        jsr hisettrue3
        move.l #swebby,demo_routine
        move #800,attime
        clr modnum
        clr auto
        bsr attr
        clr tblock
        move (a7)+,cweb
        move #1,sf_on
        bra fade

; *******************************************************************
; swebby
; Display the rotating web behind the high score table.
; *******************************************************************
swebby:
        ; This just clears the screen I think.
        move.l #0,gpu_mode
        move.l #(PITCH1|PIXEL16|WID384|XADDPHR),dest_flags  ;screen details for CLS
        move.l #$0,backg
        lea fastvector,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        bsr WaitBlit

        ; This actually draws the web.
        lea _web,a0
        add #3,28(a0)
        add #1,30(a0)
        jsr draw_objects      ;draw rotatey-Web

        ; Do the 'falling star' plane behind the rotating web.
starri:
        lea in_buf,a0
        move.l #32,(a0)      ;no. of stars
        move.l #84,20(a0)    ;seed Y
        move.l #1,gpu_mode

        move frames,d7
        move #10,d6
        move d7,d5
        move.l #$70,d4
stlp:
        move d7,d0
        lsr #2,d0
        and.l #$1ff,d0
        add d5,d7
        move.l #0,8(a0)
        move.l d0,12(a0)
        move d6,d0
        addq #1,d0
        move.l d0,16(a0)
        movem.l d4-d7,-(a7)
        move d5,d7
        lsl #2,d6
        add d6,d7
        bsr pulser
        lsl #8,d6
        or d6,d4
        move.l d4,4(a0)
        movem.l (a7)+,d4-d7
        add #$08,d4
        move.l a0,-(a7)
        lea equine2,a0
        jsr gpurun      ;do starplane
        jsr gpuwait
        move.l (a7)+,a0
        dbra d6,stlp
        rts  

;********************************************************
; yakscreen
; Display the credits screen
;********************************************************
yakscreen:
        move.l #rrts,routine
;  move #-1,db_on
        clr sync
        sub #1,joby
        and #3,joby
        bsr InitBeasties
        bsr hisettrue
        move.l #yakhead,demo_routine       ; Used by 'attract'.
        move #32,pongx                     ; Used by 'attract'.
        move #3,pongy                      ; Used by 'attract'.
        clr pongxv
        move.l #$400000,pongz
        move.l #$1c000,vp_sfs
        move.l #6,warp_count
        move.l #$0000,warp_add
        move.l #gamefx,fx
        clr.l pongyv
        jsr ringstars      ;init ring SF

        move.l #screen3,gpu_screen
        jsr clearscreen
        move.l #dudes,a0                   ; The credits header: "Tempest Dudes".
        move.l #cfont,a1                   ; The font used.
        move #6+12,d0
        tst pal
        beq snopal
        add #10,d0
snopal:
        jsr centext
        lea testpage,a5                   ; The full list of credits
        move #46,d0
        move #20+16,d1
        tst pal
        beq snopal2
        add palfix2,d1
snopal2:
        jsr pager                         ;Write the credits text to screen.
        move d7,-(a7)
        jsr hisettrue3
;  move #$7fff,attime
        bsr attract
        move (a7)+,d7
        bra fade

; *******************************************************************
; yakhead
; The routine responsible for drawing a rotating and expanding Yak Head
; in the background of the credits screen.
; *******************************************************************
yakhead:
        sub #1,pongx
        cmp #1,pongx
        bne yhead

;  move #48,pongx
;  bra yhead

        move.l #yakhead2,demo_routine
        clr pongy
        bra yhead

yakhead2:
        sub.l #$4000,pongz
        cmp.l #$220000,pongz
        bgt yhead
        move.l #yakhead3,demo_routine
        bra yhead

yakhead3:
        add.b #2,pongxv
        add.b #3,pongxv+1
        bra yhead

yhead:
        move.l #0,gpu_mode
        move.l #(PITCH1|PIXEL16|WID384|XADDPHR),dest_flags  ;screen details for CLS
        move.l #$0,backg
        lea fastvector,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        bsr WaitBlit

        add.l #$8000,warp_add
        add.l #$18000,pongyv
        lea sines,a0
        move pongyv,d0
        and #$ff,d0
        move.b 0(a0,d0.w),d1
        add.b #$40,d0
        move.b 0(a0,d0.w),d2
        ext d1
        ext d2
        swap d1
        swap d2
        clr d1
        clr d2
        asr.l #2,d1
        asr.l #2,d2 
        move.l #3,gpu_mode  ;mode 3 is starfield1
        move.l d1,in_buf+4
        move.l d2,in_buf+8
        move.l vp_sf,in_buf+12    ;pass viewpoint to GPU
        move.l #field1,d0
        move.l d0,in_buf+16  ;address off the starfield data structure
        move.l warp_count,in_buf+20
        move.l warp_add,in_buf+24
        lea fastvector,a0
        jsr gpurun    ;do gpu routine
        jsr gpuwait

        ; Paint the Yak head.
        lea pic2,a2
        move.l #$030007,d0  ;srce start pixel address
        move.l #$730086,d1  ;srce size
        tst joby
        bne notjob
        lea pic5,a2
        move.l #$5b00d2,d0
        move.l #$6b006c,d1
notjob:
        cmp #1,joby
        bne notatari
        lea pic5,a2
        move.l #$ec,d0
        move.l #$38004a,d1
notatari:
        move.l #4,gpu_mode  ;Multiple images stretching towards you in Z
        move pongy,d7

        move.l pongz,d6
        move pongx,d5
        and #$ff,d5
        swap d5
        clr d5
        move frames,d4
        asl #6,d4
        and #$ff,d4
dyakhead:
        lea in_buf,a0
        move.l a2,(a0)+  ;srce screen for effect
        move.l d0,(a0)+  ;srce start pixel address
        move.l d1,(a0)+  ;srce size
        movem.l d0-d1,-(a7)
        move.l d5,d0
        asr.l #2,d0
        move.l d0,(a0)+    ;x-scale
        move.l d0,(a0)+    ;y-scale
        lea sines,a4
        move.b pongxv,d1
        and #$ff,d1
        move.b 0(a4,d1.w),d0
        ext d0
        swap d0
        clr d0
        asr.l #6,d0
        move.l d0,(a0)+    ;shearx
        move.b pongxv+1,d1
        move.b 0(a4,d1.w),d0
        ext d0
        swap d0
        clr d0
        asr.l #6,d0
        move.l d0,(a0)+
        move.l #1,(a0)+    ;Mode 1 = Centered
        move.l #0,(a0)+
        move.l #0,(a0)+
        move.l d6,d0
        add.l #$200000,d6
        tst.l d0
        bmi xane      ;no point in drawing -ves
        move.l d0,(a0)+  ;Dest x,y,z
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
xane:
        movem.l (a7)+,d0-d1
        dbra d7,dyakhead
        rts
        
; *******************************************************************
; yh
; Calls the 'rex' shader in camel.gas (i.e. gpu_mode 4).
; Used by the victory bonus screen.
; *******************************************************************
yh:
        move.l #4,gpu_mode  ;Multiple images stretching towards you in Z
        lea in_buf,a0
        move.l a2,(a0)+  ;srce screen for effect
        move.l d0,(a0)+  ;srce start pixel address
        move.l d1,(a0)+  ;srce size
        move.l d5,(a0)+    ;x-scale
        move.l d5,(a0)+    ;y-scale
        move.l d2,(a0)+    ;shearx
        move.l d3,(a0)+    ;sheary
        move.l #1,(a0)+    ;Mode 1 = Centered
        move.l #0,(a0)+
        move.l #0,(a0)+
        move.l d6,(a0)+  ;Dest x,y,z
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jmp gpuwait


; *******************************************************************
; rexdemo
; Appears to be unused.
; Unused code
; *******************************************************************
rexdemo:
        bsr settrue
        move.l #rxdemo,demo_routine
;  move.l #rrts,fx
        move ranptr,rpcopy
        clr pongx


        bra mp_demorun  

rxdemo:
        move.l #0,gpu_mode
        move.l #(PITCH1|PIXEL16|WID384|XADDPHR),dest_flags  ;screen details for CLS
        move.l #$0,backg
        lea fastvector,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        bsr WaitBlit


; *******************************************************************
; Display an 'Excellent' message
; *******************************************************************
rexfb:
        move.l #4,gpu_mode
        lea in_buf,a0
        move.l #pic,(a0)+  ;srce screen for effect
        move.l #$10001,(a0)+  ;srce start pixel address
        move.l #$6c0120,(a0)+  ;srce size

        move pongx,d1
        and #$ff,d1
        move #9,d2
        lea p_sines,a2
        move.b 0(a2,d1.w),d0
        and.l #$ff,d0
        swap d0
        clr d0
        lsr.l d2,d0
        add.l #$14000,d0 
        move.l d0,(a0)+    ;x-scale

        move pongy,d1
        and #$ff,d1
        move.b 0(a2,d1.w),d0
        and.l #$ff,d0
        swap d0
        clr d0
        lsr.l d2,d0
        add.l #$14000,d0
        move.l d0,(a0)+    ;y-scale

        lea sines,a2
        move pongz,d1
        and #$ff,d1
        move.b 0(a2,d1.w),d0
        ext d0
        swap d0
        clr d0
        asr.l #7,d0
        move.l #0,(a0)+    ;x shear

        move pongxv,d1
        and #$ff,d1
        move.b 0(a2,d1.w),d0
        ext d0
        swap d0
        clr d0
        asr.l #7,d0
        asr.l #3,d0
        move.l #0,(a0)+

        move.l #1,(a0)+    ;Mode 1 = Centered
        move.l #$0000,(a0)+  ;Dest centre position
        move.l #-$6c0000,d0
        tst pal
        beq nopaldude
        move.l #-$8c0000,d0
nopaldude:
        move.l d0,(a0)+
        move.l #$1100000,(a0)+
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        add.l #$40000,pongx
        add.l #$31230,pongy
        add.l #$8415,pongz
        add.l #$e8d2,pongxv
        rts  

; *******************************************************************
; Display the One-Up graphic
; A member of the draw_vex list.
; *******************************************************************
draw_oneup:
        move.l #4,gpu_mode  ;Multiple images stretching towards you in Z
        move #0,d7
        move.l 12(a6),d6
        move #150,d5
        sub 46(a6),d5    ;range is 0-150
        swap d5
        clr d5
        lsr.l #2,d5
doneup:
        lea in_buf,a0
        move.l #pic2,(a0)+  ;srce screen for effect
        move.l #$000094,(a0)+  ;srce start pixel address
        move.l #$150032,(a0)+  ;srce size
        move.l d5,d0
        asr.l #2,d0
        move.l d0,(a0)+    ;x-scale
        move.l d0,(a0)+    ;y-scale
        move.l #0,(a0)+    ;no shear
        move.l #0,(a0)+
        move.l #1,(a0)+    ;Mode 1 = Centered
        move.l 4(a6),d0
        sub.l vp_x,d0
        move.l d0,(a0)+
        move.l 8(a6),d0
        sub.l vp_y,d0
        move.l d0,(a0)+
        move.l d6,d0
        sub.l vp_z,d0
        move.l d0,(a0)+  ;Dest x,y,z
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        sub.l d5,d6
        bmi rrts      ;no point in drawing -ves
        dbra d7,doneup
        add.l d5,d6
        add.l d5,d6
        move #5,d7
doneup2:
        lea in_buf,a0
        move.l #pic2,(a0)+  ;srce screen for effect
        move.l #$0000c6,(a0)+  ;srce start pixel address
        move.l #$15000f,(a0)+  ;srce size
        move.l d5,d0
        asr.l #3,d0
        move.l d0,(a0)+    ;x-scale
        move.l d0,(a0)+    ;y-scale
        move.l #0,(a0)+    ;no shear
        move.l #0,(a0)+
        move.l #1,(a0)+    ;Mode 1 = Centered
        move.l 4(a6),d0
        sub.l vp_x,d0
        move.l d0,(a0)+
        move.l 8(a6),d0
        sub.l vp_y,d0
        sub.l #$80000,d0
        move.l d0,(a0)+
        move.l d6,d0
        sub.l vp_z,d0
        move.l d0,(a0)+  ;Dest x,y,z
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        sub.l d5,d6
        bmi rrts      ;no point in drawing -ves
        dbra d7,doneup2
        rts

; *******************************************************************
; drawsphere
; A member of the draw_vex list.
; *******************************************************************
drawsphere:

        lea in_buf,a0
        move.l 4(a6),d0
        sub.l vp_x,d0
        move.l d0,(a0)
        move.l 8(a6),d0
        sub.l vp_y,d0
        move.l d0,4(a0)
        move.l 12(a6),d0
        sub.l vp_z,d0
        move.l d0,8(a0)
        move 42(a6),d0
        and.l #$ff,d0
        move.l d0,d1
        move.l d0,d2
        lsr.l #2,d1
        neg.l d1
        add.l #$ff,d1
        and #$0f,d1
        or 46(a6),d1
        asl.l #2,d0    ;was 2
        move.l d0,12(a0)  ;rad
        move.l #0,16(a0)  ;phase 1
        move frames,d0
        and.l #$ff,d0
        move.l d0,20(a0)  ;phase 2
        move 48(a6),d3
        subq #1,d3
        lsl #4,d3
        lea sphertypes,a1
        lea 0(a1,d3.w),a1
        move.l (a1)+,24(a0)  ;rings/sphere
        move.l (a1)+,28(a0)  ;pixels/ring
        move.l (a1)+,32(a0)  ;pixel spacing
        move.l (a1)+,36(a0)  ;twist per ring
        move.l d1,40(a0)  ;colour
        neg.l d2
        add.l #$ff,d2    ;calculate i decreasing
        move.l d2,44(a0)
        move.l #4,gpu_mode
        lea bovine,a0
        jsr gpurun      ;do clear screen
        jmp gpuwait

sphertypes:
        dc.l $40,$10,4,8
        dc.l $20,$08,8,16
        dc.l $10,$04,16,32
        dc.l $08,$02,32,61


; *******************************************************************
; draw_pixex
; A member of the draw_vex and solids list.
; *******************************************************************
draw_pixex:
        move.l #4,gpu_mode
        lea in_buf,a0
        move.l #pic,(a0)+  ;srce screen for effect
        move.l 36(a6),(a0)+  ;srce start pixel address
        move.l 46(a6),(a0)+  ;srce size
        move.l 42(a6),d0
        asr.l #2,d0
        move.l d0,(a0)+    ;x-scale
        move.l d0,(a0)+    ;y-scale
        move.l #0,(a0)+    ;no shear
        move.l #0,(a0)+
        move.l #1,(a0)+    ;Mode 1 = Centered
        move.l 4(a6),d0
        sub.l vp_x,d0
        move.l d0,(a0)+
        move.l 8(a6),d0
        sub.l vp_y,d0
        move.l d0,(a0)+
        move.l 12(a6),d0
        sub.l vp_z,d0
        move.l d0,(a0)+  ;Dest x,y,z
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jmp gpuwait

; *******************************************************************
; dxshot
; A member of the draw_vex and solids list.
; *******************************************************************
dxshot:
        move 30(a6),d4
        and.l #$ff,d4
        move.l #9,d5
        move 46(a6),d0
        and.l #$ff,d0
        move #2,d7
        move #$55,d6
        lea xbit,a1
        bra s_multi

; *******************************************************************
; draw_pring
; A member of the draw_vex list.
; *******************************************************************
draw_pring:
        move.l #$80000,d4
        move.l #4,d3
        move.l #6,gpu_mode
        lea in_buf,a0
        move.l d3,(a0)+    ;# pixels per ring
        move.l 4(A6),d0
        sub.l vp_x,d0
        move.l d0,(a0)+
        move.l 8(a6),d0
        sub.l vp_y,d0
        move.l d0,(a0)+
        move.l 12(a6),d0
        sub.l vp_z,d0
        move.l d0,(a0)+  ;XYZ position
        swap d0
        move d0,d7


dprdpr:
        bsr pulser
        and.l #$ff,d6
        move.l d6,(A0)+  ;colour
        move.l d4,(a0)+  ;radius 16:16
        and.l #$ff,d0
        move.l d0,(a0)+    ;phase
        lea xparrot,a0
        jsr gpurun      ;do clear screen
        jmp gpuwait

; *******************************************************************
; pupring
; *******************************************************************
pupring:
        move.l #6,gpu_mode
        move #3,d4
prloo:
        lea in_buf,a0
        move.l #12,(a0)+    ;# pixels per ring
        move.l d2,(a0)+
        move.l d3,(a0)+
        move.l d1,(a0)+  ;XYZ position
        move.l d1,d7
        swap d7
        bsr pulser
        and.l #$ff,d6
        move.l d6,(A0)+  ;colour
        move 44(a6),d0
        swap d0
        clr d0
        move.l d0,(a0)+  ;radius 16:16
        move frames,d0
        and.l #$ff,d0
        move.l d0,(a0)+    ;phase
        lea xparrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        sub.l #$80000,d1
        dbra d4,prloo
        rts

; *******************************************************************
; opupring
; *******************************************************************
opupring:
        movem.l d0-d3,-(a7)
        move.l #6,gpu_mode
        lea in_buf,a0
        move.l #20,(a0)+    ;# pixels per ring
        move.l d2,(a0)+
        move.l d3,(a0)+
        move.l d1,(a0)+  ;XYZ position
        move frames,d7
        bsr pulser
        and.l #$ff,d6
        move.l d6,(A0)+  ;colour
        move 48(a6),d0
        swap d0
        clr d0
        move.l d0,(a0)+  ;radius 16:16
        move frames,d0
        and.l #$ff,d0
        move.l d0,(a0)+    ;phase
        lea xparrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        movem.l (a7)+,d0-d3
        move #3,d4
        move 48(a6),d7
        move.l #7,gpu_mode
prloo4:
        lea in_buf,a0
        move.l #24,(a0)+    ;# pixels per ring
        move.l d2,(a0)+
        move.l d3,(a0)+
        move.l d1,(a0)+  ;XYZ position
        move d7,-(a7)
        bsr pulser
        move (a7)+,d7
        and.l #$ff,d6
        move.l d6,(A0)+  ;colour
        move #300,d0
        sub d7,d0
        asr d4,d0
        swap d0
        clr d0
        move.l d0,(a0)+  ;radius 16:16
        move.l #0,(a0)+    ;phase
        lea xparrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        dbra d4,prloo4
        rts

; *******************************************************************
; draw_prex
; A mamber of the draw_vex list.
; *******************************************************************
draw_prex:
        move.l 4(a6),d0
        move.l 8(a6),d1
        move.l 12(a6),d2
        sub.l vp_x,d0
        sub.l vp_y,d1
        sub.l vp_z,d2
        clr.l d3
        clr.l d4
        move 44(a6),d3
        swap d3
        move 46(a6),d4
        move #2,d5
        move.l #7,gpu_mode

prexloop:
        movem.l d0-d5,-(a7)

        lea in_buf,a0
        move.l d4,(a0)+    ;# pixels per ring
        move.l d0,(a0)+
        move.l d1,(a0)+
        move.l d2,(a0)+  ;XYZ position
        move.l d3,d7
        swap d7
        bsr pulser
        and.l #$ff,d6
        move.l d6,(A0)+  ;colour
        move.l d3,(a0)+  ;radius 16:16
        move frames,d0
        and.l #$ff,d0
        move.l d0,(a0)+    ;phase
        lea xparrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        movem.l (a7)+,d0-d5
        sub.l #$40000,d2
        asl.l #1,d3
        sub #2,d4
        dbra d5,prexloop
        rts

; *******************************************************************
; draw_pprex
; *******************************************************************
draw_pprex:
        clr.l d0
        clr.l d4
        move 44(a6),d0
        swap d0
        move 46(a6),d4
        move #2,d5
        move.l #1,gpu_mode

pprexloop:
        movem.l d0-d5,-(a7)

        lea in_buf,a0
        move.l d4,(a0)+    ;# pixels per ring
        move.l d2,(a0)+
        move.l d3,(a0)+
        move.l d1,(a0)+  ;XYZ position
        move.l d0,d7
        swap d7
        bsr pulser
        and.l #$ff,d6
        move.l d6,(A0)+  ;colour
        move.l d0,(a0)+  ;radius 16:16
        move frames,d0
        and.l #$ff,d0
        move.l d0,(a0)+    ;phase
        lea equine,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        movem.l (a7)+,d0-d5
        sub.l #$40000,d1
        asl.l #1,d0
        sub #2,d4
        dbra d5,pprexloop
        rts


; *******************************************************************
; dmpix
; *******************************************************************
dmpix:
        move.l 16(a6),a2
        move.l #4,gpu_mode  ;Multiple images stretching towards you in Z
        move #0,d7
        move.l 12(a6),d6
        move #150,d5
        sub 46(a6),d5    ;range is 0-150
        swap d5
        clr d5
        lsr.l #2,d5
dmup:
        lea in_buf,a0
        move.l a2,(a0)+  ;srce screen for effect
        move.l 36(a6),(a0)+  ;srce start pixel address
        move.l 40(a6),(a0)+  ;srce size
        move.l d5,d0
        asr.l #2,d0
        move.l d0,(a0)+    ;x-scale
        move.l d0,(a0)+    ;y-scale
        move.l #0,(a0)+    ;no shear
        move.l #0,(a0)+
        move.l #1,(a0)+    ;Mode 1 = Centered
        move.l 4(a6),d0
        sub.l vp_x,d0
        move.l d0,(a0)+
        move.l 8(a6),d0
        sub.l vp_y,d0
        move.l d0,(a0)+
        move.l d6,d0
        sub.l vp_z,d0
        move.l d0,(a0)+  ;Dest x,y,z
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        sub.l d5,d6
        bmi rrts      ;no point in drawing -ves
        dbra d7,dmup
        rts

; *******************************************************************
; draw_mpixex
; *******************************************************************
draw_mpixex:
        move.l #pic,a2
giff:
         move.l #4,gpu_mode  ;Multiple images stretching towards you in Z
        move #0,d7
        move.l 12(a6),d6
mpixex:
        lea in_buf,a0
        move.l a2,(a0)+  ;srce screen for effect
        move.l 36(a6),(a0)+  ;srce start pixel address
        move.l 46(a6),(a0)+  ;srce size
        move.l 42(a6),d0
        asr.l #2,d0
        move.l d0,(a0)+    ;x-scale
        move.l d0,(a0)+    ;y-scale
        move.l #0,(a0)+    ;no shear
        move.l #0,(a0)+
        move.l #1,(a0)+    ;Mode 1 = Centered
        move.l 4(a6),d0
        sub.l vp_x,d0
        move.l d0,(a0)+
        move.l 8(a6),d0
        sub.l vp_y,d0
        move.l d0,(a0)+
        move.l d6,d0
        sub.l vp_z,d0
        move.l d0,(a0)+  ;Dest x,y,z
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait

        sub.l #$100000,d6
        bmi rrts      ;no point in drawing -ves
        dbra d7,mpixex
        rts 

; *******************************************************************
; gringbull
; *******************************************************************
gringbull:
        move.l #3,gpu_mode  ;Multiple images stretching towards you in Z
        lea in_buf,a0
        move.l #pic2,(a0)+  ;srce screen for effect
        move.l #$8300d7,(a0)+  ;srce start pixel address
        bra ringa2

; *******************************************************************
; cringbull
; *******************************************************************
cringbull:
        move.l #3,gpu_mode
        bra ringa  

ringbull:
        move.l #4,gpu_mode  ;Multiple images stretching towards you in Z
ringa:
        lea in_buf,a0
        move.l #pic2,(a0)+  ;srce screen for effect
        move.l #$7300d7,(a0)+  ;srce start pixel address
ringa2:
        move.l #$0f000f,(a0)+  ;srce size
        move.l #$8000,d7
        move.l d7,(a0)+    ;x-scale
        move.l d7,(a0)+    ;y-scale
        move.l #0,(a0)+    ;no shear
        move.l #0,(a0)+
        move.l #1,(a0)+    ;Mode 1 = Centered
        move.l d2,(a0)+
        move.l d3,(a0)+
        move.l d1,(a0)+  ;Dest x,y,z
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jmp gpuwait

; *******************************************************************
; polyr
; Unused code
; *******************************************************************
polyr:
        move.l #testpoly,in_buf
        bsr itpoly
;  lea parrot,a0
;  jsr gpuload    ;load the GPU code for the demos

        lea beasties,a0    ;set main screen to 16-bit
        move.l #screen2,d2
        move.l d2,gpu_screen
        move #SIDE,d0
        sub palside,d0
        move #TOP,d1
        add paltop,d1
        swap d0
        swap d1
        move #0,d5
        move #$24,d3
        move #$24,d4
        bsr makeit

        move.l #polydemo,demo_routine
        move.l #rrts,fx
        bra mp_demorun  


; *******************************************************************
; polydemo
; Unused code
; *******************************************************************
polydemo:
        move.l #0,gpu_mode
        move.l #(PITCH1|PIXEL16|WID384|XADDPHR),dest_flags  ;screen details for CLS
;  clr.l backg
        lea fastvector,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        move.l #1,gpu_mode    ;mode to draw poly
        move rpcopy,ranptr    ;reset RNG to known value
        move #19,d0
pollies:
        move d0,-(a7)
        bsr rtpoly
        lea xparrot,a0
        jsr gpurun      ;do horizontal ripple warp
        jsr gpuwait
        move (a7)+,d0
        dbra d0,pollies
        rts

; *******************************************************************
; ppolyr
; Unused code
; *******************************************************************
ppolyr:
        move.l #testppoly,in_buf
        bsr itppoly
;  lea parrot,a0
;  jsr gpuload    ;load the GPU code for the demos

        lea beasties,a0    ;set main screen to 16-bit
        move.l #screen2,d2
        move.l d2,gpu_screen
        move #SIDE,d0
        sub palside,d0
        move #TOP,d1
        add paltop,d1
        swap d0
        swap d1
        move #0,d5
        move #$24,d3
        move #$24,d4
        bsr makeit


        move.l #ppolydemo,demo_routine
        move.l #rrts,fx
        bra mp_demorun  


; *******************************************************************
; ppolyr2
; Unused code
; *******************************************************************
ppolyr2:
; lea parrot,a0
;  jsr gpuload    ;load the GPU code for the demos

        lea beasties,a0    ;set main screen to 16-bit
        move.l #screen2,d2
        move.l d2,gpu_screen
        move #SIDE,d0
        sub palside,d0
        move #TOP,d1
        add paltop,d1
        swap d0
        swap d1
        move #0,d5
        move #$24,d3
        move #$24,d4
        bsr makeit
        move.l #2,gpu_mode  ;mode 2 is pretty poly
        move #1,dotile
        move.l #ppolydemo2,demo_routine
        move.l #rrts,fx
        move #$10,pongxv
        move #$20,pongyv
        move #0,pongphase
        move #0,pongphase2
        move #0,pongscale
        move #0,pongzv
;  move #192,pongx
;  move #119,pongy
;  move #383,d0
;  move #239,d1
        move #63,d0
        move #63,d1
        move #2,polspd1
        move #3,polspd2
        bsr ppolysize
        bra mp_demorun  

; *******************************************************************
; polyr2
; Unused code
; *******************************************************************
polyr2:
; lea parrot,a0
;  jsr gpuload    ;load the GPU code for the demos

        lea beasties,a0    ;set main screen to 16-bit
        move.l #screen2,d2
        move.l d2,gpu_screen
        move #SIDE,d0
        sub palside,d0
        move #TOP,d1
        add paltop,d1
        swap d0
        swap d1
        move #0,d5
        move #$24,d3
        move #$24,d4
        bsr makeit
        move.l #1,gpu_mode  ;mode 2 is pretty poly
        move.l #polydemo2,demo_routine
        move.l #rrts,fx
        move #$20,pongxv
        move #$30,pongyv

        move #0,pongphase
        move #0,pongphase2
        move #0,pongscale
;  move #192,pongx
;  move #119,pongy
        move #383,d0
        move #239,d1
        bsr polysize
        bra mp_demorun  

polysize:
        move d0,d2
        lsr #1,d2
        move d1,d3
        lsr #1,d3
        add #1,d0
        add #1,d1
        move d2,pongx
        move d3,pongy
        lea poly1,a0
        move d0,6(a0)
        move d0,20(a0)
        move d0,26(a0)
        move d1,28(a0)
        move d0,40(a0)
        move d1,42(a0)
        move d1,48(a0)  
        move d1,62(a0)  
        move #3,d4
psize:
        move d2,12(a0)
        move d3,14(a0)
        lea 20(a0),a0
        dbra d4,psize
        rts

; *******************************************************************
; ppolysize
; *******************************************************************
ppolysize:
        move #1,d4
        move #1,d5

ppolysi:
        move d0,d2
        lsr #1,d2
        move d1,d3
        lsr #1,d3
        add d4,d0
        add d5,d1
        add d4,d2
        add d5,d3
        move d2,polsizx
        move d3,polsizy
        lea ppoly1,a0
        move d0,8(a0)
        move d0,24(a0)
        move d0,32(a0)
        move d1,34(a0)
        move d0,48(a0)
        move d1,50(a0)
        move d1,58(a0)  
        move d1,74(a0)  
        move #3,d4
ppsize:
        move d2,16(a0)
        move d3,18(a0)
        lea 24(a0),a0
        dbra d4,ppsize
        rts

; *******************************************************************
; makepyr
; *******************************************************************
makepyr:
        movem d6-d7,-(a7)
        move pc_1,d7
        bsr pulser
        move d6,d4
        move d4,popo1
        move pc_2,d7
        bsr pulser
        move d6,d5
        move d5,popo2

;  not d5

        movem (a7)+,d6-d7  ;do colourpulses

        move d0,d2
        lsr #1,d2
        move d1,d3
        ext.l d3
        divu #3,d3
        add d3,d3

        sub d2,d6
        sub d3,d7

        add d6,d0
        add d7,d1
        add d6,d2
        add d7,d3
          
        move d2,centrx
        move d3,centry
        lea pypoly1,a0
        move d6,(a0)+
        move d1,(a0)+
        move #$5fff,(a0)+
        move d4,(a0)+

        move d2,(a0)+
        move d7,(a0)+
        move #$5fff,(a0)+
        move d5,(a0)+

        move d2,(a0)+
        move d3,(a0)+
        move #$ffff,(a0)+
        move #$88,(a0)+


        move d2,(a0)+
        move d7,(a0)+
        move #$5fff,(a0)+
        move d5,(a0)+

        move d0,(a0)+
        move d1,(a0)+
        move #$5fff,(a0)+
        move d4,(a0)+

        move d2,(a0)+
        move d3,(a0)+
        move #$ffff,(a0)+
        move #$88,(a0)+

        move d0,(a0)+
        move d1,(a0)+
        move #$5fff,(a0)+
        move d4,(a0)+

        move d6,(a0)+
        move d1,(a0)+
        move #$5fff,(a0)+
        move d4,(a0)+

        move d2,(a0)+
        move d3,(a0)+
        move #$ffff,(a0)+
        move #$88,(a0)+

        rts

; *******************************************************************
; ppolydemo2
; *******************************************************************
ppolydemo2:
        move.l #2,gpu_mode
        move.l #ppoly1,in_buf
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        move.l #ppoly2,in_buf
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        move.l #ppoly3,in_buf
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        move.l #ppoly4,in_buf
        lea parrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait

        move polspd1,d0
        asr #4,d0
        move polspd2,d1
        asr #4,d1
        add d0,pongscale
        add d1,pongphase2
        add #1,pongphase
        move pongphase,d0      ;get pulse colour
        and #$ff,d0
        lea sines,a0
        move.b 0(a0,d0.w),d1
        ext d1
        add.b #$40,d0
        move.b 0(a0,d0.w),d0
        ext d0
        add #$80,d0
        add #$80,d1
        and #$f0,d0
        lsr #4,d1
        and #$0f,d1
        or d0,d1      ;d1 is pulse colour
        move d1,ppoly1+22
        move d1,ppoly2+22
        move d1,ppoly3+22
        move d1,ppoly4+22    ;set colour in the polly definitions
        move polsizx,d0
        move d0,ppoly1+16
        move d0,ppoly2+16
        move d0,ppoly3+16
        move d0,ppoly4+16
        move polsizy,d0
        move d0,ppoly1+18
        move d0,ppoly2+18
        move d0,ppoly3+18
        move d0,ppoly4+18
        move pongphase2,d0
        and #$ff,d0
        lea p_sines,a0
        lea ppoly1,a1
        move #3,d7
sintens:
        move.b 0(a0,d0.w),d1
        lsl #8,d1
        move d1,4(a1)
        add.b #$40,d0
        move.b 0(a0,d0.w),d1
        lsl #8,d1
        move d1,12(a1)
        lea 24(a1),a1
        dbra d7,sintens
        move pongscale,d0
        and #$ff,d0
        move.b 0(a0,d0.w),d1
        lsl #8,d1
        move d1,ppoly1+20
        move d1,ppoly2+20
        move d1,ppoly3+20
        move d1,ppoly4+20

        bra jj


; *******************************************************************
; polydemo2
; *******************************************************************
polydemo2:
        move.l #poly1,in_buf
        lea xparrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        move.l #poly2,in_buf
        lea xparrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        move.l #poly3,in_buf
        lea xparrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        move.l #poly4,in_buf
        lea xparrot,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait

        add #1,pongphase
        move pongxv,d0
        asr #4,d0
        add d0,pongscale
        move pongyv,d0
        asr #4,d0
        add d0,pongphase2
        move pongphase,d0      ;get pulse colour
        and #$ff,d0
        lea sines,a0
        move.b 0(a0,d0.w),d1
        ext d1
        add.b #$40,d0
        move.b 0(a0,d0.w),d0
        ext d0
        add #$80,d0
        add #$80,d1
        and #$f0,d0
        lsr #4,d1
        and #$0f,d1
        or d0,d1      ;d1 is pulse colour
        move d1,poly1+18
        move d1,poly2+18
        move d1,poly3+18
        move d1,poly4+18    ;set colour in the polly definitions
        move pongx,d0
        move d0,poly1+12
        move d0,poly2+12
        move d0,poly3+12
        move d0,poly4+12
        move pongy,d0
        move d0,poly1+14
        move d0,poly2+14
        move d0,poly3+14
        move d0,poly4+14
        move pongphase2,d0
        and #$ff,d0
        lea p_sines,a0
        lea poly1,a1
        move #3,d7
sintens2:
        move.b 0(a0,d0.w),d1
        lsl #8,d1
        move d1,4(a1)
        add.b #$40,d0
        move.b 0(a0,d0.w),d1
        lsl #8,d1
        move d1,10(a1)
        lea 20(a1),a1
        dbra d7,sintens2
        move pongscale,d0
        and #$ff,d0
        move.b 0(a0,d0.w),d1
        lsl #8,d1
        move d1,poly1+16
        move d1,poly2+16
        move d1,poly3+16
        move d1,poly4+16

; *******************************************************************
; jj
; *******************************************************************
jj:
        move.l pad_now,d0
        and.l #allbutts,d0
        beq nobuts
        cmp.l #allbutts,d0
        bne rrts

        move.l #adec,a0
        move.l #ainc,a1
        move.l #bdec,a2
        move.l #binc,a3
        bra gjoy
        rts

nobuts:
        move.l #ydec,a0
        move.l #yinc,a1
        move.l #xdec,a2
        move.l #xinc,a3
        bra gjoy


adec:
        sub #1,polspd1
        rts
ainc:
        add #1,polspd1
        rts
bdec:
        sub #1,polspd2
        rts
binc:
        add #1,polspd2
        rts


ydec:
        sub #4,polsizy
        bpl rrts
        move #0,polsizy
        rts
yinc:
        add #4,polsizy
        cmp #239,polsizy
        ble rrts
        move #239,polsizy
        rts
xdec:
        sub #4,polsizx
        bpl rrts
        move #0,polsizx
        rts
xinc:
        add #4,polsizx
        cmp #383,polsizx
        ble rrts
        move #383,polsizx
        rts

; *******************************************************************
; ppolydemo
; *******************************************************************
ppolydemo:
        move.l #0,gpu_mode
        move.l #(PITCH1|PIXEL16|WID384|XADDPHR),dest_flags  ;screen details for CLS
;  clr.l backg
        lea fastvector,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
ppolyfb:
        move.l #testppoly,in_buf
        move.l #2,gpu_mode    ;mode to draw pretty poly
        move rpcopy,ranptr    ;reset RNG to known value
        move npolys,d0
ppollies:
        move d0,-(a7)
        bsr rtppoly
        lea parrot,a0
        jsr gpurun      ;do horizontal ripple warp
        jsr gpuwait
        move (a7)+,d0
        dbra d0,ppollies
        rts

; *******************************************************************
; itppoly
; *******************************************************************
itppoly:
        move ranptr,rpcopy    ;so sequence is always the same
rtppoly:
        move frames,d6
        lea sines,a0
        lea testppoly,a1
        jsr rannum
        move d0,d4
        add #64,d4
        jsr rannum
        and #$3f,d0
        move d0,d5
        add #64,d5
        jsr rannum
        and #$7f,d0
        add #$3f,d0
        move d0,d3
        jsr rannum
        add d6,d0
        move #2,d7
rtpp:
;  jsr rannum
        and #$ff,d0
        move.b 0(a0,d0.w),d1
        ext d1
        move d1,d2
        add #$80,d2
        lsl #8,d2
        move d2,-(a7)
        add.b #$40,d0
        move.b 0(a0,d0.w),d2
        sub.b #$40,d0
        add.b d3,d0
        ext d2
        asr #1,d1
        asr #1,d2
        add d4,d1
        add d5,d2
        move d1,(a1)+
        move d2,(a1)+
;  lea 2(a1),a1
        move (a7)+,d1
        move d1,(a1)+
        move d0,-(a7)
        jsr rannum
        move d0,(a1)+
        move (a7)+,d0
        dbra d7,rtpp
        rts

; *******************************************************************
; itpoly
; *******************************************************************
itpoly:
        move ranptr,rpcopy    ;so sequence is always the same
rtpoly:
        move frames,d6
        lea sines,a0
        lea testpoly,a1
        move #2,d7
rtp:
        jsr rannum
        move d0,d4
        add #64,d4
        jsr rannum
        and #$3f,d0
        move d0,d5
        add #64,d5
        
        jsr rannum
        add d6,d0
        and #$ff,d0
        move.b 0(a0,d0.w),d1
        ext d1
        move d1,d2
        add #$80,d2
        lsl #8,d2    ;make an i-value
        move d2,-(a7)
        add.b #$40,d0
        move.b 0(a0,d0.w),d2
        ext d2
        asr #1,d1
        asr #1,d2
        add d4,d1
        add d5,d2
        move d1,(a1)+
        move d2,(a1)+
;  lea 2(a1),a1
        move (a7)+,d1
        move d1,(a1)+
        dbra d7,rtp
        jsr rannum
        move d0,(a1)
        rts



; *******************************************************************
; feedme3
; Unused code?
; *******************************************************************

feedme3:
        move.l #testppoly,in_buf
        bsr itppoly
        move.l #ppolyfb,feedline
        move #1,npolys
        bra feed

feedme2:
        move.l #rexfb,feedline
        clr pongx
        bra feed
feedme4:
        move.l #pyrfb,feedline
        clr pongx
        bra feed
feedme5:
        move.l #rrts,fx
        move #$20,polspd1
        move #$30,polspd2
        move #0,pongphase
        move #0,pongphase2
        move #0,pongscale
;  move #0,pongzv
        move #160,d4
        move #88,d5
        move #63,d0
        move #63,d1
        bsr ppolysi
        move.l #tilfb,feedline
        clr pongx
        clr dotile
        bra feed

tilfb:
        bra ppolydemo2

; *******************************************************************
; pyrfb
; Unused?
; *******************************************************************
pyrfb:
        move.l #0,gpu_mode
        move.l #192,xcent
        move.l #120,d6
        add palfix2,d6
        move.l d6,ycent

        lea in_buf,a0      ;set up func/linedraw
        move.l #$800000,(a0)+
        move.l #$800000,(a0)+
        move.l #$a20000,(a0)+  ;XYZ source
        move.l #$0,(a0)+
        move.l #$0,(a0)+
        move.l #$200000,(a0)+  ;XYZ dest
        move popo1,d0
        and.l #$ff,d0
        move.l d0,(a0)+  ;colour
        move.l #32,(a0)+  ;# segs
        move frames,d0
        and.l #$ff,d0
        or #$01,d0
        move.l d0,(a0)+
        move.l #bovine,a0
        jsr gpurun    ;do it
        jsr gpuwait
        jsr WaitBlit
        

        lea in_buf,a0      ;set up func/linedraw
        move.l #-$800000,(a0)+
        move.l #$800000,(a0)+
        move.l #$a20000,(a0)+  ;XYZ source
        move.l #$0,(a0)+
        move.l #$0,(a0)+
        move.l #$200000,(a0)+  ;XYZ dest
        move popo1,d0
        and.l #$ff,d0
        move.l d0,(a0)+  ;colour
        move.l #32,(a0)+  ;# segs
        move frames,d0
        and.l #$ff,d0
        or #$01,d0
        move.l d0,(a0)+
        move.l #bovine,a0
        jsr gpurun    ;do it
        jsr gpuwait
        jsr WaitBlit

        lea in_buf,a0      ;set up func/linedraw
        move.l #00000,(a0)+
        move.l #-$800000,(a0)+
        move.l #$a20000,(a0)+  ;XYZ source
        move.l #$0,(a0)+
        move.l #$0,(a0)+
        move.l #$200000,(a0)+  ;XYZ dest
        move popo2,d0
        and.l #$ff,d0
        move.l d0,(a0)+  ;colour
        move.l #32,(a0)+  ;# segs
        move frames,d0
        and.l #$ff,d0
        or #$01,d0
        move.l d0,(a0)+
        move.l #bovine,a0
        jsr gpurun    ;do it
        jsr gpuwait
        jsr WaitBlit

        move pongx,d0
        move frames,d1
        and #$7f,d0
        and #$7f,d1
        sub #$3f,d0
        bpl doofb
        neg d0
doofb:
        sub #$3f,d1
        bpl doofb1
        neg d1
doofb1:
        add #32,d0
        add #48,d1
        move #192,d6
        move #130,d7
        bra dop

feedme:
        move.l #polyfb,feedline
        clr pongx

; *******************************************************************
; feed
; *******************************************************************
feed:
        bsr settrue
        move.l #feedback,demo_routine
        move.l #rrts,fx
        move.l #$1f001f0,pongy
        move #9,pongz
        move.l #0,pongxv
        move #192,pongyv
        move #120,pongzv
        bra mp_demorun

; *******************************************************************
; feedback
; *******************************************************************
feedback:
        move.l #(PITCH1|PIXEL16|WID384),d0
        move.l d0,source_flags
        move.l d0,dest_flags
        lea in_buf,a0
        move.l cscreen,(a0)    ;source screen is already-displayed screen
        move.l #384,4(a0)
        move.l #240,d0
        add palfix1,d0
        move.l d0,8(a0)    ;X and Y dest rectangle size
        clr.l d0
        move pongy,d0
;  lsr.l #4,d0
        move.l d0,12(a0)
        move pongy+2,d0
;  lsr.l #4,d0
        move.l d0,16(a0)    ;X and Y scale as 8:8 fractions
        move pongxv,d0
        and.l #$ff,d0
        move.l d0,20(a0)      ;initial angle in brads
        move pongyv,d0
        swap d0
        clr d0  
        move.l d0,24(a0)    ;source x centre in 16:16
        move pongzv,d0
        add palfix2,d0
        swap d0
        clr d0
        move.l d0,28(a0)    ;y centre the same
        move.l #$0,32(a0)    ;offset of dest rectangle
        move.l delta_i,36(a0)
        move.l #2,gpu_mode    ;op 2 of this module is Scale and Rotate
        move.l #demons,a0
        jsr gpurun      ;do it
        jsr gpuwait

        move.b pad_now,d0
        and #$22,d0      ;check 2 buttons down (set delta i to 0)
        cmp #$22,d0
        bne nrseti
        clr.l delta_i

nrseti:
        move.l pad_now,d0
        and.l #allbutts,d0
        cmp.l #allbutts,d0
        beq skank

        btst.b #5,pad_now
        beq skank00
        lea iypos,a0
        lea dypos,a1
        lea dxpos,a2
        lea ixpos,a3
        bsr gjoy


skank00:
        btst.b #1,pad_now
        beq skank0
        lea drang,a0
        lea irang,a1
        lea ddelta,a2
        lea idelta,a3
        bsr gjoy

skank0:
        btst.b #5,pad_now+2
        beq skank  

        lea dxscl,a0
        lea ixscl,a1
        lea dyscl,a2
        lea iyscl,a3
        bsr gjoy

skank:
        move.l feedline,a4
        jmp (a4)
polyfb:
        move.l pad_now,d0
        and.l #$22002000,d0
        bne njoy
        lea prevshape,a0
        lea nextshape,a1
        lea away,a2
        lea towards,a3
unskank:
        bsr gjoy

njoy:
        move frames,d0
        and.l #$ff,d0
        move pongz,d1
        and #$1ff,d1
        swap d1
        clr d1
        lsr.l #1,d1
        add.l #$10000,d1 
        move frames,pucnt    ;simulate pucnt in game

        move pongx,d2
        lsr #2,d2
        and #$fc,d2
        lea shapes,a2
        move.l 0(a2,d2.w),d2
        bpl shokk
        clr pongx
        move.l #draw_sflipper,d2
shokk:
        move.l d2,a2
        clr.l d2
        clr.l d3
        move.l #9,d4
        move.l #9,d5
        jmp (a2)

drang:
        sub.l #$2000,pongxv
        rts
irang:
        add.l #$2000,pongxv
        rts
ixpos:
        add #4,pongyv
        rts
dxpos:
        sub #4,pongyv
        rts
iypos:
        add #4,pongzv
        rts
dypos:
        sub #4,pongzv
        rts


dxscl:
        add #1,pongy
        rts
ixscl:
        sub #1,pongy
        rts
dyscl:
        add #1,pongy+2
        rts
iyscl:
        sub #1,pongy+2
        rts

idelta:
        add.l #$4000,delta_i
        and.l #$ffffff,delta_i
        rts
ddelta:
        sub.l #$4000,delta_i
        and.l #$ffffff,delta_i
        rts

; *******************************************************************
; rotate
; Unused?
; *******************************************************************
rotate:
rorota:
        add #$01,d0
        move d0,d1
        and #$ff,d1
        move d1,in_buf+22    ;Rotation-Angle
        and #$3ff,d0
        move.l d0,d1
        add #$01,d1
        move.l d1,in_buf+12
        move.l d1,in_buf+16    ;change scales
        rts        ;do it again
        
; *******************************************************************
; scarper
; Unused code?
; *******************************************************************
scarper:
scarp:
        bsr pingpong
scarp0:
        move.l pongz,in_buf+32
        move.l pongx,in_buf+24
        move.l pongy,in_buf+28
        rts


; *******************************************************************
; siner
; Unused code?
; *******************************************************************
siner:
         move.l #screen3,gpu_screen
sner:
        bsr rannum
        swap d0
        asr.l #8,d0
        move.l d0,in_buf
        bsr rannum
        swap d0
        asr.l #8,d0
        move.l d0,in_buf+4
        bsr rannum
        swap d0
        move.l d0,in_buf+8
        bsr rannum
        swap d0
        move.l d0,in_buf+12
        bsr rannum
        and.l #$ff,d0
        asl.l #3,d0
        move.l d0,in_buf+16
        bsr rannum
        and.l #$ff,d0
        asl.l #3,d0
        move.l d0,in_buf+20

        bsr rannum
        swap d0
        lsr.l #6,d0
        move.l d0,palad0
        bsr rannum
        move d0,palad2
        bsr rannum
        swap d0
        lsr.l #6,d0
        move.l d0,palad3    ;Randomise pal generator


        move.l #5,gpu_mode    ;To make sine pattern screen
        lea demons,a0
        jsr gpurun      ;do it
        jmp gpuwait  

voxel:
        rts


; *******************************************************************
; demorun
; Unused?
; *******************************************************************
demorun:
        move.l #demons,demobank
drun:
        move #1,screen_ready    ;tell DB to start up sync with foreground
        clr db_on      ;enable doublebuffer
scapa:
        movem.l d0-d4,-(a7)
        bsr db        ;sync with frame int, receive new drawscreen base
        bsr WaitBlit
        move.l demobank,a0
        jsr gpurun      ;do it
        jsr gpuwait
        move #1,screen_ready
        movem.l (a7)+,d0-d4
        move.l demo_routine,a0
        jsr (a0)
        btst.b #0,pad_now+1
;  bne fxsel      ;go select a new effect if player hits option
        bne mandy
        bra scapa    

; *******************************************************************
; mp_demorun
; *******************************************************************
mp_demorun:
        move #1,screen_ready    ;as above, but a multi-pass-capable version that lets you start
        clr db_on                ;the gpu in demo_routine
mp_scapa:
        movem.l d0-d4,-(a7)
        bsr db        ;sync with frame int, receive new drawscreen base
        movem.l (a7)+,d0-d4
        move.l demo_routine,a0
        jsr (a0)
        move #1,screen_ready
        btst.b #0,pad_now+1
;  bne fxsel      ;go select a new effect if player hits option
        bne mandy
        bra mp_scapa    


; *******************************************************************
; attract
; Called periodically during attract mode to detect button presses
; and run whatever background attract mode is active, e.g. the yak head,
; specified by demo_routine. 
; *******************************************************************
attract:
        move #500,attime
attr:
        clr ud_score
        move #1,screen_ready    ;as above, attract mode version
        clr db_on    
        clr e_attract
        clr optpress
;  move pauen,_pauen
timr:
        bsr thang
        tst e_attract
        bne arts
        move.l pad_now,d0
        and.l #allbutts,d0
        bne timr    ;wait for no buttons
dbnce:
        bsr thang
        tst pawsed
        bne dbnce
        sub #1,attime
        bpl intime
        move #-1,z
intime:
        tst optpress
        bne gogx
        tst z
        bne gogx
        tst e_attract
        bne arts
        move.l pad_now,d0
        or.l pad_now+4,d0
        and.l #allbutts,d0
        beq dbnce    ;wait for any buttons
arts:
        clr _pauen
        move.l #rrts,routine
        move.l d0,selbutt
        rts  
thang:
        bsr db        ;sync with frame int, receive new drawscreen base, do user routine
        move.l demo_routine,a0
        jsr (a0)
        tst pawsed
        beq mooocow
        jsr paustuff
mooocow:
        tst unpaused
        beq nunpa
        jsr eepromsave
        clr unpaused  
nunpa:
         move #1,screen_ready
        rts

; *******************************************************************
; gogame
; *******************************************************************
gogame:
        move #1,screen_ready    ;as above, attract mode version
        clr db_on
        clr x_end
gog:
        bsr thang
        tst z
        bne gogx
        tst x_end
        beq gog
gogx:
        clr _pauen
        move.l #rrts,routine
;  move #-1,db_on
        rts

; *******************************************************************
; drive
; Unused code
; *******************************************************************
drive:
        move.l #drxinc,a0
        move.l #drxdec,a1
        move.l #dryinc,a2
        move.l #drydec,a3
        bra gjoy

drxinc:
        add.l #$1,(a4)
        rts
drxdec:
        sub.l #$1,(a4)
        rts
dryinc:
        add.l #$100,24(a4)
        rts
drydec:
        sub.l #$100,24(a4)
        rts

drive2:
        move.l #drxinc2,a0
        move.l #drxdec2,a1
        move.l #dryinc2,a2
        move.l #drydec2,a3
        bra gjoy

drxinc2:
        add.l #$1,4(a4)
        rts
drxdec2:
        sub.l #$1,4(a4)
        rts
dryinc2:
        add.l #$100,28(a4)
        rts
drydec2:
        sub.l #$100,28(a4)
        rts

drive3:
        move.l #drxinc3,a2
        move.l #drxdec3,a3
        move.l #dryinc3,a0
        move.l #drydec3,a1
        bra gjoy

drxinc3:
        add.l #$1000,12(a4)
        rts
drxdec3:
        sub.l #$1000,12(a4)
        rts
dryinc3:
        add.l #$1000,16(a4)
        rts
drydec3:
        sub.l #$1000,16(a4)
        rts

ppong:
        move.l pongxv,d0
        add.l d0,pongx
        move.l pongyv,d0
        add.l d0,pongy
        bra pingzz

; *******************************************************************
; pingpong
; *******************************************************************
pingpong:
        move.l pongx,d0
        add.l pongxv,d0
        bmi bouncex
        cmp.l #$1800000,d0
        blt pingy
bouncex:
        sub.l pongxv,d0
        neg.l pongxv
pingy:
        move.l d0,pongx
        move.l pongy,d0
        add.l pongyv,d0
        bmi bouncey
        cmp.l #$ff0000,d0
        blt pingz
bouncey:
        sub.l pongyv,d0
        neg.l pongyv
pingz:
        move.l d0,pongy
pingzz:
        move.l #iscal,a0    ;for UP
        move.l #dscal,a1    ;for DOWN
        move.l #dang,a2    ;for LEFT
        move.l #iang,a3    ;for RIGHT
        bra gjoy    ;do joy con

dang:
        btst.b #5,pad_now+2
        beq aang1
        sub.l #$100000,pongz
        rts
aang1:
        sub #1,pongang
sang:
        move pongang,in_buf+22
        rts
dscal:
        move.l #-1,d1
        bra sscal
iscal:
        move.l #1,d1
sscal:
        lea pongscale,a0
        lea in_buf+12,a1
        btst.b #5,pad_now+2  ;fire C held modifies other scale parameter
        beq sscal0
        lea pongscale2,a0
        lea in_buf+16,a1
sscal0:
        move.l (a0),(a1)
        add.l d1,(a0)
        rts


; *******************************************************************
; iang
; *******************************************************************
iang:
        btst.b #5,pad_now+2
        beq aang2
        add.l #$100000,pongz
        rts
aang2:
        add #1,pongang
        bra sang

pgjoy:
        move.b ppad+1,d0
        bra ggjj
gjoy:
        move.b pad_now+1,d0  ;General purtpose keypad responder
ggjj:
        btst #4,d0    ;test Up
        beq gjoy1
        jsr (a0)
        bra gjoy2
gjoy1:
        btst #5,d0    ;Down
        beq gjoy2
        jsr (a1)
gjoy2:
        btst #6,d0    ;Left
        beq gjoy3
        jmp (a2)
gjoy3:
        btst #7,d0
        beq rrts
        jmp (a3)

curcon:
        move.b pad_now+1,d0    ;byte with UDLR in
        move cursx,d1
        move cursy,d2
        btst #4,d0    ;test Up
        beq curc1
        sub #2,d2    ;it's halflines remember
        bra curc2
curc1:
        btst #5,d0    ;Down
        beq curc2
        add #2,d2
curc2:
        btst #6,d0    ;Left
        beq curc3
        sub #2,d1
        bra curc4
curc3:
        btst #7,d0
        beq curc4
        add #2,d1
curc4:
        tst d1
        bmi curcy
        cmp #(width-48),d1
        bge curcy
        move d1,cursx
curcy:
        tst d2
        bmi curset
        cmp #((height*2)-60),d2
        bge curset
        move d2,cursy
curset:
        move cursx,beasties+64
        move cursy,beasties+68  ;put x and y into RMW object's data struct.
        rts


; *******************************************************************
; it
; Invoked as '_demo'.
; Start a demo game in attract mode
; *******************************************************************
it:
        move.l #$ff00,z_top    ;top intensity (z=1) **16 bits**
        move.l #1300,z_max    ;(distance to 0-intensity)*4
        move.l #skore,score
        move #1,ud_score
        move #0,warp_add  ;Set stuff unique to this Mode
        move.l #0,warp_count
        move.l #$20000,vp_sfs

        move #1,mfudj
        tst lives
        bpl zarka
        move #1,finished
        rts       ; was bra treset
zarka:
        bsr setlives
        bsr initobjects
        bsr setweb      ;the Web is not an object
        tst h2h
        beq stdinit      ;check for H2H mode
h2hin:
        bsr h2hclaws

        move.l gpu_screen,-(a7)
        move.l #screen3,gpu_screen
        jsr clearscreen
        lea beasties+64,a0
        move.l #screen3,d2
        move #SIDE,d0
        sub palside,d0
        move #TOP,d1
        add paltop,d1
        swap d0
        swap d1
        move #7,d5
        move #$24,d3
        move #$24,d4
        jsr makeit_trans    ;put up some TC screen for status display


        move #19,d0    
        move #20,d1  
        move #16,d6
        move #52,d7
        move.l #$40000,pc_1
        move.l #$560100,pc_2
        bsr makepyr      ;make a pyramid for hit points display
        jsr ppyr      ;draw that pyramid

        move #19,d0    
        move #20,d1  
        move #48,d6
        move #52,d7
        move.l #$840000,pc_1
        move.l #$d60100,pc_2
        bsr makepyr      ;make a pyramid for hit points display
        jsr ppyr      ;draw that pyramid

        jsr h2hinsc      ;make the lives-pyramids

        move.l (a7)+,gpu_screen

        clr.l l_ud
        move.l #-1,l_sc      ;clear player scores and update flags
        move #-1,_won
        move #8,afree


        bra go_in      ;go do H2H mode
        

; *******************************************************************
; stdinit
; *******************************************************************
stdinit:

        lea beasties+64,a0
        move.l #screen3,d2
        move #SIDE,d0
        sub palside,d0
        move #TOP,d1
        add paltop,d1
        swap d0
        swap d1
        move #8,d5
        move #$24,d3
        move #$24,d4
        jsr makeit_trans    ;put up some TC screen for status display

        move.l freeobjects,_claw
        move players,plc  ;player loop counter
zipp:
        move.l freeobjects,a6
        move plc,d7
        bsr setclaw    ;init claw object and put it on the web
        bsr insertobject
        bsr makedroid    ;init the droid
        sub #1,plc
        bne zipp
go_in:
        move.l #rotate_web,routine
        move.l #0,warp_count
        move.l #draw_objects,mainloop_routine
        move pauen,_pauen
        clr db_on
        bra mainloop

; *******************************************************************
; setweb
; *******************************************************************
setweb:
        lea _web,a0
        lea 4(a0),a0    ;object #0 is the Web
        clr.l (a0)+
        clr.l (a0)+    ;initial X and Y position
        move.l #256+webz,d0
        swap d0      ;initial Z position
        move.l d0,(a0)+
        lea 12(a0),a0    ;skip unused Z vel/Grav stuff
        clr.l (a0)+
        clr (a0)+    ;initial X,Y,Z rotation is zero
        move #1,(a0)+    ;STD draw
        lea 4(a0),a0    ;skip unused stuff
        move webcol,(a0)+    ;blue, the proper colour for a Tempest web
        move #-2,(a0)+    ;scaler Big 2  

sweb:
        tst h2h
        beq stdwebsel
        move cweb,d0
        and #$0f,d0
        lea h2hwebs,a0
        move.b 0(a0,d0.w),d0
        and #$ff,d0
        subq #1,d0
        bra wbsel
stdwebsel:
        tst dnt
        bpl sweboo
        clr dnt
sweboo:

        ; Load a web to _web
        move cweb,d0
        and weband,d0
        add webbase,d0    ;<<<
wbsel:
        asl #2,d0
        lea raw_webs,a0  ;<<<
        move.l 0(a0,d0.w),d6
        lea webs,a0
        asl #5,d0
        lea 0(a0,d0.w),a0
        lea 32(a0),a1
        move.l a1,lanes
        move.l 4(a0),web_otab
        move.l 8(a0),web_ptab
        move 12(a0),web_max
        move.l 14(a0),web_firstseg
        move 18(a0),web_x
        move 20(a0),web_z
        move 22(a0),connect
        move.l (a0),a0
        lea _web,a6
        clr 54(a6)    ;no Action
        move.l a0,(a6)
        move.l d6,46(a6)  ;solid Web that was the source

        tst tblock
        bne gnosis
        move cwave,d0
        lsr #4,d0
        and #$07,d0
        lea webtunes,a0
        move.b 0(a0,d0.w),d0
        move d0,modnum    ;request tune 4 this level

gnosis:
        move #15,d0
        lea bulls,a0
clbulls:
        clr.l (a0)+
        dbra d0,clbulls
        clr bully
        move #18,noclog
        tst t2k
        beq clokay
        move #21,noclog

clokay: move.l #$70007,shots
        move #32,afree
        move #1,szap_avail  ;Nuevo Superzapper!
        clr szap_on
        clr _sz
        lea spikes,a0
        move #19,d0
clsps:
        clr.l (a0)+
        dbra d0,clsps
        bsr initobjects
rsetw:
        move cwave,d0    ;move to next wave
        move d0,d1
        clr.l d2
        tst t2k
        bne dontwrap    ;t2k really does have 100 levels in the ltab...
        cmp #48,d0
        blt dontwrap
        and #$0f,d0
        lea tradmax,a0
        asl #2,d0
        move.l 0(a0,d0.w),a0  ;get looped wave pointer
        move d1,d2
        sub #48,d2
        and #$0f,d1
        add #48,d1    ;logical level no.    
        swap d2
        clr d2
        lsr.l #7,d2
        bra iwo   

dontwrap:
        lea waves,a0         ; Store the waves array in a0.
        asl #2,d0            ; d0 is cwave, multiply by 2.
        move.l 0(a0,d0.w),d0 ; Use as index into waves to get the wave data structure.
        bne iw               ; If we have one, go to iw to initialize it.
        clr cwave
        bra rsetw

iw:     move.l d0,a0         ; Move the data structure to a0.
iwo:    bsr init_wave        ; Use it to initialize the wave.
        clr pucnt

        move d1,d3
        tst t2k
        beq setemm
        move #16,d3
setemm:
        cmp #127,d3
        bne billy
        move #127,d3
billy:
        lsr #4,d3
        lea rospeeds,a0
        move.b 0(a0,d3.w),d3
        and #$ff,d3
        move d3,flip_rospeed
        lea crossdels,a0
        move.b 0(a0,d3.w),d3
        and #$ff,d3
        move.b d3,fuse_crossdelay
        move.b d3,fuse_crossdelay+1
        lea pauses,a0
        move.b 0(a0,d3.w),d3
        and #$ff,d3
        move.b d3,flip_pause
        move.b d3,flip_pause+1

        move d1,d0
        asr #1,d1
        and #$fffe,d1    ;word every 4 waves
        lea pudels,a0
        move 0(a0,d1.w),pudel  ;set pulsar phase change delay
        lea pup_stuff,a0
        move 0(a0,d1.w),pupcount  ;set powerup delay
        clr.b pupcount
        lea sz_stuff,a0
        asl #1,d0
        and #$fffc,d0    ;enery second wave
        move.l 0(a0,d0.w),d3
        add.l d2,d3
        move.l d3,spiker_zspeed
        lea fz_stuff,a0
        move.l 0(a0,d0.w),d3
        add.l d2,d3
        bsr palme
        move.l d3,flip_zspeed
        lea tz_stuff,a0
        move.l 0(a0,d0.w),d3
        add.l d2,d3
        bsr palme
        move.l d3,tank_zspeed
        lea fuz_stuff,a0
        move.l 0(a0,d0.w),d3
        add.l d2,d3
        bsr palme
        move.l d3,fuse_zspeed
        lea zs_stuff,a0
        move.l 0(a0,d0.w),zoomspeed
        move cweb,d0
        and #$7f,d0
        asr #3,d0
        and #$1e,d0
        tst h2h
        beq dntclr
        clr d0
dntclr:
        lea webcols,a0
        move 0(a0,d0.w),webcol  ;set the right colours for this web
        lea flipcols,a0
        move 0(a0,d0.w),d0
        move d0,flipcol
        lea s_flipper,a0
        bsr sfc_routine
        lea s_flip1,a0
        bsr sfc_routine
        lea s_flip2,a0
        bsr sfc_routine

        lea _web,a0
        move.l (a0),a1
        move.l #1,(a1)    ;set web all rotate
        move webcol,40(a0)
        move webcol,d0    ;paint web in current web-colour
        lsl #8,d0    ;web-colour to top of conn word
        move.l 40(a1),a1  ;now points at this object's c-list
paintweb:
        move (a1)+,d1    ;get vertex ID
        beq painted    ;zero, it's done
pverts:
        move (a1)+,d1
        and #$ff,d1    ;strip-off conn stuff
        beq paintweb    ;zero, it was last this vtx
        or d0,d1    ;merge current web-col
        move d1,-2(a1)    ;replace it
        bra pverts    ;loop for all conns this vert
painted:
        move cwave,d0    ;now set all the mutation probabilities for t2k games...
        move d0,d1
        clr sflip_prob3
        move d1,d3
        sub #16,d3
        bmi neveer
        cmp #127,d3
        ble setp3
        move #127,d3
setp3:
        lsl #1,d3
        move d3,sflip_prob3
        
neveer:
        cmp #127,d1
        ble inrng0
        move #127,d1
inrng0:
        move d1,d2
        lsl #1,d2
        move d2,sflip_prob2  
        cmp #63,d1
        ble inrnge
        move #63,d1
inrnge:
        lsl #2,d1    ;this makes SFlipper prob 1
        move d1,sflip_prob1
        asr #3,d0
        cmp #3,d0
        ble iww
        move #3,d0
iww:
        move d0,ashots
        tst beastly
        beq nomaxx
        move #7,ashots    ;Loadsa shots in Beastly Mode
nomaxx:
        move cwave,d0
        and #1,d0
        asl #2,d0
        lea fields,a0
        move.l 0(a0,d0.w),a0
        jsr (a0)      ;make starfields
        clr screaming
        clr zapdone
        move #0,max_spikers
        clr laser_type
        clr bonum
;  clr jenable
        move #0,jenable
        move.l #$38000,d0
        tst pal
        beq gnotpal
        move.l #$43333,d0    ;pal speed
gnotpal:
        tst beastly
        beq sass
        lsr.l #1,d0
sass:
        move.l d0,shotspeed
        move.l d0,bshotspeed
        bsr clzapa  
        tst t2k
        beq nt2k_reset
        move #$1c,bulland
        move #7,bullmax  
nt2k_reset:
        rts

; *******************************************************************
; palme
; *******************************************************************
palme:
        tst pal
        beq rrrts
        move.l d3,d7
        lsr.l #2,d7
        add.l d7,d3
        rts

; *******************************************************************
; sfc_routine
; *******************************************************************
sfc_routine:
        move d0,4(a0)
        move d0,52(a0)
        add #4,d0
        move d0,20(a0)
        move d0,36(A0)
        rts

bonies:
        dc.l m7scr, _tunn, m7test2, _tunn

; *******************************************************************
; sweb0
; *******************************************************************
sweb0:
        move.l #rrts,routine
        tst t2k
        beq swip1
        cmp #99,cwave
        blt wwoo
        clr _pauen
        clr pauen
        move #1,term    ;quit if someone beat t2k
        move #1,gb
        rts  
wwoo:
        tst warpy
        bpl swip1
        move #2,warpy
        move.l #screen3,a0
        move #192,d0      ;Clear screen a0
        clr d1  
        move #192,d2
        move #32,d3
        move #$000,d4
        bsr BlitBlock    ;clear off pyramids
        move.l vp_z,-(a7)
        move cweb,d0
        asr #2,d0
        and #$0c,d0
        lea bonies,a0
        move.l 0(a0,d0.w),a0
        move #1,warped
        jsr (a0)    ;<<<< do a bonus-game
        clr warped
        move #1,wason
        move.l #500,wapitch
;  move #1,screen_ready
        move.l (a7)+,vp_z
swip1:
        bsr sweb
        tst startbonus    ;check to add starting web's bonus
        beq sweb00
        move #-1,startbonus
        move.l score,a0
        lea lbonus+8,a1
        lea 8(a0),a0
        move #7,d0
        clr d1
addbon:
        move.b -(a1),d2    ;bonus digit
        add.b -(a0),d2    ;add existing score
        add.b d1,d2    ;carry over
        cmp.b #10,d2
        blt abon1    ;no carry
        sub.b #10,d2
        move #1,d1
        bra abon2
abon1:
        clr d1
abon2:
        move.b d2,(a0)    ;new score dig
        dbra d0,addbon    ;loop all digits  
sweb00:
        move.l #zoom3,routine
        move #1,sync
        move pauen,_pauen
        move #1,ud_score
        jsr clvpx
        clr outah
        lea wmes2,a0
        clr.l d0
        move.l #$8000,d1
        bsr setmsg

        move #250,msgtim1
        rts

; *******************************************************************
; swebcol
; Set the color of the web
; *******************************************************************
swebcol:
        lea _web,a0    ;set all the web to current colour
        move.l (a0),a1
        move.l #0,(a1)    ;set web all rotate
        move webcol,40(a0)
        move webcol,d0    ;paint web in current web-colour
        lsl #8,d0    ;web-colour to top of conn word
        move.l 40(a1),a1  ;now points at this object's c-list
paintwb:
        move (a1)+,d1    ;get vertex ID
        beq paintd    ;zero, it's done
pvers:
        move (a1)+,d1
        and #$ff,d1    ;strip-off conn stuff
        beq paintwb    ;zero, it was last this vtx
        or d0,d1    ;merge current web-col
        move d1,-2(a1)    ;replace it
        bra pvers    ;loop for all conns this vert
paintd:
        rts

; *******************************************************************
; swebpsych
; Set the web to psychedelic colors
; *******************************************************************
swebpsych:
        lea _web,a0    ;set all the web to psychedelic colours
        move.l (a0),a1
;  move.l #0,(a1)    ;set web all rotate
        move frames,d7
        asl #1,d7
        tst holiday
        bmi kzkk
        asl #2,d7
kzkk:
        bsr pulser
        move d6,40(a0)
        move.l 40(a1),a1  ;now points at this object's c-list
pintwb:
        move (a1)+,d1    ;get vertex ID
        beq pintd    ;zero, it's done
pers:
        add #2,d7
        bsr pulser
        move d6,d0    ;paint web in current web-colour
        lsl #8,d0    ;web-colour to top of conn word
        move (a1)+,d1
        and #$ff,d1    ;strip-off conn stuff
        beq pintwb    ;zero, it was last this vtx
        or d0,d1    ;merge current web-col
        move d1,-2(a1)    ;replace it
        bra pers    ;loop for all conns this vert
pintd:
        rts




fields:
        dc.l siney,siney

; *******************************************************************
; circa
; *******************************************************************
circa:
        bsr slebon    ;set level bonus

;  lea testmap,a1
;  bra initmstarfield  ;mapped star field init

        clr.l d4
        move cwave,d4
        asl.l #8,d4
        asl.l #6,d4
        add.l #$60000,d4
;  move.l #$72000,d4
        move.l d4,d5
        move cwave,d0
        and #$7f,d0
        add #$40,d0
        move d0,d7
        swap d7
        bra ips

slebon:
;
; set level bonus at 5800+(level*100)

        clr.l lbonus
        clr.l lbonus+4
        move cwave,d0
        move d0,d1
        mulu #200,d1
        add.l #2600,d1
        mulu d0,d1
        lea lbonus+8,a0
        move.l d1,d2
        divu #10000,d2    ;d2 is highest 4 digits
        and.l #$ffff,d2
        move d2,d3
        mulu #10000,d3
        sub.l d3,d1
        move #3,d3
xlebon:
        divu #10,d1
        swap d1
        move.b d1,-(a0)
        clr d1
        swap d1
        dbra d3,xlebon
xleb2:
         divu #10,d2
        swap d2
        move.b d2,-(a0)
        clr d2
        swap d2
        tst d2
        bne xleb2

;  tst d1
;  beq dlebon
;  bra xlebon
dlebon:
        move.l #lbonus,score
;  move #1,ud_score
        bra setcsmsg
        rts
;  bra ashowscore    ;show level bonus as score

; *******************************************************************
; siney
;
; make a siney star field
; *******************************************************************
siney:

        move cwave,d0
        cmp #31,d0
        bne sinies
        move #163,d0
sinies:
        and #$ff,d0
        move d0,d4
;  and #$01f,d4  
ondd:
        add #$01,d4
        asl #1,d4
        move d4,d5
        swap d4
        clr d4
        lea rantab,a1
        move.b 0(a1,d5.w),d0
        and #$7f,d0
        add #$04,d0
        add d0,d5
        swap d5
        clr d5
        clr.l d6
        move.l #$400000,d7
ips:
        bra initpstarfield
        

; *******************************************************************
; makedroid
; *******************************************************************
makedroid:
        cmp #2,players
        beq rrts    ;no Droid in 2p mode
        cmp #2,entities
        bne rrts    ;2 entities and not 2p, it's droidytime
mkdroid:
        move.l freeobjects,a0
        sub #1,ofree
        move.l _cube,(a0)
        move #webz-90,12(a0)
        move web_firstseg,d0
        add #2,d0
        move d0,16(a0)
        clr 18(a0)
        clr.l 20(A0)
        clr.l 24(a0)
        clr.l 28(a0)
        clr 32(a0)
        move #0,34(a0)
        move #136,40(a0)
        move #-1,42(a0)
        clr 44(a0)      ;New Mode=get target
        clr 52(a0)
        move #21,46(a0)
        move #17,54(a0)      ;use Rez Claw stuff
        move.l a0,a6
        bsr toweb      ;Attach the droid to the web
        bsr set_rezclaw
        bra insertobject

; *******************************************************************
; rundroid
; *******************************************************************
rundroid:
        clr whichclaw
        add #1,28(a6)      ;Universal stuff; flash and rotate the cube
        add #2,30(a6)
        add #3,32(A6)
        move flashcol,40(A6)

        cmp #2,entities      ;did we start with 2 entities (driod is permanent)?
        beq always_2
        cmp #-2,wave_tim
        bne always_2
        move #1,50(a6)      ;FG Unlink Please
        rts

always_2:
        sub.b #1,droidel      ;Droid's firing rate
        bpl nodfire
        move.b droidel+1,droidel
        tst locked
        bne nodfire
        tst shots+2
        bmi nodfire    
        cmp #1,34(a6)
        bne nodfire
        sub #1,shots+2
        move.l a6,a1
        move #$80,d7      ;marker for bullets to distinguish pl. 1 and pl 2 shots
        move.l _chevre,d5    ;graphic is the chevron
        bsr frab0      ;frab0 is fire w. arbitrary graphic
nodfire:
        tst 44(a6)
        bne movedroid      ;mode non0 means droid is moving.

        move droid_data,d0    ;this is the closest enemy to the top of the Web
        bsr lor        ;ask Left or Right to get there
        bne droidright      ;init droid motion to the right.
        bra droidleft      ;init droid motion to the left.

movedroid:
        move.l 20(a6),d0
        add.l d0,4(a6)
        move.l 24(a6),d0
        add.l d0,8(a6)      ;Move droid along its vector.
        sub #1,44(a6)      ;dec timer, will fall thru to zero and seek a new targ.  
        cmp #8,44(a6)      ;half way along the logical lane no. needs to change over
        bne rrts
        move 48(a6),16(a6)    ;do that very Thang
        rts

; *******************************************************************
; droidright
;
; init Droid motion to the right.
; *******************************************************************
droidright:

        bsr webinfo
        move d4,d6
        move d5,d7
        bsr r_webinfo
        bra droim

; *******************************************************************
; droidleft
;
; Init droid motion to the left along the Web.
; *******************************************************************
droidleft:

        bsr webinfo      ;get info on our lane
        move d4,d6
        move d5,d7      ;preserve midpoint of our channel
        bsr l_webinfo      ;get info on the channel to the left
droim:
        swap d4
        clr d4
        swap d5
        clr d5
        swap d6
        clr d6
        swap d7
        clr d7        ;co-ordinates to 16:16 fractions
        sub.l d6,d4
        sub.l d7,d5      ;get vector towards destination
        asr.l #4,d4
        asr.l #4,d5      ;vector /16
        move.l d4,20(a6)
        move.l d5,24(a6)    ;store the vector
        move d0,48(a6)      ;dest channel-#
        move #16,44(a6)      ;# steps
        rts  
        
; *******************************************************************
; lor
; left or right
; enter with d0=web column # of target. For any web, returns d1=0 for go left, 1 for go right, based on a6 object's position.
; *******************************************************************
lor:

        move 16(a6),d1      ;Flipper current pos
        cmp d0,d1
        bne nntrv
        tst auto
        beq nntrv
        move #-1,d1
        rts
nntrv:
        tst connect
        bne _lor1      ;Wrap mode if web is circular
        sub d0,d1
        bgt lor0
        ble lor1
;  bra zz
_lor1:
        move web_max,d2
        asr #1,d2      ;half distance around web
        sub d0,d1
        bgt _lll
        ble _rrr
;  bra zz
_lll:
        sub d2,d1
        blt lor0
        bra lor1
_rrr:
        neg d1
        sub d2,d1
        blt lor1


lor0:
        clr d1
        rts
lor1:
        move #1,d1
        rts

; *******************************************************************
; h2hclaws
; *******************************************************************
h2hclaws:
        move.l freeobjects,a6
        move.l a6,_claw
        move.l a6,a0
        move.l #0,(a0)
        clr.l 4(A0)
        clr.l 8(A0)
        move #webz-80,d0
        swap d0
        clr d0
        move.l d0,12(a0)
        move.l web_firstseg,16(a0)
        clr.l 20(a0)
        move.l #$400,24(a0)
        clr.l 28(a0)
        clr.l 32(a0)
        move.l claws,36(a0)
        move #255,40(a0)
        move #1,42(a0)
        move #150,48(a0)
        clr.l 50(a6)
        move #17,54(a6)
        jsr insertobject
        move.l freeobjects,a0
        move.l a0,a6
        move.l #0,(a0)
        clr.l 4(A0)
        clr.l 8(A0)
        move #webz+80,d0
        swap d0
        clr d0
        move.l d0,12(a0)
        move.l web_firstseg,d0
        add.l #2,d0
        move.l d0,16(a0)
        clr.l 20(a0)
        move.l #$400,24(a0)
        clr.l 28(a0)
        clr.l 32(a0)
        move.l claws,36(a0)
        move #$8f,40(a0)
        move #1,42(a0)
        move #150,48(a0)
        clr.l 50(a6)
        move #17,54(a6)
        jsr insertobject

        move #webz-76,d0    ;make the players' mirrors.  Always at (C-2) object.
        bsr makemirr
        move #webz+76,d0
makemirr:
        swap d0
        clr d0
        move.l freeobjects,a0
        move.l #-13,(a0)
        clr.l 4(a0)       ; Clear X position
        clr.l 8(a0)       ; Clear Y position
        move.l d0,12(a0)  ; Clear Z position.
        clr.l 16(a0)      ; Clear position on web.
        clr 20(a0)        ; Clear velocity.
        clr 28(a0)        ; Clear XZ orientation.
        move #0,34(a0)    ; Clear draw routine.
        clr.l 50(a0)      ; Make sure not marked for deletion.
        move #31,54(a0)   ; Set object type to claw.
        jmp insertobject

; *******************************************************************
; setclaw
; *******************************************************************
setclaw:
        move.l a6,a0
        move.l claws,(a6)    ;claw header
        clr.l 4(a6)
        clr.l 8(a6)    ;initial X and Y position
        move.l #webz-80,d0
        swap d0      ;initial Z position
        move.l d0,12(a6)
        move.l web_firstseg,16(a6)    ;web position
        clr.l 20(a6)    ;clear CLAWV
        move.l #$400,24(a6)  ;clear CLAWA
        clr.l 28(a6)
        clr 32(a6)    ;initial X,Y,Z rotation is zero
        move #0,34(a6)    ;no draw at first, it will be Z-TRAIL...
        move #255,40(a6)    ;yellow, the proper colour for a Tempest claw
        move #1,42(a6)    ;scaler value
        move #$0303,48(a6)  ;fire timer  (0303 std)
        tst beastly
        beq knobby
        move #$0606,48(a6)
knobby:
        cmp #2,players
        beq setdouble
        move #16,46(a6)
        bra set_rezclaw    ;Not 2-player simul mode
setdouble:
        move d7,d0
        add #14,d0
        move d0,46(a0)    ;Select appropriate clawcon routine; save it in 44()
        cmp #1,d7    ;this routine entered with player claw no. in d7
        bne set_rezclaw    ;modifications for player 2's claw
        move #95,40(a0)    ;Colour of second claw
        add #2,16(a0)    ;Second claw rezzes nearby
set_rezclaw:
        move #$f000,36(a6)
        move #2,44(a6)
        move #17,54(a6)
        move #0,34(a6)    
        move #-1,38(a6)
        move #0,52(a6)
        rts

; *******************************************************************
; make_bits
; Make the vector based objects.
; *******************************************************************
make_bits:
        move.l #$00,d0      ;parameters for object - XYZ scale...
        move.l #$01,d1
        move.l #$01,d2  
        move.l #0,d3      ;..local centre x,y,z...
        move.l #0,d4
        move.l #0,d5  
        clr.l d6
        clr d7
        lea ev,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_ev
        lea la_routine,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_la
        lea pu,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_pu
        move.l #$00,d0      ;parameters for object - XYZ scale...
        move.l #$01,d1
        move.l #$01,d2  
        move.l #9,d3      ;..local centre x,y,z...
        move.l #9,d4
        move.l #0,d5  
        clr.l d6
        clr d7        ;standard stuff...
        lea shot,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_shot
        lea chevre,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_chevre

        lea flipper,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_flipper
        lea zap,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_zap
        lea fliptank,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_fliptank
        lea fusetank,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_fusetank
        lea pulstank,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_pulstank
        lea spike,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_spike
        lea spiker,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_spiker
        lea fuse1,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_fuse1
        lea fuse2,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_fuse2
        lea b250,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_bons
        lea b500,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_bons+4
        lea b750,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_bons+8
        lea oneup,a1
        movem.l d0-d7,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7
        move.l a0,_oneup
        lea raw_pus,a2
        lea _pus,a3
mkpus:
        move.l (a2)+,a1
        movem.l d0-d7/a1-a3,-(a7)
        bsr make_vo3d
        movem.l (a7)+,d0-d7/a1-a3
        move.l a0,(a3)+
        cmpa.l #pu6,a1
        bne mkpus

        move.l #1,d0    ;this object wants 3-axis rotation
        move.l #2,d3
        move.l #2,d4
        move.l #2,d5
        lea cube,a1
        bsr make_vo3d
        move.l a0,_cube

        rts


; *******************************************************************
; make_claws
; *******************************************************************
make_claws:
        lea uclaws,a6
        lea claws,a5
        move.l #$00,d0      ;parameters for object - XYZ scale...
        move.l #$01,d1
        move.l #$01,d2  
        move.l #9,d3      ;..local centre x,y,z...
        move.l #9,d4
        move.l #0,d5
        clr.l d6      ;initial orientation
        move #7,d7
mclaws:
        move d7,-(a7)
        clr d7
        move.l (a6)+,a1
        movem.l d0-d6,-(a7)
        bsr make_vo3d  
        movem.l (a7)+,d0-d6
        move.l a0,(a5)+
        move (a7)+,d7
        dbra d7,mclaws
        rts

; *******************************************************************
; make_webs
; *******************************************************************
make_webs:
        lea raw_webs,a6
        lea webs,a5
;  move #15,d7
mk_webs:
        movem.l a5-a6/d7,-(a7)
        move.l (a6),a1
        move.l #40,a2
        move.l #1,d0    ;RMODE. 0=only XY rotate
        move.l #1,d1
        move.l #1,d2
        move.l #8,d4
        clr.l d6
        clr d7
        lea 32(a5),a5
        bsr extrude
        movem.l (a7)+,a5-a6/d7
        lea 4(a6),a6
        move.l a0,(a5)
        move.l web_otab,4(a5)
        move.l web_ptab,8(a5)
        move web_max,12(a5)
        move.l web_firstseg,14(a5)
        move web_x,18(a5)
        move web_z,20(a5)
        move connect,22(a5)
        lea 128(a5),a5
        move.l (a6),d7
        bne mk_webs
        rts

; *******************************************************************
; fire
;
; check for firebutton 2 and do superzapper.
; *******************************************************************
fire:

;  btst.b #1,pad_now    ;check for Superzapper request
        move.l fire_3,d0
        move.l pad_now,d1
        cmp #2,players      ;combine players firebuttons in 2pl mode
        bne snglsmart
        move.l pad_now+4,d2
        move d1,d3
        or d2,d3      ;combined...
        and.l d0,d3
        beq rrts      ;no-one smarted
        tst szap_avail
        bmi rrts      ;someone smarted, but it wasn't available
        tst szap_on
        bne rrts      ;someone smarted, but it's already happening
        clr p2smarted
        and.l d0,d2      ;did player 2 smart?    
        beq snglsmart
        move #1,p2smarted    ;Player 2 smarted!
        bra gsmart    
snglsmart:
        and.l d0,d1
        beq rrts
        tst szap_avail
        bmi rrts      ;You already had it!
        tst szap_on
        bne rrts      ;You are already Superzapping!
gsmart:
        sub #1,szap_avail
        bmi nmsg
        lea zmes1,a0
        clr.l d0
        move.l #$8000,d1
        bsr setmsg
nmsg:
        move #1,szap_on      ;Start the sizzle...
        move #7,sfx
        move #10,sfx_pri
        jsr fox
        rts  


; *******************************************************************
; h2hfrab
; *******************************************************************
h2hfrab:
        
        move.l d0,-(a7)  
        move #1,sfx
        move #1,sfx_pri
        jsr fox
        move.l freeobjects,a0    ;address of new shot
        lea bulls,a3
hgoaty:
        move bully,d0
        move bulland,d1
        and d1,d0
        lea 0(a3,d0.w),a2    ;point to this bulls slot
        move.l (A2),d0
        beq hfreeslot
        add #4,bully
        bra hgoaty      ;find 1
hfreeslot:
        add #4,bully
        move.l a0,(a2)          ;store address of this bull
        move.l a2,24(a0)        ;store slot addr. in bull
        move.l #-14,(a0)        ;header of shot data
        move.l 4(a1),4(a0)
        move.l 8(A1),8(a0)
        move.l 12(a1),12(a0)    ;XYZ same as claw
        move.l 16(a1),16(a0)    ;Web position from claw
        clr.l 28(a0)
        clr 32(a0)      ;Zero roll, pitch and yaw
        move #1,34(a0)      ;Std. draw
        move.l (a7)+,36(a0)    ;get saved velocity
        move #0,32(a0)      ;bullet ID (player ownership) changed from 44() to 32()
        move #1,52(a0)    ;not alien and Type
        move #32,54(a0)
        bra insertobject


; *******************************************************************
; run_h2hshot
; *******************************************************************
run_h2hshot:
        add #3,28(a6)    ;make it flicker
moomoomoo:
        move.l 36(a6),d0
        bmi upweb
        add.l d0,12(a6)
        move 12(a6),d0    ;this bull's Z
        move 16(a6),d1
        move.l _claw,a4
        move.l 56(a4),a4  ;p2's Claw
        move.l 56(a4),a4  ;p1's Shield
        move.l 56(a4),a4  ;p2's Shield
        cmp 12(a4),d0    ;check against the Shield
        bmi np2sh    
        tst practise
        bne reflshot
        cmp 16(a4),d1
        bne np2sh    ;check for same lane
        tst 34(a4)    ;is it On?
        beq biu2
reflshot:
        neg.l 36(a6)
        move #$13,sfx
        move #3,sfx_pri
        jsr fox
        bra moomoomoo  
np2sh:
        cmp #webz+81,12(a6)
        bmi rrts
kllit:
        move.l 24(a6),a1
        clr.l (a1)    
        move #3,50(a6)
        rts
upweb:
        add.l d0,12(a6)
        move.l _claw,a4
        move.l 56(a4),a4  ;p2's Claw
        move.l 56(a4),a4  ;p1's Shield
        move 16(a6),d0
        cmp 16(a4),d0
        bne np1sh    ;same lane chec
        move 12(a6),d0    ;this bull's Z
        cmp 12(a4),d0    ;check against the Shield
        bpl np1sh
        tst 34(a4)    ;is it On?
        beq biu1
        neg.l 36(a6)
        move #$13,sfx
        move #3,sfx_pri
        jsr fox
        bra moomoomoo  
np1sh:
        cmp #webz-81,12(a6)
        bmi kllit
        rts

biu2:
        bsr biu
        bra np2sh
biu1:
        bsr biu
        bra np1sh

biu:
        move.l 60(a4),a4
        move.l 60(a4),a4  ;point at the Claw we hit
h2hckill:
        tst _won
        bpl rrts
        tst 48(a4)
        bne rrts
        move #-1,48(a4)    ;start it exploding!
        bsr zson    ;make it go boom
        cmp.l _claw,a4
        beq bunce_p2
bunce_p1:
        add #1,l_sc
        move #1,l_ud
        cmp #4,l_sc
        bne rrts
        move.b #'1',wonmsg+7
        add #1,p1wins
        lea wonmsg,a0
showwin:
        move #180,_won
        clr.l d0
        move.l #$8000,d1
        bra setmsg
        
bunce_p2:
        add #1,r_sc
        move #1,r_ud
        cmp #4,r_sc
        bne rrts
        tst practise
        bne p2_prac
        move.b #'2',wonmsg+7
        add #1,p2wins
        lea wonmsg,a0
        bra showwin
p2_prac:
        lea wonprc,a0
        bra showwin


; *******************************************************************
; frab
;
; fire a bullet
; *******************************************************************
frab:
        move.l _shot,d5
        
frab0:
        move.l freeobjects,a0    ;address of new shot
        lea bulls,a3
goaty:
        move bully,d0
        move bulland,d1
        and d1,d0
        lea 0(a3,d0.w),a2    ;point to this bulls slot
        move.l (A2),d0
        beq freeslot
        add #4,bully
        bra goaty      ;find 1
freeslot:
        add #4,bully
        move.l a0,(a2)      ;store address of this bull
        move.l a2,24(a0)    ;store slot addr. in bull
        move.l d5,(a0)    ;header of shot data
        move.l 4(a1),4(a0)
        move.l 8(A1),8(a0)
        move.l 12(a1),12(a0)    ;XYZ same as claw
        move.l 16(a1),16(a0)    ;Web position from claw
        clr.l 28(a0)
        clr 32(a0)      ;Zero roll, pitch and yaw
        move #1,34(a0)      ;Std. draw
        move #$88,40(a0)    ;Colour
        move #1,42(a0)      ;Fine rez
        move d7,32(a0)      ;bullet ID (player ownership) changed from 44() to 32()
        move.l #1,52(a0)    ;not alien and Type
        tst blanka
        bne oaafire
        move #1,sfx
        jsr fox
        bra insertobject

oaafire:
        move.l #$b6000a,d0
        move.l #$070007,d1
        tst 32(a0)
        beq konk
        move.l #$b60000,d0
        move.l #$090009,d1
konk:
        move.l #$10000,d2
        move.l #$10000,d3
        move.l #-9,(a0)
        move #5,34(a0)    ;pixex draw
;  move #10,34(a0)    ;pixex draw
        move.l d3,42(a0)  ;initial pixel expansion
        move.l d0,36(a0)
        move.l d1,46(a0)  
        move.l d2,20(a0)
        tst laser_type
        bne oaafire2
        move #5,sfx
        move #1,sfx_pri
        jsr fox
        jmp insertobject
oaafire2:
        move #10,34(a0)
        move #$0b,sfx
        move #1,sfx_pri
        jsr fox
        bra insertobject    ;Do it!

; *******************************************************************
; make_h2hball
; *******************************************************************
make_h2hball:
        move.l freeobjects,a0
        move web_max,d1
        jsr rand
        move #webz,d1
        swap d1
        clr d1
        move.l d1,12(a0)
        move d0,16(a0)
        move #-1,18(a0)      ;Timer for player zappage
        clr.l 30(a0)
        clr 20(a0)
        move #1,34(a0)
        move.l #-18,(a0)
        clr.l 50(a0)
        bsr rannum  
        sub #$80,d0
        move d0,22(a0)      ;Direction to move, + or -
        move #$0404,24(A0)    ;Speed of motion
        clr 48(a0)
        move #34,54(a0)
        move.l a0,a6
        jsr toweb
        jmp insertobject

; *******************************************************************
; run_h2hball
; *******************************************************************
run_h2hball:
        add #3,30(a6)
        add #1,32(a6)
        tst 18(a6)
        bmi inspr
        sub #1,18(a6)
inspr:
        move 20(a6),d0
        lea h2hballmodes,a0  
        lsl #2,d0
        move.l 0(a0,d0.w),a0
        jsr (a0)

        bsr collie
        beq hballmove
        move #$2,d0
        tst h2h_sign
        bpl hball
        neg d0
hball:
        move d0,48(a6)
hballmove:
        move 48(a6),d0
        swap d0
        clr d0
        asr.l #2,d0
        add.l d0,12(a6)
        cmp #webz+80,12(A6)
        bpl got_someone
        cmp #webz-80,12(a6)
        bpl rrts
got_someone:
        move #30,18(a6)
        cmp #webz,12(a6)
        bgt zp2
        move.l _claw,a4
xeq:
        neg 48(a6)
        bra h2hckill
zp2:
        move.l _claw,a4
        move.l 56(a4),a4
        bra xeq


h2hballmodes:
        dc.l gstartmove,gmove,breset


; *******************************************************************
; breset
; *******************************************************************
breset:
        clr 20(a6)
        rts

; *******************************************************************
; make_h2hgen
; *******************************************************************
make_h2hgen:
        move.l freeobjects,a0
        move.l #-15,(a0)
        move d0,d2
        move #webz,d0
        swap d0
        clr d0
        move.l d0,12(a0)    ;start Z-pos
        move.l #$30000,d1      ;start web position
        move.l d1,16(a0)
        move #0,20(a0)      ;Mode. 0=Move in direction
        bsr rannum
        sub #$80,d0
        move d0,22(a0)      ;Direction to move, + or -
        move d2,24(A0)    ;Speed of motion (delay between 1/16 steps)
        move #1,34(a0)
        clr.l 50(a0)
        move #33,54(a0)
        move.l a0,a6
        bsr toweb  
        bra insertobject

; *******************************************************************
; run_h2hgen
; *******************************************************************
run_h2hgen:
        add #1,28(a6)

        move 20(a6),d0
        lea h2hgenmode,a0
        lsl #2,d0
        move.l 0(a0,d0.w),a0
        jsr (a0)

        bsr collie
        beq rrts      ;check for shots moving this object
        tst practise
        bne rrts
        tst h2h_sign
        bmi hupweb
        cmp #webz+50,12(a6)
        bpl rrts      ;already close enough
        add #1,12(a6)
        rts
hupweb:
        cmp #webz-50,12(a6)
        bmi rrts
        sub #1,12(a6)
        rts

h2hgenmode:
        dc.l gstartmove,gmove,ggen

; *******************************************************************
; gstartmove
; *******************************************************************
gstartmove:
         bsr webinfo      ;get info on our lane
        move d4,d6
        move d5,d7      ;preserve midpoint of our channel
gsmove:
        tst 22(a6)
        bmi gleft  
        bsr r_webinfo
        bra ggot
gleft:
        bsr l_webinfo      ;get info on the channel to the left
ggot:
        cmp d4,d6
        bne nuchan
        cmp d5,d7
        bne nuchan      ;check for channel the same (hit the edge of the web)
        neg 22(a6)
        bra gsmove      ;go init move other direction
nuchan:
        swap d4
        clr d4
        swap d5
        clr d5
        swap d6
        clr d6
        swap d7
        clr d7        ;co-ords to 16:16 fractions
        sub.l d6,d4
        sub.l d7,d5      ;get vector towards destination
        asr.l #4,d4
        asr.l #4,d5      ;vector /16
        move.l d4,36(a6)
        move.l d5,40(a6)    ;store the vector
        move d0,46(a6)      ;dest channel-#
        move #16,44(a6)      ;# steps
        move #1,20(a6)      ;mode to Do Motion
        rts  

; *******************************************************************
; gmove
; *******************************************************************
gmove:
        sub.b #1,24(a6)
        bpl rrts      ;motion delay
        move.b 25(a6),24(a6)    ;reset it
        move.l 36(a6),d0
        add.l d0,4(a6)
        move.l 40(a6),d0
        add.l d0,8(a6)      ;move 1/16 of the way to target
        cmp #8,44(a6)
        bne gmove1      ;check for halfway acress
        move 46(a6),16(a6)    ;set dest channel=our channel
gmove1:
        sub #1,44(a6)
        bne rrts
        move #2,20(A6)      ;Mode to generate enemies
        rts

; *******************************************************************
; ggen
; *******************************************************************
ggen:
        clr 20(A6)
        tst _won
        bpl rrts
        cmp #1,afree
        ble rrts
        sub #2,afree
        move.l a6,a5    ;mummy's address save
        move.l freeobjects,a6
        bsr newflipper      ;new flipper in this lane
        jsr toweb
        bsr flip_set_right
        move.l #$00010001,44(A6)
        move #3,48(a6)
        move #-1,38(a6)      ;tells it to stop Flipping after one flip
        move.l freeobjects,a6
        bsr newflipper
        jsr toweb
        move.l #$0001ffff,d0
        tst practise
        beq arse
        neg d0
arse:
        move.l d0,44(A6)
        move #-3,48(a6)
        bsr flip_set_left
        move.l #-19,(a6)  ;blue Flipper
        move #-1,38(a6)
        move.l a5,a6
        rts

; *******************************************************************
; player_shot
; *******************************************************************
player_shot:
;
; move a standard Tempest player's shot

        add #8,28(a6)      ;spin it
        add.b #$30,41(a6)    ;make it flash
        move.l shotspeed,d0
        add.l d0,12(a6)    ;move me on the z axis baby  $38000 std
        cmp #webz+80,12(a6)
        blt rrts
        move.l 24(a6),a1
        clr.l (a1)    
kill_shot:
        move.l a6,a0
        move #3,50(a6)      ;tell FG to unlink
;  bra unlinkobject  
        rts

xshot:
        add #3,30(a6)
        cmp #30,30(a6)
        bgt kill_shot
        rts

; *******************************************************************
; alienfire
;
; try and shoot from the current alien
; *******************************************************************
alienfire:

        sub.b #1,a_firerate
        bpl rrts
        move.b a_firerate+1,a_firerate
afid:
        cmp #-2,wave_tim
        beq rrts  
        tst ashots
        bmi rrts
        cmp #webz-20,12(a6)
        ble rrts      ;Cannot fire really close to the top of the Web
        move.l freeobjects,a0
        sub #1,ashots
        sub #1,afree
        move.l _shot,d0
        clr 20(a0)
        tst blanka
        beq vfyre
;  bsr rannum
;  cmp sflip_prob1,d0
;  bmi slongfur  
        move.l #-3,d0
        bra vfyre
slongfur:
        move.l #-7,d0
        move #1,20(a0)
vfyre:
        move.l d0,(a0)    ;header of shot data
        move.l 4(a6),4(a0)
        move.l 8(A6),8(a0)
        move.l 12(a6),12(a0)    ;XYZ same as firer
        move.l 16(a6),16(a0)    ;Web position from claw
        clr.l 28(a0)
        clr 32(a0)      ;Zero roll, pitch and yaw
        move #1,34(a0)      ;Std. draw
        move #$48,40(a0)    ;Colour
        move #0,42(a0)      ;Std rez (make larger than player's shots)
        clr 44(a0)      ;to allow shots to fly off of web
        move #1,52(a0)
        move #8,54(a0)      ;type is alien-shot
        bra insertobject    ;Do it!

; *******************************************************************
; run_ashot
; *******************************************************************
run_ashot:
        add #4,28(a6)    ;spin the shot
        add.b #$30,41(a6)    ;make it flash
        move.l ashot_zspeed,d0
        sub.l d0,12(a6)      ;move up the z-axis
;  tst 44(a6)
;  bne rash1
        bsr xzcollie
        bne kill_ashot    
        move #webz-80,d0
        tst 20(a6)
        beq chove
        move #10,d0
chove:
        cmp 12(a6),d0
;  blt rrts
        bpl rash1
;  move #1,44(a6)
        bsr checlane
        bne rrts
shouch:
        cmp #-2,wave_tim
        beq rrts      ;in case any find us while we zoom
        move.l a0,-(a7)
        lea gmes2,a0
        clr.l d0
        move.l #$8000,d1
        bsr setmsg
        move.l (a7)+,a0
        bsr ouch
        bra kill_ashot
rash1:
        add #13,30(a6)
        add #15,32(a6)      ;make it tumble once it leaves the web
        tst 12(a6)
        move #2,50(a6)      ;tell FG to unlink
        rts

kill_ashot:
        add #1,ashots
        bra killme  

ouch:
        clr l_soltarg
        clr.l 20(a0)      ;stop Claw moving  
        tst lives
        beq ouch1p
        cmp #2,players
        bne ouch1p
        move #20,54(a0)      ;blow up one claw while allowing play to proceed with the other
        move #0,52(a0)
        bra ow

ouch1p:
        move.l #zap_player,routine
ow:
        move.l _zap,(a0)    ;Claw shape to zap
        clr 36(a0)
        bsr clzapa
        clr laser_type
        clr jenable
        clr bonum
        move.l bshotspeed,shotspeed
        move #-17,38(a0)
        move #3,44(a0)
        move #2,34(a0)      ;set claw to ztrail
        bra zapson

tsphkillme:
        move #2,48(a6)  ;spheres density 1-4
        bra ospher

sphkillme:
        move #1,48(a6)
ospher:
        bsr rannum  
        and #$f,d0
        lsl #4,d0
        move d0,46(a6)
        bra kime

; *******************************************************************
; killme
;
; Start the current object exploding.
; *******************************************************************
killme:

        move #$10,d0
        move d0,sfx
        move #2,sfx_pri
        bsr rannum
        and.l #$ff,d0
        add.l #128,d0
        move.l d0,sfx_pitch
        jsr fox
        bra sphkillme

;##### New shit
        
        clr 48(a6)
kime:
        move #0,54(a6)
        move #9,34(a6)
        rts


; *******************************************************************
; changex
; *******************************************************************
changex:
        bsr webinfo

        tst blanka
        beq vectorzap      ;Enhanced mode uses pixel explosion graphics

        tst bolt_lock
        beq nobobo

        tst t2k
        beq nobobo    ;powerups only on t2k

dpring:
        move #11,34(a6)      ;get ready for Pring explosion
        move #16,46(a6)
        clr 44(a6)
        move #24,54(a6)
        tst h2h
        beq rrts
        move #1,34(a6)
        move.l #-17,(a6)
        rts

nobobo:
        sub.b #1,pupcount
        bpl nopup
        move.b pupcount+1,pupcount
        tst t2k
        beq nopup
        tst h2h
        bne nopup
        move #9,sfx
        move #3,sfx_pri
        jsr fox
        bsr toweb
        move #1,34(a6)
        move #300,48(a6)  ;initial rez diameter
        move #$0a,44(a6)
        move bonum,46(a6)
        move.l #-10,(a6)
        clr 52(a6)
        move #25,54(a6)    ;type PUP  
        cmp #3,cwave
        bgt noidiot
        lea pupmes,a0
        clr.l d0
        move.l #$8000,d1
        bsr setmsg
noidiot:
        rts
badd:
        cmp #7,bonum
        beq rrts    ;check for max pu
        add #1,bonum
        rts

nopup:
        cmp #2,48(a6)
        beq setsphk
        clr 48(a6)
        bra dpring

setsphk:
        move #1,48(a6)
        move.l #$9e0000,d0
        move.l #$180018,d1
        move.l #$10000,d2
        move.l #$10000,d3
        move.l 46(a6),d4
        bsr xpixex
        move.l d4,46(a6)
        move #13,34(a6)
        rts

; *******************************************************************
; xpixex
; *******************************************************************
xpixex:
        move #5,34(a6)    ;pixex draw
        clr 52(a6)
        move #22,54(a6)
        move.l d3,42(a6)  ;initial pixel expansion
        move.l d0,36(a6)
        move.l d1,46(a6)  
        move.l d2,20(a6)
        rts

; *******************************************************************
; run_pup
; *******************************************************************
run_pup:
        tst 48(a6)
        bmi domopup
        sub #4,48(a6)
        rts
domopup:
        cmp #$0a,44(a6)
        bne xtoend
        bsr checlane_only
        bne notonl  
        move 12(a6),d0
        sub 12(a0),d0
        bmi notonl
        cmp #32,d0
        bgt notonl

doita:  move #9,sfx
        move #3,sfx_pri
        move.l #428,sfx_pitch
        jsr fox

        cmp #-2,wave_tim
        beq stdpu1    ;NEVER if zooming!!!
        cmp #1,dnt
        bne stdpu1
        move #-1,dnt
        move #$0b,44(a6)  
        lea puptxt2,a0
        clr.l d0
        move.l #$8000,d1
        bsr setmsg
        bra adenoid    ;Get the early Droid if we got this
        
stdpu1:
        cmp #-2,wave_tim  ;if we are zooming give a droid next time
        bne stdpu
        tst dnt
        bne agdroid
        move #$0b,44(a6)  
        lea drtxt,a0
        clr.l d0
        move.l #$8000,d1
        bsr setmsg    ;display text on messager
        jsr zoomoff
        jsr yeson
        move #1,dnt    ;droid first thing next time
        rts

agdroid:
        move #1,bonum

stdpu:
        move bonum,d2
        cmp #4,d2
        bne nadr
        tst dnt
        bpl nadr
        add #1,bonum
        add #1,d2    ;in case we already had the early droid
nadr:
        asl #2,d2
        cmp #20,d2    ;special case if warp Thang
        bne pupdoo

        lea wtxts,a0
        move warpy,d3
        bpl dopoo1
        clr d3
dopoo1:
        lsl #2,d3
        move.l 0(a0,d3.w),a0
        move #1,show_warpy
        bra juju

pupdoo:
        lea puptxts,a0
        move.l 0(a0,d2.w),a0
juju:
        clr.l d0
        move.l #$8000,d1
        bsr setmsg    ;display text on messager

;  move 46(a6),d0
        move bonum,d0  
        lea pupvex,a0
        asl #2,d0
        move.l 0(a0,d0.w),a0
        jsr (a0)    ;do powerup thang for this type
        move #$0b,44(a6)  
        bra badd
notonl:
        sub.l #$18000,12(a6)
        cmp #webz-80,12(a6)
        blt dpring
;  bmi doita  ;-----
        rts
xtoend:
        add #5,44(a6)
;  add #10,12(a6)
        cmp #255,44(a6)
        blt rrts
        move #1,50(a6)
        rts
pupvex:
        dc.l hilaser,suprise,jenab,suprise,addroid,sprzap,suprise,suprise

; *******************************************************************
; suprise
; *******************************************************************
suprise:
        tst startbonus
        bne bonnk
        jsr rannum
        cmp #$08,d0
        bgt bonnk
        move #1,szap_on
        move #1,inf_zap    ;Infinite zapper yeah!

; *******************************************************************
; "Get outtah here!" Skips to the next level? 
; Only called when cheat is enabled.
; *******************************************************************
douttah:
        lea ohtxt,a0     ; Set message to "Outtah here!"
        clr.l d0         ; Set message x position. 
        move.l #$8000,d1 ; Set message y position.
        bsr setmsg       ; Set message.
        move #1,outah    ; 
        move #13,d0      ; Give 3,000 points.
        jsr doscore      ; Update score.
        move.l #pic,a2      ; Select beasty3.cry
        move.l #$6e0089,d0  ; Snip out the x pos for the 'Excellent' graphic
        move.l #$2a00b2,d1  ; Snip out the y pos for the 'Excellent' graphic
        jsr any_pixex       ; Display the 'Excellent' graphic.
        jmp szoom           ; Go get us away....

; *******************************************************************
; bonnk
; *******************************************************************
bonnk:  move.l #pic5,a2
        move.l #$540004,d0
        move.l #$4100c5,d1
        jsr any_pixex
        move #12,d0
        jmp doscore    ;give 2,000 points 

; *******************************************************************
; hilaser
; *******************************************************************
hilaser:
        move #1,laser_type
        move.l _claw,a0
        move.l #$48000,d0
        tst pal
        beq onopal
        move.l #$56666,d0  

onopal:
        move #$0202,48(a0)
        tst beastly
        beq sass2
        lsr.l #1,d0
        move #$0404,48(a0)

sass2:  move.l d0,shotspeed
        rts

; *******************************************************************
; Say 'Excellent', e.g. when the user naviates to an option.
; *******************************************************************
sayex:
        move #21,sfx
        move #101,sfx_pri
;  move #$ff,sfx_vol
        move.l #$160,sfx_pitch
        jsr fox
        move #101,sfx_pri
;  move #$ff,sfx_vol
        move.l #$162,sfx_pitch
        jmp fox

; *******************************************************************
; jenab
; *******************************************************************
jenab:
        move #1,jenable
        rts

; *******************************************************************
; addroid
; *******************************************************************
addroid:
        tst dnt
        bmi suprise    ;already had a droid
adenoid:
        move #$3c,bulland  ;for test droid mode
        add #8,bullmax
        move.l a6,-(a7)
        bsr mkdroid
        move.l (a7)+,a6
        rts

; *******************************************************************
; sprzap
; *******************************************************************
sprzap:
        tst warpy
        bmi knibble
        sub #1,warpy
knibble:
        move.l #pic,a2
        move.l #$6e0089,d0
        move.l #$2a00b2,d1
        jsr any_pixex
        move #21,sfx
        move #90,sfx_pri
        jsr fox
        move #21,sfx
        move #90,sfx_pri
        jsr fox
        move #1,szap_on  
        tst szap_avail
        bpl rrts
        clr szap_avail
        rts

; *******************************************************************
; xr_pixex
; *******************************************************************
xr_pixex:
        sub.l #$8000,24(a6)
        bmi run_pixex
        cmp #webz+80,12(a6)
        bge run_pixex
        move.l 24(a6),d0
        add.l d0,12(a6)
        rts
        
; *******************************************************************
; run_pixex
; *******************************************************************
run_pixex:
        move.l 20(a6),d0
        lsl.l #1,d0
        add.l d0,42(a6)
        cmp #64,42(a6)
        blt rrts
        clr 54(a6)
        move #1,50(a6)    ;unlink
        rts

; *******************************************************************
; run_prex
; *******************************************************************
run_prex:
        add #1,44(a6)
        cmp #13,34(a6)
        beq biggrx
        cmp #50,44(a6)
        bgt kikik
        rts
biggrx:
        cmp #255,44(a6)
        bgt kikik
        rts

; *******************************************************************
; vectorzap
; *******************************************************************
vectorzap:
        move.l _zap,(a6)    ;Explosion header frame
        move #$c8,40(a6)    ;Explo colour
        move #1,34(a6)      ;Std draw
        clr 52(a6)      ;NOT vulnerable to the Superzapper
        move #3,54(a6)      ;Type run_explo
        bsr rannum
        move d0,28(a6)      ;random orientation
        rts

; *******************************************************************
; run_zap
; *******************************************************************
run_zap:
        sub #1,42(a6)      ;expand it
        add #10,28(a6)      ;spin it too, why not
        cmp #-2,42(a6)
        bge rrts

; *******************************************************************
; kikik
; *******************************************************************
kikik:
        move #1,50(a6)      ;tell FG to unlink
        rts

; *******************************************************************
; make_adroid
; *******************************************************************
make_adroid:
        tst afree
        bmi rrts
        sub #1,afree
        
        move.l freeobjects,a0
        move web_max,d1
        jsr rand
        move #webz+80,d1
        swap d1
        clr d1
        move.l d1,12(a0)
        move d0,16(a0)
        move #$2020,18(a0)    ;duration of zappage
        clr.l 30(a0)
        move #3,20(a0)      ;mode=go up web
        move #1,34(a0)
        move.l #-26,(a0)
        clr 50(a0)
        move #1,52(a0)
        bsr rannum
        sub #$80,d0
        move d0,22(a0)      ;Direction to move, + or -
        move #$0202,24(A0)    ;Speed of motion
        clr 48(a0)
        move #39,54(a0)      ;MADROID
        move.l a0,a6
        jsr toweb
;  jsr insertobject
        bsr ipix
        clr d0
        rts

; *******************************************************************
; run_adroid
; *******************************************************************
run_adroid:
        sub #2,28(a6)    ;rotate the adroid
        lea adroidmodes,a0
        move 20(a6),d0
        lsl #2,d0
        move.l 0(a0,d0.w),a0
        jmp (a0)      ;go do droid move stuff

adroidmodes:
        dc.l admove,adgmove,zappage,uppweb

admove:
        jsr collie
        bne blowmeaway
        bra gstartmove

adgmove:
        jsr collie
        bne blowmeaway
        bra gmove

zappage:
        jsr collie
        bne blowmeaway
        cmp #-2,wave_tim
        beq nzppa
        jsr checlane_only
        beq frouch    ;fry player if on lane and zapping!
        add #3,28(a6)
        sub.b #1,18(a6)
        bne rrts      ;wait while zapping
        move.b 19(a6),18(a6)
        clr 20(a6)
nzppa:
        rts  

uppweb:
        jsr mcollie
        beq arab
        bsr dxle    ;spatter any shots
        move.l flip_zspeed,d0
        lsl.l #5,d0
        add.l d0,12(a6)
        cmp #webz+80,12(a6)
        bpl blowmeaway
        rts
arab:
         move.l flip_zspeed,d0
        lsl.l #1,d0
        sub.l d0,12(a6)
        cmp #webz-95,12(a6)
        bpl rrts
        clr 20(a6)
        rts

; *******************************************************************
; make_beast
; *******************************************************************
make_beast:
        bsr maflip
        bmi rrts
        move #5,44(a6)    ;Sflipper 5
        move #2,46(a6)    ;current Level
        move #-1,26(a6)    ;No delay
        move.l #-23,(a6)
        clr 48(a6)
        rts

; *******************************************************************
; make_sflip3
; *******************************************************************
make_sflip3:
        bsr maflip
        bmi rrts
        move #3,44(a6)    ;Sflipper 3
        move #-1,26(a6)    ;No delay
        move.l #-22,(a6)
        clr 48(a6)
        move #2,24(a6)    ;Stop mode makes it start running
        rts


make_sflip2:
        bsr maflip
        bmi rrts
        move #2,44(a6)    ;Sflipper 2
        move #-1,26(a6)    ;No delay
        move.l #-21,(a6)
        clr 48(a6)
        rts

; *******************************************************************
; make_flipper
;
; Make an enemy of type FLIPPER
; *******************************************************************
make_flipper:

        tst t2k
        beq maflip

        bsr rannum
        cmp sflip_prob3,d0
        bmi make_sflip2

maflip:
        tst afree
        bmi rrts
        sub #1,afree
        move.l freeobjects,a0
        move.l _flipper,d0
        tst blanka      ;check for solid flag
        beq nsf
        move.l #-1,d0      ;solid #1 is the flipper
nsf:
        move.l d0,(a0)
        move #webz+80,12(a0)
        clr 14(a0)
        move web_max,d1
        bsr rand
;  move.l _claw,a2
;  move 16(a2),d0      ;*** debug

        move d0,16(a0)    ;initial webpos of this flipper
        clr.l 30(a0)      ;clear Y and Z rotate
        move #3,34(a0)      ;std draw with displaced x centre
        clr.l 36(a0)      ;x centre to default
        move flipcol,40(a0)    ;Flippers are RED
        move flip_pause,26(a0)    ;Set the delay between flips
        move #1,42(a0)      ;Fine rez
        move #2,54(a0)      ;Type
        move #0,24(a0)      ;Flipper mode 0 (Ride up rail)
        clr 44(a0)
        move #1,52(a0)      ;IS vulnerable to the Superzapper
        move.l a0,a6
        bsr toweb      ;Attach the flipper to the web

ipix:
        bsr insertobject
;  cmp #1,wave_speed
;  bne rrts      ;This does not happen on accelerated time
        neg 34(a6)
        add #300,12(a6)      ;make remote shrunk pixel!
        clr d0
        rts



flipmodes:
        dc.l rail,flipto,stopped

run_flipper:
;
; move the Flipper enemy
        
        tst _sz
        beq flipok
        bmi flipok
;  move #-1,_sz
        bsr zappit
        bra fkillme
flipok:
        lea flipmodes,a0
        move 24(a6),d0      ;get flipper's Mode
        asl #2,d0
        move.l 0(a0,d0.w),a0
        jmp (a0)      ;go do stuff for this Mode

rail:
        move 44(a6),d0      ;get Sflipper mode
        lsl #2,d0
        lea railopts,a0
        move.l 0(a0,d0.w),a0
        jmp (a0)

railopts:
        dc.l stdrail,h2hrail,stdrail,stdrail,stdrail,beastrail

beastrail:
        bsr mcollie
        beq ssar

        move 46(a6),d0    ;get Level
        beq fkillme    ;Final, go kill me
        sub #1,46(a6)    ;dec display level
        add #23,d0
        and.l #$ff,d0
        neg.l d0
        move #1,34(a4)
        move.l d0,(a4)    ;take over the bullet
        move #38,54(a4)    ;and make it a Reflected Shot with Spin...
        move.l 24(a4),a1
        clr.l (a1)    ;...clear its bull table
        rts
        


h2hrail:
        bsr collie
        bne fkillme
        move.l flip_zspeed,d0
        tst 46(a6)
        bpl srail
        add.l d0,12(a6)
        cmp #webz+80,12(a6)
        blt rrts
        move #webz+80,12(A6)
        bra sra  



stdrail:
        bsr collie      ;Coll det
        bne fkillme      ;I'm dead!
ssar:
        bsr alienfire
        move.l flip_zspeed,d0
srail:
        sub.l d0,12(a6)      ;move Flipper vertically
        cmp #webz-80,12(a6)
        bgt rrts
        move #webz-80,12(a6)
sra:
        clr 14(a6)
flipimm:
        move #1,24(a6)      ;change flipper mode to Flip
        bsr flip_set
        rts

flipto:
        cmp #3,44(a6)
        bne flipto1
        move.l flip_zspeed,d0
        sub.l d0,12(a6)
        cmp #webz-80,12(A6)
        bgt fspesh0
        move #4,44(a6)
        bra flipto1
fspesh0:
        sub.b #1,46(a6)
        bpl flipto1
        move.b 47(a6),46(a6)
;  bsr afid      ;try to Fire more often  
flipto1:
        move 20(a6),d0
        add d0,28(a6)      ;rotate (only for flipping Flippers)
        move 22(a6),d0      ;get target angle...
flito:
        move 28(a6),d1
        add.b #128,d1
        ext d1
        and #$ff,d1
        sub d1,d0      ;compare to th' dest
        bne flipcollie      ;same, not there yet, go and detecoll
        move #2,24(a6)      ;mode to Stop
        move #0,36(a6)      ;default centre
        move #28,sfx
        move #2,sfx_pri
;  move.l #40,sfx_pitch
        jsr fox
        bra toweb      ;put us on the Web


flipcollie:
        ext d0
        tst d0
        bpl possie
        neg d0        ;dist from targ is positive.
possie:
        cmp #52,d0      ;<32, I say it can be shot.
        bgt flipcolyou      ;Nope
        bsr collie
        bne fkillme      ;Zap, baby
        rts   
flipcolyou:
        move 38(a6),d0
        bmi rrts    ;Not if out of a tanker  
        tst h2h
        beq ucolyou
        bsr h2hclan
        bne rrts
h2hgotu:
        move.l a0,a4
        jsr h2hckill
        jmp fkillme   

ucolyou:
        move players,d1
        move.l _claw,a0
        bsr clan    ;see if we are in any player's lane
        beq gotu      ;catch player if he moves to your Lane
        rts

; *******************************************************************
; checlane
;
; check to see if a claw is on your lane, for one or two player modes
; returns EQ and a0=clawbase if yeah, NE if not.
; *******************************************************************
checlane:


        tst h2h
        beq chchc
        move 16(a6),d0
h2hclan:
        move.l _claw,a0    ;get claw 1
        cmp #webz,12(a6)
        blt h2hcol1
        move.l 56(a0),a0  ;get claw 2
h2hcol1:
        cmp 16(a0),d0    ;same lane? (If in this phase they are already on the web end)
        rts  

chchc:
        move players,d1
        move.l _claw,a0
        move 16(A6),d0
clan:
        tst 52(a0)    ;check Vuln flag
        beq clnxt
        cmp 16(a0),d0
        beq clan2
clnxt:
        sub #1,d1
        beq snee
        move.l 56(a0),a0
        bra clan
snee:
        move #1,d0
        rts
clan2:
         move 12(a6),d2    ;get bullet pos
        sub 12(a0),d2    ;cmp against claw
        bpl rokki
        neg d2
rokki:
        cmp #2,d2
        bgt clnxt
        clr d2
        rts

checlane_only:
        move players,d1
        move.l _claw,a0
        move 16(A6),d0
oclan:
        tst 52(a0)    ;check Vuln flag
        beq oclnxt
        cmp 16(a0),d0
        beq oclan2
oclnxt:
        sub #1,d1
        beq osnee
        move.l 56(a0),a0
        bra oclan
osnee:
        move #1,d0
        rts
oclan2:
         cmp #webz-80,12(a0)  ;check if on top (may be jumping!)
        blt clnxt
        clr d2
        rts

; *******************************************************************
; fkillme
; *******************************************************************
fkillme:
        clr d0
fkm:
        bsr doscore
        bra killme      ;kill and score points for a flipper

stopped:
        move 44(a6),d0
        lsl #2,d0
        lea sstopmodes,a0
        move.l 0(a0,d0.w),a0
        jmp (a0)
sstopmodes:
        dc.l stdstop,sustop1,sustop1,sustop1,sustop1,stdstop


sustop1:
        tst 48(A6)
        beq stdstop
        bpl gclock
        add #1,48(a6)
        jsr flip_set_left
        cmp #2,24(a6)      ;if not wrapped Web (stopped Flipper reached edge)...
        bne rrts
        jmp flip_set_right
        
gclock:
        sub #1,48(a6)
        jsr flip_set_right
        cmp #2,24(a6)
        bne rrts
        jmp flip_set_left
 
stdstop:
        bsr collie      ;Coll det
        bne fkillme  
        tst 38(a6)
        bpl stoplgl
        cmp #-2,38(a6)
        beq topulsar      ;make this Flipper a pulsar
        clr 24(a6)      ;Special case for flipper out of a tanker
        cmp #3,44(a6)
        beq flipimm
        rts
stoplgl:
        bsr checlane
        bne notgt
        tst h2h 
        beq gotu
        bra h2hgotu
notgt:
        tst beastly
        bne flip_set    ;Flippers never pause in beastly mode
        sub.b #1,26(a6)    ;do Flipper pause
        bpl rrts
        move.b 27(a6),26(a6)    ;reset timer..
        bra flip_set      ;.. and try to Flip again

gotu:
         cmp #-2,wave_tim    ;-2 means the zoom has started and player is safe
        beq rrts      ;so can't get you
        move #25,sfx      ;scream!
        move #101,sfx_pri
        jsr fox
        move handl,handl1
        move #101,sfx_pri
        jsr fox
        move handl,handl2
        cmp #2,players
        bne singl_snatch    ;do single player get caught
;  add #1,dying
        tst lives
        beq singl_snatch
        move #13,54(a0)      ;claw to godown mode
        clr 52(A0)      ;mode to not vuln
        move #14,54(a6)      ;flipper to godown mode
        rts

singl_snatch:
        lea gmes1,a0
        clr.l d0
        move.l #$8000,d1
        bsr setmsg
        move.l a6,tmtyl
        move.l #take_me_to_your_leader,routine
        move #1,screaming
;  bra zapson
        rts

; *******************************************************************
; flip_set
;
; try and flip towards the player's position
; *******************************************************************
flip_set:

        tst h2h
        beq ufpset
        move.l _claw,a0
        cmp #webz,12(a6)
        blt luff
        move.l 56(a0),a0
        bra luff


ufpset:
        cmp #2,players      ;2psim mode?
        bne uflipset      ;No, go do it like usual
        move.l _claw,a0
fsetm:
        tst 52(a0)      ;check if claw is prey
        beq fsetnxt      ;No it is not.
        bsr _fset      ;get flip routine and dist
        move.l a1,a2
        move d1,d3
        bra _fset2
fsetnxt:
        move #500,d3      ;prev claw was not a target
        move.l #zzzz,a2
_fset2:
        move.l 56(a0),a0
        tst 52(a0)
        beq fsetfinal
        bsr _fset
        bra _fset3
fsetfinal:
        move #500,d1
        move.l #zzzz,a1
_fset3:
        cmp d3,d1  ;which is closer?
        blt toclaw2  ;Player One is.
        bgt toclaw1  ;Player Two is.
        cmp #500,d1  ;same: are they at default max?
        beq zzzz  ;They are, so we will not Flip.
        bsr rannum
        btst #0,d0
        beq toclaw2  ;random L or R flip if distance is eq

toclaw1:
        jmp (a2)  ;Flip to claw 1.
toclaw2:
        jmp (a1)  ;Flip to claw 2.
        
uflipset:
        move.l _claw,a0
luff:
         bsr _fset
;  beq rrts      ;allow for flipper halt by zzzz
        jmp (a1)      ;only one claw: just go wherever it sez

_fset:
        move 16(a0),d0      ;Player position
        move 16(a6),d1      ;Flipper current pos
        move d1,38(a6)      ;Coll detect alternative (for you!)
        tst connect
        bne seekwrap      ;Wrap mode if web is circular
        sub d0,d1
        move d1,d4
        bgt fsl
        blt fsr
        bra zz
seekwrap:
        move web_max,d2
        asr #1,d2      ;half distance around web
        sub d0,d1
        move d1,d4
        bgt lll
        blt rrr
        bra zz
lll:
        sub d2,d1
        blt fsl
        bra fsr
rrr:
        neg d1
        sub d2,d1
        blt fsr
        bra fsl

fsl:
        lea flip_set_left,a1    ;set flipset call, invert it for mode 3 Flippers
        cmp #3,44(a6)
        bne abs
        lea flip_set_right,a1
abs:
        move d4,d1
        tst d1
        bpl tart
        neg d1
tart:
        rts
fsr:
        lea flip_set_right,a1
        cmp #3,44(a6)
        bne abs
        lea flip_set_left,a1
        bra abs

; *******************************************************************
; flip_set_left
;
; Start a Flipper turning anticlokkers
; *******************************************************************
flip_set_left:


        tst 16(a6)      ;are we in lane zero?
        bne fset0
        tst connect
        bne fset1      ;special if web is connected
        bra flip_set_right

zzzz:
        move #2,24(a6)      ;stop a Flipper
        move #0,36(a6)      ;restore default x-centre    
zz:
        move.l #zzzz,a1
        move #500,d1
        rts

fset1:
        bsr webinfo
        move web_max,d6
        sub #1,d6
        move d6,16(a6)      ;Wrap anticlockwize
        bra fset
fset0:
        bsr webinfo      ;get info. on lane endpoints
        sub #1,16(a6)      ;where we're going
fset:
        move 16(a6),d7
        move.l web_otab,a0
        asl #1,d7
        move 0(a0,d7.w),d6    ;Got the target angle
        and #$ff,d6
        move d6,22(a6)      ;save it
        move #1,24(a6)      ;change flipper mode to Flip
        move #9,36(a6)      ;Offset X centre
        move flip_rospeed,d7    ;The speed of flipping
        cmp #2,44(a6)
        bne xflip
        lsl #1,d7      ;Super levels 2 or over twice as fast Walkers
xflip:
        neg d7        ;Negative to flip anticlockwise
        move d7,20(a6)      ;set ro speed
        swap d0
        clr d0
        swap d1
        clr d1        ;Set position to left lane side
        move.l d0,4(a6)      ;fixed point is now the lane side
        move.l d1,8(a6)
        rts

; *******************************************************************
; flip_set_right
;
; start a Flipper turning clockwise
; *******************************************************************
flip_set_right:

        move web_max,d0
        sub #1,d0
        cmp 16(a6),d0      ;are we in the end lane?
        bne fset2
        tst connect
        bne fset3      ;special if web is connected
        bra flip_set_left
        move #2,24(a6)      ;stop a Flipper
        move #0,36(a6)      ;restore default x-centre    
        rts

fset3:
        bsr webinfo
        clr 16(a6)      ;Wrap anticlockwize
        bra fset4
fset2:
        bsr webinfo      ;get info. on lane endpoints
        add #1,16(a6)      ;where we're going
fset4:
        move 16(a6),d7
        move.l web_otab,a0
        asl #1,d7
        move 0(a0,d7.w),d6    ;Got the target angle
        and #$ff,d6
        move d6,22(a6)      ;save it
        move #1,24(a6)      ;change flipper mode to Flip
        move #-9,36(a6)      ;Offset X centre
        move flip_rospeed,d7    ;The speed of flipping
        cmp #2,44(a6)
        bne xflip2
        lsl #1,d7      ;Super levels 2 or over twice as fast Walkers
xflip2:
        move d7,20(a6)      ;set ro speed
        swap d2
        clr d2
        swap d3
        clr d3      ;Set position to left lane side
        move.l d2,4(a6)      ;fixed point is now the lane side
        move.l d3,8(a6)
        rts

rNrts:
;
; return -1

        move #-1,d0
        rts

; *******************************************************************
; make_putanker
;
; Make a PULSAR-TANKER
; *******************************************************************
make_putanker:
m_ptank:
        move #2,d3      ;tanker-type
        tst blanka
        beq upvt
        move.l #-8,d2
        bra maketank
upvt:
        move.l _pulstank,d2
        bra maketank

; *******************************************************************
; make_futanker
;
; Make a FUSEBALL-TANKER
; *******************************************************************
make_futanker:

        move #1,d3      ;tanker-type
        tst blanka
        beq vft
        move.l #-6,d2
        bra maketank
vft:
        move.l _fusetank,d2
        bra maketank

; *******************************************************************
; make_tanker
; *******************************************************************
make_tanker:
;
; Make an enemy of type FLIPPER TANKER

        tst blanka
        beq mtv
        move.l #-2,d2
        clr d3
        bra maketank

mtv:
        move.l _fliptank,d2
        clr d3

maketank:
        cmp #2,afree
        blt rNrts      ;Tankers carry pairs of Objects
        sub #3,afree
        move.l freeobjects,a0
        move.l d2,(a0)
        move #webz+80,12(a0)
        clr 14(a0)
        move web_max,d1
        sub #2,d1
        bsr rand
        add #1,d0      ;its much easier if we can't appear in an end lane
        move d0,16(a0)    ;initial webpos of this tanker
        clr.l 30(a0)      ;clear Y and Z rotate
        move #1,34(a0)      ;std draw
        move #128,40(a0)    ;Tankers are PURPLE
        move #1,42(a0)      ;std rez
        move d3,44(a0)      ;Type of split
        move #1,52(a0)      ;IS vulnerable to the Superzapper
        move #5,54(a0)      ;Type
        move.l a0,a6
        bsr toweb      ;Attach the Tanker to the web
;  bra insertobject
        bra ipix

; *******************************************************************
; run_tanker
; *******************************************************************
run_tanker:
        bsr collie      ;Coll det
        bne opentanker    ;I'm dead! Go spawn 2 meanies.
        move.l tank_zspeed,d0
        sub.l d0,12(a6)      ;move Flipper vertically
        cmp #webz-80,12(a6)
        bgt rrts
        move #webz-80,12(a6)
        clr 14(a6)

opentanker:
        move #1,d0
        bsr doscore
        move #$11,sfx
        move #3,sfx_pri
        move.l #60,sfx_pitch
        jsr fox
        move #$11,sfx
        move #3,sfx_pri
        move.l #61,sfx_pitch
        jsr fox
        lea tankercontents,a0
        move 44(a6),d0
        asl #2,d0
        move.l 0(a0,d0.w),a0
        jmp (a0)      ;do appropriate open-thang thang

tankercontents:
        dc.l openflippers,openfuseballs,openpulsars

openflippers:
        move.l a6,a5    ;mummy's address save
        move.l freeobjects,a6
        bsr newflipper      ;new flipper in this lane
        bsr flip_set_right
        move #0,d1
        bsr superflip      ;make Super Flippers sometimes
        move #-1,38(a6)      ;tells it to stop Flipping after one flip
        move.l freeobjects,a6
        bsr newflipper
        bsr flip_set_left
        move #1,d1
        bsr superflip
        move #-1,38(a6)
        move.l a5,a6
        bra tsphkillme

superflip:
        tst t2k
        beq rrts    ;never exvept in t2k
        bsr rannum
        cmp sflip_prob1,d0  ;check prob threshold
        bpl rrts
        move #2,44(a6)    ;Sflipper 2
        move #-1,26(a6)    ;No delay
        bsr rannum
        and #3,d0
        add #1,d0
        tst d1
        beq suprf1
        neg d0
suprf1:
        move d0,48(a6)    ;set random scarper value
        move.l #-21,(a6)
        bsr rannum
        cmp sflip_prob2,d0
        bpl rrts
        move #3,44(a6)    ;Sflipper 3
        move #$0404,46(a6)  ;fire rate when activated
        move.l #-22,(a6)
        rts  

newflipper:
        move.l 4(a5),4(a6)
        move.l 8(A5),8(A6)
        move.l 12(A5),12(a6)    ;copy XYZ pos
        move.l _flipper,d0
        tst blanka
        beq nfvv
        move.l #-1,d0
nfvv:
        move.l d0,(a6)    ;def
        move.l 16(a5),16(a6)    ;pos
        move 28(a5),28(a6)    ;<
        clr.l 30(a6)
        move #3,34(a6)
        clr 36(a6)
        move flipcol,40(a6)
        clr 24(a6)
        move flip_pause,26(a6)    ;Set the delay between flips
        move #1,42(A6)
        clr 44(a6)
        move #1,52(a6)
        move #2,54(a6)
        move.l a6,a0
        bra insertobject

openfuseballs:
        move.l a6,a5    ;mummy's address save
        move.l freeobjects,a6
        add #1,16(a5)
        bsr newfuseball      ;new flipper in this lane
        bsr set_fuseright
        sub #1,16(a5)
        move.l freeobjects,a6
        bsr newfuseball
        bsr set_fuseleft
        move.l a5,a6
        bra tsphkillme

newfuseball:
        move.l _fuse1,d0
        tst blanka
        beq nufu
        move.l #-4,d0
nufu:
        move.l d0,(a6)
        move.l 12(a5),12(a6)
        move 16(a5),16(a6)    ;initial webpos of this Fuseball
        clr.l 30(a6)      ;clear Y and Z rotate
        clr 18(a6)
        move #1,34(a6)      ;standard draw
        move #15,40(a6)      ;first Fuseball leg is CYAN
        move #1,42(a6)      ;Fine rez
        move #1,52(a6)      ;does count as an enemy in the wave-end check.
        move #9,54(a6)      ;Type=RUN_FUSEBALL
        clr 44(a6)      ;Fuseball mode = Climb the rail
        move fuse_risetime,46(a6)
        move fuse_crossdelay,48(a6)
        bsr webinfo      ;get info. on lane endpoints
        swap d0
        clr d0
        swap d1
        clr d1        ;Set position to left lane side
        move.l d0,4(a6)      ;fixed point is now the lane side
        move.l d1,8(a6)
        move.l a6,a0
        bra insertobject

openpulsars:
        move.l a6,a5    ;mummy's address save
        move.l freeobjects,a6
        bsr newflipper      ;new flipper in this lane
        bsr flip_set_right
        move.l _pus+12,d0
        tst blanka
        beq vop
        move.l #-5,d0
vop:
        move.l d0,(a6)    ;header is a Pulsar
        move #-1,26(a6)    ;No delay
        move #$ff,40(a6)    ;and Pulsars are yellow
        move #-2,38(a6)      ;tells it to stop Flipping after one flip and change into a Pulsar
        move.l freeobjects,a6
        move.l d0,-(a7)
        bsr newflipper
        bsr flip_set_left
        move.l (a7)+,d0
        move.l d0,(a6)
        move #-1,26(a6)    ;No delay
        move #$ff,40(a6)
        move #-2,38(a6)
        move.l a5,a6
        bra tsphkillme

; *******************************************************************
; flipping_heck
; *******************************************************************
flipping_heck:
;
; make the current object behave as a Flipper

        move #3,34(a6)
        clr.l 36(a6)
        clr 24(a6)
        move flip_pause,26(a6)    ;Set the delay between flips
        move #1,42(A6)
        clr 44(a6)      ;Clear the Superflipper flag!!!!!!!!!!!!!!!!!!!!
        move #1,52(a6)
        move #2,54(a6)
        bra flip_set

zrts:
        move #0,d0
        rts

; *******************************************************************
; make_spike
;
; make a spike, in lane d0; uses a0/a1; ASSUMES SPIKE TABLE ADDRESS IN A1!
; *******************************************************************
make_spike:

        tst afree
        bmi rrts
        sub #1,afree
        move.l freeobjects,a0
        move.l _spike,(a0)
        move #webz+80,12(a0)
        clr 14(a0)
        move d0,16(a0)    ;initial webpos of this tanker
        asl #2,d0
        move.l a0,(a1)    ;address to spike table
        clr.l 30(a0)      ;clear Y and Z rotate
        move #4,34(a0)      ;draw #4,draw_spike
        move #30,36(a0)    ;length of spike (max 120)
        move #143,40(a0)    ;Spikes are GREEN
        move #-1,42(a0)      ;Standard rez x2 (so it can be longer than +128!)
        move.l a1,44(a0)    ;position in spike table
        move #0,52(a0)      ;does not count as an enemy in the wave-end check.
        move #6,54(a0)      ;Type=RUN_SPIKE
        clr 20(a0)
        tst t2k
        beq uspike
        jsr rannum
        cmp sflip_prob2,d0
        bpl uspike
        move #1,20(a0)      ;set Super Spike
uspike:
        move.l a6,-(a7)      ;coz it will be called from an active Spiker
        move.l a0,a6
        bsr toweb      ;Attach the Tanker to the web
        move.l (a7)+,a6
        sub #1,noclog
        bra insertobject

run_spike:
        move 12(a6),d0
        move d0,-(a7)    ;save our z pos
        sub 36(a6),d0
        move d0,12(a6)      ;our 'position' is the height of our Spike

        tst 20(a6)
        beq nospf
        move flashcol,40(a6)
nospf:

        cmp #-2,wave_tim      ;are we zooming?
        bne rspik1 
        cmp.l #zoom1,routine
        bne rspik2
;  move.l _claw,a0
;  move 16(a0),d0
;  cmp 16(a6),d0      ;in Claw lane?
        bsr checlane_only
        bne rspik1      ;naaw
        move 12(a0),d0      ;Claw Z pos
        cmp #webz+80,d0
        bge rspik1
        cmp 12(a6),d0
        blt rspik1
        move (a7)+,12(a6)
        jsr zzoomoff      ;cancel warping sound/yes yes yes
        bsr setsnatch  ;deer deer, you got spiked
zapson:
        tst screaming
        bne rrts
        move #1,screaming
zson:
        move #$0a,sfx
        move #50,sfx_pri
        move.l #200,sfx_pitch
        jsr fox
        tst h2h
        bne rrts
        move #$0a,sfx
        move #50,sfx_pri
        move.l #196,sfx_pitch    ;phased large explosions
        jmp fox


rspik1:
        bsr colok      ;so do a detecol (not allowing SuperZap)
        bne decspike
rspik2:
        move (a7)+,12(a6)
        rts
decspike:
        move (a7)+,12(a6)
        move #$0d,sfx
        move #2,sfx_pri
        move 36(a6),d0
        and.l #$1ff,d0
        add.l #524,d0
        move.l d0,sfx_pitch
        jsr fox
        move #2,d0
        bsr doscore
        bsr webinfo
        sub #3,36(a6)      ;dec spike length
        bpl rrts
        move.l 44(a6),a0
        clr.l (a0)      ;clear entry in spike table.
        add #1,noclog
        move #2,d0
        bra fkm

; *******************************************************************
; make_spiker
;
; make a spiker, in a random Lane
; *******************************************************************
make_spiker:

        tst afree
        bmi rrts
        tst max_spikers
        bmi zrts    ;zero return wont hang the wave sequencer
        sub #1,afree
        sub #1,max_spikers
        move.l freeobjects,a0
        move.l _spiker,(a0)
        move #webz+80,12(a0)
        clr 14(a0)
        move web_max,d1
        bsr rand
        move d0,16(a0)    ;initial webpos of this spiker
        clr.l 30(a0)      ;clear Y and Z rotate
        move #1,34(a0)      ;standard draw
        move #143,40(a0)    ;Spikers are GREEN
        move #1,42(a0)      ;Fine rez
        move #1,52(a0)      ;does count as an enemy in the wave-end check.
        move #7,54(a0)      ;Type=RUN_SPIKER
        clr 44(a0)      ;Spiker mode = Go to new spike
        move.l a0,a6
        bsr toweb      ;Attach the Spiker to the web
        bra insertobject

spiker_vex:
        dc.l newspike,climbspike,descendspike

; *******************************************************************
; run_spiker
; *******************************************************************
run_spiker:
        add #4,28(a6)    ;He spins
        bsr collie
        bne sfkillme      ;You can kill him
        lea spiker_vex,a0
        move 44(a6),d0
        asl #2,d0
        move.l 0(a0,d0.w),a0
        jmp (a0)

sfkillme:
        add #1,max_spikers
        bra fkillme

newspike:
        lea spikes,a0    ;Pointer to table of existing spikes.
        lea spikescratch,a1  ;Some scratch ram to build up a table.
        clr d1      ;A counter of as-yet-clear lanes.
        move #200,d2    ;A variable which holds the current shortest spike found.
        clr d0    ;Total # of lanes spikes can go in.

nuspik:
        move.l (a0),d4    ;Get next spike table entry
        bne is_spike    ;Non zero if it is a spike
        add #1,d1    ;inc free spikes ctr
        move d0,(a1)+    ;spike number to scratch ram
        bra nxtspik    ;jump past is_spike

is_spike:
        move.l d4,a2
        cmp 36(a2),d2    ;compare length of indicated spike with current shortest
        blt nxtspik    ;not as short, ignore
        move.l a2,a3    ;save the address of the shorter spike
        move 36(a2),d2    ;make it the current shortest

nxtspik:
        lea 4(a0),a0    ;next spiketable entry
        add #1,d0
        cmp web_max,d0
        blt nuspik
        bne nuspik    ;loop for all possible spikes on this web.
        tst d1      ;were there any lanes without spikes?
        bne setnewspike    ;yes, go and make one
gotospike:
        move.l 16(a3),16(a6)  ;get the web pos of the chosen spike
        move #1,44(a6)    ;mode to climb
        move.l a3,24(a6)  ;save the address of 'our' spike
        move spiker_build,36(a6)  ;amount of building to do
        bra toweb    ;fix in position and go.

setnewspike:
        tst afree    ;**CHECK** to see if there is a free slot to build a spike in.
        bpl nuspik1
        cmp #200,d2    ;check to see if there are already other spikes
        bne gotospike    ;go and lengthen another instead

aoff:
;  add #1,afree
        move #1,50(a6)      ;tell FG to unlink
        rts
;  move.l a6,a0
;  bra unlinkobject  ;Remove self if none free and no other spikes (should be rare)

nuspik1:
        sub #1,d1
        bsr rand    ;d1 already has # of free spikes
        asl #1,d0    ;to point to the words, in scratch ram
        lea spikescratch,a1
        move 0(a1,d0.w),d1  ;get lane number
        move d1,d0    ;for init
        asl #2,d1    ;make it point to longs
        lea spikes,a1
        lea 0(a1,d1.w),a1  ;point to free spike table entry
        bsr make_spike    ;init a new spike
        move.l a0,a3
        bra gotospike    ;go to the spike

climbspike:
        bsr alienfire
        move.l spiker_zspeed,d0
        sub.l d0,12(a6)    ;move up
        cmp #webz-70,12(a6)
        blt sdesc
        move.l 24(a6),a0  ;address of 'our' spike
        move 36(a0),d2    ;current spike height
        move #webz+80,d1
        sub 12(a6),d1    ;our height
        sub d2,d1    ;compare with our z
        ble rrts    ;we higher than the spike yet
        add.l 36(a0),d0    ;inc spike
        swap d0
        cmp #150,d0    ;max allowed spike length
        bge nolonger
        swap d0
        move.l d0,36(a0)  ;store longer spike
nolonger:
        sub #1,36(a6)    ;dec build duration
        bpl rrts
sdesc:
         move #2,44(a6)    ;set to descend
        rts

descendspike:
        bsr alienfire
        move.l spiker_zspeed,d0
        add.l d0,12(a6)
        cmp #webz+80,12(a6)
        blt rrts    ;climb down
        move #webz+80,12(a6)
        clr 14(a6)
        clr 44(a6)    ;mode back to seek new spike
        rts   

; *******************************************************************
; make_mirr
;
; make a Mirror
; *******************************************************************
make_mirr:

        tst afree
        bmi rrts
        sub #1,afree
        move.l freeobjects,a0
        move.l #-13,(a0)  ;draw_mirr
        move web_max,d1
        jsr rand
        move d0,16(a0)
        move #webz+80,12(a0)
        move.l fuse_zspeed,20(a0)
        move #1,34(a0)
        clr 50(a0)
        move #$01,52(a0)
        move #36,54(a0)
        move #4,24(a0)
        move.l a0,a6
        jsr toweb
        jmp ipix

; *******************************************************************
; rumirr
; *******************************************************************
rumirr:
        add #1,28(a6)
        cmp #webz-40,12(a6)  ;check nearest approach
        ble gomirr
        move.l 20(a6),d0
        sub.l d0,12(a6)    ;move it closer to the player
gomirr:
        jsr mcollie
        beq rrts    ;does nothing if not shot
        sub #1,24(a6)
        bmi blowmeaway    ;gives Big Points
        move.l 20(a6),d0
        lsl.l #4,d0
        add.l d0,12(a6)    ;moves mirror up the Web when shot
        cmp #webz+80,12(a6)  
        bgt blowmeaway

;  tst afree
;  bmi rrts
;  sub #1,afree
;  sub #1,ashots
;  move.l freeobjects,a0
;  move.l #-3,d0
;  jmp vfyre    ;fire a shot back at the player

        move #$13,sfx
        move #3,sfx_pri
        jsr fox

        move #1,34(a4)
        move.l #-7,(a4)    ;take over the bullet
        move #37,54(a4)    ;and make it a Reflected Shot..
        move.l 24(a4),a1
        clr.l (a1)    ;clear the entry in the Bull Lable
        rts

refsht2:
        add #4,28(a6)
        jsr colok    ;absorbs non powered up shots, falls thru to standard refshot, no smart bomb
        move.l shotspeed,d0
        asr.l #1,d0
        bra reshh

refsht:
        move.l shotspeed,d0
reshh:
        sub.l d0,12(a6)    ;move towards player!
        jsr checlane  
        beq shouch    ;kill player by shot if we got him
        cmp #1,12(a6)
        bpl rrts  
        move #3,50(a6)    ;give player back his shot
        rts

; *******************************************************************
; make_fuseball
; *******************************************************************
make_fuseball:
;
; make a Fuseball, in a random Lane

;  bra make_mirr

        tst afree
        bmi rrts
        sub #1,afree
        move.l freeobjects,a0
        move.l _fuse1,d0
        tst blanka
        beq mfusb
        move.l #-4,d0
mfusb:
         move.l d0,(a0)
        move #webz+80,12(a0)
        clr 14(a0)
        move web_max,d1
        bsr rand
        clr 18(a0)
        move d0,16(a0)    ;initial webpos of this Fuseball
        clr.l 30(a0)      ;clear Y and Z rotate
        move #1,34(a0)      ;standard draw
        move #15,40(a0)      ;first Fuseball leg is CYAN
        move #1,42(a0)      ;Fine rez
        move #1,52(a0)      ;does count as an enemy in the wave-end check.
        move #9,54(a0)      ;Type=RUN_FUSEBALL
        clr 44(a0)      ;Fuseball mode = Climb the rail
        move fuse_risetime,46(a0)
        move fuse_crossdelay,48(a0)
        move.l a0,a6
        bsr webinfo      ;get info. on lane endpoints
        swap d0
        clr d0
        swap d1
        clr d1        ;Set position to left lane side
        move.l d0,4(a6)      ;fixed point is now the lane side
        move.l d1,8(a6)
;  bra insertobject
        bra ipix

fuse_vex:
        dc.l climbrail,crossrail,blowaway

; *******************************************************************
; run_fuseball
; *******************************************************************
run_fuseball:
        tst _sz
        beq rfb
        bsr collie    ;so they will always smart bomb
        bne blowmeaway
rfb:
        add #2,28(a6)    ;make 'em spin
        move.l _fuse1,d1
        bsr rannum
        and #1,d0
        bne r_fuse1
        move.l _fuse2,d1
r_fuse1:
        tst blanka
        beq r_fuse2
        move.l #-4,d1
r_fuse2:
        move.l d1,(a6)      ;animate the Fuseball
        lea fuse_vex,a0
        move 44(a6),d0
        asl #2,d0
        move.l 0(a0,d0.w),a0
        jmp (a0)

; *******************************************************************
; climbrail
; *******************************************************************
climbrail:
        cmp #webz-80,12(a6)
        blt crail1      ;check for top of Web
        move.l fuse_zspeed,d0
        sub.l d0,12(a6)
crail1:
        sub.b #1,46(a6)
        bpl rrts
        move.b 47(a6),46(a6)
;
; try and rotate towards the player's position

        clr 18(a6)
        move.l _claw,a0
        move 16(a0),d0      ;Player position
        move 16(a6),d1      ;Flipper current pos
        move d1,38(a6)      ;Coll detect alternative (for you!)
        tst connect
        bne seekfwrap      ;Wrap mode if web is circular
        sub d0,d1
        bgt set_fuseleft
        ble set_fuseright
seekfwrap:
        move web_max,d2
        asr #1,d2      ;half distance around web
        sub d0,d1
        bgt flll
        ble frrr
flll:
        cmp d2,d1
        blt set_fuseleft
        bra set_fuseright
frrr:
        neg d1
        cmp d2,d1
        blt set_fuseright
        bra set_fuseleft
        

; *******************************************************************
; set_fuseleft
; *******************************************************************
set_fuseleft:
        tst 16(a6)    ;are we in lane zero?
        bne fuset0
        tst connect
        bne fuset1      ;special if web is connected
        rts

fuset1:
        move web_max,d6
        sub #1,d6
        move d6,16(a6)      ;Wrap anticlockwize
        bra fuset
fuset0:
        sub #1,16(a6)      ;where we're going
fuset:
         bsr webinfo
          sub d2,d0
        sub d3,d1      ;vector to left endpoint
        swap d0
        clr d0
        swap d1
        clr d1
        asr.l #4,d0
        asr.l #4,d1      ;/16, is motion vector now
        move.l d0,20(a6)
        move.l d1,24(a6)    ;store motion vector
        move #15,36(a6)      ;step counter
        clr 38(a6)
        move #1,44(a6)      ;set mode to cross rail
        rts

; *******************************************************************
; set_fuseright
; *******************************************************************
set_fuseright:
        bsr webinfo
        sub d0,d2
        sub d1,d3      ;vector to left endpoint
        swap d2
        clr d2
        swap d3
        clr d3
        asr.l #4,d2
        asr.l #4,d3      ;/16, is motion vector now
        move.l d2,20(a6)
        move.l d3,24(a6)    ;store motion vector
        move #15,36(a6)      ;step counter
        move #1,44(a6)      ;set mode to cross rail
        move #1,38(a6)      ;change lanes after crossing! 
        rts

; *******************************************************************
; crossrail
; *******************************************************************
crossrail:
        cmp #4,36(a6)    ;only kill if in lane centre
        blt nokll
        cmp #12,36(a6)
        bgt nokll
        tst 18(a6)
        bmi nokll
        bsr collie
        bne blowmeaway
nokll:
        cmp #webz-80,12(a6)    ;if we are at top we can kill player
        bgt nopkll
        cmp #-2,wave_tim
        beq nopkll      ;(not if we are already zooming)
        bsr checlane
        beq frouch

nopkll:
        sub.b #1,48(a6)
        bpl rrts
        move.b 49(a6),48(a6)    ;step delay reset
        move.l 20(a6),d0
        add.l d0,4(a6)
        move.l 24(a6),d0
        add.l d0,8(a6)
        sub #1,36(a6)      ;step count
        bpl rrts
        clr 44(a6)      ;set to rail ride again
        tst 38(a6)
        beq crail0
        move web_max,d0      ;change lane #
        sub #1,d0
        cmp 16(a6),d0    ;are we in lane zero?
        bne furset0
        tst connect
        bne furset1      ;special if web is connected
        rts
furset1:
        clr 16(a6)      ;Wrap anticlockwize
        bra crail0
furset0:
        add #1,16(a6)      ;where we're going
crail0:
        bsr webinfo      ;get info. on lane endpoints
        swap d0
        clr d0
        swap d1
        clr d1        ;Set position to left lane side
        move.l d0,4(a6)      ;fixed point is now the lane side
        move.l d1,8(a6)
        tst 38(a6)
        rts


; *******************************************************************
; make_pulsar
;
; make a Pulsar, in a random Lane
; *******************************************************************
make_pulsar:

        tst afree
        bmi rrts
m_puls:
        sub #1,afree
        move.l freeobjects,a0
        move.l _pus,d0
        tst blanka
        beq vop2
        move.l #-5,d0
vop2:
        move.l d0,(a0)
        move #webz+80,12(a0)
        clr 14(a0)
        move web_max,d1
        bsr rand
        move d0,16(a0)    ;initial webpos of this Fuseball
        clr.l 30(a0)      ;clear Y and Z rotate
        move #1,34(a0)      ;standard draw
        move #$ff,40(a0)    ;Pulsars are YELLOW
        move #1,42(a0)      ;Fine rez
        move #1,52(a0)      ;does count as an enemy in the wave-end check.
        move #11,54(a0)      ;Type=RUN_PULSAR
        move.l a0,a6
        bsr toweb
        bra ipix

; *******************************************************************
; topulsar
;
; transform a Flipper that looks like a pulsar into a real pulsar
; *******************************************************************
topulsar:

        move #1,34(a6)      ;to std. draw
        clr 38(a6)
        move #11,54(a6)      ;mode to PULSAR
        bra toweb      ;fix in centre of lane

; *******************************************************************
; run_pulsar
; *******************************************************************
run_pulsar:
        lea _pus,a0
        tst blanka
        bne vop3
        move pucnt,d0
        and #$0f,d0      ;get pu frame ctr
        lea pucycl,a1
        move.b 0(a1,d0.w),d0
        asl #2,d0
        move.l 0(a0,d0.w),(a6)    ;set header-frame
vop3:
        move.l pulsar_zspeed,d0
        sub.l d0,12(a6)
        move 16(a6),d0
        move webcol,d1
        asl #2,d0
        move frames,d7
        and #$0f,d7
        lsl #4,d7
        move.l lanes,a1
        move.l 0(a1,d0.w),a2    ;address of lane's vertex list cluster
        move.b d1,2(a2)    ;Set this line to blue
        move.b d1,4(a2)    ;make end bar flash
        move.l 4(a1,d0.w),a3
        move.b d1,2(a3)    ;Set this line to blue
        cmp #-2,wave_tim
        beq rrts
        bsr collie
        bne pkm
        cmp #webz-80,12(a6)
        blt lanetop    ;transform into a Flipper or a pair of Psparks
        move frames,d7
        and #$0f,d7
        lsl #4,d7
        move.b d7,4(a2)    ;make end bar flash
        move pucnt,d0
        and #$0f,d0
        cmp #7,d0    ;check for Deadly
        bne rrts
        tst zapdone    ;do we need to start a zap sound?
        bne zd0      ;no, someone already did
        move #1,zapdone
        move #$07,sfx
        move #51,sfx_pri
        move.l #500,sfx_pitch
        jsr fox

zd0:
        move 16(a6),d0
        asl #2,d0
        move webcol,d6
        move.l lanes,a1
        move.l 0(a1,d0.w),a2    ;address of lane's vertex list cluster
        move.b d7,2(a2)    ;Set this line to yellow
        move.b d7,4(a2)      ;set blue again
        move.l 4(a1,d0.w),a2
        move.b d7,2(a2)    ;Set this line to yellow
        move.b d6,4(a2)
        bsr checlane_only
        beq frouch    ;Kill player if we are in his Lane
        rts

frouch:
        move.l a0,-(a7)
        lea gmes3,a0
        clr.l d0
        move.l #$8000,d1
        bsr setmsg
        move.l (a7)+,a0
        bra ouch

pkm:
        move #3,d0
        bra fkm


lanetop:
        tst t2k
        beq flipping_heck  ;not T2K, Pulsars turn into flippers

        move #23,54(a6)    ;Type to Pulsar-Spark
        move prop_del,44(a6)  ;set propagation delay
        move #1,46(a6)    ;direction of propagation
        move.l a6,-(a7)
        move.l freeobjects,a0  ;pick up new object
        move.l (a6),(a0)  ;get header of original 
        move #23,54(a0)
        move prop_del,44(a0)
        move #-1,46(a6)    ;set Pspark stuff on new entity
        move.l 4(a6),4(a0)  ;general purpose dupe
        move.l 8(a6),8(a0)
        move.l 12(a6),12(a0)
        move.l 16(a6),16(a0)  ;copy position and Web stuff
        move.l 28(a6),28(a0)
        move.l 32(a6),32(a0)  ;copy angles and draw type
        move 42(a6),42(a0)  ;copy rez
        move.l 50(a6),50(a0)  ;copy status info
        bsr insertobject  ;add it in
        move.l (a7)+,a6    ;get back original object header
        rts

; *******************************************************************
; run_pspark
; *******************************************************************
run_pspark:
        bsr checlane
        beq frouch    ;check for hit player
        bsr collie      ;Coll det
        bne fkillme
        sub.b #1,44(a6)
        bpl rrts    ;count down to motion-delay
        move.b 45(a6),44(a6)  ;reset propagation delay
        move web_max,d0
        sub #1,d0
        tst 46(a6)    ;check motion sign
        bmi propleft
propright:
        add #1,16(a6)  ;propagate to right
        cmp 16(a6),d0
        bpl toweb
        tst connect
        bne wwrap
        neg 46(a6)
        bra propleft
wwrap:
        clr 16(a6)
        bra toweb
propleft:
        sub #1,16(a6)
        bpl toweb
        tst connect
        bne wwrap2
        neg 46(a6)
        bra propright
wwrap2:
        move d0,16(a6)
        bra toweb

; *******************************************************************
; blowmeaway
; *******************************************************************
blowmeaway:
        tst blanka
        beq vecbons
xbonx:
        move #3,d1
        bsr rand
xbon:
        move d0,-(a7)
        add #4,d0
        bsr doscore
        tst warped
        bne ntfx
        move #8,sfx
        move #3,sfx_pri
        jsr fox
ntfx:   move (a7)+,d0
        asl #3,d0
        lea px_bons,a0
        move.l 4(a0,d0.w),d1
        move.l 0(a0,d0.w),d0
        move.l #$8000,d2
        move.l #$20000,d3
        bsr xpixex      ;extended game, bonusus are pixelshatter effects
        move.l #$80000,24(a6)
        move #28,54(a6)      ;try XR_PIXEX
        move #6,34(a6)
        rts

; *******************************************************************
; any_pixex
; *******************************************************************
any_pixex:
        tst ofree
        bmi rrts
        move.l a6,-(a7)
        move.l freeobjects,a0
        move.l a2,16(a0)
        move.l d0,36(a0)
        move.l d1,40(a0)
        move.l vp_xtarg,d0
        move.l vp_ytarg,d1    ;position of our viewpoint
        asr.l #5,d0
        asr.l #5,d1      ;/128
        clr.l 4(a0)
        clr.l 8(a0)      ;start at 0,0
        move #webz+100,12(a0)
        move.l d0,20(a0)
        move.l d1,24(a0)    ;save it
        move.l _oneup,(A0)
        move #15,34(a0)
        move #150,46(a0)
        move #35,54(a0)
        clr 52(a0)
        bsr insertobject
        move.l (a7)+,a6
        rts
        

; *******************************************************************
; vecbons
; *******************************************************************
vecbons:
        move.l vp_xtarg,d0
        move.l vp_ytarg,d1    ;position of our viewpoint
        sub.l 4(a6),d0
        sub.l 8(a6),d1      ;motion vector to the viewpoint
        asr.l #5,d0
        asr.l #5,d1      ;/128
        move.l d0,20(a6)
        move.l d1,24(a6)    ;save it
        move #3,d1
        bsr rand
        move d0,-(a7)
        add #4,d0
        bsr doscore
        move (a7)+,d0
        asl #2,d0
        lea _bons,a1
        move.l 0(a1,d0.w),(a6)    ;header to srandom bonus-points
        clr 36(a6)
        move #30,38(a6)
        clr 42(a6)      ;double rez
        move #4,44(a6)
        move #2,34(a6)      ;set up ztrail
        clr 28(a6)      ;clear rotate
        move #10,54(a6)      ;blowaway
        clr 52(a6)      ;not an enemy
        move #150,46(a6)    ;duration
;  bsr webinfo
        move #8,sfx
        move #3,sfx_pri
        jsr fox
        rts


; *******************************************************************
; do_oneup
; Give the player an additional life!
; *******************************************************************
do_oneup:
        add #1,lives      ; Add a life
        add #1,lastlives  ; Add a life.
        move #24,sfx      ; Get the one up sound effect.
        move #3,sfx_pri   ; Set priority.
        jsr fox           ; Run the sound effect.

        tst noxtra        ; Extra points?
        bne rrts          ; No, return.
        move #50,holiday  ; Is this a temporar invulnerability to bullets? 
        move #1,ud_score  ; Prevent score from being updated for a short time?
        tst ofree         ; Free object?
        bmi rrts          ; No, return.

        ; Create a 'One Up' object. This is an effect where the extra life
        ; is added to the player's lives count.
        move.l freeobjects,a0  ; Get a free object from the freeobjects list.
        move.l vp_xtarg,d0     ; Get our x viewpoint pos.
        move.l vp_ytarg,d1     ; Get our y viewpoint pos.
        asr.l #5,d0            ; Divide by 128
        asr.l #5,d1            ; Divide by 128
        clr.l 4(a0)            ; Set X pos of object to 0
        clr.l 8(a0)            ; Set Y pos of object to 0
        move #webz+100,12(a0)  ; Set Z pos relative to web.
        move.l d0,20(a0)       ; Set X viewpoint.
        move.l d1,24(a0)       ; Set Y viewpoint
        move.l _oneup,(a0)     ; Set the header to _oneup
        clr 36(a0)             ; Clear the pixel data address.
        move #30,38(a0)        ; Set the colour.
        move #-1,42(a0)        ; Set the scale.
        move #4,44(a0)         ; Set climb mode.
        move #2,34(a0)         ; Set the index into draw_vex (draw_z).
        clr 28(a0)             ; Clear the orientation/rotation.
        move #12,54(a0)        ; Set the object type to oblow
        clr 52(a0)             ; Set it not be an enemy
        move #150,46(a0)       ; Set the duration

        tst blanka             ; 
        beq veconeup           ; Insert it as object type oblow.
        move #7,34(a0)         ; Set the object type to draw_oneup.

veconeup:
        bsr insertobject       ; Insert the object.
        rts

; *******************************************************************
; oblow
; *******************************************************************
oblow:  add.b #$10,41(a6)    ;Makes oneups flash

; *******************************************************************
; blowaway
; *******************************************************************
blowaway:
        sub #$40,36(a6)
oblow2: sub #1,12(a6)
        move.l 20(a6),d0
        add.l d0,4(a6)
        move.l 24(a6),d0
        add.l d0,8(a6)

        sub #1,46(a6)
        bpl rrts
        move #1,50(a6)      ;tell FG to unlink
        rts

; *******************************************************************
; Unused code
; *******************************************************************
bum:    illegal

; *******************************************************************
; go_downc
; two player Claw going down
; *******************************************************************
go_downc:

        bsr go_down
        blt rrts    ;go_down return >0 if we are at the btm
llost:
;  sub #1,dying
        move #40,54(a6)    ;go to Loiter mode (waits for DYING=0 before proceeding)
        clr 34(a6)    ;set to Not Displayed
        rts

; *******************************************************************
; loiter
; *******************************************************************
loiter:
        tst dying
        bne rrts
        move #1,ud_score
        sub #1,lives
        bmi killp2
        move #webz-80,12(a6)  ;restart new claw on top of web after godown
        bra set_rezclaw    ;re-rez claw in

killp2:
        move #-1,54(a6)    ;make him Dead
        clr 34(a6)    ;make him Not Drawn
        bra setsnatch

; *******************************************************************
; go_downf
; *******************************************************************
go_downf:
;
; Flipper go-down

        bsr go_down
        blt rrts
        move #1,50(a6)    ;Unlink in FG
        rts

; *******************************************************************
; go_down
; *******************************************************************
go_down:
        add #2,12(a6)
        cmp #webz+80,12(a6)
        rts   

; *******************************************************************
; take_me_to_your_leader
; *******************************************************************
take_me_to_your_leader:
        move.l tmtyl,a0
        move.l _claw,a1
        jsr zoomdown
        add #2,12(a0)
        add #2,12(a1)
        cmp #webz+80,12(a1)
        blt rrts
setsnatch:
        move.l #snatch_it_away,routine  ;Tuff titty
        clr l_soltarg
        rts

; *******************************************************************
; snatch_it_away
; *******************************************************************
snatch_it_away:
        bsr rightit
        sub #8,vp_z
        clr evon
        cmp #-400,vp_z
        bgt rrts
        move.l #rrts,routine
xquick:
        sub #1,lives
        clr _pauen
        clr pauen
        move #1,term
        rts

; *******************************************************************
; pzap
; Multi-player version of ZAP_PLAYER as intrinsic routine for a single claw
; *******************************************************************
pzap:

        add #12,28(a6)
        sub #$80,36(A6)
        sub.l #$4000,12(a6)
        cmp #webz-100,12(a6)
        blt llost    ;rez new ship (or not); uses code from go_down
        rts

; *******************************************************************
; zap_player
; *******************************************************************
zap_player:
        bsr rightit
        move.l _claw,a0

npss:
        move.l _zap,(a0)    ;Claw shape to zap
        move.l 4(a0),vp_xtarg
        move.l 8(a0),vp_ytarg
        add #12,28(a0)
        sub #$80,36(a0)
        sub.l #$11000,vp_z
        sub.l #$4000,12(a0)
        bpl vp_xform
        clr 34(a0)    ;turn claw off after exploding it
        bsr zapson
        bra setsnatch


xzcollie:
        tst _sz    ;special szap detect - not sz if this is second time (for bulls)
        beq colok
        bmi colok
        tst szap_avail
        bmi colok
        bra zappit
        
mcollie:
        move #1,d6    ;This entry just finds the bullet that hit us, if any
        bra colok1

collie:
;
; Collision detect the current object with all currently active bulls. Return with non-0 for a hit, and kill the bull.

        tst _sz
        beq colok
        bmi colok
zappit:
        tst inf_zap
        bne zizzit
        move #-1,_sz
zizzit:
        move.l 4(a6),boltx
        move.l 8(a6),bolty
        move.l 12(a6),boltz
        move #1,bolt_lock
        move #4,wave_speed
        move #1,d0    ;Hit (SZ)
        rts
colok:
        clr d6
colok1:
        move 16(a6),d0
        move 12(a6),d1    ;Our web and Z position
        move bullmax,d7    ;8 bullets max
        lea bulls,a5
dog:
        move.l (a5)+,d2
        beq yap
        move.l d2,a4    ;A real bull
        cmp 16(a4),d0
        bne yap      ;Not on our web seg
        move 12(a4),d3
        sub d1,d3
        bpl bone
        neg d3
bone:
        cmp #6,d3    ;Abs collision threshold
        blt bite    ;We got one!
yap:
        dbra d7,dog    ;Loop for all possibull bulls
        clr d0
        rts      ;Return zero, no collision
bite:
        tst d6
        bne rrts    ;Return with bullet in a4
        tst h2h
        bne h2h_special
        cmp #10,34(a4)    ;draw mode #10 is particle beam, does not stop
        bge xle3      ;Use XLE only to make ring bullets spark off end of Spikes
        tst blanka
        beq jstop    ;in old Tempest mode, bulls just stop
        cmp #6,54(a6)
        beq xle      ;bullets off Spikes spatter
jstop:
        move.l a4,a0
kbull:
        move.l 24(a0),a1  ;Clear coll table entry
        clr.l (a1)
        move #4,54(a0)    ;Kill nxttime
xle2:
        move #1,d0    ;return a hit
        rts  
h2h_special:
        move 36(a4),h2h_sign
        bra jstop
xle:
        tst 20(a6)    ;is this a Super Spike?
        beq dxle
        bsr dxle
        move #0,d0    ;spatter but return no hit for s.s.
        rts
dxle:
        move.l 24(a4),a1
        move.l #0,(a1)
        move.l #-16,(a4)
        move #26,54(a4)    ;Make it splatter
        move #8,30(a4)
        move #1,34(a4)
        bsr rannum
        move d0,46(a4)
        bra xle2
xle3:
        cmp #6,54(a6)    ;check for power ring hitting super spike
        bne xle2    ;not a power ring, goes thru
        tst 20(a6)
        beq xle2    ;not Super
        bra dxle    ;go kill-and-spatter, that was Super

; *******************************************************************
; toweb
;
; Fix an object in the Web according to its web position in 16(a6), and return useful
; stuff about the lane it is on.
; *******************************************************************
toweb:

        bsr webinfo
        swap d4
        clr d4
        swap d5
        clr d5        ;midpoint to 16:16
        move.l d4,4(a6)
        move.l d5,8(a6)      ;position on web set...
        move 16(a6),d6
        lsl #1,d6
        move.l web_otab,a1
        move 0(a1,d6.w),28(a6)    ;align to web section
        rts


; *******************************************************************
; l_webinfo
; *******************************************************************
l_webinfo:
        move 16(a6),d0    ;current lane
        sub #1,d0
        bpl webinf      ;-1 is positive, OK
        tst connect
        beq websame      ;not connected, return current lane
        add web_max,d0      ;wrap it
        bra webinf

; *******************************************************************
; r_webinfo
; *******************************************************************
r_webinfo:
        move 16(a6),d0
        add #1,d0
        move web_max,d1
        cmp d0,d1
        bgt webinf      ;check for on web
        tst connect
        beq websame      ;not connected, return this lane
        sub d1,d0      ;wrap me baby
        bra webinf

websame:
        move 16(a6),d0  
webinf:
        move d0,-(A7)        ;call webinfo with an arbitrary d0 which is preserved
        bsr webi
        move (a7)+,d0
        rts

; *******************************************************************
; webinfo
; *******************************************************************
webinfo:
        move 16(a6),d0
webi:   move.l web_ptab,a1      ;point to XY lane ends
        asl #2,d0
        lea 0(a1,d0.w),a1
        move (a1)+,d0
        move (a1)+,d1
        move (a1)+,d2
        move (a1)+,d3      ;get X and Y of the endpoints on the lane

        sub web_x,d0
        sub web_x,d2
        sub #8,d1
        sub #8,d3
        asl #2,d0
        asl #2,d1
        asl #2,d2
        asl #2,d3      ;(d0-d1) and  (d2,d3) are the vertex co-ordinates of the lane sides..
        
        move d2,d4
        move d3,d5
        sub d0,d4
        sub d1,d5      ;vector size
        asr #1,d4
        asr #1,d5      ;halve it
        add d0,d4
        add d1,d5      ;(d4,d5) is the midpoint
        rts

; *******************************************************************
; rotate_web:
; A 'Frame' routine called during vsync interrupt to update the state
; of the web.
; A 'routine' routine.
; *******************************************************************
rotate_web:
        lea _web,a6          ; Load the web data structure.
        sub.l #$10000,12(a6) ; move towards viewer
        add #1,30(a6)        ; rotate until angle xz is zero
        move 30(a6),d0
        asr #1,d0
        add #$80,d0
        move d0,32(a6)
        and #$ff,30(a6)  
        bne rrts

iclaw:  move.l #moveclaw,routine ; Next routine in state is moveclaw.
        tst solidweb             ; Is it a solid or transparent web?
        beq znazm                ; If transparent, skip.
        move #248,l_soltarg

znazm:  lea _web,a0              ; Load the web data structure.
        move.l (a0),a1
        move.l #0,(a1)           ;set web XY only
        rts

; *******************************************************************
; rez_claw
; A member of the run_vex list.
; *******************************************************************
rez_claw:
        tst h2h
        beq srezclaw
        move.l #-12,(a6)  ;set displayed
        move #1,34(a6)
        move #30,54(a6)
        cmp #$8f,40(a6)
        bne rrts
        tst practise
        beq gwave
        clr 34(a6)
        clr 54(A6)
        move.l 56(a6),a0
        move.l 56(a0),a0
        clr 34(a0)
gwave:
        move.l a6,-(a7)
        move cweb,d0
        and #$0f,d0
        lea h2hlevs,a0
        lsl #2,d0
        move 2(a0,d0.w),d1
        move 0(a0,d0.w),d0
        bmi nogenn
        move d1,-(a7)
        jsr make_h2hgen    ;make the enemies
        move (a7)+,d1
nogenn:
        tst d1
        bmi noball 
balls:
        move d1,-(a7)  
        jsr make_h2hball
        move (a7)+,d1
        dbra d1,balls
noball:
        lea fightmsg,a0
        clr.l d0
        move.l #$8000,d1
        bsr setmsg    ;say Fight!
        move #16,afree    ;put max alien lim in
        move.l (a7)+,a6
        rts

srezclaw:
        move #17,34(a6)
        add #$40,36(A6)  ;close rez spacing
        bne go_con
        
        move.l _claw,d0
        cmp.l (a6),d0
        bne ncjmp    ;only clear jmp if this is a claw

        clr.l cjump    ;use as jump indicator/velocity
ncjmp:
        tst blanka
        beq vclaw
        cmp #21,46(a6)
        beq vclaw    ;standard vector rez if a droid
        move #16,34(a6)    ;this is draw solid claw
        bra rclaw
vclaw:
        move #1,34(a6)    ;set drawmode normal
rclaw:
        move 46(a6),54(a6)  ;set clawcon as intrinsic routine
        move #-1,52(a6)    ;set mode to Vuln
go_con:
        move 46(a6),d0    ;skip on to clawcon (can move and fire during rezz)
        asl #2,d0
        lea run_vex,a0
        move.l 0(A0,d0.w),a0
        jmp (a0)

dsclaw2:
        cmp #21,46(a6)
        beq droidyo
        jsr nutargg
droidyo:
        jmp draw_z

; *******************************************************************
; Despite its name this routine updates the state of most active game
; objects in addition to just the claw.
; Move the claw, generate waves, update some objects.
; run_wave: Manages all enemies for this frame, including generating
;           new ones.
; A 'routine' routine.
; *******************************************************************
moveclaw:
        bsr vp_xform      ;do dynamic vp
        tst h2h
        bne h2hrun
        bsr run_wave      ; Run the wave generator!
        tst chenable      ; Is cheating enabled?
        beq nofire
        cmp #-2,wave_tim
        beq nofire
        btst.b #1,pad_now+2    ;look for Option
        beq noptcheat
        jsr douttah       ; Cheat, get more points and go to next level.
        bra nofire

noptcheat:
        ; Another cheat, lets us warp.
        move.l pad_now,d0
        and.l #six,d0
        beq nofire      ;needs this on pad 1 too!
        jsr swarp       ; Warp!
nofire:
        bsr fire        ; Fire a bullet if necessary.
        ; The main routine for updating the state of all the active
        ; objects in the game and the overall game state.
        bsr run_objects ; Update active objects
        bsr vp_set      ; Update camera viewpoint.
        rts

; *******************************************************************
; h2hrun
; Update all objects in a h2h game.
; *******************************************************************
h2hrun:
        bsr run_objects
        bsr vp_set2
        clr.l vp_xtarg
        tst _won
        bmi rrts
        sub #1,_won
        bne rrts
        clr _pauen
        clr pauen
        move.l #rrts,routine
        move #1,term
        rts

; *******************************************************************
; run_h2hclaw
; *******************************************************************
run_h2hclaw:
        tst 48(a6)
        beq clawrunn
        move.l 56(a6),a0
        move.l 56(a0),a0
        clr 34(a0)
        tst 48(a6)
        bpl addii

        sub #1,48(a6)
        cmp #-64,48(A6)
        bgt rrts
        tst _won
        bmi roga
        add #1,48(a6)
        rts
roga:
        move #150,48(a6)

addii:
        sub #1,48(a6)

clawrunn:
        move.l pad_now,d0
        clr conswap
        move #1,whichclaw
        cmp #$8f,40(a6)      ;Green claw is p2
        bne h2hcc
        move #2,whichclaw
        move.l pad_now+4,d0
        move #1,conswap
h2hcc:
        move.l d0,-(a7)
        move.l (a6),-(a7)
        bsr clawcon
        move.l (a6),36(a6)
        move.l (a7)+,(a6)
        move.l 56(a6),a4
        move.l 56(a4),a4    ;point to mirror
        move.l (a7)+,d0      ;get buttons back
        move.l 4(a6),4(a4)
        move.l 8(a6),8(a4)
        move.l 16(a6),16(a4)
        and.l fire_1,d0
        bne nomirr
        tst 48(a6)
        bne rrts
        move #1,34(a4)
        rts
nomirr:
        move #0,34(a4)  
        move frames,d1
        move.l #$40000,d0
        cmp #$8f,40(a6)
        bne nomirr1
        neg.l d0
        add #3,d1
nomirr1:
        and #7,d1
        bne rrts
        tst shots
        bmi rrts
        sub #1,shots
        move.l a6,a1
        bra h2hfrab
        

; *******************************************************************
; run_mirr
; *******************************************************************
run_mirr:
        add #1,28(A6)
        rts


; *******************************************************************
; claw_con1
; A member of the run_vex  list.
; *******************************************************************
claw_con1:
        move #1,whichclaw
        tst auto
        beq sclawr

        move.l pad_now,-(a7)
        move droid_data,d0    ;this is the closest enemy to the top of the Web
        bsr lor        ;ask Left or Right to get there
        bpl moveme
        clr.l 20(a6)      ;stop claw on ok lane
        move.l fire_1,pad_now
gscl:
        bsr sclawr
        move.l (a7)+,pad_now
        rts

moveme:
        bne clawright      ;init claw motion to the right.
        move.l fire_1,d0
        or.l #$00400000,d0
        move.l d0,pad_now
        bra gscl
clawright:
        move.l fire_1,d0
        or.l #$00800000,d0
        move.l d0,pad_now
        bra gscl

sclawr:
        move.l fire_1,d0
        and.l pad_now,d0
        beq cc2
        sub.b #1,48(a6)
        bpl cc2
        move.b 49(a6),48(a6)
        tst shots
        bmi cc2
        tst locked
        bne cc2
        sub #1,shots
        move.l a6,a1
        clr d7
        bsr frab    ;fire a bull
cc2:
        tst t2k      ;T2K specific action
        beq cce      ;T2K not on.
        move.l cjump,d0    ;check for jump running...
        beq chek4jump
        add.l d0,12(a6)
        move.l 12(a6),d1
        move #webz-80,d2
        swap d2
        clr d2
        sub.l d2,d1
        add.l vp_zbase,d1
        move.l d1,vp_z
        move.l d1,vp_ztarg
        add.l #$c11,cjump
        tst.l d0
        bmi cce
        cmp #webz-80,12(a6)
        blt cce
        move #webz-80,12(a6)
        clr 14(a6)
        clr.l cjump
        and.l #$fffc0000,vp_z
        and.l #$fffc0000,vp_ztarg  

chek4jump:
        cmp #-2,wave_tim
        beq cce
        tst jenable
        beq cce
        move.l fire_2,d0
        and.l pad_now,d0  ;check fire 2 for jump button
        beq cce
        move.l #-$20000,cjump  ;Start a jump
        move #6,sfx
        jsr fox      ;Make a v. silly noise
cce:
        move.l pad_now,d0
        bra clawcon

; *******************************************************************
; claw_con2
; A member of the run_vex list.
; *******************************************************************
claw_con2:
        move #2,whichclaw
        move.l pad_now+4,d0
        and.l fire_1,d0
        beq cc3
        sub.b #1,48(a6)
        bpl cc3
        move.b 49(a6),48(a6)
        tst shots+2
        bmi cc3    
        sub #1,shots+2
        move.l a6,a1
        move #$80,d7      ;marker for bullets to distinguish pl. 1 and pl 2 shots
        bsr frab
cc3:
        move.l pad_now+4,d0

clawcon:
        move.l 20(a6),d1
        move.l 24(a6),d2      ;current claw veloc and accel
        move.l #$6000,d3    ;maximum permitted velocity

        swap d0
        and #$c0,d0      ;check for pad left or right
        bne pad_pressed      ;go do action if pressed
stopclaw:
        clr.l 20(a6)
        bra domove    ;stop the claw
pad_pressed:

        move.b sysflags,d7    ;Rotary controller test hack
        and #$18,d7
        beq joyconn      ;Using standard controller
        tst auto
        bne joyconn

        cmp #1,whichclaw
        bne notc1
        btst #3,d7
        beq joyconn
        move.l rot_cum,20(a6)
        clr.l rot_cum
        clr.l 24(a6)
        bra domove      ;Use absolute speed value if we are on the rotary controller

notc1:
        cmp #2,whichclaw
        bne joyconn      ;must be the droid or a demo
        btst #4,d7
        beq joyconn
        move.l rot_cum+4,20(a6)
        clr.l rot_cum+4
        clr.l 24(a6)
        tst conswap
        beq domove
        neg.l 20(a6)      ;reverse p2 controls in h2h mode
        bra domove

joyconn:
        btst #7,d0
        bne claw_right
        tst conswap
        bne c_rgt      ;this is so h2h player 2 is the right way around
c_lft2:
        tst.l 20(a6)      ;check direction we were moving
        beq c_lft      ;zero, movement starting, ok
        bpl stopclaw      ;stop before reversing
c_lft:
        neg.l d3      ;negate speed limiter
        sub.l d2,d1      ;add acceleration to velocity
        cmp.l d1,d3
        bgt domove      ;too fast
        bra a_ok      ;update speed
claw_right:
        tst conswap
        bne c_lft2
c_rgt:
        tst.l 20(a6)      ;check direction
        bmi stopclaw      ;stop before reverse
        add.l d2,d1
        cmp.l d3,d1
        bgt domove
a_ok:
         move.l d1,20(a6)

; *******************************************************************
; Actually move the claw along the web.
; *******************************************************************
domove:
        move.l lanes,a1
        move 16(a6),d0
        move webcol,d1
        asl #2,d0
        move.l 0(a1,d0.w),a2    ;address of lane's vertex list cluster
        move.b d1,2(a2)    ;Set this line to blue
        move.l 4(a1,d0.w),a2
        move.b d1,2(a2)    ;Set this line to blue
        move.l 20(a6),d1
        add.l 16(a6),d1
        bpl ulchk
        swap d1
        tst connect
        beq spdone
        move web_max,d1
        sub #1,d1
        bra spok 
ulchk:
        swap d1
        cmp web_max,d1
        blt spok
        tst connect
        beq spdone
        clr d1
spok:
        swap d1
        move.l d1,16(a6)  
spdone:
        move 16(a6),d0
        move.l web_ptab,a0      ;point to XY lane ends
        asl #2,d0
        move d0,d1      ;Cause our lane to be drawn in outline yellow
        lea _web,a4
        move 40(a4),d6
        move.l lanes,a1
        move.l 0(a1,d0.w),a2    ;address of lane's vertex list cluster
        move.b 41(a6),2(a2)    ;Set this line to claw colour
        move.b d6,4(a2)      ;set blue again
        move.l 4(a1,d0.w),a2
        move.b 41(a6),2(a2)    ;Set this line to yellow
        move.b d6,4(a2)
        lea 0(a0,d0.w),a0
        move (a0)+,d0
        move (a0)+,d1
        move (a0)+,d2
        move (a0)+,d3      ;get X and Y of the endpoints on the lane

        sub web_x,d0
        sub web_x,d2
        sub #8,d1
        sub #8,d3
        asl #2,d0
        asl #2,d1
        asl #2,d2
        asl #2,d3      ;allow for scaling (webs are drawn at x4)
        sub d0,d2
        sub d1,d3      ;vector size
        asr #1,d2
        asr #1,d3      ;halve it
        add d2,d0
        add d3,d1      ;add it to get midpoint

        move d0,d2
        move d1,d3      ;save coords of claw for viewpoint shifter
        move d3,spany
        move d0,d4      ;Range should be +/-128
        asl #2,d4
        add #128,d4      ;0-255
        lsl #7,d4
        move d4,span+2
        swap d0
        clr d0
        swap d1
        clr d1
        move.l d0,4(a6)
        move.l d1,8(a6)      ;place claw on th web
        cmp #17,34(a6)
        bne nutargg
        rts
        
; *******************************************************************
; nutargg
; *******************************************************************
nutargg:
        move.l 16(a6),d0
        lsl.l #6,d0
        swap d0
        move d0,d1
        and #$1c,d0
        move.l #1,d2      ;h.scale valu
        and #$20,d1
        bne noflipme
        neg.l d2
        move #$1c,d1
        sub d0,d1
        move d1,d0      ;opposite frame
noflipme:
        lea claws,a0
        move.l 0(a0,d0.w),(a6)    ;anim-frame of claw
        move 16(a6),d0
        lsl #1,d0
        move.l web_otab,a0
        move 0(a0,d0.w),28(a6)    ;align to web section
        move.l (a6),a0
        move.l d2,4(a0)      ;scale (-ve to flip frame)
        rts

; *******************************************************************
; vp_set
; Update the camera's viewpoint for one or both players. 
; *******************************************************************
vp_set:
        cmp #1,players
        bne vp_set2
        move.l _claw,a0
        move 4(a0),d2
        move 8(a0),d3
dood:   asr #1,d2
        asr #1,d3
dshrnk:
        move view,d0
        asl #3,d0
        lea views,a0
        add 0(a0,d0.w),d2
        add 2(a0,d0.w),d3    ;translate targ to currently set vp
        move 4(a0,d0.w),vp_ztarg
        move.l vp_ztarg,vp_zbase
        cmp #1,view
        bne dpshift
        move 0(a0,d0.w),vp_xtarg
        move 2(a0,d0.w),vp_ytarg
        rts
dpshift:
        move d2,vp_xtarg
        move d3,vp_ytarg    ;Viewpoint targets
        rts

vp_set2:
        move.l _claw,a0
        move 4(a0),d2
        move 8(a0),d3
        move.l 56(a0),a0
        sub 4(a0),d2
        sub 8(a0),d3
        asr #1,d2
        asr #1,d3
        add 4(a0),d2
        add 8(a0),d3
        bra dood


; *******************************************************************
; vp_xform
; Transform the player's viewpoint if necessary
; *******************************************************************
vp_xform:
        move camroll,d0
        add d0,camrx
        move.l vp_x,d0
        cmp.l vp_xtarg,d0
        beq xtargr
        move.l vp_x,d0
        move.l vp_xtarg,d1    ;Doing the viewpoint transformation smoothly
        move.l #$4000,d2    ;VP xform speed
        tst.l cjump
        beq cjj1
        asl.l #1,d2
cjj1:
        cmp.l d0,d1
        beq xtargr
        bpl xtar1
        neg.l d2
xtar1:
        add.l d2,vp_x
xtargr:
        move.l vp_y,d0
        cmp.l vp_ytarg,d0
        beq ytargr
        move.l vp_y,d0
        move.l vp_ytarg,d1
        move.l #$4000,d2
        tst.l cjump
        beq cjj2
        asl.l #1,d2
cjj2:
        cmp.l d0,d1
        beq ytargr
        bpl ytar1
        neg.l d2
ytar1:
        add.l d2,vp_y
ytargr:move.l vp_ztarg,d3
        tst h2h
        beq ratch
        sub.l #$100000,d3  ;h2h views are more distant, sub this constant
ratch:
        move.l vp_z,d0
        cmp.l d3,d0
        beq ztargr
        move.l vp_z,d0
        move.l d3,d1
        move.l #$8000,d2
        cmp.l d0,d1
        beq ztargr
        bpl ztar1
        neg.l d2
ztar1:
        add.l d2,vp_z
ztargr:
        rts

; *******************************************************************
; donkeys
; check VP shift select and music F/X on/off toggle
; *******************************************************************
donkeys:
        tst s_db
        beq kcon
        move.l pad_now,d0
        or.l pad_now+4,d0
        and.l #allkeys,d0
        bne rrts
        clr s_db
        rts
kcon:

        move.l pad_now,d0
        cmp #2,players
        beq mmmm
        tst h2h
        beq nmmmm
mmmm:
        or.l pad_now+4,d0
nmmmm:
        move.l d0,d1
        and.l #view1,d1
        beq cpad1
        clr view
        rts
cpad1:
        move.l d0,d1
        and.l #view2,d1
        beq cpad2
        move #1,view
        rts
cpad2:
        move.l d0,d1
        and.l #view3,d1
        beq cpad3
        move #2,view
        rts
cpad3:
        and.l #$10,d0    ;check 0 (all Music off)
        beq cpad6
        tst modstop
        beq cpad33    ;test if tune already off
        move.b oldvol,vols
intune:
        move.b vols,d0
        and.l #$ff,d0
        clr d1
        jsr SET_VOLUME  
        move #10,s_db
        clr modstop
        move lastmod,d0
        clr modnum
        sub #1,d0
        move #1,unpaused
        jmp playtune
        
cpad33: move #1,modstop    ;stop any tune module
        move.b vols,oldvol
        clr.b vols
        move #10,s_db
        move #1,unpaused
        jmp STOP_MOD

cpad6:  btst.b #2,pad_now+3    ;check 6
        beq rrts

; *******************************************************************
; Display 'warp enabled' message and set warp on.
; *******************************************************************
swarp:
        move #-1,warpy    ; Set warp on.
        lea wtxt3,a0      ; Get "warp enabled" string and stash in a0.
        clr.l d0          ; Set x pos.
        move.l #$8000,d1  ; Set y pos.
        bsr setmsg        ; Initialize message for display.
        rts  

; *******************************************************************
; rightit
; *******************************************************************
rightit:
        move camrx,d0      ;zero roll during warp down if roll is happening
        and #$fe,d0
        beq zoo1
        cmp #$80,d0
        blt zdec
        add #4,d0
zdec:
        sub #2,d0
        move d0,camrx
        rts
zoo1:
        rts

; *******************************************************************
; czoom1
; intrinsic routine for claw-object to do zoom1-type stuff
; A member of the run_vex list.
; *******************************************************************
czoom1:

        bsr zoomup
        lea _web,a0
        move.l 20(a0),d0
        add.l d0,12(a6)
        move.l 12(a6),claud    ;claw distance
        cmp #webz+80,claud
        blt go_con      ;allow control while still on-web
        jsr clzapa
        move #19,d0
        bsr sclawt      ;both claws to zoom2
        clr.l claud
        rts

; *******************************************************************
; czoom2
; same thing for zoom 2
; *******************************************************************
czoom2:

        cmp #2,34(a6)
        beq zinit
        move #2,34(a6)      ;ensure m-mode
        move #0,36(a6)
        move #-1,38(a6)
        move #3,44(a6)      ;auto-init the expand-parameters
        or #8,40(a6)      ;ensure smooth colour-transition of Cube if droid is active
zinit:
        lea _web,a0
        move.l 20(a0),d0
        add.l d0,12(a6)
        add #4,28(a6)
        sub #$40,36(a6)
        bsr zoomup
        move.l claud,d0
        add.l d0,12(a6)      ;move into zplane
        cmp #2000,12(a6)
        blt rrts  
zoo2off:
        
        move.l 24(a0),d0
        move #1,34(a0)      ;Web on again
        neg.l warp_add    ;reset warp spacing
        sub.l d0,vp_z
        sub.l d0,vp_z
        clr.l vp_xtarg
        clr.l vp_ytarg
        add #1,cwave
        add #1,cweb
        move.l #sweb0,s_routine
        move.l #$ffffffff,warp_flash
        clr _pauen
        move.l #rrts,routine    ;get new web and re-init all objects
        jsr zzoomoff
        jsr flushfx      ;have to do this, in case 6-channel FX are on
        move #9,sfx    ;was 9
        move #400,sfx_pri
        jsr fox
        move handl,handl1
        move #9,sfx
        move #400,sfx_pri
        jsr fox  
        move handl,handl2
        move #80,wason
        move.l #500,wapitch
        move.l zoopitch,d0
        lsl #2,d0
        move.l d0,zoopitch
        move #-1,d0

; *******************************************************************
; sclawt
;
; set claw type d0 to one or bothj claws only if they are 'alive'
; *******************************************************************
sclawt:
        move entities,plc+2
        move.l _claw,a1
scloop:
        tst 54(a1)
        bmi isded
        move d0,54(a1)
isded:
        move.l 56(a1),a1
        sub #1,plc+2
        bne scloop
        rts

; *******************************************************************
; zoomup
; *******************************************************************
zoomup:
        add.l #1,zoopitch
        movem.l d0-d5,-(a7)
        move.b vols+1,d4
        lea sines,a2
        move vp_z,d0
        asl #2,d0
        and #$ff,d0
        move.b 0(a2,d0.w),d2
        ext d2
        asr #3,d2

        move.b vols+1,d5
        and #$ff,d5    ;get maximum permitted volume
        move.l #$0c,d0
        move vvol1,d4
        add d2,d4
        cmp d4,d5
        bpl chv1
        move.l #$08,d0    ;8=change pitch and volume
chv1:
        move handl1,d1
        move #1,d3
        move d2,-(a7)
        jsr CHANGEFX
        move d2,vvol1
        move (a7)+,d2
        neg d2  
        move.l #$0c,d0    ;8=change pitch
        move vvol2,d4
        add d2,d4
        cmp d4,d5
        bpl chv2 
        move.l #$08,d0
chv2:
        move handl2,d1
        move #1,d3
        jsr CHANGEFX
        move d2,vvol2
        movem.l (a7)+,d0-d5
        rts

; *******************************************************************
; zoomdown
; *******************************************************************
zoomdown:
        movem.l d0-d3,-(a7)
        move.l #$08,d0    ;8=change pitch
        move handl1,d1
        move #-1,d3
        jsr CHANGEFX
        move.l #$8,d0    ;8=change pitch
        move handl2,d1
        move #-2,d3
        jsr CHANGEFX
        movem.l (a7)+,d0-d3
        rts
zzoomoff:
        clr wson
zoomoff:
        movem.l d0-d3,-(a7)
        move.l #$1,d0    ;1=sample stop
        move handl1,d1
        jsr CHANGEFX
        move.l #$1,d0    ;1=sample stop
        move handl2,d1
        jsr CHANGEFX
        tst modstop
        beq modzon
        jsr DISABLE_FX    ;any SFX to off
        jsr ENABLE_FX    ;any SFX to off
modzon:
        movem.l (a7)+,d0-d3
        rts

; *******************************************************************
; flushfx
; *******************************************************************
flushfx:
        clr wson
pflushfx:
        move #5,d7
flshfx:
        move #300,sfx_pri
        move #29,sfx
        move d7,-(a7)
        jsr fox
        move (a7)+,d7
        dbra d7,flshfx
        rts
        

; *******************************************************************
; zoom1
; A 'routine' routine.
; *******************************************************************
zoom1:  bsr rightit
        lea _web,a0      ;get web
        move.l #3,warp_count
        add.l #$4000,warp_add
        move.l 20(a0),d0
        add.l d0,vp_z      ;move web past yer ears
        add.l d0,24(a0)      ;clock distance zoomed
        move.l zoomspeed,d4
        add.l d4,20(a0)
        cmp #260,vp_z      ;by web Z=40 it will be off of the screen
        bgt z1stop
        cmp #webz+80,claud
        blt nofire
        rts
z1stop: move.l #zoom2,routine    ;get ready to zoom off claw
        clr 34(a0)      ;Web off for hyperspace
        rts

; *******************************************************************
; zoom2
; *******************************************************************
zoom2:  bsr run_objects
        lea _web,a0
        add.l #$4000,warp_add
        move.l _claw,a1    ;get clawe
        move.l 20(a0),d0
        move.l zoomspeed,d4
        add.l d4,20(a0)
        add.l d0,vp_z      ;move web past yer ears
        add.l d0,24(a0)      ;clock distance zoomed
        sub #$40,36(a1)      ;inc spacing
        add.l #$1000,claud
        rts

; *******************************************************************
; zoom3
; *******************************************************************
zoom3:  jsr dowf
        lea _web,a0
        add.l #$4000,warp_add
        tst wason
        beq zoom33
        sub #1,wason
        bne zoom44

        move #22,sfx
        move #101,sfx_pri
        jsr fox      ;say, Superzapper Recharge
        move #22,sfx
        move #101,sfx_pri
        jsr fox

zoom33:
zoom44: move.l zoomspeed,d4
        sub.l d4,20(a0)
        move.l 20(a0),d0
        add.l d0,vp_z
        sub.l d0,24(a0)
        bne rrts
        move.l freeobjects,_claw  ;_claw is the base of the two claws in 2-player modes
        move players,plc+2  ;player loop counter (under interrupt so +2)
zipp0:  move.l freeobjects,a6
        move plc+2,d7
        bsr setclaw    ;init claw object and put it on the web
        bsr insertobject
        sub #1,plc+2
        bne zipp0
        bsr makedroid    ;re-make droid (if one is being used).
        clr vp_z+2
        move.l #0,warp_count
        bra iclaw      ;and go set it to rez

camel:  add #1,d0
        move d0,BORD1
        bra camel

nothing:move #1,screen_ready
        rts

wsync:  move frames,d7
wsnc:   cmp frames,d7
        beq wsnc
        rts

; *******************************************************************
; clrscreen
; *******************************************************************
clrscreen:
        clr d0      ;Clear screen a0
        clr d1  
        move #384,d2
        move #280,d3
        move #$000,d4
        bra BlitBlock
        
; *******************************************************************
; Unused code
; *******************************************************************
make160:
        move #1,14(a0)
        bra mit

makeit_rmw:
        bsr makeit
        move #0,20(a0)
        rts

; *******************************************************************
; makeit_trans
; Make a transparent GPU object from the d0-d5 registers.
; *******************************************************************
makeit_trans:
        bsr makeit
        move #1,20(a0)
        rts

; *******************************************************************
; makeit
; Make a GPU object from the d0-d5 registers.
; *******************************************************************
makeit:
        move d5,14(a0)
mit:
        move.l d0,(a0)
        move.l d1,4(a0)
        move d3,8(a0)
        move d4,10(a0)
        move.l d2,16(a0)
        move #0,12(a0)    ; make an Object
        move #-1,20(a0)    ; post creation mod: -1=none, so default
        rts

wd:     tst frames
        bpl wd
        rts

; ***************************************************************
; The game's main loop
; It handles all the GPU/Blitter drawing. It lets the 'Frame' routine
; look after updates to the objects' state so the only concern here is
; doing all the GPU/drawing operations.
;
; Minter:
; "This loop runs the GPU/Blitter code.  I found that if you
; started up the GPU/Blitter pair from inside the FRAME
; Interrupt, the system would fall over if they got really heavily
; loaded.  MAINLOOP just waits for a sync from the FRAME routine,
; launches the GPU, then loops waiting for another sync."
; ***************************************************************
mainloop:
        move #1,sync               ; Reset the sync
        move #1,screen_ready       ; Reset the screen ready.
        move pauen,_pauen          ; Reset the pause indicator.

main:   tst sync                   ; loop waiting for another sync
        bne main                   ; from the interrupt in 'Frame'

        move #1,sync               ; reset the sync so that we wait for a new frame next time around.
        move.l dscreen,gpu_screen

        move.l mainloop_routine,a0 ; do the actual mainloop work, mainloop_routine
        jsr (a0)                   ; is usually a reference to the 'draw_objects' routine.

        tst z                      ; Is 'z' (stop everything) set?
        bne rax                    ; If it is, then just loop again.

        move.l s_routine,d0        ; Do we have an s_routine?
        beq mloop                  ; If not, check if we're paused.

        tst auto                   ; Are we in demo mode?
        beq nauty                  ; If not, then run the s_routine and continue.
        clr.l s_routine            ; Clear s_routine.
        move #1,z                  ; Set the 'stop everything' mode.
        clr _pauen                 ; Clear the pause mode
        move.l #rrts,routine       ; Clear the 'routine' pointer.
        clr term                   ; Clear term.
        rts                        ; Return.

nauty:  move.l d0,a0               ; Move s_routine pointer to a0.
        jsr (a0)                   ; Run it.
        clr.l s_routine            ; Clear it.

mloop:  tst pawsed                 ; Are we paused?
        beq mlooo                  ; If not, check if we just unpaused.
        jsr paustuff               ; Do the pause mode stuff.
        
mlooo:  tst unpaused               ; Did we just unpause?
        beq nunpa2                 ; If not, prepare to loop back again.

        jsr eepromsave             ; Save the current settings to EEPROM, not sure why.
        clr unpaused               ; We're fully unpaused now.

nunpa2: ; We've finished preparing dscreen, so we can set screen_ready.
        move #1,screen_ready       ; Set screen_ready so 'Frame' can use it at the next vsync interrupt.
        tst term                   ; Has the game been terminated?
        beq main                   ; If not, continue looping.

        ; We've terminated - so bail.
rax:    clr _pauen                 ; Prevent pausing?
        move.l #rrts,routine       ; Clear the routine pointer.
        clr term                   ; Clear term
        rts                        ; Return


; *******************************************************************
; Sync with the GPU
; Switch the current drawing screen to the gpu.
; *******************************************************************
db:     move #1,sync               ; request sync
dboo:   tst sync                   ; Wait for sync to get reset
        bne dboo
        ; Move our double-buffered screen to the GPU.
        move.l dscreen,gpu_screen  ; current DB thang
        rts

; *******************************************************************
; Unused routine.
; Looks like it was used to manipulate interrupts. 
; *******************************************************************
IServ:
        btst.b #2,INT1+1
        beq Frame    ;if not stopobj must be Frame

        ; stop object code can go here
        move #$405,INT1
        clr INT2
        rte

; *******************************************************************
; Frame: MAIN VSYNC INTERRUPT ROUTINE
; This routine is responsible for updating the state of all objects in the
; game. It is called at every vertical sync interrupt.  The counterpart to this
; routine is 'mainloop'.  While mainloop is responsible for processing the
; activeobjects, this routine is where the bulk of the objects get updated
; (run_objects) and created/inserted into the activeobjects list. The main
; place this happens is in the moveclaw routine, which despite its name is
; responsible for managing the waves of enemies too.  The 'sync' and
; 'screen_ready' variables are used to co-ordinate the activities of the
; 'Frame' and 'mainloop' routines.
; *******************************************************************
Frame:
        movem.l d0-d5/a0-a2,-(a7)  ;simple thang to make

        ; vertical blank code goes here
fr:     move INT1,d0
        move d0,-(a7)
        btst #0,d0
        beq CheckTimer    ;go do Music thang

        ; Copy the display list we built in 'blist' to 'dlist'. The
        ; display list will be used by the Objects Processor to paint
        ; the next frame. The pixel data for all the objects in the display
        ; list was generated by the most recent run of 'draw_objects' in
        ; 'mainloop'.
        movem.l d6-d7/a3-a6,-(a7) ; Stash data and address registers.
        move.l blist,a0     ; Stash blist in a0.
        move.l dlist,a1     ; Stash dlist in a1.
        move.l #$30,d0      ; 0x30 units of 4 bytes each to be copied.

        ; Copy all bytes in blist to dlist.
xlst:   move.l (a0)+,(a1)+  ; Copy 4 bytes from blist to dlist.
        dbra d0,xlst        ; Keep copying until we run out of bytes.

        ; Build the display list for the next frame.
        bsr RunBeasties    ;build the next one

        ; Minter: "this code writes the proper screen address to double buffered objects in the display list."
        ; In 'main_loop' we prepare dscreen (double-buffered screen) with objects drawn by the GPU/Blitter. Once it's ready
        ; we set screen_ready. Here we check if screen_ready is set and if so, we swap dscreen into 
        ; 'cscreen' (current screen). We will then update the main screen object in the Display List to
        ;  reference this new address.
setdb:  ; Check if we can swap in the new screen prepared in 'mainloop'.
        tst screen_ready   ; has 'mainloop' finished preparing a new screen?
        beq no_new_screen  ; If no, got to no_new_screen.
        tst sync           ; Has mainloop signalled it safe to swap screens?
        beq no_new_screen  ; If no, go to new_screen.

        ; Swap dscreen into cscreen so that the new screen can be used in the Object List.
        move.l cscreen,d1  ; Stash cscreen in d1.
        move.l dscreen,cscreen  ; Overwrite cscreen with dscreen.
        move.l d1,dscreen  ; Overwrite dscreen with stashed cscreen.
        clr screen_ready   ; Signal that a new screen is required before we come here again.
        clr sync           ; Signal to mainloop it can build a new screen.

        ; Check if we have a new screen to display.
no_new_screen:
        move.l dlist,a0    ; Store the display list in a0.
        move db_on,d7      ; Store the number of double-buffered screens in d7.
        bmi no_db          ; If we don't have any, skip to warp flash.

        ; Update the main screen item in the Object List with the address of the new screen contained
        ; in cscreen. This has the effect of ensuring all the objects we drew with the GPU
        ; and Blitter in 'mainloop' are actually written to the screen by the Object Processor. 
stdb:   move.l cscreen,d6   ; Get address of current displayed screen
        and.l #$fffffff8,d6 ; lose three LSB's
        lsl.l #8,d6         ; move to correct bit position
        move.l (a0),d1      ; get first word of the BMO
        and.l #$7ff,d1      ; clear data pointer
        or.l d6,d1          ; mask in new pointer
        move.l d1,(a0)      ; replace in OL
        lea 32(a0),a0       ; This skips to the next object but is unnecessary since we are
                            ; only updating one item (the main screen) in the Object List with
                            ; our new screen pointer.

        ; Do the warp flash effect.
no_db:  jsr dowf           ; Call the warp flash effect.

        ; Now do some magic for NTSC displays. If this is an NTSC display we want to skip playing
        ; sounds every 5th and 6th interrupt for some reason. 
        tst pal           ; Are we a PAL display?
        bne dtoon         ; If no, we can skip this part.
        add #1,tuntime    ; Increment our visit count.
        cmp #4,tuntime    ; Less than 4?
        ble dtoon         ; If less than 4, go ahead and play a sound.
        cmp #6,tuntime    ; Is it 6? 
        bne ntoon         ; If not, skip playing a sound this time.
        clr tuntime       ; If it is 6, reset to zero. 

        ; Something to do with the Imagitec sound chip. Probably whether we should play
        ; a sound during the interrupt?
dtoon:  tst modstop       ; Is sound turned off?
        bne ntoon         ; If yes, don't play a sound.
        jsr NT_VBL        ; If no, play the next sound using the Imagitec sound synth.

        ; Do any effects required while in pause mode.
ntoon:  tst pawsed        ; Are we paused?
        bne zial          ; If not, skip.
        add #1,frames     ; Add to the number of paused framed.
        move.l fx,a0      ; Stash the current 'fx' routine in a0. 
        jsr (a0)          ; Run the routine.

        ; 'mainloop' might be busy processing stuff in the 'activeobjects' list. If it is,
        ; we will have to skip doing anything in this frame.
zial:   tst locked        ; Are we in the middle of adding stuff to activeobjects?
        beq doframe       ; If not, do our context-specific per-frame routine.
        bra loseframe     ; If we're busy, skip this frame.

        ;
        ; Perform any context specific updates for this frame. 
        ; 'routine' can be any one of:
        ;  - rrts, pauson, pausing, budb, pausoff, paws, zoom1, zoomto,
        ;    waitfor, zprev, znext, zshow, oselector, seldb, tunrun, text_o_run,
        ;    m7run, vicrun, failcount, viccount, txen, tgoto, rotate_web,
        ;    zoom3, zap_player, take_me_to_your_leader, snatch_it_away,           
        ;    moveclaw, zoom2
        ;
        ; rotate_web -> moveclaw -> zoom1 -> zoom2 ->
        ; zoomto -> waitfor -> zprev -> zshow -> waitfor
        ;                   -> znext -> zshow
        ;                   -> rrts
        ; oselector ->seldb -> oselector
        ; _tunn -> tunrun ->
doframe:
        move.l routine,a0 ; Stash the current 'routine' in a0.
        jsr (a0)          ; Run it.
        clr drawhalt      ; This is redundant, it is never set anywhere.

loseframe:
        bsr checkpause     ; Check if the player has requested to pause the game.
        bsr domod          ; Play a frame of music in the Imagitec synth.
        btst.b #0,sysflags ; Check for hardware interlacing. 
        bne chit           ; If not enabled, skip. 

        ; Some kind of fixing up for hardware interlace mode.
        move frames,d0     ; Stash frames in d0. 
        and #$01,d0        ; Get the lsb.
        add #SIDE,d0       ; Add SIDE.
        sub palside,d0     ; Subtract PAL side.
        move d0,beasties   ; Store in beasties.

chit:   movem.l (a7)+,d6-d7/a3-a6 ; Restore values to data and address registers we stashed at the start.

CheckTimer:
        move (a7)+,d0       ; Restore stashed d0.
        move d0,-(a7)       ; Stash it again.
        btst #3,d0          ; Do we need to check for joypad in put?
        beq exxit           ; No, we can exit the interrupt.

        ; Check for joypad input. The logic for rotary controllers was added to support
        ; the potential release of a rotary controller for the Jaguar, but this never happened.
        ; So all rotary controller logic in Tempest 2000 is unused.
        tst roconon    ; Is Rotary Controller enabled?
        bne roco       ; Yes, do the rotary controller.
        jsr dopad      ; No, check for normal joypad in put.
        bra exxit      ; We're done - so exit interrupt.

        ; Logic for reading input from the never-built and never-released rotary controller.
roco:   move pitcount,d1
        and #$07,d1
        bne rotonly
        jsr dopad
rotonly:
        add #1,pitcount
        bsr readrotary  ; Read input from the rotary controller.

        ; Minter: "Yeah, interrupts at 8x normal speed, go do special stuff."
exxit:
        move (a7)+,d0     ; Restore stashed d0.
        lsl #8,d0         ; Shift left 8 bits.
        move.b intmask,d0 ; Add our interrupt mask.
        move d0,INT1      ; Add to INT1.
        move d0,INT2      ; Add to INT2.
        movem.l (a7)+,d0-d5/a0-a2 ; Restore stashed values.
        rte               ; Return from the interrupt.

; *******************************************************************
; The unused rotary controller code. 
; *******************************************************************
readrotary:
;
; read a Rotary Controller

        btst.b #3,sysflags
        beq op2
        move.l  #$f0fffffc,d1    ; d1 = Joypad data mask   (Player 1)
        moveq.l  #-1,d2      ; d2 = Cumulative joypad reading
        move.w  #$81fe,JOYOUT
        move.l  JOYIN,d0      ; Read joypad, pause button, A button
        or.l    d1,d0      ; Mask off unused bits
        ror.l  #4,d0
        and.l  d0,d2      ; d2 = xxAPxxxx RLDUxxxx xxxxxxxx xxxxxxxx
        swap d2
        move d2,d0      ;get joypad in lo byte of d0

        lea lstcon,a1
        lea roconsens,a2
        bsr rroco
        add.l d0,rot_cum

op2:
        btst.b #4,sysflags
        beq rrts

        move.l  #$0ffffff3,d1    ; d1 = Joypad data mask    (Player 2)
        moveq.l  #-1,d2      ; d2 = Cumulative joypad reading
        move.w  #$817f,JOYOUT
        move.l  JOYIN,d0      ; Read joypad, pause button, A button
        or.l    d1,d0      ; Mask off unused bits
        rol.b  #2,d0      ; note the size of rol
        ror.l  #8,d0
        and.l  d0,d2      ; d2 = xxAPxxxx RLDUxxxx xxxxxxxx xxxxxxxx
        swap d2
        move d2,d0

        lea lstcon+2,a1
        lea roconsens+4,a2
        bsr rroco
        add.l d0,rot_cum+4
        rts


; *******************************************************************
; rroco
; Process rotary controller in put.
; *******************************************************************
rroco:
        rol.b #2,d0      ;Phase Bits to bottom of word
        and #$03,d0      ;Get juicy bits
        move (a1),d4      ;Get last value read
        cmp d4,d0
        beq decsens      ;Did not move
        move d0,(a1)      ;Save value we just read
        lea conseq,a0      ;Point to sequence values
        clr d5
slocate:
        cmp.b 0(a0,d5.w),d4
        beq slocated
        addq #1,d5
        bra slocate      ;Locate last position on sequence
slocated:
        subq #1,d5
        and #3,d5
        cmp.b 0(a0,d5.w),d0
        beq rclaw_right      ;(This is just a VERY rough L/R test)
        addq #2,d5
        and #3,d5
        cmp.b 0(a0,d5.w),d0
        beq rclaw_left
        clr.l d0
        rts
rclaw_left:
        bsr incsens
        neg.l d0
        rts
rclaw_right:
incsens:
        move.l #$2000,d0
        move.l (a2),d0
        cmp.l #$5000,d0
        bge rrts
        add.l #$1000,d0
        move.l d0,(a2)
        rts
decsens:
        clr.l d0
        cmp.l #$2000,(a2)
        beq rrts
        sub.l #$200,(a2)
        rts

; *******************************************************************
; gamefx
; Do gamefx
; *******************************************************************
gamefx:
        move.l vp_sfs,d0  ;move the starfield's vp
        add.l d0,vp_sf
        move frames,d0    ;pulsate CLUT colour #2
        and #$ff,d0
        lea sines,a0
        move.b 0(a0,d0.w),d1
        ext d1
        add.b #$40,d0
        move.b 0(a0,d0.w),d0
        ext d0
        add #$80,d0
        add #$80,d1
        and #$f0,d0
        lsr #4,d1
        and #$0f,d1
        or d0,d1
        move d1,flashcol
        lsl #8,d1
        or #$ff,d1
        move d1,CLUT+2
        bsr runmsg    ;run the Messager
        move l_soltarg,d0
        cmp l_solidweb,d0
        beq donowt
        tst d0
        bne inccc
        sub #8,l_solidweb
        bra donowt
inccc:
        add #8,l_solidweb

donowt:
        tst holiday
        bmi rrts
        sub #1,holiday
        bmi swebcol
        move frames,d0
        and #$03,d0
        bne rrts
        bra swebpsych    ;set web all psychedelic colours when HOLIDAY non0

domod:  tst modnum
        beq rrts    ;see if anything is happening?
        bmi deccount    ;dec counter and set
        tst auto
        bne iggi    ;demo can't start tunes
        move modnum,d0
        cmp lastmod,d0    ;same as module already running?
        bne smod
iggi:
        clr modnum
        rts

smod:
        move d0,lastmod  
        move #50,modtimer  ;wait 1 sec
        neg modnum
        jsr FADEDOWN    ;start last tune fading
        rts
deccount:
        tst modstop
        bne decco1
        sub #1,modtimer
        bpl rrts
        move modnum,d0
        clr modnum
        neg d0
        sub #1,d0
        jmp playtune

decco1:
        move #-1,modtimer
        rts

; *******************************************************************
; Update the message displayed to the player with whatever is in a0.
; *******************************************************************
setmsg:
        move #100,msgtim1  ;set default Messager parameters
        move #50,msgtim2
        move.l d0,msgxv
        move.l d1,msgyv
        move.l #$10000,msgxs
        move.l #$10000,msgys
        move.l a0,msg
        rts

runmsg:
        tst.l msg    ;run the Messager
        beq rrts  
        tst msgtim1
        bmi runmsg2
        sub #1,msgtim1
        rts
runmsg2:
        move.l msgxv,d0
        add.l d0,msgxs
        move.l msgyv,d0
        add.l d0,msgys
        sub #1,msgtim2
        bpl rrts
        clr.l msg
        rts

; *******************************************************************
; drawmsg
; Write a message onto the screen.
; Used for Superzapper Recharge, for example.
; *******************************************************************
drawmsg:
        move.l msg,d6
        beq rrts
        jsr text_setup
        move.l d6,a3
        move.l d6,(a0)
        jsr textlength      ;returns length of $ (a3) in pixels in d0
        lsr #1,d0
        neg d0
        add #192,d0
        swap d0
        move #80,d0
        swap d0
        move.l d0,32(a0)
        move.l msgxs,16(a0)
        move.l msgys,20(a0)
        move frames,d0
        lsl #1,d0
        and #$ff,d0
        sub #$7f,d0
        bpl mpo1
        neg d0

mpo1:   sub #$3f,d0
        swap d0
        asr.l #6,d0
        move.l d0,24(a0)
        neg.l d0
        asr.l #1,d0
        move.l d0,28(a0)
        bsr WaitBlit
        lea texter,a0
        jsr gpurun
        jsr gpuwait
        cmp.l #wmes2,msg    ;is it Superzapper?
        beq xtra1
        cmp.l #zmes1,msg
        bne rrts
        lea in_buf,a0
        move.l #zmes2,a3
        bra xtra2
xtra1:  lea in_buf,a0
        move.l #wmesx,a3
xtra2:  move.l a3,(a0)
        jsr textlength      ;returns length of $ (a3) in pixels in d0
        lsr #1,d0
        neg d0
        add #192,d0
        swap d0
        move #100,d0
        swap d0
        move.l d0,32(a0)
        bsr WaitBlit
        lea texter,a0
        jsr gpurun
        jmp gpuwait  

; *******************************************************************
; Unused code
; *******************************************************************
mandfx:
        move palphase1,d0    ;put funky colours in the whole CLUT
        and #$ff,d0
        move palphase2,d5
        and #$ff,d5
        lea CLUT,a1
        lea p_sines,a0
        move #254,d7
        move palad2,d3
        move.l palad3,d4
        add.l d4,palad2
        move.l palad0,d1
        add.l d1,palphase1
        move.l palad1,d1
        add.l d1,palad2

mclut:
        move.b 0(a0,d0.w),d1
        add.b d3,d0
        move.b 0(a0,d0.w),d2
        sub.b d3,d0
        add.b #1,d0
        and #$f0,d2
        lsr #4,d1
        and #$0f,d1
        or d2,d1
        lsl #8,d1
        or #$ff,d1
        move d1,(a1)+
        dbra d7,mclut
        clr (a1)+
        rts


; *******************************************************************
; Pause play if requested.
; *******************************************************************
checkpause:
        move.l pad_now,d0
        tst h2h
        bne bothpau
        cmp #2,players
        bne only1p
bothpau:
        or.l pad_now+4,d0
only1p:
        move.l d0,d1
        and.l #bigreset,d0
        beq chp1
        cmp.l #bigreset,d0
        bne chp1
        move #1,z    ;flag Stop Whatever You Are Doing And Reset!  
        clr auto
chp1:
        tst _auto
        beq chron
        move.l d1,d0
        move.l #allbutts,d1
        and.l d0,d1
        beq chron  
        move #1,z
        move #1,misstit
chron:
        move.l d1,-(a7)
        jsr donkeys    ;check VP shift select and music F/X on/off toggle
        move.l (a7)+,d1
        cmp.l #rrts,routine
        beq rrts
        tst _pauen
        beq rrts
        tst.l paws
        bne rrts
        move.l d1,d0
        and.l #pausebutton,d0 ;check for pause pressed
        beq rrts
        clr.l d0
        clr.l d1
        jsr SET_VOLUME    ;Music off
        jsr pflushfx
        move #-1,vadj
        move.l routine,paws
        move.l #pauson,routine
        move #1,pawsed
        rts

; *******************************************************************
; Unused code
; *******************************************************************
beastiesoff:
        neg beasties+76
        neg beasties+140
        rts


; *******************************************************************
; Pause and wait for input.
; *******************************************************************
paustuff:
        jsr text2_setup
        ; Version number message retained below.
        ;  move.l #$400040,32(a0)
        ;  move.l #vertext,(a0) 
        ;  lea texter,a0
        ;  jsr gpurun
        ;  jsr gpuwait
        tst pausprite
        beq npspri
        lea in_buf,a0
        move.l #$490074,32(a0)    ;was 35
        move.l #pautext,(a0) 
        lea texter,a0
        jsr gpurun
        jsr gpuwait

npspri:
        tst vadj
        bmi rrts

        move #64,d0    ;To do pause+volume displays: clear a block of screen..
        move #100,d1
        move #252,d2
        move #64,d3
        move.l #$00300030,d4
        move.l gpu_screen,a0
        jsr BlitBlock

        lea pvolt1,a0
        lea cfont,a1
        move #104,d0
        jsr centext    ;display ADJUST msg

        move vadj,d7    ;volume to adjust, 0=Tunes, 1=SFX
        move d7,d6
        lsl #2,d6
        lea pvolts,a0
        move.l 0(a0,d6.w),a0
        move #160,d0
        move d7,-(a7)
        jsr centext
        move (a7)+,d7    ;display what we are adjusting...

        lea vols,a0
        move.b 0(a0,d7.w),d0  ;get the actual volume
        
        and #$ff,d0
        lsr #2,d0
        move d0,d1
        lsr #2,d1
        neg d1
        add d0,d1
        move #192,d6
        move #136,d7
        add.l #$40000,pc_1
        add.l #$50100,pc_2
        bsr makepyr      ;make a pyramid for hit points display
        jmp ppyr

pauson:
        move.l pad_now,d0
        or.l pad_now+4,d0
        and.l #pausebutton,d0
        bne rrts
        move.l #pausing,routine
        move #1,pausprite
        clr tunon
        clr fxon
        tst wson
        beq quoke
        jsr zoomoff
quoke:
        jsr DISABLE_FX    ;any SFX to off
        rts      ;debounce

budb:
        move.l pad_now,d0
        or.l pad_now+4,d0
        and.l #$22000000,d0
        bne rrts
        move.l #pausing,routine
        rts

; *******************************************************************
; pausing
; *******************************************************************
pausing:
        add #1,pframes

not_opt:
        move.l pad_now,d0
        tst h2h
        beq p2mrge
        cmp #2,players
        beq np2mrge
p2mrge:
        or.l pad_now+4,d0
np2mrge:
        move.l d0,ppad
        move.l d0,d1
        and.l #$00080008,d1
        beq lpspr
        clr pausprite
lpspr:
        move.l d0,d1
        and.l #abutton,d1
        beq nottune
        move.l #budb,routine
        tst tunon
        beq turnit_on
tunoff:
        clr.l d0
        clr.l d1
        jsr SET_VOLUME    ;turn OFF the tune
        clr tunon
        move #-1,vadj
        bra nottune

turnit_on:
        move #1,tunon
        clr fxon
        clr vadj
nottune:
        move.l ppad,d0

        and.l #bbutton,d0
        beq notfx
        move.l #budb,routine
        tst fxon
        beq tfx_on
        move #-1,vadj
        clr fxon
        bra notfx
tfx_on:
        move #1,fxon

        clr.l d0
        clr.l d1
        jsr SET_VOLUME    ;turn OFF the tune
        clr tunon

        jsr ENABLE_FX    ;Fx back on
        move #1,vadj
notfx:
chunp:
        tst vadj
        bmi ntsel
        tst tunon
        beq adjsfx
        move.l #rrts,a2
        move.l a2,a3
        move.l #tvup,a0
        move.l #tvdn,a1
        jsr pgjoy
        move.b vols,d0
        and.l #$ff,d0
        clr d1
        jsr SET_VOLUME  
        bra ntsel

adjsfx:
        tst fxon
        beq ntsel
        move pframes,d0
        and #$1f,d0
        bne villi
        move #$0b,sfx
        jsr fox      ;make noises
villi:
        move.b vols+1,d0
        and.l #$ff,d0
        move #1,d1
        jsr SET_VOLUME    ;sat FX volume
        move.l #fxup,a0
        move.l #fxdn,a1
        move.l #rrts,a2
        move.l #rrts,a3
        jsr pgjoy

ntsel:
        move.l pad_now,d0
        or.l pad_now+4,d0
        and.l #pausebutton,d0
        beq rrts
        move.b vols,d0    ;Music back on
        and.l #$ff,d0
        clr d1
        jsr SET_VOLUME
        jsr ENABLE_FX    ;Sfx re-enabled
        move.l #pausoff,routine
        move #1,unpaused
        tst wson
        beq rrts
        jmp zoomon

; *******************************************************************
; tvup
; *******************************************************************
tvup:   tst.b vols
        bne tvup1
        tst modstop
        beq tvup1
        clr modstop
        move lastmod,d0
        clr modnum
        sub #1,d0
        jsr playtune
tvup1:  cmp.b #$ff,vols
        beq rrts
        add.b #1,vols
        rts

; *******************************************************************
; tvdn
; *******************************************************************
tvdn:   tst.b vols
        beq stpmod
        sub.b #1,vols
        rts
stpmod: move #1,modstop
        jmp STOP_MOD
fxup:   cmp.b #$ff,vols+1
        beq rrts
        add.b #1,vols+1
        clr modstop    ;if we add it has to be on!
        rts
fxdn:   tst.b vols+1
        beq rrts
        sub.b #1,vols+1
        rts

; *******************************************************************
; pausoff
; *******************************************************************
pausoff:
        move camry,d0
        and #$fe,d0
        beq p_off
        cmp #$80,d0
        blt decit
        add #4,d0
decit:  sub #2,d0
        move d0,camry
        rts
p_off:  move.l pad_now,d0
        cmp #2,players
        beq mergem
        tst h2h
        beq nomergem
mergem: or.l pad_now+4,d0  
nomergem:
        and.l #pausebutton,d0
        bne rrts
        move.l paws,routine
        clr.l paws
        clr pawsed
        rts

; *******************************************************************
; gpu_run
; Unused code
; *******************************************************************
gpu_run_b:
        move.l dscreen,gpu_screen
        bra rgpu 

gpu_run:
        move.l gscreen,gpu_screen
rgpu:
        move.l #-1,gpu_sem  ;flag GPU running
        move.l #$f03000,d0  ;start address of GPU program
        move.l d0,G_PC  ;set GPU's PC
        move.l #$11,G_CTRL  ;fire up GPU  
still_running:
        tst.l gpu_sem
        bmi still_running  ;wait for GPU stop
        bsr WaitBlit    ;wait for Blitter stop
        move #1,screen_ready  ;tell int routine the screen is ready        ;for display
        rts 

; *******************************************************************
; gpu
; Unused code
; *******************************************************************
gpu:
        move.l dscreen,gpu_screen
        move.l #-1,gpu_sem  ;flag GPU running
        move.l #$f03000,d0  ;start address of GPU program
        move.l d0,G_PC  ;set GPU's PC
        move.l #$11,G_CTRL  ;fire up GPU  
        lea  G_CTRL,a0
still_r:
        move.l  (a0),d0    ;ataris way of stopping
        btst #0,d0
        bne  still_r
        bsr WaitBlit    ;wait for Blitter stop
        rts 



; *******************************************************************
; Initialize the Object List. We make it 12 items long. The main object
; is the first one, which is a full screen of pixel data generated by the
; GPU.
; *******************************************************************
InitBeasties:
        lea beasties,a0
        move #12,d7
        move d7,nbeasties
ibeasts:
        move #-1,12(a0)  ;inactive
        lea 64(a0),a0      ;room for other shit
        dbra d7,ibeasts
        rts

; *******************************************************************
; RunBeasties
; Create the Object List (aka Display List). This is used by the 
; Jaguar's Object Processor to write pixel data to the screen. It has
; a fixed length of 12 objects in the list (fixed by InitBeasties above).
; The main object is the first one (see ObTypes), which is a full screen
; of pixel data populated by the GPU.
; *******************************************************************
RunBeasties:
        move.l blist,a0    ;will use MakeScaledObject to build a list
        move.l dlist,a4
        tst warp_flash
        bne StopList
        lea beasties,a2
        move nbeasties,d7

RBeasts:move d7,-(a7)
        move 12(a2),d0  ; get mode
        bmi nxbeast
        lea ModeVex,a3
        asl #2,d0
        move.l 0(a3,d0.w),a3
        jsr (a3)    ;call action for that Mode
        move (a2),d0
        and #$fff,d0    ;limit to 12-bit
        move 4(a2),d1
        ; move frames,d3
        ; and #1,d3
        bclr #0,d1
        ; or d3,d1
        move 8(a2),d6
        move 10(a2),d3
        lsl #8,d3
        or d6,d3
        swap d3
        move 14(a2),d7    ;type
        lea ObTypes,a3
        asl #3,d7
        move 0(a3,d7.w),d3  ;get width in phrases
        move 2(a3,d7.w),d4  ;vertical height
        move 4(a3,d7.w),d5  ;depth
        move 6(a3,d7.w),d2  ;CLUT offset
        move.l 16(a2),a1  ;data pointer
        bsr MakeUnScaledObject
        move 20(a2),d0    ;post-creation stuff?
        bmi nxbeast
        lea postfixups,a3
        asl #2,d0
        move.l 0(a3,d0.w),a3
        jsr (a3)  ;do any fixup
nxbeast:
        move (a7)+,d7
        lea 64(a2),a2    ;do 'em all 
        dbra d7,RBeasts
        bra StopList    ;put a stopobject on the end  

postfixups:
        dc.l make_rmw,make_trans

make_rmw:
;
; set RMW on the sprite just defined
        lea -32(a0),a3    ;point to start of object
        bset.b #6,10(a3)  ;set the RMW flag
        rts

make_trans:
;
; make this sprite transparent
        lea -32(a0),a3
        bset.b #7,10(a3)
        rts

ModeVex: dc.l rrts

; *******************************************************************
; InitLists
;
; Align object list buffers and initialise them with some
; data, set one of them to be displayed
; *******************************************************************
InitLists:
        move.l #list1,d0
        and.l #$ffffffe0,d0  ;make sure it's quadphrase aligned

        move.l d0,a0
        move.l #0,(a0)+    ;The STOP Object for v pos out of range.
        move.l #4,(a0)+
        lea 24(a0),a0    ;Move to next object
        move.l a0,ddlist  ;Initial start point of list

        lsl.l #5,d0
        move n_vdb,d1
        move n_vde,d2  ;display start + end...
        lsl #3,d1
        lsl #3,d2    ;shift'em up
        or #3,d1
        or #3,d2    ;set branch-object bitz
        bset #14,d1    ;branch if beam < n_vdb
        bset #15,d2    ;branch if beam > n_vde
        

        swap d0      ;this is the address of the stopobject
        move #0,(a0)+
        move d0,(a0)+
        swap d0
        move d0,(a0)+
        move d1,(a0)+

        swap d0      ;this is the address of the stopobject
        move #0,(a0)+
        move d0,(a0)+
        swap d0
        move d0,(a0)+
        move d2,(a0)+

        move.l a0,dlist
        bsr StopList

        move.l #list2,d0  ;same for the other list
        and.l #$ffffffe0,d0  ;make sure it's quadphrase aligned
        move.l d0,blist
        move.l d0,a0
        bra StopList

StopList:
        move #15,d0
sl:     move.l #0,(a0)+
        move.l #4,(a0)+    ;make a stopobject
        dbra d0,sl
        rts

; *******************************************************************
; MakeScaledObject
;
; Make an OL entry for an object. a0 --> current pos in OL being built
; (assumes a0 is already phrase aligned)
;  d0-d1 = x,y
;  d2 = index into CLUT
;  d3 = X size, in phrases
;  d4 = Y size, in scan lines
;  d5 = Object depth
;  a1.l = address of data
;
; uses all d-regs, a0 must have OL position, a6 used internally
;
; Adding new stuff: d3 high word now=Yscale:Xscale
; *******************************************************************
MakeScaledObject:
        ; Now the funky bit. Build a scaled bitmapped object.
        ; We are now on a quadphrase boundary too.

        move.l a1,d6    ;get copy of data pointer
        and.l #$fffffff8,d6  ;lose three LSB's
        lsl.l #8,d6    ;move to correct bit position
        move.l d6,(a0)+    ;put it in the list

        ; The link address is the same as for the preceding conditional
        ; object, and remember i saved it in a1, so...

        lea 32(a0),a6
        move.l a6,d6    ;get back link-pointer
        lsl.l #5,d6    ;make it aligned OK (bott. 3 bits are 0)
        swap d6      ;get top word of the address..
        or d6,-2(a0)    ;and or it into place on the previous word.

        ; That's the first longword done, and the remaining byte of the
        ; link address is in d6 high already.

        move.l #0,d7    ;make d7 empty
        move d4,d7    ;get a copy of the height...
        ror.l #2,d7    ;put 2 lowest bits in hi word...
        swap d6      ;get back rest of link
        or d7,d6    ;OR in top 8-bits of height..
        move d6,(a0)+    ;top word now completed..
        swap d7      ;get 2 lowest bits of height at top of d7..
        move d1,d6    ;copy of Y pos..
        lsl #3,d6    ;align...
        or d7,d6    ;mask in those 2 bits of height..
        bset #0,d6    ;set the type=1
        move d6,(a0)+    ;..which completes the first phrase.

        ; Now on to the next phrase.

        clr (a0)+    ;assume Firstpix=0, RELEASE not asserted
        move d2,d7    ;get INDEX
        lsl #7,d7    ;align it
        move.l #0,d6    ;empty d6
        move d3,d6    ;get X size in phrases
        ror.l #4,d6    ;shift low 4 bits into hi word
        bset #15,d6    ;set transparency
        or d7,d6    ;mask in Index
        move d6,(a0)+    ;ignores Reflect, RMW

        ; First long of phrase 2 is done...

        move d3,d7    ;Assume dwidth=iwidth for simplicity
        lsl #2,d7    ;align
        swap d6      ;get top of d6, which has rest of iwidth
        or d7,d6    ;mask in dwidth  
        move d6,(a0)+    ;put it in, assume pitch is 1
        move d5,d6    ;get copy of depth
        ror #4,d6    ;put it in top byte
        or d0,d6    ;Hallelujah! X doesn't need shifting!
        bset #15,d6    ;(PITCH=1)
        move d6,(a0)+    ;Here endeth the Second Phrase.

        ; Now the third and final phrase.

        move.l #0,(a0)+    ;Not used.....
        move.l d3,d6
        clr.l d7
        swap d6      ;get x- and y-scale
        move d6,d7    ;copy scales
        lsr #8,d7
        swap d7
        move d6,d7    ;recombine remainder with d7
        move.l d7,(a0)+  
        lea 8(a0),a0

        ; Outta here.
        rts

; *******************************************************************
; MakeUnScaledObject
;
; Make an OL entry for an object. a0 --> current pos in OL being built
; (assumes a0 is already phrase aligned)
;  d0-d1 = x,y
;  d2 = index into CLUT
;  d3 = X size, in phrases
;  d4 = Y size, in scan lines
;  d5 = Object depth
;  a1.l = address of data
;
; uses all d-regs, a0 must have OL position, a6 used internally
;
; *******************************************************************
MakeUnScaledObject:
        move.l a0,d6
        and #$1f,d6    ;check for aligned
        beq muso
        move.l a0,d6
        and.l #$ffffe0,d6
        move.l d6,a0
        lea 32(a0),a0    ;make it aligned 

        ; Now the funky bit. Build an unscaled bitmapped object.
        ; We are now on a quadphrase boundary too.

muso:   move.l a1,d6    ;get copy of data pointer
        and.l #$fffffff8,d6  ;lose three LSB's
        lsl.l #8,d6    ;move to correct bit position
        move.l d6,(a0)+    ;put it in the list
        lea 32(a4),a6
        move.l a6,d6    ;get back link-pointer
        lsl.l #5,d6    ;make it aligned OK (bott. 3 bits are 0)
        swap d6      ;get top word of the address..
        or d6,-2(a0)    ;and or it into place on the previous word.

        ; That's the first longword done, and the remaining byte of the
        ; link address is in d6 high already.

        move.l #0,d7    ;make d7 empty
        move d4,d7    ;get a copy of the height...
        ror.l #2,d7    ;put 2 lowest bits in hi word...
        swap d6      ;get back rest of link
        and #$ff00,d6
        or d7,d6    ;OR in top 8-bits of height..
        move d6,(a0)+    ;top word now completed..
        swap d7      ;get 2 lowest bits of height at top of d7..
        move d1,d6    ;copy of Y pos..
        lsl #3,d6    ;align...
        or d7,d6    ;mask in those 2 bits of height..
        move d6,(a0)+    ;..which completes the first phrase.

        ; Now on to the next phrase.

        clr (a0)+    ;assume Firstpix=0, RELEASE not asserted
        move d2,d7    ;get INDEX
        lsl #7,d7    ;align it
        move.l #0,d6    ;empty d6
        move d3,d6    ;get X size in phrases
        ror.l #4,d6    ;shift low 4 bits into hi word
        bclr #15,d6    ;unset transparency
        or d7,d6    ;mask in Index
        move d6,(a0)+    ;ignores Reflect, RMW

        ; First long of phrase 2 is done...

        move d3,d7    ;Assume dwidth=iwidth for simplicity
        lsl #2,d7    ;align
        swap d6      ;get top of d6, which has rest of iwidth
        or d7,d6    ;mask in dwidth  
        move d6,(a0)+    ;put it in, assume pitch is 1
        move d5,d6    ;get copy of depth
        ror #4,d6    ;put it in top byte
        or d0,d6    ;Hallelujah! X doesn't need shifting!
        bset #15,d6    ;(PITCH=1)
        move d6,(a0)+    ;Here endeth the Second Phrase.
        lea 16(a0),a0    ;not economical but if all objects are 32 bytes it makes life easier
        lea 32(a4),a4    ;where the list is really going to
        ; Outta here.

        rts


; *******************************************************************
; BlitBlock
;
; use the Blitter to draw a block, origin d0/d1, size d2/d3, colour d4,
; on the 384-pixel wide bitmap addressed at a0.
; *******************************************************************
BlitBlock:
        move.l #PITCH1|PIXEL16|WID384|XADDINC,d7
        move.l d7,A1_FLAGS
        move.l a0,d7
        move.l d7,A1_BASE  ;base of dest screen
        move d1,d7
        swap d7
        move d0,d7    ;X and Y destination start
        move.l d7,A1_PIXEL
        move.l #0,A1_FPIXEL
        move.l #$1,d7
        move.l d7,A1_INC
        move.l #0,A1_FINC  ;No fractional parts of increment
        move #1,d7    ;X and Y Step
        swap d7
        move d2,d7
        neg d7
        move.l d7,A1_STEP
        move.l #0,A1_FSTEP  ;no fraction of step
        move d3,d7
        swap d7
        move d2,d7    ;Inner and outer loop count
        move.l d7,B_COUNT
        move d4,d7    ;get colour
        swap d7
        move d4,d7    ;duplicate
        move.l d7,B_PATD
        move.l d7,B_PATD+4  ;fill up phrase wide pattern register
        move.l #PATDSEL|UPDA1,d7
        move.l d7,B_CMD  ;do the thang

WaitBlit:
        move.l B_CMD,d7  ;get Blitter status regs
        btst #0,d7
        beq WaitBlit    ;wait until outer loop is idle
rrts:   rts

; *******************************************************************
; fxBlock
;
; use the Blitter to draw a block, origin d0/d1, size d2/d3, colour d4,
; on the 384-pixel wide bitmap addressed at a0.
; *******************************************************************
fxBlock:
        move.l #PITCH1|PIXEL16|WID384|XADDINC,d7
        move.l d7,A1_FLAGS
        move.l a0,d7
        move.l d7,A1_BASE  ;base of dest screen
        move d1,d7
        swap d7
        move d0,d7    ;X and Y destination start
        move.l d7,A1_PIXEL
        move.l #0,A1_FPIXEL
        move.l #$1,d7
        move.l d7,A1_INC
        move.l #0,A1_FINC  ;No fractional parts of increment
        move #1,d7    ;X and Y Step
        swap d7
        move d2,d7
        neg d7
        move.l d7,A1_STEP
        move.l #0,A1_FSTEP  ;no fraction of step
        move d3,d7
        swap d7
        move d2,d7    ;Inner and outer loop count
        move.l d7,B_COUNT
        move d4,d7    ;get colour
        swap d7
        move d4,d7    ;duplicate
        move.l d7,B_PATD
        move.l d7,B_PATD+4  ;fill up phrase wide pattern register
        move.l #PATDSEL|UPDA1,d7
        move.l d7,B_CMD  ;do the thang
        bra WaitBlit

; *******************************************************************
; ecopy
; *******************************************************************
ecopy:  move.l #PITCH1|PIXEL16|WID384|XADDINC,d7
        bra eec

; *******************************************************************
; CopyBlock
;
; Copy from screen at a0 to screen at a1
; d0/d1=origin of sourceblock
; d2/d3=width and height of block to copy
; copy from blitter a1 to a2.
; d4/d5=destination XY
;
; This simple routine will assume both screens are the same width
;
; Using this blitter is a piece of piss.
; *******************************************************************
CopyBlock:
        move.l #PITCH1|PIXEL16|WID320|XADDINC,d7
eec:    move.l d7,A1_FLAGS  ;a1 (Source) Gubbins

        move.l #PITCH1|PIXEL16|WID384|XADDPIX|YADD1,d7
        move.l d7,A2_FLAGS  ;a2 (Dest) Gubbins

        move d3,d7
        swap d7
        move d2,d7
        move.l d7,B_COUNT   ;set inner and outer loop counts

        move d1,d7
        swap d7
        move d0,d7
        move.l d7,A1_PIXEL  ;origin of source

        move d5,d7
        swap d7
        move d4,d7
        move.l d7,A2_PIXEL  ;origin of destination

        move.l #0,A1_FPIXEL


        move.l #$0001,A1_INC
        move.l #$0,A1_FINC

        move #1,d7
        swap d7
        move d2,d7
        neg d7
        move.l d7,A1_STEP
        move.l d7,A2_STEP    ;set loop steps

        move.l a0,d7
        move.l d7,A1_BASE
        move.l a1,d7
        move.l d7,A2_BASE    ;set screen window bases

        move.l #SRCEN|UPDA1|UPDA2|DSTA2|LFU_A|LFU_AN,d7
        move.l d7,B_CMD
        bra WaitBlit

; *******************************************************************
; MergeBlock
; *******************************************************************
MergeBlock:
        move.l #0,B_PATD
        move.l #0,B_PATD+4    ;set transparency colour

        move.l #PITCH1|PIXEL16|WID384|XADDINC,d7
        move.l d7,A1_FLAGS  ;a1 (Source) Gubbins

        move.l #PITCH1|PIXEL16|WID384|XADDPIX|YADD1,d7
        move.l d7,A2_FLAGS  ;a2 (Dest) Gubbins

        move d3,d7
        swap d7
        move d2,d7
        move.l d7,B_COUNT   ;set inner and outer loop counts

        move d1,d7
        swap d7
        move d0,d7
        move.l d7,A1_PIXEL  ;origin of source

        move d5,d7
        swap d7
        move d4,d7
        move.l d7,A2_PIXEL  ;origin of destination

        move.l #0,A1_FPIXEL


        move.l #$0001,A1_INC
        move.l #$0,A1_FINC

        move #1,d7
        swap d7
        move d2,d7
        neg d7
        move.l d7,A1_STEP
        move.l d7,A2_STEP    ;set loop steps

        move.l a0,d7
        move.l d7,A1_BASE
        move.l a1,d7
        move.l d7,A2_BASE    ;set screen window bases

        move.l #SRCEN|UPDA1|UPDA2|DSTA2|LFU_A|LFU_AN|DCOMPEN,d7
        move.l d7,B_CMD
        bra WaitBlit

; *******************************************************************
; make_vo2d
; make a 2d vector object at a0, using the vertex list at (a1)
;
; d0.l=x scale, d1.l=y scale, d2.l=x centre, d3.l=y centre, d4=angle
; *******************************************************************
make_vo2d:

        move.l a0,a2
        move.l d0,(a0)+
        move.l d1,(a0)+    ;x and y scale to header
        lea 8(a0),a0    ;skip extent values
        move.l d2,(a0)+
        move.l d3,(a0)+    ;put in x and y centre
        move d4,(a0)    ;angle
        clr d5
        clr d6      ;use to do extent

        lea 32(a2),a0    ;start of vector info
gv:     move.b (a1)+,d0
        bmi gv_end
        move.b (a1)+,d1
        cmp d0,d5    ;check and set extent if necessary
        bge gv1
        move d0,d5
gv1:    cmp d1,d6
        bge gv2
        move d1,d6
gv2:    move.b (a1)+,d2    ;get 1 vertex
        and.l #$ff,d0    ;co-ordinates are 0-255
        and.l #$ff,d1
        swap d0
        swap d1
        move.l d0,(a0)+    ;already in right order for reasding as 16:16
        move.l d1,(a0)+
        ext d2
        ext.l d2
        move.l d2,(a0)+    ;vertexinfo  
        bra gv

gv_end: move.l #-1,(a0)+
        move.l d5,8(a2)
        move.l d6,12(a2)  ;put in extent
        rts

; *******************************************************************
; make_vo3d
;
; make a 3d vector object at a0, using the short data at (a1)
;
; d0.l=x scale, d1.l=y scale, d2.l=z scale, d3.l=x centre, d4.l=y centre, d5.l=z centre, d6=angle (xy)/angle (xz), d7=angle (yz)
;
; makes a 48-byte header which is copied to GPU local RAM when the object is drawn (I guess the techies would call it an instance)
; *******************************************************************
make_vo3d:
        move.l vadd,a0
        move.l a0,-(a7)
        bsr initvo
        move #$0,d4      ;use this for colour-info
buildit:move #2,d2    ;loop for three items..
b3d1:   move.b (a1)+,d0  ;X
        beq builtit    ;zero means last vertex
        and.l #$ff,d0
        move.l d0,(a2)+    ;put it in the vertex list
        dbra d2,b3d1    ;get x,y and z

        move.b (a1),d0    ;test for zero connections from this point
        bne dcnc
        lea 1(a1),a1
        bra nxtvrt

dcnc:   move d3,(a3)+    ;vertex # to connect list
cnect:  move.b (a1)+,d0    ;get connected vertex #
        bpl stdvrt
        move.b (a1)+,d4
        lsl #8,d4    ;set nu colour
        move.b (a1)+,d0

stdvrt: and #$ff,d0
        beq zv
        or d4,d0
zv:     move d0,(a3)+
        bne cnect    ;loop until a zero

nxtvrt: addq #1,d3    ;next vertex number
        bra buildit    ;go do next vertex

builtit:move.l #0,(a3)+
        and.l #$ffff,d3
        move.l d3,(a0)+    ;pass # of vertices in header
        move.l a3,connect_ptr
        move.l a2,vertex_ptr
        move.l a0,vadd
        move.l (a7)+,a0
        rts

; *******************************************************************
; initvo
; Initialize a standard vector object
; *******************************************************************
initvo: move.l a0,a2
        move.l d0,(a0)+    ;x
        move.l d1,(a0)+    ;y
        move.l d2,(a0)+    ;z scales;
        move.l d3,(a0)+    ;x
        move.l d4,(a0)+    ;y
        move.l d5,(a0)+    ;z centres;

        move.l d6,d0
        and.l #$ffff0000,d0
        swap d0
        move.l d0,(a0)+    ;angle XZ
        and.l #$ffff,d6
        move.l d6,(a0)+    ;angle XZ
        and.l #$ffff,d7
        move.l d7,(a0)+    ;angle YZ

        move.l vertex_ptr,d0
        move.l connect_ptr,a3  ;point to vertex and connection list space
        addq.l #4,d0
        and.l #$fffffffc,d0  ;longalign vertex base
        move.l d0,a2
        move.l d0,(a0)+    ;vertex pointer to header
        move.l a3,d0
        move.l d0,(a0)+    ;connect pointer to header
        move #1,d3      ;vertex number
        rts

; *******************************************************************
; extrude
; This routine reads in the web data structure for a given web.
;
; extrude a web from a list of 16 pairs of XY coordinates addressed by (a1)
;
; a0 = vector ram space; a2.l = z depth to extrude to; d0-d7 as above
; *******************************************************************
extrude:move.l vadd,a0
        movem.l d0-d7/a0/a2,-(a7)    ;save so routine can return address
        clr connect
        move.l a2,-(a7)    ;save z depth
        bsr initvo    ;make header, do standard vector object init
        move.l a3,a4    ;save first vertex
        move.l (a7)+,d7    ;retrieve z-depth
        move d7,d0
        asr #1,d0
        move d0,web_z    ;Current Web z centering
        clr.l d0
        clr.l d1
        clr d5           ;to catch highest X point
        move (a1)+,d6            ; First byte from raw_web: # channels to a web
        move d6,web_max
        move (a1)+,web_firstseg  ; Second byte: player's starting position on web?
        move.l a1,web_ptab       ; Third byte: start of x/y pairs, the position table
        move.l a3,(a5)+    ;first vertex to lanes list

        ; Read in the x/y pairs
        ; Get the current x and y pair
xweb:   move (a1)+,d0
        move (a1)+,d1    ;get X and Y
        ext.l d0
        ext.l d1
        cmp d5,d1     ; Check if this is the large X value so far
        blt xweb2     ; As above.
        move d1,d5    ; It's bigger, so save it in d5.
        ; Store the x,y,z value for the near point in the web
xweb2:  move.l d0,(a2)+ ; x value
        move.l d1,(a2)+ ; y value
        clr.l (a2)+     ; z value for near point (always 0)

        ; Store the x,y,z value for the far point in the web
        move.l d0,(a2)+ ; x value
        move.l d1,(a2)+ ; y value
        move.l d7,(a2)+ ; z value for far point (calculated by initvo).

        move d3,(a3)+    ;vertex ID to conn list
        tst d6
        beq lastpoint    ;special case for last point!

        ; Connect the vertices
        move d3,d4       ;copy vertex #
        addq #1,d4
        move d4,(a3)+    ;connect to n+1
        addq #1,d4
        move d4,(a3)+    ;connect to n+2
        move #0,(a3)+    ;end vertex 
        subq #1,d4       ;point to n+1
        move d4,(a3)+
        addq #2,d4       ;n+3
        move d4,(a3)+    ;connect
        move #0,(a3)+    ;delimit
        move.l a3,(a5)+  ;to v.conn list
        add #2,d3        ;move 2 vertices

        ; Get the next pair
        dbra d6,xweb

lastpoint:
        addq #1,d3
        move d3,(a3)+    ;connect to n+1
        move 4(a1),connect
        tst connect
        beq nconn1    ;connect to vertex 1 if required
        add #1,web_max
        move #1,(a3)+
        move #0,(a3)+
        move d3,(a3)+
        move #2,(a3)+
nconn1: move.l #0,(a3)+
        and.l #$ffff,d3
        move.l d3,(a0)+    ;pass # of vertices in header
        lea 6(a1),a1
        move.l a1,web_otab
        move.l a3,connect_ptr
        move.l a2,vertex_ptr
        move.l a0,vadd
        move.l a4,(a5)+    ;repeat first vertex addr.
        asr #1,d5
        add #1,d5
        move #8,web_x
        movem.l (a7)+,d0-d7/a0/a2  ;return with stuff intact and handle in a0
        move web_x,d5
        and.l #$ffff,d5
        move.l d5,12(a0)  ;set x centre
        move web_z,d5
        move.l d5,20(a0)  ;set z centre
        rts
        
; *******************************************************************
; make_fw
; Make a firework object
; *******************************************************************
make_fw:
        tst afree
        bmi rrts
        move.l freeobjects,a0
        move.l fw_x,4(a0)
        move.l fw_y,8(a0)
        move.l fw_z,12(a0)
        move.l fw_dx,16(a0)
        move.l fw_dy,20(a0)
        move.l fw_dz,24(a0)
        move.l #$100,28(a0)
        move fw_dur,32(a0)
        move #14,34(a0)
        move #0,36(a0)
        move #1,38(a0)
        move fw_col,40(a0)
        clr.l 50(a0)
        move #29,54(a0)
        sub #1,afree
        jmp insertobject
        
; *******************************************************************
; draw_fw
; Draw a firework object
; *******************************************************************
draw_fw:
        tst 32(a6)
        bmi fw_ex    ;Duration gone, go draw Explosion
        lea in_buf,a0
        move.l 4(a6),(a0)
        move.l 8(a6),4(a0)
        move.l 12(a6),8(a0)
        move 40(a6),d0
        and.l #$ff,d0
        move.l d0,12(a0)
        move.l #5,gpu_mode
        lea xparrot,a0
        jsr gpurun    ;do pixel in 3d
        jmp gpuwait   ; returns

fw_ex:  lea in_buf,a0
        move.l 4(a6),(a0)
        move.l 8(a6),4(a0)
        move.l 12(a6),8(a0)
        move 36(a6),d0
        and.l #$ff,d0
        asl.l #2,d0
        move.l d0,12(a0)  ;rad
        move.l #0,16(a0)  ;phase 1
        move.l #0,20(a0)  ;phase 2
        move fw_sphere,d3
        subq #1,d3
        lsl #4,d3
        lea sphertypes,a1
        lea 0(a1,d3.w),a1
        move.l (a1)+,24(a0)  ;rings/sphere
        move.l (a1)+,28(a0)  ;pixels/ring
        move.l (a1)+,32(a0)  ;pixel spacing
        move.l (a1)+,36(a0)  ;twist per ring
        move 40(a6),d1
        and.l #$ff,d1
        move.l d1,40(a0)  ;colour
        neg.l d0
        add.l #$ff,d0    ;calculate i decreasing
        move.l d0,44(a0)
        move.l #4,gpu_mode
        lea bovine,a0
        jsr gpurun      ;do clear screen
        jmp gpuwait

; *******************************************************************
; run_fw
; Updat the state of the firework object
; *******************************************************************
run_fw: tst 32(a6)
        bmi xpired
        move.l 16(a6),d0
        add.l d0,4(A6)
        move.l 20(a6),d0
        add.l d0,8(a6)
        move.l 24(a6),d0
        add.l d0,12(A6)
        move.l 28(a6),d0
        add.l d0,20(a6)    ;gravity
        sub #1,32(a6)
        rts
xpired:
        move 38(a6),d0
        add d0,36(a6)
        cmp #63,36(a6)
        blt rrts
        move #1,50(A6)
        rts

; *******************************************************************
; iv
;
; init vertex and connect pointers
; *******************************************************************
iv:     move.l #vertex_ram+4,d0
        and.l #$fffffffc,d0
        move.l d0,vertex_ptr
        move.l #connect_ram,connect_ptr
        move.l #tv,d0      ;word align vector header ram base
        addq.l #4,d0
        and.l #$fffffffc,d0
        move.l d0,vadd
        rts

; *******************************************************************
; run_vex
; Routines for updating the state of all objects.
; *******************************************************************
run_vex:
        dc.l rrts,player_shot,run_flipper,run_zap,kill_shot,run_tanker,run_spike,run_spiker,run_ashot,run_fuseball,blowaway  ;10
        dc.l run_pulsar,oblow,go_downc,go_downf,claw_con2,claw_con1,rez_claw,czoom1,czoom2,pzap,rundroid  ;21
        dc.l run_pixex,run_pspark,run_prex,run_pup,xshot,run_gate,xr_pixex,run_fw,run_h2hclaw,run_mirr,run_h2hshot,run_h2hgen  ;33
        dc.l run_h2hball,oblow2,rumirr,refsht,refsht2,run_adroid,loiter


; *******************************************************************
; run_objects
; Update the state of all the objects in the game, i.e. everything in
; the activeobjects list and more besides. 
;
; run the 'objects' in the demo
; *******************************************************************
run_objects:
        move #1,diag
        sub.b #1,pudel    ;do Pulsar pulses
        bpl zzonk
        move.b pudel+1,pudel
        add #1,pucnt  
        and #$0f,pucnt
        beq clzd
zzonk:
        cmp #7,pucnt
        bne zonk
        tst zapdone
        bmi zonk
        beq zonk
        move #-1,zapdone
        bra zonk
clzd:   clr zapdone
zonk:   move #2,diag
        move #0,d7    ;use to check for wave_end
        move.l #500,d6    ;use to find the nearest enemy, for the Droid's brain
        move.l activeobjects,a6
        clr _sz
        tst szap_on
        beq r_obj    ;check for superzap requested
        move frames,d0
        and #3,d0
        bne r_obj
        move #1,_sz    ;Kill something please...  
r_obj:  cmpa.l #-1,a6
        beq r_end
        tst 50(a6)
        bmi r_end1    ;>>>>> KLUDGE to prevent a garbled list being traversed

doitthen:
        lea run_vex,a0
        move 34(a6),d0    ;Collapsed to a pixel?
        bpl notcolap
        sub #2,12(a6)
        clr d0
        cmp #webz+80,12(a6)  ;advance to edge of Web...
        bgt r_o1    ;no official action, we already did it
        cmp #11,54(a6)
        bne setxx
        move pucnt,d1
        and #$0f,d1
        cmp #3,d1    ;Make sure that a pulsar is not created in a dangerous phase
        blt setxx
        add #2,12(a6)
        bra r_o1    ;Makes pulsars wait until innocent before touchdown

setxx:  neg 34(a6)    ;make it real now  

notcolap:
        move 54(a6),d0
        bpl r_o1    ;-ve treated as no action
        clr d0
r_o1:   asl #2,d0
        move.l 60(a6),-(a7)  ;save address of current Next in case this object is unlinked
        move.l 0(a0,d0.w),a0
        tst 52(a6)    ;'Enemy' flag
        beq zokk    ;(don't count player bulls)
        bmi zokk    ;(or claw VULNERABLE flags)
        cmp 12(a6),d6    ; check against previous nearest
        blt gokk
        swap d6
        move 16(a6),d6    ;get nearest one's Lane #
        swap d6
        move 12(a6),d6    ;make this z nearest  
gokk:   cmp 12(a6),d7
        bgt zokk
        move 12(a6),d7
zokk:   movem.l d6-d7,-(a7)
        move #3,diag
        move.l a0,diag+4
        move.l a6,diag+8
        tst locked    ;>>>>> A nasty hack.
        bne hack
        jsr (a0)    ;call motion vector
hack:   movem.l (a7)+,d6-d7    ;retrieve furthest-z
        move.l (a7)+,a6    ;Next
        move #4,diag
        move.l a6,diag+12
        bra r_obj
r_end:  move.l d6,droid_data
        move #5,diag
        tst wave_tim    ;has E been done?
        bpl r_end1    ;Nope
        cmp #-2,wave_tim  ;total end
        beq rrts
        cmp #webz-80,d7    ;furthest NME at top?
        bgt r_end1
szoom:  move #-2,wave_tim

        tst dnt
        bpl skagi
        clr dnt
skagi:  clr szap_on
        bsr clzapa
zagga:  move.l #zoom1,routine    ;fly off the web
        clr l_soltarg
        move #18,d0
        bsr sclawt      ;any claws to Zoom Mode
        lea _web,a0
        clr.l 20(a0)      ;zoom velocity
        clr.l 24(a0)
        move.l #10,zoopitch
        bsr zoomon
banana: cmp #3,cwave
        blt rrts
        cmp #15,cwave
        bgt rrts
        tst outah
        bne rrts
        lea wmes1,a0
        clr.l d0
        move.l #$8000,d1
        bsr setmsg
        move #250,msgtim1
        rts

yeson:  move #23,sfx
        move #101,sfx_pri
        jsr fox
        move handl,handl1
        move #101,sfx_pri
        jsr fox
        move handl,handl2
        rts

; *******************************************************************
; zoomon
; *******************************************************************
zoomon: move #0,sfx
        move #100,sfx_pri
        move.l zoopitch,d0
        move.l d0,sfx_pitch
        move.b vols+1,d1
        and #$ff,d1
        move d1,vvol1
        move d1,vvol2
        jsr fox
        move handl,handl1
        move #2,sfx
        move #100,sfx_pri
        lsl.l #1,d0
        move.l d0,sfx_pitch
        jsr fox
        move handl,handl2    ;start off looped engine noise
        move #1,wson
        rts

r_end1: tst _sz      ;did we Zap something?
        beq rrts    ;No
        bmi someone_fried  ;Yes
        clr szap_on    ;Superzap done
        bra clzapa
someone_fried:
        tst szap_avail  ;Was that a second, desperate Zap?
        bpl rrts    ;No
clzapa: clr szap_on    ;Yeah, he zaps 1 alien is all
        clr bolt_lock
        clr inf_zap
        move #1,wave_speed
        rts


; *******************************************************************
; rob
; *******************************************************************
rob:    move.l activeobjects,a6
r_ob:   cmpa.l #-1,a6
        beq rob_end
        tst 50(a6)
        bmi rob_end    ;>>>>> KLUDGE to prevent a garbled list being traversed
        lea run_vex,a0

        move 54(a6),d0
        bpl r_ob1    ;-ve treated as no action
        clr d0
r_ob1:  asl #2,d0
        move.l 60(a6),-(a7)  ;save address of current Next in case this object is unlinked
        move.l 0(a0,d0.w),a0
        jsr (a0)    ;call motion vector
        move.l (a7)+,a6
        bra r_ob
rob_end:rts
r_nxt:  move.l 56(a6),a6
        bra r_ob

        ; Our first pass through the activeobjects list.
dob:    move.l activeobjects,a6
d_ob:   cmpa.l #-1,a6
        beq dobend
        move 50(a6),d0    ;'Unlink Me Please'
        beq no_dunlink
        
        move.l 56(a6),d1
        bmi dtlink
        move.l d1,a5
        move.l 60(a6),60(a5)  ;if interrupted, unlinking object is invisible to int routine now

dtlink: move #-1,50(a6)    ;mark it bad
        move.l 60(a6),-(a7)
        move d0,-(a7)
        move.l a6,a0
        move 32(a6),-(a7)  ;save player ownership tag
        move (a7)+,d1
        move (a7)+,d0
        bsr dafinc
        bra nxtdob
no_dunlink:
        lea draw_vex,a0
        move 34(a6),d0    ;-ve it is collapsed to a pixel!
        asl #2,d0
        move.l 0(a0,d0.w),a0
        move.l 60(a6),-(a7)    ;go to next object
        jsr (a0)    ;execute chosen draw type
        jsr gpuwait
nxtdob: move.l (a7)+,a6    ;this way i can even trash a6 if i need II
        bra d_ob    ;finish off and terminate the ud-list

dobend: bsr showscore
        tst blanka
        beq dodvec
        bsr drawpolyos    ;draw pri-list full of poly objects
dodvec: bra drawmsg    ;draw Messager thang if needed

dafinc: add #1,afree
        move #1,locked
        bsr unlinkobject  
        clr locked
        rts

donki:  bsr showscore
        bra drawmsg

; *******************************************************************
; draw_vex
; A list of routines used for drawing vector object. The activeobjects
; list contains an index into this list so the specific draw routine
; for each object can be invoked.
; *******************************************************************
draw_vex:
        dc.l rrts,draw,draw_z,draw_vxc,draw_spike,draw_pixex,draw_mpixex,draw_oneup,draw_pel,changex  ;9
        dc.l draw_pring,draw_prex,dxshot,drawsphere,draw_fw,dmpix,dsclaw,dsclaw2



; *******************************************************************
; Draw Objects
; This is called from the mainloop and is responsible for doing
; nearly all the GPU/Blitter operations for each frame. 
; *******************************************************************
draw_objects:
        tst h2h                 ; Are we in head to head mode?
        bne nodraw              ; Yes, go to 'nodraw'.
        clr h2hor
stayhalt:
        tst drawhalt            ; 
        bsr clearscreen
        move.b sysflags,d0
        and.l #$ff,d0
        move.l d0,_sysflags     ;pass sys flags to GPU
        tst sf_on               ; Is the starfield active?
        bne dostarf             ; If yes, go to 'dostarf'.
        bra gwb                 ; Otherwise do the web.

        ; Prepare the starfield!
dostarf: move.l #3,gpu_mode      ; mode 3 is starfield1
        move.l vp_x,in_buf+4    ; Put x pos in the in_buf buffer.
        move.l vp_y,in_buf+8    ; Put y pos in the buffer.
        move.l vp_z,d0          ; Get the current z pos.
        add.l vp_sf,d0          ; Increment it. 
        move.l d0,in_buf+12     ; Add it to the buffer.
        move.l #field1,d0       ; Get the starfield data structure.
        move.l d0,in_buf+16     ; And put it in the buffer.
        move.l warp_count,in_buf+20 ; Add the warp count.
        move.l warp_add,in_buf+24   ; Add the warp increment.
        lea fastvector,a0       ; Get the GPU routine to use.
        jsr gpurun              ; do gpu routine
        jsr gpuwait             ; Wait until its finished.

gwb:    move.l vp_x,d3
        move.l vp_y,d4
        move.l vp_z,d5

solweb: move #120,d0
        add palfix2,d0
        and.l #$ff,d0
        move.l d0,ycent
        tst l_solidweb
        beq vweb
        cmp #1,webcol    ;our 'transparent' webs...
        beq vweb
        lea _web,a6    ;draw a solid poly Web
        tst 34(a6)
        beq n_wb
        lea in_buf,a0
        move.l 46(a6),d0
        move.l d0,(a0)
        move.l 4(a6),d0
        sub.l d3,d0
        move.l d0,4(a0)
        move.l 8(a6),d0
        sub.l d4,d0
        move.l d0,8(a0)
        move.l 12(a6),d0
        sub.l d5,d0
        bmi n_wb
        move.l d0,12(a0)
        move l_solidweb,d0
        and.l #$ff,d0
        move.l d0,16(a0)
        move 28(a6),d0
        and.l #$ff,d0
        move.l d0,24(a0)
        move frames,d0
        and.l #$ff,d0
        move.l d0,28(a0)
        move.l #w16col,32(a0)
        move.l #0,gpu_mode
        lea equine2,a0
        jsr gpurun
        jsr gpuwait
        jsr WaitBlit

vweb:   tst t2k
        beq gvweb
        cmp #1,webcol
        bne gvweb
        add #1,wpt    ;..are actually psychedelic vectors...
        bsr swebpsych

gvweb:  move.l #2,gpu_mode  ;Mode 2 is do-the-vectors-in-3d-thang
        lea _web,a6
        tst 34(a6)
        beq n_wb
        bsr drawweb    ;draw th' Web
n_wb:   move.l activeobjects,a6
        bsr d_obj
        bra odend

        ; A loop for processing everything in 'activeobjects'.
d_obj:  cmpa.l #-1,a6      ; Have we reached the end of activeobjects? 
        beq oooend         ; If yes, skip to end.
        move 50(a6),d0     ; Is the object marked for deletion? 
        beq no_unlink      ; If not, skip to no_unlink and draw it.

        ; This verbose section up until no_unlink is concerned entirely 
        ; with deleting the dead object from the activeobjects list.
        move.l 56(a6),d1     ; Get address of previous object. 
        bmi tlink            ;  
        move.l d1,a5         ; Move previous object to a5.
        move.l 60(a6),60(a5) ; Make it invisible to the vsync interrupt.

tlink:  move #-1,50(a6)      ; mark it bad
        move.l 60(a6),-(a7)  ; Stash the next object address
        move d0,-(a7)
        move.l a6,a0
        move 32(a6),-(a7)   ;save player ownership tag
        move (a7)+,d1
        move (a7)+,d0
        lea uls,a1
        asl #2,d0
        move.l -4(a1,d0.w),a1 ; 
        jmp (a1)

        ; Object specific unlinking/deletion routines
uls:    dc.l afinc,ashinc,pshinc

pshinc: tst d1    ;player ownership of an unlinked bullet
        beq ulsh1
        add #1,shots+2
ulo:    move #1,locked
        bsr unlinkobject  
        clr locked
        bra nxt_o             ; Finished deleting, go the the next object.
ulsh1:  add #1,shots
        bra ulo

ashinc: add #1,ashots
afinc:  add #1,afree
        bra ulo

        ; Actually draw the object.
        ; No need to remove the object, just draw it.
no_unlink:      
        lea draw_vex,a0      ; Get our table of draw routines.
        move 34(a6),d0       ; Is this object smaller than a pixel?
        bpl notpxl           ; If not, go to notpxl.
        move.l #draw_pel,a0  ; Use draw_pex for pixel-size objects.
        bra apal             ; Jump to the draw call. 
notpxl: asl #2,d0            ; Multiply the val in d0 by 2.
        move.l 0(a0,d0.w),a0 ; Use it as an index into draw_vex.
apal:   move.l 60(a6),-(a7)  ; Store the index of next object in a7. 
        jsr (a0)             ; But first call the routine in draw_vex.
        jsr gpuwait          ; Wait for the GPU to finish.
nxt_o:  clr locked           ; Clear 'locked' just in case.
nxt_ob: move.l (a7)+,a6      ; Put the index of next object back in a6.
        bra d_obj            ; Go to the next object.
oooend: rts


        ; We've finished our first pass of activeobjects.
odend:  bsr showscore     ; Show the score.
        ; In Tempest Classic mode we don't need solid polygons.
        tst blanka        ; Are we doing solid polygons?
        beq odvec         ; If not, skip.
        bsr drawpolyos    ; if we are, draw them.
odvec:  bsr drawmsg       ; Draw 'Superzapper Recharge' or other message, if applicable.
        
        tst auto      ; Check if we're in demo-mode.
        beq namsg     ; If we're not, skip.
        cmp.l #vecoptdraw,demo_routine ; Check if drawing is active in demo mode.
        beq namsg     ; If not, skip.

        ; Draw the demo text.
        lea bfont,a1    ; Load font
        lea autom1,a0   ; "Demo" string 
        move #50,d0     ; Set y position
        jsr centext     ; Display text in center
        lea cfont,a1    ; Load font
        lea autom2,a0   ; "Press Fire to Play" 
        move #180,d0    ; Set y position
        tst pal         ; PAL?
        beq dunfirst    ; No, skip next line.
        add palfix2,d0  ; Adjust for PAL
dunfirst:
        jsr centext    ; Draw the text in the centre.

namsg:  tst blanka
        beq xox1    ;no bolts on ordinary T
        tst bolt_lock
        beq xox1    ;only draw bolt if Bolt Lock is set

        jsr WaitBlit
        move.l _claw,a6
        tst p2smarted
        beq gp1smart
        move.l 56(a6),a6  ;make bolts out of p2's ship for 2pl mode
gp1smart:
        cmpa.l #-1,a6
        beq xox1
        bsr webinfo
        swap d0
        swap d1
        swap d2
        swap d3
        movem.l d0-d1,-(a7)

        move.l #192,xcent
        move.l #120,d6
        add palfix2,d6
        move.l d6,ycent

        move.l #0,gpu_mode
        lea in_buf,a0      ;set up func/linedraw
        move.l boltx,d0
        sub.l vp_x,d0
        move.l d0,(a0)+
        move.l bolty,d0
        sub.l vp_y,d0
        move.l d0,(a0)+
        move.l boltz,d0
        sub.l vp_z,d0
        move.l d0,(a0)+  ;XYZ source
        sub.l vp_x,d2
        move.l d2,(a0)+
        sub.l vp_y,d3
        move.l d3,(a0)+
        move.l 12(a6),d0
        sub.l vp_z,d0
        move.l d0,(a0)+  ;XYZ dest
        move flashcol,d0
        and.l #$ff,d0
        move.l d0,(a0)+  ;colour
        move.l #32,(a0)+  ;# segs
        move frames,d0
        and.l #$ff,d0
        or #$01,d0
        move.l d0,(a0)+
        move.l #bovine,a0
        jsr gpurun    ;do it
        jsr gpuwait

        movem.l (a7)+,d2-d3
        
        lea in_buf,a0      ;set up func/linedraw
        move.l boltx,d0
        sub.l vp_x,d0
        move.l d0,(a0)+
        move.l bolty,d0
        sub.l vp_y,d0
        move.l d0,(a0)+
        move.l boltz,d0
        sub.l vp_z,d0
        move.l d0,(a0)+  ;XYZ source
        sub.l vp_x,d2
        move.l d2,(a0)+
        sub.l vp_y,d3
        move.l d3,(a0)+
        move.l 12(a6),d0
        sub.l vp_z,d0
        move.l d0,(a0)+  ;XYZ dest
        move flashcol,d0
        and.l #$ff,d0
        move.l d0,(a0)+  ;colour
        move.l #32,(a0)+  ;# segs
        move frames,d0
        and.l #$ff,d0
        or #$01,d0
        move.l d0,(a0)+
        move.l #bovine,a0
        jsr gpurun    ;do it
        jsr gpuwait

xox1:   tst evon
        beq nevon

nevon:  rts

; *******************************************************************
; nodraw
; Drawing, but for head to head mode.
; *******************************************************************
nodraw: bsr clearscreen

        ; Draw the starfield.
        move.b sysflags,d0   ; Get the sysflags
        and.l #$ff,d0        ; Just the first byte.
        move.l d0,_sysflags  ; pass sys flags to GPU
        move.l #3,gpu_mode   ; mode 3 is starfield1
        move.l vp_x,in_buf+4 ; Put the camera x pos in the gpu buffer.
        move.l vp_y,in_buf+8 ; Put the camera y pos in the gpu buffer.
        move.l vp_z,d0       ; Get the camera z viewpoint
        add.l vp_sf,d0       ; Add the starfield offset.
        move.l d0,in_buf+12  ; Put the z pos in the gpu buffer.
        move.l #field1,d0    ; Get the starfield data structure.
        move.l d0,in_buf+16  ; Put it in the gpu buffer.
        move.l warp_count,in_buf+20 ; Add warp count to gpu buffer.
        move.l warp_add,in_buf+24   ; Add warp address to gpu buffer.
        lea fastvector,a0    ; Load the 'fastvector' routine for drawing starfields.
        jsr gpurun           ; Run the routine.
        jsr gpuwait          ; Wait for it to finish.

        ;
        ; Prepare the viewer's orientation transformation matrix.
        ; https://en.wikipedia.org/wiki/Transformation_matrix
        ; 
        move.l #4,gpu_mode ; Mode 4 is the 'viewer orientation transformation matrix (otm)'.
        lea vpang,a0       ; Get the viewpoint angle.
        move #0,d0
        and.l #$ff,d0
        move.l d0,(a0)+
        move #0,d0
        move.l d0,(a0)+
        move #0,d0
        move.l d0,(a0)+
        clr.l (a0)+
        clr.l (a0)+
        lea _web,a1
        move.l 12(a1),d0
        move.l d0,(a0)+
        lea xvector,a0    ; Load the gpu shader.
        jsr gpurun        ; Run it.
        jsr gpuwait       ; Wait.


        ; Set up X and y centre pos for web #1.
        move.l #96+32,xcent  ; X centre.
        move.l #120,d6       ; Y centre.
        add palfix2,d6       ; Adjust for PAL if required.
        move.l d6,ycent      ; Set as Y centre.

        move.l vp_x,d3       ; Get the viewer's X pos.
        move.l vp_y,d4       ; Get the viewer's Y pos.
        move.l vp_z,d5       ; Get the viewer's Z pos.
        move.l #2,gpu_mode   ; Mode 2 is do-the-vectors-in-3d-thang
        lea _web,a6          ; Get the web data structure.
        tst 34(A6)           ; Check there's a web.
        beq noo_wb           ; If zero, there's no web, so skip drawing.

        bsr drawweb          ; Draw th' Web

        ; Draw Player 2's web.
        add #128,32(a6)      ; Adjust player 2's rotation.
        move.l #288-32,xcent ; Move the center over for player 2.
        bsr drawweb          ; Draw player 2's Web
        sub #128,32(a6)      ; Restore the previous rotation.
        
noo_wb:
        move.l activeobjects,a6
        bsr d_obj    ;do std. object stuff
        bsr draw2polyos
        bsr drawmsg

        lea screen3,a0    ;source screen for any score u/d xfers
        move.l a0,a1
        tst r_ud
        beq nudl
        clr.l d4
        move #26,d2
        move #32,d3
        move #0,d1
        move #4,d0
        sub r_sc,d0
        and #7,d0
        mulu #26,d0
        add #10+32,d0
        jsr BlitBlock
        clr r_ud
nudl:   tst l_ud
        beq nudr
        clr.l d4
        move #26,d2
        move #32,d3
        move #0,d1
        move #4,d0
        sub l_sc,d0
        and #7,d0
        mulu #26,d0
        neg d0
        add #330-32,d0
        jsr BlitBlock
        clr l_ud
nudr:   bra nevon 

h2hinsc:lea screen3,a0    ;source screen for any score u/d xfers
        move.l a0,a1
        move #0,d0
        move #32,d1
        move #26,d2
        move #32,d3
        move #0,d5
        move #4,d6
zoopy1: move d6,d4
        and #7,d4
        mulu #26,d4
        add #10+32,d4
        jsr ecopy
        dbra d6,zoopy1
        move #32,d0
        move #32,d1
        move #26,d2
        move #32,d3
        move #0,d5
        move #4,d6
zoopy2: move d6,d4
        and #7,d4
        mulu #26,d4
        neg d4
        add #330-32,d4
        jsr ecopy
        dbra d6,zoopy2
        rts

; *******************************************************************
; draw_spike
; Special case of draw, for a spike.
; A member of the draw_vex list.
; *******************************************************************
draw_spike:

        move.l (a6),a0    ; Get object and put in a0.
        clr.l 20(a0)      ; Spikes are not centered in Z.
        move.l 36(a0),a1  ; Pointer to vertex table
        clr.l 8(a1)       ; Set Y to 0. Always starts at z=bottom of web
        move 36(a6),d1    ; Get the Delta Z
        neg d1            ; Negate
        ext.l d1          ; Make it a long.
        asr.l #1,d1       ; Shift right.
        move.l d1,20(a1)  ; Stretch spike towards player
        bra draw          ; Draw.

; *******************************************************************
; draw_vxc
; Draw, with a variable x-centre
; A member of the draw_vex list.
; *******************************************************************
draw_vxc:

        move.l (a6),d0       ; Check if vector or solid.
        bmi draw             ; Skip to 'draw' immediately if it's a solid.

        ; It's a vector.
vvxc:
        move #9,d4           ; Set 9 as X offset, the default for Tempest.
        sub 36(a6),d4        ; Subtract from object's Z.
        ext.l d4             ; Extend to a long.
        move.l d0,a0         ; Copy object to a0.
        move.l 12(a0),-(a7)  ; Stash Z pos.
        move.l d4,12(a0)     ; Store offset Z pos to copied object.
        move.l a0,-(a7)      ; Stash copied object.
        bsr draw             ; Draw it.
        move.l (a7)+,a0      ; Restore stash object.
        move.l (a7)+,12(a0)  ; Restore old centre
        rts

; *******************************************************************
; draw_z
; Draw  with a number of incrementally coloured layers.
; Used for vector objects in the activeobjects list.
; A member of the draw_vex list.
; *******************************************************************
draw_z:
        bsr draw           ; draw original object
        move 40(a6),-(a7)  ; save orignal colour
;  move 44(a6),d0    ;z images counter
        move #2,d0        ; Z images counter
        move 36(a6),d1    ; delta z
        ext.l d1          ; Extend 
        asl.l #8,d1       ; Convert to 16:16
        move 38(a6),d2    ; Delta for colour
        move.l 12(a6),d3  ; Z position
dr_z:
        add d2,40(a6)     ; Add the delta to the colour
        add.l d1,d3       ; Add the z delta to the z position. 
        movem.l d0-d3,-(a7) ; Stash the difference between z positions.

        move.l (a6),a1    ; Get object header
        lea in_buf+4,a0   ; Get GPU buffer
        move.l 4(a6),d0   ; Get the X pos
        sub.l vp_x,d0     ; Subtract the viewpoint
        move.l d0,(a0)+   ; Add to GPU buffer
        move.l 8(a6),d0   ; Get the Y pos
        sub.l vp_y,d0     ; Subtract the viewpoint
        move.l d0,(a0)+   ; Add to tGPU buffer
        move.l d3,d0      ; Get the z position
        bsr dra           ; Run the GPU routine to draw the vectors.
        movem.l (a7)+,d0-d3 ; Retrieve the difference between z positions
        dbra d0,dr_z      ; Loop until we've done for all diferences.

        move (a7)+,40(a6) ; Get old colour back
        rts

; *******************************************************************
; draw
; The 'base' draw routine when processing 'activeobjects'. If a 'vector'
; draw is good enough, we just do that. Otherwise we add the object to the
; 'apriority' list for processing by 'drawpolyos'. 
; *******************************************************************
draw:
        move.l a6,oopss   ; Stash the header.
        move.l (a6),d0    ; Is the header value greater than zero?
        bpl vector        ; If yes, then a vector draw will suffice.

        ; Otherwise we need to do add this object to the 'apriority'
        ; list so that it can be drawn as a solid polygon.

        ; The 'apriority' list stores objects in the descending order
        ; of their Z co-ordinate. This ensures that nearer objects are
        ; painted in front of objects that are further away or 'behind' them.
        move.l fpriority,a0  ;get a free priority object
        move.l a6,(a0)
        move.l 12(a6),d0  ;get 'z'
        move.l d0,12(a0)  ;put z in prior object
        move.l apriority,a1
        move.l a1,a2
chklp:
        cmp.l #-1,a1      ;no objects active?
        bne prio1
        bra insertprior   ;we are at top of list then, if we are first a1=a2=-1

prio1:
        cmp.l 12(a1),d0   ;check against stored 'z'
        bge insertprior   ;behind, insert on to list
        move.l a1,a2
        move.l 8(a1),a1   ;get next object
        bra chklp         ;loop until list end or next object in front of us
        rts               ;return with object at right place in the list

; *******************************************************************
; drawpolyos
; Routine for drawing all solid polygons.
; Process each object in the 'apriority' list. We remove each item after
; processing.The draw routine for each item is given by its index into
; the 'solids' array.
; *******************************************************************
drawpolyos:
        move.l #192,xcent   ; Set 192 as X centre.
        move.l #120,d6      ; Set 120 as Y centre.
        add palfix2,d6      ; Adjust for PAL if necessary.
        move.l d6,ycent     ; Store it as Y centre.
        move.l apriority,a0 ; Get our 'apriority' list.
dpoloop:
        cmp.l #-1,a0
        beq rrts            ; End of list was reached
        move.l (a0),a6      ; Get the index to 'solids'
        move.l (a6),d0      ; Store it in d0.
        move.l a0,-(a7)     ; Stash our current position in the list.
        bsr podraw          ; Go do object type draw
        jsr gpuwait         ; wait for gpu
        move.l (a7)+,a0     ; Get our current position in the list
        move.l 8(a0),-(a7)  ; Get the next position in the list
        bsr unlinkprior     ; Delete the current object.
        move.l (a7)+,a0     ; Move to the next position in the list.
        bra dpoloop         ; Loop until all objects drawn and unlinked
 
podraw:
        move.l #9,d4        ; Set X centre as 9.
        move.l #9,d5        ; Set Y centre as 9.
soldraw:
        neg d0
        lea solids,a4       ; Get the 'solids' list.
        lsl #2,d0           ; Multiply our index by 2.
        move.l 0(a4,d0.w),a0  ; Get the draw routine address from 'solids'.
        move.l 4(a6),d2     ; Get the X position from our object.
        sub.l vp_x,d2       ; Subtract our X viewpoint.
        move.l 8(a6),d3     ; Get the Y position from our object.
        sub.l vp_y,d3       ; Subtract our Y viewpoint.
        move.l 12(a6),d1    ; Get the Z position from our object.
        sub.l vp_z,d1       ; Subtract our X viewpoint.
        bmi rrts            ; Skip if not visible.
        move 28(a6),d0      ; Get orientation of object.
        and.l #$ff,d0       ; Use only the least significant bytes.
        jmp (a0)            ; Call the objects draw routine.
                            ; The draw routine returns to 'dpoloop'.

; *******************************************************************
; draw2polyos
; traverse the priority list, draw the objects on p1's web, then traverse it backwards to draw the objects on p2's web
; *******************************************************************
draw2polyos:
        move.l #96+32,xcent
        move.l #120,d6
        add palfix2,d6
        move.l d6,ycent
        clr h2hor
        move.l apriority,a0
        cmp.l #-1,a0
        beq rrts    ;End of list was reached
d2poloop:
        move.l (a0),a6    ;Get object handle
        move.l (a6),d0
        move.l a0,-(a7)
        bsr podraw    ;Go do object type draw
        jsr gpuwait
        move.l (a7)+,a0
        move.l 8(a0),d0
        bmi travback
        move.l d0,a0    ;next Object
        bra d2poloop
travback:
        move.l #288-32,xcent
        move #1,h2hor
tback:
         move.l (a0),a6    ;Get object handle
        move.l (a6),d0
        move.l a0,-(a7)
        bsr r_podraw    ;Go do object type draw
        jsr gpuwait
        move.l (a7)+,a0
        move.l 4(a0),-(a7)  ;next object or -1
        bsr bunlinkprior    ;kill this object
        move.l (a7)+,a0
        cmpa.l #-1,a0
        bne tback
        rts
 
r_podraw:
        move.l #9,d4
        move.l #9,d5    ;default xy-centre
        neg d0
        lea solids,a4
        lsl #2,d0
        move.l 0(a4,d0.w),a0  ;polyobject draw routine address
        move.l 4(a6),d2
        neg.l d2
        sub.l vp_x,d2
        move.l 8(a6),d3
        sub.l vp_y,d3
        move #webz,d6
        swap d6
        clr d6
        move.l 12(a6),d1
        sub.l d6,d1
        neg.l d1
        add.l d6,d1
        sub.l vp_z,d1
        bmi rrts    ;-ve no go
        move 28(a6),d0
        neg.b d0
        and.l #$ff,d0
        jmp (a0)    ;draw specific polyobject

; *******************************************************************
; drawweb
; Actually draw the web.
; *******************************************************************
drawweb:
        move.l a6,oopss
        move.l (a6),d0
        move.l d0,a1
        lea in_buf+4,a0
        move.l 4(a6),d0
        sub.l d3,d0
        move.l d0,(a0)+    ;Co-ordinates as X, Y, Z 16:16 frax
        move.l 8(a6),d0    ;Combine with camera viewpoint
        sub.l d4,d0
        move.l d0,(a0)+
        move.l 12(a6),d0
        sub.l d5,d0
        tst h2h
        beq swebbo
        sub.l #$40000,d0  ;hack to avoid floating Flippers
swebbo:
        move.l d0,(a0)+
        tst h2h
        beq dragg 
        lea xvector,a2
        bra draaa  

; *******************************************************************
; vector
; Draw a vector
; *******************************************************************
vector:
        move.l d0,a1       ;Get object header
        lea in_buf+4,a0
        move.l 4(a6),d0
        sub.l vp_x,d0
        move.l d0,(a0)+    ;Co-ordinates as X, Y, Z 16:16 frax
        move.l 8(a6),d0    ;Combine with camera viewpoint
        sub.l vp_y,d0
        move.l d0,(a0)+
        move.l 12(a6),d0

; Draw a vector without the above header information.
dra:    sub.l vp_z,d0     ; Subtract the camera viewpoint.
        move.l d0,(a0)+   ; Add to the GPU buffer.
dragg:  lea fastvector,a2 ; Get the fastvector shader.
draaa:  move 28(a6),d0    ; Get the XZ orientation
druuu:  and.l #$ff,d0     ; Only first byte.
        move.l d0,24(a1)  ; Copy to XY orientation
        move 30(a6),d0    ; Get Y rotation of object.
        and.l #$ff,d0     ; Only first byte.
        move.l d0,28(a1)  ; Copy to XZ orientation
        move 32(a6),d0    ; Get Z rotation
        and.l #$ff,d0     ; Only first byte.
        move.l d0,32(a1)  ; Copy to YZ orientation

        ; Copy the first 48 bytes of object to GPU buffer.
        move #11,d0    ;copy 48 bytes
xhead:  move.l (a1)+,(a0)+  ;copy the header to GPU input ram
        dbra d0,xhead

        move 40(a6),d0    ; Get the colour
        and.l #$ff,d0     ; Only first byte
        move.l d0,(a0)+   ; Add to the GPU buffer.
        move 42(a6),d0    ; Get the scale factor.
        ext.l d0          ; Make it a long.
        move.l d0,scaler  ; Move to scaler.
        move.l a1,oopss+4 ; Stash the updated object.
        move.l (a6),oopss+8 ; Stash the original object.
godraa: move.l #2,gpu_mode; Set the GPU mode
        move.l a2,a0      ; Load the fastvector shader.
        jsr gpurun        ; Run the gpu routine
        jsr gpuwait       ; Wait until finished.
        rts



; *******************************************************************
; draw_h2hclaw
; Draw a claw in head-to-head mode
; A member of the 'solids' list.
; *******************************************************************
draw_h2hclaw:
        move 48(a6),d4
        beq wittg
        bpl rezza

        lea in_buf,a0
        move.l d2,(a0)
        move.l d3,4(a0)
        move.l d1,8(a0)
        move d4,d0
        neg d0
        and.l #$ff,d0
        move.l d0,d1
        move.l d0,d2
        lsl.l #2,d2
        lsr.l #2,d1
        neg.l d1
        add.l #$ff,d1
        and #$0f,d1
        or #$f0,d1
        asl.l #2,d0
        move.l d0,12(a0)  ;rad
        move.l #0,16(a0)  ;phase 1
        move frames,d0
        and.l #$ff,d0
        move.l d0,20(a0)  ;phase 2
        move #0,d3
        lsl #4,d3
        lea sphertypes,a1
        lea 0(a1,d3.w),a1
        move.l (a1)+,24(a0)  ;rings/sphere
        move.l (a1)+,28(a0)  ;pixels/ring
        move.l (a1)+,32(a0)  ;pixel spacing
        move.l (a1)+,36(a0)  ;twist per ring
        move.l d1,40(a0)  ;colour
        neg.l d2
        add.l #$ff,d2    ;calculate i decreasing
        move.l d2,44(a0)
        move.l #2,gpu_mode
        lea equine,a0
        jsr gpurun      ;do clear screen
        jmp gpuwait     ; returns

rezza:  movem.l d0-d5,-(a7)
        move.l #1,gpu_mode
        lea in_buf,a0
        move.l #8,(a0)+    ;# pixels per ring
        move.l d2,(a0)+
        move.l d3,(a0)+
        move.l d1,(a0)+  ;XYZ position
        
        move #3,d2
xlxlxl: move d4,d7
        lea in_buf+16,a0
        
        jsr pulser
fcolour:and.l #$ff,d6
        move.l d6,(A0)+  ;colour
        move d4,d0
        swap d0
        move.l d0,(a0)+  ;radius
        move.l d6,(a0)+    ;phase
        lea equine,a0
        jsr gpurun      ;do clear screen
        jsr gpuwait
        asr #1,d4
        dbra d2,xlxlxl
        movem.l (a7)+,d0-d5
        move frames,d6
        btst #2,d6
        bne wittg
        rts  

wittg:  and.l #$ff,d0
        move.l 16(a6),d6
        lsl.l #3,d6
        swap d6
        and #$07,d6
        cmp #$8f,40(a6)
        bne snopp2
        add #8,d6
snopp2:
        lsl #2,d6
        lea sclaws,a1
        move.l 0(a1,d6.w),a1
        jmp zqz

; *******************************************************************
; Unused/unreachable code
; *******************************************************************
        lea in_buf+4,a0
        move.l d2,(a0)+
        move.l d3,(a0)+
        move.l d1,(a0)+
        move.l 36(a6),a1
        lea xvector,a2
        bra draaa

; *******************************************************************
; draw_h2hball
; Routine for drawing a solid ball in head-to-head mode.
; A member of the 'solids' list.
; *******************************************************************
draw_h2hball:
        tst 18(a6)  ;check for are we zapping someone
        bmi onlyball
        movem.l d0-d5,-(a7)
        lea in_buf,a0      ;set up func/linedraw
        move.l d2,(a0)+
        move.l d3,(a0)+
        move.l d1,(a0)+  ;XYZ source
        move.l _claw,a4
        cmp #webz,12(a6)
        bmi drh2hb1
        move.l 56(a4),a4
drh2hb1:
        move.l 4(a4),d0
        sub.l vp_x,d0
        move.l d0,(a0)+
        move.l 8(a4),d0
        sub.l vp_y,d0
        move.l d0,(a0)+
        move.l 12(a4),d0
        tst h2hor
        beq nohorra
        move #webz,d6
        swap d6
        clr d6
        sub.l d6,d0
        neg.l d0
        add.l d6,d0
nohorra:
        sub.l vp_z,d0
        move.l d0,(a0)+  ;XYZ dest
        move frames,d0
        and.l #$0f,d0
        or #$80,d0
        move.l d0,(a0)+  ;colour
        move.l #32,(a0)+  ;# segs
        move frames,d0
        and.l #$ff,d0
        or #$01,d0
        move.l d0,(a0)+    ;rnd seed
        move.l #0,gpu_mode
        move.l #bovine,a0
        jsr gpurun    ;do it
        jsr gpuwait
        jsr WaitBlit
        movem.l (a7)+,d0-d5

onlyball:
        lea in_buf+4,a0
        move.l d2,(a0)+
        move.l d3,(a0)+
        move.l d1,(a0)+
        move.l _cube,a1
        lea xvector,a2
        move 28(a6),d0
        and.l #$ff,d0
        move.l d0,24(a1)  ;XY orientation
        move 30(a6),d0
        and.l #$ff,d0
        move.l d0,28(a1)  ;XZ orientation
        move 32(a6),d0
        and.l #$ff,d0
        move.l d0,32(a1)  ;YZ orientation
        move #11,d0    ;copy 48 bytes
bhead:
         move.l (a1)+,(a0)+  ;copy the header to GPU input ram
        dbra d0,bhead
        move.l #$88,(a0)+    ;colour
        move.l #-2,scaler
        bra godraa

; *******************************************************************
; draw_pel
; Draw a pixel sized object.
; *******************************************************************
draw_pel:
        lea in_buf,a0
        move.l 4(a6),d0
        sub.l vp_x,d0
        move.l d0,(a0)+
        move.l 8(a6),d0
        sub.l vp_y,d0
        move.l d0,(a0)+
        move.l 12(a6),d0
        sub.l vp_z,d0
        move.l d0,(a0)+
        move 54(a6),d0
        and #$ff,d0
        lea pixcols,a4
        move.b 0(a4,d0.w),d0
        and.l #$ff,d0
        move.l d0,(a0)+
        move.l #5,gpu_mode
        lea xparrot,a0
        jsr gpurun    ;do gpu routine
        jsr gpuwait
        rts

; *******************************************************************
; clearscreen
; Clear the current gpu_screen.
; *******************************************************************
clearscreen:
        move.l #0,gpu_mode  ;GPU op 0 is clear the screen
        lea fastvector,a0
        jsr gpurun          ; do gpu routine
        jmp gpuwait         ; returns

; *******************************************************************
; readpad
; read joypad keys
; Unused function for reading the rotary controller before the pad.
; *******************************************************************
readpad:tst roconon
        bne rrts      ;Pad read is done by rocon routine, if enabled

; *******************************************************************
; Check for input from the controller pad. This is the one actually
; used by the game. 
; *******************************************************************
dopad:
        movem.l  d0-d2,-(sp)
        ;scan for player 1
        move.l  #$f0fffffc,d1    ; d1 = Joypad data mask
        moveq.l  #-1,d2          ; d2 = Cumulative joypad reading

        move.w  #$81fe,JOYOUT
        move.l  JOYIN,d0         ; Read joypad, pause button, A button
        or.l    d1,d0            ; Mask off unused bits
        ror.l  #4,d0
        and.l  d0,d2             ; d2 = xxAPxxxx RLDUxxxx xxxxxxxx xxxxxxxx
        move.w  #$81fd,JOYOUT
        move.l  JOYIN,d0         ; Read *741 keys, B button
        or.l    d1,d0            ; Mask off unused bits
        ror.l  #8,d0
        and.l  d0,d2             ; d2 = xxAPxxBx RLDU741* xxxxxxxx xxxxxxxx
        move.w  #$81fb,JOYOUT
        move.l  JOYIN,d0         ; Read 2580 keys, C button
        or.l    d1,d0            ; Mask off unused bits
        rol.l  #6,d0
        rol.l  #6,d0
        and.l  d0,d2             ; d2 = xxAPxxBx RLDU741* xxCxxxxx 2580xxxx
        move.w  #$81f7,JOYOUT
        move.l  JOYIN,d0         ; Read 369# keys, Option button
        or.l    d1,d0            ; Mask off unused bits
        rol.l  #8,d0
        and.l  d0,d2             ; d2 = xxAPxxBx RLDU741* xxCxxxOx 2580369# <== inputs active low

        moveq.l  #-1,d1
        eor.l  d2,d1             ; d1 = xxAPxxBx RLDU741* xxCxxxOx 2580369# <== now inputs active high

        move.l  pad_now,d0       ; old joycur needed for determining the new joyedge
        move.l  d1,pad_now       ; Current joypad reading stored into joycur
        eor.l  d1,d0
        and.l  d1,d0
        move.l  d0,pad_shot      ;joypad, buttons, keys that were just pressed

;scan for player 2
        move.l  #$0ffffff3,d1    ; d1 = Joypad data mask
        moveq.l  #-1,d2          ; d2 = Cumulative joypad reading

        move.w  #$817f,JOYOUT
        move.l  JOYIN,d0         ; Read joypad, pause button, A button
        or.l    d1,d0            ; Mask off unused bits
        rol.b  #2,d0             ; note the size of rol
        ror.l  #8,d0
        and.l  d0,d2             ; d2 = xxAPxxxx RLDUxxxx xxxxxxxx xxxxxxxx
        move.w  #$81bf,JOYOUT
        move.l  JOYIN,d0         ; Read *741 keys, B button
        or.l    d1,d0            ; Mask off unused bits
        rol.b  #2,d0             ; note the size of rol
        ror.l  #8,d0
        ror.l  #4,d0
        and.l  d0,d2             ; d2 = xxAPxxBx RLDU741* xxxxxxxx xxxxxxxx
        move.w  #$81df,JOYOUT
        move.l  JOYIN,d0         ; Read 2580 keys, C button
        or.l    d1,d0            ; Mask off unused bits
        rol.b  #2,d0             ; note the size of rol
        rol.l  #8,d0
        and.l  d0,d2             ; d2 = xxAPxxBx RLDU741* xxCxxxxx 2580xxxx
        move.w  #$81ef,JOYOUT
        move.l  JOYIN,d0         ; Read 369# keys, Option button
        or.l    d1,d0            ; Mask off unused bits
        rol.b  #2,d0             ; note the size of rol
        rol.l  #4,d0
        and.l  d0,d2             ; d2 = xxAPxxBx RLDU741* xxCxxxOx 2580369# <== inputs active low

        moveq.l  #-1,d1
        eor.l  d2,d1             ; d1 = xxAPxxBx RLDU741* xxCxxxOx 2580369# <== now inputs active high

        move.l  pad_now+4,d0     ; old joycur needed for determining the new joyedge
        move.l  d1,pad_now+4     ; Current joypad reading stored into joycur
        eor.l  d1,d0
        and.l  d1,d0
        move.l  d0,pad_shot+4    ;joypad, buttons, keys that were just pressed

        movem.l  (sp)+,d0-d2
        rts

; *******************************************************************
; MoveLink
; Linked-list transfer entry from list a4 to list a3
; prev ptr in a1, next in a2
; Part of the GPU object management system.
; *******************************************************************
MoveLink:
mlink:  cmpa.l #-1,a1    ;Prev is -1?
        bne ML1
        move.l a2,(a4)   ;Make Next entry current top of list
        cmpa.l a1,a2     ;Check if Next is -1
        beq NewLink      ;Yup, we were the only entry
ML1:    cmpa.l #-1,a2    ;Next link is -1?
        bne ML2          ;Nope
        move.l a2,60(a1) ;Make prev link-to-next -1
        bra NewLink
ML2:    cmpa.l #-1,a1
        beq ml3
        move.l a2,60(a1)
ml3:    move.l a1,56(a2) ;Link 'em up
NewLink:move.l (a3),a4   ;Get address of first entry of dest list
        cmpa.l #-1,a4    ;Check if link is real
        bne NL1          ;Yup
        move.l a0,(a3)   ;Make ourselves the first entry
        move.l #-1,56(a0)
        move.l #-1,60(a0)
        clr d0
        rts
NL1:    move.l #-1,56(a0) ;Gonna insert ourselves at the top
        move.l a0,56(a4)  ;We are his previous
        move.l a4,60(a0)  ;And he is our next
        move.l a0,(a3)    ;Put us in
        clr d0
        rts

; *******************************************************************
; initobjects
; *******************************************************************
initobjects:
        move.l #-1,activeobjects
        lea objects,a0  
        move #63,d0
        move d0,ofree
        move.l a0,freeobjects
        move.l #-1,a1
IniA:   move #-1,50(a0)
        move.l a1,56(a0)  ;set Prev
        move.l a0,a1      ;current=new Prev
        lea 64(a0),a0     ;next bullet
        move.l a0,60(a1)  ;set Next field of preceding one
        dbra d0,IniA
        move.l #-1,60(a1)  
        move #32,afree
        rts

; *******************************************************************
; initprior
; *******************************************************************
initprior:
        move.l #-1,apriority
        lea priors,a0
        move #63,d0
        move.l a0,fpriority
        move.l #-1,a1
inipri:
        move.l a1,4(a0)
        move.l a0,a1
        lea 16(a0),a0
        move.l a0,8(a1)
        dbra d0,inipri
        move.l #-1,8(a1)
        rts  

; *******************************************************************
; insertobject
;
; move object to active list
; *******************************************************************
insertobject:
        clr 50(a0)    ;init busy flag
        move.l 56(a0),a1 
        move.l 60(a0),a2
        sub #1,ofree
        lea activeobjects,a3
        lea freeobjects,a4
        bra MoveLink

; *******************************************************************
; unlinkobject
;
; render an active object inactive
; *******************************************************************
unlinkobject:
        move.l 56(a0),a1 
        move.l 60(a0),a2
        add #1,ofree
        lea freeobjects,a3
        lea activeobjects,a4
        bra MoveLink


; *******************************************************************
; insertprior
; insert object a0 behind object a1
; *******************************************************************
insertprior:
        move.l 8(a0),a3
        move.l a3,fpriority  ;next free object to top of list
        move.l #-1,4(a3)     ;set object's prev to -1, now our obj is off free list

        cmp.l #-1,a1         ;first object on list special case
        bne insp1
        cmp.l a1,a2
        beq vfo              ;if list header is -1, go do very-first-object

nvfo:   move.l a0,8(a2)      ;us to Next    this is Very Last Object
        move.l a2,4(a0)      ;him to Prev
        move.l #-1,8(a0)     ;us to List End
        rts

vfo:    move.l a0,apriority
        move.l #-1,4(a0)
        move.l #-1,8(a0)     ;set first object
        rts

insp1:  cmp.l #-1,4(a1)      ;is he at the top of the lst?
        bne gencase          ;nope
        move.l a0,apriority  ;set us as the first object
        move.l 4(a1),a3
        bra insp2            ;skip setting prev coz it's top of the lst  

gencase:move.l 4(a1),a3      ;get his/our prev
        move.l a0,8(a3)      ;put us there
insp2:  move.l a3,4(a0)      ;His prev link is now our prev link
        move.l a0,4(a1)      ;We are now his previous
        move.l a1,8(a0)      ;He is our next
        rts


; *******************************************************************
; unlinkprior
; always unlink object a0 from top of apriority to top of fpriority
; *******************************************************************
unlinkprior:
        move.l 8(a0),d0
        bpl ulp1
        move.l d0,apriority  ;sets to -1
        bra ulp2
ulp1:   move.l d0,a1
        move.l d0,apriority
        move.l #-1,4(a1)
ulp2:   move.l #-1,4(a0)
        move.l fpriority,a1
        move.l a1,8(a0)
        move.l a0,fpriority
        move.l a0,4(a1)
        rts

; *******************************************************************
; bunlinkprior
; unlink from bottom of apriority to top of fpriority
; *******************************************************************
bunlinkprior:
        move.l 4(a0),d0
        bpl ulp3
        move.l d0,apriority  ;sets to -1
        bra ulp4
ulp3:   move.l d0,a1
        move.l #-1,8(a1)
ulp4:   move.l #-1,4(a0)
        move.l fpriority,a1
        move.l a1,8(a0)
        move.l a0,fpriority
        move.l a0,4(a1)
        rts


 move.l 4(a0),a1 
 move.l 8(a0),a2
 lea fpriority,a3
 lea apriority,a4
 bra MovePrior


; *******************************************************************
; MovePrior
; Linked-list transfer entry from list a4 to list a3
; prev ptr in a1, next in a2
; *******************************************************************
MovePrior:
mprio:  cmpa.l #-1,a1    ;Prev is -1?
        bne MP1
        move.l a2,(a4)    ;Make Next entry current top of list
        cmpa.l a1,a2    ;Check if Next is -1
        beq NewPLink    ;Yup, we were the only entry
MP1:    cmpa.l #-1,a2  ;Next link is -1?
        bne MP2    ;Nope
        move.l a2,8(a1)  ;Make prev link-to-next -1
        bra NewPLink
MP2:    cmpa.l #-1,a1
        beq mp3
        move.l a2,8(a1)
mp3:    move.l a1,4(a2)    ;Link 'em up

NewPLink:
        move.l (a3),a4  ;Get address of first entry of dest list
        cmpa.l #-1,a4    ;Check if link is real
        bne NP1    ;Yup
        move.l a0,(a3)    ;Make ourselves the first entry
        move.l #-1,4(a0)
        move.l #-1,8(a0)
        rts
NP1:    move.l #-1,4(a0)  ;Gonna insert ourselves at the top
        move.l a0,4(a4)    ;We are his previous
        move.l a4,8(a0)  ;And he is our next
        move.l a0,(a3)    ;Put us in
        rts

; *******************************************************************
; return a ran# 0-255
; *******************************************************************
rannum:
        lea rantab,a3
        add #1,ranptr
        move ranptr,d0
        and #$ff,d0
        move.b 0(a3,d0.w),d0
        rts

; *******************************************************************
; Return a number between zero and d1, uses same stuff as rannum (plus d1 obviously)
; *******************************************************************
rand:
        bsr rannum
        mulu d1,d0
        lsr.l #8,d0
        rts

; *******************************************************************
; setnewgen
; Initialize the wave data in 'wstuff' using the selected wave data structure.
; a0 is the wave data structure selected from the 'waves' array.
; The processed data gets written to wstuff.
; e.g.
; _nw1:   dc.w 24       ; Duration
;         dc.w 120,0    ; Flippers - Max Time,  Index into 'inits' for generation routine.
;         dc.w -1       ; End of data sentinel
;
; _nw3:   dc.w 16       ; Duration
;         dc.w 120,0    ; Flippers - Max Time, Type
;         dc.w 0,444,1  ; Flipper Tankers - Sentinel, Max Time, Index into 'inits' for generation routine.
;         dc.w -1       ; End of data sentinel
; *******************************************************************
setnewgen:
        lea wstuff,a1        ; Point to the wstuff table to a1
        move #-1,(a1)+       ; Terminate the previous entry.
        ; Read the header byte.
        move (a0)+,wave_dur  ; Store the duration in wave_dur.
        ; There's always at least one entry - for flippers, so we
        ; do that first entry here. It always has just two elements,
        ; while the others have three.
        move (a0)+,d0        ; Stash the max time in d0.
        move d0,(a1)+        ; Then store it in the wstuff table.
        move (a0)+,(a1)+     ; Store the type in the wstuff table.
        lsr #1,d0            ; Divide max time by 2.
        move d0,(a1)+        ; Store it as a timer.

        ; Process the remaining items in the wave data.
sngenl: move (a0)+,d0        ; Stash the sentinel in d0.
        bmi thaggit          ; If it's -1, then we've reached the end of the wave data.
        move d0,(a1)+        ; Otherwise store it in the wstuff table.
        move (a0)+,d0        ; Stash the max time in d0.
        move d0,(a1)+        ; Store it in the wstuff table.
        move (a0)+,(a1)+     ; Store the type in the wstuff table.
        lsr #1,d0            ; Divide max time by 2.
        move d0,(a1)+        ; Store it as a timer. 
        bra sngenl           ; Loop until all done

thaggit:
        move d0,4(a1)        ; Store the end sentinel
        clr wave_tim         ; Clear the wave timer.
        rts

; *******************************************************************
; newgen
; Use the wstuff table to determine the generation of new enemies.
; Processes each entry in wstuff and sees if its time to generate a new
; enemy for each enemy type in the wave.
; *******************************************************************
newgen: tst wave_tim
        bmi rrts
        tst startbonus
        bpl nostab
        bsr do_oneup
        clr startbonus

nostab: lea wstuff,a0     ; Get the wave table.
        ; Process the first entry in the wstuff table (always the flipper entry).
        sub #1,6(a0)      ; Decrement the wave timer.
        bpl nugen1
        move 4(a0),d0     ; Store the type/index of the first entry (always a flipper) in d0.
        bsr launch1       ; Try to launch a new flipper.

        ; Process the rest of the wstuff table.
nugen1: lea 8(a0),a0      ; Move to the next entry in the list.
nugen2: move 4(a0),d0     ; Store the type/index of the next entry in d0.
        bmi rrts          ; If it's -1 we've reached the end of the wstuff table.
        sub #1,6(a0)      ; Subtract 1 from the wave's timer.
        bpl nugen3        ; Is it zero yet? If not - go the next item in wsstuff.
        bsr launch1       ; If it is, then it's time to create a new enemy for this part of the wave.
nugen3: lea 8(a0),a0      ; Move to the next entry in the list.
        bra nugen2        ; Process it.

        ; Generate a new enemy.
launch1:tst t2k           ; Are we in t2k mode?
        bne doany         ; If not, go ahead and try to create an enemy.
        cmp #6,d0         ; Is the type greater than 6?
        bgt shutoff       ; 

doany:  move noclog,d1    ; Get the available bandwidth for new enemies.
        cmp afree,d1      ; Do we have room for a new enemy?
        bpl rrts          ; if no, return now.
        ; Add an enemy.
        move 2(a0),6(a0)
        lsl #2,d0         ; Multiply the type/index by 2
        move.l a0,-(a7)   ; Stash a0
        lea inits,a0      ; Load the inits list to a0.
        move.l 0(a0,d0.w),a0  ; Index into 'inits' to get the routine for this type/index.
        jsr (a0)          ; Run the creation routine for this enemy type.
        move.l (a7)+,a0   ; Retrieve the stashed a0.
        sub #1,wave_dur   ; We've created an enemy, so knock one off the duration.
        bpl rrts          ; If we still have more to generate, return now.
        move #-1,wave_tim ; Otherwise signal that there are no more to do.
        rts

shutoff:
        move #$7fff,2(a0)
        move #$7fff,6(a0)
        rts


; *******************************************************************
; init_wave
; Set up the wave run routine.
; a0 is the wave data structure selected from the 'waves' array.
; e.g.
; _nw1:   dc.w 24
;         dc.w 120,0    ;Flippers
;         dc.w -1
; *******************************************************************
init_wave:
        bra setnewgen     ; Initialize the wave data

        move.l a0,wave_ptr
        move.l #wave_stack,wave_sp  ;init pointer and stack
        clr wave_tim      ;OK to run
        rts

; *******************************************************************
; Routines for generating all types of new enemies.
; *******************************************************************
inits:
        dc.l make_flipper,make_tanker,make_spiker,make_fuseball,make_pulsar,make_futanker,make_putanker  ;6
        dc.l make_sflip2,make_mirr,make_adroid,make_beast,make_sflip3

; *******************************************************************
; Generate a new enemy if required.
; *******************************************************************
run_wave:
        bra newgen          ; Add new enemies from 'wstuff' if available.

        tst wave_tim        ; Is it time to generate a new wave?
        beq rwave0          ; If yes, go to rwave0.
        bmi rrts            ; If value is negative, we're not generating enemies.
        move wave_speed,d0  ; Get the wave speed.
        sub d0,wave_tim     ; Subtract it from the wave timer.
        bpl rrts            ; If still positive, return as not time to generate a new enemy.
        clr wave_tim        ; Clear the timer, we'll generate a new enemy the next time we come round.
        rts                 ; Return.

rwave:  cmp #1,d0           ; Is wave speed '1'?
        bne strin           ; If so, avoid granting bonuses.

        ; Generate a new wave.
rwave0: tst startbonus      ; Has the player received a start bonus?
        bpl nosb            ; No, skip.
        bsr do_oneup        ; Yes, give them an extra life.
        clr startbonus      ; Clear the start bonus.

nosb:   move noclog,d0      ; Number of new waves we could tolerate.
        cmp afree,d0        ; Number of slots available.
        bge rrts            ; If not enough slots, don't add any new waves.

        ; Update the wave as appropriate to its current state.
strin:  move.l wave_ptr,a6  ; Get the current wave ptr.
rave:   move.b (a6)+,d0     ; Get the current status of the wave.

        ; Check if it's 'waiting'.
        cmp.b #'w',d0       ; Is it in wait status?
        bne rwav1           ; No, check if it's awaiting intialisation.
        ; It's waiting, so set the timer based on its value.
        move.b (a6)+,d0     ; Put the timer value in d0 
        and #$ff,d0         ; Just the LSB.
        move d0,d1          ; Stash it in d1.
        lsr #1,d0           ; Divide by 2.
        add d1,d0           ; Add to initial timer value.
        move d0,wave_tim    ; Set result as wave_tim
wok:    move.l a6,wave_ptr  ; Store updated a6 in wave_ptr
        rts

        ; Is it awaiting initialisation?
rwav1:  cmp.b #'i',d0       ; Awaiting initialisation?
        bne rwav2           ; No, check if it's open.
        ; Initialize it.
        move.b (a6)+,d0     ; Get the index to the init routine.
        and #$ff,d0         ; LSB byte only.
        lea inits,a0        ; Stash the inits array in a0.
        asl #2,d0           ; Multiply index by 2.
        move.l 0(a0,d0.w),a0 ; Get the init routine from inits.
        move.l a6,-(a7)     ; Stash a6.
        jsr (a0)            ; Run the init routine.
        move.l (a7)+,a6     ; Retrieve a6.
        bpl rave            ; If it worked, try running it.
        lea -2(a6),a6       ; Try the previous one.
        move #10,wave_tim   ; Try again after 10 ticks
        bra wok             ; Exit run_wave for now.

        ; Is it for an open loop?
rwav2:  cmp.b #'(',d0       ; Is the wave for an open loop?
        bne rwav3           ; If no, check for closed loop.
        ; Set it up.
        move.b (a6)+,d0     ; Put the loop counter in d0.
        and #$ff,d0         ; Just the LSB byte.
        move.l wave_sp,a0   ; Stash the wave_sp in a0. 
        move.l a6,(a0)+     ; Add the wave_ptr to the stack.
        move d0,(a0)+       ; Add the loop counter to the stack.
        move.l a0,wave_sp   ; Restore the wave_sp from a0.
        bra rave            ; Try again.

        ; Is it for a closed loop?
rwav3:  cmp.b #')',d0       ; Is the wave for a closed loop?
        bne rwav4           ; If no, check if it's finished.
        move.l wave_sp,a0   ; Stash wave_sp in a0.
        sub #1,-2(a0)       ; Decrement the counter.
        bmi unstak          ; If less than zero, free it up.
        move.l -6(a0),a6    ; Set pointer from stack
        bra rave            ; Try again.

unstak: sub.l #6,wave_sp    ; free stack space
        bra wok             ; Exit run_wave for now.

        ; Is it finished?
rwav4:  cmp.b #'e',d0      ; End
        bne wok            ; effectively discard spuirious shit
        move #-1,wave_tim  ; turn it off
        rts

; *******************************************************************
; initstarfield
; initialise a starfield data structure for the GPU to display
; *******************************************************************
initstarfield:

        lea field1,a0
        move #127,d7
        move.l #128,(a0)+  ;set # of stars
isf:
        bsr rannum
        move d0,d2
        sub #$80,d0
        swap d0
        move.l d0,(a0)+    ;X rand +/-128
        bsr rannum
        move d0,d3
        sub #$80,d0
        swap d0
        move.l d0,(a0)+    ;Y rand +/-128
        bsr rannum
        asl #1,d0
        swap d0
        move.l d0,(a0)+    ;Z rand 0-1FF.FFFF
        and #$f0,d2
        lsr #4,d3
        and #$0f,d3
        or d2,d3
        lsl #8,d3
        move d3,(a0)    ;make star co-ordinates an index into CRY-Space

        lea 20(a0),a0
        dbra d7,isf    ;loop for all stars
        rts

rs400:
        move #400,d5
        bra rst

; *******************************************************************
; ringstars
;
; initialise a starfield of 8 rings of 64 stars each
; *******************************************************************
ringstars:

        move #200,d5
rst:
        lea field1,a0
        lea sines,a1
        lea p_sines,a2
        move #7,d7    ;8 rings
        move.l #256,(a0)+  ;set startotal
        
        move #$0000,d4
ring1:
        move #32,d6    ;64 stars per ring
ring2:
;  bsr rannum
;  and #$0f,d0
;  add d0,d5    ;d5 is radius this star, 100-116
;  bsr rannum    ;d0 is angle of this star
        move d6,d0
        asl #3,d0
        move.b 0(a1,d0.w),d1  ;sin angle
        add.b #$40,d0
        move.b 0(a1,d0.w),d2  ;cos angle
        ext d1
        ext d2
        muls d5,d1
        muls d5,d2
        asl.l #7,d1
        asl.l #7,d2    ;XY pixel positions as 16:16 frax
        move.l d1,(a0)+
        move.l d2,(a0)+    ;XY to star data structure
        lsl #2,d0
        and #$ff,d0
        move.b 0(a1,d0.w),d1
        move.b 0(a2,d0.w),d2
        and #$f0,d2
        lsl #4,d2
        ext d1
        bpl sposss
        neg d1
sposss:
        swap d1
        clr d1
        asr.l #1,d1
        clr.l d0
        move d7,d0
        swap d0
        lsl.l #6,d0    ;Z position according to ring no.
        add.l d1,d0
        move.l d0,(a0)+
        move d4,d0
        add d2,d0
        move d0,(a0)    ;colour
        lea 20(a0),a0
        dbra d6,ring2
        add #$2000,d4
        dbra d7,ring1
        rts


; *******************************************************************
; initpstarfield
;
; initialise a patterned starfield; d6-d7=sine pointers (long); d4-d5=sine step (long)
; *******************************************************************
initpstarfield:

        lea field1,a0
        move #255,d3
        move.l #256,(a0)+
        lea sines,a1
ipstarf:
        move.l d6,d0
        swap d0
        and #$ff,d0
        move.b 0(a1,d0.w),d1
        ext d1
        move d1,-(a7)
        swap d1
        clr d1
        move.l d1,(a0)+
        move.l d7,d0
        swap d0
        and #$ff,d0
        move.b 0(a1,d0.w),d1
        ext d1
        move d1,-(a7)
        swap d1
        clr d1
        move.l d1,(a0)+
        move d3,d0
        swap d0
        clr d0
        lsl.l #1,d0
        move.l d0,(a0)+
        move (a7)+,d1
        move (a7)+,d0
        add #$80,d0
        add #$80,d1
        and #$f0,d0
        lsr #4,d1
        and #$0f,d1
        or d0,d1
        lsl #8,d1
        move d1,(a0)
        add.l d4,d6
        add.l d5,d7
        lea 20(a0),a0
        dbra d3,ipstarf
        rts

; *******************************************************************
; initmstarfield
; Unused code
;
; initialise a starfield data structure using the bitmap mask at a1
; *******************************************************************
initmstarfield:

        move (a1)+,d5    ;Width in bytes
        move (a1)+,d6    ;Size in lines


imsf:
        lea field1,a0
        move #255,d7
        move.l #256,(a0)+  ;set # of stars

imms1:
        move d5,d2
        lsl #3,d2
imms0:
        move d6,d3
immsf:
        move d3,d0
        mulu d5,d0    ;Lines times width-in-bytes
        move d2,d1    ;copy of bit no.
        lsr #3,d1    ;back to bytes
        add d1,d0    ;d0 is offset to position within bitmap
        move d2,d1    ;copy bit # again
        and #7,d1    ;bit offset within this byte
        move #7,d4
        sub d1,d4    ;d4 has the bit #
        btst.b d4,0(a1,d0.w)  ;Check if the bit's on
        bne impixel    ;It is on, go start a pixel
nnpixel:
        dbra d3,immsf
        dbra d2,imms0
        bra imms1

impixel:
        movem d2-d3,-(a7)  

        move d5,d0    ;copy total width in bytes
        asl #2,d0    ;is half no. of bits
        sub d0,d2    ;centre X
        move d6,d0    ;lines...
        asr #1,d0
        sub d0,d3    ;centre in Y


        move d2,d0    ;Bit-# to X co-ord
        swap d0
        bsr rannum
        lsl #8,d0    ;Randomise within this pixel
        asl.l #4,d0
        move.l d0,(a0)+    ;X set
        swap d0
        move d0,d2
        move d3,d0
        swap d0
        bsr rannum
        lsl #8,d0    ;Randomise within this pixel
        asl.l #4,d0
        move.l d0,(a0)+    ;Y set
        swap d0
        move d0,d3

        bsr rannum
        asl #1,d0
        swap d0
        clr d0
        move.l d0,(a0)+    ;Z set=random

        add #$80,d2
        add #$80,d3
        and #$f0,d2
        lsr #4,d3
        and #$0f,d3
        or d2,d3
        lsl #8,d3
        move d3,(a0)    ;make star co-ordinates an index into CRY-Space

        lea 20(a0),a0
        movem (a7)+,d2-d3
        dbra d7,nnpixel
        rts


; *******************************************************************
; zscore
;
; Clear score, initialise the score objects
; *******************************************************************
zscore:

        lea scoreimj,a0    ;set score object #1 to all zeros
        move #17,d0
        lea digits,a1
zsco:
        move #7,d2
zsco2:
        move #7,d3
        move.l a1,a2
zsco3:
        move.l (a2)+,(a0)+
        dbra d3,zsco3
        dbra d2,zsco2
        lea 640(a1),a1
        dbra d0,zsco
        rts

; *******************************************************************
; showscore
; *******************************************************************
showscore:
        tst show_warpy
        beq shoscc
        clr show_warpy
        cmp #2,warpy
        beq shoscc
        move.l gpu_screen,d0
        move.l d0,-(a7)
        move.l #screen3,gpu_screen
        move #2,d6
        sub warpy,d6
        lsl #5,d6
        neg d6
        add #352,d6    ;position of pyramid
        move #31,d0    
        move #20,d1  
        move #20,d7
        move.l #$40000,pc_1
        move.l #$560100,pc_2
        jsr makepyr      ;make a pyramid for warpy display
        jsr ppyr      ;draw that pyramid
        move.l (a7)+,d0
        move.l d0,gpu_screen

shoscc:
        tst ud_score
        beq rrts

; *******************************************************************
; ashowscore
; Unused code
; *******************************************************************
ashowscore:
        clr ud_score    ;fall thru to set lives display if requested
        lea screen3,a1
        lea pic2,a0      ;source/dest screens

        move.l score,a2
        move #7,d6
        move #89,d1      ;source Ystart
        move #16,d2
        move #19,d3
        move #48,d4
        move #10,d5
sscore:
        move.b (a2)+,d0
        bne sscore2
        dbra d6,sscore      ;skip leading 0's
        move #148,d0
        jsr CopyBlock    ;display one zero if there is no score
        bra setlives    ;and go do the lives
                ;return if none
sscore2:
        and #$0f,d0
        lsl #4,d0    ;*16, pixel offset to digit position
        add #148,d0    ;source is OK...
        jsr CopyBlock    ;copy the digit
        add #16,d4
        move.b (a2)+,d0
        dbra d6,sscore2

; *******************************************************************
; Update the displayed lives left
; *******************************************************************
setlives:
        move #148,d0
        move #111,d1
        move #26,d2
        move #17,d3
        move #30,d5
        move #48,d4
        lea screen3,a1
        lea pic2,a0
        move lives,d6
        sub #1,d6
        bmi lstliv
        cmp #7,d6
        ble dlives
        move #7,d6
dlives:
        jsr CopyBlock
        add #32,d4
        dbra d6,dlives
lstliv:
        add #32,d0
        jsr CopyBlock
        add #32,d4
        jmp CopyBlock    ;allows for the possibility of losing 2 lives at once (2pl mode)

; *******************************************************************
; Unused and commented out function for initialising the sound system.
; *******************************************************************
initjerry:
        rts


playsample:
        rts

loopsample:
        rts

; *******************************************************************
; doscore
; Recalculate the score.
; *******************************************************************
doscore:
        tst h2h
        bne rrts
        move.l score,a0
        lea scores,a1
        asl #1,d0
        clr d1
        move.b 1(a1,d0.w),d1
        move.b 0(a1,d0.w),d0
scorer:
        tst beastly
        beq ndbl
        tst d1
        bne shftit
        move #1,d1
        bra ndbl
shftit:
        lsl #1,d1
ndbl:
        move d0,d2
adddig:
        lea 0(a0,d0.w),a2
        add.b #1,(a2)
        cmp.b #10,(a2)
        blt nnxtdig
        clr.b (a2)
        sub #1,d0
        bmi nnxtdig
        cmp #3,d0    ;check for 10's of thou
        bne adddig
        btst.b #0,0(a0,d0.w)  ;if it is odd-going-even...
        beq adddig

        movem.l d0-d2/a0-a2,-(a7)
        bsr do_oneup
        movem.l (A7)+,d0-d2/a0-a2  ;make a OneUp object, yippee
        bra adddig
nnxtdig:
        move d2,d0
        dbra d1,ndbl
        move #1,ud_score
        rts  


; *******************************************************************
; iii
; *******************************************************************
iii:
        move.l roach,d0
        lsl.l #1,d0
        add.l (a0),d0
        move.l 20(a0),d1
        cmp.l d1,d0
        bmi rrts
        move.l 16(a0),d1
        cmp.l d1,d0
        bpl rrts
        move.l d0,(a0)
        rts

; *******************************************************************
; inertcon
;
; Inertial control. Enter with a0-> I_CON data structure, d0 bits 0 and 1 are Dec/Inc flags
; *******************************************************************
inertcon:

        move d0,d1
        and #3,d1
        beq friction  ;no accel, go do friction
        btst #0,d1
        beq ininc  ;go do add value

dedec:
        move.l (a0),d1  ;get v
        move.l 20(a0),d2  ;get minv
        cmp.l 16(a0),d2
        beq nolim1  ;if limits are equal there are no limits
        cmp.l d2,d1
        bmi instop  ;minv>v, go stop inertia
        
nolim1:
        move.l 4(a0),d0  ;get accel
        move.l 24(a0),d2  ;get maccel
        neg.l d2  ;negate coz this is dec
        cmp.l d2,d0
        bmi inmove  ;no acceleration, already close to maccel
        
        move.l 8(a0),d0
        sub.l d0,4(a0)  ;do accelerate

inmove:
        move.l 4(a0),d0
        add.l d0,(a0)  ;change V
        rts

ininc:
        move.l (a0),d1  ;get v
        move.l 16(a0),d2  ;get maxv
        cmp.l 20(a0),d2
        beq nolim2
        cmp.l d2,d1
        bpl instop  ;maxv<v, go stop inertia
        
nolim2:
        move.l 4(a0),d0  ;get accel
        move.l 24(a0),d2  ;get maccel
        cmp.l d2,d0
        bpl inmove  ;no acceleration, already close to maccel
        
        move.l 8(a0),d0
        add.l d0,4(a0)  ;do accelerate
        bra inmove


instop:
        clr.l 4(a0)
        rts

friction:
        move.l 4(a0),d0
        move.l 12(a0),d1
        move.l d1,d3
        move.l d0,d2
        bpl sposk
        neg.l d2
        neg.l d3
sposk:
        cmp.l d1,d2
        bmi instop  ;v<friction, go and stopdead
        sub.l d3,4(a0)  ;do friction
        bra inmove  ;but still move


; *******************************************************************
; itunnel
;
; init a startunnel data struct
; *******************************************************************
itunnel:

        lea field1,a0  ;gonna put it in starfield space
        move #63,d7  ;64 tunnel segs in a circular buffr
        clr d0
        clr d1
        clr d2
itunn:
         move.l #$00000020,(a0)+
        move.l #$4020ff00,(a0)+
        move.b d0,-4(a0)
        move.l #$3030b000,(a0)+
        move.b d1,-4(a0)
        move.l #$e2408f00,(a0)+
        add #1,d0
        add #2,d1
        add #3,d2
        dbra d7,itunn
        rts


; *******************************************************************
; init_fw
;
; init the firework controller, a0 pts to an f-control string
; *******************************************************************
init_fw:

        move #1,fw_del
        move.l a0,fw_ptr
        move.l #fw_stack,fw_sp
        rts

fw_run:
        sub #1,fw_del
        bpl rrts
        move.l fw_ptr,a0

fw_cmd:
        move.b (a0)+,d0    ;get cmd
        cmp.b #'.',d0    ;.=Launch at current XY
        bne fw_c1
        move.l a0,-(a7)
        jsr make_fw
        move.l (a7)+,a0
        bra fw_cmd
fw_c1:
        cmp.b #'d',d0    ;d=Set duration
        bne fw_c2
        move.b (a0)+,d0
        and.l #$ff,d0
        move d0,fw_dur
        bra fw_cmd
fw_c2:
         cmp.b #'c',d0    ;c=Set colour
        bne fw_c3
        move.b (a0)+,d0
        and.l #$ff,d0
        move d0,fw_col
        bra fw_cmd
fw_c3:
        cmp.b #'w',d0    ;w=Wait frames
        bne fw_c4
        move.b (a0)+,d0
        and.l #$ff,d0
        move d0,fw_del
        move.l a0,fw_ptr
        rts
fw_c4:
        cmp.b #'(',d0    ;(=Set loop and count
        bne fw_c5
        move.l fw_sp,a1
        move.b (a0)+,d0
        and #$ff,d0
        move d0,(a1)+  ;stack count
        move.l a0,(a1)+  ;stack address
        move.l a1,fw_sp
        bra fw_cmd
fw_c5:
        cmp.b #')',d0    ;)=Loop and dec count
        bne fw_c6
        move.l fw_sp,a1
        sub #1,-6(a1)
        bmi go_fw
        move.l -4(a1),a0
        bra fw_cmd
go_fw:
        sub.l #6,fw_sp
        bra fw_cmd
fw_c6:
        cmp.b #'[',d0    ;[=start Forever Loop
        bne fw_c7
        move.l fw_sp,a1
        move.l a0,(a1)+
        move.l a1,fw_sp
        bra fw_cmd
fw_c7:
        cmp.b #']',d0    ;]=loop Forever
        bne fw_c8
        move.l fw_sp,a1
        move.l -4(a1),a0
        bra fw_cmd
fw_c8:
        cmp.b #'+',d0    ;inc col or dur
        bne fw_c81
        move.b (a0)+,d0
        cmp.b #'d',d0
        beq indur
        add #1,fw_col
        bra fw_cmd
indur:
        add #5,fw_dur
        bra fw_cmd
fw_c81:
        cmp.b #'-',d0    ;inc col or dur
        bne fw_c82
        move.b (a0)+,d0
        cmp.b #'d',d0
        beq dedur
        sub #1,fw_col
        bra fw_cmd
dedur:
        sub #5,fw_dur
        bra fw_cmd
fw_c82:
        cmp.b #'Z',d0    ;X,Y or Z=set speeds
        bgt fw_c9
        lea fw_dx,a2
        sub.b #'X',d0
        and #$ff,d0
        lsl #2,d0
        lea 0(a2,d0.w),a2
        bra fw_setvar
fw_c9:
        lea fw_x,a2    ;x,y or z=set abs positions
        sub.b #'x',d0
        and #$ff,d0
        lsl #2,d0
        lea 0(a2,d0.w),a2
fw_setvar:
        move.b (a0)+,d0
        cmp.b #'!',d0    ;Negate
        bne fw_sv1
        neg.l (a2)
        bra fw_cmd
fw_sv1:
        cmp.b #'=',d0    ;Set equal to
        bne fw_sv2
        move.b (a0)+,d0
        ext d0
        swap d0
        clr d0
        asr.l #4,d0
        move.l d0,(a2)
        bra fw_cmd
fw_sv2:
        cmp.b #'+',d0    ;Add to
        bne fw_sv3
        move.b (a0)+,d0
        and.l #$ff,d0
        swap d0
        lsr.l #4,d0
        add.l d0,(a2)
        bra fw_cmd
fw_sv3:
        cmp.b #'-',d0    ;Subtract from
        bne fw_sv4
        move.b (a0)+,d0
        and.l #$ff,d0
        swap d0
        lsr.l #4,d0
        sub.l d0,(a2)
        bra fw_cmd
fw_sv4:
        bra fw_cmd
          

; *******************************************************************
; score2num
;
; convert the score pointed to by a0 into a long integer in d0
; *******************************************************************
score2num:

        lea 8(a0),a0
        clr.l d0    ;get units out
        clr.l d4
        move #1,d1    ;multiplier
        move #3,d7    ;loop for all digits
s2n:
        move.b -(a0),d2
        and #$0f,d2
        mulu d1,d2
        add.l d2,d0
        mulu #10,d1
        dbra d7,s2n
        move #1,d1
        move #3,d7
s3n:
        move.b -(a0),d2
        and #$0f,d2
        mulu d1,d2
        add.l d2,d4
        mulu #10,d1
        dbra d7,s3n
        mulu #10000,d4
        add.l d4,d0
        rts

; *******************************************************************
; xscoretab
;
; Expand a HS table from the packed data starting at a0.
; *******************************************************************
xscoretab:
        lea hstab1,a1
        lea 80(a0),a3
        move #9,d4  ;do 10 scores
xscore:
        lea 3(a1),a2
        move #59,d1
cccl:
        move.b #' ',(a2)+
        dbra d1,cccl  ;clear out line

        lea 4(a1),a2  ;Point to start.
        cmp #9,d4  ;Is this Score No. 1?
        bne notnoone  ;Nope

        lea -2(a2),a2  ;skip a couple of spaces back

        move #5,d7  ;copy vanity msg
getvain:
        move.b (a3)+,d6
        beq gotvain  ;get until 0
        move.b d6,(a2)+
        dbra d7,getvain
gotvain:
        move.b #' ',(a2)+
;   move.b #' ',(a2)+
        move.b #'(',(a2)+
        lea 4(a0),a3
        move #2,d7
ginits:
        move.b (a3)+,d6
        bne sinsi
        move.b #' ',d6
sinsi:
        move.b d6,(a2)+
        dbra d7,ginits
        move.b #')',(a2)+
        move.b #' ',(a2)+
        bra xxnum

notnoone:
        lea 4(a0),a3
        move #2,d7
ginits1:
        move.b (a3)+,d6
        bne sinsi1
        move.b #' ',d6
sinsi1:
        move.b d6,(a2)+
        dbra d7,ginits1    ;grab initials
        move.b #' ',(a2)+


xxnum:
        lea 7(a2),a4  ;place to expand the number into
        move.l (a0),d0  ;get the number to be expanded

        move.l d0,d2
        divu #10000,d2    ;d2 is highest 4 digits
        and.l #$ffff,d2
        move d2,d3
        mulu #10000,d3
        sub.l d3,d0
        move #3,d3
xscr:
        divu #10,d0
        swap d0
        add.b #'0',d0
        move.b d0,-(a4)
        clr d0
        swap d0
        dbra d3,xscr
xscr2:
         divu #10,d2
        swap d2
        add.b #'0',d2
        move.b d2,-(a4)
        clr d2
        swap d2
        tst d2
        bne xscr2

        lea 9(a2),a2
        move.b #'l',(a2)+
        move.b #'v',(a2)+
        move.b #'l',(a2)+
;  lea 4(a2),a3
        lea linebuff+10,a3

        move.b 7(a0),d0
        and.l #$ff,d0
        add #1,d0
        cmp #99,d0
        ble zokay
        move #99,d0
zokay:
        move #2,d3
xlvl:
        divu #10,d0
        swap d0
;  add.b #'0',d0
        move.b d0,-(a3)
        clr d0
        swap d0
        dbra d3,xlvl

        move #2,d7
        lea 1(a2),a4
animal:
        move.b (a3)+,d0
        bne anima1
        dbra d7,animal

anima1:
        add.b #'0',d0
        move.b d0,(a4)+
        move.b (a3)+,d0
        dbra d7,anima1 
        move.b #0,4(a2)

        lea 8(a0),a0  ;next line of c-table
        lea 64(a1),a1  ;next line of uc-table
        dbra d4,xscore  ;xfer them all
        rts
        
; *******************************************************************
; eepromsave
; Save the EEPROM
; *******************************************************************
eepromsave:
        move #63,d1
        move #$6510,d0
        jsr eewrite  ;$6510 is validation no.

        lea hscom1,a1
        lea epromcopy,a2
        clr d2
        move #57,d1
xxhs1:
        move (a1)+,d0
        add d0,d2
        cmp (a2),d0
        beq unchnged
        move d0,(a2)
        jsr eewrite  ;save the EEPROM
unchnged:
        lea 2(a2),a2
        dbra d1,xxhs1

        move d2,d0
        move #62,d1
        jsr eewrite  ;save checksum
        rts

; *******************************************************************
; eepromload
; Load the EEPROM
; *******************************************************************
eepromload:
        move #63,d1
        jsr eeread
        cmp #$6510,d0
        bne rrts    ;not valid - accept defaults
        lea hscom1,a1
        lea epromcopy,a2
        move #62,d1
        jsr eeread    ;get checksum word
        move d0,d2
        clr d3
        move #57,d1
gghs1:
        jsr eeread
        move d0,(a1)+  ;load the eeprom stuff in
        move d0,(a2)+  ;copy so we only save what changes
        add d0,d3
        dbra d1,gghs1
        cmp d2,d3
        bne zapreset
        rts
zapreset:
        lea defaults,a0    ;reset defaults
        lea hscom1,a1
        move #57,d0
ccrset:
        move (a0)+,(a1)+    ;copy var defaults to ram
        dbra d0,ccrset
        jsr spall      ;(makesure PAL bit is set)
        bra eepromsave

; *******************************************************************
; pager
;
; use text thang to do a page of txt. Pass d0,d1=start pos of first line. Returns 0=text done, 1=more text waiting (a0 poised)
; *******************************************************************
pager:

        lea in_buf,a0
        move.l #linebuff,(a0)    ;Set up texter: address of text $
        move.l #cfont,4(a0)    ;default font
        move.l #0,8(a0)
        move.l #0,12(a0)    ;dropshadow vector
        move.l #$10000,16(a0)
        move.l #$10000,20(a0)    ;text scale
        move.l #0,24(a0)
        move.l #0,28(a0)    ;text shear
        move.l #0,36(a0)
;  bsr g_textlength
nxline:
        bsr g_getline    ;returns length in d6, d7 is flag for text end
        tst d6
        beq nuline
        move d1,d2
        swap d2
        move d0,d2
        move.l d2,32(a0)    ;set text origin
        move.l a0,-(a7)
        lea texter,a0
        jsr gpurun
        jsr gpuwait
        move.l (A7)+,a0
nuline:
        tst d7
        beq rrts      ;d7 0 means text has ended
        add 4(a1),d1
        add #2,d1      ;linefeed
        cmp #2,d7
        bne notbiglf
        add #6,d1      ;bigger LF
notbiglf:
        move #220,d3
        tst pal
        beq palll
        move #250,d3

palll:
         cmp d3,d1    ;btm line of text
        ble nxline
        move #1,d7
        rts

g_getline:
        move.l a5,a2  ;d2.l points to 0term text
        move #0,d7
        move.l 4(a0),a1    ;get font base  
        move 6(a1),d6
        add #2,d6    ;got text width
        lea linebuff,a3
        move d0,d2    ;copy text origin
        move #350,d3
        sub d6,d3    ;maximum text position
g_gtlin:
        move.b (a2)+,d5
        cmp.b #'*',d5
        beq retend    ;found end of the text
        cmp.b #'/',d5
        beq morend    ;return and say more
        cmp.b #'~',d5
        beq morend2    ;use for larger CR/LF gap
        cmp.b #'^',d5
        bne g_gt1
        lea fonties,a1
        move.b (a2)+,d5
        sub.b #'0',d5
        and #$ff,d5
        lsl #2,d5
        move.l 0(a1,d5.w),a1  ;get new font
        bra g_gtlin
g_gt1:
         cmp.b #'>',d5
        bne g_gt2
        move.b (a2)+,d5
        sub.b #'0',d5
        and #$ff,d5
        mulu #10,d5
        move d5,d0
        move.b (a2)+,d5
        sub.b #'0',d5
        add d5,d0
        bra g_gtlin
g_gt2:
        move.b d5,(a3)+    ;copy to line buffer
        add d6,d7
        move d0,d5
        add d7,d5
        cmp d3,d5
        bmi g_gtlin    ;wait till a letter goes too far over
bakkup:
        move.b #0,-(a3)    ;back up till a space
        sub d6,d7
        move.b -(a2),d5
        cmp.b #' ',d5
        bne bakkup
        lea 1(a2),a2    ;skip the space
morend:
        move.l a2,a5
        move d7,d6
        move.b #0,(a3)+
        move #1,d7
        rts
retend:
        move.b #0,(a3)+
        move d7,d6
        clr d7
        rts  
morend2:
        move.l a2,a5
        move d7,d6
        move.b #0,(a3)+
        move #2,d7
        rts

; *******************************************************************
; xkeys
;
; set up OPTION8 according to how many keys there are.
; *******************************************************************
xkeys:

        lea keys,a0
        lea keym1,a1
        lea option8+8,a5
        move #-1,d5
xky:
        move.l a1,a2
        move.b 3(a0),d1    ;get stored level
        beq stetoff
        move.l a1,(a5)+
        move #2,d7
xnam:
        move.b (a0)+,d0
        bne xfacer
        move.b #' ',d0
xfacer:
        move.b d0,(a2)+   
        dbra d7,xnam    ;copy over the initials

        lea linebuff+10,a3
        and.l #$ff,d1
        add #1,d1
        cmp #99,d1
        ble zokay2
        move #99,d1
zokay2:
        move #1,d3
xlvl2:
        divu #10,d1
        swap d1
        move.b d1,-(a3)
        clr d1
        swap d1
        dbra d3,xlvl2

        move #1,d7
        lea 11(a1),a4
animal2:
        move.b (a3)+,d0
        bne nskipzer2
        dbra d7,animal2
        bra azonk
nskipzer2:
        add.b #'0',d0
        move.b d0,(a4)+
        move.b (a3)+,d0
        dbra d7,nskipzer2
azonk:
        lea 20(a1),a1
        lea 1(a0),a0
        add #1,d5
        cmp #3,d5
        blt xky
stetoff:
        move d5,akeys
        move.l #0,(a5)
        rts

; *******************************************************************
; playtune
; Play a tune
; *******************************************************************
playtune:
        jsr STOP_MOD
        lsl #2,d0
        lea modbase,a0
        move.l 0(a0,d0.w),a0  ;get tune base
        jsr PT_MOD_INIT
        move.b vols,d0
        and.l #$ff,d0
        clr d1
        jsr SET_VOLUME
        move.l d0,vset
        jsr NOFADE
        jmp START_MOD

; *******************************************************************
; fox
; Play a selected sound sample.
; *******************************************************************
fox:
        movem.l d0-d3/a0,-(a7)  ;play a SFX sample
        move sfx,d0
        lsl #3,d0
        move d0,d1    ;copy 8x
        lsl #2,d0    ;d0 is 32x...
        add d1,d0    ;d0 is 40x, much faster than mulu
        lea samtab,a0
        lea 20(a0,d0.w),a0  ;point to past FX name...
        move sfx_pri,d1
        move sfx_vol,d2
        move.l sfx_pitch,d3
        jsr PLAYFX2
        move d0,handl
        clr sfx_pri
        clr sfx_vol
        clr.l sfx_pitch
        movem.l (a7)+,d0-d3/a0
        rts

.include "eeprim.s"    ;EEPROM code

*---------  fixed data

; *******************************************************************
; Control string for the firework display
; *******************************************************************
fw_test:dc.b '[x=',0,'y=',$40,'z=',$70,'X=',0,'Y=',-8,'Z=',$10
        dc.b 'd',80,'c',0,'.Y-',2,'c',$88,'.Y-',2,'c',$f0,'.Y+',4,'w',50
        dc.b 'X=',-8,'d',80,'c',$ff,'(',7,'.X!.X!w',20,'X+',1,'-c-c-d)w',30
        dc.b 'x=',$60,'(',4,'Y=',-8,'X=',0,'d',140,'c',0,'.x!.x!Y-',2,'c',$88,'.x!.x!Y-',2,'c',$f0,'.x!.x!Y+',4,'w',20
        dc.b 'X=',-16,'c',$8f,'(',7,'.X!x!.X!x!Y+',4,'.X!x!.X!x!-c-cw',20,'Y-',3,'x-',$10,'X+',2,')x+',$80,'w',20,')'
        dc.b 'Z=',7,'d',80,'x=',$60,'X=',0,'(',5,'Y=',-6,'c',0,'(',5,'.x!.x!+c+c+c+cw',1,'Y-',1,')w',40,'x+',$10,')w',50
        dc.b 'x=',0,'y=',$40,'z=',$70,'(',4,'X=',0,'Y=',-7,'Z=',$10,'d',$a0,'c',$f0,'.w',20,'X+',2,'Y+',1,'c',$88,'.X!.X!w',20
        dc.b 'X+',2,'Y+',1,'c',0,'.X!.X!w',50,')w',50
        dc.b ']'

; *******************************************************************
; Sequence for the rotary controller
; *******************************************************************
conseq: dc.b 0,1,3,2


; *******************************************************************
; Animation sequence for the claw. These data structures are defined
; in obj2d.s
; *******************************************************************
sclaws: dc.l sclaw0,sclaw1,sclaw2,sclaw3,sclaw4,sclaw5,sclaw6,sclaw7
        dc.l gsclaw0,gsclaw1,gsclaw2,gsclaw3,gsclaw4,gsclaw5,gsclaw6,gsclaw7

.phrase

; *******************************************************************
; The tune to use for each web.
; *******************************************************************
webtunes:
        dc.b 5,2,6,7,5,2,6,7

; *******************************************************************
; Unused
; *******************************************************************
testskore:
        dc.b 0,0,6,0,5,0,0,1

; *******************************************************************
; Fonts
; *******************************************************************
fonties:dc.l afont,bfont,cfont

; *******************************************************************
; Speeds on the web?
; *******************************************************************
rospeeds:
        dc.b 2,4,8,8,8,8,8,8


; *******************************************************************
; The definition of each wave
; e.g.
; _nw3:   dc.w 16       ; Duration
;         dc.w 120,0    ; Flippers - Max Time, Index into 'inits' for generation routine.
;         dc.w 0,444,1  ; Flipper Tankers - Sentinel, Max Time, Index into 'inits' for generation routine.
;         dc.w -1       ; End of data sentinel
; *******************************************************************
_nw1:   dc.w 24
        dc.w 120,0    ;Flippers
        dc.w -1

_nw2:  dc.w 24
        dc.w 100,0    ;Flippers
        dc.w -1

_nw3:  dc.w 16
        dc.w 120,0    ;Flippers
        dc.w 0,444,1    ;Flipper Tankers
        dc.w -1    

_nw4:  dc.w 24
        dc.w 80,0    ;Flippers
        dc.w 0,333,1    ;Flipper Tankers
        dc.w 0,800,2    ;Spikers
        dc.w -1  

_nw5:  dc.w 24
        dc.w 100,0    ;Flippers
        dc.w 0,280,1    ;Flipper Tankers
        dc.w 0,800,2    ;Spikers
        dc.w -1

_nw6:  dc.w 30
        dc.w 95,0    ;Flippers
        dc.w 0,260,1    ;Flipper Tankers
        dc.w 0,800,2    ;Spikers
        dc.w -1

_nw7:  dc.w 30
        dc.w 90,0    ;Flippers
        dc.w 0,250,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w -1

_nw8:  dc.w 30
        dc.w 90,0    ;Flippers
        dc.w 0,240,1    ;Flipper Tankers
        dc.w 0,650,2    ;Spikers
        dc.w -1

_nw9:  dc.w 30
        dc.w 85,0    ;Flippers
        dc.w 0,230,1    ;Flipper Tankers
        dc.w 0,600,2    ;Spikers
        dc.w -1

_nw10:  dc.w 30
        dc.w 85,0    ;Flippers
        dc.w 0,240,1    ;Flipper Tankers
        dc.w 0,850,2    ;Spikers
        dc.w 0,2000,10    ;Beasties
        dc.w -1

_nw11:  dc.w 30
        dc.w 85,0    ;Flippers
        dc.w 0,270,1    ;Flipper Tankers
        dc.w 0,850,2    ;Spikers
        dc.w 0,1000,3    ;Fuseballs
        dc.w 0,2000,10    ;Beasties
        dc.w -1

_nw12:  dc.w 30
        dc.w 80,0    ;Flippers
        dc.w 0,270,1    ;Flipper Tankers
        dc.w 0,850,2    ;Spikers
        dc.w 0,2000,10    ;Beasties
        dc.w 0,700,3    ;Fuseballs
        dc.w -1

_nw13:  dc.w 30
        dc.w 80,0    ;Flippers
        dc.w 0,270,1    ;Flipper Tankers
        dc.w 0,2000,10    ;Beasties
        dc.w 0,750,2    ;Spikers
        dc.w 0,600,3    ;Fuseballs
        dc.w -1

_nw14:  dc.w 30
        dc.w 75,0    ;Flippers
        dc.w 0,270,1    ;Flipper Tankers
        dc.w 0,2000,10    ;Beasties
        dc.w 0,750,2    ;Spikers
        dc.w 0,600,3    ;Fuseballs
        dc.w -1

_nw15:  dc.w 30
        dc.w 75,0    ;Flippers
        dc.w 0,270,1    ;Flipper Tankers
        dc.w 0,2000,10    ;Beasties
        dc.w 0,750,2    ;Spikers
        dc.w 0,500,3    ;Fuseballs
        dc.w -1

_nw16:  dc.w 40
        dc.w 70,0    ;Flippers
        dc.w 0,230,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,2000,10    ;Beasties
        dc.w 0,500,3    ;Fuseballs
        dc.w -1

_nw17:  dc.w 24
        dc.w 120,0    ;Flippers
        dc.w 0,600,4    ;Pulsars
        dc.w 0,750,2    ;Spikers
        dc.w 0,1000,10    ;Beasties
        dc.w 0,900,3    ;Fuseballs
        dc.w -1

_nw18:  dc.w 30
        dc.w 100,0    ;Flippers
        dc.w 0,500,4    ;Pulsars
        dc.w 0,750,2    ;Spikers
        dc.w 0,1000,10    ;Beasties
        dc.w 0,900,3    ;Fuseballs
        dc.w -1

_nw19:  dc.w 30
        dc.w 120,0    ;Flippers
        dc.w 0,444,1    ;Flipper Tankers
        dc.w 0,600,4    ;Pulsars
        dc.w 0,1000,10    ;Beasties
        dc.w 0,750,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w -1    

_nw20:  dc.w 32
        dc.w 80,0    ;Flippers
        dc.w 0,333,1    ;Flipper Tankers
        dc.w 0,500,4    ;Pulsars
        dc.w 0,1000,10    ;Beasties
        dc.w 0,750,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w -1  

_nw21:  dc.w 32
        dc.w 100,0    ;Flippers
        dc.w 0,280,1    ;Flipper Tankers
        dc.w 0,800,2    ;Spikers
        dc.w 0,1000,10    ;Beasties
        dc.w 0,432,4    ;Pulsars
        dc.w 0,900,3    ;Fuseballs
        dc.w -1

_nw22:  dc.w 35
        dc.w 95,0    ;Flippers
        dc.w 0,260,1    ;Flipper Tankers
        dc.w 0,800,2    ;Spikers
        dc.w 0,1000,10    ;Beasties
        dc.w 0,425,4    ;Pulsars
        dc.w 0,900,3    ;Fuseballs
        dc.w -1

_nw23:  dc.w 35
        dc.w 90,0    ;Flippers
        dc.w 0,250,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,1000,10    ;Beasties
        dc.w 0,462,4    ;Pulsars
        dc.w 0,900,3    ;Fuseballs
        dc.w -1

_nw24:  dc.w 35
        dc.w 90,0    ;Flippers
        dc.w 0,240,1    ;Flipper Tankers
        dc.w 0,650,2    ;Spikers
        dc.w 0,1000,10    ;Beasties
        dc.w 0,411,4    ;Pulsars
        dc.w 0,900,3    ;Fuseballs
        dc.w -1

_nw25:  dc.w 40
        dc.w 85,0    ;Flippers
        dc.w 0,230,1    ;Flipper Tankers
        dc.w 0,600,2    ;Spikers
        dc.w 0,560,4    ;Pulsars
        dc.w 0,1000,10    ;Beasties
        dc.w 0,700,3    ;Fuseballs
        dc.w 0,2000,5    ;Fuseball Tankers
        dc.w -1  

_nw26:  dc.w 40
        dc.w 85,0    ;Flippers
        dc.w 0,240,1    ;Flipper Tankers
        dc.w 0,850,2    ;Spikers
        dc.w 0,1000,10    ;Beasties
        dc.w 0,399,4    ;Pulsars
        dc.w 0,700,3    ;Fuseballs
        dc.w 0,2000,5
        dc.w -1

_nw27:  dc.w 40
        dc.w 85,0    ;Flippers
        dc.w 0,370,1    ;Flipper Tankers
        dc.w 0,850,2    ;Spikers
        dc.w 0,1000,10    ;Beasties
        dc.w 0,1000,3    ;Fuseballs
        dc.w 0,388,4    ;Pulsars
        dc.w 0,2000,5    ;Fuseball Tankers
        dc.w -1

_nw28:  dc.w 40
        dc.w 80,0    ;Flippers
        dc.w 0,370,1    ;Flipper Tankers
        dc.w 0,850,2    ;Spikers
        dc.w 0,700,3    ;Fuseballs
        dc.w 0,1000,10    ;Beasties
        dc.w 0,377,4    ;Pulsars
        dc.w 0,2000,5    ;Fuseball Tankers
        dc.w -1

_nw29:  dc.w 40
        dc.w 80,0    ;Flippers
        dc.w 0,470,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,1000,10    ;Beasties
        dc.w 0,366,4    ;Pulsars
        dc.w 0,2000,5    ;Fuseball Tankers
        dc.w -1

_nw30:  dc.w 40
        dc.w 75,0    ;Flippers
        dc.w 0,470,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,1000,10    ;Beasties
        dc.w 0,350,4    ;Pulsars
        dc.w 0,1000,5    ;Fuseball Tankers
        dc.w -1

_nw31:  dc.w 40
        dc.w 95,0    ;Flippers
        dc.w 0,470,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,1000,10    ;Beasties
        dc.w 0,350,4    ;Pulsars
        dc.w 0,1000,5    ;Fuseball Tankers
        dc.w -1

_nw32:  dc.w 40
        dc.w 90,0    ;Flippers
        dc.w 0,430,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,500,3    ;Fuseballs
        dc.w 0,1000,10    ;Beasties
        dc.w 0,900,4    ;Pulsars
        dc.w 0,500,5    ;Fuseball Tankers
        dc.w -1


_nw33:  dc.w 24
        dc.w 100,0    ;Flippers
        dc.w 0,750,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,500,6    ;Pulsar Tankers
        dc.w 0,700,10    ;Beasties
        dc.w -1

_nw34:  dc.w 30
        dc.w 100,0    ;Flippers
        dc.w 0,750,2    ;Spikers
        dc.w 0,700,10    ;Beasties
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w 0,900,3    ;Fuseballs
        dc.w -1

_nw35:  dc.w 30
        dc.w 120,0    ;Flippers
        dc.w 0,444,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,700,10    ;Beasties
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w -1    

_nw36:  dc.w 32
        dc.w 80,0    ;Flippers
        dc.w 0,333,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,700,10    ;Beasties
        dc.w 0,950,3    ;Fuseballs
        dc.w 0,400,6    ;Pulsar Tankers
        dc.w -1  

_nw37:  dc.w 32
        dc.w 100,0    ;Flippers
        dc.w 0,280,1    ;Flipper Tankers
        dc.w 0,800,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,700,10    ;Beasties
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w -1

_nw38:  dc.w 35
        dc.w 95,0    ;Flippers
        dc.w 0,260,1    ;Flipper Tankers
        dc.w 0,800,2    ;Spikers
        dc.w 0,700,10    ;Beasties
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w -1

_nw39:  dc.w 35
        dc.w 90,0    ;Flippers
        dc.w 0,250,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,700,10    ;Beasties
        dc.w 0,400,6    ;Pulsar Tankers
        dc.w -1

_nw40:  dc.w 35
        dc.w 90,0    ;Flippers
        dc.w 0,240,1    ;Flipper Tankers
        dc.w 0,650,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,700,10    ;Beasties
        dc.w 0,350,6    ;Pulsar Tankers
        dc.w -1

_nw41:  dc.w 40
        dc.w 85,0    ;Flippers
        dc.w 0,230,1    ;Flipper Tankers
        dc.w 0,600,2    ;Spikers
        dc.w 0,1100,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w 0,700,3    ;Fuseballs
        dc.w 0,800,5    ;Fuseball Tankers
        dc.w 0,350,6    ;Pulsar Tankers
        dc.w -1  

_nw42:  dc.w 40
        dc.w 85,0    ;Flippers
        dc.w 0,240,1    ;Flipper Tankers
        dc.w 0,850,2    ;Spikers
        dc.w 0,1100,4    ;Pulsars
        dc.w 0,700,10    ;Beasties
        dc.w 0,700,3    ;Fuseballs
        dc.w 0,350,6    ;Pulsar Tankers
        dc.w 0,2000,5
        dc.w -1

_nw43:  dc.w 40
        dc.w 85,0    ;Flippers
        dc.w 0,270,1    ;Flipper Tankers
        dc.w 0,850,2    ;Spikers
        dc.w 0,400,3    ;Fuseballs
        dc.w 0,1100,4    ;Pulsars
        dc.w 0,500,6    ;Pulsar Tankers
        dc.w 0,700,10    ;Beasties
        dc.w 0,300,5    ;Fuseball Tankers
        dc.w -1

_nw44:  dc.w 40
        dc.w 80,0    ;Flippers
        dc.w 0,270,1    ;Flipper Tankers
        dc.w 0,850,2    ;Spikers
        dc.w 0,700,3    ;Fuseballs
        dc.w 0,700,10    ;Beasties
        dc.w 0,500,4    ;Pulsars
        dc.w 0,500,6    ;Pulsar Tankers
        dc.w 0,300,5    ;Fuseball Tankers
        dc.w -1

_nw45:  dc.w 40
        dc.w 80,0    ;Flippers
        dc.w 0,270,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,700,10    ;Beasties
        dc.w 0,1000,4    ;Pulsars
        dc.w 0,300,6    ;Pulsar Tankers
        dc.w 0,800,5    ;Fuseball Tankers
        dc.w -1

_nw46:  dc.w 40
        dc.w 75,0    ;Flippers
        dc.w 0,270,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,700,10    ;Beasties
        dc.w 0,1000,4    ;Pulsars
        dc.w 0,300,6    ;Pulsar Tankers
        dc.w 0,800,5    ;Fuseball Tankers
        dc.w -1

_nw47:  dc.w 40
        dc.w 95,0    ;Flippers
        dc.w 0,270,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,700,10    ;Beasties
        dc.w 0,350,4    ;Pulsars
        dc.w 0,300,6    ;Pulsar Tankers
        dc.w 0,800,5    ;Fuseball Tankers
        dc.w -1

_nw48:  dc.w 40
        dc.w 90,0    ;Flippers
        dc.w 0,230,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,700,10    ;Beasties
        dc.w 0,500,3    ;Fuseballs
        dc.w 0,900,4    ;Pulsars
        dc.w 0,300,6    ;Pulsar Tankers
        dc.w 0,400,5    ;Fuseball Tankers
        dc.w -1

_nw49:  dc.w 16
        dc.w 140,10    ;Beasties!
        dc.w -1

_nw50:  dc.w 40
        dc.w 50,0    ;Flippers
        dc.w 0,750,2    ;Spikers
        dc.w 0,500,10    ;Beasties
        dc.w 0,900,3    ;Fuseballs
        dc.w -1

_nw51:  dc.w 45
        dc.w 50,0    ;Flippers
        dc.w 0,750,2    ;Spikers
        dc.w 0,500,10    ;Beasties
        dc.w 0,950,6    ;Pulsar Tankers
        dc.w -1    

_nw52:  dc.w 50
        dc.w 50,0    ;Flippers
        dc.w 0,750,2    ;Spikers
        dc.w 0,950,3    ;Fuseballs
        dc.w 0,300,10    ;Beasties
        dc.w -1  

_nw53:  dc.w 50
        dc.w 50,0    ;Flippers
        dc.w 0,280,1    ;Flipper Tankers
        dc.w 0,800,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,200,10    ;Beasties
        dc.w -1

_nw54:  dc.w 50
        dc.w 50,0    ;Flippers
        dc.w 0,260,1    ;Flipper Tankers
        dc.w 0,800,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,100,10    ;Beasties
        dc.w -1

_nw55:  dc.w 50
        dc.w 50,0    ;Flippers
        dc.w 0,250,1    ;Flipper Tankers
        dc.w 0,750,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,100,10    ;Beasties
        dc.w -1

_nw56:  dc.w 50
        dc.w 50,0    ;Flippers
        dc.w 0,240,1    ;Flipper Tankers
        dc.w 0,650,2    ;Spikers
        dc.w 0,900,3    ;Fuseballs
        dc.w 0,100,10    ;Beasties
        dc.w -1

;_nw1:
_nw57:  dc.w 60
        dc.w 25,7    ;SFlip2
        dc.w 0,400,8    ;Mirror
        dc.w -1  

_nw58:  dc.w 40
        dc.w 50,2    ;Flippers
        dc.w 0,400,8    ;Mirror
        dc.w 0,151,4    ;Pulsars
        dc.w -1

_nw59:  dc.w 40
        dc.w 50,2    ;Flippers
        dc.w 0,400,8    ;Mirror
        dc.w 0,151,4    ;Pulsars
        dc.w 0,523,3    ;Fuseballs
        dc.w -1

_nw60:  dc.w 50
        dc.w 50,2    ;Flippers
        dc.w 0,400,8    ;Mirror
        dc.w 0,151,4    ;Pulsars
        dc.w 0,523,3    ;Fuseballs
        dc.w 0,1500,2    ;Spikers
        dc.w -1

_nw61:  dc.w 50
        dc.w 50,2    ;Flippers
        dc.w 0,400,8    ;Mirror
        dc.w 0,151,4    ;Pulsars
        dc.w 0,523,3    ;Fuseballs
        dc.w 0,1500,2    ;Spikers
        dc.w -1

_nw62:  dc.w 50
        dc.w 50,2    ;Flippers
        dc.w 0,400,8    ;Mirror
        dc.w 0,351,6    ;Pulsar Tankers
        dc.w 0,523,3    ;Fuseballs
        dc.w 0,1500,2    ;Spikers
        dc.w -1

_nw63:  dc.w 50
        dc.w 50,2    ;Flippers
        dc.w 0,400,8    ;Mirror
        dc.w 0,251,6    ;Pulsar Tankers
        dc.w 0,523,3    ;Fuseballs
        dc.w 0,1500,2    ;Spikers
        dc.w -1

_nw64:  dc.w 50
        dc.w 30,4    ;Pulsars
        dc.w 0,400,10    ;Beasties
        dc.w -1

_nw65:  dc.w 60
        dc.w 20,7    ;Beasties!
        dc.w 0,700,9    ;Adroids
        dc.w -1

_nw66:  dc.w 60
        dc.w 40,7    ;Flippers3
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w -1

_nw67:  dc.w 60
        dc.w 40,7    ;Flippers3
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,3    ;Fuseballs
        dc.w -1

_nw68:  dc.w 60
        dc.w 40,7    ;Flippers3
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,3    ;Fuseballs
        dc.w -1

_nw69:  dc.w 60
        dc.w 40,7    ;Flippers3
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,6    ;Pulsar Tankers
        dc.w -1

_nw70:  dc.w 60
        dc.w 70,6    ;Pulsar Tankers
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,300,3    ;Fuseballs
        dc.w -1

_nw71:  dc.w 60
        dc.w 70,6    ;Pulsar Tankers
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,10    ;Beasties
        dc.w -1

_nw72:  dc.w 60
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,2    ;Spikers
        dc.w -1

_nw73:  dc.w 60
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,2    ;Spikers
        dc.w 0,300,3    ;Fuseballs
        dc.w -1

_nw74:  dc.w 60
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,2    ;Spikers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w -1

_nw75:  dc.w 60
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,2    ;Spikers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,700,1    ;flip tanker
        dc.w -1

_nw76:  dc.w 60
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,2    ;Spikers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,700,1    ;flip tanker
        dc.w 0,300,4    ;Pulsars
        dc.w -1

_nw77:  dc.w 60
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,2    ;Spikers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,700,1    ;flip tanker
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w -1

_nw78:  dc.w 60
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,2    ;Spikers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,700,1    ;flip tanker
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w -1

_nw79:  dc.w 60
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,2    ;Spikers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,700,1    ;flip tanker
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw80:  dc.w 60
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,700,1    ;flip tanker
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw81:  dc.w 60
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,600,9    ;Adroids
        dc.w 0,500,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,700,1    ;flip tanker
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw82:  dc.w 60
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,500,9    ;Adroids
        dc.w 0,500,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,500,1    ;flip tanker
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw83:  dc.w 60
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,500,9    ;Adroids
        dc.w 0,500,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,500,1    ;flip tanker
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw84:  dc.w 60
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,500,9    ;Adroids
        dc.w 0,500,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,500,1    ;flip tanker
        dc.w 0,523,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1


_nw85:  dc.w 70
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,500,9    ;Adroids
        dc.w 0,500,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,500,1    ;flip tanker
        dc.w 0,523,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw86:  dc.w 70
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,400,9    ;Adroids
        dc.w 0,500,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,500,1    ;flip tanker
        dc.w 0,523,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw87:  dc.w 70
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,400,9    ;Adroids
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,500,1    ;flip tanker
        dc.w 0,523,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw88:  dc.w 70
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,400,9    ;Adroids
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,500,1    ;flip tanker
        dc.w 0,523,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw89:  dc.w 70
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,400,9    ;Adroids
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,300,1    ;flip tanker
        dc.w 0,523,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw90:  dc.w 80
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,400,9    ;Adroids
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,400,11    ;flip3
        dc.w 0,300,1    ;flip tanker
        dc.w 0,523,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw91:  dc.w 80
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,400,9    ;Adroids
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,350,11    ;flip3
        dc.w 0,300,1    ;flip tanker
        dc.w 0,523,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw92:  dc.w 80
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,400,9    ;Adroids
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,350,11    ;flip3
        dc.w 0,250,1    ;flip tanker
        dc.w 0,523,5    ;Fuseball Tanker
        dc.w 0,300,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw93:  dc.w 80
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,400,9    ;Adroids
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,350,11    ;flip3
        dc.w 0,250,1    ;flip tanker
        dc.w 0,523,5    ;Fuseball Tanker
        dc.w 0,100,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw94:  dc.w 80
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,400,9    ;Adroids
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,350,11    ;flip3
        dc.w 0,250,1    ;flip tanker
        dc.w 0,523,5    ;Fuseball Tanker
        dc.w 0,100,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw95:  dc.w 80
        dc.w 20,7    ;flip2
        dc.w 0,750,8    ;Mirrors
        dc.w 0,200,9    ;Adroids
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,350,11    ;flip3
        dc.w 0,250,1    ;flip tanker
        dc.w 0,523,5    ;Fuseball Tanker
        dc.w 0,100,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw96:  dc.w 90
        dc.w 20,7    ;flip2
        dc.w 0,350,8    ;Mirrors
        dc.w 0,200,9    ;Adroids
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,350,11    ;flip3
        dc.w 0,250,1    ;flip tanker
        dc.w 0,523,5    ;Fuseball Tanker
        dc.w 0,100,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw97:  dc.w 90
        dc.w 20,7    ;flip2
        dc.w 0,350,8    ;Mirrors
        dc.w 0,200,9    ;Adroids
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,350,11    ;flip3
        dc.w 0,250,1    ;flip tanker
        dc.w 0,423,5    ;Fuseball Tanker
        dc.w 0,100,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw98:  dc.w 90
        dc.w 20,7    ;flip2
        dc.w 0,350,8    ;Mirrors
        dc.w 0,200,9    ;Adroids
        dc.w 0,450,6    ;Pulsar Tankers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,350,11    ;flip3
        dc.w 0,250,1    ;flip tanker
        dc.w 0,323,5    ;Fuseball Tanker
        dc.w 0,100,4    ;Pulsars
        dc.w 0,800,10    ;Beasties
        dc.w -1

_nw99:
; dc.w 90
;  dc.w 20,7    ;flip2
;  dc.w 0,350,8    ;Mirrors
;  dc.w 0,200,9    ;Adroids
;  dc.w 0,450,6    ;Pulsar Tankers
;  dc.w 0,300,3    ;Fuseballs
;  dc.w 0,350,11    ;flip3
;  dc.w 0,250,1    ;flip tanker
;  dc.w 0,423,5    ;Fuseball Tanker
;  dc.w 0,100,4    ;Pulsars
;  dc.w 0,500,10    ;Beasties
;  dc.w -1

_nw100: dc.w 100
        dc.w 20,7    ;flip2
        dc.w 0,100,10    ;Beasties
        dc.w -1


; *******************************************************************
; A list of all waves in the order in which they occur, using the wave
; data structures defined above.
; *******************************************************************
waves:
        dc.l _nw1,_nw2,_nw3,_nw4,_nw5,_nw6,_nw7,_nw8,_nw9,_nw10,_nw11,_nw12,_nw13,_nw14,_nw15,_nw16
        dc.l _nw17,_nw18,_nw19,_nw20,_nw21,_nw22,_nw23,_nw24,_nw25,_nw26,_nw27,_nw28,_nw29,_nw30,_nw31,_nw32
        dc.l _nw33,_nw34,_nw35,_nw36,_nw37,_nw38,_nw39,_nw40,_nw41,_nw42,_nw43,_nw44,_nw45,_nw46,_nw47,_nw48
        dc.l _nw49,_nw50,_nw51,_nw52,_nw53,_nw54,_nw55,_nw56,_nw57,_nw58,_nw59,_nw60,_nw61,_nw62,_nw63,_nw64
        dc.l _nw65,_nw66,_nw67,_nw68,_nw69,_nw70,_nw71,_nw72,_nw73,_nw74,_nw75,_nw76,_nw77,_nw78,_nw79,_nw80
        dc.l _nw81,_nw82,_nw83,_nw84,_nw85,_nw86,_nw87,_nw88,_nw89,_nw90,_nw91,_nw92,_nw93,_nw94,_nw95,_nw96
        dc.l _nw97,_nw98,_nw99,_nw100,_nw85,_nw86,_nw87,_nw88,_nw89,_nw90,_nw91,_nw92,_nw93,_nw94,_nw95,_nw96
        dc.l 0


; *******************************************************************
; A list of all waves for traditional Tempest.
; *******************************************************************
tradmax: dc.l _tm1,_tm2,_tm3,_tm4,_tm5,_tm6,_tm7,_tm8,_tm9,_tm10,_tm11,_tm12,_tm13,_tm14,_tm15,_tm16

; *******************************************************************
; The definition of each wave for traditional/classic Tempest
; e.g.
; _nw3:   dc.w 16       ; Duration
;         dc.w 120,0    ; Flippers - Max Time, Index into 'inits' for generation routine.
;         dc.w 0,444,1  ; Flipper Tankers - Sentinel, Max Time, Index into 'inits' for generation routine.
;         dc.w -1       ; End of data sentinel
; *******************************************************************
_tm1:   dc.w 40
        dc.w 50,0    ;Flippers
        dc.w 0,450,2    ;Spikers
        dc.w 0,700,3    ;Fuseballs
        dc.w 0,300,6    ;Pulsar Tankers
        dc.w -1

_tm2:   dc.w 40
        dc.w 50,0    ;Flippers
        dc.w 0,450,2    ;Spikers
        dc.w 0,700,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w -1

_tm3:   dc.w 50
        dc.w 40,0    ;Flippers
        dc.w 0,444,1    ;Flipper Tankers
        dc.w 0,450,2    ;Spikers
        dc.w 0,700,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w -1

_tm4:   dc.w 50
        dc.w 40,0    ;Flippers
        dc.w 0,444,1    ;Flipper Tankers
        dc.w 0,450,2    ;Spikers
        dc.w 0,500,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w -1

_tm5:   dc.w 60
        dc.w 40,0    ;Flippers
        dc.w 0,444,1    ;Flipper Tankers
        dc.w 0,450,2    ;Spikers
        dc.w 0,500,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w -1


_tm6:   dc.w 60
        dc.w 30,0    ;Flippers
        dc.w 0,444,1    ;Flipper Tankers
        dc.w 0,450,2    ;Spikers
        dc.w 0,500,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w -1

_tm7:   dc.w 60
        dc.w 30,0    ;Flippers
        dc.w 0,444,1    ;Flipper Tankers
        dc.w 0,450,2    ;Spikers
        dc.w 0,500,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w -1

_tm8:   dc.w 60
        dc.w 30,0    ;Flippers
        dc.w 0,444,1    ;Flipper Tankers
        dc.w 0,450,2    ;Spikers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w -1

_tm9:   dc.w 60
        dc.w 30,0    ;Flippers
        dc.w 0,444,1    ;Flipper Tankers
        dc.w 0,450,2    ;Spikers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w -1

_tm10:  dc.w 60
        dc.w 30,0    ;Flippers
        dc.w 0,444,1    ;Flipper Tankers
        dc.w 0,450,2    ;Spikers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w 0,151,4    ;Pulsars
        dc.w -1

_tm11:  dc.w 60
        dc.w 30,0    ;Flippers
        dc.w 0,344,1    ;Flipper Tankers
        dc.w 0,450,2    ;Spikers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w 0,151,4    ;Pulsars
        dc.w -1

_tm12:  dc.w 65
        dc.w 30,0    ;Flippers
        dc.w 0,344,1    ;Flipper Tankers
        dc.w 0,450,2    ;Spikers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w 0,151,4    ;Pulsars
        dc.w -1

_tm13:  dc.w 60
        dc.w 30,0    ;Flippers
        dc.w 0,344,1    ;Flipper Tankers
        dc.w 0,450,2    ;Spikers
        dc.w 0,300,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w 0,151,4    ;Pulsars
        dc.w -1

_tm14:  dc.w 60
        dc.w 30,0    ;Flippers
        dc.w 0,244,1    ;Flipper Tankers
        dc.w 0,350,2    ;Spikers
        dc.w 0,200,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w 0,151,4    ;Pulsars
        dc.w -1

_tm15:  dc.w 60
        dc.w 30,0    ;Flippers
        dc.w 0,244,1    ;Flipper Tankers
        dc.w 0,350,2    ;Spikers
        dc.w 0,200,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w 0,623,5    ;Fuseball Tanker
        dc.w 0,151,4    ;Pulsars
        dc.w -1

_tm16:  dc.w 80
        dc.w 30,0    ;Flippers
        dc.w 0,244,1    ;Flipper Tankers
        dc.w 0,350,2    ;Spikers
        dc.w 0,200,3    ;Fuseballs
        dc.w 0,250,6    ;Pulsar Tankers
        dc.w 0,423,5    ;Fuseball Tanker
        dc.w 0,111,4    ;Pulsars
        dc.w -1


; *******************************************************************
; The webs to use for head-to-head mode.
; Each of these is an index into raw_webs
; *******************************************************************
h2hwebs:dc.b 1,2,5,10,12,13,15,23,29,32,34,35,37,44,47,48

; *******************************************************************
; 
; *******************************************************************
h2hlevs:dc.w $1010,-1
        dc.w $0c0c,-1
        dc.w $0c0c,0
        dc.w $0808,0
        dc.w $0404,-1
        dc.w -1,3
        dc.w $0c0c,1
        dc.w $0a0a,1
        dc.w $0c0c,2
        dc.w $0a0a,2
        dc.w $0808,2
        dc.w $0c0c,2
        dc.w -1,4
        dc.w $0202,0
        dc.w $0404,1
        dc.w $0,-1


; *******************************************************************
; Vertex list describing a cube.
; *******************************************************************
cube:   dc.b 1,1,1,2,3,5,0
        dc.b 3,1,1,6,4,0
        dc.b 1,3,1,4,7,0
        dc.b 3,3,1,0    ;was 1,6,0
        dc.b 1,1,3,0    ;was 3,3,0
        dc.b 3,1,3,5,0
        dc.b 1,3,3,5,0
        dc.b 3,3,3,4,6,7,0
        dc.b 0



; *******************************************************************
; Vertices for the classic claw shape?
; *******************************************************************
claw1:  dc.b 6,4,1,2,8,0
        dc.b 3,9,1,3,0
        dc.b 9,12,1,4,0
        dc.b 15,9,1,5,0
        dc.b 12,4,1,6,0
        dc.b 17,9,1,7,0
        dc.b 9,15,1,8,0
        dc.b 1,9,1,0,0

claw2:  dc.b 5,4,1,2,8,0
        dc.b 3,10,1,3,0
        dc.b 10,12,1,4,0
        dc.b 15,9,1,5,0
        dc.b 12,4,1,6,0
        dc.b 17,9,1,7,0
        dc.b 10,15,1,8,0
        dc.b 1,10,1,0,0

claw3:  dc.b 4,5,1,2,8,0
        dc.b 4,11,1,3,0
        dc.b 11,12,1,4,0
        dc.b 15,8,1,5,0
        dc.b 12,4,1,6,0
        dc.b 17,8,1,7,0
        dc.b 11,15,1,8,0
        dc.b 2,12,1,0,0

claw4:  dc.b 4,6,1,2,8,0
        dc.b 5,12,1,3,0
        dc.b 11,13,1,4,0
        dc.b 15,8,1,5,0
        dc.b 11,3,1,6,0
        dc.b 17,7,1,7,0
        dc.b 12,16,1,8,0
        dc.b 3,13,1,0,0

claw5:  dc.b 3,8,1,2,8,0
        dc.b 6,13,1,3,0
        dc.b 12,13,1,4,0
        dc.b 15,7,1,5,0
        dc.b 11,3,1,6,0
        dc.b 17,6,1,7,0
        dc.b 13,16,1,8,0
        dc.b 4,14,1,0,0

claw6:  dc.b 3,9,1,2,8,0
        dc.b 7,13,1,3,0
        dc.b 13,13,1,4,0
        dc.b 15,6,1,5,0
        dc.b 10,3,1,6,0
        dc.b 17,5,1,7,0
        dc.b 15,16,1,8,0
        dc.b 6,15,1,0,0

claw7:  dc.b 4,11,1,2,8,0
        dc.b 10,14,1,3,0
        dc.b 14,13,1,4,0
        dc.b 15,6,1,5,0
        dc.b 10,3,1,6,0
        dc.b 17,4,1,7,0
        dc.b 16,15,1,8,0
        dc.b 10,16,1,0,0

claw8:  dc.b 5,14,1,2,8,0
        dc.b 11,14,1,3,0
        dc.b 14,12,1,4,0
        dc.b 15,6,1,5,0
        dc.b 9,3,1,6,0
        dc.b 16,4,1,7,0
        dc.b 17,13,1,8,0
        dc.b 11,16,1,0,0

t_test: dc.b 1,4,1,2,0
        dc.b 9,4,1,0
        dc.b 5,4,1,4,0
        dc.b 5,4,20,0,0

test:   dc.b 1,1,1,2,3,0
        dc.b 1,3,3,0
        dc.b 3,1,1,4,0
        dc.b 3,1,3,5,0
        dc.b 3,3,1,0,0

        dc.b 1,3,1,6,0
        dc.b 1,3,3,0
        dc.b 3,3,1,8,0
        dc.b 3,3,3,0
        dc.b 0

tetra:  dc.b 2,1,1,2,3,4,0
        dc.b 1,2,1,3,4,0
        dc.b 3,3,1,4,0
        dc.b 2,2,3,0
        dc.b 0

; *******************************************************************
; An unused vector list giving the 'Tempest' title screen.
; *******************************************************************
tempest:dc.b 1,1,1,2,0
        dc.b 5,1,1,0
        dc.b 3,1,1,4,0
        dc.b 3,5,1,0

        dc.b 7,1,1,6,9,0
        dc.b 11,1,1,0
        dc.b 7,3,1,8,0
        dc.b 9,3,1,0
        dc.b 7,5,1,10,0
        dc.b 11,5,1,0

        dc.b 13,5,1,12,0
        dc.b 13,1,1,13,0
        dc.b 15,3,1,14,0
        dc.b 17,1,1,15,0
        dc.b 17,5,1,0

        dc.b 19,5,1,17,0
        dc.b 19,1,1,18,0
        dc.b 21,1,1,19,0
        dc.b 22,2,1,20,0
        dc.b 21,3,1,21,0
        dc.b 19,3,1,0

        dc.b 28,1,1,23,0
        dc.b 24,1,1,26,0
        dc.b 24,3,1,25,0
        dc.b 26,3,1,0
        dc.b 24,5,1,27,0
        dc.b 28,5,1,0

        dc.b 30,5,1,29,0
        dc.b 32,5,1,30,0
        dc.b 33,4,1,31,0
        dc.b 32,3,1,32,0
        dc.b 31,3,1,33,0
        dc.b 30,2,1,34,0
        dc.b 31,1,1,35,0
        dc.b 33,1,1,0

        dc.b 35,1,1,37,0
        dc.b 39,1,1,0
        dc.b 37,1,1,39,0
        dc.b 37,5,1,0
        dc.b 0

; *******************************************************************
; The vertex lists that define each web.
; *******************************************************************
web1:   dc.w 11,5
        dc.w -3,16,-1,16,1,16,3,16,5,16    ;flat plane
        dc.w 7,16,9,16,11,16,13,16
        dc.w 15,16,17,16,19,16,-3,16,0

        dc.w 0,0,0,0,0,0,0,0,0,0,0  ;orientation table (angle of an object within a particular lane)
        dc.w $80,$70,$60,$50,$40,$30,$32,$34,$36,$48,$5a

web2:   dc.w 15,7
        dc.w 1,1,2,3,3,5,4,7    ;v
        dc.w 5,9,6,11,7,13,8,15
        dc.w 10,15,11,13,12,11,13,9
        dc.w 14,7,15,5,16,3,17,1,1,1,0

        dc.w 48,48,48,48,48,48,48,0,-48,-48,-48,-48,-48,-48,-48
        dc.w 0,$10,$20,$30,$40,$50,$60,$70,$60,$50,$40,$30,$20,$10,0

web3:   dc.w 15,7
        dc.w 1,1,1,3,1,5,1,7    ;u
        dc.w 2,9,4,11,6,12,8,12
        dc.w 10,12,12,12,14,11,16,9
        dc.w 17,7,17,5,17,3,17,1,1,1,0

        dc.w 64,64,64,48,32,16,0,0,0,-16,-32,-48,-64,-64,-64  ;orientation table (angle of an object within a particular lane)
        dc.w 0,$10,$20,$30,$40,$50,$60,$70,$60,$50,$40,$30,$20,$10,0


web4:   dc.w 15,7
        dc.w 8,6,7,4,5,5,4,7    ;clover
        dc.w 6,8,4,9,5,11,7,12
        dc.w 8,10,9,12,11,11,12,9
        dc.w 10,8,12,7,11,5,9,4,8,6,-1

        dc.w -80,112,80,16,112,48,16,-48,48,-16,-48,-112,-16,-80,-112,80  ;orientation table (angle of an object within a particular lane)
        dc.w $0,$70,$10,$60,$20,$50,$30,$40,$40,$30,$50,$20,$60,$10,$70,0

web5:   dc.w 15,7
        dc.w 7,2,5,3,3,5,2,7    ;circle
        dc.w 2,9,3,11,5,13,7,14
        dc.w 9,14,11,13,13,11,14,9
        dc.w 14,7,13,5,11,3,9,2,7,2,-1

        dc.w 112,96,80,64,48,32,16,0,-16,-32,-48,-64,-80,-96,-112,-128  ;orientation table (angle of an object within a particular lane)
        dc.w 0,$01,$02,$03,$04,$05,$06,07,$07,$6,$05,$04,$03,$02,$01,0

web6:   dc.w 15,6
        dc.w 1,3,2,5,3,7,4,9    ;distorted w
        dc.w 5,11,6,13,7,15,9,15
        dc.w 10,13,11,11,13,11,14,9
        dc.w 15,7,16,5,17,3,18,1,1,3,0

        dc.w 48,48,48,48,48,48,0,-48,-48,0,-48,-48,-48,-48,-48  ;orientation table (angle of an object within a particular lane)
        dc.w 0,$10,$20,$30,$40,$50,$60,$70,$60,$50,$40,$30,$20,$10,0

web7:   dc.w 15,7
        dc.w 7,6,5,5,3,5,1,7    ;dumb-bell
        dc.w 1,9,3,11,5,11,7,10
        dc.w 9,10,11,11,13,11,15,9
        dc.w 15,7,13,5,11,5,9,6,7,6,-1

        dc.w -96,128,96,64,32,0,-32,0,32,0,-32,-64,-96,128,96,128  ;orientation table (angle of an object within a particular lane)
        dc.w $00,$01,$02,$03,$04,$15,$26,$37,$37,$26,$15,$04,$03,$02,$01,$00

web8:   dc.w 15,15
        dc.w 7,7,5,5,3,5,1,7    ;figure-8
        dc.w 1,9,3,11,5,11,7,9  
        dc.w 9,7,11,5,13,5,15,7
        dc.w 15,9,13,11,11,11,9,9,7,7,-1

        dc.w -96,128,96,64,32,0,-32,-32,-32,0,32,64,96,128,-96,-96  ;orientation table (angle of an object within a particular lane)
        dc.w 0,$10,$20,$30,$40,$50,$60,$70,$60,$50,$40,$30,$20,$10,0

web9:   dc.w 17,8      ;triangle
        dc.w 8,1,7,3,6,5,5,7,4,9,3,11
        dc.w 2,13,4,13,6,13,8,13,10,13,12,13,14,13
        dc.w 13,11,12,9,11,7,10,5,9,3,8,1,-1
        dc.w 80,80,80,80,80,80,0,0,0,0,0,0,-80,-80,-80,-80,-80,-80  ;orientation table (angle of an object within a particular lane)
        dc.w $04,$14,$23,$33,$42,$52,$61,$71,$70,$70,$71,$61,$52,$42,$33,$23,$14,$04

web10:  dc.w 15,7        ;cross
        dc.w 7,3,7,5,5,7,3,7,3,9,5,9,7,11,7,13
        dc.w 9,13,9,11,11,9,13,9
        dc.w 13,7,11,7,9,5,9,3,7,3,-1

        dc.w 64,96,128,64,0,32,64,0,-64,-32,0,-64,128,-96,-64,128  ;orientation table (angle of an object within a particular lane)
        dc.w $0,$70,$10,$60,$20,$50,$30,$40,$40,$30,$50,$20,$60,$10,$70,0

web11:  dc.w 15,5    ;square
        dc.w 4,4,4,6,4,8,4,10,4,12
        dc.w 6,12,8,12,10,12,12,12
        dc.w 12,10,12,8,12,6,12,4
        dc.w 10,4,8,4,6,4,4,4,-1
        dc.w 64,64,64,64,0,0,0,0,-64,-64,-64,-64,128,128,128,128  ;orientation table (angle of an object within a particular lane)
        dc.w $00,$01,$02,$03,$04,$15,$26,$37,$37,$26,$15,$04,$03,$02,$01,$00
web12:  dc.w 14,7    ;w
        dc.w -3,8,-1,10,1,12,3,14,5,16,6,14,7,12,8,10
        dc.w 9,12,10,14,11,16,13,14,15,12,17,10,19,8,-3,8,0

        dc.w 32,32,32,32,-48,-48,-48,48,48,48,-32,-32,-32,-32

web13:  dc.w 14,6          ;sine wave
        dc.w -2,14,-2,12,-1,10,1,8
        dc.w 3,7,5,7,7,8,9,10
        dc.w 11,12,13,13,15,13,17,12
        dc.w 19,10,20,8,20,6,-2,14,0

        dc.w -64,-48,-32,-16,0,16,32,32,16,0,-16,-32,-48,-64

web14:
        dc.w 13,7          ;parabola
        dc.w 1,15,2,13,3,11,4,9
        dc.w 5,7,7,5,9,4,11,4
        dc.w 13,5,15,7,16,9,17,11
        dc.w 18,13,19,15,1,15,0

        dc.w -48,-48,-48,-48,-32,-16,0,16,32,48,48,48,48
        dc.w $84,$74,$63,$53,$42,$32,$21,$32,$42,$53,$63,$74,$84

web15:  dc.w 17,8          ;arrowhead
        dc.w 8,5,6,4,4,3,2,2,3,4,4,6,5,8,6,10,7,12,8,14
        dc.w 9,12,10,10,11,8,12,6,13,4,14,2,12,3,10,4,8,5,-1
        dc.w -112,-112,-112,48,48,48,48,48,48,-48,-48,-48,-48,-48,-48,112,112,112

web16:  dc.w 15,7
        dc.w 1,4,-1,6,-1,8,1,10,3,10,4,12,5,14,6,16
        dc.w 8,16,9,14,10,12,11,10,13,10,15,8,15,6,13,4,1,4,0
w16col:
        dc.w 96,64,32,0,48,48,48,0,-48,-48,-48,0,-32,-64,-96
        dc.w 0,$10,$20,$30,$40,$50,$60,$70,$60,$50,$40,$30,$20,$10,0

web17:  dc.w 12,6          ;wobbly u
        dc.w 6,1,4,2,3,4,2,6
        dc.w 3,8,5,9,7,10,9,10
        dc.w 11,9,12,7,13,5,14,3,15,1,6,1,0
        dc.w 112,80,80,48,16,16,0,-16,-48,-48,-48,-48
        dc.w $0f,$0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04

web18:  dc.w 13,8          ;lemon
        dc.w 12,3,10,3,8,3,6,4,4,6,3,8,3,10,3,12,5,12,7,12,9,11,11,9,12,7,12,5,12,3,-1
        dc.w 128,128,112,96,80,64,64,0,0,-16,-32,-48,-64,-64
        dc.w 0,$21,$42,$63,$84,$a5,$c6,$c6,$a5,$84,$63,$42,$21,0

web19:  dc.w 14,5        ;long wide v
        dc.w -3,3,-3,5,-3,7,-3,9,-3,11,-1,13,1,13,3,12,5,11
        dc.w 7,10,9,9,11,8,13,7,15,6,16,4,-3,3,0
        dc.w 64,64,64,64,32,0,-16,-16,-16,-16,-16,-16,-16,-48
        dc.w 0,$10,$21,$31,$42,$52,$63,$73,$84,$94,$a5,$a6,$a7,$a8

web20:  dc.w 13,6        ;giraffes neck kind of a shape
        dc.w -1,16,-3,15,-3,13,-3,11,-1,9,1,8,3,7,5,6,7,4,8,2,9,0,10,-2,12,-3,14,-3,-1,16,0
        dc.w -112,-64,-64,-32,-16,-16,-16,-32,-48,-48,-48,-16,0
        dc.w 0,$10,$21,$31,$42,$52,$63,$73,$64,$54,$45,$36,$27,$18
        
web21:  dc.w 7,3        ;tiny nut
        dc.w 7,5,5,7,5,9,7,11,9,11,11,9,11,7,9,5,7,5,-1
        dc.w 96,64,32,0,-32,-64,-96,128  
        dc.w 0,$20,$40,$60,$80,$60,$40,$20

web22:  dc.w 11,3        ;tiny star
        dc.w 7,5,5,7,3,8,5,9,7,11,8,13,9,11,11,9,13,8,11,7,9,5,8,3,7,5,-1
        dc.w 96,112,16,32,48,-48,-32,-16,-112,-96,-80,80  
        dc.w 0,$14,$34,$40,$54,$74,$80,$74,$54,$40,$34,$14

web23:  dc.w 15,3    ;spiraloid
        dc.w 1,9,2,11,4,12,6,13,8,13,10,12,12,10,13,8,13,6,12,4,11,2,9,1,7,1,5,3,5,5,7,6,1,9,0
        dc.w 48,16,16,0,-16,-32,-48,-64,-80,-80,-112,128,96,64,16
        dc.w $40,$41,$42,$43,$54,$55,$56,$57,$68,$69,$6a,$6b,$7c,$7d,$7e

web24:  dc.w 17,4    ;big oval
        dc.w 1,8,1,10,2,12,4,13,6,14,8,14,10,14,12,13,14,12,15,10,15,8
        dc.w 14,6,12,5,10,4,8,4,6,4,4,5,2,6,1,8,-1
        dc.w 64,48,16,16,0,0,-16,-16,-48,-64,-80,-112,-112,128,128,112,112,80
        dc.w $40,$42,$54,$56,$68,$6a,$7c,$7e,$7e,$7c,$6a,$68,$56,$54,$42,$40,$40,$40

web25:  dc.w 12,9    ;hook kind of a shape
        dc.w 8,-3,8,-1,7,1,5,3,3,5,2,7,2,9,3,11,5,13,7,14,9,14,11,13,13,11,8,-3,0
        dc.w 64,80,96,96,80,64,48,32,16,0,-16,-32
        dc.w $ff,$fe,$fd,$fc,$fb,$fa,$f9,$f8,$f7,$f6,$f5,$f4

web26:  dc.w 15,6    ;really diffy tiny star
        dc.w 8,3,8,5,7,7,5,8,3,8,5,8,7,9,8,11,8,13,8,11,9,9,11,8,13,8,11,8,9,7,8,5,8,3,-1
        dc.w 64,80,112,128,0,16,48,64,-64,-48,-16,0,128,-112,-80,-64
        dc.w $8f,$40,$50,$8d,$8d,$60,$70,$8b,$8b,$70,$60,$8d,$8d,$50,$40,$8f
web27:  dc.w 14,7    ;pentagon
        dc.w 8,2,6,4,4,6,2,8,3,10,4,12,5,14,7,14,9,14,11,14,12,12,13,10,14,8,12,6,10,4,8,2,-1
        dc.w 96,96,96,48,48,48,0,0,0,-48,-48,-48,-96,-96,-96
        dc.w $ff,$fd,$fc,$f4,$f2,$f0,$90,$80,$70,$20,$10,0,$7f,$8f,$9f

web28:  dc.w 12,5    ;inverted bird shape thang
        dc.w -2,8,-1,6,1,5,3,4,5,3,7,1,8,-1,9,1,11,3,13,4,15,5,17,6,18,8,-2,8,0
        dc.w -48,-16,-16,-16,-32,-48,48,32,16,16,16,48
        dc.w $ff,$fe,$fd,$fc,$fb,$fa,$fa,$fb,$fc,$fd,$fe,$ff

web29:  dc.w 14,2    ;D
        dc.w 2,12,4,12,6,12,8,12,10,12,12,12,14,12,14,10,13,8,11,6,9,5,7,5,5,6,3,8,2,10,2,12,-1
        dc.w 0,0,0,0,0,0,-64,-80,-96,-112,128,112,96,80,64
        dc.w 0,$20,$40,$40,$20,$0,0,$24,$48,$6c,$8f,$6c,$48,$24,0

web30:  dc.w 13,8    ;curved L
        dc.w -2,0,-2,2,-2,4,-2,6,-2,8,-1,10,1,12,3,13,5,13,7,13,9,13,11,12,13,12,15,13,-2,0,0
        dc.w 64,64,64,64,48,32,16,0,0,0,-16,0,16
        dc.w $f0,$e0,$d0,$c0,$b0,$a0,$90,$80,$70,$60,$50,$40,$30

web31:  dc.w 17,3    ;mouse pointer (diffi)
        dc.w 2,16,4,14,4,16,4,18,5,16,6,14,7,12,8,10,9,8,7,6,5,7,3,8,1,9,-1,10,-3,11,-1,11,1,11,-1,13,2,16,0
        dc.w -32,64,64,-48,-48,-48,-48,-48,-96,112,112,112,112,112,0,0,96
        dc.w $f0,$d0,$b0,$90,$70,$50,$30,$10,0,$10,$30,$50,$70,$90,$b0,$d0,$f0

web32:  dc.w 12,4    ;diagonal arse shape
        dc.w -3,4,-4,6,-4,8,-3,10,-1,11,1,11,3,10,2,12,2,14,3,16,5,17,7,17,9,16,-3,4,0
        dc.w 80,64,48,16,0,-16,80,64,48,16,0,-16
        dc.w $80,$70,$60,$50,$40,$30,$20,$10,0,0,0,0

web33:  dc.w 15,7    ;kind of cats head shaped
        dc.w 8,1,6,2,4,0,3,2,1,3,3,4,4,6,6,8,8,8,10,8,12,6,13,4,15,3,13,2,12,0,10,2,8,1,-1
        dc.w 112,-96,80,112,16,48,32,0,0,-32,-48,-16,-112,-80,96,112
        dc.w $f0,$d0,$b0,$90,$70,$50,$30,$10,$10,$30,$50,$70,$90,$b0,$d0,$f0

web34:  dc.w 14,7    ;teardrop
        dc.w 8,-1,8,1,7,3,5,5,4,7,4,9,5,11,7,12,9,12,11,11,12,9,12,7,11,5,9,3,8,1,8,-1,-1
        dc.w 64,80,96,80,64,48,16,0,-16,-48,-64,-80,-96,-80,-64
        dc.w $40,$42,$34,$36,$28,$2a,$1c,$1e,$1c,$2a,$28,$36,$34,$42,$40

web35:  dc.w 14,10    ;crinkly L
        dc.w 1,-2,1,0,2,2,2,4,3,6,3,8,4,10,4,12,5,14,5,16,6,18,8,18,10,17,12,17,14,16,1,-2,0
        dc.w 64,48,64,48,64,48,64,48,64,48,0,-16,0,-16
        dc.w $f0,$d0,$b0,$90,$70,$50,$40,$30,$20,$10,0,0

web36:  dc.w 12,3    ;kiss of death
        dc.w 2,7,3,9,5,10,7,11,9,11,11,10,13,9,14,7,12,6,10,6,8,7,6,6,4,6,2,7,-1
        dc.w 48,16,16,0,-16,-16,-48,-112,128,112,-112,128,112
        dc.w $d0,$b0,$90,$70,$90,$b0,$d0,$d0,$b0,$90,$90,$b0,$d0

web37:  dc.w 15,2    ;backwards C 
        dc.w 6,10,4,12,6,14,8,14,10,13,12,12,14,11,15,9,15,7,14,5,12,4,10,3,8,2,6,2,4,4,6,6,6,10,0
        dc.w 96,32,0,-16,-16,-16,-48,-64,-80,-112,-112,-112,128,96,32
        dc.w $f0,$f1,$e2,$e3,$d4,$d5,$c6,$c7,$b8,$b9,$aa,$ab,$9c,$9d,$ae

; *******************************************************************
; Vertext list defining different enemy objects.
; *******************************************************************
shot:   dc.b 8,7,1,2,0
        dc.b 10,11,1,0
        dc.b 10,7,1,4,0
        dc.b 8,11,1,0
        dc.b 7,9,1,6,0
        dc.b 11,9,1,0,0

flipper:dc.b 2,5,1,2,6,0
        dc.b 16,13,1,3,0
        dc.b 12,9,1,4,0
        dc.b 16,5,1,5,0
        dc.b 2,13,1,6,0
        dc.b 6,9,1,0,0

zap:    dc.b 3,3,1,2,10,0
        dc.b 8,7,1,3,0
        dc.b 14,3,1,4,0
        dc.b 12,8,1,5,0
        dc.b 16,12,1,6,0
        dc.b 11,11,1,7,0
        dc.b 10,16,1,8,0
        dc.b 7,11,1,9,0
        dc.b 3,13,1,10,0
        dc.b 6,8,1,0,0

fliptank:
        dc.b 2,9,1,2,7,4,0
        dc.b 9,16,1,8,3,0
        dc.b 16,9,1,4,5,0
        dc.b 9,2,1,6,0
        dc.b 9,6,1,6,8,0
        dc.b 6,9,1,7,0
        dc.b 9,12,1,8,-1,240,0
        dc.b 12,9,1,0
        dc.b 7,8,1,10,14,-1,0,0
        dc.b 11,10,1,11,0
        dc.b 10,9,1,12,0
        dc.b 11,8,1,13,0
        dc.b 7,10,1,14,0
        dc.b 8,9,1,0,0

fusetank: dc.b 2,9,1,2,7,4,0
        dc.b 9,16,1,8,3,0
        dc.b 16,9,1,4,5,0
        dc.b 9,2,1,6,0
        dc.b 9,4,1,6,8,0
        dc.b 4,9,1,7,0
        dc.b 9,14,1,8,-1,240,0
        dc.b 14,9,1,0
        dc.b 9,9,1,10,0
        dc.b 8,10,1,11,0
        dc.b 8,12,1,0
        dc.b 10,11,1,-1,143,9,13,0
        dc.b 11,12,1,0
        dc.b 11,8,1,-1,240,9,15,0
        dc.b 12,8,1,0
        dc.b 8,7,1,-1,15,9,17,0
        dc.b 9,5,1,0
        dc.b 7,8,1,-1,255,9,19,0
        dc.b 5,9,1,0,0

pulstank: dc.b 2,9,1,2,7,4,0
        dc.b 9,16,1,8,3,0
        dc.b 16,9,1,4,5,0
        dc.b 9,2,1,6,0
        dc.b 9,4,1,6,8,0
        dc.b 4,9,1,7,0
        dc.b 9,14,1,8,-1,255,0
        dc.b 14,9,1,0
        dc.b 6,10,1,10,0
        dc.b 7,7,1,11,0
        dc.b 8,12,1,12,0
        dc.b 9,6,1,13,0
        dc.b 10,11,1,14,0
        dc.b 11,7,1,15,0
        dc.b 12,9,1,0,0

spike:
        dc.b 9,9,1,2,-1,$88,0
        dc.b 9,9,2,0,0
        dc.b 9,9,3,0,0

spiker: dc.b 10,9,1,2,0
        dc.b 9,10,1,3,0
        dc.b 8,9,1,4,0
        dc.b 9,7,1,5,0
        dc.b 12,8,1,6,0
        dc.b 10,11,1,7,0
        dc.b 8,11,1,8,0
        dc.b 6,8,1,9,0
        dc.b 9,5,1,10,0
        dc.b 14,7,1,11,0
        dc.b 13,14,1,12,0
        dc.b 6,15,1,0,0

ev:     dc.b 3,1,1,2,0
        dc.b 1,1,1,3,0
        dc.b 1,5,1,4,0
        dc.b 3,5,1,0
        dc.b 1,3,1,6,0
        dc.b 2,3,1,0

        dc.b 4,1,1,8,0
        dc.b 5,5,1,9,0
        dc.b 6,1,1,0

        dc.b 7,1,1,11,0
        dc.b 7,5,1,0

        dc.b 8,1,1,13,0
        dc.b 10,1,1,0
        dc.b 9,1,1,15,0
        dc.b 9,5,1,0

        dc.b 13,1,1,17,0
        dc.b 11,1,1,18,0
        dc.b 11,5,1,19,0
        dc.b 13,5,1,0
        dc.b 11,3,1,21,0
        dc.b 12,3,1,0

        dc.b 14,1,1,23,0
        dc.b 16,1,1,24,0
        dc.b 14,5,1,25,0
        dc.b 16,5,1,0,0

la_routine:
        dc.b 1,1,1,2,0
        dc.b 1,5,1,3,0
        dc.b 3,5,1,0

        dc.b 4,5,1,5,0
        dc.b 6,1,1,6,0
        dc.b 8,5,1,0
        dc.b 5,3,1,8,0
        dc.b 7,3,1,0

        dc.b 12,1,1,10,0
        dc.b 10,1,1,11,0
        dc.b 9,2,1,12,0
        dc.b 10,3,1,13,0
        dc.b 11,3,1,14,0
        dc.b 12,4,1,15,0
        dc.b 11,5,1,16,0
        dc.b 9,5,1,0,0


pu:     dc.b 1,5,1,2,0
        dc.b 1,1,1,3,0
        dc.b 3,1,1,4,0
        dc.b 4,2,1,5,0
        dc.b 3,3,1,6,0
        dc.b 1,3,1,0

        dc.b 5,1,1,8,0
        dc.b 5,4,1,9,0
        dc.b 6,5,1,10,0
        dc.b 7,5,1,11,0
        dc.b 8,4,1,12,0
        dc.b 8,1,1,0

        dc.b 9,5,1,14,0
        dc.b 9,1,1,15,0
        dc.b 11,5,1,16,0
        dc.b 11,1,1,0

        dc.b 12,1,1,18,0
        dc.b 14,1,1,0
        dc.b 13,1,1,20,0
        dc.b 13,5,1,0

        dc.b 17,1,1,22,0
        dc.b 15,1,1,23,0
        dc.b 15,5,1,24,0
        dc.b 17,5,1,0
        dc.b 15,3,1,26,0
        dc.b 16,3,1,0

        dc.b 21,1,1,28,0
        dc.b 19,1,1,29,0
        dc.b 18,2,1,30,0
        dc.b 19,3,1,31,0
        dc.b 20,3,1,32,0
        dc.b 21,4,1,33,0
        dc.b 20,5,1,34,0
        dc.b 18,5,1,0,0

fuse1:  dc.b 9,9,1,2,0
        dc.b 8,7,1,3,0
        dc.b 10,5,1,4,0
        dc.b 9,2,1,-1,-1,0
        dc.b 6,8,1,1,6,0
        dc.b 4,9,1,7,0
        dc.b 2,7,1,-1,128,0
        dc.b 7,12,1,1,9,0
        dc.b 7,14,1,10,0
        dc.b 5,16,1,-1,143,0
        dc.b 11,10,1,1,12,0
        dc.b 11,13,1,13,0
        dc.b 13,15,1,-1,240,0
        dc.b 11,7,1,1,15,0
        dc.b 13,7,1,16,0
        dc.b 14,5,1,0,0

fuse2:  dc.b 9,9,1,2,0
        dc.b 10,7,1,3,0
        dc.b 8,5,1,4,0
        dc.b 9,2,1,-1,-1,0
        dc.b 6,10,1,1,6,0
        dc.b 4,8,1,7,0
        dc.b 2,9,1,-1,128,0
        dc.b 8,13,1,1,9,0
        dc.b 6,13,1,10,0
        dc.b 5,16,1,-1,43,0
        dc.b 10,12,1,1,12,0
        dc.b 12,13,1,13,0
        dc.b 13,16,1,-1,240,0
        dc.b 13,8,1,1,15,0
        dc.b 13,6,1,16,0
        dc.b 15,4,1,0,0


b250:   dc.b 5,7,1,2,0
        dc.b 6,7,1,3,0
        dc.b 7,8,1,4,0
        dc.b 7,9,1,5,0
        dc.b 5,11,1,6,0
        dc.b 7,11,1,0
        dc.b 8,11,1,8,0
        dc.b 9,11,1,9,0
        dc.b 10,10,1,10,0
        dc.b 9,9,1,11,0
        dc.b 8,9,1,12,0
        dc.b 8,7,1,13,0
        dc.b 10,7,1,0
        dc.b 11,7,1,15,17,0
        dc.b 13,7,1,16,0
        dc.b 13,11,1,17,0
        dc.b 11,11,1,0,0

b500:   dc.b 7,7,1,2,0
        dc.b 5,7,1,3,0
        dc.b 5,9,1,4,0
        dc.b 6,9,1,5,0
        dc.b 7,10,1,6,0
        dc.b 6,11,1,7,0
        dc.b 5,11,1,0
        dc.b 8,7,1,9,11,0
        dc.b 10,7,1,10,0
        dc.b 10,11,1,11,0
        dc.b 8,11,1,0
        dc.b 11,7,1,13,15,0
        dc.b 13,7,1,14,0
        dc.b 13,11,1,15,0
        dc.b 11,11,1,0,0

b750:   dc.b 5,7,1,2,0
        dc.b 7,7,1,3,0
        dc.b 5,11,1,0
        dc.b 10,7,1,5,0
        dc.b 8,7,1,6,0
        dc.b 8,9,1,7,0
        dc.b 9,9,1,8,0
        dc.b 10,10,1,9,0
        dc.b 9,11,1,10,0
        dc.b 8,11,1,0
        dc.b 11,7,1,12,14,0
        dc.b 13,7,1,13,0
        dc.b 13,11,1,14,0
        dc.b 11,11,1,0,0

pu6:    dc.b 1,9,1,2,0
        dc.b 4,2,1,3,0
        dc.b 7,16,1,4,0
        dc.b 11,2,1,5,0
        dc.b 14,15,1,6,0
        dc.b 17,9,1,0,0

pu5:    dc.b 1,9,1,2,0
        dc.b 4,3,1,3,0
        dc.b 7,15,1,4,0
        dc.b 11,3,1,5,0
        dc.b 14,14,1,6,0
        dc.b 17,9,1,0,0

pu4:    dc.b 2,9,1,2,0
        dc.b 4,5,1,3,0
        dc.b 7,13,1,4,0
        dc.b 11,5,1,5,0
        dc.b 14,14,1,6,0
        dc.b 16,9,1,0,0

pu3:    dc.b 2,9,1,2,0
        dc.b 4,6,1,3,0
        dc.b 7,12,1,4,0
        dc.b 11,7,1,5,0
        dc.b 13,13,1,6,0
        dc.b 16,9,1,0,0

pu2:    dc.b 2,9,1,2,0
        dc.b 5,7,1,3,0
        dc.b 8,11,1,4,0
        dc.b 11,8,1,5,0
        dc.b 13,10,1,6,0
        dc.b 16,9,1,0,0

pu1:    dc.b 3,9,1,2,0
        dc.b 6,8,1,3,0
        dc.b 8,10,1,4,0
        dc.b 11,9,1,5,0
        dc.b 13,10,1,6,0
        dc.b 15,9,1,0,0

oneup:  dc.b 8,4,1,2,0
        dc.b 9,3,1,3,0
        dc.b 9,8,1,0
        dc.b 8,8,1,5,0
        dc.b 10,8,1,0
        dc.b 5,10,1,7,0
        dc.b 5,13,1,8,0
        dc.b 6,14,1,9,0
        dc.b 7,14,1,10,0
        dc.b 8,13,1,11,0
        dc.b 8,10,1,0
        dc.b 10,14,1,13,0
        dc.b 10,10,1,14,0
        dc.b 12,10,1,15,0
        dc.b 13,11,1,16,0
        dc.b 12,12,1,17,0
        dc.b 10,12,1,0,0

chevre: dc.b 9,5,1,2,0
        dc.b 9,9,7,3,0
        dc.b 9,13,1,0,0

sample:
samend:
        dc.w 0

; *******************************************************************
; Fuseball colors
; *******************************************************************
fbcols: dc.b 15,255,128,143,240

spulsars: dc.l spuls6,spuls6,spuls6,spuls5,spuls4,spuls3,spuls2,spuls1
          dc.l spuls1,spuls2,spuls3,spuls4,spuls5,spuls6,spuls6,spuls6

scores: dc.b 6,14
        dc.b 5,0
        dc.b 7,2
        dc.b 5,1
        dc.b 6,24
        dc.b 5,4
        dc.b 6,74
        dc.b 7,0
        dc.b 7,3
        dc.b 7,7
        dc.b 6,2  ;10
        dc.b 3,1
        dc.b 4,1
        dc.b 4,4

autom1:      dc.b "demo",0
autom2:      dc.b "press FIRE to play",0
premes1:     dc.b "PRESS c FOR MORE, a TO QUIT",0
premes2:     dc.b "PRESS any fire button TO QUIT",0
optmsg:      dc.b "PRESS option FOR GAME OPTIONS",0


bftest:      dc.b "llama love",0
llamacop:    dc.b "DEVELOPED BY llamasoft",0
ataricop:    dc.b "(C) 1981,1994 ATARI CORP.",0
ataricop1:   dc.b "COPYRIGHT 1981,",0
ataricop2:   dc.b "1994 ATARI CORP.",0
enlm1:       dc.b "USE left AND right",0
enlm2:       dc.b "TO SELECT LETTER. PRESS fire",0
enlm3:       dc.b "WHEN LETTER IS CORRECT.",0
conm1:       dc.b "congratulations!",0
conm2:       dc.b "you got a hi-score!",0
conm3:       dc.b "enter three initials dude",0

nkeym1:      dc.b "no high score",0
nkeym2:      dc.b "but you got a key!",0
nkeym3:      dc.b "enter three initials for tag",0

conm4:       dc.b "awesome blasting!",0
conm5:       dc.b "the boss score!",0
conm6:       dc.b "enter something EGOTISTICAL!",0

fightmsg:    dc.b 'fight!',0

legal:       dc.b "abcdefghijklmnopqrstuvwxyz .!-?*",0

vertext:     dc.b "t2k version 121193",0
pautext:     dc.b "paused",0
option1:     dc.l o1t1,o1t2,o1s1,o1s2,o1s3,o1s4,0

puptxts:     dc.l puptxt1,puptxt6,puptxt4,puptxt7,puptxt2,puptxt5,puptxt6,puptxt8

pupmes:      dc.b "collect powerups!",0
puptxt1:     dc.b "particle laser!",0
puptxt4:     dc.b "jump enabled!",0
puptxt2:     dc.b "a.i. droid!",0
puptxt5:     dc.b "wicked!",0
puptxt6:     dc.b "zappo!",0
puptxt7:     dc.b "outstanding!",0
puptxt8:     dc.b "dude!",0
ohtxt:       dc.b "outta here!",0
drtxt:       dc.b "yes! yes! yes!",0
warpytxt:    dc.b "warp 5 levels!",0

wtxt1:       dc.b "2 more for warp",0
wtxt2:       dc.b "1 more for warp",0
wtxt3:       dc.b "warp enabled",0
wtxts:       dc.l wtxt3,wtxt2,wtxt1

o1t1:        dc.b "select game type",0
o1t2:        dc.b "to play",0
o1s1:        dc.b "traditional ",0
o1s2:        dc.b "tempest plus",0
o1s3:        dc.b "tempest 2000",0
o1s4:        dc.b "tempest duel",0

o6t1:        dc.b "play or practice",0
o6t2:        dc.b "tempest duel game",0
o6s1:        dc.b "tempest duel",0
o6s2:        dc.b "solo practice",0

option6:     dc.l o6t1,o6t2,o6s1,o6s2,o3s3,0
option7:     dc.l o7t1,o7t2,o7s1,o7s2,o7s3,0
option9:     dc.l o9t1,o9t2,o9s1,o9s2,0
option10:    dc.l o10t1,o10t2,o10s1,o10s2,o10s3,0
option11:    dc.l o11t1,o11t2,o11s1,o11s2,0

o11t1:       dc.b "clear cartridge",0
o11t2:       dc.b "memory",0
o11s1:       dc.b "no! no! no!",0
o11s2:       dc.b "absolutely!",0

o10t1:       dc.b "please choose type",0
o10t2:       dc.b "of match to play",0
o10s1:       dc.b "one round",0
o10s2:       dc.b "best of three",0
o10s3:       dc.b "best of five",0

bstymsg:     dc.b "PRESS option FOR BEASTLY MODE!",0

o9t1:        dc.b "keys are available",0
o9t2:        dc.b "please choose",0
o9s1:        dc.b "use a key",0
o9s2:        dc.b "just start",0


o7t1:        dc.b "select options",0
o7t2:        dc.b "for this game",0
o7s1:        dc.b "1 player",0
o7s2:        dc.b "ai droid",0
o7s3:        dc.b "2 player team",0



o2t1:        dc.b "game options",0
o2t2:        dc.b "select, dude",0
o2s1:        dc.b "display setup",0
o2s2:        dc.b "control setup",0
o2s3:        dc.b "controller type",0

o3t1:        dc.b "display options",0
o3t2:        dc.b "please select",0
o3s10:       dc.b "interlace",0
o3s11:       dc.b "no interlace",0
o3s20:       dc.b "fat vectors",0
o3s21:       dc.b "skinny vectors",0
o3s3:        dc.b "exit",0

o4t1:        dc.b "firebutton options",0
o4t2:        dc.b "hit chosen button",0
option4:     dc.l o4t1,o4t2,o4s1,o4s2,o4s3,o3s3,0

o5t1:        dc.b "select controller",0
o5t2:        dc.b "type to use",0

o5s10:       dc.b "p1 joypad",0
o5s11:       dc.b "p1 rotary",0
o5s20:       dc.b "p2 joypad",0
o5s21:       dc.b "p2 rotary",0

o5s2:        dc.b "practice warp",0



gmes1:       dc.b "caught you!",0
gmes2:       dc.b "shot you!",0
gmes3:       dc.b "fried you!",0

zmes1:       dc.b "eat electric",0
zmes2:       dc.b "death!",0

wmes1:       dc.b "avoid the spikes",0
wmes2:       dc.b "superzapper",0
wmesx:       dc.b "recharge",0

m7msg1:      dc.b "speed boost",0

wonprc:      dc.b "practice over",0

csmsg2:      dc.b "up AND down TO SELECT LEVEL",0

pvolt1:      dc.b "USE up AND down TO ADJUST",0
pvolt2:      dc.b "music VOLUME",0
pvolt3:      dc.b "sound fx VOLUME",0
pvolts:      dc.l pvolt2,pvolt3

fires:       dc.l $20000000
 dc.l        $02000000
 dc.l        $00002000

testpage:   dc.b "ORIGINAL GAME DESIGNED BY/       dave theurer~"
            dc.b "JAGUAR VERSION BY/      yak~"
            dc.b "BITMAP ARTWORK BY/     joby~"
            dc.b "TUNES BY/    imagitec design~"
            dc.b "GAME TESTING BY/   joe, andrew, hans and goku~"
            dc.b "VOICES BY/  ted and carrie tahquechi~"
            dc.b "PRODUCED BY/ john skruch*"


victpage:   dc.b "you beat the game!//now try to beat tempest - the beastly mode!//press option on the "
            dc.b "level select screen to begin this harder version of the game.//all points scored in "
            dc.b "beastly mode are doubled!//now go and have a nice cup of tea to calm down!*"

victpage2:  dc.b "totally awesome!//you beat the game in beastly mode!//you had better have about "
            dc.b "six cups of tea after this!//with reflexes like that, you should join the air force and "
            dc.b "become a fighter pilot?//outstanding tempest, dude!*"



fnlmsg:      dc.b "final score",0
nxrmsg:      dc.b "press fire to play next round",0
dudes:       dc.b "tempest dudes",0


keyh1:       dc.b "player access keys",0
keyh2:       dc.b "choose yourself",0
warp2msg:    dc.b "STAY ON THE GREEN TRACK",0

pobj:   dc.w 10
        dc.w -4,-4,-2
        dc.w -3,-3,-1
        dc.w -2,-2,0
        dc.w -3,3,3
        dc.w -4,4,2
        dc.w 4,-4,-2
        dc.w 3,-3,-1
        dc.w 2,-2,0
        dc.w 3,3,3
        dc.w 4,4,2

pobj2:  dc.w 9
        dc.w -3,0,0,3,0,0,0,-3,0,0,3,0
        dc.w -1,0,0,1,0,0,0,-1,0,0,1,0
        dc.w 0,0,0

pobj3:  dc.w 10
        dc.w -8,-4,0,8,-4,0,-8,4,0,8,4,0,0,8,0,0,-8,0
        dc.w -4,0,3,4,0,3,0,4,3,0,-4,3
        dc.w -4,0,-3,4,0,-3,0,4,-3,0,-4,-3


; *******************************************************************
; Bonus round level definitions
; *******************************************************************
courses: dc.l course1,course6,course3,course2,course7,course5,course4,course8

course1: dc.l $08001000
        dc.l $08081100
        dc.l $08101200
        dc.l $08181300
        dc.l $08201400
        dc.l $08281503
        dc.l $08301600
        dc.l $08301700
        dc.l $08301800
        dc.l $08201900
        dc.l $08102000
        dc.l $08001000
        dc.l $08f01100
        dc.l $08e01200
        dc.l $08d01300
        dc.l $08e01403
        dc.l $08d01500
        dc.l $08e01600
        dc.l $08f01700
        dc.l $08001800
        dc.l $08101900
        dc.l $08202000
        dc.l $08101000
        dc.l $08202000
        dc.l $08101001
        dc.l $0820f000
        dc.l $0830e000
        dc.l $0840f003
        dc.l $0830e000
        dc.l $0840f000
        dc.l $0830e000
        dc.l $0820f000
        dc.l $0810e000
        dc.l $0800d000
        dc.l $08f0d000
        dc.l $08e0d001
        dc.l $08d0c000
        dc.l $08c0c000
        dc.l $08d0c003
        dc.l $08e0d000
        dc.l $08f0e000
        dc.l $0800f002
        dc.l $08201000
        dc.l $08002000
        dc.l $08203002
        dc.l $08004000
        dc.l $08e03003
        dc.l $08c02000
        dc.l $08d01000
        dc.l $08e01000
        dc.l $08f01003
        dc.l $08e01003
        dc.l $08f01004
        dc.l $080010ff

course2: dc.l $08001000
        dc.l $08082000
        dc.l $08101000
        dc.l $0818f000
        dc.l $0820e000
        dc.l $0828d003
        dc.l $0830d000
        dc.l $0830e000
        dc.l $0830f000
        dc.l $08201000
        dc.l $08102000
        dc.l $08001000
        dc.l $08f02002
        dc.l $08e03002
        dc.l $08d04000
        dc.l $08e03003
        dc.l $08d02000
        dc.l $08e01000
        dc.l $08f0f003
        dc.l $0800f003
        dc.l $0810f003
        dc.l $0820f003
        dc.l $0810f000
        dc.l $0820e001
        dc.l $0810d001
        dc.l $0820c000
        dc.l $0830e000
        dc.l $0840f000
        dc.l $0830e000
        dc.l $0840f000
        dc.l $0830e000
        dc.l $0820f000
        dc.l $0810e000
        dc.l $0800d000
        dc.l $08f0e000
        dc.l $08e0f001
        dc.l $08d0f000
        dc.l $08c01000
        dc.l $08d02002
        dc.l $08e03000
        dc.l $08f03002
        dc.l $08004002
        dc.l $08204002
        dc.l $08003000
        dc.l $08202000
        dc.l $08001000
        dc.l $08e01003
        dc.l $08c0f000
        dc.l $08d0e001
        dc.l $08e0d001
        dc.l $08f0c001
        dc.l $08e0b001
        dc.l $08f0b004
        dc.l $0800b0ff

course3: dc.l $08001000
        dc.l $08102000
        dc.l $08001000
        dc.l $08f0f000
        dc.l $0800e000
        dc.l $0810d003
        dc.l $0820d000
        dc.l $0810e000
        dc.l $0800f000
        dc.l $08f01000
        dc.l $08e02000
        dc.l $08d01000
        dc.l $08e02002
        dc.l $08f03002
        dc.l $08004000
        dc.l $08003003
        dc.l $08002000
        dc.l $08101000
        dc.l $08f0f003
        dc.l $0810f003
        dc.l $08f0f003
        dc.l $0810f003
        dc.l $0800f000
        dc.l $0800e001
        dc.l $0800d001
        dc.l $0810c000
        dc.l $0820e000
        dc.l $0830f000
        dc.l $0840e000
        dc.l $0830f000
        dc.l $0820e000
        dc.l $0810f000
        dc.l $0800e000
        dc.l $0810d000
        dc.l $0820e000
        dc.l $0830f001
        dc.l $0840f000
        dc.l $08301000
        dc.l $08202002
        dc.l $08203000
        dc.l $08003002
        dc.l $08e04002
        dc.l $08e04002
        dc.l $08f03000
        dc.l $08002000
        dc.l $08101000
        dc.l $08201003
        dc.l $0810f000
        dc.l $08f0e001
        dc.l $0810d001
        dc.l $08f0c001
        dc.l $0810b001
        dc.l $08f0b004
        dc.l $0800b0ff

course4: dc.l $0800f003
        dc.l $0810f003
        dc.l $0800f003
        dc.l $08f0f003
        dc.l $0800f000
        dc.l $0810f000
        dc.l $08201000
        dc.l $08102002
        dc.l $08003002
        dc.l $08f04002
        dc.l $08e05002
        dc.l $08d06000
        dc.l $08e06000
        dc.l $08f06000
        dc.l $08006000
        dc.l $08006002
        dc.l $08007002
        dc.l $08107000
        dc.l $08f07000
        dc.l $08107000
        dc.l $08f06000
        dc.l $08105000
        dc.l $08004000
        dc.l $08003000
        dc.l $08002000
        dc.l $08101000
        dc.l $08200000
        dc.l $0830f000
        dc.l $0840e001
        dc.l $0830d001
        dc.l $0820c001
        dc.l $0810b001
        dc.l $0800a000
        dc.l $0810a000
        dc.l $0820a000
        dc.l $0830a001
        dc.l $0840a000
        dc.l $0830b000
        dc.l $0820c002
        dc.l $0820d000
        dc.l $0800e002
        dc.l $08e0f002
        dc.l $08e0f002
        dc.l $08f0f000
        dc.l $0800f000
        dc.l $0810f003
        dc.l $0820e001
        dc.l $0810d001
        dc.l $08f0c001
        dc.l $0810b001
        dc.l $08f0a001
        dc.l $0810a001
        dc.l $08f0a004
        dc.l $0800a0ff

course5: dc.l $0800f003
        dc.l $0810f003
        dc.l $0820f003
        dc.l $0800f003
        dc.l $08f0f000
        dc.l $08e0f000
        dc.l $08001000
        dc.l $08102002
        dc.l $08203002
        dc.l $08304002
        dc.l $08005002
        dc.l $08f06000
        dc.l $08e06000
        dc.l $08d06000
        dc.l $08006000
        dc.l $08206002
        dc.l $08207002
        dc.l $08007000
        dc.l $08007000
        dc.l $08e07000
        dc.l $08e06000
        dc.l $08005000
        dc.l $08004000
        dc.l $08203000
        dc.l $08402000
        dc.l $08201000
        dc.l $08000000
        dc.l $08e0f000
        dc.l $08c0e001
        dc.l $08e0d001
        dc.l $0800c001
        dc.l $0800b001
        dc.l $0800a000
        dc.l $0800a000
        dc.l $0830a000
        dc.l $0820a001
        dc.l $0810a000
        dc.l $0800b000
        dc.l $0800c002
        dc.l $0800d000
        dc.l $0800e002
        dc.l $08d0f002
        dc.l $08e0f002
        dc.l $08f0f000
        dc.l $0800f000
        dc.l $0800f003
        dc.l $0800e001
        dc.l $0820d001
        dc.l $0820c001
        dc.l $0840b001
        dc.l $0840a001
        dc.l $0820a001
        dc.l $0820a004
        dc.l $0800a0ff

course6: dc.l $08001003
        dc.l $08001003
        dc.l $08001003
        dc.l $08001003
        dc.l $08001003
        dc.l $08001003
        dc.l $08001003
        dc.l $08001003
        dc.l $08001000
        dc.l $08001000
        dc.l $08001400
        dc.l $08001800
        dc.l $08001c00
        dc.l $08002000
        dc.l $08001c00
        dc.l $08001800
        dc.l $08001400
        dc.l $08001200
        dc.l $08001000
        dc.l $08000800
        dc.l $08000400
        dc.l $0800fc00
        dc.l $0800f800
        dc.l $0800f400
        dc.l $0800f000
        dc.l $0800ec00
        dc.l $0800e800
        dc.l $0800e400
        dc.l $0800e003
        dc.l $0800e003
        dc.l $0800e003
        dc.l $0800e003
        dc.l $0800e003
        dc.l $0800e003
        dc.l $0800e200
        dc.l $0800e400
        dc.l $0800e600
        dc.l $0800e800
        dc.l $0800ea00
        dc.l $0800ec00
        dc.l $0800ee00
        dc.l $0800f000
        dc.l $0800f000
        dc.l $0800f000
        dc.l $0800f000
        dc.l $0800f000
        dc.l $0800f000
        dc.l $0800f003
        dc.l $0800f003
        dc.l $0800f003
        dc.l $0800f003
        dc.l $0800f003
        dc.l $0800f004
        dc.l $0800f0ff

course7: dc.l $06001000
        dc.l $05081100
        dc.l $04101200
        dc.l $04181300
        dc.l $05201400
        dc.l $04281503
        dc.l $05301600
        dc.l $05301700
        dc.l $04301800
        dc.l $05201900
        dc.l $04102000
        dc.l $04001000
        dc.l $03f01100
        dc.l $03e01200
        dc.l $04d01300
        dc.l $03e01403
        dc.l $04d01500
        dc.l $03e01600
        dc.l $04f01700
        dc.l $04001800
        dc.l $04101900
        dc.l $05202000
        dc.l $05101000
        dc.l $05202000
        dc.l $04101001
        dc.l $0420f000
        dc.l $0430e000
        dc.l $0440f003
        dc.l $0530e000
        dc.l $0440f000
        dc.l $0530e000
        dc.l $0620f000
        dc.l $0710e000
        dc.l $0800d000
        dc.l $08f0d000
        dc.l $07e0d001
        dc.l $07d0c000
        dc.l $06c0c000
        dc.l $06d0c003
        dc.l $06e0d000
        dc.l $05f0e000
        dc.l $0400f002
        dc.l $04201000
        dc.l $04002000
        dc.l $04203002
        dc.l $05004000
        dc.l $04e03003
        dc.l $05c02000
        dc.l $04d01000
        dc.l $03e01000
        dc.l $03f01003
        dc.l $03e01003
        dc.l $03f01004
        dc.l $030010ff

course8: dc.l $03001003
        dc.l $03021003
        dc.l $03041003
        dc.l $03061003
        dc.l $03081003
        dc.l $030a1003
        dc.l $030c1003
        dc.l $030e1003
        dc.l $03101000
        dc.l $03121000
        dc.l $03141400
        dc.l $03161800
        dc.l $03141c00
        dc.l $03122000
        dc.l $03101c00
        dc.l $030e1800
        dc.l $030c1400
        dc.l $030a1200
        dc.l $03081000
        dc.l $03060800
        dc.l $03040400
        dc.l $0302fc00
        dc.l $0300f800
        dc.l $03fef400
        dc.l $03fcf000
        dc.l $03faec00
        dc.l $03f8e800
        dc.l $03f6e400
        dc.l $03f4e003
        dc.l $03f2e003
        dc.l $03f0e003
        dc.l $03f4e003
        dc.l $03f8e003
        dc.l $03fce003
        dc.l $0300e200
        dc.l $0304e400
        dc.l $0308e600
        dc.l $030ce800
        dc.l $0310ea00
        dc.l $0314ec00
        dc.l $0318ee00
        dc.l $031cf000
        dc.l $0320f000
        dc.l $031cf000
        dc.l $031af000
        dc.l $0318f000
        dc.l $0316f000
        dc.l $0314f003
        dc.l $0312f003
        dc.l $0310f003
        dc.l $030cf003
        dc.l $0308f003
        dc.l $0304f004
        dc.l $0300f0ff

; *******************************************************************
; Bonus round tunnel definitions
; *******************************************************************
tunnels: dc.l tunlvl,tunlvl7,tunlvl3,tunlvl2,tunlvl4,tunlvl5,tunlvl6,tunlvl8

tunlvl: dc.b 0,0,1,1,2,2,2,2
        dc.b 2,1,1,1,0,-1,-1,-2

        dc.b -2,-3,-3,-2,-1,0,2,0
        dc.b 2,4,2,4,4,4,2,0

        dc.b -2,2,-3,3,-4,4,0,0
        dc.b 0,1,2,3,4,5,6,6

        dc.b -6,-6,-5,-4,-3,-2,-1,0
        dc.b 8,8,8,0,0,0,0,0

tunlvl2:dc.b 0,0,2,2,-2,-2,2,2
        dc.b 0,3,0,3,0,3,0,3

        dc.b 0,-3,0,-3,0,-3,0,-3
        dc.b 6,6,6,6,6,6,6,6

        dc.b 0,-6,-6,0,-6,-6,0,-6
        dc.b -6,-6,-5,-5,-4,-4,-3,-3

        dc.b -2,-2,-1,-1,8,-2,8,-2
        dc.b -7,-5,-7,0,0,0,0,0  

tunlvl3:dc.b 0,0,2,2,2,2,2,2
        dc.b -3,-3,-3,-3,-3,-3,-3,-3

        dc.b 4,4,4,4,4,4,4,4
        dc.b -5,-5,-5,-5,-5,-5,-5,-5

        dc.b 6,6,6,6,6,6,6,6
        dc.b -6,-6,-6,-6,-6,-6,-6,-6

        dc.b 0,0,0,0,6,-6,6,-6
        dc.b 7,7,7,7,0,0,0,0  

tunlvl4:dc.b 0,0,0,0,0,0,0,0
        dc.b 7,7,7,7,7,7,7,7

        dc.b 7,7,7,7,7,7,7,7
        dc.b -7,-7,-7,-7,-7,-7,-7,-7

        dc.b 7,7,7,7,7,7,7,7
        dc.b -7,-7,-7,-7,-7,-7,-7,-7

        dc.b -7,-7,-7,-7,-7,-7,-7,-7
        dc.b 8,8,8,8,0,0,0,0  

tunlvl5:dc.b 0,0,2,4,6,2,6,4
        dc.b -4,-2,-3,-1,-4,-2,-3,-1

        dc.b 2,3,-8,2,3,-8,2,4
        dc.b -2,-3,8,-2,-3,8,-2,-4

        dc.b -8,-8,-7,-7,-6,-6,-5,-5
        dc.b -4,-4,-3,-3,-2,-2,-1,-1

        dc.b 0,1,2,3,4,5,6,7
        dc.b 8,9,10,11,0,0,0,0

tunlvl6:dc.b 0,0,4,4,-12,4,4,-12
        dc.b 0,-12,1,-12,2,-12,3,-12

        dc.b 4,-12,5,-12,6,-12,7,-12
        dc.b 8,-12,7,-12,6,-12,5,-12

        dc.b 4,-12,3,-12,2,-12,1,-12
        dc.b 0,-12,0,-12,0,-12,0,-12

        dc.b 8,8,8,8,9,9,9,9
        dc.b -12,-12,-12,-12,0,0,0,0

tunlvl7:dc.b 0,0,1,1,1,1,2,2
        dc.b 2,2,2,2,3,3,3,3

        dc.b 3,3,3,3,4,4,4,4
        dc.b 4,4,4,4,5,5,5,5

        dc.b 6,6,6,6,7,7,7,7
        dc.b -7,-7,-7,-7,-6,-6,-6,-6

        dc.b -5,-5,-5,-5,-4,-4,-4,-4
        dc.b -3,-3,-2,-2,-1,0,0,0

tunlvl8:dc.b 1,2,3,4,-8,-8,4,5
        dc.b 6,7,-8,-8,0,0,4,-9

        dc.b 3,-2,6,2,7,-4,-7,2
        dc.b -5,2,-5,3,-8,9,-5,6

        dc.b 8,8,8,-12,8,8,8,-12
        dc.b 12,-8,-8,-8,12,-8,-8,-8

        dc.b 7,0,-7,0,-7,-7,-7,13
        dc.b 13,7,7,-13,0,0,0,0

px_bons: dc.l $6e0000,$2c002d,$6e002e,$2c002c,$6e005a,$2c002d


; *******************************************************************
; Cross delays
; *******************************************************************
crossdels: dc.b 8,4,3,2,1,1,1,1
; *******************************************************************
; Fli pauses
; *******************************************************************
pauses: dc.b $10,$08,$06,$05,$04,$03,$02,$01

; *******************************************************************
; Zoom speeds for each web
; *******************************************************************
zs_stuff:
        dc.l $400,$400,$400,$400,$400,$400,$400,$400
        dc.l $400,$400,$400,$400,$400,$400,$400,$400
        dc.l $400,$400,$400,$400,$400,$400,$400,$400
        dc.l $400,$400,$400,$400,$400,$400,$400,$400
        dc.l $400,$400,$400,$400,$400,$400,$400,$400
        dc.l $400,$400,$400,$400,$400,$400,$400,$400
        dc.l $400,$400,$400,$400,$400,$400,$400,$400

; *******************************************************************
; Spiker Z speeds for each web
; *******************************************************************
sz_stuff:
        dc.l $d000,$d000,$e000,$f000,$10000,$11000,$12000,$13000
        dc.l $d000,$d000,$e000,$f000,$10000,$11000,$12000,$13000
        dc.l $d000,$d000,$e000,$f000,$10000,$11000,$12000,$13000
        dc.l $d000,$d000,$e000,$f000,$10000,$11000,$12000,$13000
        dc.l $14000,$14000,$15000,$15000,$16000,$16000,$16000,$16000
        dc.l $15000,$16000,$16000,$17000,$17000,$18000,$18000,$18000
        dc.l $15000,$16000,$16000,$17000,$17000,$18000,$18000,$18000
        
; *******************************************************************
; Flipper z speeds for each web
; *******************************************************************
fz_stuff:
        dc.l $a000,$a200,$a400,$a600,$a800,$aa00,$ac00,$ae00
        dc.l $a800,$aa00,$ac00,$ae00,$b000,$b200,$b400,$b600
        dc.l $b000,$b200,$b400,$b600,$b800,$ba00,$bc00,$be00
        dc.l $b000,$b200,$b400,$b600,$b800,$ba00,$bc00,$be00
        dc.l $b000,$b200,$b400,$b600,$b800,$ba00,$bc00,$be00
        dc.l $c000,$c200,$c400,$c600,$c800,$ca00,$cc00,$ce00
        dc.l $d000,$d200,$d400,$d600,$d800,$da00,$dc00,$de00

; *******************************************************************
; Tanker z speeds for each web
; *******************************************************************
tz_stuff:
        dc.l $8000,$8000,$8800,$8800,$9000,$9000,$9800,$9800
        dc.l $8000,$8000,$8800,$8800,$9000,$9000,$9800,$9800
        dc.l $8000,$8000,$9800,$9800,$a000,$a000,$b800,$b800
        dc.l $8000,$8000,$9800,$9800,$a000,$a000,$b800,$b800
        dc.l $8000,$8000,$9800,$9800,$a000,$a000,$b800,$b800
        dc.l $a000,$a000,$b800,$b800,$c000,$c000,$c800,$c800
        dc.l $a000,$a000,$b800,$b800,$c000,$c000,$c800,$c800

; *******************************************************************
; Fuseball z speeds for each web
; *******************************************************************
fuz_stuff:
        dc.l $8000,$8000,$8000,$8000,$8000,$8000,$8800,$9000
        dc.l $9000,$9800,$a000,$a800,$b000,$b800,$c000,$c800
        dc.l $a000,$a800,$b000,$b800,$c000,$c800,$d000,$d800
        dc.l $a000,$a800,$b000,$b800,$c000,$c800,$d000,$d800
        dc.l $a000,$a800,$b000,$b800,$c000,$c800,$d000,$d800
        dc.l $c000,$c800,$d000,$d800,$e000,$e800,$f000,$f800
        dc.l $d000,$e800,$f000,$f800,$10000,$10800,$11000,$11800

; *******************************************************************
; Pulsar phase change delay for each web
; *******************************************************************
pudels: dc.w $0808,$0808,$0808,$0808
        dc.w $0808,$0707,$0606,$0505
        dc.w $0606,$0505,$0404,$0303
        dc.w $0606,$0505,$0404,$0303
        dc.w $0606,$0505,$0404,$0303
        dc.w $0606,$0505,$0404,$0303
        dc.w $0606,$0505,$0404,$0303

; *******************************************************************
; Power up delay for each web
; *******************************************************************
pup_stuff:
        dc.w $0404,$0505,$0606,$0606
        dc.w $0606,$0606,$0707,$0707
        dc.w $0808,$0808,$0808,$0808
        dc.w $0808,$0808,$0808,$0808
        dc.w $0808,$0808,$0808,$0808
        dc.w $0a0a,$0a0a,$0a0a,$0a0a
        dc.w $0f0f,$0f0f,$0f0f,$0f0f

; *******************************************************************
; Colours for each web
; *******************************************************************
webcols:dc.w 2,240,$ff,1,160,$f8,$88

; *******************************************************************
; Flipper colors for each web
; *******************************************************************
flipcols:
        dc.w 240,$48,$cb,$2b,$88,$fb,$80

; *******************************************************************
; Pulsar header values
; *******************************************************************
pucycl: dc.b 0,0,0,1,2,3,4,5,5,4,3,2,1,0,0,0

; *******************************************************************
; Claw animation sequence in classic mode
; *******************************************************************
uclaws: dc.l claw1,claw2,claw3,claw4,claw5,claw6,claw7,claw8

; *******************************************************************
; Initial viewpoints for each joy pad
; *******************************************************************
views:  dc.w 0,0,0,0    ;(x,y,z,?)
        dc.w 0,-1,-23,0
        dc.w 0,-3,5,0

; *******************************************************************
; Lookup table for drawing a pixel
; *******************************************************************
pixcols:dc.b 0,0,$f0,0,0,$0f,0,0,0,$80,0,$ff  ;11
        dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  ;30
        dc.b 0,0,0,0,0,$88,0,0,$55 

; *******************************************************************
; The 9 different objects in our object list. The first one is the
; main one and it is this one that the GPU and Blitter draws most
; stuff to.
; *******************************************************************
ObTypes:
        dc.w $60,279,4,0  ;384x280, 16bit
        dc.w $28,99,4,0    ;160x100
        dc.w $10,99,4,0    ;64x100, robot object
        dc.w 32,18,4,0    ;score object, truecolour
        dc.w 2,6,0,1    ;lives object, clutbase 2
        dc.w $30,239,3,0  ;384x240, 8bit
        dc.w $c,29,4,0    ;RMW object
        dc.w $60,32,4,0    ;32-pixel high bit of cry screen
        dc.w $60,48,4,0    ;48-pixel high bit of cry screen

        include "digits.dat"  ;actually now only the ship gfx

; *******************************************************************
; A sine table
; *******************************************************************
sines: .include "sines.dat"

; *******************************************************************
; A table for seeding random numbers
; *******************************************************************
rantab:
        .include "rantab.dat"
; *******************************************************************
; Table of the draw routines for all solid polygons in Tempest 2000
; *******************************************************************
solids: 
        dc.l rrts,cdraw_sflipper,draw_sfliptank,s_shot,draw_sfuseball,draw_spulsar,draw_sfusetank,ringbull,draw_spulstank  ;8
        dc.l draw_pixex,draw_pup1,draw_gate,draw_h2hclaw,draw_mirr,draw_h2hshot,draw_h2hgen,dxshot        ;16
        dc.l draw_pprex,draw_h2hball,draw_blueflip,ringbull,supf1,supf2,draw_beast,dr_beast3,dr_beast2        ;25
        dc.l draw_adroid            

; *******************************************************************
; Start of ROM
; *******************************************************************
romstart:
        dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

        .include "moomoo.dat"


        .include "obj2d.dat"
        .include "afont.dat"
        .include "bfont.dat"
        .include "cfont.dat"

        dc.l $a00000,0,$1000,$800,$1400000,0,$20000
        dc.l $80000,0,$8000,$2000,$1400000,-$1400000,$80000
        dc.l 0,0,$1000,$100,0,0,$40000
        dc.l $10000
        dc.l wave_stack
        dc.w 3
        dc.l web5,web11,web1,web2,web9,web3,web12,web7,web13,web4,web14,web10,web15,web6,web16,web8
        dc.l web5,web11,web1,web2,web9,web3,web18,web19,web20,web4,web14,web10,web17,web6,web16,web22
        dc.l web24,web23,web27,web25,web21,web28,web29,web30,web32,web33,web34,web35,web36,web37,web26,web31
        dc.l 0
        dc.l o2t1,o2t2,o2s1,o2s2,0,0

        dc.l pu1,pu2,pu3,pu4,pu5,pu6
        dc.w 50,50,$ffff,300,100,$8888,75,150,$2222,0
        dc.w 50,50,$ffff,1,300,100,$8888,$8f,75,150,$4444,$f0
        dc.w 160,88,$4000,$ff,224,88,$4000,$f0,191,119,$ffff,$88
        dc.w 224,88,$4000,$f0,224,152,$4000,$88,191,119,$ffff,$88
        dc.w 224,152,$4000,$88,160,152,$4000,$0,191,119,$ffff,$88
        dc.w 160,152,$4000,$0,160,88,$4000,$ff,191,119,$ffff,$88

        dc.w 160,88,$4000,$ff,224,88,$4000,$f0,191,119,$ffff,$88
        dc.w 224,88,$4000,$f0,224,152,$4000,$88,191,119,$ffff,$88
        dc.w 224,152,$4000,$88,160,152,$4000,$0,191,119,$ffff,$88

        dc.w 0,0,$4000,383,0,$4000,191,119,$ffff,$88
        dc.w 383,0,$4000,383,239,$4000,191,119,$ffff,$88
        dc.w 383,239,$4000,0,239,$4000,191,119,$ffff,$88
        dc.w 0,239,$4000,0,0,$4000,191,119,$ffff,$88

        dc.l $a000
        dc.w 4
        dc.w $1010
        dc.l $8000
        dc.l $8000
        dc.w 50
        dc.w $7070
        dc.l $18000
        dc.l $8000
        dc.w $3030
        dc.w $0404
        dc.l $8000

        dc.w $80,$16
        dc.w $40,$1c
        dc.w $2000,$100
        dc.w $800,$60

        dc.w $50,$09
        dc.w $70,$0f
        dc.w $6000,$280
        dc.w $c00,$c0
 
        dc.w $80,$16
        dc.w $40,$1c
        dc.w $2000,$100
        dc.w $800,$60


        dc.w 300
        dc.l screen1
        dc.l screen2
        dc.w $0505
        dc.l $10000
        dc.l $10000
        dc.l $02000000
        dc.l $20000000
        dc.l $00002000
        dc.w $0404    ;Pulsar spark propagation delay
        dc.w $0808
        dc.w -1
        dc.w 6
        dc.w 2
        dc.l $f80000
        dc.w 2
        dc.l $100000
        dc.l o3t1,o3t2,o3s10,o3s20,o3s3,0
        dc.b "jump        a",0,0,0
        dc.b "fire        b",0,0,0
        dc.b "superzapper c",0,0,0

        dc.l o5t1,o5t2,o5s10,o5s2,o3s3,0

defaults:
        dc.l 500017    ;0  -eeprom position
        dc.b 'yak',0    ;4
        dc.l 400000    ;8
        dc.b 'ewe',0    ;12
        dc.l 300000    ;16
        dc.b 'cow',0    ;20
        dc.l 200000    ;24
        dc.b 'gnu',0    ;28
        dc.l 100000    ;32
        dc.b 'ox ',0    ;36
        dc.l 90000    ;40
        dc.b 'elk',0    ;44
        dc.l 80000    ;48
        dc.b 'doe',0    ;52
        dc.l 70000    ;56
        dc.b 'moo',0    ;60
        dc.l 60000    ;64
        dc.b 'baa',0    ;68
        dc.l 50000    ;72
        dc.b 'fur',0    ;76
        dc.b 'beast',0,0,0,0,0  ;80

        dc.b "yak",0    ;90
        dc.b "cow",0    ;94
        dc.b "zoo",0    ;98
        dc.b "axe",0    ;102

        dc.b $7f,$7f    ;106
        dc.w 0      ;108
        dc.w 1      ;110
        dc.w 2      ;112
        dc.w $0100    ;114

        dc.w 0,0,0,0,0

        dc.b "1: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "2: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "3: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "4: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "5: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "6: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "7: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "8: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "9: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "10:.......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."



        dc.b "player 1 wins!",0
        dc.b "player one 0   player two 0",0
        dc.b "00000000 BONUS",0

        dc.b "aaa AT lvl   ",0,0,0,0,0,0,0
        dc.b "aaa AT lvl   ",0,0,0,0,0,0,0
        dc.b "aaa AT lvl   ",0,0,0,0,0,0,0
        dc.b "aaa AT lvl   ",0,0,0,0,0,0,0

        dc.l keyh1,keyh2,keym1,keym2,keym3,keym4,0
romend: dc.l 0

.even
.data

copstart:
        dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; *******************************************************************
; This contains the object code from syn6.o, which is the Imagitec
; 'mod' player for the Jaguar, adapted for Tempest 2K. 
; 'Mod' is a sound file format. All of the T2K tunes use the format.
; The Sound FX do not used the 'mod' format, they are just PCM data.
; The Imagitec Mod player is basically a 4 channel protrack mod player and 4 channels for sfx.
; https://forums.atariage.com/topic/157184-imagitec-designs-mod-player-informations/
; *******************************************************************
.include "moomoo.dat"
.include "obj2d.s"
.include "afont.s"
.include "bfont.s"
.include "cfont.s"
;  ***** END OF LONGALIGNED AREA

ixcon:  dc.l $a00000,0,$1000,$800,$1400000,0,$20000
iycon:  dc.l $80000,0,$8000,$2000,$1400000,-$1400000,$80000
iacon:  dc.l 0,0,$1000,$100,0,0,$40000
grndvel:dc.l $10000
wave_sp:dc.l wave_stack
lives:  dc.w 3
raw_webs:
        dc.l web5,web11,web1,web2,web9,web3,web12,web7,web13,web4,web14,web10,web15,web6,web16,web8
        dc.l web5,web11,web1,web2,web9,web3,web18,web18,web13,web4,web14,web10,web20,web6,web16,web21
        dc.l web24,web23,web27,web25,web21,web28,web26,web29,web30,web31,web32,web33,web34,web35,web36,web37
        dc.l 0
option2:dc.l o2t1,o2t2,o2s1,o2s2,o2s3,0

raw_pus:dc.l pu1,pu2,pu3,pu4,pu5,pu6
testpoly:
        dc.w 50,50,$ffff,300,100,$8888,75,150,$2222,0
testppoly:
        dc.w 50,50,$ffff,1,300,100,$8888,$8f,75,150,$4444,$f0
ppoly1: dc.w 160,88,$4000,$ff,224,88,$4000,$f0,191,119,$ffff,$88
ppoly2: dc.w 224,88,$4000,$f0,224,152,$4000,$88,191,119,$ffff,$88
ppoly3: dc.w 224,152,$4000,$88,160,152,$4000,$0,191,119,$ffff,$88
ppoly4: dc.w 160,152,$4000,$0,160,88,$4000,$ff,191,119,$ffff,$88

pypoly1:dc.w 160,88,$4000,$ff,224,88,$4000,$f0,191,119,$ffff,$88
pypoly2:dc.w 224,88,$4000,$f0,224,152,$4000,$88,191,119,$ffff,$88
pypoly3:dc.w 224,152,$4000,$88,160,152,$4000,$0,191,119,$ffff,$88

poly1:  dc.w 0,0,$4000,383,0,$4000,191,119,$ffff,$88
poly2:  dc.w 383,0,$4000,383,239,$4000,191,119,$ffff,$88
poly3:  dc.w 383,239,$4000,0,239,$4000,191,119,$ffff,$88
poly4:  dc.w 0,239,$4000,0,0,$4000,191,119,$ffff,$88

flip_zspeed:     dc.l $a000
flip_rospeed:    dc.w 4
flip_pause:      dc.w $1010
tank_zspeed:     dc.l $8000
spiker_zspeed:   dc.l $8000
spiker_build:    dc.w 50
a_firerate:      dc.w $7070
ashot_zspeed:    dc.l $18000
fuse_zspeed:     dc.l $8000
fuse_risetime:   dc.w $3030
fuse_crossdelay: dc.w $0404
pulsar_zspeed:   dc.l $8000

pgens:  dc.w $80,$16
        dc.w $40,$1c
        dc.w $2000,$100
        dc.w $800,$60

        dc.w $50,$09
        dc.w $70,$0f
        dc.w $6000,$280
        dc.w $c00,$c0
 
        dc.w $80,$16
        dc.w $40,$1c
        dc.w $2000,$100
        dc.w $800,$60

pgenctr:  dc.w 300
cscreen:  dc.l screen1
dscreen:  dc.l screen2
droidel:  dc.w $0505
palad2:   dc.l $10000
palad3:   dc.l $10000
fire_2:   dc.l $20000000
fire_1:   dc.l $02000000
fire_3:   dc.l $00002000
prop_del: dc.w $0404    ;Pulsar spark propagation delay
pupcount: dc.w $0808
holiday:  dc.w -1
npolys:   dc.w 6
selected: dc.w 2
delta_i:  dc.l $f80000
tunc:     dc.w 2
cg_cnt:   dc.l $100000
option3:  dc.l o3t1,o3t2,o3s10,o3s20,o3s3,0

o4s1: dc.b "jump        a",0,0,0
o4s2: dc.b "fire        b",0,0,0
o4s3: dc.b "superzapper c",0,0,0


option5: dc.l o5t1,o5t2,o5s10,o5s2,o3s3,0

hscom1: dc.l 500002
        dc.b 'yak',0
        dc.l 400000
        dc.b 'ewe',0
        dc.l 300000
        dc.b 'cow',0
        dc.l 200000
        dc.b 'gnu',0
        dc.l 100000
        dc.b 'ox ',0
        dc.l 90000
        dc.b 'elk',0
        dc.l 80000
        dc.b 'doe',0
        dc.l 70000
        dc.b 'moo',0
        dc.l 60000
        dc.b 'baa',0
        dc.l 50000
        dc.b 'fur',0
        dc.b 'goaty boy',0

keys:   dc.b "yak",0
        dc.b "cow",0
        dc.b "zoo",0
        dc.b "axe",0

vols:   dc.b $ff,$ff
firea:  dc.w 0
fireb:  dc.w 1
firec:  dc.w 2
sysflags: dc.w 0
        dc.w 0,0,0,0,0

hstab1:
        dc.b "1: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "2: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "3: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "4: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "5: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "6: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "7: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "8: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "9: .......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."
        dc.b "10:.......;;;;;;;;;;..........;;;;;;;;;;..........''''''''''...."

wonmsg: dc.b "player 1 wins!",0
rndmsg: dc.b "player one 0   player two 0",0
csmsg1: dc.b "00000000 BONUS",0

keym1:  dc.b "aaa AT lvl   ",0,0,0,0,0,0,0
keym2:  dc.b "aaa AT lvl   ",0,0,0,0,0,0,0
keym3:  dc.b "aaa AT lvl   ",0,0,0,0,0,0,0
keym4:  dc.b "aaa AT lvl   ",0,0,0,0,0,0,0

option8:dc.l keyh1,keyh2,keym1,keym2,keym3,keym4,0
copend: dc.l 0

; *******************************************************************
; Data to be zeroed, or which is explicitly set up
; *******************************************************************
zerstart:

the_option:       dc.l 0
grnd:             dc.l 0
cwave:            dc.w 0
wave_ptr:         dc.l 0
wave_stack:       dcb.l 32,0
wave_tim:         dc.w 0


keyplay:          dc.w 0
akeys:            dc.w 0
ofree:            dc.w 0
activeobjects:    dc.l 0
freeobjects:      dc.l 0
i_activeobjects:  dc.l 0

                  ; Current Joypad reading
pad_now:          dc.l      0,0  ; xxApxxBx RLDU741* xxCxxxox 2580369#
pad_2:            dc.l 0

                  ; OneShot Joypad reading
pad_shot:         dc.l      0,0

term:             dc.w 0    ;to terminate the mainloop

_demo:            dc.l it
vertex_ptr:       dc.l vertex_ram
connect_ptr:      dc.l connect_ram
webs:             dcb.l 48*50,0
cweb:             dc.w 0
long:             dc.l 0
tv:               dcb.l 2000,0
skore:            dc.b 0,0,0,0,0,0,0,0
lbonus:           dc.b 0,0,0,0,0,0,0,0
score:            dc.l skore
web_z:            dc.w 0
web_x:            dc.w 0
web_ptab:         dc.l 0
web_otab:         dc.l 0
web_max:          dc.w 0
web_firstseg:     dc.l $7000
_pus:             dc.l 0,0,0,0,0,0
spikes:           dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
spikescratch:     dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
evon:             dc.w 0
_oneup:           dc.l 0
_cube:            dc.l 0
_chevre:          dc.l 0
_ev:              dc.l 0
_la:              dc.l 0
_pu:              dc.l 0
szap_avail:       dc.w 0
szap_on:          dc.w 0
_sz:              dc.w 0
bulls:            dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
bully:            dc.w 0
lanes:            dc.l 0

_bons:            dc.l 0,0,0

afree:            dc.w 12
shots:            dc.w 7,7
ashots:           dc.w 3
_web:             dcb.l 16,0
_claw:            dc.l 0
_shot:            dc.l 0
_flipper:         dc.l 0
_zap:             dc.l 0
_fliptank:        dc.l 0
_fusetank:        dc.l 0
_pulstank:        dc.l 0
_spike:           dc.l 0
_spiker:          dc.l 0
_fuse1:           dc.l 0
_fuse2:           dc.l 0

webcol:           dc.w 0
flipcol:          dc.w 0

objects:          dcb.l 64*16,0    ;room for 64 64-byte Objects

pudel:            dc.w $0808
pucnt:            dc.w 0

timer:            dc.w 0

connect:          dc.w 0
claws:            dc.l 0,0,0,0,0,0,0,0

pgenphase:        dc.w 0

tmtyl:            dc.l 0
vp_sf:            dc.l 0
vp_sfs:           dc.l $10000
span:             dc.l $3fff
spany:            dc.w 0
zapdone:          dc.w 0
ud_score:         dc.w 0
nbeasties:        dc.w 12
beasties:         dcb.l 286,0
startbonus:       dc.w 0
warp_count:       dc.l 2
warp_add:         dc.l $10000
warp_flash:       dc.l 0
warp_phase:       dc.w 0
        dcb.l     200,0
stack:            dc.l 0
routine:          dc.l rrts
fx:               dc.l rrts
vadd:             dc.l 0
vp_x:             dc.l 0
vp_y:             dc.l 0
vp_z:             dc.l 0
vp_xtarg:         dc.l 0
vp_ytarg:         dc.l 0
vp_ztarg:         dc.l 0
vp_zbase:         dc.l 0

max_spikers:      dc.w 0
view:             dc.w 0
screaming:        dc.w 0
bink:             dc.l 0
clawv:            dc.l 0
clawa:            dc.l 0
sf_on:            dc.w 1
s_routine:        dc.l 0
sync:             dc.w 0
screen_ready:     dc.w 0
db_on:            dc.w 0
elist:            dc.l 0
gscreen:          dc.l 0
mainloop_routine: dc.l 0
imsk:             dc.w 0
paws:             dc.l 0
frames:           dc.w 0
count:            dc.w 0
locked:           dc.w 0
players:          dc.w 2
camrx:            dc.w 0
camry:            dc.w 0
camrz:            dc.w 0
camroll:          dc.w 0
entities:         dc.w 0
droid_data:       dc.l 0
bulland:          dc.w 0
bullmax:          dc.w 0
claud:            dc.l 0
diag:             dc.l 0,0,0,0,0,0,0,0
plc:              dc.l 0
flashcol:         dc.w 0
cursx:            dc.w 0
cursy:            dc.w 0

pongang:          dc.w 0

pongx:            dc.l 0
pongy:            dc.l 0
pongz:            dc.l 0
pongxv:           dc.l 0
pongyv:           dc.l 0
pongzv:           dc.l 0
pongscale:        dc.l 0
pongscale2:       dc.l 0
pongphase:        dc.l 0
pongphase2:       dc.l 0

palad0:           dc.l 0
palad1:           dc.l 0
palphase1:        dc.l 0
palphase2:        dc.l 0

demo_routine:     dc.l 0
demobank:         dc.l 0
fxnum:            dc.b 0,0,0,0,0,0,0,0
numin:            dc.l 0
blanka:           dc.w -1
e_attract:        dc.w 0
wave_speed:       dc.w 1

laser_type:       dc.w 0
jenable:          dc.w 0

bonum:            dc.w 0
priors:           dcb.l 4*64,0
fpriority:        dc.l -1
apriority:        dc.l -1
oopss:            dc.l 0,0,0,0
feedline:         dc.l 0
centrx:           dc.l 0
centry:           dc.l 0
pc_1:             dc.l      0
pc_2:             dc.l      0
ranptr:           dc.w 0
rpcopy:           dc.w 0
selectable:       dc.w 0
t2k:              dc.w 0
pawsed:           dc.w 0
wpt:              dc.w 0
noclog:           dc.w 0
cjump:            dc.l 0
popo1:            dc.w 0
popo2:            dc.w 0
boltx:            dc.l 0
bolty:            dc.l 0
boltz:            dc.l 0
bolt_lock:        dc.w 0
shotspeed:        dc.l 0
dotile:           dc.w 0
polsizx:          dc.w 0
polsizy:          dc.w 0
polspd1:          dc.w 0
polspd2:          dc.w 0

msg:              dc.l 0
msgtim1:          dc.w 0
msgtim2:          dc.w 0
msgxv:            dc.l 0
msgyv:            dc.l 0
msgxs:            dc.l 0
msgys:            dc.l 0
m7x:              dc.l 0
m7y:              dc.l 0
m7yv:             dc.l 0
m7z:              dc.l 0
v_on:             dc.w 0
l_on:             dc.w 0
cg_ptr:           dc.l 0
cg_tim:           dc.w 0
noxtra:           dc.w 0
x_end:            dc.w 0
tbbptr:           dc.w 0
ltail:            dc.l 0
tunadd:           dc.w 0
tuncnt:           dc.w 0
victree:          dc.w 0
psycho:           dc.w 0
rocnt:            dc.w 0
warpy:            dc.w 0
selbutt:          dc.l 0
sbg:              dc.w 0
solidweb:         dc.w 0
l_solidweb:       dc.w 0
l_soltarg:        dc.w 0
weband:           dc.w 0
webbase:          dc.w 0
entxt:            dc.w 0,0,0,0,0,0,0,0
ennum:            dc.w 0
enmax:            dc.w 0
enl1:             dc.l 0
enl2:             dc.l 0
enl3:             dc.l 0
fw_x:             dc.l 0
fw_y:             dc.l 0
fw_z:             dc.l 0
fw_dx:            dc.l 0
fw_dy:            dc.l 0
fw_dz:            dc.l 0
fw_dur:           dc.w 0
fw_col:           dc.w 0
fw_del:           dc.w 0
fw_ptr:           dc.l 0
fw_sp:            dc.l 0
fw_stack:         dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
fw_sphere:        dc.w 0
h2h:              dc.w 0
h2h_sign:         dc.w 0
h2hor:            dc.w 0
practise:         dc.w 0
l_ud:             dc.w 0
r_ud:             dc.w 0
l_sc:             dc.w 0
r_sc:             dc.w 0
_won:             dc.w 0
z:                dc.w 0
optpress:         dc.w 0
pauen:            dc.w 0
auto:             dc.w 0
attime:           dc.w 0
csmsg:            dc.l 0
fskore:           dc.b 0,0,0,0,0,0,0,0
inf_zap:          dc.w 0
sflip_prob1:      dc.w 0
sflip_prob2:      dc.w 0
sflip_prob3:      dc.w 0
show_warpy:       dc.w 0
bolev1:           dc.w 0
bolev2:           dc.w 0
bolev3:           dc.w 0
tunspd:           dc.l 0
sfxo:             dc.l 0
sfyo:             dc.l 0
butty:            dc.l 0
botty:            dc.w 0
zoomspeed:        dc.l 0
joby:             dc.w 0
t2k_max:          dc.w 0
t2k_high:         dc.w 0
trad_max:         dc.w 0
trad_high:        dc.w 0
topsel:           dc.w 0
vadj:             dc.l 0
pit0:             dc.w $400
pit1:             dc.w $c00
vset:             dc.l 0
modtimer:         dc.w 0
modnum:           dc.w 0
lastmod:          dc.w 0
_auto:            dc.w 0
sfx:              dc.w 0
sfx_pri:          dc.w 0
sfx_vol:          dc.w 0
sfx_pitch:        dc.l 0
tblock:           dc.w 0
rounds:           dc.w 0
p1wins:           dc.w 0
p2wins:           dc.w 0
beastly:          dc.w 0
gb:               dc.w 0
dnt:              dc.w 0
pframes:          dc.w 0
handl1:           dc.w 0
handl2:           dc.w 0
handl:            dc.w 0
zoopitch:         dc.l 0
modstop:          dc.w 0
wason:            dc.w 0
wapitch:          dc.l 0
pausprite:        dc.w 0
tunon:            dc.w 0
fxon:             dc.w 0
psmsgtim:         dc.w 0
oldvol:           dc.w 0
s_db:             dc.w 0
_pauen:           dc.w 0
misstit:          dc.w 0
wson:             dc.w 0
yespitch:         dc.l 0
yesnum:           dc.w 0
p2smarted:        dc.w 0
dying:            dc.w 0
lastlives:        dc.w 0
flock:            dc.w 0
unpaused:         dc.w 0
ppad:             dc.l 0
vvol1:            dc.w 0
vvol2:            dc.w 0
paucopy:          dc.w 0
warped:           dc.w 0
noup:             dc.w 0
lstcon:           dc.w 0,0
conswap:          dc.w 0
rot_cum:          dc.l 0,0
pitcount:         dc.w 0
roconon:          dc.w 0
roconsens:        dc.l 0,0
tuntime:          dc.w 0
whichclaw:        dc.w 0
mint:             dc.w 0
ppit1:            dc.w 0
roach:            dc.l 0
mfudj:            dc.w 0
palside:          dc.w 0
paltop:           dc.w 0
palfix1:          dc.w 0
palfix2:          dc.w 0,0
palfix3:          dc.l 0
bshotspeed:       dc.l 0
outah:            dc.w 0
chenable:         dc.w 0
finished:         dc.w 0
drawhalt:         dc.w 0
zerend:           dc.l 0,0
                  dcb.l 32,0
list1:            dcb.l 124,0
                  dcb.l 32,0
list2:            dcb.l 124,0
blist:            dc.l list1
dlist:            dc.l list2
ddlist:           dc.l 0


.bss
.phrase

vertex_ram:       .ds.l     6000
connect_ram:      .ds.l     4000
wave_dur:         .ds.w     1
wstuff:           .ds.w     64
linebuff:         ds.b 64

epromcopy:        ds.b 128


