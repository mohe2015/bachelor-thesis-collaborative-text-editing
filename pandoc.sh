#!/usr/bin/env bash

cargo install --git https://github.com/typstyle-rs/typstyle.git
find latex/chapters/* -type f -name "*.tex" -exec bash -c 'for f; do pandoc --template template.pandoc.typ -f reader.lua -t thesis.lua "$f" -o "../../athena-tu-darmstadt-thesis/${f%.tex}.typ"; done' _ {} +
typstyle --line-width=1000 --wrap-text=fill-sentence -i chapters_* # get the sentences to full width
typstyle --wrap-text=sentence -i chapters_* # format code with normal line width