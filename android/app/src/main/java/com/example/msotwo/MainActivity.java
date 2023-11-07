package com.example.msotwo;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import android.content.Context;
import android.content.ContextWrapper;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbManager;
import android.os.BatteryManager;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;

import com.google.gson.Gson;
import com.intellego.morphosmart.driver.DeviceException;
import com.intellego.morphosmart.driver.DeviceProbe;
import com.intellego.morphosmart.driver.MorphoSmart;
import com.intellego.mykad.CardHolderInfo;
import com.intellego.mykad.MyKad;

import java.util.Date;

public class MainActivity extends FlutterActivity implements OnReadCardTaskCompleteListener {
  private static final String CHANNEL = "samples.flutter.dev/battery";
  private MorphoSmart morphoSmart;
  private DeviceProbe deviceProbe;
  private ReadCardAsyncTaskManager readCardAsyncManager;
  private MyKad mykad;

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
  super.configureFlutterEngine(flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
        .setMethodCallHandler(
            (call, result) -> {
                // This method is invoked on the main thread.
                if (call.method.equals("getBatteryLevel")) {
                  int batteryLevel = getBatteryLevel();

                  if (batteryLevel != -1) {
                    result.success(batteryLevel);
                  } else {
                    result.error("UNAVAILABLE", "Battery level not available.", null);
                  }
                }
                else if (call.method.equals("onCreate")) {
                  try {
                    deviceProbe = new DeviceProbe(this.getBaseContext());
                    result.success("Connect success");
                  } catch (DeviceException e) {
                    throw new RuntimeException(e.getMessage());
                  }

                  readCardAsyncManager = new ReadCardAsyncTaskManager(this, this);
                  readCardAsyncManager
                          .handleRetainedTask(getLastNonConfigurationInstance());
                }
                else if (call.method.equals("onReadMyKad")) {
                  if (morphoSmart == null) {
                    UsbManager usbManager = (UsbManager) this.getBaseContext()
                            .getSystemService(Context.USB_SERVICE);

                    if (deviceProbe == null){
                      throw new RuntimeException("No smart card reader attached to the system");
                    }

                    if (deviceProbe.getUsbDevice() == null){
                      throw new RuntimeException("No smart card reader attached to the system");
                    }

                    morphoSmart = new MorphoSmart(usbManager,
                            deviceProbe.getUsbDevice(), this);
                  }

                  try {
                    morphoSmart.open();
//                    readCardAsyncManager.setupTask(new ReadCardTask(getResources(),
//                            morphoSmart, true));

                    mykad = new MyKad(morphoSmart);
                    long lStartTime = new Date().getTime();

                    CardHolderInfo cardHolderInfo = new CardHolderInfo();

                    try {

                      mykad.powerUp();
                      cardHolderInfo = mykad.getCardHolderInfo(false, false);

//                      if (readPhoto) {
//                        cardHolderInfo.setPhoto(mykad.getPhoto());
//                      }
                      mykad.powerDown();

                      long lEndTime = new Date().getTime();

                      result.success(cardHolderInfo.getName());
//                      return new ReadCardResult(cardHolderInfo, true, (lEndTime - lStartTime) / 1000, "");
                    } catch (Exception e) {
                      // TODO Auto-generated catch block
                      throw new RuntimeException(e.getMessage());
                    }

                  } catch (DeviceException e) {
                    throw new RuntimeException("Error opening smartcard reader:" + e.getMessage());
                  }
                }
                else {
                  result.notImplemented();
                }
              }
        );
  }

  private int getBatteryLevel() {
    int batteryLevel = -1;
    if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
      BatteryManager batteryManager = (BatteryManager) getSystemService(BATTERY_SERVICE);
      batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY);
    } else {
      Intent intent = new ContextWrapper(getApplicationContext()).
          registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
      batteryLevel = (intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100) /
          intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1);
    }

    return batteryLevel;
  }

  @Override
  public void onTaskComplete(ReadCardTask task) {
    try {
      ReadCardResult readCardResult = task.get();

      if (readCardResult.isSuccessful()) {
        CardHolderInfo cardHolderInfo = readCardResult.getPersonalInfo();

        Gson gson = new Gson();
//        result.success(gson.toJson(cardHolderInfo));
//        MsgBox(gson.toJson(cardHolderInfo));
        return;
      } else {
        throw new RuntimeException("fail192:" + readCardResult.getErrorMessage());
      }
    }
    catch (Exception e) {
      throw new RuntimeException(e.getMessage());
    }
  }

  public void MsgBox(String response) {
    AlertDialog.Builder builder = new AlertDialog.Builder(this);
    builder.setCancelable(false); // This blocks the 'BACK' button
    builder.setMessage(response);

    builder.setNegativeButton("OK", new DialogInterface.OnClickListener() {
      public void onClick(DialogInterface dialog, int id) {
        dialog.cancel();
      }
    });

    AlertDialog alertDialog = builder.create();
    alertDialog.show();
  }
}