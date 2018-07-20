#!/bin/bash

sym=''
alljobs=false
bottom=false
path_to_exe='/some/path' # must be set!
wtime=01:00:00

if [[ -z $path_to_exe ]]; then
  echo "You must set the path to rwtbs.exe"
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
#SBATCH --account=def-mariusz # change depending
#SBATCH --mem=2GB
#SBATCH --time=$1
#SBATCH --job-name=$2

echo ----------------------------------------
echo ----------------------------------------
echo began running on \`date\`
echo ----------------------------------------
echo ----------------------------------------
$3/rwtbs $2 >& $4
echo ----------------------------------------
echo ----------------------------------------
echo stopped running on \`date\`
echo ----------------------------------------
echo ----------------------------------------
EOF
}


if [ "$alljobs" == true ]; then
  job=`ls *inp`
elif [ -z "$job" ]; then
  echo no job given
  exit
fi

for file in $job; do
  dir=$(echo $file | sed -e "s/-.*//")
  if [[ -d "$dir" ]]; then
    echo "$dir already here"
  else
    mkdir $dir
  fi
  cd $dir

  # keep old out files and delete others
  rename "out" "out-old" *.out
  rm *inp
  rm *GUS
  rm *MCS

  cp ../$file $file"-orig"
  file_base=$(echo $file | sed -e 's/_.*//')

  # read the number of basis functions
  read -r -a old_bs <<< $(sed -n -e '/nbfsym/{s/.*nbfsym(1)=//; s/\$end//; p}' $file"-orig")
  # get the most contracted basis function
  IFS='+' read -r -a old_top <<< $(sed -n -e '/ +/p' $file"-orig")

  # keep track of how many files are made
  total=0
  for i in $(seq $low $high); do
    for j in $(seq 0 3); do
      new_bs[j]=${old_bs[j]}
      new_top[j]=${old_top[j]}
    done

    # make alterations based on symmetry
    case $sym in 
      "F")
        ((new_bs[3]-=$i))
        # make sure that not too many functions are cut
        if [[ "${new_bs[3]}" == "0" ]]; then
          break
        fi
        ((new_top[3]+=$i))
        ;;
      "D")
        ((new_bs[2]-=$i))
        if [[ "${new_bs[2]}" == "0" ]]; then
          break
        fi
        ((new_top[2]+=$i))
        ;;
      "P")
        ((new_bs[1]-=$i))
        if [[ "${new_bs[1]}" == "0" ]]; then
          break
        fi
        ((new_top[1]+=$i))
        ;;
      "S")
        ((new_bs[0]-=$i))
        if [[ "${new_bs[0]}" == "0" ]]; then
          break
        fi
        ((new_top[0]+=$i))
        ;;
    esac

    # make new calculation
    new_file=$file_base"_"${new_bs[0]}"s"${new_bs[1]}"p"${new_bs[2]}"d"${new_bs[3]}"f.inp"
    cp $file"-orig" $new_file
    sed -i "s/nalp=${old_bs[0]}/nalp=${new_bs[0]}/" $new_file
    sed -i "s/${old_bs[0]} ${old_bs[1]} ${old_bs[2]} ${old_bs[3]}/${new_bs[0]} ${new_bs[1]} ${new_bs[2]} ${new_bs[3]}/" $new_file
    if [ "$bottom" == false ]; then
      sed -i -e "s/${old_top[0]}+/${new_top[0]} +/" -e "s/${old_top[1]}+/${new_top[1]} +/" -e "s/${old_top[2]}+/${new_top[2]} +/" -e "s/${old_top[3]} +/${new_top[3]} +/" $new_file
    fi

    # write submission script
    boilerplate $wtime $new_file $path_to_exe ${new_file%???}out > ${new_file%???}.sh
    #sbatch ${new_file%???}.sh # uncomment to automatically submit job
    ((total++))
  done
  echo "$total files made"
  cd ../
done
