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
 * Kemenag Prayer Time Service (api.myquran.com v3)
 *
 * Data source: api.myquran.com v3 — mirror KEMENAG (Kementerian Agama RI).
 * Endpoint v3 changed from numeric city IDs to MD5 city IDs.
 *
 * Endpoints:
 *  - GET /sholat/kabkota/semua          → semua kota (~517)
 *  - GET /sholat/kabkota/cari/{keyword} → cari kota by nama
 *  - GET /sholat/jadwal/{city_id}/{period} → jadwal per hari (YYYY-MM-DD) atau per bulan (YYYY-MM)
 *
 * Field response jadwal:
 *  - tanggal, imsak, subuh, terbit, dhuha, dzuhur, ashar, maghrib, isya (format "HH:MM")
 *
 * Free, no auth, no API key.
 */

@JsonClass(generateAdapter = true)
data class KemenagCity(
    val id: String,
    val lokasi: String
)

@JsonClass(generateAdapter = true)
data class KemenagCityListResponse(
    val status: Boolean,
    val message: String = "",
    val data: List<KemenagCity> = emptyList()
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
    val isya: String = ""
)

@JsonClass(generateAdapter = true)
data class KemenagJadwalData(
    val id: String = "",
    val kabko: String = "",
    val prov: String = "",
    // v3 returns a date-keyed map for both daily and monthly responses
    val jadwal: Map<String, KemenagJadwal> = emptyMap()
)

@JsonClass(generateAdapter = true)
data class KemenagJadwalResponse(
    val status: Boolean,
    val message: String = "",
    val data: KemenagJadwalData = KemenagJadwalData()
)

@JsonClass(generateAdapter = true)
data class KemenagMonthlyJadwalResponse(
    val status: Boolean,
    val message: String = "",
    val data: KemenagJadwalData = KemenagJadwalData()
)

interface KemenagApiService {
    @GET("sholat/kabkota/semua")
    suspend fun getAllCities(): KemenagCityListResponse

    @GET("sholat/kabkota/cari/{keyword}")
    suspend fun searchCities(@Path("keyword") keyword: String): KemenagCityListResponse

    @GET("sholat/jadwal/{cityId}/{period}")
    suspend fun getDailyJadwal(
        @Path("cityId") cityId: String,
        @Path("period") period: String
    ): KemenagJadwalResponse

    @GET("sholat/jadwal/{cityId}/{period}")
    suspend fun getMonthlyJadwal(
        @Path("cityId") cityId: String,
        @Path("period") period: String
    ): KemenagMonthlyJadwalResponse
}

object KemenagClient {
    private const val BASE_URL = "https://api.myquran.com/v3/"

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
