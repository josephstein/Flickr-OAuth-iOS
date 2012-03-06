//
//  NSString+URLEncodeString.m
//  IDRelease
//
//  Created by Jason Coco on 10/02/01.
//  Copyright 2010 9mmedia. All rights reserved.
//

#import "NSString+URLEncodeString.h"

@implementation NSString (NMMURLEncodeString)

- (NSString*)stringByAddingURLEncoding
{
  static CFStringRef specialCharacters = CFSTR("% /'\"?=&+<>;:!");
  NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, specialCharacters, kCFStringEncodingUTF8);
  return [result autorelease];
}

- (NSString*)stringWithOAuthEncoding
{
  NSMutableString *result = [NSMutableString string];
	const char *p = [self UTF8String];
	unsigned char c;
	
	for(; (c = *p); p++)
	{
		switch(c)
		{
			case '0' ... '9':
			case 'A' ... 'Z':
			case 'a' ... 'z':
			case '.':
			case '-':
			case '~':
			case '_':
				[result appendFormat:@"%c", c];
				break;
			default:
				[result appendFormat:@"%%%02X", c];
		}
	}
	return result;
}

@end