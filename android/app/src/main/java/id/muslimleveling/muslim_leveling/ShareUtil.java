package id.muslimleveling.muslim_leveling;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import androidx.annotation.NonNull;

import java.io.File;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class ShareUtil implements MethodChannel.MethodCallHandler {
    private static final String CHANNEL = "muslim_leveling/share";
    private final Context context;

    public ShareUtil(Context context) {
        this.context = context;
    }

    public static void register(FlutterEngine engine, Context context) {
        new MethodChannel(engine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(new ShareUtil(context));
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (!"shareFile".equals(call.method)) {
            result.notImplemented();
            return;
        }

        String filePath = call.argument("filePath");
        String text = call.argument("text");
        if (filePath == null) {
            result.error("INVALID_ARG", "filePath is required", null);
            return;
        }

        try {
            File file = new File(filePath);
            Uri uri = androidx.core.content.FileProvider.getUriForFile(
                    context,
                    context.getPackageName() + ".fileprovider",
                    file
            );

            Intent intent = new Intent(Intent.ACTION_SEND);
            intent.setType("image/png");
            intent.putExtra(Intent.EXTRA_STREAM, uri);
            if (text != null) {
                intent.putExtra(Intent.EXTRA_TEXT, text);
            }
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

            Intent chooser = Intent.createChooser(intent, "Bagikan ke");
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(chooser);

            result.success(true);
        } catch (Exception e) {
            result.error("SHARE_FAILED", e.getMessage(), null);
        }
    }
}
