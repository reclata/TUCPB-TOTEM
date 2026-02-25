# Regras Proguard para o TUCPB Totem

# Preservar classes do gertec_pos_printer (impressora do SK-210)
-keep class br.com.gertec.** { *; }
-keep class com.terreiro.gertec.** { *; }
-dontwarn br.com.gertec.**

# Preservar classes do printing
-keep class com.rtfpessoa.** { *; }
-dontwarn com.rtfpessoa.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
