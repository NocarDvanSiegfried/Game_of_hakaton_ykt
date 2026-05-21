# Run Scene 6-7 For Testing

Start the project with F5 in Godot.

The expected chain is:

```text
scene1_timeline -> scene2_timeline -> scene3_timeline -> scene4_timeline -> scene5_timeline -> scene6_timeline -> scene7_timeline -> scene8_timeline -> scene9_timeline
```

Play through Scenes 1, 2, 3, 4, and 5. After Scene 5 ends, Scene 6 should start automatically. After Scene 6 ends, Scene 7 should start automatically. Scene 7 should now continue into Scene 8, then Scene 9. After Scene 9 ends, the Output panel should print:

```text
Сцена 9 завершена. Здесь будет переход к Сцене 10.
```

## Variables To Watch

Scene 6:

- `scene6_verdict`
- `guilt_score`
- `mercy_score`
- `truth_seen`
- `khara_outcome`

Scene 7:

- `scene7_cut_choice`
- `pain_released`
- `self_acceptance`
- `memory_weight`
- `butcher_outcome`

## Output Checks

Watch the Output panel for:

- missing Dialogic character ids
- missing timeline ids
- condition or choice parsing errors
- missing resource errors

Scene 6 and Scene 7 currently do not use `[background ...]` commands for planned art, because those files are not present yet. The timelines use TODO comments instead. Add background commands only after the matching files exist in `assets/art/backgrounds/scene6` and `assets/art/backgrounds/scene7`.

Scene 7 must stay symbolic: no graphic violence, no blood, and no body horror. The ritual is about soul, pain, guilt, memory, and self-acceptance.
