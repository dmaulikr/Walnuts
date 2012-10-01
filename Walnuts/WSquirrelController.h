//
//  WSquirrelController.h
//  Walnuts
//
//  Created by Danny Pollack on 9/23/12.
//  Copyright (c) 2012 Danny Pollack. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    WSquirrelStateWaiting,
    WSquirrelStateRunning
} WSquirrelState;

typedef enum {
    WSquirrelActionRock = 0,
    WSquirrelActionNut,
    WSquirrelActionCount
} WSquirrelAction;

@protocol WSquirrelControllerDelegate;
@interface WSquirrelController : NSObject {
    WSquirrelState _state;
    float _nutProbability;
    float _rockProbability;
    CFTimeInterval _runTime;
    CFTimeInterval _startTime;
    BOOL _headingLeft;
    CFTimeInterval _lastDirectionChange;
    
    id<WSquirrelControllerDelegate> _delegate; // weak
}
@property (nonatomic, readwrite, assign) id<WSquirrelControllerDelegate> delegate;
@property (nonatomic, readonly, assign) CFTimeInterval lastDirectionChange;
@property (nonatomic, readonly, assign) BOOL headingLeft;

- (id)initWithDelegate:(id<WSquirrelControllerDelegate>)delegate;
- (void)runFor:(CFTimeInterval)runTime;
- (void)stopForDeathEvent:(WSquirrelAction)event;
- (void)didHitBounds;
- (void)resetProbabilities;

@end


@protocol WSquirrelControllerDelegate <NSObject>
- (void)squirrelControllerRunDidComplete:(WSquirrelController *)controller;
- (void)squirrelController:(WSquirrelController *)controller performAction:(WSquirrelAction)action;
@end