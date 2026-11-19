#!/bin/sh
# tools/fetch_nt4.sh [ISO]: NT 4.0 Workstation's files into work/sys (the CD's I386, then Service
# Pack 6a's files over them), and the rebased set in work/rebased-shell (each module at its own fixed
# base, out of the host's way). Needs work/iso/<I386 dir> and the SP6a package (7z x from ISO when
# given). Idempotent.
P=${PCRECOMP:-../pcrecomp}; R=${R:-work/rebased-shell}; S=work/sys
I=work/iso/ROOT/WNT40WKS/I386; SP=work/iso/ROOT/SVCPACK/WKS_SRV/SP6A_I386.EXE
[ -n "$1" ] && [ ! -d $I ] && { 7z x -y -owork/iso "$1" 'ROOT/WNT40WKS/I386/*' 'ROOT/SVCPACK/WKS_SRV/SP6A_I386.EXE' >/dev/null || exit 1; }
[ -d $I ] || { echo "no $I: tools/fetch_nt4.sh <NT 4.0 CD image>"; exit 1; }
if [ ! -f $S/.sp6a ]; then
  mkdir -p $S work/sp6a
  for f in $I/*; do case "$f" in *_) 7z e -y -o$S "$f" >/dev/null 2>&1;; *) [ -f "$f" ] && cp "$f" $S/;; esac; done
  [ -f $SP ] && { 7z x -y -owork/sp6a $SP >/dev/null || exit 1; cp -f work/sp6a/* $S/ 2>/dev/null; }
  ( cd $S && for f in *; do l=$(echo "$f" | tr A-Z a-z); [ "$f" = "$l" ] || mv -f "$f" "$l"; done )
  touch $S/.sp6a
fi
mkdir -p $R
# the modules and their bases (0x20000000 up: the system set; 0x21000000 up: the shell's)
BASES="ntdll.dll=0x20000000 kernel32.dll=0x20100000 msvcrt.dll=0x20200000 user32.dll=0x20300000 gdi32.dll=0x20400000
 comctl32.dll=0x20800000 shell32.dll=0x21000000 comdlg32.dll=0x21A00000
 mpr.dll=0x21B00000 winmm.dll=0x21E00000 winspool.drv=0x21F00000 ole32.dll=0x22000000 oleaut32.dll=0x22200000
 version.dll=0x22400000 lz32.dll=0x22500000 netapi32.dll=0x22600000 netrap.dll=0x22700000 samlib.dll=0x22800000"
EXES="explorer.exe notepad.exe calc.exe winmine.exe cmd.exe"
NEED=""; for b in $BASES; do f=${b%%=*}; [ -f $R/$f ] || NEED="$NEED $b"; done
[ -z "$NEED" ] || py -3 $P/tools/pe/rebase.py $S $R $NEED >/dev/null || exit 1
for e in $EXES; do [ -f $R/$e ] || cp $S/$e $R/; done   # (NT 4.0's exes have no relocations: at their own bases)
echo "fetched: $R"
# cmd's set (stage 2): only what it lifts, so the host's advapi32 and shell32 answer the rest
mkdir -p work/rebased; for f in cmd.exe ntdll.dll kernel32.dll msvcrt.dll user32.dll gdi32.dll mpr.dll; do [ -f work/rebased/$f ] || cp $R/$f work/rebased/; done
