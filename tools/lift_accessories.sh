#!/bin/sh
# tools/lift_accessories.sh [APP...]: the accessories (default winmine notepad calc) on NT 4.0's own
# ntdll..gdi32, comctl32, shell32 and comdlg32 (the host's advapi32 as a proxy); cmd on its own set.
R=work/rebased-shell
sh tools/fetch_nt4.sh || exit 1
U="$R/ntdll.dll $R/kernel32.dll $R/msvcrt.dll $R/user32.dll $R/gdi32.dll"
SET3="$U $R/comctl32.dll $R/shell32.dll $R/comdlg32.dll"
for app in ${@:-winmine notepad calc}; do
  case $app in cmd) T=cmd; M="work/rebased/cmd.exe ${U//$R/work/rebased} work/rebased/mpr.dll";; *) T=nt$app; M="$R/$app.exe $SET3";; esac
  py -3 tools/lift.py $T $M > work/lift_$T.log 2>&1 || { tail -3 work/lift_$T.log; exit 1; }
  cmd //d //c "$(cygpath -w "$PWD")\build.cmd --target rebuild_cache" >/dev/null 2>&1
  cmd //d //c "$(cygpath -w "$PWD")\build.cmd --target $T" > work/build_$T.log 2>&1 || { grep -E " error|FAILED" work/build_$T.log | head; exit 1; }
  echo "built $T: $(tail -1 work/lift_$T.log)"
done
