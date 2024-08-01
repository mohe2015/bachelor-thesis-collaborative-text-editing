#!/usr/bin/env bash

cd text-rdt

rm -R jvm/figure-benchmark-results
mkdir -p jvm/figure-benchmark-results
rm jvm/*.csv

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkSequentialInserts.sequentialInserts -f 1 -wi 3 -w 3 -i 1 -r 0 -p factoryConstructor=simple,complex -p count=4000,8000,12000,16000,20000 -p shouldMeasureMemory=true -bm Throughput -rf csv -rff simple-complex-sequential-inserts-memory.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyRealWorldBenchmarkLocal -f 1 -wi 3 -w 3 -i 1 -r 0 -p factoryConstructor=simple,complex,simpleavl -p count=4000,8000,12000,16000,20000 -p shouldMeasureMemory=true -bm Throughput -rf csv -rff simple-complex-simpleavl-real-world-memory.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyRealWorldBenchmarkLocal -f 1 -wi 3 -w 3 -i 1 -r 0 -p factoryConstructor=simpleavl,complexavl -p count=50000,100000,150000,200000,259778 -p shouldMeasureMemory=true -bm Throughput -rf csv -rff simpleavl-complexavl-large-real-world-memory.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkEvilInsert.evilChildrenComplexAVL -f 1 -wi 3 -w 3 -i 1 -r 0 -p factoryConstructor=complexavl -p count=50000,100000,150000,200000,259778 -p shouldMeasureMemory=true -bm Throughput -rf csv -rff complexavl-evil-children-memory.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkEvilInsert.evilInsert1ComplexAVL -f 1 -wi 3 -w 3 -i 1 -r 0 -p factoryConstructor=complexavl -p count=50000,100000,150000,200000,259778 -p shouldMeasureMemory=true  -bm Throughput -rf csv -rff complexavl-evil-insert-1-memory.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkEvilInsert.evilInsert2ComplexAVL -f 1 -wi 3 -w 3 -i 1 -r 0 -p factoryConstructor=complexavl -p count=50000,100000,150000,200000,259778 -p shouldMeasureMemory=true -bm Throughput -rf csv -rff complexavl-evil-insert-2-memory.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkEvilInsert.evilSplitComplexAVL -f 1 -wi 3 -w 3 -i 1 -r 0 -p factoryConstructor=complexavl -p count=50000,100000,150000,200000,259778 -p shouldMeasureMemory=true -bm Throughput -rf csv -rff complexavl-evil-split-memory.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkEvilInsert.evilSplitManyRightChildrenComplexAVL -f 1 -wi 3 -w 3 -i 1 -r 0 -p factoryConstructor=complexavl -p count=50000,100000,150000,200000,259778 -p shouldMeasureMemory=true -bm Throughput -rf csv -rff complexavl-evil-split-many-right-children-memory.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyRealWorldBenchmarkLargeLocal -f 1 -wi 3 -w 3 -i 1 -r 0 -p factoryConstructor=complexavl -p count=20,40,60,80,100 -p shouldMeasureMemory=true -bm Throughput -rf csv -rff complexavl-extra-large-local-real-world-memory.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyRealWorldBenchmarkLargeRemote -f 1 -wi 3 -w 3 -i 1 -r 0 -p factoryConstructor=complexavl -p count=20,40,60,80,100 -p shouldMeasureMemory=true -bm Throughput -rf csv -rff complexavl-extra-large-remote-real-world-memory.csv"


sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkSequentialInserts.sequentialInserts -f 1 -p factoryConstructor=simple,complex -p count=4000,8000,12000,16000,20000 -bm Throughput -rf csv -rff simple-complex-sequential-inserts.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyRealWorldBenchmarkLocal -f 1 -p factoryConstructor=simple,complex,simpleavl -p count=4000,8000,12000,16000,20000 -bm Throughput -rf csv -rff simple-complex-simpleavl-real-world.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyRealWorldBenchmarkLocal -f 1 -p factoryConstructor=simpleavl,complexavl -p count=50000,100000,150000,200000,259778 -bm Throughput -rf csv -rff simpleavl-complexavl-large-real-world.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkEvilInsert.evilChildrenComplexAVL -f 1 -p factoryConstructor=complexavl -p count=50000,100000,150000,200000,259778 -bm Throughput -rf csv -rff complexavl-evil-children.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkEvilInsert.evilInsert1ComplexAVL -f 1 -p factoryConstructor=complexavl -p count=50000,100000,150000,200000,259778 -bm Throughput -rf csv -rff complexavl-evil-insert-1.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkEvilInsert.evilInsert2ComplexAVL -f 1 -p factoryConstructor=complexavl -p count=50000,100000,150000,200000,259778 -bm Throughput -rf csv -rff complexavl-evil-insert-2.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkEvilInsert.evilSplitComplexAVL -f 1 -p factoryConstructor=complexavl -p count=50000,100000,150000,200000,259778 -bm Throughput -rf csv -rff complexavl-evil-split.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkEvilInsert.evilSplitManyRightChildrenComplexAVL -f 1 -p factoryConstructor=complexavl -p count=50000,100000,150000,200000,259778 -bm Throughput -rf csv -rff complexavl-evil-split-many-right-children.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyRealWorldBenchmarkLargeLocal -f 1 -p factoryConstructor=complexavl -p count=20,40,60,80,100 -bm Throughput -rf csv -rff complexavl-extra-large-local-real-world.csv"

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyRealWorldBenchmarkLargeRemote -f 1 -p factoryConstructor=complexavl -p count=20,40,60,80,100 -bm Throughput -rf csv -rff complexavl-extra-large-remote-real-world.csv"


sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkSequentialInserts.sequentialInserts -f 1 -p factoryConstructor=simple -p count=20000 -bm Throughput -prof \"async:output=jfr;dir=figure-benchmark-results;event=cpu;alloc\""

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyTerribleBenchmarkSequentialInserts.sequentialInserts -f 1 -p factoryConstructor=complex -p count=10000000 -bm Throughput -prof \"async:output=jfr;dir=figure-benchmark-results;event=cpu;alloc\""

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyRealWorldBenchmarkLocal -f 1 -p factoryConstructor=complex -p count=20000 -bm Throughput -prof \"async:output=jfr;dir=figure-benchmark-results;event=cpu;alloc\""

sbt "textrdtJVM/clean; textrdtJVM/jmh:run MyRealWorldBenchmarkLocal -f 1 -p factoryConstructor=simpleavl,complexavl -p count=259778 -bm Throughput -prof \"async:output=jfr;dir=figure-benchmark-results;event=cpu;alloc\""


