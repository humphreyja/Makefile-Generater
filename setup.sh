#!/bin/bash

if [ "$(id -u)" != "0" ]; then
	echo "ERROR: Required root access"
	exit 1
fi

cp ./gen-make.sh /bin/gen-make