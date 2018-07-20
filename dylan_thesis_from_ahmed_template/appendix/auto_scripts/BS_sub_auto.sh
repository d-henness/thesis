#!/bin/bash

sym=''
nuc=''
exepath=/home/dhenness/prophet/exe  # path to the executable
ver=dfratomgpu_binarysearch2.x      # the cudaDFRATOM executable file
alljobs=false
bottom=false
wtime=01:00:00

if [[ -z $exepath ]]; then
  echo "You must set the path to the executable"
  exit
fi

while [ $# -gt 0 ]
do
  val=$1
  shift
  case $val in
    "-a")
       alljobs=true
     ;;
    "-b")
      bottom=true
    ;;
    "-gauss")
       nuc='gauss_'
     ;;
    "-point")
       nuc='point_'
     ;;
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
     "-t")
       wtime=$1
       shift
     ;;
     *)
       job=$val
     ;;
  esac
done

boilerplate(){
  cat << EOF
#!/bin/bash
#SBATCH --account=def-mariusz
#SBATCH --gres=gpu:1
#SBATCH --mem=4GB
#SBATCH --time=$1
#SBATCH --job-name=$2
#SBATCH --output=%x-%j.out

echo ----------------------------------------
echo ----------------------------------------
echo began running on \`date\`
echo ----------------------------------------
echo ----------------------------------------
$3 $4 > $5
echo ----------------------------------------
echo ----------------------------------------
echo stopped running on \`date\`
echo ----------------------------------------
echo ----------------------------------------
EOF
}

if [[ -z $nuc ]]; then
  echo No nuc entered
  exit
fi

if [ "$alljobs" = true ]; then
  job=`ls *inp`
elif [ -z "$job" ]; then
  echo no job given
  exit
fi

for file in $job; do
  dir=`echo $file | sed 's/_.*$//'`
  mkdir $dir
  cp $file $dir/$file-orig
  cd $dir

  # keep old out files and delete others
  rename "out" "out-old" *.out
  rm *inp
  rm *sh

  file_base=$(echo $file | sed -e "s/$nuc.*/$nuc/")
  read -r -a old_bs <<< $(sed -n -e "/nbs/{s/nbs=//; p}" $file-orig)
  read -r -a old_start <<< $(sed -n -e "/start/{s/start=//; s/\$end//; p}" $file-orig)

  # keep track of how many files are made
  total=0
  for i in $(seq $low $high); do
    for j in $(seq 0 6); do
      new_bs[j]=${old_bs[j]}
      new_start[j]=${old_start[j]}
    done

    # make alterations based on symmetry

    case $sym in
      "F")
        ((new_bs[5]-=$i))
        ((new_bs[6]-=$i))
        # make sure that the number of basis functions is not zero
        if [[ "${new_bs[5]}" == "0" ]]; then
          break
        fi
        ((new_start[5]+=$i))
        ((new_start[6]+=$i))
        ;;
      "D")
        ((new_bs[3]-=$i))
        ((new_bs[4]-=$i))
        if [[ "${new_bs[3]}" == "0" ]]; then
          break
        fi
        ((new_start[3]+=$i))
        ((new_start[4]+=$i))
        ;;
      "P")
        ((new_bs[1]-=$i))
        ((new_bs[2]-=$i))
        if [[ "${new_bs[1]}" == "0" ]]; then
          break
        fi
        ((new_start[1]+=$i))
        ((new_start[2]+=$i))
        ;;
      "S")
        ((new_bs[0]-=$i))
        if [[ "${new_bs[0]}" == "0" ]]; then
          break
        fi
        ((new_start[0]+=$i))
        ;;
    esac
    new_file=$file_base${new_bs[0]}"s"${new_bs[1]}"p-"${new_bs[2]}"p+"${new_bs[3]}"d-"${new_bs[4]}"d+"${new_bs[5]}"f-"${new_bs[6]}"f+.inp"
    cp $file-orig $new_file
    sed -i -e "s/${old_bs[0]} ${old_bs[1]} ${old_bs[2]} ${old_bs[3]} ${old_bs[4]} ${old_bs[5]} ${old_bs[6]}/\
${new_bs[0]} ${new_bs[1]} ${new_bs[2]} ${new_bs[3]} ${new_bs[4]} ${new_bs[5]} ${new_bs[6]}/" $new_file # continuing from last line
    if [ "$bottom" == true ]; then
      sed -i -e "s/${old_start[0]} ${old_start[1]} ${old_start[2]} ${old_start[3]} ${old_start[4]} ${old_start[5]} ${old_start[6]}/\
${new_start[0]} ${new_start[1]} ${new_start[2]} ${new_start[3]} ${new_start[4]} ${new_start[5]} ${new_start[6]}/" $new_file # continuing from last line
    fi

    boilerplate $wtime ${new_file%????} $exepath/$ver $new_file ${new_file%???}log > ${new_file%???}sh
    ((total++))
  done


  echo "Submitting $total input files"
  for sub in *sh; do
    sbatch $sub
  done
done
