# Tempest 2000 by Jeff Minter

This is the source code for Tempest 2000 by Jeff Minter.

The source code, after some light modifications, can be compiled into an executable that you can run
in `virtual-jaguar`.


## Build Instructions

### Build Requirements
```sh
sudo apt install build-essentials wine virtual-jaguar
```

### Build the assembler toolchain
We use three tools to build the source code: vasm, rmac and rln. If you already have these installed you may have some
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
