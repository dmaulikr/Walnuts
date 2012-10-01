//
//  UIApplication+UIApplication_WExensions.h
//  Walnuts
//
//  Created by Danny Pollack on 9/23/12.
//  Copyright (c) 2012 Danny Pollack. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (UIApplication_WExensions)
+(CGSize) currentSize;
+(CGSize) sizeInOrientation:(UIInterfaceOrientation)orientation;
@end
