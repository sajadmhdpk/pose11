# Flutter & SharedPreferences Proguard rules
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class androidx.datastore.** { *; }
-keep class androidx.preference.** { *; }
-keep class com.example.pose1.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**
-dontwarn androidx.datastore.**
