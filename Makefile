.PHONY: all clean

DIRS=src/bin

all: clean t2000.abs

t2000.abs: sources 
	$(shell mkdir -p $(DIRS))
	./rmac/rmac -fr -mtom -l -isrc src/gpu/donky.gas -o src/bin/donky.o
	./rmac/rmac -fr -mtom -l -isrc src/gpu/camel.gas -o src/bin/camel.o
	./rmac/rmac -fr -mtom -l -isrc src/gpu/antelope.gas -o src/bin/antelope.o
	./rmac/rmac -fr -mtom -l -isrc src/gpu/goat.gas -o src/bin/goat.o
	./rmac/rmac -fr -mtom -l -isrc src/gpu/llama.gas -o src/bin/llama.o
	./rmac/rmac -fr -mtom -l -isrc src/gpu/horse.gas -o src/bin/horse.o
	./rmac/rmac -fr -mtom -l -isrc src/gpu/ox.gas -o src/bin/ox.o
	./rmac/rmac -fr -mtom -l -isrc src/gpu/stoat.gas -o src/bin/stoat.o
	./rmac/rmac -fr -mtom -l -isrc src/gpu/xcamel.gas -o src/bin/xcamel.o
	./rmac/rmac -fb -isrc -l src/yak.s -o src/bin/yak.cof
	./rmac/rmac -fb -isrc src/yakgpu.s -o src/bin/yakgpu.cof
	./rmac/rmac -fb -isrc src/vidinit.s -o src/bin/vidinit.cof
	./rmac/rmac -fb -Isrc src/images_sounds.s -o src/bin/images_sounds.o
	./rln/rln -z -e -a 802000 4000 efa8 src/bin/yak.cof src/bin/vidinit.cof src/bin/yakgpu.cof src/bin/images_sounds.o -o t2000.abs
	echo "44e71799ee06615a59ff57b2c8a1ef52  t2000.abs" | md5sum -c

clean_build: t2000.abs 
	echo "44e71799ee06615a59ff57b2c8a1ef52  t2000.abs" | md5sum -c

sources: src/*.s src/gpu/*.gas

cartridge: clean_build
	wine ./utils/filefix t2000.abs
	./utils/CreateCart.py t2k.rom  src/incbin/romheader.bin T2000.TX
	echo "602bc9953d3737b1ba52b2a0d9932f7c  t2k.rom" | md5sum -c

dirty: t2000.abs
	wine ./utils/filefix t2000.abs
	./utils/CreateCart.py t2k.rom  src/incbin/romheader.bin T2000.TX

run: cartridge
	wine ./utils/t2k.exe t2k.rom

clean:
	-rm src/bin/*.o
	-rm src/bin/*.cof
	-rm -f t2000.abs
	-rm -f T2000.DB
	-rm -f T2000.TX
	-rm -f T2000.DTA
	-rm -f t2k.rom
