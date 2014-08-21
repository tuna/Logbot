#!/bin/bash


if [ ! -d public/ ] ; then
  echo -e "public/ not exist or not a directory"
  exit 1
fi

wget -V >/dev/null 2>&1
if [ $? != 0 ] ; then
  echo -e "command \"wget\" not found"
  exit 1
fi

wget -O public/md5.min.js https://raw.githubusercontent.com/blueimp/JavaScript-MD5/1.1.0/js/md5.min.js