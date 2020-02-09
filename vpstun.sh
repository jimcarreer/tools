# Key setup on this vps
ssh -D 9999 -C -q -N jim@nicksec.org &
sshpid=$!

/opt/google/chrome/google-chrome --host-resolver-rules="MAP * ~NOTFOUND, EXCLUDE 127.0.0.1" --proxy-server="socks5://127.0.0.1:9999" --incognito --user-data-dir="/home/jim/.config/google-chrome-proxied/" --new-window

# Dont just orphan the shit out of these connections
if ls -l /proc/$sshpid/exe 2> /dev/null | grep -q "ssh$"; then
	kill -9 $sshpid
fi
