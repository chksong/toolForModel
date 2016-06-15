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
#include <unistd.h>
#import <CommonCrypto/CommonCryptor.h>


static unsigned int  CRCccitt_table[] =   {
    0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50A5, 0x60C6, 0x70E7,
    0x8108, 0x9129, 0xA14A, 0xB16B, 0xC18C, 0xD1AD, 0xE1CE, 0xF1EF,
    0x1231, 0x0210, 0x3273, 0x2252, 0x52B5, 0x4294, 0x72F7, 0x62D6,
    0x9339, 0x8318, 0xB37B, 0xA35A, 0xD3BD, 0xC39C, 0xF3FF, 0xE3DE,
    0x2462, 0x3443, 0x0420, 0x1401, 0x64E6, 0x74C7, 0x44A4, 0x5485,
    0xA56A, 0xB54B, 0x8528, 0x9509, 0xE5EE, 0xF5CF, 0xC5AC, 0xD58D,
    0x3653, 0x2672, 0x1611, 0x0630, 0x76D7, 0x66F6, 0x5695, 0x46B4,
    0xB75B, 0xA77A, 0x9719, 0x8738, 0xF7DF, 0xE7FE, 0xD79D, 0xC7BC,
    0x48C4, 0x58E5, 0x6886, 0x78A7, 0x0840, 0x1861, 0x2802, 0x3823,
    0xC9CC, 0xD9ED, 0xE98E, 0xF9AF, 0x8948, 0x9969, 0xA90A, 0xB92B,
    0x5AF5, 0x4AD4, 0x7AB7, 0x6A96, 0x1A71, 0x0A50, 0x3A33, 0x2A12,
    0xDBFD, 0xCBDC, 0xFBBF, 0xEB9E, 0x9B79, 0x8B58, 0xBB3B, 0xAB1A,
    0x6CA6, 0x7C87, 0x4CE4, 0x5CC5, 0x2C22, 0x3C03, 0x0C60, 0x1C41,
    0xEDAE, 0xFD8F, 0xCDEC, 0xDDCD, 0xAD2A, 0xBD0B, 0x8D68, 0x9D49,
    0x7E97, 0x6EB6, 0x5ED5, 0x4EF4, 0x3E13, 0x2E32, 0x1E51, 0x0E70,
    0xFF9F, 0xEFBE, 0xDFDD, 0xCFFC, 0xBF1B, 0xAF3A, 0x9F59, 0x8F78,
    0x9188, 0x81A9, 0xB1CA, 0xA1EB, 0xD10C, 0xC12D, 0xF14E, 0xE16F,
    0x1080, 0x00A1, 0x30C2, 0x20E3, 0x5004, 0x4025, 0x7046, 0x6067,
    0x83B9, 0x9398, 0xA3FB, 0xB3DA, 0xC33D, 0xD31C, 0xE37F, 0xF35E,
    0x02B1, 0x1290, 0x22F3, 0x32D2, 0x4235, 0x5214, 0x6277, 0x7256,
    0xB5EA, 0xA5CB, 0x95A8, 0x8589, 0xF56E, 0xE54F, 0xD52C, 0xC50D,
    0x34E2, 0x24C3, 0x14A0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
    0xA7DB, 0xB7FA, 0x8799, 0x97B8, 0xE75F, 0xF77E, 0xC71D, 0xD73C,
    0x26D3, 0x36F2, 0x0691, 0x16B0, 0x6657, 0x7676, 0x4615, 0x5634,
    0xD94C, 0xC96D, 0xF90E, 0xE92F, 0x99C8, 0x89E9, 0xB98A, 0xA9AB,
    0x5844, 0x4865, 0x7806, 0x6827, 0x18C0, 0x08E1, 0x3882, 0x28A3,
    0xCB7D, 0xDB5C, 0xEB3F, 0xFB1E, 0x8BF9, 0x9BD8, 0xABBB, 0xBB9A,
    0x4A75, 0x5A54, 0x6A37, 0x7A16, 0x0AF1, 0x1AD0, 0x2AB3, 0x3A92,
    0xFD2E, 0xED0F, 0xDD6C, 0xCD4D, 0xBDAA, 0xAD8B, 0x9DE8, 0x8DC9,
    0x7C26, 0x6C07, 0x5C64, 0x4C45, 0x3CA2, 0x2C83, 0x1CE0, 0x0CC1,
    0xEF1F, 0xFF3E, 0xCF5D, 0xDF7C, 0xAF9B, 0xBFBA, 0x8FD9, 0x9FF8,
    0x6E17, 0x7E36, 0x4E55, 0x5E74, 0x2E93, 0x3EB2, 0x0ED1, 0x1EF0
};

unsigned  short GetCrc16(const unsigned char* data_p, int len) {
    int crc = 0;
    for (int i = 0; i < len; i++) {
        crc = CRCccitt_table[((crc >> 8) ^ data_p[i]) & 0xFF] ^ ((crc << 8) & 0xFFFF);
    }
    //    byte[] temp = new byte[2];
    //    temp[0] = (byte)(crc & 0xFF);
    //    temp[1] = (byte)((crc >> 8) & 0xFF);
    // return ((ucCRCHi & 0x00FF) << 8) | (ucCRCLo & 0x00FF) & 0xFFFF;
    // return temp;
    return crc;
}


@interface MuticastViewController ()<GCDAsyncUdpSocketDelegate>
{
    dispatch_source_t heartTimer ;
}

@property (weak, nonatomic) IBOutlet UITextField *textSSID;
@property (weak, nonatomic) IBOutlet UITextField *textPasswd;

@property (nonatomic, strong) GCDAsyncUdpSocket *udpsocketSend;
@property (nonatomic ,strong) GCDAsyncUdpSocket *udpsocketRecv ;

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
    dispatch_queue_t concurrentQueue=dispatch_queue_create("com.tcl.udpqueue", 0);
 //   dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    heartTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, concurrentQueue);
    const int KeepHeartBeatInterval = 2 ;
    dispatch_source_set_timer(heartTimer, DISPATCH_TIME_NOW, KeepHeartBeatInterval * NSEC_PER_SEC, 0);
    __weak id weakSelf = self;
    dispatch_source_set_event_handler(heartTimer, ^{
        [weakSelf __sendMutiCast];
    });
   // dispatch_resume(heartTimer) ;
    
    
    //UDP socket
    self.udpsocketSend = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:concurrentQueue] ;
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
    
    _textPasswd.text = @"12345678" ;
    self.udpsocketRecv = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    if (![self.udpsocketRecv bindToPort:8710 error:&error]) {
        NSLog(@"%s  : %@" , __FUNCTION__ , error) ;
    }
    
    if (![self.udpsocketRecv beginReceiving:nil]) {
      //  return self;
    }
    
    if (![self.udpsocketRecv enableBroadcast:YES error:nil]) {
       // return self;
    }
    
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
    
    
    Byte  data_len = ((4 + strSSID.length + strPass.length + 15) / 16 ) * 16 ;
    Byte ip_2 = ((data_len / 16 -1 ) & 0x07);
    Byte ip_3 = 255 - ip_2 ;
    NSString* strMuticastIP = [NSString stringWithFormat:@"239.116.%d.%d" ,ip_2 ,ip_3] ;
    
    // 清零
    NSData *data = [NSData dataWithBytes:"" length:data_len];
    bzero((void*)data.bytes, data_len) ;
    
    Byte* data_bytes = data.bytes;
    data_bytes[0] = strSSID.length ;
    data_bytes[1] = strPass.length  ;
    
    strcpy((char*)&data_bytes[2], [strSSID UTF8String]);
    strcpy((char*)&data_bytes[2 + strSSID.length], [strPass UTF8String]);
    
    unsigned char *bytes = data.bytes ;
    NSInteger length = 2 + strSSID.length + strPass.length;
    unsigned short  crcval = GetCrc16(bytes, length);
    data_bytes[strSSID.length + strPass.length + 2] =   (crcval & 0xff );
    data_bytes[strSSID.length + strPass.length + 3] =   ((crcval >> 8)& 0xff );
    
    
    NSString *strkey = @"1234567890123456";
    char keyPtr[kCCKeySizeAES128+1] ;
    bzero(keyPtr, kCCKeySizeAES128+1) ;
    [strkey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    

    size_t bufferSize = data_len + kCCBlockSizeAES128 ;
    void*  esBuffer  = malloc(bufferSize) ;
    //加密后的
    NSData * esData ;
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, 0x0000 | kCCOptionECBMode,
                                          keyPtr, kCCKeySizeAES128,
                                          NULL /* initialization vector (optional) */,
                                          [data bytes], data_len, /* input */
                                          esBuffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
         Byte  data_len_jiami = ((numBytesEncrypted / 16 )) * 16 ;
         esData = [NSData dataWithBytes:"" length:data_len_jiami];
         bzero((void*)esData.bytes, data_len_jiami) ;
         memcpy((void*)esData.bytes, esBuffer, numBytesEncrypted) ;
    } else {
        return ;
    }
    
    
    for (int n = 0; n < 4; n++) {
        NSString* strhead = @"T" ;
        // NSData *header = [ NSData dataWithBytes:[head UTF8String] length:1] ;
        NSData *header = [strhead dataUsingEncoding:NSUTF8StringEncoding];
        for (int i = 0 ; i < 200;  i++) {
            [self.udpsocketSend sendData:header toHost:strMuticastIP port:30000 withTimeout:-1 tag:i];
            usleep(2000);
        }
     
        for (int i=0; i < 20; i++) {
            Byte cnt = 7 ;
            NSUInteger len = esData.length ;
            Byte* data_bytes = esData.bytes;
            for (int j = 0 ; j < len; j+=2) {
                Byte ip_1 = cnt++ ;
                Byte ip_2 = data_bytes[j] ;
                Byte ip_3 = data_bytes[j+1] ;
                
                NSString* strMuticastIP = [NSString stringWithFormat:@"239.%d.%d.%d" ,ip_1, ip_2 ,ip_3] ;
                
                [self.udpsocketSend sendData:data toHost:strMuticastIP port:30000 withTimeout:-1 tag:j];
                usleep(1000);
            }
            
            usleep(10000);
        }
        

    }
    
    
    NSLog(@"%s --- end", __FUNCTION__);
    
}

//特使出差网络环境
- (IBAction)SendMutiCast:(id)sender {
    
    NSString *strWifi  =[self networkingStateFromStatebar];
    UIAlertController *ctrl = [UIAlertController alertControllerWithTitle:@"debug" message:strWifi preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *act  = [UIAlertAction actionWithTitle:@"Done" style:(UIAlertActionStyleDefault) handler:nil];
    [ctrl addAction:act];
    [self presentViewController:ctrl animated:YES completion:nil];
}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext {
    
    NSString *strRecvIP = nil;
    uint16_t port = 0;
    [GCDAsyncUdpSocket getHost:&strRecvIP port:&port fromAddress:address];
  
    NSLog(@"strRecvIP=%@  port=%d" , strRecvIP , port);
    
    NSString *strRecv = [[NSString alloc] initWithData:data   encoding:NSASCIIStringEncoding];
    
    NSString *strcmp = [NSString stringWithFormat:@"%@,%@\n", self.textSSID.text , self.textPasswd.text] ;
    
    if (  0 == [strcmp caseInsensitiveCompare:strRecv]) {
        dispatch_suspend(heartTimer) ;
    }
}

@end
