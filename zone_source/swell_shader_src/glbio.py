"""Minimal glTF-binary reader/writer for OAT model_export GLBs."""
import json, struct


def load(path):
    data = open(path, 'rb').read()
    magic, _ver, length = struct.unpack_from('<III', data, 0)
    assert magic == 0x46546C67, path
    off = 12
    js = binary = None
    while off < length:
        clen, ctype = struct.unpack_from('<II', data, off)
        chunk = data[off + 8:off + 8 + clen]
        off += 8 + clen
        if ctype == 0x4E4F534A:
            js = json.loads(chunk.decode('utf-8'))
        elif ctype == 0x004E4942:
            binary = bytearray(chunk)
    return js, binary


def save(path, js, binary):
    jb = json.dumps(js, separators=(',', ':')).encode('utf-8')
    jb += b' ' * ((4 - len(jb) % 4) % 4)
    bb = bytes(binary) + b'\x00' * ((4 - len(binary) % 4) % 4)
    with open(path, 'wb') as f:
        f.write(struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(jb) + 8 + len(bb)))
        f.write(struct.pack('<II', len(jb), 0x4E4F534A))
        f.write(jb)
        f.write(struct.pack('<II', len(bb), 0x004E4942))
        f.write(bb)


_FMT = {5126: 'f', 5123: 'H', 5125: 'I', 5121: 'B', 5122: 'h', 5120: 'b'}
_N = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}


def view(js, idx):
    """(base offset, stride, count, struct format) of accessor idx."""
    a = js['accessors'][idx]
    bv = js['bufferViews'][a['bufferView']]
    n = _N[a['type']]
    fmt = '<' + _FMT[a['componentType']] * n
    stride = bv.get('byteStride', struct.calcsize(fmt))
    return bv.get('byteOffset', 0) + a.get('byteOffset', 0), stride, a['count'], fmt


def read(js, binary, idx):
    base, stride, count, fmt = view(js, idx)
    return [struct.unpack_from(fmt, binary, base + i * stride) for i in range(count)]


def write(js, binary, idx, values):
    base, stride, count, fmt = view(js, idx)
    assert len(values) == count
    for i, v in enumerate(values):
        struct.pack_into(fmt, binary, base + i * stride, *v)
