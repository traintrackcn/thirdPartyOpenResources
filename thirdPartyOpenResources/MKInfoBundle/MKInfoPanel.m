//
//  MKInfoPanel.m
//  HorizontalMenu
//
//  Created by Mugunth on 25/04/11.
//  Copyright 2011 Steinlogic. All rights reserved.
//  Permission granted to do anything, commercial/non-commercial with this file apart from removing the line/URL above
//  Read my blog post at http://mk.sg/8e on how to use this code
//  Compatible with ARC by Reber Eric

//  As a side note on using this code, you might consider giving some credit to me by
//	1) linking my website from your app's website 
//	2) or crediting me inside the app's credits page 
//	3) or a tweet mentioning @mugunthkumar
//	4) A paypal donation to mugunth.kumar@gmail.com
//
//  A note on redistribution
//	While I'm ok with modifications to this source code, 
//	if you are re-publishing after editing, please retain the above copyright notices

#import "MKInfoPanel.h"
#import <QuartzCore/QuartzCore.h>

// Private Methods

@interface MKInfoPanel ()

@property (nonatomic, assign) MKInfoPanelType type;

+ (MKInfoPanel*) infoPanel;

- (void)setup;

@end


@implementation MKInfoPanel



////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}



////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Setter/Getter
////////////////////////////////////////////////////////////////////////

-(void)setType:(MKInfoPanelType)type {
    NSString *imageName;
    switch (type) {
        case MKInfoPanelTypeError:
            imageName = @"MKIconError";
            break;
        case MKInfoPanelTypeInfo:
            imageName = @"MKIconInfo";
            break;
        case MKInfoPanelTypeWarning:
            imageName = @"MKIconWarning";
            break;
        default:
            break;
    }
    
    [_thumbImage setImage:[UIImage imageNamed:imageName]];
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Show/Hide
////////////////////////////////////////////////////////////////////////

+ (MKInfoPanel *)showPanelInView:(UIView *)view type:(MKInfoPanelType)type title:(NSString *)title subtitle:(NSString *)subtitle {
    return [self showPanelInView:view type:type title:title subtitle:subtitle hideAfter:-1];
}

+(MKInfoPanel *)showPanelInView:(UIView *)view type:(MKInfoPanelType)type title:(NSString *)title subtitle:(NSString *)subtitle hideAfter:(NSTimeInterval)interval {
    
    [self hideAllPanelsImmediatelyUnderView:view];
    
    MKInfoPanel *panel = [MKInfoPanel infoPanel];
    CGFloat panelHeight = 50;   // panel height when no subtitle set
    
    panel.type = type;
    panel.titleLabel.text = title;
    
    if(subtitle) {
        panel.detailLabel.text = subtitle;
        [panel.detailLabel sizeToFit];
        
        panelHeight = MAX(CGRectGetMaxY(panel.thumbImage.frame), CGRectGetMaxY(panel.detailLabel.frame));
        panelHeight += 10.f;    // padding at bottom
    } else {
        panel.detailLabel.hidden = YES;
        panel.thumbImage.frame = CGRectMake(22, 30, 18, 18);
        panel.titleLabel.frame = CGRectMake(57, 28, 240, 21);
        panelHeight += 15.f;    // padding at bottom
    }
    
    // update frame of panel
//    if ([[UIApplication sharedApplication] isStatusBarHidden]) {
//    panelHeight += 20;
    panel.frame = CGRectMake(0, 0.0f, view.bounds.size.width, panelHeight);
//    }else{
//        panel.frame = CGRectMake(0, 20.0f, view.bounds.size.width, panelHeight);
//    }
    [view addSubview:panel];
    
//    LOG_DEBUG(@"w -> %f h -> %f", view.bounds.size.width, panelHeight);
    
    if (interval > 0) {
        [panel performSelector:@selector(hidePanel) withObject:view afterDelay:interval]; 
    }
    
    return panel;
}

+ (MKInfoPanel *)showPanelInWindow:(UIWindow *)window type:(MKInfoPanelType)type title:(NSString *)title subtitle:(NSString *)subtitle {
    return [self showPanelInWindow:window type:type title:title subtitle:subtitle hideAfter:-1];
}

+(MKInfoPanel *)showPanelInWindow:(UIWindow *)window type:(MKInfoPanelType)type title:(NSString *)title subtitle:(NSString *)subtitle hideAfter:(NSTimeInterval)interval {
    MKInfoPanel *panel = [self showPanelInView:window type:type title:title subtitle:subtitle hideAfter:interval];
    
//    if (![UIApplication sharedApplication].statusBarHidden) {
//        CGRect frame = panel.frame;
//        frame.origin.y += [UIApplication sharedApplication].statusBarFrame.size.height;
//        panel.frame = frame;
//    }
    
    return panel;
}

-(void)hidePanel {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    CATransition *transition = [CATransition animation];
	transition.duration = 0.25;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type = kCATransitionPush;	
	transition.subtype = kCATransitionFromTop;
	[self.layer addAnimation:transition forKey:nil];
    self.frame = CGRectMake(0, -self.frame.size.height, self.frame.size.width, self.frame.size.height); 
    
    [self performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.25];
}

- (void)hidePanelImmediately{
    [self removeFromSuperview];
}


+(BOOL)hideAllPanelsImmediatelyUnderView:(UIView*)view
{
    BOOL flag = NO;
    for (UIView *subView in view.subviews) {
        if ([subView isKindOfClass:[MKInfoPanel class]]) {
            MKInfoPanel* panel = (MKInfoPanel*)subView;
//            [panel hidePanel];
            [panel hidePanelImmediately];
            flag = YES;
        }
    }
    
    return flag;
}


// Hides all panels under a view, returns success
+(BOOL)hideAllPanelsUnderView:(UIView*)view
{
    BOOL flag = NO;
    for (UIView *subView in view.subviews) {
        if ([subView isKindOfClass:[MKInfoPanel class]]) {
            MKInfoPanel* panel = (MKInfoPanel*)subView;
            [panel hidePanel];
            flag = YES;
        }
    }
    
    return flag;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Touch Recognition
////////////////////////////////////////////////////////////////////////

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//     objc_msgSend(self, _onTouched);
    [self performSelector:@selector(hidePanel) withObject:nil];
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private
////////////////////////////////////////////////////////////////////////

+(MKInfoPanel *)infoPanel {
    MKInfoPanel *panel =  (MKInfoPanel*) [[[UINib nibWithNibName:@"MKInfoPanel" bundle:nil] 
                                           instantiateWithOwner:self options:nil] objectAtIndex:0];
    
    CATransition *transition = [CATransition animation];
	transition.duration = 0.25;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type = kCATransitionPush;	
	transition.subtype = kCATransitionFromBottom;
	[panel.layer addAnimation:transition forKey:nil];
    
    CGFloat c = 0.0f;
    [panel setBackgroundColor:[UIColor colorWithRed:c green:c blue:c alpha:0.8f]];
    return panel;
}

- (void)setup {
    self.onTouched = @selector(hidePanel);
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

@end
