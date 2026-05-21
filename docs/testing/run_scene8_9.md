# Run Scene 8-9 For Testing

Start the project with F5 in Godot.

The expected chain is:

```text
scene1_timeline -> scene2_timeline -> scene3_timeline -> scene4_timeline -> scene5_timeline -> scene6_timeline -> scene7_timeline -> scene8_timeline -> scene9_timeline
```

Play through Scenes 1, 2, 3, 4, 5, 6, and 7. After Scene 7 ends, Scene 8 should start automatically. After Scene 8 ends, Scene 9 should start automatically. After Scene 9 ends, the Output panel should print:

```text
Сцена 9 завершена. Здесь будет переход к Сцене 10.
```

## Variables To Watch

Scene 8:

- `scene8_meaning_choice`
- `chaos_acceptance`
- `mirror_truth`
- `false_life_released`
- `oibon_outcome`

Scene 9:

- `scene9_ancestor_choice`
- `ancestral_guilt`
- `forgiveness_strength`
- `father_truth`
- `uguyar_outcome`

## Output Checks

Watch the Output panel for:

- missing Dialogic character ids
- missing timeline ids
- condition or choice parsing errors
- missing resource errors

Scene 8 and Scene 9 currently do not use `[background ...]` commands for planned art, because those files are not present yet. The timelines use TODO comments instead. Add background commands only after the matching files exist in `assets/art/backgrounds/scene8` and `assets/art/backgrounds/scene9`.
