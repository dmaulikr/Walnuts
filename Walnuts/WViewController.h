//
//  WViewController.h
//  Walnuts
//
//  Created by Danny Pollack on 9/23/12.
//  Copyright (c) 2012 Danny Pollack. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "WSquirrelController.h"

typedef enum {
    WGameStateRunning,
    WGameStateLostLife,
    WGameStateBetweenLevels
} WGameState;

@class CADisplayLink;
@interface WViewController : UIViewController<WSquirrelControllerDelegate, AVAudioPlayerDelegate> {
    WGameState _state;
    UILabel *_scoreLabel;
    NSUInteger _score;
    
    UIImageView *_squirrel;
    UIView *_basket;
    WSquirrelController *_squirrelController;
    
    NSMutableArray *_fallingObjects;
    CADisplayLink *_displayLink;
    CFTimeInterval _lastDisplayLinkUpdate;
    
    AVAudioPlayer *_musicPlayer;
    AVAudioPlayer *_effectsPlayer;
    NSMutableArray *_pendingEffects;
}

@end
