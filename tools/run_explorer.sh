#!/bin/sh
# tools/run_explorer.sh NAME [SECS] [hiddenrun args...]: ntexplorer on an 800x600 virtual screen, muted,
# on hiddenrun's private desktop (pcrecomp_nt4); shots/exp/NAME_<t>.png and .log. $EXARGS go to ntexplorer.
# Fails (exit 1) if any host module other than the allowed proxies was mapped into the guest.
N=$1; S=${2:-20}; shift 2 2>/dev/null
mkdir -p shots/exp
export PCRECOMP_MUTE=1 MSYS_NO_PATHCONV=1 HIDDENRUN_DESKTOP=${HIDDENRUN_DESKTOP:-pcrecomp_nt4} W2K_SCREEN=${W2K_SCREEN:-800x600}
# a private NT 4.0 profile (tools/profile.py) inside the file box: C:\ is work/profile/C, and the guest
# sees these host paths as C:\WINNT\Profiles\...; never the host's Start Menu, Desktop or AppData
B=$(cygpath -w "$PWD/work/profile"); D='WINNT\Profiles'
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
P="$B\\C\\$D"
export PCRECOMP_GUEST_PATH='C:\WINNT\system32'
export ProgramFiles="$B\C\Program Files" CommonProgramFiles="$B\C\Program Files\Common Files" ProgramW6432= CommonProgramW6432=
export USERPROFILE="$P\user" ALLUSERSPROFILE="$P\all" ProgramData="$P\all" PUBLIC="$P\all" \
  APPDATA="$P\user\Application Data" LOCALAPPDATA="$P\user\Local Settings\Application Data" \
  HOMEDRIVE= HOMEPATH= TEMP="$B\C\TEMP" TMP="$B\C\TEMP" PCRECOMP_FILEBOX="$B"
py -3 tools/hiddenrun.py --secs "$S" --shot $((S - 3)) --out shots/exp/$N "$@" -- "$(cygpath -m "$PWD")/build/ntexplorer.exe" --mute --watchdog $((S - 1)) $EXARGS | tail -${TAIL_SHOWN:-2}
grep -av "HOST DLL in the guest: .*advapi32.dll" shots/exp/$N.log | grep -av "RegisterClassExW .* failed: 1410" | head -${LINES_SHOWN:-40}
# ponytail: advapi32 is the only host DLL explorer may proxy; widen ALLOW when a new one is reviewed
ALLOW='advapi32\.dll'
# every process in the run, launched children included, from its first line: the same rule for all
BAD=$(grep -aiE "HOST DLL in the guest|the host.s, through a proxy" shots/exp/$N.log | grep -aivE "[\\/]($ALLOW)[,:]")
[ -z "$BAD" ] || { echo "!!! HOST MODULE IN THE GUEST (run failed):"; echo "$BAD"; exit 1; }
