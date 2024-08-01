#!/usr/bin/env bash

cd text-rdt

ls -d jvm/figure-benchmark-results/*/ | xargs -I {} bash -c "cd {} && java -jar /opt/async-profiler/lib/converter.jar jfr2flame jfr-cpu.jfr cpu.html"
ls -d jvm/figure-benchmark-results/*/ | xargs -I {} bash -c "cd {} && java -jar /opt/async-profiler/lib/converter.jar jfr2flame --alloc --simple jfr-cpu.jfr alloc.html"

cd ..

gnuplot latex/figures/gnupulot.txt