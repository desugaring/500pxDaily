//
//  ASStore.m
//  
//
//  Created by Alex Semenikhine on 2015-04-11.
//
//

#import "ASStore.h"
#import "ASCategory.h"

@implementation ASStore

@dynamic categories;

- (void)updateCategoriesIfNeeded {
    // Stub
}

- (NSMutableOrderedSet *)activeCategories {
    NSMutableOrderedSet *activeCategories = [NSMutableOrderedSet new];
    for (ASCategory *category in self.categories) {
        if ([category.status isEqualToNumber:@(0)] == false) [activeCategories addObject:category];
    }
    return activeCategories;
}

@end