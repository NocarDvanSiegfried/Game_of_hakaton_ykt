"""Audit Scene 1 dialogue vs audio wiring (read-only)."""

from __future__ import annotations

import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DTL = ROOT / "dialogic/timelines/scene1_timeline.dtl"
VOICE_DIR = ROOT / "assets/audio/scene_01/voice"
SCENE1_AUDIO = ROOT / "assets/audio/scene_01"

VOICE_CHANNELS = {
    "narrator_voice",
    "ebe_voice",
    "aisen_voice",
    "kunney_voice",
    "tongus_voice",
}
SPEAKERS = {"narrator", "ebe", "aisen", "kunney", "tongus", "bargyy"}


def parse_timeline(text: str) -> tuple[list[dict], list[dict]]:
    entries: list[dict] = []
    all_audio: list[dict] = []
    pending: list[dict] = []

    for line_no, raw in enumerate(text.splitlines(), 1):
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue

        if stripped.startswith("audio "):
            cmd = _parse_audio_line(stripped, line_no)
            all_audio.append(cmd)
            pending.append(cmd)
            continue

        speaker_match = re.match(r"^(narrator|ebe|aisen|kunney|tongus|bargyy):\s*(.*)$", stripped, re.I)
        if speaker_match:
            speaker = speaker_match.group(1).lower()
            text_line = speaker_match.group(2).strip()
            voice_cmds = [c for c in pending if c["channel"] in VOICE_CHANNELS]
            sfx_cmds = [
                c
                for c in pending
                if c["channel"] not in VOICE_CHANNELS and c["path"] and c["path"] != "-"
            ]
            stop_cmds = [c for c in pending if c["path"] == "-" or c["path"] == ""]
            entries.append(
                {
                    "line": line_no,
                    "speaker": speaker,
                    "text": text_line,
                    "voice_cmds": voice_cmds,
                    "sfx_before": sfx_cmds,
                    "channel_stops": stop_cmds,
                }
            )
            pending.clear()
            continue

    return entries, all_audio


def _parse_audio_line(stripped: str, line_no: int) -> dict:
    channel = ""
    path = ""
    rest = stripped[6:].strip()
    if rest.startswith('"'):
        path = rest.split('"')[1]
    elif rest.startswith("-") and not rest.startswith('"'):
        parts = rest.split(None, 1)
        channel = parts[0]
        path = "-"
    else:
        parts = rest.split(None, 1)
        channel = parts[0]
        if '"' in rest:
            path = rest.split('"')[1]
        elif channel == "-":
            path = "-"
    return {"line": line_no, "channel": channel, "path": path, "raw": stripped}


def main() -> None:
    text = DTL.read_text(encoding="utf-8")
    entries, all_audio = parse_timeline(text)

    ref_paths = set(re.findall(r'res://assets/audio/scene_01/[^"\s]+', text))
    missing: list[str] = []
    empty: list[str] = []
    for ref in sorted(ref_paths):
        fp = ROOT / ref.replace("res://", "").replace("/", os.sep)
        if not fp.exists():
            missing.append(ref)
        elif fp.stat().st_size == 0:
            empty.append(ref)

    used_voice_names = {Path(p).name for p in ref_paths if "/voice/" in p}
    disk_voice = {p.name for p in VOICE_DIR.glob("*") if p.suffix.lower() in {".mp3", ".wav", ".ogg"}}
    orphan_voice = sorted(disk_voice - used_voice_names)

    with_voice = [e for e in entries if any(v["path"] and v["path"] != "-" for v in e["voice_cmds"])]
    without_voice = [e for e in entries if e not in with_voice]

    # voice files referenced but check case sensitivity on Windows vs export
    case_issues: list[str] = []
    for ref in ref_paths:
        fp = ROOT / ref.replace("res://", "").replace("/", os.sep)
        if fp.exists():
            continue
        parent = fp.parent
        if parent.exists():
            names = {p.name.lower(): p.name for p in parent.iterdir()}
            want = fp.name.lower()
            if want in names and names[want] != fp.name:
                case_issues.append(f"{ref} -> disk has {names[want]}")

    print("=== COVERAGE ===")
    print(f"replies_total={len(entries)}")
    print(f"replies_with_voice_cmd={len(with_voice)}")
    print(f"replies_without_voice_cmd={len(without_voice)}")
    pct = (len(with_voice) / len(entries) * 100) if entries else 0
    print(f"coverage_pct={pct:.1f}")

    print("\n=== MISSING REFS ({}) ===".format(len(missing)))
    for m in missing:
        print(m)

    print("\n=== EMPTY FILES ({}) ===".format(len(empty)))
    for e in empty:
        print(e)

    print("\n=== ORPHAN VOICE FILES ({}) ===".format(len(orphan_voice)))
    for o in orphan_voice:
        print(o)

    print("\n=== CASE ISSUES ({}) ===".format(len(case_issues)))
    for c in case_issues:
        print(c)

    print("\n=== REPLIES WITHOUT VOICE ===")
    for e in without_voice:
        sfx = ", ".join(Path(s["path"]).name for s in e["sfx_before"][:3])
        print(f"L{e['line']:4} {e['speaker']:8} sfx=[{sfx}] | {e['text'][:90]}")

    print("\n=== ALL AUDIO COMMANDS ({}) ===".format(len(all_audio)))
    for a in all_audio:
        print(f"L{a['line']:4} ch={a['channel'] or 'SFX':18} {a['path']}")


if __name__ == "__main__":
    main()
