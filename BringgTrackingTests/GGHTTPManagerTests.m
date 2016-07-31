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
#import "GGHTTPClientManager.h"

#import "GGOrder.h"
#import "GGDriver.h"
#import "GGSharedLocation.h"
#import "GGWaypoint.h"
#import "GGCustomer.h"

@interface GGHTTPManagerTests : XCTestCase

@property (nonatomic, strong) GGHTTPClientManager *httpManager;

@property (nullable, nonatomic, strong) NSDictionary *acceptJson;
@property (nullable, nonatomic, strong) NSDictionary *startJson;

-(GGCustomer *)generatedCustomer;

@end

@implementation GGHTTPManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.httpManager = [GGHTTPClientManager managerWithDeveloperToken:nil];
    
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

-(void)testManagerStatic{
    GGHTTPClientManager *manager = [GGHTTPClientManager manager];
    XCTAssertTrue([manager isEqual:self.httpManager]);
}

-(void)testAuthenticatingCustomer{
   
    
    [self.httpManager useCustomer:self.generatedCustomer];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    [self.httpManager addAuthinticationToParams:&params];
    
    
    XCTAssertTrue(params.count == 3);
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
    [self.httpManager getOrderByOrderUUID:updatedOrder.uuid extras:nil withCompletionHandler:nil];
}

- (void)testFalseNegativeGetOrderById {
    // test to prove bug reported https://app.asana.com/0/32014397880520/160164813262190
    const NSString *devToken = @"5KBxNkjHoTyPQ-NtcshW";
    
    [self.httpManager setDeveloperToken:devToken];
    
    const NSNumber *merchantId = @10263;
    const NSString *customerName = @"Thomas In Sook Holmen";
    const NSString *confirmationCode = @"8356";
    const NSString *phone = @"+4510000003";
    
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
    XCTAssertTrue([resultCustomer.name isEqualToString:customerName]);
    
    // not try to get problematic order
    const NSNumber *orderId = @961031;
    
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

@end
