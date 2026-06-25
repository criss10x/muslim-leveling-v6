package com.example.data

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import retrofit2.http.GET
import retrofit2.http.Path
import java.util.concurrent.TimeUnit

/**
 * Kemenag Prayer Time Service
 *
 * Menggunakan api.myquran.com — mirror JSON resmi data KEMENAG (Kementerian Agama RI).
 * Site resmi KEMENAG (jadwalsholat.org) hanya menyediakan HTML, jadi kita pakai
 * mirror JSON ini yang berisi data yang sama persis (imsak, subuh, terbit, dhuha,
 * dzuhur, ashar, maghrib, isya).
 *
 * Endpoint:
 *  - GET /v1/sholat/kota/semua           → semua kota (~300+)
 *  - GET /v1/sholat/kota/cari/{keyword}  → cari kota by nama
 *  - GET /v1/sholat/jadwal/{city_id}/{YYYY}/{M}    → jadwal 1 bulan penuh
 *  - GET /v1/sholat/jadwal/{city_id}/{YYYY}/{M}/{D} → jadwal 1 hari
 *
 * Field response:
 *  - imsak, subuh, terbit, dhuha, dzuhur, ashar, maghrib, isya (format "HH:MM")
 *  - tanggal (Indonesian), date (ISO YYYY-MM-DD)
 *  - lokasi (nama kota), daerah (provinsi)
 *
 * Free, no auth, no API key. Rate limit: pakai caching monthly (1 request per kota per bulan).
 */

@JsonClass(generateAdapter = true)
data class KemenagCity(
    val id: String,
    val lokasi: String
)

@JsonClass(generateAdapter = true)
data class KemenagCityListResponse(
    val status: Boolean,
    val data: List<KemenagCity>
)

@JsonClass(generateAdapter = true)
data class KemenagJadwal(
    val tanggal: String = "",
    val imsak: String = "",
    val subuh: String = "",
    val terbit: String = "",
    val dhuha: String = "",
    val dzuhur: String = "",
    val ashar: String = "",
    val maghrib: String = "",
    val isya: String = "",
    val date: String = ""
)

@JsonClass(generateAdapter = true)
data class KemenagJadwalData(
    val id: Int = 0,
    val lokasi: String = "",
    val daerah: String = "",
    val jadwal: KemenagJadwal = KemenagJadwal()
)

@JsonClass(generateAdapter = true)
data class KemenagJadwalResponse(
    val status: Boolean,
    val data: KemenagJadwalData
)

@JsonClass(generateAdapter = true)
data class KemenagMonthlyJadwalResponse(
    val status: Boolean,
    val data: KemenagJadwalData
)

interface KemenagApiService {
    @GET("v1/sholat/kota/semua")
    suspend fun getAllCities(): KemenagCityListResponse

    @GET("v1/sholat/kota/cari/{keyword}")
    suspend fun searchCities(@Path("keyword") keyword: String): KemenagCityListResponse

    @GET("v1/sholat/jadwal/{cityId}/{year}/{month}/{day}")
    suspend fun getDailyJadwal(
        @Path("cityId") cityId: String,
        @Path("year") year: Int,
        @Path("month") month: Int,
        @Path("day") day: Int
    ): KemenagJadwalResponse

    @GET("v1/sholat/jadwal/{cityId}/{year}/{month}")
    suspend fun getMonthlyJadwal(
        @Path("cityId") cityId: String,
        @Path("year") year: Int,
        @Path("month") month: Int
    ): KemenagMonthlyJadwalResponse
}

object KemenagClient {
    private const val BASE_URL = "https://api.myquran.com/"

    private val logging = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BASIC
    }

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(logging)
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    val apiService: KemenagApiService by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create())
            .build()
            .create(KemenagApiService::class.java)
    }
}
