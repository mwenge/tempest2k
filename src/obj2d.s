; ***********************************************************************************
; Welcome to the Motorola 68K Assembler source code for 'Tempest 2000' by Jeff Minter.
;                                                             
;                                'i;             'v;          
;                              :tJ)               =Tu=        
;                            =jGJ'                 `zkw)      
;                          \JAA*                     %YKF%    
;                       _lF8$m=                       '2DHVI: 
;                       )F&$$ws"`                   .=lu@HKh% 
;                         ^?68@@P31):           _\!fg@KKht"   
;                            =!m8@@@YSLr+.  ^x76bKKKKde"      
;                               +]q&@@@@8E5d&KKKK@do|         
;                                  /1S8@@@@KKK@47\            
;                                     "1g&@$4z\.              
;                                        )1i.                 
;
;                     Fig 1. Ascii rendering of the 'claw'.
;                                                                                                                 
; This source code was originally 'leaked' by 'JaySmith2000' in August 2008,
; who solid it on CD as part of a release entitled the 'Jaguar Sector II Source Code
; Collection':
;  https://web.archive.org/web/20131117222232/http://www.jaysmith2000.com/Jagpriceguide.htm
;
; This is a cleaned-up and commented version of the source code file 'obj2d.s'.
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
; obj2d.s contains the data structures for 2d enemy and player objects.
; ***********************************************************************************
;
; s_flipper
;   -:.                                 _-
;    _/:.                             _^_ 
;     _|":.                         _^+_  
;      _||/:.                     _^++_   
;       _|||/'.                 _^++=_    
;        _||||/'.             _^+===_     
;         _|||||/'          _^+====_      
;          _||||||/'      _^++====_       
;           _"||||||+'. _;++++++=_        
;            +)>>>>>)i=_^^;;;;;^:         
;           ^vvvvv%%\:  .',,,,,,,-        
;          ^vvvv%%\:      .',,,,,,-       
;         ^vvv%%<:          .',,,,,-      
;        ;vv%%<:              `',,,,-     
;       ;v%%<:                  `',,,-    
;      ;%%<,                      `',,-   
;     ;%<,                          `',-  
;    ;<;                              `:- 
;   ';.                                 ``

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

; 
; s_fliptank
;                                         
;                    "[]|.                
;                 `\tfy#Tt)-              
;               _veCyy3#TT#7x'            
;             ,rzJw32#sczJ#T#j{^          
;           +}u#Jy3Lx_  -v7wCT#u?/        
;        .)]n#Tfyo>`      .<affJJT1\.     
;      -)aT#TJC1\_          ./!w2fwJov_   
;    :x7#TnnLI^  ^/^_.   .-'_  ;*Tyyyyus; 
;   =7yfCCwu|     +""=_.':,:.    +jJJJwfj"
;    '%zfyyyC!/  ,^:`    ._:'  =IunnT#o%' 
;      .\1#wf3ya>-          `)1wJT#Tt>`   
;         /?uJJfyzv-      `)7ywT#n!|.     
;           ^{j#TJwur:  'cu3yJ#L*=        
;             'x7#TTJu{{#23fJzl,          
;               -)tT#T#yyyCei_            
;                 .|!uTyw1\.              
;                    /!t"                 
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

; 
; s_fliptank2
;            -,"i^        +)/:`           
;    ._,/>lI17LnTzv;.  `^cLTujo1}c>/,-.   
; '\r[7n#JJ##TTnnTu}>/")?nnnnTT#JJJ#uo!c|_
;  .-:^">x{?tojLunTT!%x1#Tnuj7a]}li)+;'`. 
;           ._,/<%l*]rs?lv\/,-.           
;       .-',=/|\>)iv)/"ii)><|"=;:_`.      
; `:=|<)v%xxxcccxxci/^="vcxxcccxx%vi>\"=:.
; .-';+|<)v%xccxxx>^_..'=)xxxccx%v)<|=;'` 
;         `_,+|>v|-      _\v<|=,_`        

; 
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


; fbpiece1
;                                         
;                      :,                 
;                   `,/}qTx;              
;                `,"<><Idddqux,           
;             `,/<>>>><IdVVVddSjl'        
;          `,"<))))>><|lyFSVdddddqux'     
;       `:"<<<|"+;,_-`   -:|<s?oTymgpu%^  
;     `'^^:_`.                    ',<xI?<;

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

; fbpiece2
;                                         
;     `-`.                            -;;'
;     .-^/|"=;:_`.           `_=\iI1TJz}=`
;         '=\))>>\)"/^,=v{]L#56hddd5[<`   
;            '=\>))>>)<?dddddddV5]\.      
;              ._+\>>>\IdVddd3t|`         
;                 .'+\<IdV2a\`            
;                    .'x7v`               


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

; 
; spuls1
;                                         
;                                         
;                                         
;                   _3z                   
;                  :S$$#.                 
;                 /EEc?YF_                
;                )d7_  ;wm^               
;               %T|      %T|              
; -           ."i         _%^            _
; <%         "c_            ;r;        _l+
;  cC)     -o7_              =#I      cC) 
;   iEj_  x4L.                '56)  ^fS=  
;    "XX*f8[                   .J&7[k6'   
;     ;S$&r                      o$$J`    
;      '2c                        aT      

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

; spuls2
;                                         
;                                         
;                                         
;                    .                    
;                   /Sf'                  
;                  {O$$g<                 
;                _#Of>cmk1                
;               \2T/    >y#^              
; `           .)*^        )*/.           -
; ^\:       `vi_            ^I%        "x;
;  ,rc;   'snx.              _76{`   \7!' 
;   .%tr|I5J/                  lGE!in2c   
;     /]Jg[`                    ^p8qn+    
;      'tl                       .ze-     

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

; spuls3
;                                         
;                                         
;                                         
;                                         
;                    `                    
;                   iSp|                  
;                 =JYZ$UL:                
;               '[mf{^|tSh}`              
; `           `^sc:      =}{;`          .`
; _++_     -)x"`            'x?<`    .^i\_
;  .+%v/;<!jI;                <Jp7i+ct]|  
;    `)l[we"                   .rm4noi.   
;      '{x.                      :e?:     

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

; spuls4
;                                         
;                                         
;                                         
;                                         
;                                         
;                    _.                   
;                  :}md?'                 
;               ."e6gSA$Zj/               
; ..         .-,l[})=',\{7L{,'.         ``
; `:=^,__^|vli;`.          `_<!t*i/:=\i)=`
;   `;")ca[c^                 `>72y!Il/`  
;      'i%:                      "1l^     

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

; spuls5
;                                         
;                                         
;                                         
;                                         
;                                         
;                                         
;                    '_                   
;                .^lzSGw{^                
; .`-```_:::,;':xofF5mbYbd#l:^/==^^'''':'`
; ._;+""%1]Ic|'-'_-``-____::-+le#fJ*srv|:.
;     -,)c"_                    ^xtx"'    

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

; spuls6
;                                         
;                                         
;                                         
;                                         
;                                         
;                                         
;                                         
;       ``          `;;`         ._`.     
; .-';^^)Isx>":'<*oJ2VAPSJ[>'+v}tjLci>|+:`
; .`-',;>s%</;--=>stupgpu!%+-:"is[ev\"=:-.

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


; chevron
;                                         
;                                         
;                                         
;                                    '^^=-
;                           ',:\)>r}I[}|- 
;                  '''\<<{{{][[1tta1r+    
;        -=="x%c!!]eoo777oooooooo1i:      
;        _|">t1e232ggghhhSSSqqqqS5?,      
;               `.-\\<1tty22ghhhhVdme|    
;                        ```)<<!eaC5pmTi- 
;                                 .__|c%v:
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

; chev
;                                         
;                                         
;                                    `_-\ 
;                              -;,<x%?[]t.
;                        `//\{s?t1ttt1111.
;                `--\<<II?ttttt1111111111.
;          -;;<cx?]]ttt111111111111111111.
;          _=^isr]11ttt111111111111111111.
;                _''>)i!!!ttt1t1111111111.
;                      ``_)|)I*!ttttt1111.
;                              _=^)ll![[t.
;                                    _::v.

chev: dc.l 1

	dc.w $44
	dc.w 2,$c000
	dc.w 1,$ffff
	dc.w 0,$4000
	dc.w 0

goatverts: dc.w 1,9,4,8,4,10


; pshot
;                                         
;                      `           -      
;                   .+l{,         =}x^    
;                 -|s!!!I=       "?!!!l/` 
;                ;l!]!!?!?/     \!??!!]?%:
;                 .'/)l}!]!)   )]!?*c>='. 
;                      -^\%{\-){v|;`      
;                         `+v|v^.         
;                    .'/>lII= "?}c<='     
;                -^)%{I!!]*,   =I]!!Isv|;`
;                '%?]!??!r'     ;*!??![?)_
;                  '>*!!c-       's!!{\_  
;                    _<%`         _c|`    

; 
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

; pwrlaser
;                                         
;                                    _|   
;                                   /t{   
;                                 .x7js   
;                                ;?j7zs   
;                               >ez77zs   
;                             '{z7777zs   
;                            |tz77777zs   
;                          -c77777777zs   
;                         =]j77777777zs   
;                       .i7z777777777zs   
;                      :Iz7oo77777777z{`-`
;                      '^;;;;I77777777ea!;
;                            *z7777777z1; 
;                            *z777777j?'  
;                            *z77777j{`   
;                            *z7777zc.    
;                            *z7777i      
;                            *z77o\       
;                            *z7e/        
;                            *j1^         
;                            I[:          
;                            v'           
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


; g1
;                                         
;                                         
;                                       "\
;                                    /!j1^
;                                 +?eyF#; 
;                              +Ie35233|  
;                           /}e3523yy5r   
;                        /{e3523yyyy5t.   
;                     /re3523yyyyyy2T;    
;                  /le3523yyyyyyyy3y<     
;               "xe3523yyyyyyyyyyy5{      
;            "%e352333333333333335e       
;        ."vey23yyyyyyyyyyyyyyyyyu;       
;        -%!juuLjjjjjjjjjjjjjjjju*`       
;           '%}oLLjzzzzzzzzzzzzzzu%       
;              '%?oLLjjjjjjjjjjjjjL/      
;                 '%!oLLjjjjjjjjjjje'     
;                    '%]oLLjjjjjjjjLI`    
;                       '%[oLjjjjjjjuv    
;                          'v1oLjjjjjL+   
;                             'vtoLjjje-  
;                                'vtoLuI. 
;                                  .'vt7%.
;                                     `:%)
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

; g2
;                                         
;                                       ;=
;                                    ,vsx:
;                                 ,vl[tI' 
;                              ,il[1[[[^  
;                           ;)l[1[[[[1<   
;                        ;>l[1[[[[[[1c.   
;                     ;<l[1[[[[[[[[[}'    
;                  ;\l[1[[[[[[[[[[[]=     
;               ;)l[1[[[[[[[[[[[[[1>      
;            ;"l]1[]]]]]]]]]]]]]]1l       
;        ./<{1at1111111111111111t*'       
;        _saw22yyyyyyyyyyyyyyyyy2t-       
;           ,{ewF5233333333333333F{       
;              ,{ow5523333333333335)      
;                 :{zw5523333333332C,     
;                    :{jw52233333335e-    
;                       :{uw52233333Fs    
;                          :{nw5223332|   
;                             :sTw5222C_  
;                               .:sTw5Fo` 
;                                  .:sTy{.
;                                     `;*c

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


; arr
;                                         
;                          ^em]:          
;                        |nZ&&&X7=        
;                      vyk&&AAA&&b#\      
;                   -{m&&AAAAAAAA&&O2x.   
;                 =tg88&AAAAAAAAAAA&88V!: 
;                <u52yyG&AAAAAAAAA&gyy22z"
;                      m&AAAAAAAAA&J      
;                      m&AAAAAAAAA&J      
;                      m&AAAAAAAAA&J      
;                      m&AAAAAAAAA&J      
;                      m&AAAAAAAAA&J      
;                      m&AAAAAAAAA&J      
;                      q&&&&&&&&&&&C      
;                      2PPPPPPPPPPGu      

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

; dchev
;                                         
;                                         
;                           .:            
;                         .)c/]v          
;                       _%u[_ ^f2c`       
;                     :sT2I    _#GFI:     
;                   =?J3yl      .oPXSt=   
;                `<ey23wv         [gPG4n>`
;                ^%xvv%"   `|\>.   v{s{}s=
;                        _xo\.{wl`        
;                      :r##/   x46}:      
;                    =?J2L;     \gPqt=    
;                 .)tf33e'       /FXXdL\. 
;                +[#JT#t-         ^ySShqo+
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

; epyr
;                                         
;                     "|                  
;                    |{{<.                
;                  .<{ss{).               
;                 `){ssss{v-              
;                -v{ssssss{%_             
;               _x{ssssssss{c:            
;              :c{ssssssssss{l;           
;             ;l{ssssssssssss{r=          
;            =rsssssssssssssssss/         
;           /sssssssssssssssssss{|        
;          |{ssssssssssssssssssss{<.      
;        .<{ssssssssssssssssssssss{).     
;       `){ssssssssssssssssssssssss{v-    
;      -v{ssssssssssssssssssssssssss{%_   
;     _x{ssssssssssssssssssssssssssss{c:  
;    :c{ssssssssssssssssssssssssssssss{l; 
;   'xllllllllllllllllllllllllllllllllllc;

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

; xbit
;                                         
;                                         
;                                         
;                                         
;                                         
;                                         
;                                         
; `_'_-.                                  
;   .'^//+^:_`                            
;       -;/)<\|/=;:-.                     
;          .'=|\<<<\)|/=;'-.              
;              -;/)<<\\<<\\)"/^,'-.       
;                 .'=|\\\\\\\\<<\\)"/=;'`.
;                 ._^|\\\\\\\\<<<\)|"=;:-.
;              `,/)\<\\\<<\)|/=;:-.       
;          ._^"\<<<\\|"=^:_`.             
;       `:+)<\)"+^:_`.                    
;   ._;+"/=,_`.                           
; ._::_`                                  
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

; mirr
;                                         
;                    .+snhwr;             
;                :)tFYB000NW8q1|.         
;           ./{#4$R000RRRNDBBNNKXT%'      
;       :iepYB000RRRRRRRRNDBBBBBWNBk5?=   
;   '{Jg@R00RRRRRRRRRRRRRNDBBBBBBBBWNN@d7|
;   cGY&@BMRRRRRRRRRRRRRRNDBBBBBBBBBBHUYXJ
;   cEhhhdgb&KWRRRRRRRRRRNDBBBBBBBKOXgm6mT
;   cEVVVVVhhV4Pk$BMRRRRRNDBBBDUb4q66mmmqT
;   cEVVVVVVVVVhhhdgb&KWRRBH&Phm66mmmmmmqT
;   cEVVVVVVVVVVVVVVVVddddqmmmmmmmmmmmmmqT
;   cEVVVVVVVVddddVgpyTjot[ajC5mqqmmmmmmqT
;   cEVVVVddddhm2Cu7eeeooot11[t7T36qqmmmqT
;   cEdddVSpfTjoeeeooooooot11111[1eufFmqS#
;   cES5Cu7eeeoooooooooooot1111111111tjCpT
;   '>xI1o777ooooooooooooot11111111ttt[{)=
;       _=){[e777ooooooooot11111tat!l|'   
;           .:|xIto777oooot1tta1Iv=-      
;                -=>s]e77ott]s<,.         
;                    .,)c!r|_             

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

; h2hshot1
;                                         
;                   ,'                    
;                   `l;                   
;                    +1=     .)'          
;                     re|  -%J}.          
;                     :tai{fhj.           
;                      veuSSf:            
;   ..                 -!um6)             
;   `^|)v)|^_.          )nS{              
;      `^>*en#LaIl>";_. .e7               
;           `/[5FpF5y#7I)iv'              
;          `\[uLo[*%\='`. )Tei,           
;         ^%l>+'`          +fSfec/`       
;         .                 :ngm5C7}<:    
;                            -oSm65fJu1%=`
;                             .[qm6q!/""+_
;                               *mmSs     
;                                x6g{     
;                                 <p*     
;                                  \x     

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

; h2hshot2
;                                         
;                   :'                    
;                   `%;                   
;                    =I^     ./_          
;                     x]/  `<ax           
;                     '!]<%oJ].           
;                      >]a##7_            
;    .                 -*aTn/             
;   .,=|\|+,-.          "e#%              
;      `,|%I1t]*c)|=:-.  !?               
;           .^{nTTTnLe!l))<_              
;          `|Ioe1Il)|^'`  /t?<:           
;         ;i%\^'.          ;7Jj!%=`       
;         .                 '1#Tnj1r|'    
;                            `I#TnuLjo?i^`
;                             .s#TnTr=+/^_
;                               %TT#v     
;                                >uJv     
;                                 "u%     
;                                  />     

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


; leaf
;                         .               
;                    -:/>%{v"_            
;              .:^\%rI?!!!!!!?l\;.        
;        .-^|)r{?!!!!!!!!!!!!!!!!{i/-     
;  ._,")x*I!]]!!!!!!!!!!!!!!!!!!!!]]Ic\:. 
; `,"<)iii))>>>>>>>>>>>>>>>>>>>>>>>>)ii>=.
;     .`_:,^=+////////////////////////;-  
;            .`':;=+/""""""""""""""/;`    
;                   .-':^=+/"""""+:.      
;                         .`_';^'         

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

; blueflipper
;   `:.                                .^:
;    _+:.                            .;<; 
;     _"/'.                        .;<v;  
;      _/"+'.                    .;<vi,   
;       _/""+'                 .,<vii;    
;        _/"""+'              ,<iiii;     
;         _/""""+'          ,\viiii;      
;          _/"""""='      ,\viiiii;       
;           _//////"=' .,\vviiiii;        
;            =<<<<<<>>^,\\\))))\=         
;           ;iiiiivv):  -^/"/////:        
;          ;iiiiii):      -^"""""":       
;         ;iiiii\:          -^""""":      
;        ;iiii\:              -^"""":     
;       ;ivi\:                  -="""'    
;      ;iv\:                      -="":   
;     ;i<:                          _=":  
;    ;\,                              _=' 
;   ';                                  __

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

; s_flip1
;                                         
;                                         
;                                         
;                                         
;                     -'.                 
;                .,\%>,=r[r/`             
;            '/%!7or^    /t6gw[i;         
;       -=)*aLJJa)-        _r5bYEpu}\'    
;   -\{tL#JJ##I=              "jPbbbZ4Fjl:
;   `=i*aL#JJ#1>-            _cyZbbZ4puI<_
;        _+iIenJLs^        +edYPmT?>,     
;             '"c[eI)-  _vu6yt%^.         
;                 `=>)^/{*<_              

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

; s_flip2
;                                         
;                                         
;                                         
;                    `zn_                 
;                   <h@@4i                
;                 `1PZY88Az_              

;              _/vapVkU$8AOp]),           
;         .,\r1jT2EA$$$$$$U&kG457l+`      
;     -=iIon#JJ5X8$$$$$$$$$$U&YbbbXq#?<:. 
;   'ce#CCJ#T#V$$$$$$$$$$$$$$U$AGGGbkObqa+
;    .'/%!7TJJCFPU$$$$$$$$$$$&YbbbPgw1i^` 
;         `^>*aL#5g&$$$$$$U&OZE6u*|_      
;              '|xo6dkU$8AOma%^.          
;                 _ePGY88&n'              
;                   id@@gx                
;                    _J3,                 

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

; hornm1
;                                         
;                                         
;                                         
;                                         
;                                         
;                  '/||||||||||=-         
;             -=)*aLTTTTTTTTTTTnz[l\,.    
;         ,\l[7LLLLjLnuuuuuuuuujLLLLLeI%/_
;        :jTTTTz!cv%}Tuuuuuuunjxv%rtuTTTT[
;        :unuuunnj]l{Tuuuuuuunj%{auTnuuun1
;        :LnuuuuunTL7nuuuuuuunL7nTnuuuuun1
;        :nTnnnnnnnTTnnnnnnnnnnTnnnnnnnT#t
;        _{[e777ooooooooooooooooooooooe1?v
;           '+>l}![[]]]]]]]!??I}*{lv\+'.  
;               `;)c*}{srlc%%vv>";-       

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


; hornm2
; #`                                      
; Uy_                                     
; A$6,                                    
; AA$h+                                   
; AAAUg\                                  
; AAAA8Zv                                 
; AAAAAAgJtc+-                            
; &AAkYYXghhq3j*\:                        
; A&YbYYXqSSSghhgpCac;                    
; )#GAYYXqSSSghhgFJ1%,                    
;   /zgAPghhmyz{)'                        
;     ;16J1%=`                            
;       .                                 
;                                         
;                                         
;                                         
;                                         
;                                  '::::::
;                                 `eLLLLLi
;                                 `onuuT* 
;                                 `onune_ 
;                                 `onuL=  
;                                 `onTv   
;                                 `o#I    
;                                 `77_    
;                                 `e"     
;                                 -)      

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

; 
; hornm3
;                                       ,J
;                                      ;SG
;                                     "d$g
;                                    <XU&g
;                                   %b8A&g
;                                 :*k8AA&g
;                            `=%1#FXkOAA&g
;                        '|{7ymhhgSEYbYO&P
;                     `%LpVdVgSSSSqEYYYOk2
;                      -=i!n5ShhgSqEkAbfv.
;                           _|s7fmgPPn)   
;                               .^vI=     
;                                         
;                                         
;                                         
;                                         
;                                         
;  :!]]]]?_                               
;   c#TnTu:                               
;   .!TuuL:                               
;    '7nuL:                               
;     |nnL:                               
;      lTL:                               
;      .[u:                               
;       ,o:                               
;        \:                               

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

; 
; adroid
;   .__-----------------------------____-`
;   c7JyyffffffffffffffffffffffffffwCJTn#o
;   Io1u5mmmmmmmmmmmmmmmmmmmm6F52yfwCCy5pT
;   IT[?]zy6m666666666pF53ywCJJJJJ#Cy555Fn
;   I#L]!?!oC6mm6F52yfwwwCwwwwwwCw35F555Fn
;   I#T7!!!!!]><<\\\\\\\<<<<<<<\eFFF5555Fn
;   I#nna!!!]s                  rJF55555Fn
;   I#nnu[!!]{                  rayF5555Fn
;   I#nnTj!!]{                  r1o5F555Fn
;   I#nnnTo!]{                  rt[LF555Fn
;   I#nnnnnt!{                  rt1[JF55Fn
;   I#nnnnnu1s                  rt1[tyF5Fn
;   I#nnnnnTL{                  rt11[o5FFn
;   I#nnnnnTTI;;;;;;;;,,,,::,;=/I1[[1[uFFn
;   I#nnTTu1liiiiiiiiiv%cs}]te7jzot1[[[Cpn
;   I#TTj!%>>))ivxl*?[ao7zjjzzzzzzz7a1[t2T
;   I#7}%i%l{I[to7zjjjzzzzzzzzzzzzzzz7e1zn
;   r!r{?[teeoeeeeeeeeeeeeeeeeeeeeeeeeea1]

; 
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



;                                         
;                                         
;                                         
;                                         
;            'i;             'v;          
;          :tJ)               =Tu=        
;        =jGJ'                 `zkw)      
;      \JAA*                     %YKF%    
;   _lF8$m=                       '2DHVI: 
;   )F&$$ws"`                   .=lu@HKh% 
;     ^?68@@P31):           _\!fg@KKht"   
;        =!m8@@@YSLr+.  ^x76bKKKKde"      
;           +]q&@@@@8E5d&KKKK@do|         
;              /1S8@@@@KKK@47\            
;                 "1g&@$4z\.              
;                    )1i.                 

sclaw4: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 6,4,1,9,3,9,9,12,9,15,15,9,17,9,12,4

;                                         
;                            _i<.         
;         ^^                  _?3t=       
;         #>                    =fO6{'    
;        )&\                      )hHYCx' 
;        F$)                      `]8HHkr 
;       %U$)                    ^oGKHAL;  
;      .h$U"                  |#OKH8#=    
;      *$$$5uo[}li\/;'`.    i2UKK$f"      
;     :b$@@@@@@@@@@8AYGEh63gKKK@5<        
;     +jw6dPO8@@@@@@@@@@@@@KKKmi          
;          -,")r]zCpVPk8@@@Kgx            
;                    _;|v*e{.             


sclaw5: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 4,5,2,13,4,11,11,12,11,15,15,8,17,8,12,4

; 
;                                         
;                                         
;                          .              
;                          ,lI)'          
;                           `iCESz%;      
;                              /n&DUdJ}|_ 
;                                :1gHHHKa 
;                                  <&KKF- 
;       'v                        iYKKh_  
;       .2n`                     r&KHP;   
;        r$m+                   ?UKKk"    
;        _G$Zl                 e@KK8i     
;         n$$Uj`              nKKK@r      
;         >$$$$dwwwCCCCCCCCCCqKKKK]       
;         .]n2SPO$@@@@@@@@@@@@KKKz        
;              .'=\%}tn3qEbA$@@KJ         
;                        .'=<l!t`         

; 
sclaw6: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 3,8,4,14,6,13,12,13,13,16,15,7,17,6,11,3

; 
;                                         
;                                         
;                        ``               
;                        ^sjy3Jz1}li)+;'` 
;                          `|!5YHDDHK$&k2 
;                              `\t6kKHHHf 
;                                  :PKKH! 
;                                  /UKKK> 
;                                  tKKKA: 
;                                  gKKKd  
;                                 =8KKHC  
;          '|):                   !KKKH!  
;           _>aTox;               6KKKK<  
;              ^?6GdT{/`   .'+>s1T8KKKO:  
;                 "7X$$X3fSgY8@@@@@@KK4   
;                   .iJb$@@@@UAbPdS5CLl   
;                      :Io!rv\=:-.        

; 
sclaw7: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 4,11,10,16,10,14,14,13,16,15,15,6,17,4,10,3

;                                         
;               ._,/<i>;                  
;   _<vrI17nf5q4GYZgns/`                  
;   i$$$$$$$$$$G3?|`                      
;   v@@@$$UZ51\-                          
;   v@@@@@L'                              
;   v@@@@@5                               
;   v@@@@@A;                              
;   v@@@@@@*                              
;   v@@@@@@5                              
;   v@@@@@@k:                             
;   v@@@@@@@s                       .^\"- 
;   v@@@@@@@y                   `"Iu#]|`  
;   v@@@@@@@ki='.           :iapZGfc_     
;   v@@@@@@KKK8YgSyL[r>+"*TV8D@q}:        
;   v@@KKKKKKKKKKKKKKKKU@DDHd1=           
;   _il}[ouw5mVgZk&U@KKHHPL\              
;              ._:=|>x{!c-                
; 
;                                                             
sclaw0: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 8,3,1,4,3,6,4,13,1,15,8,14,8,16,14,11

;                                         
;                                         
;                                         
;                ;\=                      
;           .=ru27<`                      
;       '<!wg8bu"                         
;   'lz6Z$$$E]:                           
;   =k$$$8Fl`                             
;    }@@@&r                               
;     2@@@8!                           ,% 
;     ^b@@@@7                         >Pl 
;      *@@@@@#.                      [Ub` 
;       y@@@@@2_                   :yHDj  
;       ;b@@@@@S;                 )XHH@|  
;        s$@@@@@E\;;;;;;;;;;;;;;;1UHHHh   
;         f@@@@@@$&&&&&&&&&&88U$@HHHHH?   
;         ,G@@@KKKKKKKKKKKK$AZEq3naIc<`   
;          r@@K$&YXhpwL1*%\=:`            
;           }Ix\=:`                       

sclaw1: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 7,3,1,6,3,7,6,13,4,16,12,13,14,14,15,8

;                                         
;             '"_                         
;           <7a+                   __     
;        =[hgl                     "n     
;     :{5AAe-                      =U%    
;   =wY$$h^                        =@X-   
;   _?g@@Oyv                       =UDz   
;     -]P@@@S{`                    ^UHU)  
;       'ab@@@E[:                  /UHHg. 
;         ,zk@@@bz=._:^"<%s?tj#y6hgYHHHH[ 
;           =TA@@@AXbO8$KKKKKKKKHHKA45jI\ 
;             "w8@@KKKKKKKKK&Pm#[x"'      
;               \3UKK&Ggfos\;.            
;                 v[%/_                   

sclaw2: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 6,4,1,8,3,8,7,12,7,15,14,11,16,12,14,5

;                                         
;            'i;               _%         
;          :tJ)                 {F=       
;        =jGJ'                   JA*      
;      \JAA*                     `dDy;    
;   _cF8$m+                       /&Dbr   
;   \q$$$#v:                       r@HHy= 
;     \LP@@k6t<-              -^<reC$Kb6c 
;       _rF8@@@PyI/   `;)c]u2dY$KKOmt<_   
;          /eE@@@@8d2gPA@KKKKKYFt<_       
;            `%fk@@@KKKKKKbFt<_           
;               ;!gUK@Z51<_               
;                  iti'                   

; 
sclaw3: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 6,4,1,9,3,9,8,12,8,15,15,10,17,10,13,4

; 
;                                         
;                                         
;                                         
;                                         
;            'i;             'v;          
;          :tJ)               =Tu=        
;        =jGJ'                 `zkw)      
;      \JAA*                     %YKF%    
;   _lF8$m=                       '2DHVI: 
;   )F&$$ws"`                   .=lu@HKh% 
;     ^?68@@P31):           _\!fg@KKht"   
;        =!m8@@@YSLr+.  ^x76bKKKKde"      
;           +]q&@@@@8E5d&KKKK@do|         
;              /1S8@@@@KKK@47\            
;                 "1g&@$4z\.              
;                    )1i.                 

gsclaw4: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 6,4,1,9,3,9,9,12,9,15,15,9,17,9,12,4

; 
;                                         
;                                         
;                                         
;                                         
;                            _i<.         
;         ^^                  _?3t=       
;         #>                    =fO6{'    
;        )&\                      )hHYCx' 
;        F$)                      `]8HHkr 
;       %U$)                    ^oGKHAL;  
;      .h$U"                  |#OKH8#=    
;      *$$$5uo[}li\/;'`.    i2UKK$f"      
;     :b$@@@@@@@@@@8AYGEh63gKKK@5<        
;     +jw6dPO8@@@@@@@@@@@@@KKKmi          
;          -,")r]zCpVPk8@@@Kgx            
;                    _;|v*e{.             

; 
;                                         
gsclaw5: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 4,5,2,13,4,11,11,12,11,15,15,8,17,8,12,4

;                                         
;                          .              
;                          ,lI)'          
;                           `iCESz%;      
;                              /n&DUdJ}|_ 
;                                :1gHHHKa 
;                                  <&KKF- 
;       'v                        iYKKh_  
;       .2n`                     r&KHP;   
;        r$m+                   ?UKKk"    
;        _G$Zl                 e@KK8i     
;         n$$Uj`              nKKK@r      
;         >$$$$dwwwCCCCCCCCCCqKKKK]       
;         .]n2SPO$@@@@@@@@@@@@KKKz        
;              .'=\%}tn3qEbA$@@KJ         
;                        .'=<l!t`         

; 
;                                         
; 
gsclaw6: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 3,8,4,14,6,13,12,13,13,16,15,7,17,6,11,3

;                                         
;                        ``               
;                        ^sjy3Jz1}li)+;'` 
;                          `|!5YHDDHK$&k2 
;                              `\t6kKHHHf 
;                                  :PKKH! 
;                                  /UKKK> 
;                                  tKKKA: 
;                                  gKKKd  
;                                 =8KKHC  
;          '|):                   !KKKH!  
;           _>aTox;               6KKKK<  
;              ^?6GdT{/`   .'+>s1T8KKKO:  
;                 "7X$$X3fSgY8@@@@@@KK4   
;                   .iJb$@@@@UAbPdS5CLl   
;                      :Io!rv\=:-.        

; 
;                                         

gsclaw7: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 4,11,10,16,10,14,14,13,16,15,15,6,17,4,10,3

;                                         
;                                         
;               ._,/<i>;                  
;   _<vrI17nf5q4GYZgns/`                  
;   i$$$$$$$$$$G3?|`                      
;   v@@@$$UZ51\-                          
;   v@@@@@L'                              
;   v@@@@@5                               
;   v@@@@@A;                              
;   v@@@@@@*                              
;   v@@@@@@5                              
;   v@@@@@@k:                             
;   v@@@@@@@s                       .^\"- 
;   v@@@@@@@y                   `"Iu#]|`  
;   v@@@@@@@ki='.           :iapZGfc_     
;   v@@@@@@KKK8YgSyL[r>+"*TV8D@q}:        
;   v@@KKKKKKKKKKKKKKKKU@DDHd1=           
;   _il}[ouw5mVgZk&U@KKHHPL\              
;              ._:=|>x{!c-                

; 
gsclaw0: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 8,3,1,4,3,6,4,13,1,15,8,14,8,16,14,11

;                                         
;                                         
;                                         
;                ;\=                      
;           .=ru27<`                      
;       '<!wg8bu"                         
;   'lz6Z$$$E]:                           
;   =k$$$8Fl`                             
;    }@@@&r                               
;     2@@@8!                           ,% 
;     ^b@@@@7                         >Pl 
;      *@@@@@#.                      [Ub` 
;       y@@@@@2_                   :yHDj  
;       ;b@@@@@S;                 )XHH@|  
;        s$@@@@@E\;;;;;;;;;;;;;;;1UHHHh   
;         f@@@@@@$&&&&&&&&&&88U$@HHHHH?   
;         ,G@@@KKKKKKKKKKKK$AZEq3naIc<`   
;          r@@K$&YXhpwL1*%\=:`            
;           }Ix\=:`                       

; 
gsclaw1: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 7,3,1,6,3,7,6,13,4,16,12,13,14,14,15,8

; 
;                                         
;                                         
;                                         
;                                         
;             '"_                         
;           <7a+                   __     
;        =[hgl                     "n     
;     :{5AAe-                      =U%    
;   =wY$$h^                        =@X-   
;   _?g@@Oyv                       =UDz   
;     -]P@@@S{`                    ^UHU)  
;       'ab@@@E[:                  /UHHg. 
;         ,zk@@@bz=._:^"<%s?tj#y6hgYHHHH[ 
;           =TA@@@AXbO8$KKKKKKKKHHKA45jI\ 
;             "w8@@KKKKKKKKK&Pm#[x"'      
;               \3UKK&Ggfos\;.            
;                 v[%/_                   

; 

gsclaw2: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 6,4,1,8,3,8,7,12,7,15,14,11,16,12,14,5

;                                         
;                                         
;                                         
;                                         
;            'i;               _%         
;          :tJ)                 {F=       
;        =jGJ'                   JA*      
;      \JAA*                     `dDy;    
;   _cF8$m+                       /&Dbr   
;   \q$$$#v:                       r@HHy= 
;     \LP@@k6t<-              -^<reC$Kb6c 
;       _rF8@@@PyI/   `;)c]u2dY$KKOmt<_   
;          /eE@@@@8d2gPA@KKKKKYFt<_       
;            `%fk@@@KKKKKKbFt<_           
;               ;!gUK@Z51<_               
;                  iti'                   

; 
gsclaw3: dc.l 6

	dc.w $ff,0,$ff00,1,$ff00,2,$c000,0,$fe,1,$ff00,2,$c000,4,$ff00,0,$fd,2,$c000,3,$8000,4,$ff00,0
	dc.w $fd,3,$8000,5,$c000,4,$ff00,0,$fe,4,$ff00,5,$c000,6,$ff00,0,$ff,5,$c000,6,$ff00,7,$ff00,0
	dc.w 6,4,1,9,3,9,8,12,8,15,15,10,17,10,13,4




