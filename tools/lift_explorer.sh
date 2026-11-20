#!/bin/sh
# tools/lift_explorer.sh: NT 4.0's explorer on its own ntdll..gdi32, comctl32, shell32, comdlg32 and mpr
# (the host's advapi32 as a proxy), lifted into src/gen/ntexplorer and built. tools/run_explorer.sh runs it.
R=work/rebased-shell
sh tools/fetch_nt4.sh || exit 1
M=""; for m in ntdll kernel32 msvcrt user32 gdi32 comctl32 shell32 comdlg32 mpr; do M="$M $R/$m.dll"; done
py -3 tools/lift.py ntexplorer $R/explorer.exe $M > work/lift_ntexplorer.log 2>&1 || { tail -3 work/lift_ntexplorer.log; exit 1; }
tail -1 work/lift_ntexplorer.log
cmd //d //c "$(cygpath -w "$PWD")\build.cmd --target rebuild_cache" >/dev/null 2>&1
cmd //d //c "$(cygpath -w "$PWD")\build.cmd --target ntexplorer" > work/build_ntexplorer.log 2>&1 || { grep -E " error|FAILED" work/build_ntexplorer.log | head; exit 1; }
echo built ntexplorer
