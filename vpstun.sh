#!/bin/bash

sshpid=''
encdir=/home/jim/.config/google-chrome-proxied-enc/
decdir=/home/jim/.config/google-chrome-proxied/

# Chrome default profile files cleared on exit
rmfiles="History History-journal 'Top Sites' 'Top Sites-journal' 'Visited Links' 'Web Data'"
rmfiles="${rmfiles} 'Web Data-journal' Cookies' 'Cookies-journal' 'Media History'"
rmfiles="${rmfiles} 'Media History-journal' 'History Provider Cache'"


function setup {
  if ! command -v zenity &> /dev/null; then
    echo "Missing zenity"
    exit 1
  fi
  if ! command -v encfs &> /dev/null; then
    zenity --warning --text="You're missing encfs"
    exit 1
  fi
  if [ ! -d $encdir ]; then
    mkdir $encdir
    if ! $?; then
      zenity --warning --text="Failed to make empty enc dir"
      exit 1
    fi
  fi
  if [ ! -d $decdir ]; then
    mkdir $decdir
    if [[ ! "$?" ]]; then
      zenity --warning --text="Failed to make empty dec dir"
      exit 1
    fi
  fi
  dircpass=$(zenity --password --text="FS Password")
  # Key setup on this vps
  ssh -D 9999 -C -q -N jim@nicksec.org > /dev/null 2>&1 &
  sshpid=$!
  echo "${dircpass}" | encfs --standard --stdinpass ${encdir} ${decdir}
  if [[ -z `ls -A "$decdir"` ]]; then
    zenity --warning --text="Bad password"
    exit 1
  fi
}

function tear_down {
  # Dont just orphan the shit out of these connections
  if ls -l /proc/$sshpid/exe 2> /dev/null | grep -q "ssh$"; then
    echo "Killing tunnel (PID: ${sshpid})"
    kill -9 $sshpid  > /dev/null 2>&1
  fi
  # Clean up some  some chrome stuff
  cd $decdir/Default > /dev/null 2>&1
  for filename in ${rmfiles}; do
    rm -f $decdir/Default/${filename} > /dev/null 2>&1
  done
  # Unmount encfs with force
  umount -l ${decdir} > /dev/null 2>&1
  rmdir ${decdir}
}
trap tear_down EXIT

function run_chrome {
  /opt/google/chrome/google-chrome --host-resolver-rules="MAP * ~NOTFOUND, EXCLUDE 127.0.0.1" \
                                   --proxy-server="socks5://127.0.0.1:9999" \
                                   --user-data-dir="${decdir}" \
                                   --new-window
}


setup
run_chrome
