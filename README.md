# Tempest 2000 (1994) by Jeff Minter
<img src="https://user-images.githubusercontent.com/58846/121210319-7da9b400-c873-11eb-87c0-7a8e6f4b425b.png" height=300><img src="https://user-images.githubusercontent.com/58846/121211760-a8e0d300-c874-11eb-9fec-fe6a47e9be1d.gif" height=300>

This is the source code for Tempest 2000 by Jeff Minter originally published in 1994 for the ill-fated Atari Jaguar.

The source code can be compiled into an executable that you can run in `virtual-jaguar`.

## Build Instructions

### Build Requirements
```sh
sudo apt install build-essentials wine virtual-jaguar
```

### Build the assembler toolchain
We use three tools to build the source code: `vasm`, `rmac` and `rln`. If you already have these installed you may have some
luck using them, if not you can build the versions included in this repository as they are known to work. 

```sh
cd vasm-mirror
make CPU=jagrisc SYNTAX=madmac
cd ../rmac
make
cd ../rln
make 
cd ..
```

### Build Tempest 2000

To build an executable file `t2000.abs`:
```sh
make t2000.abs
```
You can run this as follows using `virtual-jaguar`:
```sh
virtual-jaguar t2000.abs
```
Note that you may need to explicitly load the file from within `virtual-jaguar` for this to work.

To build a cartridge file that is byte-for-byte identical to the rom commonly circulated in forums:
```sh
make cartridge
```

This will create a file `t2k.rom`. You can run this as follows using `virtual-jaguar`:
```sh
virtual-jaguar t2k.rom
```

For an optimal Tempest 2000 experience you should run the game in 'Project
Tempest' a Jaguar emulator optimize for Tempest 2000 specifically. Project
Tempest is available in the `utils` folder as `PT.exe`. To use it run the
following at the command line, select File->Open Rom and load `t2k.rom`:
```sh
wine ./utils/PT.EXE
```
