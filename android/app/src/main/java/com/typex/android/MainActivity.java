package com.typex.android;

import android.app.Activity;
import android.os.Bundle;
import android.content.Intent;
import android.net.Uri;
import android.provider.Settings;
import android.view.Gravity;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.ScrollView;
import android.widget.Toast;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

public class MainActivity extends Activity {
    private static final String RELEASES_URL="https://api.github.com/repos/Lyte3075/TypeX/releases";
    private static final int OPEN_JSON=2001, SAVE_JSON=2002;
    private TextView updateStatus; private LinearLayout releaseList; private Button checkButton;

    @Override public void onCreate(Bundle state){
        super.onCreate(state);
        ScrollView scroll=new ScrollView(this); LinearLayout root=new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL); root.setPadding(32,32,32,32);

        TextView title=new TextView(this); title.setText("TypeX"); title.setTextSize(32); title.setGravity(Gravity.CENTER); root.addView(title,new LinearLayout.LayoutParams(-1,-2));
        TextView info=new TextView(this); info.setText("TypeX customizable keyboard\n\nEnable it in System Settings → Languages & input → On-screen keyboard."); info.setTextSize(16); info.setGravity(Gravity.CENTER); root.addView(info,new LinearLayout.LayoutParams(-1,-2));

        Button settings=new Button(this);settings.setText("Open Keyboard Settings");settings.setOnClickListener(v->startActivity(new Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)));root.addView(settings,new LinearLayout.LayoutParams(-1,-2));

        TextView configTitle=new TextView(this);configTitle.setText("Keyboard Configuration");configTitle.setTextSize(22);configTitle.setPadding(0,40,0,12);root.addView(configTitle);
        TextView configInfo=new TextView(this);configInfo.setText("TypeX uses the same JSON keyboard format as the iOS designer. Export a keyboard from TypeX on iOS, then import it here to use the same layout, actions, colors, gestures, haptics, sounds and behavior on Android.");configInfo.setTextSize(14);root.addView(configInfo);
        LinearLayout configButtons=new LinearLayout(this);configButtons.setOrientation(LinearLayout.HORIZONTAL);
        Button importButton=new Button(this);importButton.setText("Import JSON");importButton.setOnClickListener(v->openImport());configButtons.addView(importButton,new LinearLayout.LayoutParams(0,-2,1));
        Button exportButton=new Button(this);exportButton.setText("Export JSON");exportButton.setOnClickListener(v->openExport());configButtons.addView(exportButton,new LinearLayout.LayoutParams(0,-2,1));
        root.addView(configButtons);

        TextView updatesTitle=new TextView(this);updatesTitle.setText("Updates & Versions");updatesTitle.setTextSize(22);updatesTitle.setPadding(0,40,0,12);root.addView(updatesTitle);
        updateStatus=new TextView(this);updateStatus.setText("Installed: v"+getInstalledVersion()+"\nTap below to check GitHub for releases.");updateStatus.setTextSize(16);root.addView(updateStatus);
        checkButton=new Button(this);checkButton.setText("Check for Updates");checkButton.setOnClickListener(v->checkForUpdates());root.addView(checkButton,new LinearLayout.LayoutParams(-1,-2));
        releaseList=new LinearLayout(this);releaseList.setOrientation(LinearLayout.VERTICAL);releaseList.setPadding(0,12,0,0);root.addView(releaseList,new LinearLayout.LayoutParams(-1,-2));
        TextView note=new TextView(this);note.setText("Selecting a version opens its GitHub release page. Android can then install a downloaded APK using the normal Android installer.");note.setTextSize(13);note.setPadding(0,20,0,20);root.addView(note);
        scroll.addView(root);setContentView(scroll);
    }

    private void openImport(){startActivityForResult(new Intent(Intent.ACTION_OPEN_DOCUMENT).setType("application/json").addCategory(Intent.CATEGORY_OPENABLE),OPEN_JSON);}
    private void openExport(){Intent i=new Intent(Intent.ACTION_CREATE_DOCUMENT);i.setType("application/json");i.putExtra(Intent.EXTRA_TITLE,"TypeX-Keyboard.json");startActivityForResult(i,SAVE_JSON);}
    @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(result!=RESULT_OK||data==null)return;Uri uri=data.getData();if(uri==null)return;try{if(request==OPEN_JSON){BufferedReader r=new BufferedReader(new InputStreamReader(getContentResolver().openInputStream(uri)));StringBuilder s=new StringBuilder();String line;while((line=r.readLine())!=null)s.append(line);r.close();TypeXAndroidConfig.save(this,s.toString());Toast.makeText(this,"Keyboard imported. Reopen TypeX keyboard to apply it.",Toast.LENGTH_LONG).show();}else if(request==SAVE_JSON){OutputStream out=getContentResolver().openOutputStream(uri);out.write(TypeXAndroidConfig.loadJson(this).getBytes("UTF-8"));out.close();Toast.makeText(this,"Keyboard exported.",Toast.LENGTH_SHORT).show();}}catch(Exception e){Toast.makeText(this,"Could not read or write that file.",Toast.LENGTH_LONG).show();}}

    private String getInstalledVersion(){try{return getPackageManager().getPackageInfo(getPackageName(),0).versionName;}catch(Exception e){return "1.0.0";}}
    private void checkForUpdates(){checkButton.setEnabled(false);updateStatus.setText("Checking GitHub releases...");releaseList.removeAllViews();new Thread(()->{try{HttpURLConnection c=(HttpURLConnection)new URL(RELEASES_URL).openConnection();c.setRequestProperty("Accept","application/vnd.github+json");c.setRequestProperty("User-Agent","TypeX-VersionManager");c.setConnectTimeout(10000);c.setReadTimeout(10000);if(c.getResponseCode()<200||c.getResponseCode()>=300)throw new Exception();BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream()));StringBuilder j=new StringBuilder();String line;while((line=r.readLine())!=null)j.append(line);r.close();c.disconnect();JSONArray a=new JSONArray(j.toString());List<ReleaseInfo> list=new ArrayList<>();for(int i=0;i<a.length();i++){JSONObject o=a.getJSONObject(i);if(o.optBoolean("draft",false))continue;list.add(new ReleaseInfo(o.optString("tag_name",""),o.optString("name",o.optString("tag_name","")),o.optString("html_url",""),o.optBoolean("prerelease",false)));}runOnUiThread(()->showReleases(list));}catch(Exception e){runOnUiThread(()->{updateStatus.setText("Couldn't check GitHub. Check your internet connection and try again.");checkButton.setEnabled(true);});}}).start();}
    private void showReleases(List<ReleaseInfo> releases){checkButton.setEnabled(true);if(releases.isEmpty()){updateStatus.setText("No GitHub releases have been published yet.");return;}String current=getInstalledVersion();ReleaseInfo latest=releases.get(0);boolean newer=compareVersions(cleanVersion(latest.tag),current)>0;updateStatus.setText(newer?"Update available: v"+cleanVersion(latest.tag)+" (installed v"+current+")":"You're running the newest release currently listed on GitHub.");for(ReleaseInfo r:releases){Button b=new Button(this);String label=r.name+" • v"+cleanVersion(r.tag);if(cleanVersion(r.tag).equals(current))label+=" • Installed";if(r.prerelease)label+=" • Pre-release";b.setText(label);b.setOnClickListener(v->openRelease(r.url));releaseList.addView(b,new LinearLayout.LayoutParams(-1,-2));}}
    private void openRelease(String url){if(url!=null&&!url.isEmpty())startActivity(new Intent(Intent.ACTION_VIEW,Uri.parse(url)));}
    private static String cleanVersion(String v){return v!=null&&v.startsWith("v")?v.substring(1):v;}
    private static int compareVersions(String a,String b){String[] l=cleanVersion(a).split("\\.");String[] r=cleanVersion(b).split("\\.");int n=Math.max(l.length,r.length);for(int i=0;i<n;i++){int x=i<l.length?number(l[i]):0,y=i<r.length?number(r[i]):0;if(x!=y)return Integer.compare(x,y);}return 0;}
    private static int number(String v){try{return Integer.parseInt(v.replaceAll("[^0-9].*",""));}catch(Exception e){return 0;}}
    private static class ReleaseInfo{final String tag,name,url;final boolean prerelease;ReleaseInfo(String t,String n,String u,boolean p){tag=t;name=n;url=u;prerelease=p;}}
}