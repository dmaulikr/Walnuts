//
//  WSquirrelController.m
//  Walnuts
//
//  Created by Danny Pollack on 9/23/12.
//  Copyright (c) 2012 Danny Pollack. All rights reserved.
//

#import "WSquirrelController.h"
#import "stdlib.h"

static const float kWSquirrelDirectionChangeProbability = 0.02;

@implementation WSquirrelController

@synthesize lastDirectionChange=_lastDirectionChange;
@synthesize headingLeft=_headingLeft;

- (id)initWithDelegate:(id<WSquirrelControllerDelegate>)delegate {
    if (self = [super init]) {
        _state = WSquirrelStateWaiting;
        _headingLeft = NO;
        
        [self resetProbabilities];
        _runTime = 0.0;

        _delegate = delegate;
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)setDelegate:(id<WSquirrelControllerDelegate>)delegate {
    _delegate = delegate;
}

- (void)resetProbabilities {
    _nutProbability = 0.15;
    _rockProbability = 0.002;
}

- (void)stopForDeathEvent:(WSquirrelAction)event {
    switch (event) {
        case WSquirrelActionNut:
            _nutProbability = _nutProbability*0.9;
            break;
            
        case WSquirrelActionRock:
            _rockProbability = _rockProbability*0.8;
            break;
            
        default:
            break;
    }
    
    _state = WSquirrelStateWaiting;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_processAction) object:nil];
}

- (void)runFor:(CFTimeInterval)runTime {
    _runTime = runTime;
    _startTime = CACurrentMediaTime();
    _state = WSquirrelStateRunning;
    _lastDirectionChange = _startTime;
    
    [self _processAction];
}

- (void)didHitBounds {
    _headingLeft = !_headingLeft;
    _lastDirectionChange = CACurrentMediaTime();
}

- (void)_processAction {
    if (CACurrentMediaTime() >= _startTime + _runTime) {
        _runTime = 0.0;
        _startTime = 0.0;
        _state = WSquirrelStateWaiting;
        
        _rockProbability = MIN(_rockProbability*2.0, 0.2);
        NSLog(@"Rock probability is now %f", _rockProbability);
        [_delegate squirrelControllerRunDidComplete:self];
        return;
    }
    
    WSquirrelAction action = WSquirrelActionCount;
    float pn = arc4random_uniform(100)/100.0f;
    if (pn <= _nutProbability) {
        action = WSquirrelActionNut;
    } else {
        float pr = arc4random_uniform(100)/100.0f;
        if (pr <= _rockProbability) {
            action = WSquirrelActionRock;
        }
    }
    
    if (action < WSquirrelActionCount) {
        [_delegate squirrelController:self performAction:action];
    }
    
    float pd = arc4random_uniform(100)/100.0f;
    if (pd <= kWSquirrelDirectionChangeProbability) {
        _headingLeft = !_headingLeft;
        _lastDirectionChange = CACurrentMediaTime();
    }

    [self performSelector:@selector(_processAction) withObject:nil afterDelay:0.1];
}

@end
