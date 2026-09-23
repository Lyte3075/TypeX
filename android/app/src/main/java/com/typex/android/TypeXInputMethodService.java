package com.typex.android;

import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.inputmethodservice.InputMethodService;
import android.media.AudioManager;
import android.media.ToneGenerator;
import android.os.Build;
import android.os.Handler;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.text.InputType;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.widget.Button;
import android.widget.LinearLayout;
import java.util.Locale;

public class TypeXInputMethodService extends InputMethodService {
    private LinearLayout root; private TypeXAndroidConfig config; private boolean shifted; private Vibrator vibrator; private ToneGenerator tone; private float density;
    @Override public void onCreate(){super.onCreate();density=getResources().getDisplayMetrics().density;vibrator=(Vibrator)getSystemService(VIBRATOR_SERVICE);tone=new ToneGenerator(AudioManager.STREAM_SYSTEM,45);}
    @Override public View onCreateInputView(){buildKeyboard();return root;}
    @Override public void onStartInput(EditorInfo info,boolean restarting){super.onStartInput(info,restarting);shifted=config!=null&&config.autoCapitalize&&isSentenceCap(info);if(root!=null)updateShiftLabels();}
    @Override public void onDestroy(){if(tone!=null)tone.release();super.onDestroy();}
    private void buildKeyboard(){config=TypeXAndroidConfig.load(this);root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);root.setPadding(dp(6),dp(6),dp(6),dp(6));root.setBackgroundColor(opacityColor(TypeXAndroidConfig.color(config.backgroundHex,Color.rgb(11,11,18)),config.opacity));for(TypeXAndroidConfig.Row data:config.rows){LinearLayout row=new LinearLayout(this);row.setGravity(Gravity.CENTER);row.setOrientation(LinearLayout.HORIZONTAL);root.addView(row,new LinearLayout.LayoutParams(-1,dp(config.keyHeight)));for(TypeXAndroidConfig.Key key:data.keys){Button b=makeButton(key);LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(0,0,(float)Math.max(.4,key.width));lp.height=dp(config.keyHeight*key.height);int gap=dp(config.keySpacing/2);lp.setMargins(gap,dp(config.keySpacing/2),gap,dp(config.keySpacing/2));row.addView(b,lp);}}}
    private Button makeButton(TypeXAndroidConfig.Key key){Button b=new Button(this);b.setText(displayLabel(key));b.setTextSize((float)key.fontSize);b.setTextColor(TypeXAndroidConfig.color(key.foregroundHex,Color.WHITE));b.setGravity(Gravity.CENTER);b.setAllCaps(false);b.setTypeface(Typeface.DEFAULT,key.fontWeight>=700?Typeface.BOLD:Typeface.NORMAL);b.setPadding(0,0,0,0);b.setMinWidth(0);b.setMinHeight(0);b.setStateListAnimator(null);applyBg(b,key.backgroundHex,key.cornerRadius);installTouch(b,key);return b;}
    private void applyBg(Button b,String hex,double radius){GradientDrawable g=new GradientDrawable();g.setColor(TypeXAndroidConfig.color(hex,Color.rgb(23,23,36)));g.setCornerRadius(dp(radius));b.setBackground(g);}
    private void installTouch(Button b,TypeXAndroidConfig.Key key){final float[] start={0,0};final boolean[] moved={false};final boolean[] longPressed={false};final Handler h=new Handler();final Runnable[] task={null};b.setOnTouchListener((v,e)->{switch(e.getActionMasked()){case MotionEvent.ACTION_DOWN:start[0]=e.getX();start[1]=e.getY();moved[0]=false;longPressed[0]=false;applyBg(b,key.pressedHex,key.cornerRadius);feedback(key);if(!key.longPressAction.isEmpty()||!key.longPressOutput.isEmpty()){task[0]=()->{longPressed[0]=true;perform(key.longPressAction,key.longPressOutput);};h.postDelayed(task[0],450);}return true;case MotionEvent.ACTION_MOVE:float dx=e.getX()-start[0],dy=e.getY()-start[1];if(Math.max(Math.abs(dx),Math.abs(dy))>dp(28)&&!moved[0]){moved[0]=true;if(task[0]!=null)h.removeCallbacks(task[0]);String a=Math.abs(dx)>Math.abs(dy)?(dx>0?key.swipeRightAction:key.swipeLeftAction):(dy>0?key.swipeDownAction:key.swipeUpAction);String o=Math.abs(dx)>Math.abs(dy)?(dx>0?key.swipeRightOutput:key.swipeLeftOutput):(dy>0?key.swipeDownOutput:key.swipeUpOutput);if(!a.isEmpty()||!o.isEmpty())perform(a,o);}return true;case MotionEvent.ACTION_UP:if(task[0]!=null)h.removeCallbacks(task[0]);applyBg(b,key.backgroundHex,key.cornerRadius);if(!moved[0]&&!longPressed[0])perform(key.action,key.output);return true;case MotionEvent.ACTION_CANCEL:if(task[0]!=null)h.removeCallbacks(task[0]);applyBg(b,key.backgroundHex,key.cornerRadius);return true;}return false;});}
    private void feedback(TypeXAndroidConfig.Key k){if(config.haptics&&k.haptic&&vibrator!=null&&vibrator.hasVibrator()){if(Build.VERSION.SDK_INT>=26)vibrator.vibrate(VibrationEffect.createOneShot(10,VibrationEffect.DEFAULT_AMPLITUDE));else vibrator.vibrate(10);}if(config.sounds&&k.sound&&tone!=null)tone.startTone(ToneGenerator.TONE_PROP_BEEP,25);}
    private void perform(String action,String output){if(action==null)action="";if(output==null)output="";InputConnection ic=getCurrentInputConnection();if(ic==null)return;switch(action){case "backspace":ic.deleteSurroundingText(1,0);break;case "space":handleSpace();break;case "returnKey":commit("\n");break;case "shift":shifted=!shifted;updateShiftLabels();break;case "nextKeyboard":if(Build.VERSION.SDK_INT>=28)switchToNextInputMethod(false);break;case "dismiss":requestHideSelf(0);break;case "tab":commit("\t");break;case "emoji":commit("🙂");break;default:commit(output);}}
    private void commit(String value){if(value==null||value.isEmpty())return;String v=transform(value);InputConnection ic=getCurrentInputConnection();if(ic==null)return;ic.commitText(v,1);if(shifted&&containsLetter(v)){shifted=false;updateShiftLabels();}}
    private String transform(String v){if(shifted)v=v.toUpperCase(Locale.getDefault());if(config.smartQuotes){v=v.replace("\"","“").replace("'","’");}if(config.smartDashes)v=v.replace(" -- "," — ");return v;}
    private void handleSpace(){InputConnection ic=getCurrentInputConnection();if(ic==null)return;if(config.doubleSpacePeriod){CharSequence before=ic.getTextBeforeCursor(1,0);if(before!=null&&before.length()==1&&before.charAt(0)==' '){ic.deleteSurroundingText(1,0);ic.commitText(". ",1);return;}}ic.commitText(" ",1);}
    private void updateShiftLabels(){if(root==null)return;for(int i=0;i<root.getChildCount();i++){View rv=root.getChildAt(i);if(!(rv instanceof ViewGroup))continue;ViewGroup row=(ViewGroup)rv;for(int j=0;j<row.getChildCount();j++){View v=row.getChildAt(j);if(v instanceof Button){Button b=(Button)v;String s=String.valueOf(b.getText());if(s.length()==1&&Character.isLetter(s.charAt(0)))b.setText(shifted?s.toUpperCase(Locale.getDefault()):s.toLowerCase(Locale.getDefault()));}}}}
    private String displayLabel(TypeXAndroidConfig.Key k){return shifted&&"text".equals(k.action)?k.label.toUpperCase(Locale.getDefault()):k.label;}
    private boolean isSentenceCap(EditorInfo i){return (i.inputType&InputType.TYPE_MASK_CLASS)==InputType.TYPE_CLASS_TEXT&&(i.inputType&InputType.TYPE_TEXT_FLAG_CAP_SENTENCES)!=0;}
    private boolean containsLetter(String s){for(int i=0;i<s.length();i++)if(Character.isLetter(s.charAt(i)))return true;return false;}
    private int opacityColor(int c,double o){int a=(int)(Math.max(0,Math.min(1,o))*255);return Color.argb(a,Color.red(c),Color.green(c),Color.blue(c));}
    private int dp(double v){return (int)Math.round(v*density);}
}