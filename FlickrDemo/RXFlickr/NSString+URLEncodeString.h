//
//  NSString+URLEncodeString.h
//  IDRelease
//
//  Created by Jason Coco on 10/02/01.
//  Copyright 2010 9mmedia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NMMURLEncodeString)
- (NSString*)stringByAddingURLEncoding;
- (NSString*)stringWithOAuthEncoding;
@end
