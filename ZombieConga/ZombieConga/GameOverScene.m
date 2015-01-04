//
//  GameOverScene.m
//  ZombieConga
//
//  Created by Dru Lang on 1/4/15.
//  Copyright (c) 2015 drulang. All rights reserved.
//

#import "GameOverScene.h"
#import "GameScene.h"

@implementation GameOverScene


- (instancetype)initWithSize:(CGSize)size won:(BOOL)won {
    self = [super initWithSize:size];
    
    if (self) {
        SKSpriteNode *bg;
        if (won) {
            bg = [SKSpriteNode spriteNodeWithImageNamed:@"YouWin.png"];
            SKAction *sequence = [SKAction sequence:@[
                                                      [SKAction waitForDuration:.1],
                                                      [SKAction playSoundFileNamed:@"win.wav" waitForCompletion:NO],
                                                      ]];
            [self runAction:sequence];
        } else {
            bg = [SKSpriteNode spriteNodeWithImageNamed:@"YouLose.png"];
            
            SKAction *sequence = [SKAction sequence:@[
                                                      [SKAction waitForDuration:.1],
                                                      [SKAction playSoundFileNamed:@"lose.wav" waitForCompletion:NO],
                                                      ]];
            [self runAction:sequence];
        }
        
        bg.position = CGPointMake(self.size.width/2, self.size.height/2);
        [self addChild:bg];
        
        //Wait a few seconds then transition to the main screen
        SKAction *wait = [SKAction waitForDuration:5];
        SKAction *block = [SKAction runBlock:^{
            GameScene *gameScene = [[GameScene alloc] initWithSize:self.size];
            SKTransition *reveal = [SKTransition flipHorizontalWithDuration:.5];
            [self.view presentScene:gameScene transition:reveal];
        }];
        [self runAction:[SKAction sequence:@[wait, block]]];
    }
    
    return self;
}

@end
