#import "CDVWeibo.h"

NSString *WEIBO_APP_KEY = @"weibo_app_key";
NSString *WEBIO_REDIRECT_URI = @"redirecturi";
NSString *WEBIO_DEFUALT_REDIRECT_URI = @"https://api.weibo.com/oauth2/default.html";
NSString *WEIBO_CANCEL_BY_USER = @"cancel by user";
NSString *WEIBO_SHARE_INSDK_FAIL = @"share in sdk failed";
NSString *WEIBO_SEND_FAIL = @"send failed";
NSString *WEIBO_UNSPPORTTED = @"Weibo unspport";
NSString *WEIBO_AUTH_ERROR = @"Weibo auth error";
NSString *WEIBO_UNKNOW_ERROR = @"Weibo unknow error";
NSString *WEIBO_TOKEN_EMPTY = @"Weibo token is empty";
NSString *WEIBO_USER_CANCEL_INSTALL = @"user cancel install weibo";

@implementation CDVWeibo
/**
 *  插件初始化主要用于appkey的注册
 */
- (void)pluginInitialize {
    NSString *appKey = [[self.commandDelegate settings] objectForKey:WEIBO_APP_KEY];
    self.appKey = appKey;
    [WeiboSDK registerApp:appKey];
    NSString *redirectURI = [[self.commandDelegate settings] objectForKey:WEBIO_REDIRECT_URI];
    if (nil == redirectURI) {
        self.redirectURI = WEBIO_DEFUALT_REDIRECT_URI;
    } else {
        self.redirectURI = redirectURI;
    }
}
/**
 *  检查微博官方客户端是否安装
 *
 *  @param command CDVInvokedUrlCommand
 */
- (void)isInstalled:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[WeiboSDK isWeiboAppInstalled]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

/**
 *  分享网页到微博
 */
 - (void)shareWebpage:(CDVInvokedUrlCommand *)command {
     self.callbackId = command.callbackId;

     WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
     authRequest.redirectURI = self.redirectURI;
     authRequest.scope = @"all";

     NSDictionary *params = [command.arguments objectAtIndex:0];

     WBWebpageObject *webpage = [WBWebpageObject object];
     webpage.objectID = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
     webpage.title = [self check:@"title" in:params];
     webpage.description = [NSString stringWithFormat:[self check:@"description" in:params], [[NSDate date] timeIntervalSince1970]];
     webpage.webpageUrl = [self check:@"url" in:params];

     WBMessageObject *message = [WBMessageObject message];
     message.mediaObject = webpage;

     NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
     NSString *token = [saveDefaults objectForKey:@"access_token"];
     WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message authInfo:authRequest access_token:token];
     request.userInfo = @{ @"ShareMessageFrom" : @"CDVWeibo",
                           @"Other_Info_1" : [NSNumber numberWithInt:123],
                           @"Other_Info_2" : @[ @"obj1", @"obj2" ],
                           @"Other_Info_3" : @{@"key1" : @"obj1", @"key2" : @"obj2"} };
     [WeiboSDK sendRequest:request];
 }

/**
 *  处理URL
 *
 *  @param notification cordova传递的消息对象
 */
- (void)handleOpenURL:(NSNotification *)notification {
    NSURL *url = [notification object];
    if ([url isKindOfClass:[NSURL class]] && [url.absoluteString hasPrefix:[@"wb" stringByAppendingString:self.appKey]]) {
        [WeiboSDK handleOpenURL:url delegate:self];
    }
}

#pragma mark - WeiboSDKDelegate
- (void)didReceiveWeiboResponse:(WBBaseResponse *)response {
    if ([response isKindOfClass:WBSendMessageToWeiboResponse.class]) {
        if (response.statusCode == WeiboSDKResponseStatusCodeSuccess) {
            WBSendMessageToWeiboResponse *sendMessageToWeiboResponse = (WBSendMessageToWeiboResponse *)response;
            NSString *accessToken = [sendMessageToWeiboResponse.authResponse accessToken];
            NSString *userId = [sendMessageToWeiboResponse.authResponse userID];
            NSString *expirationTime = [NSString stringWithFormat:@"%f", [sendMessageToWeiboResponse.authResponse.expirationDate timeIntervalSince1970] * 1000];
            if (accessToken && userId && expirationTime) {
                NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
                [saveDefaults setValue:accessToken forKey:@"access_token"];
                [saveDefaults setValue:userId forKey:@"userId"];
                [saveDefaults setValue:expirationTime forKey:@"expires_time"];
                [saveDefaults synchronize];
            }
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeUserCancel) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_CANCEL_BY_USER];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeSentFail) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_SEND_FAIL];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeShareInSDKFailed) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_SHARE_INSDK_FAIL];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeUnsupport) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_UNSPPORTTED];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeUnknown) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_UNKNOW_ERROR];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeAuthDeny) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_AUTH_ERROR];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeUserCancelInstall) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_USER_CANCEL_INSTALL];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        }
    } else if ([response isKindOfClass:WBAuthorizeResponse.class]) {
        if (response.statusCode == WeiboSDKResponseStatusCodeSuccess) {
            NSMutableDictionary *Dic = [NSMutableDictionary dictionaryWithCapacity:2];
            [Dic setObject:[(WBAuthorizeResponse *)response userID] forKey:@"userId"];
            [Dic setObject:[(WBAuthorizeResponse *)response accessToken] forKey:@"access_token"];
            [Dic setObject:[NSString stringWithFormat:@"%f", [(WBAuthorizeResponse *)response expirationDate].timeIntervalSince1970 * 1000] forKey:@"expires_time"];
            NSUserDefaults *saveDefaults = [NSUserDefaults standardUserDefaults];
            [saveDefaults setValue:[(WBAuthorizeResponse *)response userID] forKey:@"userId"];
            [saveDefaults setValue:[(WBAuthorizeResponse *)response accessToken] forKey:@"access_token"];
            [saveDefaults setValue:[NSString stringWithFormat:@"%f", [(WBAuthorizeResponse *)response expirationDate].timeIntervalSince1970 * 1000] forKey:@"expires_time"];
            [saveDefaults synchronize];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:Dic];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeUserCancel) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_CANCEL_BY_USER];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeSentFail) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_SEND_FAIL];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeShareInSDKFailed) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_SHARE_INSDK_FAIL];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeUnsupport) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_UNSPPORTTED];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeUnknown) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_UNKNOW_ERROR];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeAuthDeny) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_AUTH_ERROR];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        } else if (response.statusCode == WeiboSDKResponseStatusCodeUserCancelInstall) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEIBO_USER_CANCEL_INSTALL];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        }
    }
}

- (void)didReceiveWeiboRequest:(WBBaseRequest *)request {
}

#pragma mark - WBHttpRequestDelegate

- (void)request:(WBHttpRequest *)request didFinishLoadingWithResult:(NSString *)result {
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

- (void)request:(WBHttpRequest *)request didFailWithError:(NSError *)error {
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

/**
 检查参数是否存在

 @param param 要检查的参数
 @param args 参数字典
 @return 参数
 */
- (NSString *)check:(NSString *)param in:(NSDictionary *)args {
    NSString *data = [args objectForKey:param];
    return data?data:@"";
}
@end
