//
//  RootViewController.m
//  PaymentViaWebDemo
//
//  Created by Ze Shao on 2020/7/21.
//  Copyright © 2020 Ze Shao. All rights reserved.
//

#import "RootViewController.h"
#import <WebKit/WebKit.h>
#import "WebChatPayH5View.h"

@interface RootViewController ()<WKUIDelegate,WKNavigationDelegate>

//加载支付网页
@property (nonatomic, strong) WKWebView *wkVW;

@end

@implementation RootViewController
/*
 1.在Target -> Info -> URL Types设置URL Schcemes 为www.PaymentViaWebDemo.com 原因：支付完成获知取消跳回来会用到
 2.在plist中的LSApplicationQueriesSchemes添加wechat和alipay
 
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.grayColor;
    [self.view addSubview:self.wkVW];
}

#pragma mark - 用于URL编码的私有方法
//urlEncode编码
- (NSString *)urlEncodeStr:(NSString *)input {
    NSString *charactersToEscape = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\| ";
    NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
    NSString *upSign = [input stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
    return upSign;
}

//urlEncode解码
- (NSString *)decoderUrlEncodeStr: (NSString *) input {
    NSMutableString *outputStr = [NSMutableString stringWithString:input];
    [outputStr replaceOccurrencesOfString:@"+" withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[outputStr length])];
    return [outputStr stringByRemovingPercentEncoding];
}


#pragma mark - 事件方法
- (IBAction)alipaysPay:(id)sender {
    NSString *urlString = @"";
    [self.wkVW loadHTMLString:urlString baseURL:nil];
    
}


- (IBAction)weChatPay:(id)sender {
    //1.获取跳转链接这个链接一般由后台获取 例如https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?参数1=内容1&参数2e=内容2
    //2.开始加载链接
    NSString *urlString = @"https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?参数1=内容1&参数2e=内容2";
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.wkVW loadRequest:request];
}

#pragma mark - 懒加载

///加载页面的网页
-(WKWebView *)wkVW{
    if (!_wkVW) {
        
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]init];
        CGRect frame = CGRectMake(0, 200, 1, 1);
        _wkVW = [[WKWebView alloc]initWithFrame:frame configuration:config];
        _wkVW.UIDelegate = self;
        _wkVW.navigationDelegate = self;
        //开了支持滑动返回
        _wkVW.allowsBackForwardNavigationGestures = YES;
        _wkVW.backgroundColor = UIColor.redColor;
    }
    return _wkVW;
}


#pragma mark - WKWebViewDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{

    NSString *url = navigationAction.request.URL.absoluteString;
    if ([url containsString:@"https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?"]) {
        #warning 微信支付链接不要拼接redirect_url，如果拼接了还是会返回到浏览器的
        //传入的是微信支付链接：https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?prepay_id=wx201801291021026cb304f9050743178155&package=3456576571
        //这里把webView设置成一个像素点，主要是不影响操作和界面，主要的作用是设置referer和调起微信
        WebChatPayH5View *h5View = [[WebChatPayH5View alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        //url是没有拼接redirect_url微信h5支付链接
        [h5View loadingURL:url withIsWebChatURL:NO];
        [self.view addSubview:h5View];
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    //加载支付宝支付
    else
    {
        if ([navigationAction.request.URL.scheme isEqualToString:@"alipay"]) {
            //  1.以？号来切割字符串
            NSArray *urlBaseArr = [navigationAction.request.URL.absoluteString componentsSeparatedByString:@"?"];
            NSString *urlBaseStr = urlBaseArr.firstObject;
            NSString *urlNeedDecode = urlBaseArr.lastObject;
            //  2.将截取以后的Str，做一下URLDecode，方便我们处理数据
            NSMutableString *afterDecodeStr = [NSMutableString stringWithString:[self decoderUrlEncodeStr:urlNeedDecode]];
            //  3.替换里面的默认Scheme为自己的Scheme
            NSString *afterHandleStr = [afterDecodeStr stringByReplacingOccurrencesOfString:@"alipays" withString:@"www.PaymentViaWebDemo.com"];
            
            //  4.然后把处理后的，和最开始切割的做下拼接，就得到了最终的字符串
            NSString *finalStr = [NSString stringWithFormat:@"%@?%@",urlBaseStr, [self urlEncodeStr:afterHandleStr]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //  判断一下，是否安装了支付宝APP（也就是看看能不能打开这个URL）
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:finalStr]]) {
                    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:finalStr]];
                    [self applicationOpenUrl:[NSURL URLWithString:finalStr]];
                } else {
                    //未安装支付宝, 自行处理
                    NSString *url = @"itms://itunes.apple.com/cn/app/支付宝-让生活更简单/id333206289?mt=8";
                    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                    [self applicationOpenUrl:[NSURL URLWithString:url]];
                }
            });
            decisionHandler(WKNavigationActionPolicyCancel);
        }
        else
        {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
    }
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
