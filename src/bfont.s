; **************************************************************************************
; Welcome to the Motorola 68K Assembler source code for 'Tempest 2000' by Jeff Minter.
;
; ^^+)ir!1[]!]1e7L#C#uz7LTLeIx</^^      </`vtat[!!!!!!!]1e7L#C#uz7LTLeIx</^^      </-i=^+)ir!1[]!]1e7L#C#uz7LTCwwCTLeov===
; .=ltuTza[!II?]teznTL7atz#JJCu?\_      "/`%FFne1!!!???I?]teznTL7atz#JJCu?\_      "/-)`=ltuTza[!II?]teznTL7at7u###nL3C<   
; >?77!)\||)|||"//+=====^^=+|sjJz*^     "/-%fJ{<<<\\\)|||"//+=====^^=+|sjJz*^     "/-i>?77!)\||)|||"//+=====^^^;;;,;eL\   
; oo?v")<>vxxxclrs{ssrcx%%)=^;"t7T>     "/-%nLs>>>ccr{sxclrs{ssrcx%%)=^;"t7T>     "/-veo?v")<>vxxxclrs{ssrcx%vvvviix]T)   
; zoc\<<%lci<"||)))))|"|>x{x|^^)#6%     "/-voel<<<c{i))"||)))))|"|>%sx|^^)#6%     "/-v7oc\<<%lci<"||)))))|""""""/"||)v^   
; a!%<\<r!>:_```...````_:=s]>;;=yVl     "/-v1]%<\<r!"..```...```.`,i]1);;^3Vl     "/-vt]%<\<r!i^:_----------------__':`   
; ?{i\)\]uLe]}s{I?*rrrrs{*ezv,,=6gr     "/-vI{i\)\]uz1?*s{I?*rrrr*[a7?),;<56%     "/-vI{i\)\?e<`.                         
; sx>)|\*[oo1?*r{II{rlrrlrrr|,:=S4c     "/-vrx>)|\*[oo1!}r{II{rlrrc)<^;/v[z!+     "/-vrx>)|\tL<                           
; %%<|||//+===^^^;;;,,,::::::::^mq%     "/-v%%<|||//+===^^^;;;,,,::::,=<rIs)_     "/-v%%<||)7u<                           
; vr)|"|slx%v%%vi><<>><\<)x*)'';33)     "/-ivr)|"|Isx%v%%vi><<>><\\\=,::+ljo|     "/-ivr)|")j7)                           
; rIi"/|ttv+///++===+====|aTv__,#T<     "/-vlIi"/|aav+///++===+=^/)<)>='_:##<     "/-vlIi"/|te|                           
; }1%//"[7<``````````````'Jmr-_:7L\     "/-v*t%//"[7)        ... .,%{*"__'zj\     "/-v}t%//"!7r=                          
; 17x+=/ej\              _mE{`-'a#>     "/-v[7x+="j6m6p5pp2yw#LjuT##oc^-')eo|     "/-v]ol"++>{eJ55pp5yw#Ljunje1???I?I?/   
; ouc==/en<              _Shl``_L2v     "/-venc==+r[o7o1oooa1[!}}{li^``,\I!r^     "/-vxI}%"=;="%!toooa1[!}*I?*rc%vvcn5v   
; uj%==/7j\              -ywi--:j5%     "/-%Lj%==^;,::::'''____---`-^/<%s{%"_     "/-i+irrcv<"=,::'''____---````..._JSc   
; t?%<<i*["              `[!rxxl}a)     "/-v]si<<>><\\\<\\\\<>iv%x%vvx%%i|=^-     "/-i',/<%clcvi><\\\\<>iv%x%viii%cltfv   
;                                                                                                                 
; |?eat]!!!!!]][tojTJJTj7jnu7[r)|=       /).\|^="<cI[1]!![tojTJJTj7jnJwww#uoe      /).\|^="<cI[1]!![tojTJJTj7jnJwww#uoe!=
; |umfe[???III}*I!t7uTnzetonJJCJa%;      _).<^'>!jTLo1]?II![e7uTnzetoLT###LCy1     _).<^'>!jTLo1]?II![e7uTnzetoLT###LCy1 
; |7yo<\\\))||""//+++====^^=="ie#u[)     _).\)lajtc<||))||""/++====^^^^;;;,sL!     _).\)lajtc<||))||""/++====^^^^;;;,sL! 
; |tT1>>>%lls{{srrs{ssrlx%%>/=^,*oL1     _).|!7tr||\<ixxxxcrs{ssrlx%vvvvii%}za     _).|!7tr||\<ixxxxcrs{ssrlx%vvvvii%}za 
; |]7!<<<%sr)))||)))))||"<vrr>^^+15n     _).|]z!\<<iclv>|"|)))))||""""""/"|)><     _).|]z!\<<iclv>|"|)))))||""""""/"|)>< 
; )?1{<\\%Is`-----------_:^v?*;;,tgw     _).)?1{<<\%I{;'-```..````````---___''     _).)?1{<<\%I{;'-```..````````---___'' 
; ){Ic\\)rtI             .-vt?,;:7Ef     _).){Ic\\)s7To1I{s*?}srrrrl%;             _).){Ic\\)s7To1I{s*?}srrrrl%;         
; )lli))|*z[               xj1,,'jgJ     _).)lli))|x!t7t]I{r*I*rllr1t"             _).)lli))|x!t7t]I{r*I*rllr1t"         
; )%%i||"?u[               l#o::'7hL     _).)%%i|||"/++===^;;;;,,,,}e)             _).)%%i|||"/++===^;;;;,,,,}e)         
; \vxc||"?L}               *3u''_tpo     _).\vxc||"lIc%v%%vi><<>>>\l[|             _).\vxc||"lIc%v%%vi><<>>>\l[|         
; )c*{""/{o*               !mT_'-!w[     _).)c*{""/*oI=+//++===+///"<,             _).)c*{""/*oI+///++===+///"<,         
; )r]?//+roI             ./e3a__`{u?     _).)r[?//+let<'.      ...``-.             _).)r]?//+ro!```````````--_'`         
; )}o[++=IyS66666F3fJnjLT#Ju!<--=}7*     _).)*e[|+=)c[u35FpFyfJujjnLot!?!II??c     _).)}o[++=*j!                         
; |!La===i?a7777ooe11]I*}r%"_`'+r!}>     _).\%{?r)+^^/<}[eooe11]I*}?}sl%vv%ayL     _).|!La===*u1                         
; |1u]===;,::::''''___----`:+)il{l<;     _).\|)lsl%>)/;::''''___----````.. ?6#     _).|1u]==^*L?                         
; )}I%<<>>><\\\\\\\<<)i%xxvv%x%v\/^,     _).\+:^)vxll%i><\\\\<<)i%xx%iiivcx?nj     _).|I[{><>r!{                         
; \|^;^^^^^^^^^^^^^^^^========//=;_      _).<;.-',;^^^^^^^^^^^^^=====^^==///))     _).\)=^^=+/)|                         
;
;                   Fig 1. Ascii rendering of sample characters from bfont.s
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
; bfont.s consists of addresses into the data in pic6 (beasty8.cry). pic6 contains a spritesheet
; of characters for the font.
; **************************************************************************************
*
*
* Page 6 font, 32x32, by Joby

bfont:
  dc.l pic6     ; beasty8.cry
	dc.l $001f001b

 	dc.l $470119	;Space
	dc.l $8d0047	;!
	dc.l $470119	;"
	dc.l $470119	;#
	dc.l $470119	;$
	dc.l $470119	;%
	dc.l $470119	;&
	dc.l $470119	;'
	dc.l $470119	;(
	dc.l $470119	;)
	dc.l $8d008d	;*
	dc.l $470119	;+
	dc.l $b600f8	;,
	dc.l $8d006a	;-
	dc.l $8d0024	;.
	dc.l $470119	;/
	dc.l $6a0001	;0
	dc.l $6a0024	;1
	dc.l $6a0047	;2
	dc.l $6a006a	;3
	dc.l $6a008d	;4
	dc.l $6a00b0	;5
	dc.l $6a00d3	;6
	dc.l $6a00f6	;7
	dc.l $6a0119	;8
	dc.l $8d0001	;9
	dc.l $b600e5	;:
	dc.l $470119	;;
	dc.l $470119	;<
	dc.l $470119	;=
	dc.l $470119	;>
	dc.l $8d00b0	;?
	dc.l $470119	;@
	dc.l $010001	;A
	dc.l $010024	;B
	dc.l $010047	;C
	dc.l $01006a	;D
	dc.l $01008d	;E
	dc.l $0100b0	;F
	dc.l $0100d3	;G
	dc.l $0100f6	;H
	dc.l $010119	;I
	dc.l $240001	;J
	dc.l $240024	;K
	dc.l $240047	;L
	dc.l $24006a	;M
	dc.l $24008d	;N
	dc.l $2400b0	;O
	dc.l $2400d3	;P
	dc.l $2400f6	;Q
	dc.l $240119	;R
	dc.l $470001	;S
	dc.l $470024	;T
	dc.l $470047	;U
	dc.l $47006a	;V
	dc.l $47008d	;W
	dc.l $4700b0	;X
	dc.l $4700d3	;Y
	dc.l $4700f6	;Z
	dc.l $470119	;[
	dc.l $470119	;\
	dc.l $470119	;]
	dc.l $470119	;^
	dc.l $470119	;_
	dc.l $470119	;`
	dc.l $010001	;A
	dc.l $010024	;B
	dc.l $010047	;C
	dc.l $01006a	;D
	dc.l $01008d	;E
	dc.l $0100b0	;F
	dc.l $0100d3	;G
	dc.l $0100f6	;H
	dc.l $010119	;I
	dc.l $240001	;J
	dc.l $240024	;K
	dc.l $240047	;L
	dc.l $24006a	;M
	dc.l $24008d	;N
	dc.l $2400b0	;O
	dc.l $2400d3	;P
	dc.l $2400f6	;Q
	dc.l $240119	;R
	dc.l $470001	;S
	dc.l $470024	;T
	dc.l $470047	;U
	dc.l $47006a	;V
	dc.l $47008d	;W
	dc.l $4700b0	;X
	dc.l $4700d3	;Y
	dc.l $4700f6	;Z
	dc.l $470119	;{
	dc.l $470119	;|
	dc.l $470119	;}
	dc.l $470119	;~
	dc.l $470119	;DEL
; vim:ft=asm68k ts=2
