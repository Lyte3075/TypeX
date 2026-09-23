package com.typex.android;

import android.app.Activity;
import android.os.Bundle;
import android.content.Intent;
import android.net.Uri;
import android.provider.Settings;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.ProgressBar;
import android.widget.ScrollView;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

public class MainActivity extends Activity {
    private static final String RELEASES_URL = "https://api.github.com/repos/Lyte3075/TypeX/releases";
    private TextView updateStatus;
    private LinearLayout releaseList;
    private Button checkButton;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);

        ScrollView scroll = new ScrollView(this);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(32, 32, 32, 32);

        TextView title = new TextView(this);
        title.setText("TypeX");
        title.setTextSize(32);
        title.setGravity(Gravity.CENTER);
        root.addView(title, new LinearLayout.LayoutParams(-1, -2));

        TextView info = new TextView(this);
        info.setText("TypeX Android keyboard\\n\\nEnable it in System Settings → Languages & input → On-screen keyboard.");
        info.setTextSize(16);
        info.setGravity(Gravity.CENTER);
        root.addView(info, new LinearLayout.LayoutParams(-1, -2));

        Button settings = new Button(this);
        settings.setText("Open Keyboard Settings");
        settings.setOnClickListener(v -> startActivity(new Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)));
        root.addView(settings, new LinearLayout.LayoutParams(-1, -2));

        TextView updatesTitle = new TextView(this);
        updatesTitle.setText("Updates & Versions");
        updatesTitle.setTextSize(22);
        updatesTitle.setPadding(0, 40, 0, 12);
        root.addView(updatesTitle);

        updateStatus = new TextView(this);
        updateStatus.setText("Installed: v" + getInstalledVersion() + "\\nTap below to check GitHub for releases.");
        updateStatus.setTextSize(16);
        root.addView(updateStatus);

        checkButton = new Button(this);
        checkButton.setText("Check for Updates");
        checkButton.setOnClickListener(v -> checkForUpdates());
        root.addView(checkButton, new LinearLayout.LayoutParams(-1, -2));

        releaseList = new LinearLayout(this);
        releaseList.setOrientation(LinearLayout.VERTICAL);
        releaseList.setPadding(0, 12, 0, 0);
        root.addView(releaseList, new LinearLayout.LayoutParams(-1, -2));

        TextView note = new TextView(this);
        note.setText("Selecting a version opens its GitHub release page. Android can then install a downloaded APK using the normal Android installer.");
        note.setTextSize(13);
        note.setPadding(0, 20, 0, 20);
        root.addView(note);

        scroll.addView(root);
        setContentView(scroll);
    }

    private String getInstalledVersion() {
        try {
            return getPackageManager().getPackageInfo(getPackageName(), 0).versionName;
        } catch (Exception e) {
            return "1.0.0";
        }
    }

    private void checkForUpdates() {
        checkButton.setEnabled(false);
        updateStatus.setText("Checking GitHub releases...");
        releaseList.removeAllViews();

        new Thread(() -> {
            try {
                HttpURLConnection connection = (HttpURLConnection) new URL(RELEASES_URL).openConnection();
                connection.setRequestProperty("Accept", "application/vnd.github+json");
                connection.setRequestProperty("User-Agent", "TypeX-VersionManager");
                connection.setConnectTimeout(10000);
                connection.setReadTimeout(10000);

                if (connection.getResponseCode() < 200 || connection.getResponseCode() >= 300) {
                    throw new Exception("GitHub returned HTTP " + connection.getResponseCode());
                }

                BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
                StringBuilder jsonText = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) jsonText.append(line);
                reader.close();
                connection.disconnect();

                JSONArray releases = new JSONArray(jsonText.toString());
                List<ReleaseInfo> parsed = new ArrayList<>();

                for (int i = 0; i < releases.length(); i++) {
                    JSONObject item = releases.getJSONObject(i);
                    if (item.optBoolean("draft", false)) continue;
                    String tag = item.optString("tag_name", "");
                    String name = item.optString("name", tag);
                    String url = item.optString("html_url", "");
                    boolean prerelease = item.optBoolean("prerelease", false);
                    parsed.add(new ReleaseInfo(tag, name, url, prerelease));
                }

                runOnUiThread(() -> showReleases(parsed));
            } catch (Exception e) {
                runOnUiThread(() -> {
                    updateStatus.setText("Couldn't check GitHub. Check your internet connection and try again.");
                    checkButton.setEnabled(true);
                });
            }
        }).start();
    }

    private void showReleases(List<ReleaseInfo> releases) {
        checkButton.setEnabled(true);
        if (releases.isEmpty()) {
            updateStatus.setText("No GitHub releases have been published yet.");
            return;
        }

        String current = getInstalledVersion();
        ReleaseInfo latest = releases.get(0);
        boolean newer = compareVersions(cleanVersion(latest.tag), current) > 0;

        updateStatus.setText(newer
                ? "Update available: v" + cleanVersion(latest.tag) + " (installed v" + current + ")"
                : "You're running the newest release currently listed on GitHub.");

        for (ReleaseInfo release : releases) {
            Button version = new Button(this);
            String label = release.name + " • v" + cleanVersion(release.tag);
            if (cleanVersion(release.tag).equals(current)) label += " • Installed";
            if (release.prerelease) label += " • Pre-release";
            version.setText(label);
            version.setOnClickListener(v -> openRelease(release.url));
            releaseList.addView(version, new LinearLayout.LayoutParams(-1, -2));
        }
    }

    private void openRelease(String url) {
        if (url == null || url.isEmpty()) return;
        startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
    }

    private static String cleanVersion(String version) {
        if (version == null) return "0.0.0";
        return version.startsWith("v") ? version.substring(1) : version;
    }

    private static int compareVersions(String a, String b) {
        String[] left = cleanVersion(a).split("\\.");
        String[] right = cleanVersion(b).split("\\.");
        int count = Math.max(left.length, right.length);
        for (int i = 0; i < count; i++) {
            int x = i < left.length ? number(left[i]) : 0;
            int y = i < right.length ? number(right[i]) : 0;
            if (x != y) return Integer.compare(x, y);
        }
        return 0;
    }

    private static int number(String value) {
        try { return Integer.parseInt(value.replaceAll("[^0-9].*", "")); }
        catch (Exception e) { return 0; }
    }

    private static class ReleaseInfo {
        final String tag;
        final String name;
        final String url;
        final boolean prerelease;
        ReleaseInfo(String tag, String name, String url, boolean prerelease) {
            this.tag = tag;
            this.name = name;
            this.url = url;
            this.prerelease = prerelease;
        }
    }
}
