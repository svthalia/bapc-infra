#!/bin/bash

for file in *.ps; do ps2pdf $file $file.pdf; rm $file; done
