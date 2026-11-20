#!/bin/sh
# tools/box.sh: explorer's registry box (HKCU\Software\pcrecomp\nt4\explorer) and private profile
# (work/profile, the guest's C:\). Idempotent; tools/run_explorer.sh and tools/setup.ps1 run it.
D='WINNT\Profiles'
# a private NT 4.0 profile (tools/profile.py) inside the file box: C:\ is work/profile/C, and the guest
# sees these host paths as C:\WINNT\Profiles\...; never the host's Start Menu, Desktop or AppData
mkdir -p "work/profile/C/WINNT/Profiles" work/profile/C/TEMP work/profile/C/WINNT/system32
# NT 4.0's own registry from its setup hives (the CD has no HIVE*.INF), before the profile's folders:
# shell32's CLSIDs name shell32.dll (not Windows 11's windows.storage.dll), the Explorer key (desktop
# NameSpace), and the default user's Control Panel (the teal desktop, NT 4.0's colours)
H() { py -3 tools/hive.py 'nt4\explorer' "$@" >/dev/null || exit 1; }
H work/sys/software Classes 'HKLM\SOFTWARE\Classes'
H work/sys/software 'Microsoft\Windows\CurrentVersion\Explorer' 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
H work/sys/default 'Control Panel' 'HKCU\Control Panel'
py -3 tools/profile.py 'nt4\explorer' "work/profile/C/WINNT/Profiles" "C:\\$D" >/dev/null || exit 1
# names for the shell's program search (the Run dialog's "winmine"): the launch path starts their lifted runners
for x in winmine notepad calc; do : > work/profile/C/WINNT/system32/$x.exe; done
