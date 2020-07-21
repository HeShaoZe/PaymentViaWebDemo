//
//  WebChatPayH5View.m
//  PaymentViaWebDemo
//
//  Created by Ze Shao on 2020/7/21.
//  Copyright © 2020 Ze Shao. All rights reserved.
//

#import "WebChatPayH5View.h"
#import <WebKit/WebKit.h>

@interface WebChatPayH5View ()<WKNavigationDelegate>

@property (strong, nonatomic) WKWebView *myWebView;

@property (assign, nonatomic) BOOL isLoading;

@end

@implementation WebChatPayH5View

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 1.创建webview，并设置大小
        WKWebView *webView = [[WKWebView alloc] initWithFrame:self.frame];
        webView.navigationDelegate = self;
        //最后将webView添加到界面
        [self addSubview:webView];
        self.myWebView = webView;
    }
    return self;
}

#pragma mark 加载地址
- (void)loadingURL:(NSString *)url withIsWebChatURL:(BOOL)isLoading {
    //首先要设置为NO
    self.isLoading = isLoading;
    [self.myWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    
    NSURLRequest *request = navigationAction.request;
    NSURL *url = [request URL];
    
    NSString *newUrl = url.absoluteString;
    if (!self.isLoading) {
        if ([newUrl rangeOfString:@"weixin://wap/pay"].location != NSNotFound) {
            self.isLoading = YES;
            NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
            [self.myWebView loadRequest:request];
        }
    } else {
        if ([newUrl rangeOfString:@"weixin://wap/pay"].location != NSNotFound) {
            self.myWebView = nil;
            [self applicationOpenUrl:url];
        }
    }
    
    NSDictionary *headers = [request allHTTPHeaderFields];
    BOOL hasReferer = [headers objectForKey:@"Referer"] != nil;
    if (!hasReferer) {
        // relaunch with a modified request
             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                 dispatch_async(dispatch_get_main_queue(), ^{
                     NSURL *url = [request URL];
                     NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
                     //设置授权域名
                     [request setValue:@"www.PaymentViaWebDemo.com://" forHTTPHeaderField: @"Referer"];
                     
                     [self.myWebView loadRequest:request];
                 });
             });
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)applicationOpenUrl:(NSURL *)url {
    UIApplication *application = [UIApplication sharedApplication];
    if([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        [application openURL:url options:@{}
           completionHandler:^(BOOL success) {
            NSLog(@"Open %@: %d",url,success);
        }];
    }else{
        BOOL success = [application openURL:url];
        NSLog(@"Open %@: %d",url,success);
    }
}


@end
