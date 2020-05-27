toolchain_ncgen = {
	name = "ncgen",
	compiler = "bin/cowcom.cgen.bootstrap.exe",
	linker = "bin/cowlink.cgen.bootstrap.exe",
	assembler = buildcgen,
	runtime = "rt/cgen",
	asmext = ".c",
	binext = ".exe",
	tester = nativetest
}

toolchain_nncgen = {
	name = "nncgen",
	compiler = "bin/cowcom.cgen.ncgen.exe",
	linker = "bin/cowlink.cgen.ncgen.exe",
	assembler = buildcgen,
	runtime = "rt/cgen",
	asmext = ".c",
	binext = ".exe",
	tester = nativetest
}

toolchain_ncpm = {
	name = "ncpm",
	compiler = "bin/cowcom.8080.nncgen.exe",
	linker = "bin/cowlink.8080.nncgen.exe",
	assembler = buildzmac,
	runtime = "rt/cpm",
	asmext = ".asm",
	binext = ".8080.com",
	tester = cpmtest,
}

toolchain_ncpmz = {
	name = "ncpmz",
	compiler = "bin/cowcom.z80.nncgen.exe",
	linker = "bin/cowlink.8080.nncgen.exe",
	assembler = buildzmac,
	runtime = "rt/cpmz",
	asmext = ".z80",
	binext = ".z80.com",
	tester = cpmtest,
}

ALL_TOOLCHAINS = {
	toolchain_nncgen,
	toolchain_ncgen,
	toolchain_ncpm,
	toolchain_ncpmz,
}
