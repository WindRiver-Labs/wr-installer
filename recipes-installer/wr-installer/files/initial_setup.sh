#!/bin/sh
echo "Running initial setup scripts"
for i in /etc/initial_setup/[0-9]*.sh
do
  echo "-> running ${i}"
  sh ${i}
done
