# Run Scene 10 For Testing

Start the project with F5 in Godot.

The expected full chain is:

```text
scene1_timeline -> scene2_timeline -> scene3_timeline -> scene4_timeline -> scene5_timeline -> scene6_timeline -> scene7_timeline -> scene8_timeline -> scene9_timeline -> scene10_timeline
```

Play through Scenes 1 through 10. After Scene 9 ends, Scene 10 should start automatically. After Scene 10 ends, the Output panel should print:

```text
Игра завершена. Финальный каркас пройден.
```

## Variables To Watch

- `scene10_final_choice`
- `heart_resonance`
- `sacrifice_score`
- `spirits_support`
- `door_state`
- `final_outcome`

## Output Checks

Watch the Output panel for:

- missing Dialogic character ids
- missing timeline ids
- condition or choice parsing errors
- missing resource errors

Scene 10 currently does not use `[background ...]` commands for planned art, because those files are not present yet. The timeline uses TODO comments instead. Add background commands only after the matching files exist in `assets/art/backgrounds/scene10`.
