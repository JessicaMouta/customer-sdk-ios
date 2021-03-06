//
//  GGHTTPManagerTests.m
//  BringgTracking
//
//  Created by Matan on 05/11/2015.
//  Copyright © 2015 Matan Poreh. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

#import "GGTestUtils.h"

#import "GGHTTPClientManager_Private.h"

#import "GGOrder.h"
#import "GGDriver.h"
#import "GGSharedLocation.h"
#import "GGWaypoint.h"
#import "GGCustomer.h"
#import "GGTrackerManager.h"
#import <BringgTracking/BringgGlobals.h>

@class GGHTTPClientManagerTestClient;

@interface GGHTTPManagerTests : XCTestCase

@property (nonatomic, strong) GGHTTPClientManager *httpManager;
@property (nonatomic, strong) GGHTTPClientManagerTestClient *httpManagerDelegate;
@property (nullable, nonatomic, strong) NSDictionary *acceptJson;
@property (nullable, nonatomic, strong) NSDictionary *startJson;

-(GGCustomer *)generatedCustomer;

@end


@interface GGHTTPClientManagerTestClient : NSObject <PrivateClientConnectionDelegate>
    
@end
    
@implementation GGHTTPClientManagerTestClient

    
- (NSString *)hostDomainForClientManager:(GGHTTPClientManager *)clientManager{
    return @"10.0.1.148:3030";
}

- (NSString *)hostDomainForTrackerManager:(GGTrackerManager *)trackerManager{
    return @"10.0.1.148:3000";
}
    
@end


@implementation GGHTTPManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.httpManager = [[GGHTTPClientManager alloc] init];
    self.httpManagerDelegate = [[GGHTTPClientManagerTestClient alloc] init];
    
    [self.httpManager setConnectionDelegate:self.httpManagerDelegate];
    [self.httpManager useSecuredConnection:NO];
    [self.httpManager setDeveloperToken:nil];
    self.acceptJson = [GGTestUtils parseJsonFile:@"orderUpdate_onaccept"];
    self.startJson = [GGTestUtils parseJsonFile:@"orderUpdate_onstart"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    self.httpManager = nil;
    self.acceptJson = nil;
    self.startJson = nil;
    
}

#pragma mark - Helpers

-(GGCustomer *)generatedCustomer{
    GGCustomer *customer = [[GGCustomer alloc] init];
    customer.customerToken = @"0e687e31b346f9981ddf197b4eb12881ba467aa4a685ded51bae050ddf0ec8cf";
    customer.phone = @"+972545541748";
    customer.name = @"Matan Poreh";
    customer.address = @"habarzel 10, tel aviv";
    customer.customerId = 102961;
    customer.lat = 0;
    customer.lng = 0;
    customer.merchantId = @8250;
    
    return customer;
}

#pragma mark - Tests

-(void)testAuthenticatingCustomer{
   
    
    [self.httpManager useCustomer:self.generatedCustomer];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    [self.httpManager addAuthinticationToParams:&params];
    
    
    XCTAssertTrue(params.allKeys.count == 3);
}


- (void)testGettingOrderStatus{
    
    self.acceptJson = [GGTestUtils parseJsonFile:@"orderUpdate_onaccept"];
    self.startJson = [GGTestUtils parseJsonFile:@"orderUpdate_onstart"];
    
    [self.httpManager useCustomer:self.generatedCustomer];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    [self.httpManager addAuthinticationToParams:&params];
    
    NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.acceptJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    //
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];

    //
    [self.httpManager getOrderByShareUUID:updatedOrder.sharedLocationUUID accessControlParamKey:PARAM_ORDER_UUID accessControlParamValue:updatedOrder.uuid extras:nil withCompletionHandler:nil];
}
/*
 this test is only for live testing
- (void)testFalseNegativeGetOrderById {
    // test to prove bug reported https://app.asana.com/0/32014397880520/160164813262190
    const NSString *devToken = @"zwp-i8j9R3xSk4xCScKx";// @"5KBxNkjHoTyPQ-NtcshW";
    
    [self.httpManager setDeveloperToken:devToken];
    
    const NSNumber *merchantId = @10263;
    const NSString *customerName = @"Thomas In Sook Holmen";
    const NSString *confirmationCode = @"5320";
    const NSString *phone = @"+4510000002";
    
    // this is a test with production data
    
      NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:12];
    __block BOOL didRespond = NO;
    __block BOOL didSucceed = NO;
    __block GGCustomer *resultCustomer;
    
    // try sign in
    [self.httpManager signInWithName:customerName phone:phone email:nil password:nil confirmationCode:confirmationCode merchantId:merchantId extras:nil completionHandler:^(BOOL success, NSDictionary * _Nullable response, GGCustomer * _Nullable customer, NSError * _Nullable error) {
        //
        
        didRespond = YES;
        didSucceed = success;
        
        resultCustomer = customer;
    }];
    
    while (!didRespond && [loopUntil timeIntervalSinceNow] > 0) {
        
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    XCTAssertTrue(didRespond);
    XCTAssertTrue(didSucceed);
    XCTAssertNotNil(resultCustomer);
    XCTAssertTrue([resultCustomer.name.lowercaseString isEqualToString:customerName.lowercaseString]);
    
    // not try to get problematic order
    const NSNumber *orderId = @953191;
    
    loopUntil = [NSDate dateWithTimeIntervalSinceNow:12];
    didRespond = NO;
    didSucceed = NO;
    __block GGOrder *resultOrder;
    
    [self.httpManager getOrderByID:orderId.integerValue extras:nil withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
        //
        
        didRespond = YES;
        didSucceed = success;
        
        resultOrder = order;
        
    }];
    
    while (!didRespond && [loopUntil timeIntervalSinceNow] > 0) {
        
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }


    XCTAssertTrue(didRespond);
    XCTAssertTrue(didSucceed);
    XCTAssertNotNil(resultOrder);
    
    XCTAssertTrue(resultOrder.orderid == orderId.integerValue);
}
*/

/*
 this test is only for live testing
- (void)testFineMeLiveUsingHttpManagerOnly{
    // to exectute this test you must have an active order and customer (that must be allowed to login)
    
    const NSString *devToken = @"rvWLCySWSJFyP3kBbkZB";//@"xHDAaSnfBFcd9DRzJQpc";
    
    [self.httpManager setDeveloperToken:devToken];
    
    const NSNumber *merchantId = @1;//@9800;
    const NSString *customerName = @"Alex trost";//@"Matan Poreh";
    const NSString *confirmationCode = @"6926";//@"7305";
    const NSString *phone = @"+972526511950";// @"+972545541748";
    
    // this is a test with production data
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:12];
    __block BOOL didRespond = NO;
    __block BOOL didSucceed = NO;
    __block GGCustomer *resultCustomer;
    
    // try sign in
    [self.httpManager signInWithName:customerName phone:phone email:nil password:nil confirmationCode:confirmationCode merchantId:merchantId extras:nil completionHandler:^(BOOL success, NSDictionary * _Nullable response, GGCustomer * _Nullable customer, NSError * _Nullable error) {
        //
        
        didRespond = YES;
        didSucceed = success;
        
        resultCustomer = customer;
    }];
    
    while (!didRespond && [loopUntil timeIntervalSinceNow] > 0) {
        
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    XCTAssertTrue(didRespond);
    XCTAssertTrue(didSucceed);
    XCTAssertNotNil(resultCustomer);
    XCTAssertTrue([resultCustomer.name.lowercaseString isEqualToString:customerName.lowercaseString]);
    
    
    if (!didSucceed) {
        return;
    }
    
    const NSNumber *orderId = @109;//@1027197;
    
    loopUntil = [NSDate dateWithTimeIntervalSinceNow:12];
    didRespond = NO;
    didSucceed = NO;
    __block GGOrder *resultOrder;
    
    [self.httpManager getOrderByID:orderId.integerValue extras:nil withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
        //
        
        didRespond = YES;
        didSucceed = success;
        
        resultOrder = order;
        
    }];
    
    while (!didRespond && [loopUntil timeIntervalSinceNow] > 0) {
        
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    
    
    XCTAssertTrue(didRespond);
    XCTAssertTrue(didSucceed);
    XCTAssertNotNil(resultOrder);
    
    XCTAssertTrue(resultOrder.orderid == orderId.integerValue);
    
    XCTAssertNotNil(resultOrder.sharedLocation);
    XCTAssertNotNil(resultOrder.sharedLocation.findMe);
    XCTAssertNotNil(resultOrder.sharedLocation.findMe.url);
    
    if (!resultOrder.sharedLocation.findMe.url) {
        return;
    }
    
    NSString *findMeURL = [resultOrder.sharedLocation.findMe.url stringByReplacingOccurrencesOfString:@"localhost" withString:@"10.0.1.148"];
    
    GGFindMe *findMeConfig =resultOrder.sharedLocation.findMe;
    [findMeConfig setUrl:findMeURL];
    
    XCTAssertTrue([findMeConfig canSendFindMe]);
    
    
    // now call get order id again to see that findme url is still the same
    loopUntil = [NSDate dateWithTimeIntervalSinceNow:12];
    didRespond = NO;
    didSucceed = NO;
    resultOrder;
    
    [self.httpManager getOrderByID:orderId.integerValue extras:nil withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
        //
        
        didRespond = YES;
        didSucceed = success;
        
        resultOrder = order;
        
    }];
    
    while (!didRespond && [loopUntil timeIntervalSinceNow] > 0) {
        
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    

    XCTAssertTrue(didRespond);
    XCTAssertTrue(didSucceed);
    XCTAssertNotNil(resultOrder);
    
    XCTAssertTrue(resultOrder.orderid == orderId.integerValue);
    
    XCTAssertNotNil(resultOrder.sharedLocation);
    XCTAssertNotNil(resultOrder.sharedLocation.findMe);
    XCTAssertNotNil(resultOrder.sharedLocation.findMe.url);
    
    if (!resultOrder.sharedLocation.findMe.url) {
        return;
    }
    
    NSString *findMeURLB = [resultOrder.sharedLocation.findMe.url stringByReplacingOccurrencesOfString:@"localhost" withString:@"10.0.1.148"];
    
    GGFindMe *findMeConfigB = resultOrder.sharedLocation.findMe;
    [findMeConfigB setUrl:findMeURLB];
    
    XCTAssertTrue([findMeConfigB canSendFindMe]);
    XCTAssertTrue([findMeURLB isEqualToString:findMeURL]);
    
    loopUntil = [NSDate dateWithTimeIntervalSinceNow:12];
    didRespond = NO;
    didSucceed = NO;
   
    

    [self.httpManager sendFindMeRequestWithFindMeConfiguration:findMeConfig latitude:32.08653f longitude:34.79226f withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        
        didRespond = YES;
        didSucceed = success;
        
        //
    }];
    
    while (!didRespond && [loopUntil timeIntervalSinceNow] > 0) {
        
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    XCTAssertTrue(didRespond);
    XCTAssertTrue(didSucceed);
}
*/

@end
