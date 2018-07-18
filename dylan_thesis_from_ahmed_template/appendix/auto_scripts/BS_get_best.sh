#!/bin/bash

tol=$1

if [ -z $tol ]; then
  tol='5*10^-8'
fi

echo The tolerance in relative error is $tol

mkdir best
for dir in `ls -d */`; do
  if [ "$dir" != 'old/' ]; then
    if [ "$dir" != 'best/' ]; then
      if [ "$dir" != 'tests/' ]; then
      echo entering $dir
      cd $dir
      for file in *.inp; do
        error=`grep -i 'rela' ${file%????}*log | tail -1 | awk '{print $7}'`
        comperror=`echo $error | sed -e 's/E/\*10\^/'`
        testthress=`echo "scale=20; ($tol - $comperror)*10^10 >= 1" | bc -l`
        if [ $testthress -ge 1 ]; then
          cp $file ../best
          cp ${file%????}*out ../best
          echo Found best for $file
          break
        fi
      done
      fi
    fi
  fi
  cd ..
done
