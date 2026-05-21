# Run Scene 2 For Testing

Scene 1 currently starts from `scripts/main.gd`.

To temporarily test Scene 2:

1. Open `scripts/main.gd`.
2. Find the startup call:

```gdscript
Dialogic.start("scene1_timeline")
```

3. Temporarily replace it with:

```gdscript
Dialogic.start("scene2_timeline")
```

4. Run the project from Godot.
5. After testing, change it back to:

```gdscript
Dialogic.start("scene1_timeline")
```

Do not commit the temporary `scripts/main.gd` change unless the project gets an approved debug scene selector.

Potential safe improvement for later: add a debug-only scene selector or exported timeline name in `scripts/main.gd`, so Scene 1, Scene 2, and Scene 3 can be tested without editing code each time.
