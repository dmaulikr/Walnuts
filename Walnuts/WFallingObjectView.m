//
//  WFallingObjectView.m
//  Walnuts
//
//  Created by Danny Pollack on 9/23/12.
//  Copyright (c) 2012 Danny Pollack. All rights reserved.
//

#import "WFallingObjectView.h"
#import "UIApplication+WExensions.h"

static const CGFloat kWFallingObjectMovementScreenProportion = 0.5; // Amount of screen to fall per second

@implementation WFallingObjectView

@synthesize action=_action;

#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame action:(WSquirrelAction)action {
    if (self = [super initWithFrame:frame]) {
        if (action == WSquirrelActionNut) {
            UIImage *nutImage = [UIImage imageNamed:@"walnut.png"];
            [self setImage:nutImage];
        } else {
            UIImage *rockImage = [UIImage imageNamed:@"rock.png"];
            [self setImage:rockImage];
        }

        _action = action;
        _startTime = CACurrentMediaTime();
        _y0 = frame.origin.y;
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark - Updating

- (void)updateFrame {
    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval deltaT = now - _startTime;
    CGRect frame = [self frame];
    CGSize screenSize = [UIApplication currentSize];
    CGFloat yPos = _y0 + ceilf(deltaT*kWFallingObjectMovementScreenProportion*screenSize.height);
    
    frame.origin.y = yPos;
    [self setFrame:frame];
}

@end
