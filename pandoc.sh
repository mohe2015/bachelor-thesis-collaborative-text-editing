#!/usr/bin/env bash

cargo install --git https://github.com/typstyle-rs/typstyle.git
find latex/chapters/* -type f -name "*.tex" -exec bash -c 'for f; do pandoc --citeproc --template template.pandoc.typ -f reader.lua -t thesis.lua "$f" -o "athena-tu-darmstadt-thesis/chapters/$(basename "$f" .tex).typ"; done' _ {} +
typstyle --line-width=1000 --wrap-text=fill-sentence -i athena-tu-darmstadt-thesis/chapters/* # get the sentences to full width
typstyle --wrap-text=sentence -i athena-tu-darmstadt-thesis/chapters/* # format code with normal line width