//
//  RESTEngine.m
//  iHotelApp
//
//  Created by Mugunth on 25/05/11.
//  Copyright 2011 Steinlogic. All rights reserved.

#import "RESTfulEngine.h"
#import "MenuItem.h"

@implementation RESTfulEngine

-(NSString*) accessToken
{
    if(!_accessToken)
    {
      [self willChangeValueForKey:@"AccessToken"];
        _accessToken = [[NSUserDefaults standardUserDefaults] stringForKey:kAccessTokenDefaultsKey];
      [self didChangeValueForKey:@"AccessToken"];
    }
    
    return _accessToken;
}
-(void) setAccessToken:(NSString *) aAccessToken
{
    [self willChangeValueForKey:@"AccessToken"];
    _accessToken = aAccessToken;
    [self didChangeValueForKey:@"AccessToken"];
    
    // if you are going to have multiple accounts support, 
    // it's advisable to store the access token as a serialized object    
    // this code will break when a second RESTEngine object is instantiated and a new token is issued for him

    [[NSUserDefaults standardUserDefaults] setObject:self.accessToken forKey:kAccessTokenDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (RESTfulOperation*) prepareRequestForURLString:(NSString*) urlString
{
  RESTfulOperation *op = (RESTfulOperation*) [self operationWithPath:urlString];
  
  // this inserts a header like ''Authorization = Token blahblah''
    if(self.accessToken)
      [op setAuthorizationHeaderValue:self.accessToken forAuthType:@"Token"];
  
  return op;
}

#pragma mark -
#pragma mark Custom Methods

// Add your custom methods here
-(RESTfulOperation*) loginWithName:(NSString*) loginName 
           password:(NSString*) password
        onSucceeded:(VoidBlock) succeededBlock 
            onError:(ErrorBlock) errorBlock
{  
  RESTfulOperation *op = (RESTfulOperation*) [self operationWithPath:LOGIN_URL];
  
  [op setUsername:loginName password:password basicAuth:YES];
  [op onCompletion:^(MKNetworkOperation *completedOperation) {
      
    NSDictionary *responseDict = [completedOperation responseJSON];	
    self.accessToken = [responseDict objectForKey:@"accessToken"];	
    succeededBlock();
  } onError:^(NSError *error) {
    
    self.accessToken = nil;
    errorBlock(error);

  }];
	
	[self enqueueOperation:op];  
  return op;
}

-(RESTfulOperation*) fetchMenuItemsOnSucceeded:(ArrayBlock) succeededBlock 
                                       onError:(ErrorBlock) errorBlock
{
  RESTfulOperation *op = (RESTfulOperation*) [self operationWithPath:MENU_ITEMS_URL];
    
  [op onCompletion:^(MKNetworkOperation *completedOperation) {
      
    NSMutableArray *responseArray = [completedOperation responseJSON];
    NSMutableArray *menuItems = [NSMutableArray array];
    
    [responseArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

      [menuItems addObject:[[MenuItem alloc] initWithDictionary:obj]];
    }];

    succeededBlock(menuItems);
    
  } onError:errorBlock];
	
	[self enqueueOperation:op];    
  return op;
}

-(RESTfulOperation*) fetchMenuItemsFromWrongLocationOnSucceeded:(ArrayBlock) succeededBlock 
                                                        onError:(ErrorBlock) errorBlock
{
  RESTfulOperation *op = (RESTfulOperation*) [self operationWithPath:@"404"];
  
  [op onCompletion:^(MKNetworkOperation *completedOperation) {
    
    NSMutableArray *responseArray = [completedOperation responseJSON];	
    NSMutableArray *menuItems = [NSMutableArray array];
    
    [responseArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      
      [menuItems addObject:[[MenuItem alloc] initWithDictionary:obj]];
    }];
    
    succeededBlock(menuItems);
    
  } onError:errorBlock];
	
	[self enqueueOperation:op];    
  return op;
}
@end
