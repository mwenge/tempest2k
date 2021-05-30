.PHONY: all clean run


all: clean

tempest2000.jag: 
	./rmac/rmac -v -fb -isrc src/yak.s -o bin/yak.cof
	#./rmac/rmac -fa -mtom -isrc src/donky.gas -o src/donky.bin
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/donky.gas -o src/donky.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin -L camel.asm src/camel.gas -o src/camel.o
	#./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/ians.gas -o src/ians.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin -L antelope.asm src/antelope.gas -o src/antelope.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/goat.gas -o src/goat.o
	#./rmac/rmac -fa -mtom -isrc src/llama.gas -o src/llama.bin
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/llama.gas -o src/llama.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/horse.gas -o src/horse.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/ox.gas -o src/ox.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -Fbin src/stoat.gas -o src/stoat.o
	./vasm-mirror/vasmjagrisc_madmac -mgpu -L xcamel.asm -Fbin src/xcamel.gas -o src/xcamel.o
	./rmac/rmac -v -fb -isrc src/yakgpu.s -o bin/yakgpu.cof
	./rmac/rmac -v -fb -isrc src/vidinit.s -o bin/vidinit.cof
	./rmac/rmac -v -fb -Isrc src/images_sounds.s -o bin/images_sounds.o
	rln -v -e -a 802000 4000 efa8 bin/yak.cof bin/vidinit.cof bin/yakgpu.cof bin/images_sounds.o -o t2000.abs
	wine filefix t2000.abs



clean:
	-rm bin/*.o
