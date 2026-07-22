# Plan: Strava-like Light Color Scheme — Muslim Leveling v6

**Branch:** `feat/light-theme-redesign`  
**Mode:** planning only (no implementation this turn)  
**Scope:** light theme color system + role mapping. Dark theme = out of scope until light ships.  
**App identity:** Muslim daily practice + gamification (XP, quests, streak, rank tiers).

---

## Goal

Light theme that feels like **Strava** — clean athletic UI, one loud action color, neutral surfaces, high card separation, easy-to-read ink — while staying a **Muslim gamification** app (not a Strava clone, not generic mint Material).

Success criteria:
1. Body/label/CTA contrast ≥ WCAG AA (4.5:1 body, 3:1 large/UI).
2. Card vs canvas separation ≥ ~1.4 contrast (eye can parse sections without shadow).
3. One brand accent drives CTA / progress / selected nav (Strava orange energy pattern).
4. Reward (XP/streak) and “live now” (current prayer) stay distinct secondary accents.
5. Tier colors readable on white cards in light mode.
6. Diff stays token-first: change `AppColorsLight` (+ tier light map); avoid per-screen rewrites.

---

## What “Strava-like” means (steal system, not logo)

| Strava pattern | What we copy | What we do NOT copy |
|---|---|---|
| Near-white / cool-grey canvas | Neutral recessed bg | Mint-green monochrome canvas |
| Pure white cards | High separation, flat | Soft emerald-tinted cards |
| Near-black ink | `#1A1A1A` / grey labels | Green-black ink only |
| **One** brand accent for action | CTA, progress, selected tab | 3 competing neon accents |
| Sparse data accents | Chart/state colors only | Gold/cyan everywhere as decoration |
| Flat elevation (no soft card shadow) | Surface ramp only | Glow / glass (already killed) |
| Orange brand | Optional — see open Q | Forced orange if brand stays emerald |

Strava’s power is **restraint**: 90% neutral, 10% brand heat. Current light theme is 90% cool emerald mint — opposite problem.

---

## Current → target mapping

### Current light (problem)

| Role | Now | Issue |
|---|---|---|
| Canvas | `#DDE4E0` mint grey | Clinical, low card Δ (1.22) |
| Card | `#F5FAF7` cool white-green | Not “paper white” |
| Ink | `#0E1A15` green-black | OK contrast, green cast |
| Primary | `#006C50` emerald | AA OK; competes with mint surfaces |
| Secondary | gold ink `#7E5E00` | OK; role muddled with Fixed tokens |
| Tertiary | cyan `#11697A` | OK |
| Tier colors | neon (dark-native) | FAIL on white (Master 2.4, Legend white 1.1) |

### Target light (Strava system + Muslim roles)

| Role | Strava analogue | Muslim Leveling use | Proposed light value |
|---|---|---|---|
| Canvas | Feed grey | Scaffold / between cards | `#E8EAED` cool neutral (or `#E9ECEF`) |
| Card / raised | White | FlatCard, panels, nav bar | `#FFFFFF` |
| Top elevated | White+ | Snackbar, sheets | `#FFFFFF` |
| Inset track | Subtle grey | Progress track, chips, segmented | `#E5E7EB` |
| Inset deeper | — | Progress bar empty | `#D1D5DB` |
| Ink primary | Near black | Titles, body | `#1A1A1A` |
| Ink secondary | Mid grey | Labels, meta, HudHeader | `#5C6370` |
| Outline | Hairline | Dividers | `#C5CAD3` |
| Outline strong | UI chrome | Borders needing 3:1 | `#8B929E` |
| **Primary (action)** | Strava orange *or* keep emerald | CTA, claim, selected nav, XP bar fill, prayer done | **Decision required** — see Open Q |
| Primary container | Soft brand tint | Soft selected bg, tint chips | brand @ ~12–18% mix / fixed soft fill |
| **Reward (secondary)** | PR / kudos gold moments | Streak fire, XP pill accent, achievements gold | ink `#9A6700` · fill `#F5D76E` |
| **Live (tertiary)** | Map/route blue | Current prayer, “aktif sekarang”, live HUD | ink `#0B6E99` · fill soft `#D7F0FA` |
| Error | Red | Fail / destructive | keep `#BA1A1A` |
| onPrimary | White | Text on solid CTA | `#FFFFFF` |

### Semantic role rules (lock these)

```
INK (text/icon on light surface):
  onSurface | onSurfaceVariant | primary | goldInk | cyanInk | onPrimary | error

FILL only (never body text):
  primaryFixed | primaryContainer | secondaryContainer | secondaryFixedDim |
  tertiaryFixed | tertiaryContainer | goldFill

INSET surfaces:
  no gold/cyan body text — use onSurface / onSurfaceVariant
```

Aliases already exist: `AppColors.goldInk`, `goldFill`, `cyanInk` — keep; retarget values only.

---

## Primary hue decision (must pick before code)

| Option | Primary | Feel | Risk |
|---|---|---|---|
| **A. Emerald keep** (recommended default) | `#0B6B4F` or keep `#006C50` | Still Muslim/green brand; Strava *structure* only | Less “Strava-looking” at first glance |
| **B. Strava orange energy** | `#E34C00` / `#FC4C02` darkened for AA | Instant athletic energy | Orange ≠ Islamic brand; gold reward collides |
| **C. Hybrid** | Orange CTA + emerald “done/success” | Most Strava-like + keep green for complete | Two action hues — need discipline |

**Plan default if user says “gas” without pick: Option A** (structure Strava, brand emerald).  
If user wants “beneran kayak Strava”: Option B or C.

Contrast check target for primary on white card: ≥ 4.5.  
`#FC4C02` on white ≈ 3.4 → too light for small text; use darker action orange `#C2410C` / `#B33A00` for ink+button if Option B/C.

---

## Dark theme

**Do not touch** in this plan. Dark already has gaming identity (neon emerald/cyan/gold).  
Light becomes the “Strava athletic journal”; dark stays “RPG night mode.”  
Optional later: dark orange accent — YAGNI.

---

## Approach (token-first, ponytail)

1. Rewrite `AppColorsLight` constants only (surfaces + ink + accents).
2. Sync `AppTheme.light()` ColorScheme (already maps from `AppColorsLight` — auto if fields reused).
3. Add light-safe **tier ink map** in `tier_avatar.dart` (dark keeps neon).
4. Grep for bright-token-as-text regressions; fix only fail paths.
5. No new design system package. No shadow reintroduction. No cream/parchment fork.

**Files (expected):**
- `lib/theme/app_theme.dart` — `AppColorsLight` values + comments
- `lib/widgets/tier_avatar.dart` — `getTierVisualConfig` light ink OR `tierInkForLight(config)`
- Maybe 0–3 call sites if something hardcodes mint assumptions
- **Not** mass-edit 313 AppColors references (roles stay; values change)

---

## Proposed token table (Option A default)

Concrete values implementer pastes into `AppColorsLight`:

```dart
// ── Surfaces (Strava-like neutral ramp) ──
static const background = Color(0xFFE8EAED);              // recessed canvas
static const surfaceDim = Color(0xFFE8EAED);
static const surface = Color(0xFFE8EAED);
static const surfaceBright = Color(0xFFE8EAED);
static const surfaceContainerLowest = Color(0xFFFFFFFF); // top elevated
static const surfaceContainerLow = Color(0xFFFFFFFF);    // cards
static const surfaceContainer = Color(0xFFFFFFFF);       // panels
static const surfaceContainerHigh = Color(0xFFE5E7EB);   // inset chips/tracks
static const surfaceContainerHighest = Color(0xFFD1D5DB);// progress empty
static const surfaceVariant = Color(0xFFE5E7EB);

// ── Ink ──
static const onSurface = Color(0xFF1A1A1A);        // body
static const onSurfaceVariant = Color(0xFF5C6370); // labels
static const onBackground = Color(0xFF1A1A1A);
static const outline = Color(0xFF8B929E);          // UI chrome ≥3:1 on white
static const outlineVariant = Color(0xFFC5CAD3);   // hairlines only

// ── Primary (emerald action — Option A) ──
static const primary = Color(0xFF006C50);          // keep; AA on white ~6.1
static const primaryFixed = Color(0xFF2BBF8E);     // chart/fill only
static const primaryFixedDim = Color(0xFF0FAE7A);
static const primaryContainer = Color(0xFFD1F5E8); // soft tint bg
static const onPrimary = Color(0xFFFFFFFF);
static const onPrimaryFixed = Color(0xFF002116);
static const onPrimaryFixedVariant = Color(0xFF00513B);
static const onPrimaryContainer = Color(0xFF003828);
static const surfaceTint = Color(0xFF006C50);
static const inversePrimary = Color(0xFF42E5B1);

// ── Secondary / reward (gold) ──
static const secondary = Color(0xFF9A6700);
static const secondaryContainer = Color(0xFFF5D76E);
static const secondaryFixed = Color(0xFF9A6700);   // goldInk — AA
static const secondaryFixedDim = Color(0xFFE8B923);// goldFill
static const onSecondary = Color(0xFFFFFFFF);
static const onSecondaryContainer = Color(0xFF2A1F00);
static const onSecondaryFixed = Color(0xFF2A1F00);
static const onSecondaryFixedVariant = Color(0xFF5C4300);

// ── Tertiary / live (blue-cyan, Strava-map energy) ──
static const tertiary = Color(0xFF0B6E99);         // cyanInk
static const tertiaryContainer = Color(0xFFD7F0FA);
static const tertiaryFixed = Color(0xFF7DD3F0);    // fill only
static const tertiaryFixedDim = Color(0xFF2BA3D4);
static const onTertiary = Color(0xFFFFFFFF);
static const onTertiaryContainer = Color(0xFF00344A);
static const onTertiaryFixed = Color(0xFF002022);
static const onTertiaryFixedVariant = Color(0xFF004F54);

// error: unchanged
```

**Option B swap (if chosen):**  
`primary = Color(0xFFB33A00)`, `primaryContainer = Color(0xFFFFE0D1)`, keep emerald as success-only via new alias later — only if requested.

### Tier light ink map

In `getTierVisualConfig` or thin wrapper:

```dart
// ponytail: light ink only; dark keeps neon constants
Color tierInk(Color darkNeon) => isLightTheme ? _lightInk[darkNeon] ?? darken(darkNeon) : darkNeon;

// proposed fixed map:
Warrior      #5B21B6
Elite        #1D4ED8
Master       #0F766E
Grandmaster  #B45309
Epic         #B91C1C
Legend       #1A1A1A  // never white on light
Mythic*      #B91C1C / #B45309 pair
```

Border in light uses `tierInk.withValues(alpha: 0.55)`.  
Title already uses `onSurface` in light — keep.

---

## Step-by-step tasks (bite-sized)

### Task 1 — Confirm primary option (user gate)
- [ ] User picks A / B / C
- Default A if “gas / lanjutkan”
- **Verify:** one-line decision recorded in commit message

### Task 2 — Rewrite `AppColorsLight` surfaces + ink
- File: `lib/theme/app_theme.dart`
- Replace surface + onSurface/outline block with table above
- Update M3 inversion comment (High/Highest still insets, now neutral greys)
- **Verify:**
  ```bash
  # contrast script (reuse prior python) — onSurface@card ≥ 12, card@canvas ≥ 1.35
  ```

### Task 3 — Rewrite accent tokens (primary/secondary/tertiary)
- Same file; keep getter names; retarget hex only
- Soften `primaryContainer` to pastel (not neon mint `#8AF8D3`)
- Gold ink `#9A6700`, live `#0B6E99`
- **Verify:** goldInk@card ≥ 4.5, cyan@card ≥ 4.5, primary@card ≥ 4.5

### Task 4 — Tier light ink
- File: `lib/widgets/tier_avatar.dart`
- Smallest path: function `Color resolveTierPrimary(TierVisualConfig c)` used by light call sites **or** branch inside config factory if colors are only read via getters
- Prefer: add optional light fields OR darken at use in hero border only if 1–2 call sites
- **ponytail:** if only hero border + avatar ring need it, fix those 2 sites; full map if medals also break
- **Verify:** Master/Grandmaster/Legend border visible on white screenshot or contrast ≥ 3:1 UI

### Task 5 — Grep bright-as-text fail paths
```bash
rg -n "primaryFixed|secondaryFixedDim|tertiaryFixed|primaryContainer" lib/screens lib/widgets
```
- Fix only light-visible **text/icon** uses (ShaderMask already gated in jadwal/hero)
- Leave fill/gradient ends that are decorative if not text
- **Verify:** no white/yellow/mint text on white card

### Task 6 — Nav + snackbar smoke (already partially fixed)
- Confirm nav uses `surfaceContainerLow` white + primary selected (no glow light) — already done
- Snackbar onSurface on white elevated — already done
- **Verify:** visual toggle light/dark once

### Task 7 — Analyze + commit
```bash
flutter analyze lib/theme/app_theme.dart lib/widgets/tier_avatar.dart
git add lib/theme/app_theme.dart lib/widgets/tier_avatar.dart [any fixes]
git commit -m "feat(theme): Strava-like light neutrals + AA accents (Option A emerald)"
```

### Task 8 — Optional APK ship
- Only if user asks
- tmpfiles.org delivery per user pref

---

## Out of scope (YAGNI)

- Cream/parchment palette
- Dark theme recolor
- Full ColorScheme migration off global `AppColors`
- Extract home_tab widgets
- New fonts
- Reintroducing card shadows “to look elevated” (Strava is flat; separation = white on grey)
- Per-screen decorative recolors

---

## Validation checklist

- [ ] `onSurface` on card ≥ 12:1
- [ ] `onSurfaceVariant` on card ≥ 4.5:1
- [ ] `primary` on card ≥ 4.5:1; white on primary ≥ 4.5:1
- [ ] `goldInk` / `cyanInk` on card ≥ 4.5:1
- [ ] Card vs canvas contrast ≥ 1.35
- [ ] Tier Master/Grandmaster/Legend UI chrome ≥ 3:1 on card
- [ ] No Fixed/Container as body text in light
- [ ] Home / Jadwal / Profil / Nav look intentional in light (manual)
- [ ] Dark theme unchanged smoke

Contrast helper (leave as one-off script or run inline python as before).

---

## Risks & tradeoffs

| Risk | Mitigation |
|---|---|
| Pure white cards feel “empty” vs mint | Deeper canvas `#E8EAED`; keep HudHeader hairlines |
| Emerald on white still “not Strava” | Structure is Strava; Option B if user wants orange heat |
| Gold + orange collision (Option B/C) | Reward gold darker; CTA orange redder; never both as fill on same chip |
| Hardcoded tier neon in many files | Centralize resolve helper; don’t hunt every hex |
| `primaryContainer` soft pastel breaks dark-assumptions using alpha | Grep alpha usages; soft fill is safer than neon mint |
| Live theme switch stale colors | Already have ListenableBuilder shell — retest once |

---

## Open questions

1. **Primary hue:** A emerald (default) / B orange / C hybrid?
2. Pure `#FFFFFF` cards vs off-white `#FAFBFC`? (default pure white = more Strava)
3. Apply same neutral canvas to **splash/welcome** light path or leave immersive dark moments? (default: leave celebration screens dark)

---

## Execution order when approved

```
Task 1 (pick) → 2 surfaces → 3 accents → 4 tiers → 5 grep fixes → 6 smoke → 7 commit
```

Estimate: ~30–45 min coding once Option locked.  
Largest risk is Task 4 (tier) if medals hardcode neon widely — then expand map centrally.

---

## One-line summary

**Make light mode a Strava feed: grey canvas, white cards, black ink, one action color, gold=reward, blue=live; fix tier neon for AA. Dark untouched. Token-first.**
