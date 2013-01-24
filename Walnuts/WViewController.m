//
//  WViewController.m
//  Walnuts
//
//  Created by Danny Pollack on 9/23/12.
//  Copyright (c) 2012 Danny Pollack. All rights reserved.
//

#import "WViewController.h"
#import "UIApplication+WExensions.h"
#import "WFallingObjectView.h"
#import <QuartzCore/QuartzCore.h>

#import <AudioToolbox/AudioServices.h>


static const CGFloat kWSquirrelMovementScreenProportion = 0.2; // Proportion of the screen the squirrel will traverse per second

#define kHighScoreKey @"highScore-v0"

@implementation WViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    NSNumber *highScore = [[NSUserDefaults standardUserDefaults] objectForKey:kHighScoreKey];
    _highScore = [highScore unsignedIntegerValue];
    
    UIImage *image = [UIImage imageNamed:@"background-final.png"];
    
    _scale = [image size].height/[UIApplication currentSize].height;
    
    UIImage *scaledImage =
    [UIImage imageWithCGImage:[image CGImage]
                        scale:_scale orientation:UIImageOrientationUp];
    
    if ([UIApplication currentSize].width < scaledImage.size.width) {
        CGFloat extraWidth = scaledImage.size.width - [UIApplication currentSize].width;
        
        CGRect cropRect = CGRectMake(floorf(extraWidth/2.0)*scaledImage.scale, 0, [UIApplication currentSize].width*scaledImage.scale, scaledImage.size.height*scaledImage.scale);
        CGImageRef imageRef = CGImageCreateWithImageInRect([scaledImage CGImage], cropRect);
        scaledImage = [UIImage imageWithCGImage:imageRef scale:scaledImage.scale orientation:UIImageOrientationUp];
        CFRelease(imageRef);
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:scaledImage];
    [[self view] addSubview:imageView];
    [[self view] sendSubviewToBack:imageView];
    [imageView release];
    
    _squirrelController = [[WSquirrelController alloc] initWithDelegate:self];

    _squirrel = [[UIImageView alloc] initWithImage:[self _getHappySquirrel]];
    CGSize squirrelSize = [_squirrel frame].size;
    [_squirrel setFrame:CGRectMake(floor(([UIApplication currentSize].width-squirrelSize.width)/2.0), 0, squirrelSize.width, squirrelSize.height)];
    [[self view] addSubview:_squirrel];
    
    CGFloat basketHeight = 60.0*1.0/_scale;
    CGFloat basketWidth = 80.0*1.0/_scale;
    CGFloat screenHeight = [UIApplication currentSize].height;
    UIImage *basketImage = [UIImage imageWithCGImage:[[UIImage imageNamed:@"basket.png"] CGImage] scale:_scale orientation:UIImageOrientationUp];
    _basket = [[UIImageView alloc] initWithImage:basketImage];
    [_basket setContentMode:UIViewContentModeScaleToFill];
    [_basket setFrame:CGRectMake(floor(([UIApplication currentSize].width-basketWidth)/2.0), screenHeight - basketHeight, basketWidth, basketHeight)];
    [_basket setBackgroundColor:[UIColor yellowColor]];
    [[self view] addSubview:_basket];
    
    _scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(3, 1, 100*1.0/_scale, 10*1.0/_scale)];
    [_scoreLabel setFont:[UIFont boldSystemFontOfSize:floorf(12.0*1.0/_scale)]];
    [_scoreLabel setTextColor:[UIColor redColor]];
    [_scoreLabel setBackgroundColor:[UIColor clearColor]];
    [[self view] addSubview:_scoreLabel];
    
    _displayLink = [[CADisplayLink displayLinkWithTarget:self selector:@selector(_recalculatePositions)] retain];
    
    NSURL *fileURL = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"walnuts" ofType:@"mp3"]];
    NSError *error = nil;
    _musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    [_musicPlayer setNumberOfLoops:-1];
    [_musicPlayer play];
    
    _state = WGameStateOver;
    [self _showNewGameView];
}

- (void)_showBetweenGameViewWithText:(NSString *)text buttonTitle:(NSString *)buttonTitle {
    [self _tearDownBetweenGameView];
    
    CGFloat border = 20;
    _betweenGameView = [[UIView alloc] initWithFrame:CGRectMake(border, border, [UIApplication currentSize].width-(2*border), [UIApplication currentSize].height-(2*border))];
    
    [_betweenGameView setBackgroundColor:[UIColor blackColor]];
    [_betweenGameView setAlpha:0.8];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIApplication currentSize].width-(2*border), 200)];
    [label setText:text];
    [label setNumberOfLines:6];
    [label setTextColor:[UIColor whiteColor]];
    [label setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.0]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setFont:[UIFont boldSystemFontOfSize:20.0]];
    
    [_betweenGameView addSubview:label];
    [label release];
    
    CGFloat buttonWidth = 100;
    CGFloat buttonHeight = 50;
    UIButton *playButton = [[UIButton alloc] initWithFrame:CGRectMake(floorf((_betweenGameView.frame.size.width-buttonWidth)/2.0), _betweenGameView.frame.size.height-20-buttonHeight, buttonWidth, buttonHeight)];
    [playButton setTitle:buttonTitle forState:UIControlStateNormal];
    [playButton setBackgroundColor:[UIColor grayColor]];
    [playButton addTarget:self action:@selector(_restartGame) forControlEvents:UIControlEventTouchUpInside];
    [_betweenGameView addSubview:playButton];
    [playButton release];
    
    [[self view] addSubview: _betweenGameView];
}

- (void)_showNewGameView {
    [self _showBetweenGameViewWithText:[NSString stringWithFormat:@"Welcome to Walnuts\n\nCatch the nuts, avoid the rocks, and beat the squirrel!\n\nHigh score: %u", _highScore] buttonTitle:@"Play"];
}

- (void)_showGameOverView {
    [self _showBetweenGameViewWithText:[NSString stringWithFormat:@"Game over!\n\nYou saved %u walnut%@.\nHigh score: %u", _score, _score == 1 ? @"" : @"s", _highScore] buttonTitle:@"Rematch"];
}

- (void)_showHighScoreGameOverView {
    [self _showBetweenGameViewWithText:[NSString stringWithFormat:@"Game over!\n\n High score!!\nYou saved %u walnut%@.", _score, _score == 1 ? @"" : @"s"] buttonTitle:@"Rematch"];
}

- (void)_tearDownBetweenGameView {
    [_betweenGameView removeFromSuperview];
    [_betweenGameView release];
    _betweenGameView = nil;
}

- (void)viewDidAppear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // This would be a good spot to dump the images I'm storing in static variables
}

- (void)dealloc {
    [_squirrelController setDelegate:nil];
    [_squirrel release];
    [_basket release];
    [_scoreLabel release];
    [_fallingObjects release];
    [_musicPlayer release];
    [_effectsPlayer setDelegate:nil];
    [_effectsPlayer release];
    [_pendingEffects release];
    [_betweenGameView release];
    
    [super dealloc];
}

#pragma mark - Sound effects

- (void)_playHappySquirrel {
    static SystemSoundID sHappySquirrel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *fileURL = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"happysquirrel" ofType:@"mp3"]];
        OSStatus error = AudioServicesCreateSystemSoundID((CFURLRef)fileURL, &sHappySquirrel);
        if (error != kAudioServicesNoError) {
            NSLog(@"Uh oh, couldn't load sound");
        }
    });
    AudioServicesPlaySystemSound(sHappySquirrel);
}

- (void)_playMadSquirrel {
    static SystemSoundID sMadSquirrel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *fileURL = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"madsquirrel" ofType:@"mp3"]];
        OSStatus error = AudioServicesCreateSystemSoundID((CFURLRef)fileURL, &sMadSquirrel);
        if (error != kAudioServicesNoError) {
            NSLog(@"Uh oh, couldn't load sound");
        }
    });
    AudioServicesPlaySystemSound(sMadSquirrel);
}

- (void)_playNutCatch {
    static SystemSoundID sNutCatch;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *fileURL = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"nutcatch2" ofType:@"mp3"]];
        OSStatus error = AudioServicesCreateSystemSoundID((CFURLRef)fileURL, &sNutCatch);
        if (error != kAudioServicesNoError) {
            NSLog(@"Uh oh, couldn't load sound");
        }
    });
    AudioServicesPlaySystemSound(sNutCatch);
}

- (void)_playNutMiss {
    static SystemSoundID sNutMiss;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *fileURL = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"nutmiss" ofType:@"mp3"]];
        OSStatus error = AudioServicesCreateSystemSoundID((CFURLRef)fileURL, &sNutMiss);
        if (error != kAudioServicesNoError) {
            NSLog(@"Uh oh, couldn't load sound");
        }
    });
    AudioServicesPlaySystemSound(sNutMiss);
}

- (void)_playRock {
    static SystemSoundID sRock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *fileURL = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"rocksound" ofType:@"mp3"]];
        OSStatus error = AudioServicesCreateSystemSoundID((CFURLRef)fileURL, &sRock);
        if (error != kAudioServicesNoError) {
            NSLog(@"Uh oh, couldn't load sound");
        }
    });
    AudioServicesPlaySystemSound(sRock);
}

#pragma mark - Image utilities

- (UIImage *)_getHappySquirrel {
    static UIImage *sHappySquirrel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIImage *squirrelImage = [UIImage imageNamed:@"happysquirrel.png"];
        sHappySquirrel = [[UIImage imageWithCGImage:[squirrelImage CGImage] scale:_scale orientation:UIImageOrientationUp] retain];
    });
    return sHappySquirrel;
}

#pragma mark - Score

- (void)_updateScoreLabel {
    [_scoreLabel setText:[NSString stringWithFormat:@"%u", _score]];
    [_scoreLabel sizeToFit];
}

#pragma mark - Levels

- (void)_restartGame {
    [self _tearDownBetweenGameView];
    
    NSLog(@"Restarting game");
    _score = 0;
    [_squirrelController resetProbabilities];
    [self _updateScoreLabel];
    
    _state = WGameStateRunning;
    [self performSelector:@selector(_startLevel) withObject:nil afterDelay:2];
}

- (void)_startLevel {
    NSLog(@"Starting level");
    [_squirrel setImage:[self _getHappySquirrel]];
    [_squirrelController runFor:30.0];
    _state = WGameStateRunning;
}

- (void)_processEndLevelIfNecessary {
    static UIImage *sScaledMadSquirrel = nil;
    static UIImage *sScaledPleasedSquirrel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIImage *madSquirrel = [UIImage imageNamed:@"madsquirrel2.png"];
        sScaledMadSquirrel = [[UIImage imageWithCGImage:[madSquirrel CGImage] scale:_scale orientation:UIImageOrientationUp] retain];
        UIImage *pleasedSquirrel = [UIImage imageNamed:@"pleasedsquirrel.png"];
        sScaledPleasedSquirrel = [[UIImage imageWithCGImage:[pleasedSquirrel CGImage] scale:_scale orientation:UIImageOrientationUp] retain];
    });

    // The squirrel is waiting and we're between levels
    if ((_state == WGameStateBetweenLevels) && ([_fallingObjects count] == 0)) {
        NSLog(@"Level completed!");
        [_squirrel setImage:sScaledMadSquirrel];
        [self _playMadSquirrel];
        [self performSelector:@selector(_startLevel) withObject:nil afterDelay:2.0];
    } else if ((_state == WGameStateLostLife) && ([_fallingObjects count] == 0)) {
        NSLog(@"Game over");
        [_squirrel setImage:sScaledPleasedSquirrel];
        [self _playHappySquirrel];
        if (_score > _highScore) {
            [self performSelector:@selector(_showHighScoreGameOverView) withObject:nil afterDelay:0.5];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:_score] forKey:kHighScoreKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            _highScore = _score;
        } else {
            [self performSelector:@selector(_showGameOverView) withObject:nil afterDelay:0.5];
        }
    }
}

#pragma mark - Display link

- (void)_recalculatePositions {
    // Squirrel
    if (_state == WGameStateRunning)
        [self _updateSquirrelPosition];
    
    // Falling Objects
    __block WSquirrelAction deathReason = WSquirrelActionCount;
    
    __block BOOL scoreNeedsUpdate = NO;
    NSMutableIndexSet *removeSet = [NSMutableIndexSet indexSet];
    CGSize screenSize = [UIApplication currentSize];
    [_fallingObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        WFallingObjectView *fallingObject = obj;
        [fallingObject updateFrame];
        
        CGRect frame = [fallingObject frame];
        CGRect basketFrame = [_basket frame];
        
        if (_state == WGameStateRunning || _state == WGameStateBetweenLevels) {
            if ([fallingObject action] == WSquirrelActionNut) {
                // Let's make this basket taller and wider by half a nut on all sides
                CGRect lenientBasketFrame = basketFrame;
                lenientBasketFrame.origin.x -= frame.size.width/2.0;
                lenientBasketFrame.size.width += frame.size.width; // make up for the shift left too
                
                lenientBasketFrame.origin.y -= frame.size.height/2.0;
                lenientBasketFrame.size.height += frame.size.height/2.0; // no need to make it extra deep, just make up for the shift up
                if (CGRectContainsRect(lenientBasketFrame, frame)) {
                    [self _playNutCatch];
                    _score += 1;
                    scoreNeedsUpdate = YES;
                    [removeSet addIndex:idx];
                }
            } else if ([fallingObject action] == WSquirrelActionRock) {
                // Let's make this basket thinner and shorter by half a rock on all sides
                CGRect lenientBasketFrame = basketFrame;
                lenientBasketFrame.origin.x += frame.size.width/2.0;
                lenientBasketFrame.size.width -= frame.size.width; // make up for the shift right too
                
                lenientBasketFrame.origin.y += frame.size.height/2.0;
                lenientBasketFrame.size.height -= frame.size.height/2.0; // no need to make it extra deep, just make up for the shift down
                if (CGRectContainsRect(lenientBasketFrame, frame)) {
                    [self _playRock];
                    deathReason = WSquirrelActionRock;
                    _state = WGameStateLostLife;
                    [removeSet addIndex:idx];
                }
            }
        }

        if (frame.origin.y >= screenSize.height) {
            if ([fallingObject action] == WSquirrelActionNut) {
                [self _playNutMiss];
                deathReason = WSquirrelActionNut;
                _state = WGameStateLostLife;
            }
            [removeSet addIndex:idx];
        }
    }];

    [removeSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [[_fallingObjects objectAtIndex:idx] removeFromSuperview];
    }];
    [_fallingObjects removeObjectsAtIndexes:removeSet];
    
    if ([_fallingObjects count] == 0) {
        [_fallingObjects release];
        _fallingObjects = nil;
        [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

        [self _processEndLevelIfNecessary];
    }
    
    if (scoreNeedsUpdate) {
        [self _updateScoreLabel];
    }
    if (deathReason < WSquirrelActionCount) {
        [_squirrelController stopForDeathEvent:deathReason];
    }
    
    _lastDisplayLinkUpdate = CACurrentMediaTime();
}

#pragma mark - Squirrel positioning

- (void)_updateSquirrelPosition {
    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval deltaT = now - _lastDisplayLinkUpdate;

    CGSize screenSize = [UIApplication currentSize];
    CGFloat deltaX = ceilf(deltaT * kWSquirrelMovementScreenProportion * screenSize.width);
    if ([_squirrelController headingLeft])
        deltaX *= -1.0;
    
    BOOL hitBounds = NO;
    CGRect frame = [_squirrel frame];
    CGFloat minX = 0.0;
    CGFloat maxX = screenSize.width - frame.size.width;
    
    frame.origin.x += deltaX;
    if (frame.origin.x < minX) {
        frame.origin.x = minX;
        hitBounds = YES;
    } else if (frame.origin.x > maxX) {
        frame.origin.x = maxX;
        hitBounds = YES;
    }
    
    [_squirrel setFrame:frame];
    
    if (hitBounds) {
        NSLog(@"Hitbounds!");
        [_squirrelController didHitBounds];
    }
}

#pragma mark - Falling objects

- (void)_addFallingObject:(WSquirrelAction)action {
    if (!_fallingObjects) {
        _fallingObjects = [[NSMutableArray alloc] init];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        _lastDisplayLinkUpdate = CACurrentMediaTime();
    }
    
    CGRect squirrelFrame = [_squirrel frame];
    CGFloat objectDimension = floorf(15.0*1.0/_scale);
    CGRect objectFrame = CGRectMake(squirrelFrame.origin.x + ceilf(squirrelFrame.size.width/2.0) - ceilf(objectDimension/2.0), squirrelFrame.size.height, objectDimension, objectDimension);
    WFallingObjectView *objectView = [[WFallingObjectView alloc] initWithFrame:objectFrame action:action];
    [[self view] addSubview:objectView];
    [_fallingObjects addObject:objectView];
    [objectView release];
    
    [[self view] bringSubviewToFront:_basket];
}

#pragma mark - WSquirrelControllerDelegate

- (void)squirrelControllerRunDidComplete:(WSquirrelController *)controller {
    NSLog(@"Run did complete!!");
    _state = WGameStateBetweenLevels;
    [self _processEndLevelIfNecessary];
}

- (void)squirrelController:(WSquirrelController *)controller performAction:(WSquirrelAction)action {
    [self _addFallingObject:action];
}

#pragma mark - Basket utilities

- (CGRect)_calculateBasketFrameForCenter:(CGPoint)attemptedCenter {
    // Let the basket go 2/3 off screen on either side.
    CGRect frame = [_basket frame];
    CGFloat leeway = ceilf(2*frame.size.width/3.0);
    CGFloat maxXCenter = [UIApplication currentSize].width - ceilf(frame.size.width/2.0) + leeway;
    CGFloat minXCenter = floorf(frame.size.width/2.0) - leeway;
    
    CGFloat centerX = MAX(minXCenter, MIN(maxXCenter, attemptedCenter.x));
    frame.origin.x = centerX - floorf(frame.size.width/2.0);
    return frame;
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch && (_state == WGameStateRunning || _state == WGameStateBetweenLevels)) {
        CGPoint touchPoint = [touch locationInView:[self view]];
        CGRect frame = [self _calculateBasketFrameForCenter:touchPoint];
        [_basket setFrame:frame];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

@end
