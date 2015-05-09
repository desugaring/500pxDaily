//
//  ASImage.m
//  FiveHundredPixelsDaily
//
//  Created by Alex Semenikhine on 2015-04-11.
//  Copyright (c) 2015 Alex Semenikhine. All rights reserved.
//

#import "ASImage.h"
#import "ASBaseOperation.h"
#import "ASCategory.h"
#import "ASStore.h"

@implementation ASImage

@dynamic thumbnailURL;
@dynamic fullURL;
@dynamic thumbnail;
@dynamic full;
@dynamic category;

@synthesize delegate;
@synthesize activeRequest;

- (ASBaseOperation *)operation {
    return self.category.operation;
}

- (void)awakeCommon {
    self.activeRequest = nil;
}

- (void)requestThumbnailImageIfNeeded {
    if (self.thumbnail == nil && self.activeRequest == nil) {
//        NSLog(@"requesting thumbnail for image named %@", self.name);
        ASBaseOperation *operation = [self operation];
        operation.object = self;
        operation.userInfo = @{ @"size": @"thumbnail" };
        operation.completion = ^(NSArray *results, NSError *error) {
            if (error != nil) {
                NSLog(@"url response error: %@", error);
            } else if (results.count > 0 && [results[0] isKindOfClass:NSData.class]){
                NSData *data = (NSData *)results[0];
                [self.managedObjectContext performBlockAndWait:^{
                    self.thumbnail = [UIImage imageWithData:data];
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.category imageThumbnailUpdated:self];
                });
            }
        };
        if (self.category.imagesDataQueue.operationCount != 0) [operation addDependency:self.category.imagesDataQueue.operations.firstObject];
        [self.category.thumbnailQueue addOperation:operation];
        self.activeRequest = operation;
    }
}

- (void)requestFullImageIfNeeded {
    if (self.full == nil && self.activeRequest == nil) {
        NSLog(@"requesting full for image named %@", self.name);
        ASBaseOperation *operation = [self operation];
        operation.object = self;
        operation.userInfo = @{ @"size": @"full" };
        operation.completion = ^(NSArray *results, NSError *error) {
            if (error != nil) {
                NSLog(@"url response error: %@", error);
            } else if (results.count > 0 && [results[0] isKindOfClass:NSData.class]){
                NSData *data = (NSData *)results[0];
                [self.managedObjectContext performBlockAndWait:^{
                    self.full = [UIImage imageWithData:data];
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.category imageFullUpdated:self];
                    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(imageFullUpdated:)]) [self.delegate imageFullUpdated:self];
                });
            }
        };
        if (self.category.imagesDataQueue.operationCount != 0) [operation addDependency:self.category.imagesDataQueue.operations.firstObject];
        [self.category.fullQueue addOperation:operation];
        self.activeRequest = operation;
    }
}

@end
