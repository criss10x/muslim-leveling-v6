package com.example.data

/**
 * Daftar kota/kabupaten Indonesia untuk pilihan jadwal sholat.
 *
 * ID kota sesuai dengan api.myquran.com v3.
 * v3 uses MD5-like city IDs (not numeric IDs like v1).
 *   GET /sholat/jadwal/{id}/{period}   (period = YYYY-MM-DD or YYYY-MM)
 *
 * Sumber: https://api.myquran.com/v3/sholat/kabkota/semua
 * Daftar ini hanya fallback offline; app akan fetch daftar lengkap dari API
 * saat onboarding/settings dibuka dan cache hasilnya in-memory.
 */
object IndonesianCities {

    data class CityEntry(
        val id: String,
        val name: String
    )

    data class CityGroup(val region: String, val cities: List<CityEntry>)

    // NOTE: Daftar statis ini hanya fallback awal.
    // App akan fetch daftar lengkap dari API saat onboarding/settings dibuka
    // dan cache hasilnya. Lihat GameViewModel.loadCitiesFromKemenag().

    /** Default city untuk onboarding (Kota Denpasar, v3 ID) */
    val defaultCity = CityEntry("6a9aeddfc689c1d0e3b9ccc3ab651bc5", "KOTA DENPASAR")

    /**
     * Daftar kota populer sebagai fallback offline (saat API gagal).
     * ID diambil dari api.myquran.com v3.
     */
    val fallbackCities: List<CityEntry> = listOf(
        CityEntry("58a2fc6ed39fd083f55d4182bf88826d", "KOTA JAKARTA"),
        CityEntry("cedebb6e872f539bef8c3f919874e9d7", "KOTA BEKASI"),
        CityEntry("31fefc0e570cb3860f2a6d4b38c6490d", "KOTA DEPOK"),
        CityEntry("6cdd60ea0045eb7a6ec44c54d29ed402", "KOTA BOGOR"),
        CityEntry("bd4c9ab730f5513206b999ec0d90d1fb", "KOTA TANGERANG"),
        CityEntry("82aa4b0af34c2313a562076992e50aa3", "KOTA TANGERANG SELATAN"),
        CityEntry("fc221309746013ac554571fbd180e1c8", "KOTA BANDUNG"),
        CityEntry("74db120f0a8e5646ef5a30154e9f6deb", "KOTA SEMARANG"),
        CityEntry("577ef1154f3240ad5b9b413aa7346a1e", "KOTA YOGYAKARTA"),
        CityEntry("4734ba6f3de83d861c3176a6273cac6d", "KOTA SURABAYA"),
        CityEntry("06138bc5af6023646ede0e1f7c1eac75", "KOTA MALANG"),
        CityEntry("2838023a778dfaecdc212708f721b788", "KOTA MEDAN"),
        CityEntry("1afa34a7f984eeabdbb0a7d494132ee5", "KOTA PALEMBANG"),
        CityEntry("b7b16ecf8ca53723593894116071700c", "KOTA MAKASSAR"),
        CityEntry("6a9aeddfc689c1d0e3b9ccc3ab651bc5", "KOTA DENPASAR"),
        CityEntry("1700002963a49da13542e0726b7bb758", "KOTA MATARAM"),
        CityEntry("3dd48ab31d016ffcbf3314df2b3cb9ce", "KOTA BANJARMASIN"),
        CityEntry("9be40cee5b0eee1462c82c6964087ff9", "KOTA SAMARINDA"),
        CityEntry("00411460f7c92d2124a67ea0f4cb5f85", "KOTA BALIKPAPAN"),
        CityEntry("0353ab4cbed5beae847a7ff6e220b5cf", "KOTA AMBON"),
        CityEntry("550a141f12de6341fba65b0ad0433500", "KOTA MANADO"),
        CityEntry("41ae36ecb9b3eee609d05b90c14222fb", "KOTA KENDARI"),
        CityEntry("142949df56ea9ae0be8b5306971900a4", "KOTA GORONTALO"),
        CityEntry("f74909ace68e51891440e4da0b65a70c", "KOTA PALU"),
        CityEntry("b83aac23b9528732c23cc7352950e880", "KOTA PONTIANAK"),
        CityEntry("758874998f5bd0c393da094e1967a72b", "KOTA KUPANG"),
        CityEntry("5b69b9cb83065d403869739ae7f0995e", "KOTA JAYAPURA"),
        CityEntry("c7e1249ffc03eb9ded908c236bd1996d", "KOTA PEKANBARU"),
        CityEntry("7cbbc409ec990f19c78c75bd1e06f215", "KOTA PADANG"),
        CityEntry("b3e3e393c77e35a4a3f3cbd1e429b5dc", "KOTA BANDAR LAMPUNG"),
        CityEntry("98dce83da57b0395e163467c9dae521b", "KOTA BATAM"),
        CityEntry("2b44928ae11fb9384c4cf38708677c48", "KOTA BENGKULU"),
        CityEntry("c9e1074f5b3f9fc8ea15d152add07294", "KOTA JAMBI"),
    )

    val cityGroups = listOf(
        CityGroup("Populer", fallbackCities)
    )

    /** Cari kota fallback berdasarkan query (case-insensitive, contains match) */
    fun searchFallback(query: String): List<CityEntry> {
        if (query.isBlank()) return fallbackCities
        return fallbackCities.filter { it.name.contains(query, ignoreCase = true) }
    }
}
