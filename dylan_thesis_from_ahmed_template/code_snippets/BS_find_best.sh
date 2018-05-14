#!/bin/bash

tol=$1

if [ -z $tol ]; then
  tol='5*10^-9'
fi

echo The tolerance in relative error is $tol

mkdir best
for dir in `ls -d */`; do
  if [ "$dir" != 'old/' ]; then
    if [ "$dir" != 'best/' ]; then
      if [ "$dir" != 'tests/' ]; then
      cd $dir
      for file in *.out; do
        error=`grep -A 1 '[E(WT)-E(rf)]/E(rf)' $file | tail -1 | awk '{print $4}'`
        comperror=`echo $error | sed -e 's/D/\*10\^/'`
        testthress=$(bc -l <<< "scale=20; ($tol - $comperror)*10^10 >= 1")
        if [ $testthress -ge 1 ]; then
          cp `echo $file | sed -e 's/out/inp/'` ../best
          cp $file ../best
          echo Found best for $file
          break
        fi
      done
      fi
    fi
  fi
  cd ..
done
