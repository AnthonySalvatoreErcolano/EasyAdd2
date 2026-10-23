# EasyAdd 2.0.0 — App Store Connect listing

Copy each field into App Store Connect → EasyAdd → iOS App → 2.0.0.

## Build

- Version: **2.0.0**, build **10**
- File: `build/ios/ipa/EasyAdd.ipa` (rebuild with `flutter build ipa --release`)
- Export compliance: answered in the app (`ITSAppUsesNonExemptEncryption = NO`), so no question on upload.

## Name and subtitle

| Field | Limit | Text |
| --- | --- | --- |
| Name | 30 | `EasyAdd` |
| Subtitle | 30 | `Feet, inches & fractions` |

## Promotional text (170)

```
Add feet, inches and fractions the way your tape reads them. Exact answers to 1/16", plus concrete, stairs and board-foot tools.
```

## Description (4000)

```
EasyAdd is a tape measure calculator. Type measurements the way your tape reads them, like 1' 2 1/2", and get answers back the same way: 1' 6 3/8".

BUILT FOR THE JOB SITE
• Feet, inches and fraction keys: tap 1/8 through 7/8, or switch to sixteenths
• Exact math with no rounding drift. Answers round to the nearest 1/16" (or 1/2" to 1/64", your choice) and show ≈ when rounded
• Add, subtract, multiply and divide, with a live answer as you type
• Length × length gives square feet; three lengths give cubic feet or yards
• Mix in metric: type mm, cm or m and get feet and inches back
• Tap a result to switch between feet & inches, inches, decimal feet, mm, cm and m
• Backspace one key at a time, or bring back the last calculation to fix a typo
• Memory keys and a saved history of your last 50 calculations

TOOLS
• Concrete: cubic yards and 60 lb / 80 lb bag counts for slabs, footings and round columns, with a waste allowance
• Stairs: number of risers, riser height, treads, total run, stringer diagonal and angle, with warnings when a riser or tread is outside residential code limits
• Board feet: lumber volume and total cost, with nominal or actual sizes
• Convert: see any length in all six formats at once

EASY TO READ
• Big, high-contrast tape-yellow display with real stacked fractions
• Works with VoiceOver (results are read as "3 feet 4 and five eighths inches") and larger text sizes
• Works on iPhone and iPad

No accounts, no ads, no tracking. Your history stays on your device.
```

## Keywords (100)

```
tape measure,construction,carpenter,feet,inches,fraction,concrete,stair,board foot,lumber,contractor
```

(Exactly 100 characters. "calculator" and the app name are already indexed from the name and subtitle, so they are left out.)

## What's New in This Version (4000)

```
EasyAdd 2.0 is rebuilt from the ground up.

• All-new tape-measure display with real stacked fractions
• Exact feet, inches and fraction math, rounded to the 1/16" (adjustable)
• Live answers as you type, memory keys and calculation history
• Area and volume: square feet, cubic feet and cubic yards
• Metric entry and conversion
• New tools: Concrete, Stairs, Board Feet and Convert
• VoiceOver and larger text support
• iPad support
```

## URLs

| Field | Value |
| --- | --- |
| Privacy Policy URL (required) | `https://github.com/AnthonySalvatoreErcolano/EasyAdd2/blob/main/PRIVACY.md` (or keep the one already on the listing) |
| Support URL (required) | `https://github.com/AnthonySalvatoreErcolano/EasyAdd2/issues` (or keep the one already on the listing) |

## App Privacy

Answer **"Data Not Collected"**. The app has no analytics, ads, accounts or network calls; settings and history are stored only on the device.

## Screenshots

Upload in this order (01 → 06), from `store/screenshots/`:

| Device slot in App Store Connect | Folder | Pixel size |
| --- | --- | --- |
| iPhone 6.9" display | `iphone-6.9/` | 1320 × 2868 |
| iPhone 6.5" display | `iphone-6.5/` | 1242 × 2688 |
| iPad 13" display | `ipad-13/` | 2064 × 2752 |

To regenerate after UI changes: `flutter test --tags golden --update-goldens test/store`.

## Category and age rating

Keep the category and age rating already on the listing. Nothing in 2.0 changes them (no web access, no user content, no ads).
