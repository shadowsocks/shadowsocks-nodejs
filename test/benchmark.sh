#!/bin/bash

for i in {1..10} ; do
  echo $i
  curl --socks5-hostname 127.0.0.1:$1 http://www.google.com/ >/dev/null
done
