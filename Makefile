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

clean:
	rm -f *.bin *.pdf
