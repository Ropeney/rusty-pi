# define showerrs on the command-line to see what errors are generated by
# the xxx-err.rs programs

pi?=192.168.1.35

rust_exe_src:=$(wildcard src/*.rs)
rust_lib_src:=$(shell find src/ -path 'src/*/*.rs')
rust_src:=$(rust_exe_src) $(rust_lib_src)

rust_exes:=$(patsubst src/%.rs,out/%,$(filter-out %-err.rs,$(rust_exe_src)))
rust_compile_errors:=$(patsubst src/%-err.rs,out/compile-output/%-err.compile-output,$(rust_exe_src))

book_src:=$(wildcard doc/*.asciidoc)
book_images:=$(wildcard doc/*.svg doc/*.jpg doc/*.png)

version:=$(shell git describe --tags --always --dirty=-local --match='v*' | sed -e 's/^v//')
rust_version:=$(shell rustc --version | cut -c 7-)

asciidoc_icondir=/usr/share/asciidoc/icons
asciidoc_icons:=$(shell find $(asciidoc_icondir) -type f -name '*.*')

linker=../tools/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/bin/arm-bcm2708hardfp-linux-gnueabi-g++
rustflags=-L . --target arm-unknown-linux-gnueabihf -C linker=$(linker)

all: pdf exes
exes: $(rust_exes)
pdf: out/pdf/book.pdf

out/pdf/book.pdf: out/docbook/book.xml
	@mkdir -p $(dir $@)
	dblatex -o $@ --fig-path=doc -P latex.encoding=utf8 $<

out/docbook/book.xml: $(book_src) $(rust_src) $(rust_compile_errors)
	@mkdir -p $(dir $@)
	asciidoc \
		-a icons \
		-a version="$(version)" \
		-b docbook45 \
		-o $@ doc/book.asciidoc

out/%: src/%.rs $(rust_lib_src)
	@mkdir -p $(dir $@)
	rustc $(rustflags) -o $@ $<

out/compile-output/%.compile-output: src/%.rs
	@mkdir -p $(dir $@)
ifdef showerrs
	-rustc $(rustflags) -o $(dir $@)/$* $< 2>&1 | tee $@
else
	-rustc $(rustflags) -o $(dir $@)/$* $< > $@ 2>&1
endif
	diff $@ doc/$*.compile-output


deployed: $(rust_exes)
	rsync $^ $(pi):

clean:
	rm -rf out/

again: clean deployed

.PHONY: all pdf exes deployed clean again tmp
