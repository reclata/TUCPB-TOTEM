package com.qz.gertec_pos_printer.sku210;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.RemoteException;
import android.util.Log;

import com.topwise.cloudpos.aidl.printer.AidlPrinter;
import com.topwise.cloudpos.aidl.printer.AidlPrinterListener;
import com.topwise.cloudpos.aidl.printer.PrintCuttingMode;
import com.topwise.cloudpos.aidl.printer.PrintItemObj;
import com.topwise.cloudpos.data.PrinterConstant;

import com.qz.gertec_pos_printer.sku210.DeviceServiceManager;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

public class GertecPrinter210 {
    private Context context;
    private AidlPrinter printer;

    private AidlPrinterListener mListen = new AidlPrinterListener.Stub() {
        @Override
        public void onError(int i) throws RemoteException {
            Log.d("FLUTTER", "onError: " + i);
        }

        @Override
        public void onPrintFinish() throws RemoteException {
        }
    };

    public GertecPrinter210(Context context) {
        this.context = context;
        try {
            printer = DeviceServiceManager.getInstance().getPrintManager(context);
        } catch (Exception e) {
            Log.e("GERTEC_SK210", "Erro init: " + e.toString());
        }
    }

    public boolean wrap(int times) throws RemoteException {
        if (printer == null)
            return false;
        printer.goPaper(times);
        return true;
    }

    public void printerQRCode(HashMap map) throws RemoteException {
        if (printer == null)
            return;
        String text = (String) map.get("textQRCode");
        // Tentativa de assinatura mais comum se addRuiQRCode falhar
        try {
            printer.addRuiQRCode(text, 240, 240);
        } catch (Throwable t) {
            Log.e("GERTEC_SK210", "Erro addRuiQRCode");
        }
        printer.printRuiQueue(mListen);
    }

    public void printBarcode(HashMap map) throws RemoteException {
        if (printer == null)
            return;
        String text = (String) map.get("message");
        printer.printBarCode(120, 120, 0, 73, text, mListen);
    }

    public int cut(int mode) throws RemoteException {
        if (printer == null)
            return -1;
        return printer
                .cuttingPaper(mode == 1 ? PrintCuttingMode.CUTTING_MODE_HALT : PrintCuttingMode.CUTTING_MODE_FULL);
    }

    public int getPrinterStatus() throws RemoteException {
        if (printer == null)
            return -1;
        return printer.getPrinterState();
    }

    private int getInt(Object value, int defaultValue) {
        if (value == null)
            return defaultValue;
        try {
            if (value instanceof Number)
                return ((Number) value).intValue();
            if (value instanceof String)
                return Integer.parseInt((String) value);
        } catch (Exception e) {
        }
        return defaultValue;
    }

    public void printTextCustom(Map map) throws RemoteException {
        if (map == null || printer == null)
            return;
        List<Map> list = new ArrayList<>();
        list.add(map);
        printTextListCustom(list);
    }

    public void printTextListCustom(List<Map> list) throws RemoteException {
        if (list == null || printer == null)
            return;
        try {
            List<PrintItemObj> items = new ArrayList<>();
            for (Map map : list) {
                String text = (String) map.get("message");
                if (text == null)
                    text = " ";
                int fontSize = getInt(map.get("fontSize"), PrinterConstant.FontSize.NORMAL);
                // Usando construtor simples para evitar problemas com enums de alinhamento
                items.add(new PrintItemObj(text, fontSize));
            }
            // addRuiText recebe a lista no SK210
            printer.addRuiText(items);
            printer.printRuiQueue(mListen);
        } catch (Exception e) {
            Log.e("GERTEC_SK210", "Erro printTextList: " + e.toString());
        }
    }

    public void printBitmapCustom(Bitmap bitmap) throws RemoteException {
        if (bitmap == null || printer == null)
            return;
        try {
            Log.i("GERTEC_SK210", "Motor Gráfico (printBmp 5-params)...");
            final CountDownLatch latch = new CountDownLatch(1);
            AidlPrinterListener listener = new AidlPrinterListener.Stub() {
                @Override
                public void onError(int i) throws RemoteException {
                    latch.countDown();
                }

                @Override
                public void onPrintFinish() throws RemoteException {
                    latch.countDown();
                }
            };

            // CORREÇÃO: Usando 5 parâmetros identificados no log (int, int, int, Bitmap,
            // Listener)
            // Geralmente: (leftOffset, width, height, bitmap, listener)
            printer.printBmp(0, bitmap.getWidth(), bitmap.getHeight(), bitmap, listener);

            latch.await(20, TimeUnit.SECONDS);
        } catch (Exception e) {
            Log.e("GERTEC_SK210", "Erro Bitmap: " + e.toString());
        }
    }
}
