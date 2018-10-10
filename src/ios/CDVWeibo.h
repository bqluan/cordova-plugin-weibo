#import <Cordova/CDVPlugin.h>
#import "WeiboSDK.h"

@interface CDVWeibo : CDVPlugin <WeiboSDKDelegate, WBHttpRequestDelegate>

@property (nonatomic, copy) NSString *callbackId;
@property (nonatomic, copy) NSString *redirectURI;
@property (nonatomic, copy) NSString *appKey;

- (void)shareWebpage:(CDVInvokedUrlCommand *)command;

- (void)isInstalled:(CDVInvokedUrlCommand *)command;

@end
