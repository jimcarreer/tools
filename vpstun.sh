#!/bin/bash

sshpid=''
encdir=/home/jim/.config/google-chrome-proxied-enc/
decdir=/home/jim/.config/google-chrome-proxied/

# Chrome default profile files cleared on exit
rmfiles="History History-journal 'Top Sites' 'Top Sites-journal' 'Visited Links' 'Web Data'"
rmfiles="${rmfiles} 'Web Data-journal' Cookies' 'Cookies-journal' 'Media History'"
rmfiles="${rmfiles} 'Media History-journal' 'History Provider Cache'"

# Use this all mostly for user interaction
if ! command -v zenity &> /dev/null; then
  echo "Missing zenity"
  exit 1
fi


function error_bail {
  msg=$1
  err=1
  if [[ "$#" -eq 2 ]]; then
    err=$2
  fi
  zenity --error --text="${msg}"
  exit $err
}


function setup {
  if ! command -v encfs &> /dev/null; then
    error_bail "You're missing encfs"
  fi
  if [[ ! -d $encdir ]]; then
    mkdir $encdir
    if [[ ! "$?" ]]; then
      error_bail "Failed to make empty enc dir"
    fi
  fi
  if [[ ! -d $decdir ]]; then
    mkdir $decdir
    if [[ ! "$?" ]] ; then
      error_bail "Failed to make empty enc dir"
    fi
  fi

  # Key setup on this vps
  ssh -D 9999 -C -q -N jim@nicksec.org > /dev/null 2>&1 &
  sshpid=$!
  result=$(lsof -i -P -n | grep -E "^ssh.+127.0.0.1:9999 \(LISTEN\)")
  if [[ ! -z "${result}" ]]; then
    error_bail "Proxy did not come up"
  fi

  dircpass=$(zenity --password --text="FS Password")
  result=$(echo "${dircpass}" | encfs --standard --stdinpass ${encdir} ${decdir} 2>&1 | grep -o "Error decoding")
  if [[ ! -z "${result}"  ]]; then
    error_bail "Bad password"
  fi
}


function tear_down {
  # Dont just orphan the shit out of these connections
  result=$(ls -l /proc/$sshpid/exe 2> /dev/null | grep "ssh$")
  if [[ ! -z "{result}" ]]; then
    echo "Killing tunnel (PID: ${sshpid})"
    kill -9 $sshpid  > /dev/null 2>&1
  fi
  # Clean up some  some chrome stuff
  cd $decdir/Default > /dev/null 2>&1
  for filename in ${rmfiles}; do
    rm -f $decdir/Default/${filename} > /dev/null 2>&1
  done
  # Unmount encfs with force
  echo "Unmounting ${decdir}"
  umount -l ${decdir} > /dev/null 2>&1
  echo "Removing ${decdir}"
  rm -rf ${decdir}
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
