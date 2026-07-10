# R8 full-mode menghapus generic signature TypeToken milik Gson →
# flutter_local_notifications melempar "Missing type parameter" di release
# build pada semua jalur persistensi (zonedSchedule/cancelAll/
# pendingNotificationRequests). Rules resmi dari README Gson:
-keepattributes Signature
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
