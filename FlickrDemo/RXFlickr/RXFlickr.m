//
//  RXFlickr.m
//
//  Created by Joseph Stein on 12/19/11.
//  Copyright (c) 2011, 9mmedia LLC. All rights reserved
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <CommonCrypto/CommonHMAC.h>
#import "RXFlickr.h"
#import "NSData+Base64.h"
#import "NSString+URLEncodeString.h"

typedef enum {
  FlickrOAuthStateRequestToken,
  FlickrOAuthStateAccessToken
} FlickrOAuthState;

static NSString* kRequestTokenBaseURL = @"http://www.flickr.com/services/oauth/request_token";
static NSString* kAuthorizeBaseURL    = @"http://www.flickr.com/services/oauth/authorize";
static NSString* kAccessTokenBaseURL  = @"http://www.flickr.com/services/oauth/access_token";

@interface RXFlickr () {
  NSString* _consumerKey;
  NSString* _consumerSecret;
  NSString* _callbackURL;
  
  FlickrOAuthState _currentState;
  NSMutableData* _receivedData;
}
@end

@implementation RXFlickr

@synthesize webView = _webView;
@synthesize delegate = _delegate;

@synthesize token = _token;
@synthesize tokenSecret = _tokenSecret;

#pragma mark - Initialization / Memory Management

- (id)initWithConsumerKey:(NSString*)consumerKey secret:(NSString*)consumerSecret callbackURL:(NSString*)callbackURL
{
  NSParameterAssert(consumerKey);
  NSParameterAssert(consumerSecret);
  NSParameterAssert(callbackURL);
  
  self = [super init];
  if (self) {
    _consumerKey = [consumerKey retain];
    _consumerSecret = [consumerSecret retain];
    _callbackURL = [callbackURL retain];
  }
  return self;
}

- (void)dealloc 
{
  [_consumerKey release];
  [_consumerSecret release];
  [_callbackURL release];
  [_webView release];
  
  [super dealloc];
}

#pragma mark - Utility Methods

- (NSString*)extractVerifierFromURL:(NSURL*)url
{
  NSArray* parameters = [[url absoluteString] componentsSeparatedByString:@"&"];
  NSArray* keyValue = [[parameters objectAtIndex:1] componentsSeparatedByString:@"="];
  NSString* verifier = [keyValue objectAtIndex:1];
  return verifier;
}

- (NSString*)flickr_oauthSignatureFor:(NSString*)dataString withKey:(NSString*)secret
{
  NSData* secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
  NSData* stringData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
  
  const void* keyBytes = [secretData bytes];
  const void* dataBytes = [stringData bytes];
  void* outs = malloc(CC_SHA1_DIGEST_LENGTH);
  CCHmac(kCCHmacAlgSHA1, keyBytes, [secretData length], dataBytes, [stringData length], outs);
  
  NSData* signatureData = [NSData dataWithBytesNoCopy:outs length:CC_SHA1_DIGEST_LENGTH freeWhenDone:YES];
  return [signatureData base64EncodedString];
}

- (NSString*)sortedURLStringFromDictionary:(NSDictionary*)dictionary urlEscape:(BOOL)urlEscape 
{
  NSMutableArray* pairs = [NSMutableArray array];
  NSArray* keys = [[dictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
  for (NSString *key in keys) {
    NSString *value = [dictionary objectForKey:key];
    CFStringRef escapedValue = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)value, NULL, CFSTR("%:/?#[]@!$&'()*+,;="), kCFStringEncodingUTF8);
    NSMutableString *pair = [[key mutableCopy] autorelease];
    [pair appendString:@"="];
    [pair appendString:(NSString *)escapedValue];
    [pairs addObject:pair];
    CFRelease(escapedValue);
  }
  NSString *URLString = (_currentState == FlickrOAuthStateRequestToken) ? kRequestTokenBaseURL : kAccessTokenBaseURL;
  if (urlEscape) {
    URLString = [URLString stringByAddingURLEncoding];
  }
  
  NSMutableString *mURLString = [[URLString mutableCopy] autorelease];
  [mURLString appendString:(urlEscape ? @"&" : @"?")];
  NSString *args = [pairs componentsJoinedByString:@"&"];
  if( urlEscape ) { args = [args stringByAddingURLEncoding]; }
  [mURLString appendString:args];
  
  return mURLString;
}

- (void)handleCallBackURL:(NSURL*)url
{
  _currentState = FlickrOAuthStateAccessToken;
  
  CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
  NSString* nonce = (NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuid);
  CFRelease(uuid);
  NSString* timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
  NSString* signatureMethod = [NSString stringWithString:@"HMAC-SHA1"];
  NSString* version = [NSString stringWithString:@"1.0"];
  NSString* verifier = [self extractVerifierFromURL:url];
  
  NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:nonce, @"oauth_nonce", timestamp, @"oauth_timestamp", verifier, @"oauth_verifier", _consumerKey, @"oauth_consumer_key", signatureMethod, @"oauth_signature_method", version, @"oauth_version", _token, @"oauth_token", nil];
  NSString* urlStringBeforeSignature = [self sortedURLStringFromDictionary:parameters urlEscape:YES];
  
  NSString* signature = [NSString stringWithFormat:@"GET&%@", urlStringBeforeSignature];
  NSString* signatureString = [self flickr_oauthSignatureFor:signature withKey:[NSString stringWithFormat:@"%@&%@", _consumerSecret, _tokenSecret]]; //[_consumerSecret stringByAppendingString:@"&"]];
  
  [parameters setValue:signatureString forKey:@"oauth_signature"];
  NSString* urlStringWithSignature = [self sortedURLStringFromDictionary:parameters urlEscape:NO];
  
  NSMutableURLRequest* req = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStringWithSignature]] autorelease];
  NSURLConnection* connection = [[[NSURLConnection alloc] initWithRequest:req delegate:self] autorelease];
  _receivedData = [[NSMutableData data] retain];
  [connection start];
  [nonce release];
}

#pragma mark - Public Methods

- (void)startAuthorization
{
  NSParameterAssert(_webView != nil);
  _currentState = FlickrOAuthStateRequestToken;
  
  CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
  NSString* nonce = (NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuid);
  CFRelease(uuid);
  NSString* timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
  NSString* signatureMethod = [NSString stringWithString:@"HMAC-SHA1"];
  NSString* version = [NSString stringWithString:@"1.0"];

  NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:nonce, @"oauth_nonce", timestamp, @"oauth_timestamp", _consumerKey, @"oauth_consumer_key", signatureMethod, @"oauth_signature_method", version, @"oauth_version", _callbackURL, @"oauth_callback", nil];
  NSString* urlStringBeforeSignature = [self sortedURLStringFromDictionary:parameters urlEscape:YES];
  
  NSString* signature = [NSString stringWithFormat:@"GET&%@", urlStringBeforeSignature];
  NSString* signatureString = [self flickr_oauthSignatureFor:signature withKey:[_consumerSecret stringByAppendingString:@"&"]];
  
  [parameters setValue:signatureString forKey:@"oauth_signature"];
  NSString* urlStringWithSignature = [self sortedURLStringFromDictionary:parameters urlEscape:NO];
  
  NSMutableURLRequest* req = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStringWithSignature]] autorelease];
  NSURLConnection* connection = [[[NSURLConnection alloc] initWithRequest:req delegate:self] autorelease];
  _receivedData = [[NSMutableData data] retain];
  [connection start];
  
  [nonce release];
}

#pragma mark - UIWebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
  NSURL* url = [request URL];
  NSURL* callbackURL = [NSURL URLWithString:_callbackURL];
  if ([[url host] isEqualToString:[callbackURL host]]) {
    [self handleCallBackURL:url];
    return NO;
  }
  return YES;
}

#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  [_receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [_receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  if (_currentState == FlickrOAuthStateRequestToken) {
    NSString* response = [[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding];
    NSArray* parameters = [response componentsSeparatedByString:@"&"];
    NSLog(@"parameters = %@", parameters);
    NSMutableDictionary* d = [NSMutableDictionary dictionary];
    [parameters enumerateObjectsUsingBlock:^(NSString* element, NSUInteger idx, BOOL *stop) {
      NSArray* array = [element componentsSeparatedByString:@"="];
      NSString* key = [array objectAtIndex:0];
      NSString* value = [array objectAtIndex:1];
      [d setValue:value forKey:key];
    }];
    if ([[d objectForKey:@"oauth_callback_confirmed"] boolValue] == YES) {
      _token = [[d objectForKey:@"oauth_token"] retain];
      _tokenSecret = [[d objectForKey:@"oauth_token_secret"] retain];
      NSString* urlString = [NSString stringWithFormat:@"%@?oauth_token=%@&perms=%@", kAuthorizeBaseURL, _token, @"read"];
      [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    } else {
      if ([_delegate respondsToSelector:@selector(flickrDidNotAuthorize:)]) {
        [_delegate flickrDidNotAuthorize:self];
      }
    }
    [_receivedData release];
    [response release];
  } else {
    NSString* response = [[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding];
    NSArray* parameters = [response componentsSeparatedByString:@"&"];
    NSLog(@"parameters = %@", parameters);
    NSMutableDictionary* d = [NSMutableDictionary dictionary];
    [parameters enumerateObjectsUsingBlock:^(NSString* element, NSUInteger idx, BOOL *stop) {
      NSArray* array = [element componentsSeparatedByString:@"="];
      NSString* key = [array objectAtIndex:0];
      NSString* value = [array objectAtIndex:1];
      [d setValue:value forKey:key];
    }];
    if ([[d objectForKey:@"username"] length] > 0) {
      if (_token) [_token release];
      if (_tokenSecret) [_tokenSecret release];
      _token = [[d objectForKey:@"oauth_token"] retain];
      _tokenSecret = [[d objectForKey:@"oauth_token_secret"] retain];
      if ([_delegate respondsToSelector:@selector(flickrDidAuthorize:)]) {
        [_delegate flickrDidAuthorize:self];
      }
    } else {
      if ([_delegate respondsToSelector:@selector(flickrDidNotAuthorize:)]) {
        [_delegate flickrDidNotAuthorize:self];
      }
    }
    
    [_receivedData release];
    [response release];
  }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  [_receivedData release];
}

#pragma mark - Public Properties

- (void)setWebView:(UIWebView *)webView
{
  if (_webView) [_webView release];
  _webView = [webView retain];
  [_webView setDelegate:self];
  [_webView setScalesPageToFit:YES];
}

@end
