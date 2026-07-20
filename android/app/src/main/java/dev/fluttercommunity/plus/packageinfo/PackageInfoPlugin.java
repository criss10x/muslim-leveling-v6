package dev.fluttercommunity.plus.packageinfo;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * Stub — package_info_plus ships a Kotlin plugin but Gradle Kotlin
 * compilation often fails on CI. This Java stub avoids the build error.
 * ponytail: remove when Kotlin compiler version alignment is resolved.
 */
public class PackageInfoPlugin implements FlutterPlugin, MethodCallHandler {
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        new io.flutter.plugins.pathprovider.PathProviderPlugin();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {}

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        result.notImplemented();
    }
}
