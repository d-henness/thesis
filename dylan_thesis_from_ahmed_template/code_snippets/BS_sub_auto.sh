#!/bin/bash

kind=''
sym=''
which='top'

while [ $# -gt 0 ]
do
  val=$1
  shift
  case $val in
    "-S")
       sym='S'
       low=$1
       high=$2
       shift
       shift
     ;;
    "-P")
       sym='P'
       low=$1
       high=$2
       shift
       shift
     ;;
     "-D")
       sym='D'
       low=$1
       high=$2
       shift
       shift
     ;;
     "-F")
       sym='F'
       low=$1
       high=$2
       shift
       shift
     ;;
     "-N")
       kind='nxt'
       change=$1
       shift
     ;;
     "-V")
       ver=$1
       shift
     ;;
     "-B")
       which='bottom'
     ;;
     *)
       job=$val
     ;;
  esac
done

if [ -z $ver ]; then
  ver='intel03'
fi

if [ -z $job ]; then
  if [ $kind == 'nxt' ]; then
    for file in *.inp; do
      dir=`echo $file | sed 's/-.*$//'`
      mkdir $dir
      cp $file $dir/$file'-orig'
      cd $dir
      rm *.inp
      oldnxt=`sed -n -e 's/^.*nxt=//p' $file'-orig' | awk '{print $1}'`
      i=0
      while [ $i -lt $change ]; do
        let newnxt=$oldnxt+$i
        newfile=${file%.*}"_nxt"$newnxt".inp"
        cp $file'-orig' $newfile
        sed -i "s/nxt=$oldnxt/nxt=$newnxt/" $newfile
        let i=$i+1
      done
      cat << EOF > jobsub"$dir".pbs
#!/bin/bash

#PBS -S /bin/bash
#PBS -l nodes=1:ppn=1
#PBS -l mem=4GB
#PBS -l walltime=47:00:00
#PBS -r n
#--#PBS -m bea

#PBS -N $dir-N

cd \$PBS_O_WORKDIR
echo "Current working directory is \`pwd\`"
echo "Running on \`hostname\`"
echo "Starting run at: \`date\`"

EOF
      for job in *.inp; do
        echo "rwtbsRun "$job $ver >> jobsub"$dir".pbs
      done
  
      qsub jobsub"$dir".pbs
      
      cd ../
    done
  
  else
    for file in *.inp; do 
      dir=`echo $file | sed 's/-.*$//'`
      mkdir $dir
      cp $file $dir/$file'-orig'
      cd $dir
      rm *.inp
      totalalpha=`sed -n -e 's/^.*nalp=//p' $file'-orig' | awk '{print $1}'`
      nbfsym=`sed -n -e "s/^.*nbfsym(1)=//p" $file'-orig'`
      olds=`echo $nbfsym | awk '{print $1}'`
      oldp=`echo $nbfsym | awk '{print $2}'`
      oldd=`echo $nbfsym | awk '{print $3}'`
      oldf=`echo $nbfsym | awk '{print $4}'`
      news=$olds
      newp=$oldp
      newd=$oldd
      newf=$oldf
      i=$low
      while [ $i -le $high ]; do
        let newalpha=$totalalpha
        if [ $sym == 'S' ]; then
          let newalpha=$totalalpha+$i
          let news=$olds+$i
          if [ "$oldp" != "0" ]; then
            let newp=$newalpha-$totalalpha+$oldp
            if [ "$oldd" != "0" ]; then
              let newd=$newalpha-$totalalpha+$oldd
              if [ "$oldf" != "0" ]; then
                let newf=$newalpha-$totalalpha+$oldf
              fi
            fi
          fi
        elif [ $sym == 'P' ]; then
          if [ "$oldp" != '0' ]; then
            let newp=$oldp-$high+$i
            let oldpstart=$totalalpha-$oldp+1
            let newpstart=$totalalpha-$newp+1
          fi
        elif [ $sym == 'D' ]; then
          if [ "$oldp" != '0' ]; then
            if [ "$oldd" != "0" ]; then
              let newd=$oldd-$high+$i
              let olddstart=$totalalpha-$oldd+1
              let newdstart=$totalalpha-$newd+1
            fi
           fi
        elif [ $sym == 'F' ]; then
          if [ "$oldp" != '0' ]; then
            if [ "$oldd" != "0" ]; then
              if [ "$oldf" != "0" ]; then
                let newf=$oldf-$high+$i
                let oldfstart=$totalalpha-$oldf+1
                let newfstart=$totalalpha-$newf+1
              fi
            fi
          fi
        fi
        newfile=`echo $file | sed -e "s/"$olds"s/"$news"s/" -e "s/"$oldp"p/"$newp"p/" -e "s/"$oldd"d/"$newd"d/" -e "s/"$oldf"f/"$newf"f/"`
        cp $file'-orig' $newfile
        sed -i -e "s/nalp=$totalalpha/nalp=$newalpha/" -e "s/nbfsym(1)=$olds $oldp $oldd $oldf/nbfsym(1)=$news $newp $newd $newf/" $newfile
	if [ $which == 'top' ]; then
          if [ $sym == 'P' ]; then
            sed -i "s/ $oldpstart +/ $newpstart +/" $newfile
          elif [ $sym == 'D' ]; then
            sed -i "s/ $olddstart +/ $newdstart +/" $newfile
          elif [ $sym == 'F' ]; then
            sed -i "s/ $oldfstart +/ $newfstart +/" $newfile
          fi
	fi
        let i=$i+1
        done
      cat << EOF > jobsub"$dir".pbs
#!/bin/bash

#PBS -S /bin/bash
#PBS -l nodes=1:ppn=1
#PBS -l mem=4GB
#PBS -l walltime=21:00:00
#PBS -r n
#--#PBS -m bea

#PBS -N $dir-$sym

cd \$PBS_O_WORKDIR
echo "Current working directory is \`pwd\`"
echo "Running on \`hostname\`"
echo "Starting run at: \`date\`"

EOF
    
      for job in *.inp; do
        echo "rwtbsRun "$job $ver >> jobsub"$dir".pbs
      done
    
      qsub jobsub"$dir".pbs
      cd ..
    done
  fi
else
  if [ "$kind" == 'nxt' ]; then
      file=$job
      dir=`echo $file | sed 's/-.*$//'`
      mkdir $dir
      cp $file $dir/$file'-orig'
      cd $dir
      rm *.inp
      oldnxt=`sed -n -e 's/^.*nxt=//p' $file'-orig' | awk '{print $1}'`
      i=0
      while [ $i -lt $change ]; do
        let newnxt=$oldnxt+$i
        newfile=${file%.*}"_nxt"$newnxt".inp"
        cp $file'-orig' $newfile
        sed -i "s/nxt=$oldnxt/nxt=$newnxt/" $newfile
        let i=$i+1
      done
      cat << EOF > jobsub"$dir".pbs
#!/bin/bash

#PBS -S /bin/bash
#PBS -l nodes=1:ppn=1
#PBS -l mem=4GB
#PBS -l walltime=47:00:00
#PBS -r n
#--#PBS -m bea

#PBS -N $dir-N

cd \$PBS_O_WORKDIR
echo "Current working directory is \`pwd\`"
echo "Running on \`hostname\`"
echo "Starting run at: \`date\`"

EOF
      for job in *.inp; do
        echo "rwtbsRun "$job $ver >> jobsub"$dir".pbs
      done
  
      qsub jobsub"$dir".pbs
      
      cd ../
  
  else
      file=$job
      dir=`echo $file | sed 's/-.*$//'`
      mkdir $dir
      cp $file $dir/$file'-orig'
      cd $dir
      rm *.inp
      totalalpha=`sed -n -e 's/^.*nalp=//p' $file'-orig' | awk '{print $1}'`
      nbfsym=`sed -n -e "s/^.*nbfsym(1)=//p" $file'-orig'`
      olds=`echo $nbfsym | awk '{print $1}'`
      oldp=`echo $nbfsym | awk '{print $2}'`
      oldd=`echo $nbfsym | awk '{print $3}'`
      oldf=`echo $nbfsym | awk '{print $4}'`
      news=$olds
      newp=$oldp
      newd=$oldd
      newf=$oldf
      i=$low
      while [ $i -le $high ]; do
        let newalpha=$totalalpha
        if [ $sym == 'S' ]; then
          let newalpha=$totalalpha+$i
          let news=$olds+$i
          if [ "$oldp" != "0" ]; then
            let newp=$newalpha-$totalalpha+$oldp
            if [ "$oldd" != "0" ]; then
              let newd=$newalpha-$totalalpha+$oldd
              if [ "$oldf" != "0" ]; then
                let newf=$newalpha-$totalalpha+$oldf
              fi
            fi
          fi
        elif [ $sym == 'P' ]; then
          if [ "$oldp" != '0' ]; then
            let newp=$oldp-$high+$i
            let oldpstart=$totalalpha-$oldp+1
            let newpstart=$totalalpha-$newp+1
          fi
        elif [ $sym == 'D' ]; then
          if [ "$oldp" != '0' ]; then
            if [ "$oldd" != "0" ]; then
              let newd=$oldd-$high+$i
              let olddstart=$totalalpha-$oldd+1
              let newdstart=$totalalpha-$newd+1
            fi
           fi
        elif [ $sym == 'F' ]; then
          if [ "$oldp" != '0' ]; then
            if [ "$oldd" != "0" ]; then
              if [ "$oldf" != "0" ]; then
                let newf=$oldf-$high+$i
                let oldfstart=$totalalpha-$oldf+1
                let newfstart=$totalalpha-$newf+1
              fi
            fi
          fi
        fi
        newfile=`echo $file | sed -e "s/"$olds"s/"$news"s/" -e "s/"$oldp"p/"$newp"p/" -e "s/"$oldd"d/"$newd"d/" -e "s/"$oldf"f/"$newf"f/"`
        cp $file'-orig' $newfile
        sed -i -e "s/nalp=$totalalpha/nalp=$newalpha/" -e "s/nbfsym(1)=$olds $oldp $oldd $oldf/nbfsym(1)=$news $newp $newd $newf/" $newfile
        if [ $which == 'top' ]; then
          if [ $sym == 'P' ]; then
            sed -i "s/ $oldpstart +/ $newpstart +/" $newfile
          elif [ $sym == 'D' ]; then
            sed -i "s/ $olddstart +/ $newdstart +/" $newfile
          elif [ $sym == 'F' ]; then
            sed -i "s/ $oldfstart +/ $newfstart +/" $newfile
          fi
        fi
        let i=$i+1
        done
      cat << EOF > jobsub"$dir".pbs
#!/bin/bash

#PBS -S /bin/bash
#PBS -l nodes=1:ppn=1
#PBS -l mem=4GB
#PBS -l walltime=21:00:00
#PBS -r n
#--#PBS -m bea

#PBS -N $dir-$sym

cd \$PBS_O_WORKDIR
echo "Current working directory is \`pwd\`"
echo "Running on \`hostname\`"
echo "Starting run at: \`date\`"

EOF
    
      for newjob in *.inp; do
        echo "rwtbsRun "$newjob $ver >> jobsub"$dir".pbs
      done
    
      qsub jobsub"$dir".pbs
      cd ..
  fi
fi
