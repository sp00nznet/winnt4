#!/usr/bin/env python3
"""Seed a registry box with a key of NT 4.0's own setup hive (the CD's SOFTWARE._).

    py -3 tools/hive.py BOX HIVE KEY DEST   (e.g. nt4\\explorer work/sys/software Classes HKLM\\SOFTWARE\\Classes)

NT 4.0's CD has no HIVE*.INF: its classes (shell32's CLSIDs, file types) are in the
software hive setup copies. KEY's subtree is written under HKCU\\Software\\pcrecomp\\BOX\\DEST;
with the box answering CLSID keys alone (pcrecomp regbox32.c) the host's never reach the guest.
A plain regf reader: nk/vk cells and lf/lh/li/ri subkey lists, no big-data (db) values.
"""
import struct, sys, winreg

def cells(d):
    base = 0x1000
    u = lambda o, f='<I': struct.unpack_from(f, d, base + o + 4)[0]
    def subkeys(lst):
        sig = d[base + lst + 4:base + lst + 6]
        n = struct.unpack_from('<H', d, base + lst + 6)[0]
        step = 4 if sig in (b'li', b'ri') else 8
        for i in range(n):
            o = struct.unpack_from('<I', d, base + lst + 8 + i * step)[0]
            if sig == b'ri': yield from subkeys(o)
            else: yield o
    def nk(o):
        p = base + o + 4
        assert d[p:p + 2] == b'nk', hex(o)
        nsub, lst = struct.unpack_from('<II', d, p + 0x14)[0], struct.unpack_from('<I', d, p + 0x1C)[0]
        nval, vl = struct.unpack_from('<II', d, p + 0x24)
        fl, nl = struct.unpack_from('<H', d, p + 2)[0], struct.unpack_from('<H', d, p + 0x48)[0]
        raw = d[p + 0x4C:p + 0x4C + nl]
        name = raw.decode('latin-1') if fl & 0x20 else raw.decode('utf-16-le')
        vals = []
        for i in range(nval):
            v = base + struct.unpack_from('<I', d, base + vl + 4 + i * 4)[0] + 4
            vnl, sz, off, typ, vfl = struct.unpack_from('<HIIIH', d, v + 2)
            vraw = d[v + 0x14:v + 0x14 + vnl]
            vn = vraw.decode('latin-1') if vfl & 1 else vraw.decode('utf-16-le')
            data = struct.pack('<I', off)[:sz & 0x7FFFFFFF] if sz & 0x80000000 else d[base + off + 4:base + off + 4 + sz]
            vals.append((vn, typ, data))
        kids = list(subkeys(lst)) if nsub else []
        return name, vals, kids
    root = struct.unpack_from('<I', d, 0x24)[0]
    return nk, root

def conv(typ, data):
    if typ in (1, 2): return data.decode('utf-16-le', 'replace').split('\0')[0]
    if typ == 4: return struct.unpack('<I', data[:4].ljust(4, b'\0'))[0]
    if typ == 7: return [x for x in data.decode('utf-16-le', 'replace').split('\0') if x]
    return bytes(data)

def main():
    box, hive, key, dest = sys.argv[1:5]
    d = open(hive, 'rb').read()
    assert d[:4] == b'regf'
    nk, o = cells(d)
    for part in key.split('\\'):
        o = next(k for k in nk(o)[2] if nk(k)[0].lower() == part.lower())
    n = 0
    def walk(o, path):
        nonlocal n
        name, vals, kids = nk(o)
        with winreg.CreateKey(winreg.HKEY_CURRENT_USER, path) as k:
            for vn, typ, data in vals:
                winreg.SetValueEx(k, vn, 0, typ, conv(typ, data)); n += 1
        for c in kids: walk(c, path + '\\' + nk(c)[0])
    walk(o, r'Software\pcrecomp\%s\%s' % (box, dest))
    print('%s: %d values from %s\\%s' % (box, n, hive, key))

if __name__ == '__main__':
    main()
