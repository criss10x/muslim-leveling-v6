package com.example

import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.ui.screens.*
import androidx.compose.ui.graphics.Brush
import com.example.ui.theme.*
import com.example.viewmodel.GameViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Create the notifications channel initially
        NotificationHelper.createNotificationChannel(this)

        setContent {
            MuslimLevelingTheme {
                val gameViewModel: GameViewModel = viewModel()
                val context = LocalContext.current

                val isLoaded by gameViewModel.isLoaded.collectAsStateWithLifecycle()
                val gameState by gameViewModel.gameData.collectAsStateWithLifecycle()

                var showSplash by remember { mutableStateOf(true) }

                // Register Toast events listener
                LaunchedEffect(Unit) {
                    gameViewModel.toastEvent.collect { message ->
                        Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
                    }
                }

                if (showSplash) {
                    SplashScreen(onTimeout = { showSplash = false })
                } else if (!isLoaded) {
                    // Loading central state
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .futuristicBackground(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = IslamicGreen)
                    }
                } else {
                    if (gameState.user.username.isEmpty()) {
                        // Onboarding first launch
                        OnboardingScreen(
                            onComplete = { username, intensityMode, kota ->
                                gameViewModel.startNewGame(username, intensityMode, kota)
                            }
                        )
                    } else {
                        // Game Main Screen with 4 tabs switcher
                        var activeTab by remember { mutableStateOf("home") } // home, jadwal, belajar, profil

                        Scaffold(
                            modifier = Modifier.fillMaxSize(),
                            bottomBar = {
                                CustomGameBottomNavbar(
                                    activeTab = activeTab,
                                    onTabSelected = { activeTab = it }
                                )
                            },
                            contentWindowInsets = WindowInsets.navigationBars
                        ) { innerPadding ->
                            Box(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .padding(innerPadding)
                                    .background(DarkBackground)
                            ) {
                                // Content view switcher with fade transitions
                                AnimatedContent(
                                    targetState = activeTab,
                                    transitionSpec = {
                                        fadeIn() togetherWith fadeOut()
                                    },
                                    label = "TabTransition"
                                ) { selectedTab ->
                                    when (selectedTab) {
                                        "home" -> HomeScreen(
                                            viewModel = gameViewModel,
                                            state = gameState
                                        )
                                        "jadwal" -> JadwalSholatScreen(
                                            viewModel = gameViewModel,
                                            state = gameState
                                        )
                                        "belajar" -> BelajarScreen(
                                            viewModel = gameViewModel,
                                            state = gameState
                                        )
                                        "profil" -> ProfileScreen(
                                            viewModel = gameViewModel,
                                            state = gameState
                                        )
                                    }
                                }
                            }
                        }

                        // Celebrate and rewards reveal dialogs overlays
                        val levelUpEvent by gameViewModel.levelUpAnimationEvent.collectAsStateWithLifecycle()
                        val rewardRevealEvent by gameViewModel.rewardRevealEvent.collectAsStateWithLifecycle()

                        if (levelUpEvent != null) {
                            val lv = levelUpEvent!!
                            LevelUpCelebrationOverlay(
                                unlockedLevel = lv,
                                rankTitle = gameViewModel.getRankTitle(lv),
                                onDismiss = { gameViewModel.levelUpAnimationEvent.value = null }
                            )
                        }

                        if (rewardRevealEvent != null && levelUpEvent == null) {
                            // If level-up exists, complete it first, then show reward reveal sequence
                            RewardRevealOverlay(
                                state = rewardRevealEvent!!,
                                onDismiss = { gameViewModel.rewardRevealEvent.value = null }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun CustomGameBottomNavbar(
    activeTab: String,
    onTabSelected: (String) -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.navigationBars),
        color = DarkSurface,
        tonalElevation = 8.dp
    ) {
        Column {
            // Horizontal border line separating screen from navigation bar
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Color(0xFF1F2937))
            )

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(60.dp)
                    .padding(horizontal = 8.dp),
                horizontalArrangement = Arrangement.SpaceAround,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Tab 1: Home
                BottomTabItem(
                    tag = "home",
                    label = "Home",
                    iconString = "🕌",
                    isActive = activeTab == "home",
                    onClick = { onTabSelected("home") }
                )

                // Tab 2: Jadwal Sholat
                BottomTabItem(
                    tag = "jadwal",
                    label = "Jadwal",
                    iconString = "🕐",
                    isActive = activeTab == "jadwal",
                    onClick = { onTabSelected("jadwal") }
                )

                // Tab 3: Belajar
                BottomTabItem(
                    tag = "belajar",
                    label = "Belajar",
                    iconString = "📚",
                    isActive = activeTab == "belajar",
                    onClick = { onTabSelected("belajar") }
                )

                // Tab 4: Profil
                BottomTabItem(
                    tag = "profil",
                    label = "Profil",
                    iconString = "👑",
                    isActive = activeTab == "profil",
                    onClick = { onTabSelected("profil") }
                )
            }
        }
    }
}

@Composable
fun BottomTabItem(
    tag: String,
    label: String,
    iconString: String,
    isActive: Boolean,
    onClick: () -> Unit
) {
    val activeColor = IslamicGreen
    val inactiveColor = TextMuted

    Column(
        modifier = Modifier
            .testTag("tab_button_$tag")
            .clip(RoundedCornerShape(14.dp))
            .then(
                if (isActive) Modifier
                    .background(
                        Brush.verticalGradient(listOf(IslamicGreen.copy(alpha = 0.18f), IslamicGreen.copy(alpha = 0.05f))),
                        RoundedCornerShape(14.dp)
                    )
                    .border(
                        1.dp,
                        Brush.linearGradient(listOf(IslamicGreen.copy(alpha = 0.6f), GoldAccent.copy(alpha = 0.3f))),
                        RoundedCornerShape(14.dp)
                    )
                    .shadow(
                        elevation = 8.dp,
                        shape = RoundedCornerShape(14.dp),
                        ambientColor = IslamicGreen.copy(alpha = 0.35f),
                        spotColor = IslamicGreen.copy(alpha = 0.2f)
                    )
                else Modifier
            )
            .clickable { onClick() }
            .padding(horizontal = 10.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = iconString,
            fontSize = if (isActive) 24.sp else 18.sp,
            color = if (isActive) activeColor else inactiveColor
        )

        Spacer(modifier = Modifier.height(2.dp))

        Text(
            text = label,
            fontSize = 11.sp,
            fontWeight = if (isActive) FontWeight.Black else FontWeight.Medium,
            color = if (isActive) activeColor else inactiveColor
        )
    }
}
