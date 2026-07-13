# Sakīnah — Award-Tier Motion & Polish Design

Date: 2026-07-12
Status: Approved to implement
Design language locked earlier: **Modern Sanctuary** (Space Grotesk + Inter + Amiri, cool off-white, deep green accent)

## Reframed goal

Award-tier by *craft*, not by kineticism. The reference set is Apple Weather, Arc, Linear, Airbnb, Not Boring — apps that are quietly extraordinary. Explicitly not the Awwwards agency-portfolio vocabulary (scroll hijacks, kinetic marquees, cursor physics, glitch effects), which would break the sacred, private, mercy-driven tone of Sakīnah.

The bar is: **every screen has one moment a competitor's app doesn't have, and every micro-interaction is considered.**

## Locked scoping decisions (2026-07-12)

- **Primary target:** iOS + Android. macOS + web + Windows + Linux still work but are secondary; touch-and-haptic-first motion.
- **Transitions:** shared-element Hero flights (wordmark/calligraphy fly between screens), not color-reveals.

## The five signature moves

### 1. One signature moment per screen

Each screen has one crafted, memorable interaction that shows deliberate care.

**Sign-in**
- On mount: `ٱلسَّلَامُ عَلَيْكُمْ` draws in with a per-glyph fade+scale stagger (~40 ms between glyphs, cubic-out spring). The tagline "A private space, for the two of you." fades in 200 ms after the last glyph settles.
- On successful sign-in: the current screen fades and slides up 24 px; the home screen slides in from below with matched fade. Total: 480 ms.

**Pair — invite tab**
- Empty state: heart icon breathes (opacity 0.7 → 1.0 → 0.7 over 3 s), zero motion otherwise.
- Code arrival: 6 characters enter one at a time (30 ms stagger, cubic-out with 8-px y-slide + 0.9 → 1.0 scale). Feels typed by a caring hand.
- Countdown ring: circular progress arc around the code, drawn with `CustomPainter`. Under the last 60 s, arc color transitions from accent → warning (500 ms lerp).
- QR: path-draws itself in on first render using `CustomPainter` — matrix cells fade in on a spiral from centre outward, 400 ms total.

**Pair — join tab**
- 6 individual character slots (not one text field). Each digit lands with a 200-ms scale-in-from-0.7 spring.
- Wrong code: shake ONLY the slot row (horizontal ±8 px, 3 oscillations, 400 ms), not the whole screen.
- Correct code: the row exhales upward (24 px y-slide + fade) and the accepted-couple state morphs into the home hero.

**Home**
- Next-prayer card breathes: 4-second scale pulse (0.998 ↔ 1.002) with matching subtle brightness pulse. Barely visible, but noticed.
- Arabic prayer name crossfades to the next prayer's Arabic name 90 seconds before the current prayer ends. Never a hard swap.
- First mount of the day: greeting reveals in phrases — "Good evening," then "Ridwan." after a 300 ms delay. Never re-plays within the same session.
- Coming-soon tiles enter with a staggered rise (60 ms between tiles, 24 px y-slide + fade), triggered by scroll-into-view.

**OTP**
- 6 digit slots. Each typed digit lands identically to Pair/Join.
- Auto-verify when 6 digits are entered — no explicit "Continue" tap required. Continue button becomes a subtle "or wait to verify" hint that fades out on last digit.

### 2. Shared-element route transitions

Implemented via Flutter's `Hero` + `PageRouteBuilder`.

| From → To | Shared element(s) |
|---|---|
| Splash → Sign-in | The calligraphy سَكِينَة flies to become the Sakīnah wordmark |
| Sign-in → Pair | Sakīnah wordmark stays; content around it morphs |
| Pair → Home | The couple-accent color washes from the accepted-code position into the home hero, then reveals home content |
| Home → any future detail screen | The card being tapped becomes the header of the detail screen |

Cross-fade duration for content beneath heroes: 320 ms with `Curves.easeOutCubic`.

### 3. Skeletons everywhere, no spinners

Every loading state is a shape-preserving skeleton with a subtle shimmer (`_ShimmerBox` primitive). Zero `CircularProgressIndicator` in-app after this pass (splash retains it for its dedicated loading moment).

- `ProfileSkeleton` — the greeting area while `ownProfileProvider` resolves
- `NextPrayerSkeleton` — accent-tinted skeleton matching the next-prayer card exactly
- `TilesSkeleton` — 4 rounded-rect skeletons matching the coming-soon tiles
- Button loading state remains a small progress circle (a spinner IS the right choice inside a button — the exception)

### 4. Odometer counters and tabular numerals

Any number that changes (countdown, sadaqah jar, dhikr counter, prayer count) uses:
- `FontFeature.tabularFigures()` for column-stability
- `AnimatedDigit` widget — digits transition with a vertical slide+fade rather than an instant swap

Applied everywhere numbers change in real time. Deferred until the actual features ship, but the primitive is built now.

### 5. Custom crescent illustration

A single hand-drawn SVG-in-Dart `HijriCrescent` widget, 24 px, rendered via `CustomPainter`. Fills correctly for the current Hijri phase (new moon → full → new again over the month). Lives beside the Hijri date in the home header. Small detail, high impact.

## Anti-list (won't build)

- No scroll-hijack, horizontal-pan, sticky-stack, marquee, or scroll-triggered pinning
- No cursor physics, custom mouse cursors, glitch effects, brutalist type
- No auto-playing sound, no background music
- No gamification: no streak fireworks, no confetti, no celebratory bursts, no badges beyond a soft "Soon" chip
- No aurora / mesh gradient hero backgrounds
- No AI-purple, no oversaturated accents outside of our locked deep-green
- No `Instrument Serif` or `Fraunces` (banned per the design skill)

## Reduced motion policy

`MediaQuery.disableAnimationsOf(context)` (or the platform's `AccessibilityFeatures.disableAnimations`) is checked. When on:
- All entrance staggers collapse to a single 120 ms fade-in
- All spring physics become straight cubic
- Breathing pulses stop entirely
- Route transitions become instant cross-fades

No motion is essential to comprehension — reduced motion is a first-class mode, not a fallback.

## Haptics

Mobile only (`Platform.isIOS || Platform.isAndroid`). No-op on macOS, Windows, Linux, web.

- Sign-in success → `HapticFeedback.mediumImpact()`
- Code generated → `HapticFeedback.selectionClick()`
- Code accepted (paired) → `HapticFeedback.heavyImpact()` followed by `HapticFeedback.mediumImpact()` 100 ms later ("we're paired" feels like two heartbeats)
- Wrong code → `HapticFeedback.mediumImpact()` (matches the shake)
- Tapping any primary button → `HapticFeedback.lightImpact()` (only for primary CTAs, not every button)

## Motion library — `core/motion/`

A tiny shared library so every screen speaks the same motion language.

```
core/motion/
├── curves.dart          # SakMotion.enter / .standard / .breathe / .spring
├── durations.dart       # SakMotion.quick=150, standard=240, gentle=400, hero=480
├── stagger.dart         # Stagger extension for a List<Widget>
├── shimmer_box.dart     # <_ShimmerBox width, height, radius>
├── animated_digit.dart  # Odometer digit
├── hijri_crescent.dart  # Custom-painted crescent
└── motion.dart          # barrel
```

All widgets:
- Honor `MediaQuery.disableAnimationsOf(context)`
- Have `@Debounce`-free implementations (no timers accumulated in dispose)
- Never call `setState` during build (the recent Riverpod bug taught us)

## Component work

### New primitives

- `SakMotion.enter(child, delay:)` — wraps any widget in a fade+y-slide entrance
- `SakStagger` — driver widget that gives its children incremental delays
- `SakShimmerBox({width, height, radius})` — the skeleton primitive
- `SakAnimatedDigit(value)` — odometer digit; used inside a `SakDigitRow`
- `HijriCrescent(hijriDate, size)` — the crescent
- `SakBreathing({child, minScale, maxScale, period})` — infinite scale pulse, honors reduced motion

### Rewrites

- `SakButton` — add `HapticFeedback.lightImpact()` on tap for primary variant on mobile
- `SakScaffold` — expose an optional `heroTag` so the app bar title can Hero across screens
- `SplashScreen` (in router) — replace `CircularProgressIndicator` with a self-drawing calligraphy stroke animation
- `SignInScreen` — glyph-stagger entrance for the salām, keep everything else identical
- `InviteTab` — character-stagger entrance for code, ring painter, QR path-draw
- `JoinTab` — 6 slot widgets replacing the single `TextField`, shake on wrong code
- `HomeScreen` — greeting reveal, breathing prayer card, staggered tiles, HijriCrescent in header
- `OtpScreen` — same 6-slot pattern as JoinTab, auto-submit

## What's NOT touched

- Data layer (auth, pairing, supabase, prayer engine) — no changes
- Schema (already Phase 1-5 complete)
- Router structure (only splash + shared-element hero tags added)
- Content and copy on any screen

## Testing

- Golden tests are out of scope for animated widgets (too flaky)
- Add `test/core/motion/animated_digit_test.dart` — assert digit change increments internal value; no visual assertion
- Existing tests remain green

## Rollout order

1. `core/motion/` — build all primitives
2. Splash + shared-element hero setup
3. Sign-in (biggest first-impression payoff)
4. OTP
5. Pair invite tab
6. Pair join tab
7. Home
8. `flutter analyze` + `flutter test` clean

## Success criteria

- Every screen has a signature moment demonstrable in <5 seconds
- Reduced-motion mode ships a proper degraded experience, not a broken one
- Haptics fire on the four defined events on mobile
- Zero `CircularProgressIndicator` outside `SakButton.loading` and the splash's initial 200 ms
- `flutter analyze` clean, `flutter test` green
- App runs on iOS simulator, macOS, and web without motion-related crashes
