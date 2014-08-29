#!/bin/bash

helpmsg() {
	echo "Usage: gen-make [ -e name ] [ -c ]"
	echo "                [ -s compiler name ]"
	echo "                [ -f compile flag ]"
	echo "Try 'gen-make -h' for more information"
	if [ $1 -eq 1 ]; then
	echo "Description:"
	echo "	Generates a makefile with the files located in the current directory"
	echo "Options:"
	echo "	-e (optional) Used to specify an executable name"
	echo
	echo "	-s (optional) sets a different compiler to use"
	echo "	   Default is g++"
	echo 
	echo "	-c (optional) specifies to create the make file for"
	echo "	   compiling C programs.  Default is C++"
	echo
	echo "	-f (optional) specifies the version of c++ to use like c++11"
	echo 
	fi
	exit 1
} 

compiler="g++"
cleanheader="clean:\n\t\t"
clean='rm -rf *.o $(EXE)'
exearg=0
defaultfile="*.cpp"

while getopts ":s: :e: :c :h :f:" opt; do
	case $opt in
	c) 
		defaultfile="*.c"
		;;
	f)
		cflag="-std=$OPTARG"
		;;
	s)
		compiler="$OPTARG"
		;;
	e)
		exe="$OPTARG"
		exearg=1
		;;
	h)
		helpmsg 1
		;;
	\?)
		echo "ERROR: Invalid option: -$OPTARG"
		helpmsg 0
		;;
	esac
done

shift $(($OPTIND-1))



declare -a objs
declare -a headers

files=(*)

for f in "${files[@]}"
do
	if [[ $f == $defaultfile ]]; then
		objsmap+=("$f ${f%%.*}.o")
		objs+=("${f%%.*}.o")
	elif [[ $f == *.h ]]; then
		headers+=("$f")
	fi
done

if [ ${#objs[@]} -lt 1 ]; then
	echo "ERROR: No $defaultfile files found"
	helpmsg 0
fi

if [ $exearg -eq 0 ]; then
	echo -ne "Please specify an executable name: "
	read exe
fi

echo "Creating makefile..."
if [ -a makefile ]; then
	rm makefile
fi
touch makefile
if [ $? -ne 0 ]; then
	echo "Error creating file.  Do you have permission?"
	exit 1
fi

echo "CC= $compiler" >> makefile
echo "OBJECTS= ${objs[@]}" >> makefile
echo "EXE= $exe" >> makefile
echo "CFLAGS= $cflag" >> makefile
echo >> makefile
echo -e '$(EXE):\t\t$(OBJECTS)' >> makefile
echo -e '\t\t$(CC) -o $(EXE) $(OBJECTS)' >> makefile


declare -a cppheaderlist
for o in "${objsmap[@]}"
do
	unset cppheaderlist
	for h in "${headers[@]}"
	do
		cppfilename=$(echo "${o[0]}" | awk '{print $1}')
		cat $cppfilename | grep -q "$h"
		if [ $? -eq 0 ]; then
			cppheaderlist+=("$h")
		fi
	done
	
	objname=$(echo "${o[0]}" | awk '{print $2}')
	cppname=$(echo "${o[0]}" | awk '{print $1}')
	echo -e "$objname:\t\t$cppname ${cppheaderlist[@]}" >> makefile
	echo -e -n '\t\t$(CC) -c ' >> makefile
	echo -e "$cppname" >> makefile
done

echo -e -n "$cleanheader" >> makefile
echo "$clean" >> makefile