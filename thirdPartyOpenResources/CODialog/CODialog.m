//
//  CODialog.m
//  CODialog
//
//  Created by Erik Aigner on 10.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "CODialog.h"
#import "CODialogWindowOverlay.h"

//@interface CODialogWindowOverlay : UIWindow
////@property (nonatomic, strong) CODialog *dialog;
//@end

@interface CODialog ()
@property (nonatomic, strong) CODialogWindowOverlay *overlay;
@property (nonatomic, strong) UIWindow *hostWindow;
//@property (nonatomic, strong) UIView *accessoryView;
@property (nonatomic, strong) UIFont *titleFont;
@end

//#define CODialogSynth(x) @synthesize x = x##_;
//#define CODialogAssertMQ() NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"%@ must be called on main queue", NSStringFromSelector(_cmd));



#define kCODialogAnimationDuration 0.1
#define kCODialogPopScale 0.66
#define kCODialogPadding 8.0
//#define kCODialogFrameInset 1.0
#define kCODialogButtonHeight 44.0
//#define kCODialogTextFieldHeight 29.0

#define degreesToRadian(x) (M_PI * (x) / 180.0)


struct {
    CGRect contentRect;
    CGRect titleRect;
    CGRect customRect;
    CGRect buttonContainerRect;
} layout;

@implementation CODialog {
    UILabel *titleLabel;
    NSMutableArray *buttons;
    UIView *contentView;
}

+ (instancetype)dialogWithWindow:(UIWindow *)hostWindow {
  return [[self alloc] initWithWindow:hostWindow];
}

- (id)initWithWindow:(UIWindow *)hostWindow {
  self = [super initWithFrame: CGRectZero];
  if (self) {
    self.transform = [self dialogTransform];
    self.bounds = [self defaultDialogBounds];
    self.batchDelay = 0;
//    self.highlightedIndex = -1;
    self.titleFont = [UIFont boldSystemFontOfSize:18.0];
    self.hostWindow = hostWindow;
    self.opaque = NO;
    self.alpha = 1.0;
    buttons = [NSMutableArray array];
      
      
    
    // Register for keyboard notifications
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(orientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)adjustToKeyboardBounds:(CGRect)bounds {
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat height = 0;
  CGRect frame = self.frame;
    
  switch ([UIApplication sharedApplication].statusBarOrientation) {
    case UIInterfaceOrientationPortrait:
      height = CGRectGetHeight(screenBounds) - CGRectGetHeight(bounds);
      frame.origin.y = (height - CGRectGetHeight(self.bounds)) / 2.0;
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
      height = CGRectGetHeight(screenBounds) - CGRectGetHeight(bounds);
      frame.origin.y = (height - CGRectGetHeight(self.bounds)) / 2.0 + CGRectGetHeight(bounds);
      break;
    case UIInterfaceOrientationLandscapeLeft:
      height = CGRectGetWidth(screenBounds) - CGRectGetWidth(bounds);
      frame.origin.x = (height - CGRectGetWidth(self.bounds)) / 2.0;
      break;
    case UIInterfaceOrientationLandscapeRight:
      height = CGRectGetWidth(screenBounds) - CGRectGetWidth(bounds);
      frame.origin.x = (height - CGRectGetWidth(self.bounds)) / 2.0  + CGRectGetWidth(bounds);
      break;
    default:
      break;
  }
  
  if (CGRectGetMinY(frame) < 0) {
    NSLog(@"warning: dialog is clipped, origin negative (%f)", CGRectGetMinY(frame));
  }
  
  [UIView animateWithDuration:kCODialogAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
    self.frame = frame;
  } completion:^(BOOL finished) {
    // stub
  }];
}

#pragma mark - observer actions

- (void)keyboardWillShow:(NSNotification *)note {
  NSValue *value = [[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
  CGRect frame = [value CGRectValue];
  
  [self adjustToKeyboardBounds:frame];
}

- (void)keyboardWillHide:(NSNotification *)note {
  [self adjustToKeyboardBounds:CGRectZero];
}

- (void)orientationChanged:(NSNotification*)notification
{
  [UIView animateWithDuration:0.3
                   animations:^{
                     [self setTransform: [self dialogTransform]];
                   }];
  
}


#pragma mark - transforms

- (CGAffineTransform)dialogTransform{
  CGAffineTransform transform = CGAffineTransformIdentity;
  switch ([UIApplication sharedApplication].statusBarOrientation) {
    case UIInterfaceOrientationPortrait:
      transform = CGAffineTransformMakeRotation(degreesToRadian(0));
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
      transform = CGAffineTransformMakeRotation(degreesToRadian(180));
      break;
    case UIInterfaceOrientationLandscapeLeft:
      transform = CGAffineTransformMakeRotation(degreesToRadian(270));
      break;
    case UIInterfaceOrientationLandscapeRight:
      transform = CGAffineTransformMakeRotation(degreesToRadian(90));
      break;
    default:
      break;
  }
  return transform;
}


#pragma mark - bounds

- (CGRect)defaultDialogBounds {
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    CGRect insetFrame = CGRectZero;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    insetFrame.size.width = 380;
    } else {
    insetFrame.size.width = 300;
    }
    insetFrame.size.height = MIN(appFrame.size.width, appFrame.size.height) - 40;
    return insetFrame;
}

#pragma mark - bounds properties

- (CGFloat)contentW{
    return CGRectGetWidth(layout.contentRect);
}

- (CGFloat)contentX{
    return CGRectGetMinX(layout.contentRect);
}

#pragma mark - assemblers

- (void)assembleContentView{
    if (contentView == nil) {
        contentView = [[UIView alloc] init];
        [contentView setClipsToBounds:YES];
        [self addSubview:contentView];
        
        [contentView setBackgroundColor:[UIColor clearColor]];
        
        
//        if ([[[UIDevice currentDevice] systemVersion] doubleValue] < 7.0){
//            [self setBackgroundColor:[UIColor whiteColor]];
//            [self.layer setCornerRadius:10.0];
//        }else{
//            [self setCornerRadius:10.0];
//        }
    }
}

- (void)assembleTitleView{
    if (titleLabel == nil) {
        titleLabel = [[UILabel alloc] init];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
        [titleLabel setFont:self.titleFont];
        [contentView addSubview:titleLabel];
    }
    [titleLabel setText:self.title];
}

- (void)assembleCustomView{
    self.customView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    [contentView addSubview:self.customView];
}

- (void)assembleButtons{
    NSUInteger count = buttons.count;
    for (int i=0; i<count; i++) {
        UIButton *button = [buttons objectAtIndex:i];
        [contentView addSubview:button];
    }
}

#pragma mark - layout actions



- (void)layoutTitleView{
    // frame
    CGFloat titleHeight = 0;
    CGFloat targetY = CGRectGetMinY(layout.contentRect);
    if (self.title.length > 0) {
        titleHeight = [self.title sizeWithFont:self.titleFont
                             constrainedToSize:CGSizeMake(self.contentW, MAXFLOAT)
                                 lineBreakMode:NSLineBreakByWordWrapping].height;
        //      NSLineBreakMode
//        targetY += kCODialogPadding;
    }
    
//    TLOG(@"contentX -> %f self.diagW -> %f minY -> %f", self.contentX, self.contentW,minY);
    
    //component
    layout.titleRect = CGRectMake(0, targetY, self.contentW, titleHeight);
    [titleLabel setFrame:layout.titleRect];
//    [titleLabel.layer setBorderWidth:1];
    
    // Adjust layout frame
    layout.contentRect.size.height = CGRectGetMaxY(layout.titleRect);
}



- (void)layoutCustomView{
    CGFloat h = 0;
    CGFloat w = 0;
    CGFloat x = 0;
    
    CGFloat targetY = CGRectGetMaxY(layout.titleRect);
    h = CGRectGetHeight(self.customView.frame);
    w = CGRectGetWidth(self.customView.frame);
    x = (CGRectGetWidth(layout.contentRect) - w) / 2.0;
    layout.customRect = CGRectMake(x, targetY, w, h);
    
    // Layout accessory view
    [self.customView setFrame:layout.customRect];
    
//    [self.customView.layer setBorderWidth:1.0];
    
    // Adjust layout frame
    layout.contentRect.size.height = CGRectGetMaxY(layout.customRect);
}



- (void)layoutButtons{
        // Buttons frame (note that views are in the content view coordinate system)
    CGFloat buttonsHeight = 0;
    CGFloat targetY = CGRectGetMaxY(layout.contentRect);
    if (buttons.count > 0) {
        buttonsHeight = kCODialogButtonHeight;
//        targetY += kCODialogPadding;
    }
    layout.buttonContainerRect = CGRectMake(self.contentX, targetY, self.contentW, buttonsHeight);
    
    // Adjust layout frame
    layout.contentRect.size.height = CGRectGetMaxY(layout.buttonContainerRect);
    
    
    
    
    NSUInteger count = buttons.count;
    if (count > 0) {
        CGFloat buttonWidth = (CGRectGetWidth(layout.buttonContainerRect) - kCODialogPadding * ((CGFloat)count - 1.0)) / (CGFloat)count;
        
        for (int i=0; i<count; i++) {
            CGFloat left = (kCODialogPadding + buttonWidth) * (CGFloat)i;
            CGRect buttonFrame = CGRectIntegral(CGRectMake(left, CGRectGetMinY(layout.buttonContainerRect), buttonWidth, CGRectGetHeight(layout.buttonContainerRect)));
            
            UIButton *button = [buttons objectAtIndex:i];
            button.frame = buttonFrame;
            button.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
//            [button.layer setBorderWidth:1.0];
        }
    }
}




- (void)layoutDialogView{
    
//    TLOG(@"%@", NSStringFromCGRect(layout.diagRect));
    
    CGRect dialogFrame = CGRectInset(layout.contentRect,  - kCODialogPadding,  - kCODialogPadding);
    //        dialogFrame = layout.diagRect;
    self.bounds = (CGRect){CGPointZero, dialogFrame.size};
    dialogFrame = self.frame;
    dialogFrame.origin.x = (CGRectGetWidth(self.hostWindow.bounds) - CGRectGetWidth(dialogFrame)) / 2.0;
    dialogFrame.origin.y = (CGRectGetHeight(self.hostWindow.bounds) - CGRectGetHeight(dialogFrame)) / 2.0;
    
    self.frame = CGRectIntegral(dialogFrame);
}

- (void)layoutContentView{
    [contentView setFrame:layout.contentRect];
}


- (void)layoutComponents {
    [self setNeedsDisplay];
    
    layout.contentRect = CGRectInset(self.bounds, kCODialogPadding, kCODialogPadding);
    [self assembleContentView];
    [self assembleTitleView];
    [self assembleCustomView];
    [self assembleButtons];
    
    [self layoutTitleView];
    [self layoutCustomView];
    [self layoutButtons];
    [self layoutContentView];
    [self layoutDialogView];
}

#pragma mark - animation actions


#pragma mark - components

- (void)addButtonWithTitle:(NSString *)title target:(id)target selector:(SEL)sel {
  [self addButtonWithTitle:title target:target selector:sel highlighted:NO];
}

- (void)addButtonWithTitle:(NSString *)title target:(id)target selector:(SEL)sel highlighted:(BOOL)flag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//    button = [DSButtonCreator createButtonWithTitle:title target:target action:sel];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRed:0 green:120.0/255.0 blue:252.0/255.0 alpha:1] forState:UIControlStateNormal];
    [button addTarget:target action:sel forControlEvents:UIControlEventTouchUpInside];
    [buttons addObject:button];
}

#pragma mark - main actions

- (void)showOrUpdateAnimatedInternal:(BOOL)flag {
//  CODialogAssertMQ();
  
  CODialogWindowOverlay *overlay = self.overlay;
  BOOL show = (overlay == nil);
  
  // Create overlay
  if (show) {
    self.overlay = overlay = [[CODialogWindowOverlay alloc] initWithFrame:self.hostWindow.bounds];
  }
  
  // Layout components
    [self layoutComponents];
    [overlay addSubview:self];
    [overlay makeKeyAndVisible];
  
    if (show) {
      [self playShowDialogAnimation:overlay];
    }
    
    
}

- (void)playShowDialogAnimation:(CODialogWindowOverlay *)overlay{
    CGAffineTransform originTransform = [self dialogTransform];
    self.transform = CGAffineTransformScale(originTransform, 1.3, 1.3);
    overlay.backgroundView.alpha = 0;
//    self.alpha = 0;
//    self.translucentAlpha = 0.6;
    self.customView.alpha = 1;
    // Animate
    NSTimeInterval animationDuration = 0.25;
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        overlay.backgroundView.alpha = 0.4235;
        self.transform = originTransform;
//        self.translucentAlpha = 1;
    } completion:^(BOOL finished) {
        // stub
    }];
}

- (void)showOrUpdateAnimated:(BOOL)flag {
//    int a = 1;
//    int b = 2;
//NSAssert(a==b, @"%@ must be called on main queue", NSStringFromSelector(_cmd));
//  CODialogAssertMQ();
  SEL selector = @selector(showOrUpdateAnimatedInternal:);
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:selector object:nil];
  [self performSelector:selector withObject:[NSNumber numberWithBool:flag] afterDelay:self.batchDelay];
}

- (void)hideAnimated:(BOOL)flag {
//  CODialogAssertMQ();
  
  CODialogWindowOverlay *overlay = self.overlay;
  
  // Nothing to hide if it is not key window
  if (overlay == nil) {
    return;
  }
  
  NSTimeInterval animationDuration = 0.165;
//    animationDuration = .33;
//    self.translucentAlpha = 1;
    self.customView.alpha = 1;
    overlay.backgroundView.alpha = 0.4235;
  [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
    overlay.backgroundView.alpha = 0;
    self.transform = CGAffineTransformScale([self dialogTransform], 0.8, 0.8);
//      self.translucentAlpha = 0;
      self.customView.alpha = 0;
  } completion:^(BOOL finished) {
    overlay.hidden = YES;
    self.transform = [self dialogTransform];
    [self removeFromSuperview];
    self.overlay = nil;
    
    // Rekey host window
    // https://github.com/eaigner/CODialog/issues/6
    //
    [self.hostWindow makeKeyWindow];
  }];
}

- (void)hideAnimated:(BOOL)flag afterDelay:(NSTimeInterval)delay {
//  CODialogAssertMQ();
  
  SEL selector = @selector(hideAnimated:);
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:selector object:nil];
  [self performSelector:selector withObject:[NSNumber numberWithBool:flag] afterDelay:delay];
}


@end

