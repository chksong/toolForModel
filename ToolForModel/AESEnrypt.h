//
//  AESEnrypt.h
//  ToolForModel
//
//  Created by chksong on 16/6/14.
//  Copyright © 2016年 TCL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AESEnrypt : NSObject

+ (NSString*) AES128Encrypt:(NSString *)plainText;

+ (NSString*) AES128Decrypt:(NSString *)encryptText;

@end
