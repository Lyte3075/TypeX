package com.typex.android;

import android.inputmethodservice.InputMethodService;
import android.view.View;
import android.view.ViewGroup;
import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.widget.Button;
import android.widget.LinearLayout;
import android.view.inputmethod.InputConnection;

public class TypeXInputMethodService extends InputMethodService {
    private LinearLayout root;

    @Override public View onCreateInputView() {
        root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(4, 4, 4, 4);
        root.setBackgroundColor(Color.rgb(18, 18, 24));

        addRow("QWERTYUIOP");
        addRow("ASDFGHJKL");
        addRow("ZXCVBNM");
        addBottomRow();

        return root;
    }

    private void addRow(String letters) {
        LinearLayout row = new LinearLayout(this);
        row.setGravity(Gravity.CENTER);
        row.setWeightSum(letters.length());
        for (char c : letters.toCharArray()) {
            addKey(row, String.valueOf(c), String.valueOf(c), 1f);
        }
        root.addView(row, new LinearLayout.LayoutParams(-1, 56));
    }

    private void addBottomRow() {
        LinearLayout row = new LinearLayout(this);
        row.setGravity(Gravity.CENTER);
        addKey(row, "⌫", null, 1f);
        addKey(row, "Space", " ", 4f);
        addKey(row, "↵", "\n", 1f);
        root.addView(row, new LinearLayout.LayoutParams(-1, 56));
    }

    private void addKey(ViewGroup row, String label, String output, float weight) {
        Button b = new Button(this);
        b.setText(label);
        b.setTextSize(14);
        b.setTypeface(Typeface.DEFAULT, Typeface.NORMAL);
        b.setAllCaps(false);
        b.setOnClickListener(v -> {
            InputConnection ic = getCurrentInputConnection();
            if (ic == null) return;
            if ("⌫".equals(label)) {
                ic.deleteSurroundingText(1, 0);
            } else if ("↵".equals(label)) {
                ic.commitText("\n", 1);
            } else {
                ic.commitText(output == null ? label : output, 1);
            }
        });
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, -1, weight);
        lp.setMargins(2, 2, 2, 2);
        row.addView(b, lp);
    }
}
