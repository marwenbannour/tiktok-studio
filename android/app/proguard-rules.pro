# Plugins اللي يتعيّطلهم من Dart بـJNI: R8 ما يشوفش الاستعمال ويفسخهم في الـrelease.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
# الـsignatures اللي يلوّج عليهم JNI فيهم Continuation: ما يلزمش يتبدّل اسمها.
# (Continuation، CoroutineSingletons، Result، Unit.INSTANCE يتلوّج عليهم بالاسم من jni)
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
