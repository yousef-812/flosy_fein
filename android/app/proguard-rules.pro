-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# WorkManager and Room Database
-keep class androidx.work.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
