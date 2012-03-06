//
//  RXViewController.m
//  FlickrDemo
//
//  Created by Joseph Stein on 1/8/12.
//  Copyright (c) 2012 9mmedia. All rights reserved.
//

#import "RXViewController.h"

static NSString* kConsumerKey = @"INSERT_CONSUMER_KEY";
static NSString* kConsumerSecret = @"INSERT_CONSUMER_SECRET";
static NSString* kCallbackURL = @"INSERT_CALLBACK_URL";

@interface RXViewController () {
  RXFlickr* _flickrAccount;
  IBOutlet UIWebView* _webView;
}
- (IBAction)tappedAuthenticationButton;
@end

@implementation RXViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  NSAssert(![kConsumerKey isEqualToString:@"INSERT_CONSUMER_KEY"], @"Invalid Consumer Key");
  NSAssert(![kConsumerSecret isEqualToString:@"INSERT_CONSUMER_SECRET"], @"Invalid Consumer Secret");
  NSAssert(![kCallbackURL isEqualToString:@"INSERT_CALLBACK_URL"], @"Invalid Callback Url");
  
  _flickrAccount = [[RXFlickr alloc] initWithConsumerKey:kConsumerKey secret:kConsumerSecret callbackURL:kCallbackURL];
  [_flickrAccount setDelegate:self];
}

- (void)viewDidUnload
{
  [_webView release];
  _webView = nil;
  
  [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void)dealloc
{
  [_flickrAccount release];
  [_webView release];
  
  [super dealloc];
}

#pragma mark - Action Methods

- (void)tappedAuthenticationButton
{
  [_flickrAccount setWebView:_webView];
  [_flickrAccount startAuthorization];
}

#pragma mark - RXFlickr Delegate

- (void)flickrDidAuthorize:(RXFlickr *)flickr
{
  NSString* message = [NSString stringWithFormat:@"Token = %@\nSecret=%@", [_flickrAccount token], [_flickrAccount tokenSecret]];
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Success" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
  [alert show];
  [alert release];
  
  [_webView loadHTMLString:nil baseURL:nil];
}

- (void)flickrDidNotAuthorize:(RXFlickr *)flickr
{
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"An authorization error has occured" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
  [alert show];
  [alert release];
}

@end
