package com.qz.gertec_pos_printer;

import android.content.Context;
import android.os.RemoteException;
import android.util.Log;

import androidx.annotation.NonNull;

import com.qz.gertec_pos_printer.gertec.GertecPrinter;
import com.qz.gertec_pos_printer.sku210.GertecPrinter210;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** GertecPosPrinterPlugin */
public class GertecPosPrinterPlugin implements FlutterPlugin, MethodCallHandler {

  private MethodChannel channel;
  private Context context;
  private Object gertecPrinterObj;
  private GertecPrinter210 printer210;
  private Response response;

  private GertecPrinter getGertecPrinter() {
    if (gertecPrinterObj == null) {
      try {
        gertecPrinterObj = new GertecPrinter(this.context);
      } catch (Throwable t) {
        Log.e("GERTEC_PLUGIN", "FALHA GPOS700: " + t.toString());
      }
    }
    return (GertecPrinter) gertecPrinterObj;
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "qz_gertec_printer");
    context = flutterPluginBinding.getApplicationContext();
    channel.setMethodCallHandler(this);
    printer210 = new GertecPrinter210(context);
    response = new Response();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    // Log minimal para evitar overhead mas confirmar atividade
    if (!call.method.equals("callPrintBitmap210")) {
      Log.d("GERTEC_PLUGIN", "Método: " + call.method);
    }

    try {
      if (call.method.equals("callStatusGertec")) {
        GertecPrinter gp = getGertecPrinter();
        result.success(response.send("success", gp != null ? gp.getStatusImpressora() : "OFFLINE", true));
      } else if (call.method.equals("callPrint210")) {
        printer210.printTextCustom((Map) call.arguments);
        result.success(response.send("success", "", true));
      } else if (call.method.equals("callPrintTextList210")) {
        printer210.printTextListCustom((List<Map>) call.argument("params"));
        result.success(response.send("success", "", true));
      } else if (call.method.equals("callPrintBitmap210")) {
        byte[] bitmapBytes = (byte[]) call.argument("bitmap");
        android.graphics.Bitmap bitmap = android.graphics.BitmapFactory.decodeByteArray(bitmapBytes, 0,
            bitmapBytes.length);
        printer210.printBitmapCustom(bitmap);
        result.success(response.send("success", "", true));
      } else if (call.method.equals("callCut210")) {
        int r = printer210.cut((int) call.argument("mode"));
        result.success(response.send("success", r, true));
      } else if (call.method.equals("callPrinterWrap210")) {
        printer210.wrap((int) call.argument("linesWrap"));
        result.success(response.send("success", "", true));
      } else if (call.method.equals("callPrinterStatus210")) {
        result.success(response.send("success", printer210.getPrinterStatus(), true));
      } else if (call.method.equals("callPrinterBarcode210")) {
        printer210.printBarcode((HashMap) call.argument("params"));
        result.success(response.send("success", "", true));
      } else if (call.method.equals("callPrinterQRCode210")) {
        printer210.printerQRCode((HashMap) call.argument("params"));
        result.success(response.send("success", "", true));
      } else {
        result.notImplemented();
      }
    } catch (Exception e) {
      Log.e("GERTEC_PLUGIN", "ERRO EM " + call.method + ": " + e.toString());
      result.success(response.send("Error", e.getMessage(), false));
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
    }
  }

  private class Response {
    public Map<String, Object> send(String status, Object msg, boolean success) {
      Map<String, Object> map = new HashMap<>();
      map.put("status", status);
      map.put("message", msg);
      map.put("success", success);
      return map;
    }
  }
}
