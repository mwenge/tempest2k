.PHONY: all clean

DIRS=src/bin

all: clean cartridge

tempest2000.jag: 
	$(shell mkdir -p $(DIRS))
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/donky.gas -o src/bin/donky.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/camel.gas -o src/bin/camel.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/antelope.gas -o src/bin/antelope.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/goat.gas -o src/bin/goat.o
	#./rmac/rmac -fa -mtom -isrc src/llama.gas -o src/llama.bin
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/llama.gas -o src/bin/llama.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/horse.gas -o src/bin/horse.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/ox.gas -o src/bin/ox.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/stoat.gas -o src/bin/stoat.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -L xcamel.asm -Fbin src/xcamel.gas -o src/bin/xcamel.o
	./rmac/rmac -fb -isrc src/yak.s -o src/bin/yak.cof
	./rmac/rmac -fb -isrc src/yakgpu.s -o src/bin/yakgpu.cof
	./rmac/rmac -fb -isrc src/vidinit.s -o src/bin/vidinit.cof
	./rmac/rmac -fb -Isrc src/images_sounds.s -o src/bin/images_sounds.o
	./rln/rln -e -a 802000 4000 efa8 src/bin/yak.cof src/bin/vidinit.cof src/bin/yakgpu.cof src/bin/images_sounds.o -o t2000.abs
	echo "515c0e0fcfe9a96d24c858968c3bad72  t2000.abs" | md5sum -c

cartridge: tempest2000.jag
	wine ./utils/filefix t2000.abs
	./utils/CreateCart.py t2k.rom  src/incbin/romheader.bin T2000.TX src/incbin/paddingaftersamples.bin 
	echo "602bc9953d3737b1ba52b2a0d9932f7c  t2k.rom" | md5sum -c

clean:
	-rm src/bin/*.o
	-rm src/bin/*.cof
	-rm t2000.abs
	-rm T2000.DB
	-rm T2000.TX
	-rm T2000.DTA
	-rm t2k.rom
