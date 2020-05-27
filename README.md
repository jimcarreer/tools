# Tools

This is just a repo where I throw weird crap, scripts, little projects and
other odds and ends I use on Linux.  Also, I'm going to use it to document
small issues I encounter using it as my primary OS and the fixes or work
arounds for them.

## GDM/GDM3 Multimonitor Fix
To force the login screen of GDM to be on the correct monitor, that is to say
the primary monitor selected as a user, do the following:
```
sudo cp ~/.config/monitors.xml ~gdm/.config/monitors.xml
sudo chown gdm:gdm ~gdm/.config/monitors.xml
```
Also, for the time being, if wayland is installed and the default for GDM it 
must be disabled in `/etc/gdm3/custom.conf` and modifying it to set:
```
WaylandEnable=false
```
The bug seems to be in wayland. [Reference](https://bugzilla.redhat.com/show_bug.cgi?id=1184617#c4).
