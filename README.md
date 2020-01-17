(This is a placeholder document which will be replaced at some point.)

This is just a few simple notes on using the new compiler prototype.

The _old_ compiler is the one documented at http://cowlark.com/cowgol. This is
not it. See [WHAT-HAPPENED-TO-COWGOL.md](WHAT-HAPPENED-TO-COWGOL.md) for
details about it (tl;dr: became too big and complex, am rewriting from
scratch).

This version of the compiler is in C and isn't self-hosting yet but is
drastically simpler but also better. It targets:

- 8080 (CP/M)
- 80386 (Linux)
- Thumb2 (Linux)

Sadly I've removed the Apollo Guidance Computer backend --- I'd like to get
that running again, but I'm focusing on the compiler core for now. (It should
be easy to produce a code generator for using the new model.)

To build:

    $ sudo apt install ninja-build lua5.2 pasmo libz80ex-dev flex \
	    libbsd-dev libreadline-dev bison qemu-user \
		binutils-arm-linux-gnueabihf \
		binutils-i686-linux-gnu
    $ make

Sadly, out of the box it'll probably only work on Linux; the test framework
relies on the alien executable format stuff to run 80386 and Thumb2 binaries in
emulation (with qemu). If you're on another platform and want to try it anyway,
you'll need to edit the mkninja.sh script and comment out the test lines near
the bottom.

To use it yourself, probably the easiest way is to patch your code into
`examples/empty.cow` and run `make`. The less easy way is:

    $ bin/tinycowc-8080 -Irt/ -Irt/cpm/ inputfile.cow outputfile.asm

...but then you'll have to assemble the result and link it against the standard
libraries yourself.

