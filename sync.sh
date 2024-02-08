#!/bin/bash

SRC_ROOT=/home/jim/backup/jds

for JDS_DIR in `ls $SRC_ROOT`; do
  if [[ "$JDS_DIR" =~ ^JDS\.20[0-9]{2}\.[0-9]{2}$ ]]; then
    echo "Handling ${JDS_DIR}"
    rsync --progress --delete -rltpDcuog "${SRC_ROOT}/${JDS_DIR}/" "./${JDS_DIR}/"
  else
    echo "Skipping ${JDS_DIR}"
  fi
done
