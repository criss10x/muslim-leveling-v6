package com.example.data

/**
 * Daftar kota/kabupaten Indonesia untuk pilihan jadwal sholat.
 *
 * ID kota sesuai dengan api.myquran.com (mirror KEMENAG).
 * ID numeric diperlukan untuk query jadwal sholat:
 *   GET /v1/sholat/jadwal/{id}/{year}/{month}
 *
 * Sumber: api.myquran.com/v1/sholat/kota/semua
 * Dikelompokkan per pulau untuk memudahkan pencarian.
 */
object IndonesianCities {

    data class CityEntry(
        val id: String,
        val name: String
    )

    data class CityGroup(val region: String, val cities: List<CityEntry>)

    val cityGroups = listOf(
        CityGroup("Sumatera", listOf(
            CityEntry("1301", "Kota Jakarta"),  // placeholder, akan diganti
        ))
    )

    // NOTE: Daftar statis ini hanya fallback awal.
    // App akan fetch daftar lengkap dari API saat onboarding/settings dibuka
    // dan cache hasilnya. Lihat [KemenagCityRepository].

    /** Default city untuk onboarding */
    val defaultCity = CityEntry("1301", "Kota Jakarta")

    /**
     * Daftar kota populer sebagai fallback offline (saat API gagal).
     * Diambil dari data KEMENAG. Format: ID → Nama.
     */
    val fallbackCities: List<CityEntry> = listOf(
        CityEntry("1301", "Kota Jakarta"),
        CityEntry("1303", "Kota Bekasi"),
        CityEntry("1304", "Kota Bogor"),
        CityEntry("1305", "Kota Tangerang"),
        CityEntry("1306", "Kota Depok"),
        CityEntry("1309", "Kab. Bogor"),
        CityEntry("1310", "Kab. Bekasi"),
        CityEntry("1311", "Kab. Tangerang"),
        CityEntry("3204", "Kota Bandung"),
        CityEntry("3215", "Kab. Bandung"),
        CityEntry("3207", "Kota Cirebon"),
        CityEntry("3302", "Kab. Cirebon"),
        CityEntry("3309", "Kab. Cilacap"),
        CityEntry("3374", "Kota Semarang"),
        CityEntry("3328", "Kab. Pekalongan"),
        CityEntry("3402", "Kab. Bantul"),
        CityEntry("3401", "Kab. Kulon Progo"),
        CityEntry("3471", "Kota Yogyakarta"),
        CityEntry("3510", "Kab. Malang"),
        CityEntry("3573", "Kota Malang"),
        CityEntry("3578", "Kota Surabaya"),
        CityEntry("3576", "Kota Kediri"),
        CityEntry("3524", "Kab. Lamongan"),
        CityEntry("3577", "Kota Madiun"),
        CityEntry("3603", "Kota Tangerang Selatan"),
        CityEntry("3208", "Kota Sukabumi"),
        CityEntry("3276", "Kota Tasikmalaya"),
        // Bali & Nusa Tenggara
        CityEntry("5108", "Kab. Jembrana"),
        CityEntry("5171", "Kota Denpasar"),
        CityEntry("5201", "Kab. Lombok Barat"),
        CityEntry("5271", "Kota Mataram"),
        CityEntry("5301", "Kab. Kupang"),
        CityEntry("5371", "Kota Kupang"),
        // Kalimantan
        CityEntry("6101", "Kab. Sambas"),
        CityEntry("6171", "Kota Pontianak"),
        CityEntry("6205", "Kab. Barito Selatan"),
        CityEntry("6271", "Kota Banjarmasin"),
        CityEntry("6371", "Kota Samarinda"),
        CityEntry("6372", "Kota Balikpapan"),
        CityEntry("6471", "Kota Tarakan"),
        // Sulawesi
        CityEntry("7301", "Kab. Bantaeng"),
        CityEntry("7371", "Kota Makassar"),
        CityEntry("7171", "Kota Manado"),
        CityEntry("7401", "Kab. Kolaka"),
        CityEntry("7471", "Kota Kendari"),
        CityEntry("7201", "Kab. Banggai"),
        CityEntry("7271", "Kota Palu"),
        CityEntry("7501", "Kab. Bolaang Mongondow"),
        CityEntry("7571", "Kota Gorontalo"),
        // Maluku & Papua
        CityEntry("8101", "Kab. Maluku Tengah"),
        CityEntry("8171", "Kota Ambon"),
        CityEntry("8271", "Kota Ternate"),
        CityEntry("9101", "Kab. Merauke"),
        CityEntry("9171", "Kota Jayapura"),
        CityEntry("9201", "Kab. Sorong"),
        CityEntry("9105", "Kab. Nabire"),
        // Sumatera
        CityEntry("1101", "Kab. Aceh Selatan"),
        CityEntry("1171", "Kota Banda Aceh"),
        CityEntry("1201", "Kab. Tapanuli Tengah"),
        CityEntry("1271", "Kota Medan"),
        CityEntry("1301", "Kota Jakarta"),
        CityEntry("1371", "Kota Jambi"),
        CityEntry("1671", "Kota Palembang"),
        CityEntry("1701", "Kab. Bengkulu Utara"),
        CityEntry("1871", "Kota Bandar Lampung"),
    )

    /** Cari kota fallback berdasarkan query (case-insensitive, contains match) */
    fun searchFallback(query: String): List<CityEntry> {
        if (query.isBlank()) return fallbackCities
        return fallbackCities.filter { it.name.contains(query, ignoreCase = true) }
    }
}
