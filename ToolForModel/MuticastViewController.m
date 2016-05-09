//
//  MuticastViewController.m
//  ToolForModel
//
//  Created by chksong on 16/5/4.
//  Copyright © 2016年 TCL. All rights reserved.
//

#import "MuticastViewController.h"
#import "GCDAsyncUdpSocket.h" // for UDP
#import <SystemConfiguration/CaptiveNetwork.h>
#import <NetworkExtension/NetworkExtension.h>


@interface MuticastViewController ()<GCDAsyncUdpSocketDelegate>
{
    dispatch_source_t heartTimer ;
}

@property (weak, nonatomic) IBOutlet UITextField *textSSID;
@property (weak, nonatomic) IBOutlet UITextField *textPasswd;

@property (nonatomic, strong) GCDAsyncUdpSocket *udpsocketSend;

@end

@implementation MuticastViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
  
        
      //  NSError *error ;
     //   [self.udpsocketSend joinMulticastGroup:@"" error:&error];
        
     
        
    }
    return self;
}

//j获得网络状态方法
-(NSString*) networkingStateFromStatebar {
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *childrens = [[[app valueForKey:@"statusBar"] valueForKey:@"foregroundView"] subviews];
    
    int type = 0;
    for(id child in childrens) {
        if ([child isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
            type = [[child valueForKey:@"dataNetworkType"] intValue];
        }
    }
    
    NSString *stateString = @"wifi" ;
    switch (type) {
        case 0:
            stateString = @"notReachable" ;
            break;
        case 1:
            stateString = @"2G" ;
            break;
        case 2:
            stateString = @"3G" ;
            break ;
        case 3 :
            stateString = @"4G" ;
            break ;
        case 4:
            stateString = @"LTE" ;
            break ;
        case 5:
            stateString = @"Wifi" ;
            break;
        default:
            break;
    }
    
    NSLog(@"%s   %@" , __FUNCTION__ , stateString) ;
    return  stateString ;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textSSID.text = [self fetchSSIDInfo];
    
    //初始化定时器
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    heartTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, concurrentQueue);
    const int KeepHeartBeatInterval = 10 ;
    dispatch_source_set_timer(heartTimer, DISPATCH_TIME_NOW, KeepHeartBeatInterval * NSEC_PER_SEC, 0);
    __weak id weakSelf = self;
    dispatch_source_set_event_handler(heartTimer, ^{
        [weakSelf __sendMutiCast];
    });
   // dispatch_resume(heartTimer) ;
    
    
    //UDP socket
    self.udpsocketSend = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()] ;
    NSError *error ;
   [self.udpsocketSend bindToPort:0 error:&error];
    bool bRet ;
    bRet = [self.udpsocketSend enableBroadcast:YES error:&error];
    if (! bRet || nil != error) {
        NSLog(@"UPD Enable Broadcast Error: %@", [error description]);

    }
    
//    bRet = [self.udpsocketSend beginReceiving:&error];
//    if (! bRet || nil != error) {
//        NSLog(@"UPD Begin Recive Error: %@", [error description]);
//    }
    
    
 }

-(void) viewDidUnload {
    
    heartTimer = nil ;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



-(void) viewDidDisappear:(BOOL)animated {
    dispatch_suspend(heartTimer) ;
}

-(void) viewDidAppear:(BOOL)animated {
    NSString *strWifi  =[self networkingStateFromStatebar];
    if ([strWifi caseInsensitiveCompare:@"wifi"]) {
        
        UIAlertController *ctrl = [UIAlertController alertControllerWithTitle:@"警告" message:@"当前不是在WiFi的网络环境中" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *act  = [UIAlertAction actionWithTitle:@"Done" style:(UIAlertActionStyleDefault) handler:nil];
        [ctrl addAction:act];
        
        [self presentViewController:ctrl animated:YES completion:nil];
    }
    else
    {
        dispatch_resume(heartTimer) ;
    }
}

-(NSString*) fetchSSIDInfo
{
    NSString *ssid = @"Not Found";
    NSString *macIp = @"Not Found";
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray != nil) {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        if (myDict != nil) {
            NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
            
            ssid = [dict valueForKey:@"SSID"];
            macIp = [dict valueForKey:@"BSSID"];
        }
    }
    
//    NSArray * networkInterfaces = [NEHotspotHelper supportedNetworkInterfaces];
//    NSLog(@"Networks %@",networkInterfaces);
//    
////    for(NEHotspotNetwork *hotspotNetwork in networkInterfaces) {
////        NSString *ssid = hotspotNetwork.SSID;
////        NSString *bssid = hotspotNetwork.BSSID;
////        BOOL secure = hotspotNetwork.secure;
////        BOOL autoJoined = hotspotNetwork.autoJoined;
////        double signalStrength = hotspotNetwork.signalStrength;
////        
////       
////    }
    
    return ssid ;
}


-(void) __sendMutiCast {
    NSLog(@"%s", __FUNCTION__);
    
    
   //不是wifi
    NSString *strWifi  =[self networkingStateFromStatebar];
    if ([strWifi caseInsensitiveCompare:@"wifi"]) {
        return;
    }
    

    NSError* error ;
    BOOL bRet ;
   // [self.udpsocketSend enableBroadcast:YES error:&error];
  //  [self.udpsocketSend joinMulticastGroup:@"192.168.0.1" error:&error];
  //  [self.udpsocketSend beginReceiving:&error];
    
    NSString *strSSID  = self.textSSID.text;
    NSString *strPass = self.textPasswd.text ;
    
    
    Byte  data_len = ((2 + strSSID.length + strPass.length + 15) / 16 ) * 16 ;
    Byte ip_2 = data_len / 16 -1 ;
    Byte ip_3 = 255 - ip_2 ;
    NSString* strMuticastIP = [NSString stringWithFormat:@"239.116.%d.%d" ,ip_2 ,ip_3] ;
    
    NSData *data = [NSData dataWithBytes:"" length:data_len];
    Byte* data_bytes = data.bytes;
    data_bytes[0] = strSSID.length ;
    data_bytes[1] = strPass.length  ;
    
    strcpy((char*)&data_bytes[2], [strSSID UTF8String]);
    strcpy((char*)&data_bytes[2 + strSSID.length], [strPass UTF8String]);
    
    
    for (int n = 0; n < 10; n++) {
       // bRet = [self.udpsocketSend joinMulticastGroup:strMuticastIP error:&error];
//        if (! bRet || nil != error) {
//            NSLog(@"UPD Join Multicast Error: %@", [error description]);
//            break;
//        }
        
        NSString* strhead = @"T" ;
        // NSData *header = [ NSData dataWithBytes:[head UTF8String] length:1] ;
        NSData *header = [strhead dataUsingEncoding:NSUTF8StringEncoding];
        for (int i = 0 ; i < 20;  i++) {
             [self.udpsocketSend sendData:header toHost:strMuticastIP port:30000 withTimeout:-1 tag:i];
         }
     
//        bRet = [self.udpsocketSend leaveMulticastGroup:strMuticastIP error:&error];
//        if (! bRet || nil != error)
//        {
//            NSLog(@"UPD EleaveMulticastGroup Error: %@", [error description]);
//            break;
//        }
    }
    
    
    
    
}

//特使出差网络环境
- (IBAction)SendMutiCast:(id)sender {
    
    NSString *strWifi  =[self networkingStateFromStatebar];
    UIAlertController *ctrl = [UIAlertController alertControllerWithTitle:@"debug" message:strWifi preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *act  = [UIAlertAction actionWithTitle:@"Done" style:(UIAlertActionStyleDefault) handler:nil];
    [ctrl addAction:act];
    [self presentViewController:ctrl animated:YES completion:nil];
}


@end
