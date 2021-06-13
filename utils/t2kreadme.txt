            Jaguar Tempest 2000 Emulator

(approximate)
Minimum Requirements: 500MHz or greater (should work with throttle)
Recommended Requirements: 1GHz or greater.
For games other than Tempest 2000, the faster the better...

DirectX 9 is required. Windows XP may or may not be required.

Starscream 680x0 emulation library by Neill Corlett
(corlett@elwha.nrrc.ncsu.edu)

This software also makes use of the excellent LibPNG and Zlib, both
available at Sourceforge.

THIS EMULATOR IS PROVIDED WITH NO WARRANTY, INCLUDING IMPLIED WARRANTIES,
ETC. IT IS A BETA PRODUCT THAT IS KNOWN NOT TO BE THOROUGHLY DEBUGGED, AND
HAS PREVIOUSLY CONTAINED AT LEAST ONE BUG THAT CAN UNRECOVERABLY CRASH A
SYSTEM. YOU USE IT ENTIRELY AT YOUR OWN RISK.


Keys:
----

F1 - Fullscreen toggle
F3 - Enable Music device capture
F4 - Show Music Input
F6 - Load State
F7 - Save State
F11 - Throttle toggle
F12 - Screenshot
O - option
P - pause
Z/Ctrl - A
X/ALT - B
C/Space - C
Arrow keys
Numeric keypad (. is #)
Q - three-fingered salute (used on the flashing CD with ?) to engage VLM
Esc - Quit

VLM: press Z (button A) twice to enter program mode, press O to engage
user programmable mode, then the numeric pad or numbers: first press is
bank, second press is effect in bank.

Joypads are supported.

Mouse-as-spinner mode is only loosely tested and probably not well
calibrated. Pause hits both pause keys so can be used to enable spinner
mode in game. Note that if spinner mode is enabled it is saved in the
EEPROM.





The game defaults to unthrottled operation, in which it assumes the blitter
and GPU have infinite speed. This makes Tempest 2000 run at 60fps at all
times. Throttling will take GPU and blitter into account and run more
realistically as in the real hardware. This also reduces the load on the host
CPU and will probably be required for processors under about 1GHz.

MOST GAMES OTHER THAN T2K REQUIRE THROTTLED OPERATION

The latest versions use native sound rather than emulating the DSP under Tempest
2000. The cost of sound is well down under previous versions. Native sound can
be forced off from the menu. With throttling this should enable T2K to run even on
slow processors or in low CPU power states. It does not need to be manually disabled
on games other than Tempest 2000.

The emulator can yield unneeeded CPU time to the operating system. This may
cause stuttering on CPU's with dynamic clocking if the CPU ends up bouncing
between two power states. SpeedswitchXP is your friend.

Smoothing toggles between point sampling and bilinear interpolation filtering
of the upscale of the Jaguar screen. Select your preference accordingly for
chunky pixels or Telly-O-Vision.

EEPROM saves are placed in directory assigned in the options, which defaults to
the All Users Application Data directory (in theory, although they have been
sighted in the application directory, the rom directory, and frankly just about
anywhere else it feels like it).

In PAL mode (selected by adding -pal on the command line) you can see slightly
more of the web, but the 50Hz refresh rate will not look as smooth. The game
also feels very slightly different.

If you have an older DX7 card then you may find that the emulator's screen size
does not resize with the window; in this case you must use fullscreen mode. You
may find it doesn't work at all, although I hope that is no longer the case.

SAVE STATES ARE NOT COMPATIBLE BETWEEN VERSIONS.



VLM Music
---------

Old method - attach a WAV file. This has no level control.

Preferred now: select 'Music input is output' from the settings menu, which will
take the currently running sound output. If there is more than one sound capture
device in the system it will offer you a choice. You may also need to double-click
the speaker icon in the taskbar, select properties/recording and map the input to
Wave or Stereo Mix (or similar using the sound card's own control).

The level will need to be adjusted to make VLM's triggers work properly - VLM
is at it's most fascinating when the levels are well balanced, and it's
particularly important for music genres like rock which are rich across the
entire audio spectrum. 

If you select 'Show music input' (F4) it will give a level graph, and the
input level scaling can be adjusted with the up and down keys while it is
displayed. Setting it so the peak red line tends to be around the blue guide
and rarely dramatically exceeds it should give reasonable results. You can
also use your music program's level control. This option works best on the
"Waiting for CD" screen - once VLM itself is running results will be less
consistent.

Another good option is to use Bank 3 effect 3 (swirling squares) - if this
is always very dark it's too quiet for VLM's internal triggers, while if it's
always extremely bright then it's probably too loud. A nice balance should give
excellent results.

VLM will happily eat up every emulated cycle most PC's can generate, and so you
may find either VLM or the music replay stuttering unless you have a very
high-spec machine. If this happens, turning on Throttle and Yield will usually
improve matters.



Known / Suspected Bugs:
----------------------

The game must be throttled to play the track bonus levels. Unless you like it tricky.

Yield mode is also frequently slightly drunken music mode.

EEPROM saving and loading has previously proved a bit less reliable than it should
be, but this should be fixed with the specific setting of the eeprom save
directory.

Throttled mode cannot throttle the blitter slower than one blit per frame.

Dialog boxes often do not appear if the game is in fullscreen mode. If you repeatedly
close it with escape and reopen then it will usually appear after a few tries. Yes,
D3D has a flag that fixes this. No, I can't get it to work.

Switching out of fullscreen mode used to crash some nvidia systems with a Blue
Screen Of Death (or the Windows XP equivalent of the Silent Reboot). It seems
that 0.05 has fixed this but users should still be aware of the issue.

The joystick button mapping isn't very clever. In particular, there is no keyboard
command to escape from it.



Kind of not bugs:
----------------

Windowed mode suffers tearing artifacts due to the lack of sync with vertical
retrace. Fullscreen should not have these, but may not be perfectly smooth if
the fullscreen refresh rate is not 60Hz or in PAL mode.



Version history
---------------

0.06: (Core)
      Experimented with an alternate memory access method, which didn't help performance much
      Halved timeslice sizes
      Move CLUT to be a memory region rather than part of the chip
      Compute buffer size and pixel aspect ratio accurately in the OP, pass to window system
      Cleaned up CPU and RISC interrupt systems, added CPU stop object interrupt
	  Rewrote Tom PIT to the correct spec (and fixed the stall bug I found in it too)
	  Rewrote Jerry PIT to correct an awful inaccuracy. However, to get AvP sound right
            I had to add a hack to multiply the rate by 4. I don't understand why, I don't
            know where the bug is, and in particular I don't know if I should apply the same
            hack to the Tom PIT as well.
	  Fixed a bug that was causing writes to the start of some memory regions to be misdirected
      Rewrote OP towards optional line-granularity
	  Added option to disable DSP altogether
	  Added all DSP wavetables, or at least guesses at same
	  Hacked around a problem that was causing the 'superzapper recharge' sample not to appear in T2K. Also
	        hacked the 'gappy sample' issue by slowing the music replay rate down 2% in the native
	        sound routine
      GPU/Risc fixes: truly embarassing bug with sat8, equally rubbish bug with move pc,
            MMULT instruction, kick off small timeslice on all RISC starts to avoid race if the RISC
            sets a status flag which the 68k then checks, possibly the largest bug in the history
            of errors in RISC interrupts (which weren't saving flags), ADDQMOD instruction,
            PACKUNPACK instruction, PC register, hidata register
	  OP bugfixes: don't infinite loop on zero vscale, abort if hit address zero, fully
	        clipped objects off left side fix, some colour transparency, RGB16 conversion
	        was incorrect, scaled objects needed signed height, 8-bit OP scaled objects,
	        improved horizontal scaling accuracy, added RGB24 mode
	  Blitter bugfixes: bit to pixel expansion bits were reversed bit order, 32bpp phrasemode
            blits were using wrong address mask, moved srcshade inside transparency check, fixed
            8-bit phrasemode blit alignment several times, added byte-to-phrase blits
	  Blitter improvements: added blitter A1 inc sign, added blitter Y inc, added 8-bit
			srcshade, additive blits
      (Debugger)
      Track RISC history (some of these need compile switches)
      Append register name comments to disasm output
      Added help menu in debugger because I'm too stupid to remember my own commands
      Tidied up some registers
      Kill OP object option
      (Windows)
      Fixed fullscreen on certain widescreen machines
      Connected OP screen width hook
	  Went up to W4 and fixed most of the additional warnings
	  Reversed left and right sound channels
	  Fixed the remaining bugs with fastcall and switched to it, for a small performance gain
	  Added joystick button configuration
	  (All)
	  Clean up headers, clearly define core/window system interface
0.05: (Core)
      Blitter speed optimisations
      RISC core speed optimisations
      OP speed optimisations (contributed by Gary Liddon)
      Screen capture support
      Defender 2000 compatibility fixes (some contributed by David Bateman)
      Native sound for T2K to avoid high DSP load
      (Windows)
      Rewrote keyboard system
      Rewrote D3D fullscreen switch - should have fixed fullscreen change crash
      Fixed D3D cards that support StretchRect but need no filter specified
      Options dialog box for configuring controls and directories
      Saves options into registry
      Avoid window shrink with repeated restart or fullscreen switch
      Made fullscreen mode select a wide ratio mode if desktop is in a widescreen mode
0.04: Fixed no joystick support
      Added sound capture and level meter
      More internal work for porting
0.03: Cleaned up fullscreen code a little
      Cleared all fullscreen backbuffers at init
      Added automatic resizing of window if too big for screen
      Fixed (in theory) mono and 8-bit WAV files
      Added joystick/joypad support
      Internal code cleaning in preparation for Mac/Linux ports
0.02: Fixed bug with some video cards
0.01: First release




Rough compatibility list (only a few games tried):

Seem Playable:

Tempest 2000: The shaded web is not exactly matching up with the line web, and there
are sometimes thin stripy lines on horizontal left-of-centre segments.

VLM: bank 4 effects flicker with throttle enabled.

Defender 2000: Classic and Plus have no screen, although it sounds like the game is
running. 2000 mode mostly works but it looks like the 'assistant' ship is broken.

Trevor McFur In The Crescent Galaxy: White objects shoot black, near-invisible
bullets, which doesn't seem right.

Sensible Soccer: Looks fine, although I'm not sure what's going on with save/load.


Not playable:

Alien vs Predator: Graphical glitches. Marine mode broken. Marines do not shoot at player.

Doom: Panel is distorted. Game sticks as soon as you move.



