//
//  MainMenuScene.m
//  ZombieConga
//
//  Created by Dru Lang on 1/4/15.
//  Copyright (c) 2015 drulang. All rights reserved.
//

#import "MainMenuScene.h"
#import "GameScene.h"

@implementation MainMenuScene

- (instancetype)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    if (self) {
        SKNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"MainMenu.png"];
        bg.position = CGPointMake(self.size.width / 2, self.size.height /2);
        [self addChild:bg];
    }
    
    return self;
}

# pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    GameScene *scene = [[GameScene alloc] initWithSize:self.size];
    SKTransition *doorway = [SKTransition doorsOpenHorizontalWithDuration:1];
    [self.view presentScene:scene transition:doorway];
}

@end
