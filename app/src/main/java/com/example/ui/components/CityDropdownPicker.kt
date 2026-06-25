package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.IndonesianCities
import com.example.data.KemenagCity
import com.example.ui.theme.*

/**
 * A searchable dropdown picker for Indonesian cities (KEMENAG data source).
 *
 * Uses Material3 [ExposedDropdownMenuBox].
 *
 * FIX (force close): Versi lama pakai `verticalScroll(rememberScrollState())`
 * di dalam `DropdownMenu` → Compose throw `IllegalArgumentException` karena
 * `DropdownMenu` measure content dengan unbounded maxHeight. Solusi: hapus
 * `verticalScroll` — `DropdownMenu` sudah punya internal scroll sendiri.
 *
 * Sekarang menerima [KemenagCity] (id + lokasi) bukan plain String, supaya
 * bisa langsung query API KEMENAG dengan city ID numeric.
 *
 * Design (Arena Hikmah):
 * - DarkBackground container, IslamicGreen (teal) border on focus
 * - Dropdown: DarkSurfaceElevated bg, 8dp rounded corners
 * - Selected city: teal accent + check icon
 * - Loading state: spinner saat fetch kota dari API
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CityDropdownPicker(
    value: String,
    onValueChange: (String) -> Unit,
    cities: List<KemenagCity> = emptyList(),
    isLoading: Boolean = false,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }
    var query by remember { mutableStateOf(value) }

    // Sync external value → internal query when value changes outside (e.g. reset)
    LaunchedEffect(value) {
        if (value != query) query = value
    }

    val keyboard = LocalSoftwareKeyboardController.current

    // Filter cities by search query (case-insensitive contains)
    val filteredCities by remember(query, cities) {
        derivedStateOf {
            val q = query.trim()
            if (q.isBlank()) cities
            else cities.filter { it.lokasi.contains(q, ignoreCase = true) }
        }
    }

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = it },
        modifier = modifier
    ) {
        OutlinedTextField(
            value = query,
            onValueChange = { typed ->
                query = typed
                onValueChange(typed)
                if (!expanded) expanded = true
            },
            placeholder = { Text("Cari kota/kabupaten...", color = TextMuted) },
            leadingIcon = {
                Icon(
                    imageVector = Icons.Default.LocationOn,
                    contentDescription = null,
                    tint = IslamicGreen,
                    modifier = Modifier.size(18.dp)
                )
            },
            trailingIcon = {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        strokeWidth = 2.dp,
                        color = IslamicGreen
                    )
                }
            },
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
            keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
                keyboardType = KeyboardType.Text,
                imeAction = ImeAction.Done
            ),
            modifier = Modifier
                .menuAnchor()
                .fillMaxWidth()
        )

        DropdownMenu(
            expanded = expanded,
            onDismissRequest = {
                expanded = false
                // Validate: if text doesn't match any city, clear it.
                val match = cities.find { it.lokasi.equals(query.trim(), ignoreCase = true) }
                if (match != null) {
                    query = match.lokasi
                    onValueChange(match.lokasi)
                } else if (query.isNotBlank()) {
                    query = ""
                    onValueChange("")
                }
            },
            modifier = Modifier
                .background(DarkSurfaceElevated, RoundedCornerShape(8.dp))
                .heightIn(max = 320.dp)
                .width(IntrinsicSize.Max)
        ) {
            if (isLoading && filteredCities.isEmpty()) {
                Row(
                    modifier = Modifier
                        .padding(horizontal = 16.dp, vertical = 16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(14.dp),
                        strokeWidth = 2.dp,
                        color = IslamicGreen
                    )
                    Text(
                        text = "Memuat daftar kota...",
                        color = TextMuted,
                        fontSize = 13.sp
                    )
                }
            } else if (filteredCities.isEmpty()) {
                Text(
                    text = "Kota tidak ditemukan",
                    color = TextMuted,
                    fontSize = 13.sp,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
                )
            } else {
                // NOTE: Tidak pakai verticalScroll — DropdownMenu sudah punya
                // internal scroll sendiri. verticalScroll di sini bikin crash
                // IllegalArgumentException (unbounded maxHeight measurement).
                filteredCities.take(50).forEach { city ->
                    val isSelected = city.lokasi.equals(value, ignoreCase = true)
                    DropdownMenuItem(
                        text = {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = city.lokasi,
                                    color = if (isSelected) IslamicGreen else TextLight,
                                    fontSize = 13.sp,
                                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                                    modifier = Modifier.weight(1f)
                                )
                                if (isSelected) {
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Icon(
                                        imageVector = Icons.Filled.Check,
                                        contentDescription = null,
                                        tint = IslamicGreen,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                            }
                        },
                        onClick = {
                            query = city.lokasi
                            onValueChange(city.lokasi)
                            expanded = false
                            keyboard?.hide()
                        }
                    )
                }
                if (filteredCities.size > 50) {
                    Text(
                        text = "↓ ${filteredCities.size - 50} kota lainnya. Ketik untuk filter.",
                        color = TextMuted,
                        fontSize = 11.sp,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }
            }
        }
    }
}

/**
 * Overload lama untuk kompatibilitas — menerima plain String list.
 * Digunakan jika caller belum migrate ke KemenagCity.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CityDropdownPicker(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    CityDropdownPicker(
        value = value,
        onValueChange = onValueChange,
        cities = IndonesianCities.fallbackCities.map { KemenagCity(id = it.id, lokasi = it.name) },
        isLoading = false,
        modifier = modifier
    )
}
