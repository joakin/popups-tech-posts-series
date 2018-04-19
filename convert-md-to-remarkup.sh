#!/usr/bin/env bash

shopt -s globstar

for f in docs/**/*.md; do
  DIR=$(dirname "${f}")
  NAME=$(basename "${f}")
  OUTDIR="_phame${DIR#docs}"
  OUTNAME="${NAME%.md}.remarkup"
  OUT="${OUTDIR}/${OUTNAME}"
  mkdir -p "$OUTDIR" && pandoc -f commonmark -t remarkup.lua "$f" > "$OUT"
done
