"""bo1_snd_to_wav.py - decode Black Ops 1 PC sound files to plain PCM WAV.

BO1 ships its audio (raw\\sound\\**\\*.wav, and sound/ inside main\\*.iwd) as a
`snd_asset` header plus codec data, not RIFF. Layout from DTZxPorter's
BassDrop (H:\\Plutonium\\tools\\BassDrop-Enhanced\\src\\BaseDrop\\Converter.cs,
struct snd_asset), confirmed on BO1's AK-47 folder:

    u32 version (1), frame_count, frame_rate, channel_count, header_size (0x830),
        block_size, buffer_size, format, channel_flags, flags,
        seek_table_count, seek_ptr, data_size, data_ptr
    format: 0 PCM16, 1 PCM24, 2 PCM32, 3 IEEE float, 4 XMA, 5 MP3,
            6 MS-ADPCM, 7 xWMA

Audio starts at header_size. xWMA (7) is wrapped in a RIFF/XWMA header with
a dpds seek chunk built from BO1's own seek table; MS-ADPCM (6) in a
standard WAVE header with the 7 standard coefficients and 262-byte-per-channel blocks,
as BassDrop writes them. PCM formats are wrapped directly. ffmpeg
then writes 16-bit PCM WAV at the source rate with a plain 16-byte fmt chunk,
the only layout OAT's T6 bank writer reads correctly.

    python bo1_snd_to_wav.py <file.wav or dir> <out dir>
"""
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

FIELDS = ('version', 'frame_count', 'frame_rate', 'channel_count', 'header_size', 'block_size',
          'buffer_size', 'format', 'channel_flags', 'flags', 'seek_table_count', 'seek_ptr',
          'data_size', 'data_ptr')
ADPCM_COEFFS = (256, 0, 512, -256, 0, 0, 192, 64, 240, 0, 460, -208, 392, -232)


def parse(data):
    h = dict(zip(FIELDS, struct.unpack_from('<14I', data, 0)))
    if h['version'] != 1 or not 0 < h['channel_count'] < 10 or h['header_size'] > len(data):
        raise ValueError(f'not a BO1 snd_asset (version {h["version"]}, channels {h["channel_count"]})')
    start = h['header_size']
    size = min(h['data_size'] or len(data) - start, len(data) - start)
    seek = []
    if h['seek_table_count']:
        # the seek table follows the 0x38-byte header inside the 0x830 block
        seek = list(struct.unpack_from(f'<{h["seek_table_count"]}I', data, 0x38))
    return h, data[start:start + size], seek


def riff(tag, fmt, extra_chunks, payload):
    body = b'fmt ' + struct.pack('<I', len(fmt)) + fmt + extra_chunks
    body += b'data' + struct.pack('<I', len(payload)) + payload
    return b'RIFF' + struct.pack('<I', 4 + len(body)) + tag + body


def wrap(h, payload, seek):
    ch, rate, fmtid = h['channel_count'], h['frame_rate'], h['format']
    if fmtid == 7:   # xWMA
        blocks = max(1, len(seek))
        fmt = struct.pack('<HHIIHHH', 0x161, ch, rate, 12000, max(1, len(payload) // blocks), 16, 0)
        dpds = b''.join(struct.pack('<I', s) for s in seek) or struct.pack('<I', 0)
        return riff(b'XWMA', fmt, b'dpds' + struct.pack('<I', len(dpds)) + dpds, payload)
    if fmtid == 6:   # MS-ADPCM: 262 bytes per channel per block (measured on 4,911
        # files; BassDrop writes block_align = channel_count * 262 too)
        align = 262 * ch
        spb = (align - 7 * ch) * 8 // (4 * ch) + 2
        fmt = struct.pack('<HHIIHHHHH', 2, ch, rate, rate * align // spb, align, 4, 32, spb, 7)
        fmt += struct.pack('<14h', *ADPCM_COEFFS)
        return riff(b'WAVE', fmt, b'', payload)
    if fmtid in (0, 1, 2, 3):
        bits = {0: 16, 1: 24, 2: 32, 3: 32}[fmtid]
        tag = 3 if fmtid == 3 else 1
        fmt = struct.pack('<HHIIHH', tag, ch, rate, rate * ch * bits // 8, ch * bits // 8, bits)
        return riff(b'WAVE', fmt, b'', payload)
    raise ValueError(f'format {fmtid} not handled (4 = XMA, 5 = MP3)')


def convert(src, dst):
    data = src.read_bytes()
    if data[:4] == b'RIFF':
        # 30 of BO1's 8,777 files (creek_1 frogs, mp_jungle rope) are already a
        # standard RIFF WAV, MS-ADPCM inside; ffmpeg reads those directly.
        fmt = data.find(b'fmt ')
        tag, ch, rate = struct.unpack_from('<HHI', data, fmt + 8)
        h = {'format': f'riff 0x{tag:x}', 'frame_rate': rate, 'channel_count': ch, 'frame_count': 0}
        tmp = str(src)
        owned_tmp = False
    else:
        h, payload, seek = parse(data)
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as t:
            t.write(wrap(h, payload, seek))
            tmp = t.name
        owned_tmp = True
    dst.parent.mkdir(parents=True, exist_ok=True)
    # BO1 recorded many voice and foley files at odd rates (47934, 48086 Hz ...).
    # T6 audio is 48 kHz (OAT warns on anything else), and ffmpeg writes an
    # 18-byte WAVE_FORMAT_EXTENSIBLE-style fmt chunk for some odd rates, which
    # OAT's bank writer misreads. Resample to 44.1 or 48 kHz, whichever is
    # nearer, and force the plain 16-byte chunk.
    rate = 44100 if abs(h['frame_rate'] - 44100) < abs(h['frame_rate'] - 48000) else 48000
    r = subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', tmp,
                        '-c:a', 'pcm_s16le', '-ar', str(rate), '-map_metadata', '-1', '-rf64', 'never',
                        '-write_bext', '0', '-fflags', '+bitexact', '-flags:a', '+bitexact', str(dst)],
                       capture_output=True, text=True)
    if owned_tmp:
        Path(tmp).unlink(missing_ok=True)
    if r.returncode != 0 or not dst.is_file():
        raise RuntimeError(f'ffmpeg: {r.stderr.strip()[:300]}')
    return h


def main():
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    files = [src] if src.is_file() else sorted(src.rglob('*.wav'))
    ok = bad = 0
    for f in files:
        rel = Path(f.name) if src.is_file() else f.relative_to(src)
        try:
            h = convert(f, out / rel)
            ok += 1
            print(f'ok   {rel}  fmt {h["format"]}  {h["frame_rate"]} Hz  {h["channel_count"]} ch  {h["frame_count"]} frames')
        except Exception as e:
            bad += 1
            print(f'FAIL {rel}: {e}')
    print(f'{ok} converted, {bad} failed')
    return 1 if bad else 0


if __name__ == '__main__':
    raise SystemExit(main())
