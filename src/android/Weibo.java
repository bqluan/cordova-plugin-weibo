package com.github.bqluan.weibo;

import android.content.Intent;
import android.util.Log;

import com.sina.weibo.sdk.WbSdk;
import com.sina.weibo.sdk.WeiboAppManager;
import com.sina.weibo.sdk.api.TextObject;
import com.sina.weibo.sdk.api.WeiboMultiMessage;
import com.sina.weibo.sdk.auth.AuthInfo;
import com.sina.weibo.sdk.auth.WbAppInfo;
import com.sina.weibo.sdk.share.WbShareCallback;
import com.sina.weibo.sdk.share.WbShareHandler;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class Weibo extends CordovaPlugin implements WbShareCallback {
    public static final String TAG = "Weibo";

    private static final String APP_KEY = "APP_KEY";
    private static final String REDIRECT_URL = "REDIRECT_URL";
    private static final String DEFAULT_REDIRECT_URL = "https://api.weibo.com/oauth2/default.html";
    private static final String SCOPE = "email,direct_messages_read,direct_messages_write,"
            + "friendships_groups_read,friendships_groups_write,statuses_to_me_read,"
            + "follow_app_official_microblog," + "invitation_write";

    private String appKey;
    private String redirectUrl;
    private WbShareHandler shareHandler;
    private CallbackContext ctx;

    public Weibo() {
    }

    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);

        appKey = webView.getPreferences().getString(APP_KEY, "");
        redirectUrl = webView.getPreferences().getString(REDIRECT_URL, DEFAULT_REDIRECT_URL);
        WbSdk.install(cordova.getActivity(), new AuthInfo(cordova.getActivity(), appKey, redirectUrl, SCOPE));
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent intent) {
        super.onActivityResult(requestCode, resultCode, intent);
        getShareHandler().doResultIntent(intent, this);
    }

    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {
        if ("isInstalled".equals(action)) {
            return isInstalled(args, callbackContext);
        } else if ("shareWebpage".equals(action)) {
            return tryToShareWebpage(args, callbackContext);
        } else {
            return false;
        }
    }

    @Override
    public void onWbShareSuccess() {
        if (ctx == null) {
            return;
        }
        ctx.success();
    }

    @Override
    public void onWbShareCancel() {
        if (ctx == null) {
            return;
        }
        ctx.error("canceled by user");
    }

    @Override
    public void onWbShareFail() {
        if (ctx == null) {
            return;
        }
        ctx.error("failed to share");
    }

    private boolean isInstalled(JSONArray args, final CallbackContext callbackContext) {
        WbAppInfo wbAppInfo = WeiboAppManager.getInstance(cordova.getActivity()).getWbAppInfo();
        callbackContext.success((wbAppInfo != null && wbAppInfo.isLegal()) ? 1 : 0);
        return true;
    }

    private boolean tryToShareWebpage(final JSONArray args, final CallbackContext callbackContext) {
        ctx = callbackContext;

        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    shareWebpage(args, callbackContext);
                } catch (JSONException e) {
                    callbackContext.error(e.getMessage());
                }
            }
        });

        return true;
    }

    private void shareWebpage(JSONArray args, final CallbackContext callbackContext) throws JSONException {
        JSONObject webpage = args.getJSONObject(0);
        String title = webpage.has("title") ? webpage.getString("title") : "";
        String url = webpage.has("url") ? webpage.getString("url") : "";
        String description = webpage.has("description") ? webpage.getString("description") : "";

        TextObject txt = new TextObject();
        txt.text = ((description == null || description.trim().equals("")) ? title : description) + " " + url;

        Log.d(TAG, "txt.text = " + txt.text);

        WeiboMultiMessage msg = new WeiboMultiMessage();
        msg.textObject = txt;

        getShareHandler().shareMessage(msg, false);
    }

    private WbShareHandler getShareHandler() {
        if (shareHandler == null) {
            shareHandler = new WbShareHandler(cordova.getActivity());
            shareHandler.registerApp();
        }
        return shareHandler;
    }
}
