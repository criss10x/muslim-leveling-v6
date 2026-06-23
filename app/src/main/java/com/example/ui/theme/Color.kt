package com.example.ui.theme

import androidx.compose.ui.graphics.Color

// ═══════════════════════════════════════════════════════════════
// ARENA HIKMAH THEME — Esports Arena × Islamic Illumination
// v3 redesign (2026-06-24). Palette pulled from ML championship
// stage lighting + gold-leaf Islamic geometric art.
// ═══════════════════════════════════════════════════════════════

// ─── Core Backgrounds (deep midnight blue, NOT pure black) ───
val DarkBackground = Color(0xFF0A0E1A)       // Midnight Arena
val DarkSurface = Color(0xFF121729)          // Card surface (with blue undertone)
val DarkSurfaceVariant = Color(0xFF1A2040)   // Inner surface / borders
val DarkSurfaceElevated = Color(0xFF1E2647)  // Elevated cards

// ─── Electric Teal (primary energy/XP — ML effect vibe) ───
val IslamicGreen = Color(0xFF14E8C8)         // Electric Teal (kept name for compat)
val IslamicGreenDim = Color(0xFF0FA88F)      // Muted teal
val IslamicGreenGlow = Color(0x5514E8C8)     // Teal glow effect

// ─── Solar Gold (level/achievement — warm gold leaf) ───
val GoldAccent = Color(0xFFFFB627)           // Solar Gold (kept name for compat)
val GoldGlow = Color(0x40FFB627)             // Gold glow
val AmberFlame = Color(0xFFFF8A00)           // Deep amber
val AmberGlow = Color(0x35FF8A00)

// ─── Ritual Ring Colors (Crimson Pulse = low HP bar ML) ───
val RingRed = Color(0xFFFF3D5A)              // Crimson Pulse
val RingRedGlow = Color(0x50FF3D5A)
val RingGreen = Color(0xFF14E8C8)            // Electric teal
val RingGreenGlow = Color(0x5014E8C8)
val RingBlue = Color(0xFF14E8C8)             // Unified to teal (was cyan, too many colors)
val RingBlueGlow = Color(0x5014E8C8)

// ─── Text Colors ───
val TextLight = Color(0xFFE8EDF5)            // Mist (cool white)
val TextMuted = Color(0xFF6B7494)            // Muted slate
val TextGold = Color(0xFFFFB627)

// ─── Accent Colors (reduced palette — discipline) ───
val CyanAccent = Color(0xFF14E8C8)           // Unified to teal (was separate cyan)
val CyanGlow = Color(0x4014E8C8)
val OrangeFlame = Color(0xFFFF8A00)          // Deep amber
val PurpleNeon = Color(0xFF8B5CF6)           // Muted violet (was neon purple)
val PurpleGlow = Color(0x408B5CF6)
val PinkNeon = Color(0xFFFF3D5A)             // Unified to crimson (was pink)
val PinkGlow = Color(0x40FF3D5A)

// ─── XP and Level Colors ───
val XpBarGreen = Color(0xFF14E8C8)
val XpBarTrack = Color(0xFF1A2040)
val LevelUpGold = Color(0xFFFFB627)

// ─── Card Gradient Colors ───
val CardGradientStart = Color(0xFF121729)
val CardGradientEnd = Color(0xFF1A2040)
val CardBorderGlow = Color(0x2214E8C8)

// ═══════════════════════════════════════════════════════════════
// GRADIENT COLOR SETS (for Brush construction)
// ═══════════════════════════════════════════════════════════════

val GradientGreenGold = listOf(IslamicGreen, GoldAccent)
val GradientCyanGreen = listOf(CyanAccent, IslamicGreen)
val GradientPurplePink = listOf(PurpleNeon, PinkNeon)
val GradientGoldAmber = listOf(GoldAccent, AmberFlame)
val GradientBlueCyan = listOf(RingBlue, CyanAccent)
val GradientRedPink = listOf(RingRed, PinkNeon)
val GradientDarkSurface = listOf(DarkSurface, DarkSurfaceElevated)

// ─── Glow alpha helpers ───
fun Color.neonShadow(alpha: Float = 0.35f) = this.copy(alpha = alpha)
