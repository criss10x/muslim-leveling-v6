package com.example.data

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import retrofit2.http.GET
import retrofit2.http.Query
import java.util.concurrent.TimeUnit

@JsonClass(generateAdapter = true)
data class AladhanTimings(
    @param:Json(name = "Fajr") val fajr: String,
    @param:Json(name = "Sunrise") val sunrise: String? = null,
    @param:Json(name = "Dhuhr") val dhuhr: String,
    @param:Json(name = "Asr") val asr: String,
    @param:Json(name = "Maghrib") val maghrib: String,
    @param:Json(name = "Isha") val isha: String
)

@JsonClass(generateAdapter = true)
data class AladhanData(
    val timings: AladhanTimings
)

@JsonClass(generateAdapter = true)
data class AladhanResponse(
    val code: Int,
    val status: String,
    val data: AladhanData
)

interface AladhanApiService {
    @GET("v1/timingsByCity")
    suspend fun getTimingsByCity(
        @Query("city") city: String,
        @Query("country") country: String = "Indonesia"
    ): AladhanResponse
}

object AladhanClient {
    private const val BASE_URL = "https://api.aladhan.com/"

    private val logging = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(logging)
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    val apiService: AladhanApiService by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create())
            .build()
            .create(AladhanApiService::class.java)
    }
}
