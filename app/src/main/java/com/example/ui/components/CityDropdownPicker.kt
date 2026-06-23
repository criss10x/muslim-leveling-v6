package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.IndonesianCities
import com.example.ui.theme.*

/**
 * A searchable dropdown picker for Indonesian cities.
 *
 * Shows a text field that, when focused/clicked, opens a dropdown menu with
 * the city list filtered by the search query. Cities are grouped by region
 * (island) with gold uppercase headers.
 *
 * Design language (Arena Hikmah):
 * - DarkSurface background, IslamicGreen (teal) border on focus
 * - TextLight text, TextMuted placeholder
 * - Dropdown: DarkSurfaceElevated bg, 8dp rounded corners, max height 240dp
 * - Selected city: teal accent + check icon
 * - Region group headers: GoldAccent, 11sp bold uppercase
 */
@Composable
fun CityDropdownPicker(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }
    val keyboard = LocalSoftwareKeyboardController.current

    // Pre-compute filtered groups reactively from the current value (search query).
    val filteredGroups by remember(value) {
        derivedStateOf {
            val query = value.trim()
            IndonesianCities.cityGroups.mapNotNull { group ->
                val matches = if (query.isBlank()) {
                    group.cities
                } else {
                    group.cities.filter { it.contains(query, ignoreCase = true) }
                }
                if (matches.isEmpty()) null else group.copy(cities = matches)
            }
        }
    }

    Box(modifier = modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = { typed ->
                // Typing updates the query and re-opens the dropdown so results show.
                if (!expanded) expanded = true
                onValueChange(typed)
            },
            placeholder = { Text("Cari kota...", color = TextMuted) },
            singleLine = true,
            colors = OutlinedTextFieldDefaults.colors(
                focusedTextColor = TextLight,
                unfocusedTextColor = TextLight,
                focusedBorderColor = IslamicGreen,
                unfocusedBorderColor = DarkSurfaceVariant,
                focusedContainerColor = DarkBackground,
                unfocusedContainerColor = DarkBackground,
                cursorColor = IslamicGreen
            ),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier
                .fillMaxWidth()
                .clickable { expanded = !expanded }
        )

        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            modifier = Modifier
                .background(DarkSurfaceElevated, RoundedCornerShape(8.dp))
                .width(IntrinsicSize.Max)
                .heightIn(max = 240.dp)
        ) {
            if (filteredGroups.isEmpty()) {
                Text(
                    text = "Kota tidak ditemukan",
                    color = TextMuted,
                    fontSize = 13.sp,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
                )
            } else {
                Column(
                    modifier = Modifier
                        .verticalScroll(rememberScrollState())
                        .padding(vertical = 4.dp)
                ) {
                    filteredGroups.forEach { group ->
                        // Region header
                        Text(
                            text = group.region.uppercase(),
                            color = GoldAccent,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(
                                start = 16.dp,
                                end = 16.dp,
                                top = 10.dp,
                                bottom = 4.dp
                            )
                        )
                        group.cities.forEach { city ->
                            val isSelected = city == value
                            DropdownMenuItem(
                                text = {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text(
                                            text = city,
                                            color = if (isSelected) IslamicGreen else TextLight,
                                            fontSize = 14.sp,
                                            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                                            modifier = Modifier.weight(1f)
                                        )
                                        if (isSelected) {
                                            Spacer(modifier = Modifier.width(8.dp))
                                            androidx.compose.material3.Icon(
                                                imageVector = Icons.Filled.Check,
                                                contentDescription = null,
                                                tint = IslamicGreen,
                                                modifier = Modifier.size(16.dp)
                                            )
                                        }
                                    }
                                },
                                onClick = {
                                    onValueChange(city)
                                    expanded = false
                                    keyboard?.hide()
                                },
                                modifier = Modifier.padding(horizontal = 8.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}
