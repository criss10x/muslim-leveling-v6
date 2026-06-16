package com.example.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.MuslimLevelingData
import com.example.data.Quest
import com.example.ui.theme.*
import com.example.viewmodel.GameViewModel

@Composable
fun QuestScreen(
    viewModel: GameViewModel,
    state: MuslimLevelingData
) {
    val scrollState = rememberScrollState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .muslimPattern()
            .windowInsetsPadding(WindowInsets.statusBars)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(horizontal = 24.dp)
                .padding(top = 28.dp, bottom = 80.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Header Info
            Text(
                text = "BATTLE QUESTS",
                fontSize = 11.sp,
                fontWeight = FontWeight.ExtraBold,
                color = GoldAccent,
                letterSpacing = 2.5.sp,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Misi Harian 📋",
                fontSize = 22.sp,
                fontWeight = FontWeight.Black,
                color = TextLight,
                textAlign = TextAlign.Center
            )
            Text(
                text = "Selesaikan misi-misi di bawah buat ngumpulin XP hari ini!",
                fontSize = 12.sp,
                color = TextMuted,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 6.dp, bottom = 24.dp)
            )

            // Dzikir Clicker Companion Widget (If that quest is active)
            val zikirQuestActive = state.quests.list.any { it.id == "quest_zikir_after_prayer" }
            if (zikirQuestActive) {
                InteractiveZikirWidget(state, viewModel)
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Doa Quick Checker Widget (If that quest is active)
            val doaQuestActive = state.quests.list.any { it.id == "quest_doa_solat" }
            if (doaQuestActive) {
                val doaQuest = state.quests.list.find { it.id == "quest_doa_solat" }
                if (doaQuest != null && !doaQuest.completed) {
                    InteractiveDoaWidget(viewModel)
                    Spacer(modifier = Modifier.height(16.dp))
                }
            }

            // Quest List Header Label
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "TARGET HARI INI (RESET JAM 24:00)",
                    fontSize = 10.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = GoldAccent,
                    letterSpacing = 1.2.sp
                )
                Box(modifier = Modifier.weight(1f).height(1.dp).background(Color(0xFF1F2937)))
            }

            // Quest Listings
            if (state.quests.list.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color(0xFF111827).copy(alpha = 0.5f), RoundedCornerShape(16.dp))
                        .border(BorderStroke(1.dp, Color(0xFF1F2937)), RoundedCornerShape(16.dp))
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Belum ada quest nih. Masukin kota asal di Pengaturan dulu ya biar quest-nya muncul!",
                        color = TextMuted,
                        fontSize = 13.sp,
                        textAlign = TextAlign.Center
                    )
                }
            } else {
                Column(
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    state.quests.list.forEach { quest ->
                        QuestRowCard(
                            quest = quest,
                            onClaim = { viewModel.claimQuest(quest.id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun QuestRowCard(
    quest: Quest,
    onClaim: () -> Unit
) {
    val isCompleted = quest.completed
    val isClaimed = quest.claimed
    val progressPercent = if (quest.target > 0) {
        (quest.progress.toFloat() / quest.target.toFloat()).coerceIn(0f, 1f)
    } else 0f

    val borderColor = when {
        isClaimed -> DarkSurfaceVariant
        isCompleted -> GoldAccent
        else -> IslamicGreen.copy(alpha = 0.2f)
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("quest_card_${quest.id}"),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isClaimed) DarkSurface.copy(alpha = 0.5f) else DarkSurface
        ),
        border = BorderStroke(1.2.dp, borderColor)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Title + XP badge
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = quest.desc,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = if (isClaimed) TextMuted else TextLight,
                    modifier = Modifier.weight(1f)
                )

                Box(
                    modifier = Modifier
                        .background(IslamicGreen.copy(alpha = 0.15f), RoundedCornerShape(6.dp))
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = "+${quest.xpReward} XP",
                        color = IslamicGreen,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.ExtraBold
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Progress Bar & Claim action
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                // Progress stats
                Column(modifier = Modifier.weight(1f)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Progres",
                            fontSize = 11.sp,
                            color = TextMuted
                        )
                        Text(
                            text = "${quest.progress}/${quest.target}",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = if (isCompleted) GoldAccent else TextLight
                        )
                    }

                    Spacer(modifier = Modifier.height(4.dp))

                    LinearProgressIndicator(
                        progress = { progressPercent },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(6.dp)
                            .clip(CircleShape),
                        color = if (isCompleted) GoldAccent else IslamicGreen,
                        trackColor = DarkSurfaceVariant
                    )
                }

                Spacer(modifier = Modifier.width(16.dp))

                // Action Button
                when {
                    isClaimed -> {
                        Button(
                            onClick = {},
                            enabled = false,
                            colors = ButtonDefaults.buttonColors(
                                disabledContainerColor = DarkSurfaceVariant,
                                disabledContentColor = TextMuted
                            ),
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier.height(32.dp)
                        ) {
                            Text("Diklaim ✓", fontSize = 11.sp)
                        }
                    }
                    isCompleted -> {
                        Button(
                            onClick = onClaim,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = GoldAccent,
                                contentColor = Color.Black
                            ),
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier
                                .height(32.dp)
                                .testTag("claim_btn_${quest.id}")
                        ) {
                            Text("Klaim XP", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                        }
                    }
                    else -> {
                        Button(
                            onClick = {},
                            enabled = false,
                            colors = ButtonDefaults.buttonColors(
                                disabledContainerColor = DarkSurfaceVariant,
                                disabledContentColor = TextMuted
                            ),
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier.height(32.dp)
                        ) {
                            Text("Belum Selesai", fontSize = 11.sp)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun InteractiveZikirWidget(
    state: MuslimLevelingData,
    viewModel: GameViewModel
) {
    val count = if (state.zikirCounter.date == java.time.LocalDate.now().toString()) state.zikirCounter.count else 0

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(1.5.dp, RingBlue.copy(alpha = 0.5f))
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "📿 Tasbih Dzikir",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = RingBlue
                )
                Text(
                    text = "Tap buat nambah dzikir setelah sholat (1x per sholat)",
                    fontSize = 11.sp,
                    color = TextMuted,
                    lineHeight = 15.sp,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Big tap counter
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(RingBlue.copy(alpha = 0.15f))
                        .border(BorderStroke(1.dp, RingBlue), RoundedCornerShape(10.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "$count/3",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Black,
                        color = TextLight
                    )
                }

                Button(
                    onClick = { viewModel.incrementZikirQuestCounter() },
                    enabled = count < 3,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = RingBlue,
                        contentColor = Color.Black
                    ),
                    shape = CircleShape,
                    contentPadding = PaddingValues(0.dp),
                    modifier = Modifier.size(36.dp)
                ) {
                    Text("+", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color.Black)
                }
            }
        }
    }
}

@Composable
fun InteractiveDoaWidget(
    viewModel: GameViewModel
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        border = BorderStroke(1.5.dp, CyanAccent.copy(alpha = 0.5f))
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "🙏 Doa Setelah Sholat",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = CyanAccent
                )
                Text(
                    text = "Udah berdoa setelah sholat belum? Tap Selesai buat klaim quest!",
                    fontSize = 11.sp,
                    color = TextMuted,
                    lineHeight = 15.sp,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Button(
                onClick = { viewModel.triggerManualDoaQuest() },
                colors = ButtonDefaults.buttonColors(
                    containerColor = CyanAccent,
                    contentColor = Color.Black
                ),
                shape = RoundedCornerShape(10.dp),
                modifier = Modifier.height(36.dp)
            ) {
                Text("Selesai", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            }
        }
    }
}
