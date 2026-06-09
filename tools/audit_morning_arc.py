"""Audit morning arc voice coverage in scene1_timeline.dtl."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DTL = ROOT / "dialogic/timelines/scene1_timeline.dtl"
VOICE_DIR = ROOT / "assets/audio/scene_01/voice"
VOICE_CHANNELS = {
    "narrator_voice",
    "ebe_voice",
    "aisen_voice",
    "kunney_voice",
    "tongus_voice",
}


def parse_audio_line(stripped: str, line_no: int) -> dict:
    rest = stripped[6:].strip()
    channel = ""
    path = ""
    if rest.startswith('"'):
        path = rest.split('"')[1]
        channel = "SFX"
    elif rest.startswith("-") or (rest and not rest.startswith('"')):
        parts = rest.split(None, 1)
        channel = parts[0]
        path = "-"
        if '"' in rest:
            path = rest.split('"')[1]
    return {"line": line_no, "channel": channel, "path": path, "raw": stripped}


def main() -> None:
    lines = DTL.read_text(encoding="utf-8").splitlines()
    start = next(i for i, l in enumerate(lines) if "label scene1_part2_morning" in l)
    end = next(i for i, l in enumerate(lines) if i > start and "ЧАСТЬ 3:" in l)

    pending: list[dict] = []
    entries: list[dict] = []
    for line_no in range(start + 1, end):
        stripped = lines[line_no].strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("audio "):
            pending.append(parse_audio_line(stripped, line_no + 1))
            continue
        speaker_match = re.match(
            r"^(narrator|ebe|aisen|kunney|tongus|bargyy):\s*(.*)$", stripped, re.I
        )
        if speaker_match:
            speaker = speaker_match.group(1).lower()
            text = speaker_match.group(2).strip()
            voice_cmds = [
                c for c in pending if c["channel"] in VOICE_CHANNELS and c["path"] not in ("", "-")
            ]
            sfx_cmds = [
                c
                for c in pending
                if c["channel"] not in VOICE_CHANNELS and c["path"] not in ("", "-")
            ]
            entries.append(
                {
                    "line": line_no + 1,
                    "speaker": speaker,
                    "text": text,
                    "voice": voice_cmds,
                    "sfx": sfx_cmds,
                }
            )
            pending.clear()

    # candidate files by keyword
    voice_files = sorted(p.name for p in VOICE_DIR.glob("*.mp3"))
    morning_files = [f for f in voice_files if "morning" in f or "wake" in f]

    print("=== MORNING REPLIES ===")
    for e in entries:
        vc = e["voice"]
        sfx = [s["path"].split("/")[-1] for s in e["sfx"]]
        vpaths = [v["path"].split("/")[-1] for v in vc]
        vstr = ", ".join(vpaths) if vpaths else "NONE"
        print(
            f"L{e['line']:3d} {e['speaker']:8s} voice={vstr:45s} sfx={sfx} | {e['text'][:70]}"
        )

    print("\n=== MORNING-RELATED VOICE FILES ON DISK ===")
    for f in sorted(set(morning_files + [x for x in voice_files if x.startswith("aisen_voice_0")])):
        print(f)

    print("\n=== JSON ===")
    print(json.dumps(entries, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
