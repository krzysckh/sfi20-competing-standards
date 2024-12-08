.SUFFIXES: .el .bin

all: flag.bin spec.pdf

.el.bin:
	cask emacs --batch \
		--load "asm.el" \
		--load "$<" \
		--eval "(A/compile A//$* \"$@\")"

spec.pdf: spec.md
	pandoc --metadata title="competing standards" -f markdown+raw_tex --standalone \
		--pdf-engine=lualatex -V links-as-notes=true -H ./res/cfg.tex \
		-H res/coffee.tex \
		-t pdf -o spec.pdf < $<

competing-standards@master.tgz:
	git archive --format=tgz -o $@ --prefix=competing-standards/ master

sficpy: flag.bin spec.pdf vm.scm competing-standards@master.tgz
	yes | sficpy competing-standards flag.bin
	yes | sficpy competing-standards spec.pdf
	yes | sficpy competing-standards vm.scm
	yes | sficpy competing-standards competing-standards@master.tgz

clean:
	rm -f *.bin *.pdf *.tgz
