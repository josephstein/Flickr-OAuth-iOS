//
//  RXFlickr.h
//
//  Created by Joseph Stein on 12/19/11.
//  Copyright (c) 2011, 9mmedia LLC. All rights reserved
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>

@class RXFlickr;

/*!
 * @protocol RXFlickrDelegate
 * @abstract The RXFlickrDelegate protocol defines two methods that a delegate of a RXFlickr 
 * object must implement to notify if authorization has succeeded or failed.
 */
@protocol RXFlickrDelegate <NSObject>
@required

/*!
 @method flickrDidAuthorize:
 @abstract Send after user successfully completes authorization process
 */
- (void)flickrDidAuthorize:(RXFlickr*)flickr;

/*!
 @method flickrDidNotAuthorize:
 @abstract Send after user unsuccessfully complete authorization process
 */
- (void)flickrDidNotAuthorize:(RXFlickr*)flickr;
@end

/*!
 * @class RXFlickr
 * @abstract Convenience class for retreiving a Flickr user's authorization details
 * @discussion This class provides a simple way for gaining a Flickr user's access token
 * and token secret necessary for making any further API calls. It goes through
 * the OAuth flow of retreving a request token, getting a user's authorization, and
 * exchanging the request token for an access token. When the process is finished either
 * the flickrDidAuthorize: or flickrDidNotAuthorize: delegate methods will be called.
 * @seealso http://www.flickr.com/services/api/auth.oauth.html
 */
@interface RXFlickr : NSObject <UIWebViewDelegate> {
  id<RXFlickrDelegate> delegate;
}

@property(nonatomic,retain) UIWebView* webView;
@property(nonatomic,assign) id<RXFlickrDelegate> delegate;
@property(nonatomic,retain) NSString* token;
@property(nonatomic,retain) NSString* tokenSecret;


/*!
 * @method startAuthorization
 * @abstract Starts the beginning of a user's Flick authorization flow.
 * @discussion This method immediately attempts to link the user's Flickr account.
 * On completion, this methods invokes one of two required delegate methods. On success,
 * the @link token @/link and @link tokenSecret @/link properties will be set. It is a programming error
 * to call this method without setting its @link webView @/link property.
 */
- (void)startAuthorization;

/*!
 * @method initWithConsumerKey:secret:callbackURL:
 * @abstract Initializes a new RXFlickr object with a consumer key, consumer secret, and callbackURL
 * @param consumerKey consumer key provided by Flickr
 * @param consumerSecret consumer secret provided by Flickr
 * @param callbackURL callback URL defined in Flickr
 * @discussion While the consumer key and secret are provided by Flickr after registering an app, your callbackURL
 * is an optional value that you must explicitly set yourself. None of the required delegate methods will fire
 * if the wrong callbackURL is entered.
 */
- (id)initWithConsumerKey:(NSString*)consumerKey secret:(NSString*)consumerSecret callbackURL:(NSString*)callbackURL;

@end
