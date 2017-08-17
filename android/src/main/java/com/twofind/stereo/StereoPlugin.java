package com.twofind.stereo;

import android.app.Activity;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.widget.Toast;

import java.io.IOException;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * StereoPlugin
 */
public class StereoPlugin implements MethodCallHandler {

    private MediaPlayer player;

    private boolean isPlaying;

    private Activity activity;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.mcs.plugins/stereo");
        channel.setMethodCallHandler(new StereoPlugin(registrar.activity()));
    }

    private StereoPlugin(Activity activity) {
        this.activity = activity;
        initPlayer();
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equals("app.loadItemWithURL")) {
            if (!call.arguments.getClass().equals(String.class)) {
                Toast.makeText(activity.getApplicationContext(), "The specified URL must be a string.", Toast.LENGTH_SHORT).show();
                result.error("WRONG_ARG_TYPE", "The specified URL must be a string.", null);
            } else {
                Uri uri = Uri.parse((String) call.arguments);
                loadItemWithURL(uri);
                result.success(null);
            }
        } else if (call.method.equals("app.togglePlaying")) {
            result.success(togglePlaying());
        } else {
            result.notImplemented();
        }
    }

    private void loadItemWithURL(Uri uri) {
        try {
            player.setDataSource(activity.getApplicationContext(), uri);
            player.prepare();
        } catch (IOException e) {
            Toast.makeText(activity.getApplicationContext(), "Something went wrong loading the file...", Toast.LENGTH_SHORT).show();
        }
    }

    private boolean togglePlaying() {
        if (isPlaying) {
            player.pause();
        } else {
            player.start();
        }
        isPlaying = !isPlaying;

        return isPlaying;
    }

    private void initPlayer() {
        player = new MediaPlayer();
        player.setAudioStreamType(AudioManager.STREAM_MUSIC);
    }
}