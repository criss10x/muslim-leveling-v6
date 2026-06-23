package com.example.data

/**
 * Daftar kota-kota besar di Indonesia untuk pilihan jadwal sholat.
 * Nama kota sesuai format yang diterima oleh Aladhan API (api.aladhan.com).
 * Dikelompokkan per pulau untuk memudahkan pencarian.
 */
object IndonesianCities {

    data class CityGroup(val region: String, val cities: List<String>)

    val cityGroups = listOf(
        CityGroup("Sumatera", listOf(
            "Banda Aceh", "Medan", "Padang", "Pekanbaru", "Jambi",
            "Palembang", "Bengkulu", "Bandar Lampung", "Tanjung Pinang",
            "Pangkal Pinang", "Sibolga", "Lhokseumawe"
        )),
        CityGroup("Jawa", listOf(
            "Jakarta", "Bandung", "Semarang", "Yogyakarta", "Surabaya",
            "Serang", "Bekasi", "Tangerang", "Depok", "Bogor",
            "Cirebon", "Tegal", "Pekalongan", "Magelang", "Solo",
            "Madiun", "Kediri", "Malang", "Jember", "Probolinggo"
        )),
        CityGroup("Bali & Nusa Tenggara", listOf(
            "Denpasar", "Mataram", "Kupang", "Singaraja", "Bima"
        )),
        CityGroup("Kalimantan", listOf(
            "Pontianak", "Banjarmasin", "Palangkaraya", "Samarinda",
            "Tanjung Selor", "Balikpapan", "Tarakan"
        )),
        CityGroup("Sulawesi", listOf(
            "Makassar", "Manado", "Palu", "Kendari", "Gorontalo",
            "Mamuju", "Bitung", "Palopo", "Bau-Bau"
        )),
        CityGroup("Maluku & Papua", listOf(
            "Ambon", "Ternate", "Sofifi", "Jayapura", "Manokwari",
            "Sorong", "Nabire", "Merauke"
        ))
    )

    /** Flat list semua kota (A-Z) */
    val allCities: List<String> = cityGroups.flatMap { it.cities }.sortedBy { it.lowercase() }

    /** Cari kota berdasarkan query (case-insensitive, contains match) */
    fun search(query: String): List<String> {
        if (query.isBlank()) return allCities
        return allCities.filter { it.contains(query, ignoreCase = true) }
    }
}
