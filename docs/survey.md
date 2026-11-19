# Windows NT 4.0 Workstation SP6a on pcrecomp: survey and handoff

Sibling of win2000 and winxp. Toolkit branch: pcrecomp `nt4` (worktree G:/recomp/pc/pcrecomp-nt4,
rebased on origin/main 621860a). NT 4.0-specific answers go behind ntguest.h's `nt_guest_nt4()`.

## Stages
1. winmine, notepad, calc on the host's DLLs (build/<app>.exe): run.
2. cmd.exe on NT 4.0's own ntdll, kernel32, msvcrt, user32, gdi32, mpr (host advapi32/shell32 proxies):
   `build\cmd.exe --mute -- /c ver` prints `Windows NT Version 4.0`.
3. The accessories on NT 4.0's own user32/gdi32 (+comctl32, shell32, comdlg32): build/nt<app>.exe.
   winmine makes its window and menu; the board does not paint yet (gray client).

## Running (rules)
Every run: PCRECOMP_MUTE=1, HIDDENRUN_DESKTOP=pcrecomp_nt4, PCRECOMP_FILEBOX=<abs work\profile>
(the host refuses to start without it). From Git Bash set MSYS_NO_PATHCONV=1, or `/c` reaches the
guest as `C:/`.

## Lifter notes
- LIFT32_PUSHRET (NT 4.0's compiler runs a __finally as `push cont; <finally>; ret`): only a push
  right after a try-level store (`mov dword ptr [ebp-4], X`; X is -1 or an outer level, ntdll
  0x200057BE) is a continuation. cmd's parser tables push code addresses as arguments.
- tools/fetch_nt4.sh rebases the exes unbound (no relocations: same base).

## Handoff (newest last)
- 2026-11-19: rebased nt4 onto main (clean), fixed the try-level predicate (stage 2 back), relifting
  ntwinmine with fresh catalogs (old ones in work/cat.old). Untracked tools/*.py|sh, Setup.cmd and
  tools/setup.ps1 are verbatim winxp copies, not yet adapted.
