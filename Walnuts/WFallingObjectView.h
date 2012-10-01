//
//  WFallingObjectView.h
//  Walnuts
//
//  Created by Danny Pollack on 9/23/12.
//  Copyright (c) 2012 Danny Pollack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WSquirrelController.h"

@interface WFallingObjectView : UIImageView {
    WSquirrelAction _action;
    CFTimeInterval _startTime;
    CGFloat _velocity;
    CGFloat _y0;
}

@property (nonatomic, readonly, assign) WSquirrelAction action;

- (id)initWithFrame:(CGRect)frame action:(WSquirrelAction)action;
- (void)updateFrame;

@end
