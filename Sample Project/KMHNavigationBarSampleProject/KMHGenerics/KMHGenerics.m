//
//  KMHGenerics.m
//  KMHNavigationBarSampleProject
//
//  Created by Ken M. Haggerty on 9/22/16.
//  Copyright © 2016 Ken M. Haggerty. All rights reserved.
//

#pragma mark - // NOTES (Private) //

#pragma mark - // IMPORTS (Private) //

#import "KMHGenerics.h"
#import <objc/runtime.h>

#pragma mark - // NSObject //

@implementation NSObject (KMHGenerics)

#pragma mark Public Methods

// copied w/ modifications via Mattt Thompson's tutorial at http://nshipster.com/method-swizzling/
- (void)swizzleMethod:(SEL)originalSelector withMethod:(SEL)swizzledSelector {
    Class class = [self class];
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    // When swizzling a class method, use the following:
    // Class class = object_getClass((id)self);
    // ...
    // Method originalMethod = class_getClassMethod(class, originalSelector);
    // Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
    
    BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (success) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end

#pragma mark - // UINavigationItem //

#pragma mark Notifications

NSString * const UINavigationItemNotificationObjectKey = @"kUINavigationItemNotificationObjectKey";

NSString * const UINavigationItemTitleDidChangeNotification = @"kUINavigationItemTitleDidChangeNotification";
NSString * const UINavigationItemPromptDidChangeNotification = @"kUINavigationItemPromptDidChangeNotification";
NSString * const UINavigationItemHidesBackButtonDidChangeNotification = @"kUINavigationItemHidesBackButtonDidChangeNotification";

@implementation UINavigationItem (KMHGenerics)

#pragma mark Setters and Getters

- (void)setHidesTitleView:(BOOL)hidesTitleView {
    if (hidesTitleView == self.hidesTitleView) {
        return;
    }
    
    objc_setAssociatedObject(self, @selector(hidesTitleView), @(hidesTitleView), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (hidesTitleView) {
        self.storedTitleView = self.titleView;
        self.titleView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    else {
        self.titleView = self.storedTitleView;
        self.storedTitleView = nil;
    }
}

- (BOOL)hidesTitleView {
    NSNumber *hidesTitleViewValue = objc_getAssociatedObject(self, @selector(hidesTitleView));
    if (hidesTitleViewValue) {
        return hidesTitleViewValue.boolValue;
    }
    
    objc_setAssociatedObject(self, @selector(hidesTitleView), @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self.hidesTitleView;
}

- (void)setBackBarButtonItemIsHidden:(BOOL)backBarButtonItemIsHidden {
    if (backBarButtonItemIsHidden == self.backBarButtonItemIsHidden) {
        return;
    }
    
    objc_setAssociatedObject(self, @selector(backBarButtonItemIsHidden), @(backBarButtonItemIsHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (backBarButtonItemIsHidden) {
        self.storedBackBarButtonItem = self.backBarButtonItem;
        self.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    else {
        self.backBarButtonItem = self.storedBackBarButtonItem;
        self.storedBackBarButtonItem = nil;
    }
}

- (BOOL)backBarButtonItemIsHidden {
    NSNumber *backBarButtonItemIsHiddenValue = objc_getAssociatedObject(self, @selector(backBarButtonItemIsHidden));
    if (backBarButtonItemIsHiddenValue) {
        return backBarButtonItemIsHiddenValue.boolValue;
    }
    
    objc_setAssociatedObject(self, @selector(backBarButtonItemIsHidden), @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self.backBarButtonItemIsHidden;
}

- (void)setStoredTitleView:(UIView *)storedTitleView {
    objc_setAssociatedObject(self, @selector(storedTitleView), storedTitleView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)storedTitleView {
    return objc_getAssociatedObject(self, @selector(storedTitleView));
}

- (void)setStoredBackBarButtonItem:(UIBarButtonItem *)storedBackBarButtonItem {
    objc_setAssociatedObject(self, @selector(storedBackBarButtonItem), storedBackBarButtonItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIBarButtonItem *)storedBackBarButtonItem {
    return objc_getAssociatedObject(self, @selector(storedBackBarButtonItem));
}

#pragma mark Inits and Loads

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethod:@selector(setPrompt:) withMethod:@selector(swizzled_setPrompt:)];
        [self swizzleMethod:@selector(setTitle:) withMethod:@selector(swizzled_setTitle:)];
        [self swizzleMethod:@selector(setHidesBackButton:) withMethod:@selector(swizzled_setHidesBackButton:)];
    });
}

#pragma mark Swizzled Methods

- (void)swizzled_setPrompt:(NSString *)prompt {
    if ((!prompt && !self.prompt) || ([prompt isEqualToString:self.prompt])) {
        return;
    }
    
    [self swizzled_setPrompt:prompt];
    
    NSDictionary *userInfo = prompt ? @{UINavigationItemNotificationObjectKey : prompt} : @{};
    [[NSNotificationCenter defaultCenter] postNotificationName:UINavigationItemPromptDidChangeNotification object:self userInfo:userInfo];
}

- (void)swizzled_setTitle:(NSString *)title {
    if ((!title && !self.title) || ([title isEqualToString:self.title])) {
        return;
    }
    
    [self swizzled_setTitle:title];
    
    NSDictionary *userInfo = title ? @{UINavigationItemNotificationObjectKey : title} : @{};
    [[NSNotificationCenter defaultCenter] postNotificationName:UINavigationItemTitleDidChangeNotification object:self userInfo:userInfo];
}

- (void)swizzled_setHidesBackButton:(BOOL)hidesBackButton {
    if (hidesBackButton == self.hidesBackButton) {
        return;
    }
    
    [self swizzled_setHidesBackButton:hidesBackButton];
    
    NSDictionary *userInfo = @{UINavigationItemNotificationObjectKey : @(hidesBackButton)};
    [[NSNotificationCenter defaultCenter] postNotificationName:UINavigationItemHidesBackButtonDidChangeNotification object:self userInfo:userInfo];
}


@end

#pragma mark - // UIView //

@implementation UIView (KMHGenerics)

#pragma mark Public Methods

- (void)updateConstraintsWithDuration:(NSTimeInterval)duration block:(void (^)(void))block {
    if (block) {
        block();
    }
    [self setNeedsUpdateConstraints];
    [UIView animateWithDuration:duration animations:^{
        [self layoutIfNeeded];
    }];
}

@end

#pragma mark - // UIViewController //

#pragma mark Notifications

//NSString * const UIViewControllerNotificationObjectKey = @"kUIViewControllerNotificationObjectKey";
//
//NSString * const UIViewControllerWillBePushedNotification = @"kUIViewControllerWillBePushedNotification";
//NSString * const UIViewControllerWillPopNotification =  @"kUIViewControllerWillPopNotification";
//NSString * const UIViewControllerDidPopNotification =  @"kUIViewControllerDidPopNotification";

@implementation UIViewController (KMHGenerics)

#pragma mark Inits and Loads

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethod:@selector(viewWillDisappear:) withMethod:@selector(swizzled_viewWillDisappear:)];
        [self swizzleMethod:@selector(viewDidDisappear:) withMethod:@selector(swizzled_viewDidDisappear:)];
    });
}

#pragma mark Public Methods

- (void)viewWillBePushed:(BOOL)animated {
//    NSDictionary *userInfo = @{UIViewControllerNotificationObjectKey : @(animated)};
//    [[NSNotificationCenter defaultCenter] postNotification:UIViewControllerWillBePushedNotification object:self userInfo:userInfo];
}

- (void)viewDidPop:(BOOL)animated {
//    NSDictionary *userInfo = @{UIViewControllerNotificationObjectKey : @(animated)};
//    [[NSNotificationCenter defaultCenter] postNotification:UIViewControllerDidPopNotification object:self userInfo:userInfo];
}

- (void)viewWillPop:(BOOL)animated {
//    NSDictionary *userInfo = @{UIViewControllerNotificationObjectKey : @(animated)};
//    [[NSNotificationCenter defaultCenter] postNotification:UIViewControllerWillPopNotification object:self userInfo:userInfo];
}

#pragma mark Swizzled Methods

- (void)swizzled_viewWillDisappear:(BOOL)animated {
    [self swizzled_viewWillDisappear:animated];
    
    if (!self.navigationController) {
        return;
    }
    
    if (self.isMovingFromParentViewController) {
        [self viewWillPop:animated];
    }
    else if (!self.isMovingFromParentViewController) {
        [self viewWillBePushed:animated];
    }
}

- (void)swizzled_viewDidDisappear:(BOOL)animated {
    [self swizzled_viewDidDisappear:animated];
    
    if (self.isMovingFromParentViewController) {
        [self viewDidPop:animated];
    }
}

@end
