# Windows NT 4.0 Workstation SP6a on pcrecomp: survey and handoff

Sibling of win2000 and winxp. Toolkit branch: pcrecomp `nt4` (worktree G:/recomp/pc/pcrecomp-nt4,
rebased on origin/main 621860a). NT 4.0-specific answers go behind ntguest.h's `nt_guest_nt4()`.

## Stages
1. winmine, notepad, calc on the host's DLLs (build/<app>.exe): run.
2. cmd.exe on NT 4.0's own ntdll, kernel32, msvcrt, user32, gdi32, mpr (host advapi32/shell32 proxies):
   `build\cmd.exe --mute -- /c ver` prints `Windows NT Version 4.0`.
3. The accessories on NT 4.0's own user32/gdi32 (+comctl32, shell32, comdlg32): build/nt<app>.exe.
   tools/interact.py (stage 1 column, 3840x2160@192): winmine start/click/intermediate/menu open/
   menu+Intermediate 0 px, notepad start/typed 0 px. Differ by design or still open:
   - winmine Custom dialog: NT 4.0's user32 gives a dialog without DS_3DLOOK the bold font
     (weight 700), so it is larger than the host's (stage 1). The "custom 20x30" run's typing does
     not reach the edits yet (lifted shot stays 154x240).
   - calc: client area matches stage 1; the window is 4 px smaller (NT 4.0's own client-side
     AdjustWindowRect has no padded border). Calc paints slowly (~8 s for all buttons).

## Running (rules)
Every run: PCRECOMP_MUTE=1, HIDDENRUN_DESKTOP=pcrecomp_nt4, PCRECOMP_FILEBOX=<abs work\profile>
(the host refuses to start without it). From Git Bash set MSYS_NO_PATHCONV=1, or `/c` reaches the
guest as `C:/`.

## NT 4.0 answers in pcrecomp (ntguest.h, all behind nt_guest_nt4)
- WND (nt_wnd): pSelf 0xC, links 0x14..0x20, rcWindow 0x28, rcClient 0x38, lpfnWndProc 0x48, pcls
  0x4C, cbwndExtra 0x50, hrgnUpdate 0x54, ID 0x68, fnid 0x7A, dwUserData 0x80, state 0x9C, ExStyle
  0xA4, style 0xA8, hModule 0xAC, extra bytes 0xB0.
- SERVERINFO (nt_si): cHandleEntries +4, aiSysMet[0x4C] +0x170, argbSystem[0x19] +0x2A0, ahbrSystem
  +0x304, atomSysClass +0x788, font chars +0x7D4.., dmLogPixels +0x754, BitCount +0x75C; others
  go to scratch at +0xF000.
- DC_ATTR (nt_dca): ROP2/BkMode 0x28/0x29, ptlCurrent 0x2C, lBkMode 0x3C, text align 0x48/0x4C,
  font 0x60, map mode 0x138, origins/extents 0x13C.., brush origin 0x170.
- TEB GDI batch at +0x1FC (nt_teb_batch); PolyPatBlt rectangles at +0x18.
- MENU: pSelf 0xC, cItems 0x28, rgItems 0x38, ITEM 0x40 bytes.
- apfnClientW is built on user32's stack: DispatchClientMessage found by scanning for
  `mov [ebp+d], DefDlgProcW` and the register stored at d+0x20 (w32kuser.c find_dcm).
- NtUserCallHwndParam routines 0x3F/0x41/0x43 (Clear state, dialog pointer, Set state); FNIDs
  from 0x29F one lower than 2000's; NtUserfnINSTRING[NULL] pass a LARGE_STRING; NtUserInitBrushes
  fills user32's own brush copy; GetTextFace answers the asked face (NT 4.0 named an alias so).

## Lifter notes
- LIFT32_PUSHRET (NT 4.0's compiler runs a __finally as `push cont; <finally>; ret`): only a push
  right after a try-level store (`mov dword ptr [ebp-4], X`; X is -1 or an outer level, ntdll
  0x200057BE) is a continuation. cmd's parser tables push code addresses as arguments.
- tools/fetch_nt4.sh rebases the exes unbound (no relocations: same base).

## Handoff (newest last)
- 2026-11-19: rebased nt4 onto main (clean), fixed the try-level predicate (stage 2 back), relifting
  ntwinmine with fresh catalogs (old ones in work/cat.old). Untracked tools/*.py|sh, Setup.cmd and
  tools/setup.ps1 are verbatim winxp copies, not yet adapted.
- 2026-11-19 (later): stage 3 on NT 4.0's own user32/gdi32 (pcrecomp nt4 e39db85..ee9f518).
  Next: winmine Custom dialog typing; calc frame size; then explorer (tools/lift_explorer.sh,
  run_explorer.sh, setup.ps1, Setup.cmd and the other untracked tools are still winxp copies to
  adapt: NT 4.0 profile is C:\WINNT\Profiles, no HIVE*.INF on its CD (the `default` hive)),
  README, clean-clone setup test.
- 2026-11-19 (end of session): pcrecomp nt4 at f398827. winmine Custom 20x30 now works
  (NtUserfnOUTSTRING). Explorer (tools/lift_explorer.sh, tools/run_explorer.sh NAME SECS; build
  target ntexplorer) starts on NT 4.0's own set with only advapi32 proxied (the box's
  NetworkProvider order is empty: tools/profile.py), but spins in a text-fitting loop: ~740k
  NtGdiGetTextExtent calls in 20 s and a black 800x600 screen. Next: find the caller (watchdog's
  guest stack; likely the tray/Start button sizing a string) and check NtGdiGetTextExtent's answer
  for NT 4.0 (its SIZE, or a DC_ATTR field the loop reads). After that: README with screenshots,
  Setup.cmd and tools/setup.ps1 (still winxp copies, untracked), and a clean-clone setup test.
  Sibling regression (2026-11-19): win2000 and winxp interact.py on nt4 builds (build-nt4check)
  vs main 621860a (build-mergelu) matched row by row except known-flaky rows (winmine click,
  sol/freecell/packager timing), which re-run equal.
