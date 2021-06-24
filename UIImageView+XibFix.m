//
//  UIImageView+XibFix.m
//  HTComponents
//
//  Created by mac on 2021/6/23.
//

#import "UIImageView+XibFix.h"

void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector)
{
    // the method might not exist in the class, but in its superclass
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    // class_addMethod will fail if original method already exists
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    // the method doesn’t exist and we just added one
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
}

@interface UIImage (XibFix)
@property (nonatomic, copy) NSString *xibFixImageName;
@end

@implementation UIImage (XibFix)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzleMethod(NSClassFromString(@"UIImageNibPlaceholder"), @selector(initWithCoder:), @selector(swizzle_image_ht_initWithCoder:));
    });
}

- (void)setXibFixImageName:(NSString *)xibFixImageName {
    objc_setAssociatedObject(self, @selector(xibFixImageName), xibFixImageName, OBJC_ASSOCIATION_COPY);
}

- (NSString *)xibFixImageName {
    return objc_getAssociatedObject(self, @selector(xibFixImageName));
}

- (instancetype)swizzle_image_ht_initWithCoder:(NSCoder *)coder {
    UIImage *image = [self swizzle_image_ht_initWithCoder:coder];
    image.xibFixImageName = [coder decodeObjectForKey:@"UIResourceName"];
    return image;
}

@end

@implementation UIImageView (XibFix)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzleMethod([self class], @selector(initWithCoder:), @selector(swizzle_initWithCoder:));
        swizzleMethod([self class], @selector(setImage:), @selector(swizzle_setImage:));
    });
}

- (instancetype)swizzle_initWithCoder:(NSCoder *)coder {
    UIImageView *imageView = [self swizzle_initWithCoder:coder];
    imageView.image = imageView.image;
    return imageView;
}

- (void)swizzle_setImage:(UIImage *)image {
    if ([image.xibFixImageName isKindOfClass:NSString.class] && image.xibFixImageName.length > 0) {
        [self swizzle_setImage:[UIImage imageNamed:image.xibFixImageName]];
    } else {
        [self swizzle_setImage:image];
    }
}

@end
