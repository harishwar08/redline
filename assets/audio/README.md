# Audio — engine & cue assets

`AudioService` (`lib/shared/services/audio_service.dart`) plays these cues. Until
the files exist, every cue degrades silently (no crash).

## Expected files

| File | Cue |
|------|-----|
| `engine_start.mp3` | Focus lap starts (engine rev) |
| `lap_complete.mp3` | Focus lap finishes (downshift / chime) |
| `pit_in.mp3` | Break starts |
| `pit_out.mp3` | Break finishes |

## To enable

1. Drop the four `.mp3` files here.
2. Uncomment the `assets:` block in `pubspec.yaml`.

Engine Sound can be toggled per-user in the Tuning Bay.
