.PHONY: thesis.pdf clean
thesis.pdf:
	SOURCE_DATE_EPOCH=1722865452 latexmk thesis.tex
check:
	find -name '*.tex' -not -path "./tuda_latex_templates/*" | xargs -L 1 lacheck
clean:
	SOURCE_DATE_EPOCH=1722865452 latexmk -C thesis.tex
