# InvoicePe ProGuard Rules

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Supabase
-keep class io.supabase.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# PhonePe SDK
-keep class com.phonepe.intent.sdk.** { *; }
-keep interface com.phonepe.intent.sdk.** { *; }

# Dart Mappable
-keep class **.mapper.dart { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Security - Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Keep model classes
-keep class com.invoicepe.invoice_pe_app.models.** { *; }
-keepclassmembers class com.invoicepe.invoice_pe_app.models.** { *; }
