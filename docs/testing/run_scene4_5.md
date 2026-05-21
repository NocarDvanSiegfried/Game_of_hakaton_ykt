# Run Scene 4-5 For Testing

Start the project with F5 in Godot.

The expected chain is:

```text
scene1_timeline -> scene2_timeline -> scene3_timeline -> scene4_timeline -> scene5_timeline -> scene6_timeline -> scene7_timeline -> scene8_timeline -> scene9_timeline
```

Play through Scenes 1, 2, and 3. After Scene 3 ends, Scene 4 should start automatically. After Scene 4 ends, Scene 5 should start automatically. Scene 5 should now continue through Scene 9. After Scene 9 ends, the Output panel should print:

```text
Сцена 9 завершена. Здесь будет переход к Сцене 10.
```

## Variables To Watch

Scene 4:

- `scene4_memory`
- `empathy_score`
- `water_truth`
- `forgiveness_choice`
- `ytyyr_outcome`

Scene 5:

- `scene5_forge_path`
- `forge_rhythm`
- `idea_strength`
- `knife_resonance`
- `timir_outcome`

## Output Checks

Watch the Output panel for:

- missing Dialogic character ids
- missing timeline ids
- condition or choice parsing errors
- missing resource errors

Scene 4 and Scene 5 currently do not use `[background ...]` commands for planned art, because those files are not present yet. The timelines use TODO comments instead. Add background commands only after the matching files exist in `assets/art/backgrounds/scene4` and `assets/art/backgrounds/scene5`.
