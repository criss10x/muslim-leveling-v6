package dev.fluttercommunity.plus.packageinfo;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * Stub Java implementation — shadows the Kotlin version from package_info_plus
 * that fails to compile with AGP 9.0 / Gradle 9.1.
 */
public class PackageInfoPlugin implements FlutterPlugin {
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        // no-op: package info not needed for share feature
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        // no-op
    }
}
