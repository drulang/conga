//
//  GameScene.m
//  ZombieConga
//
//  Created by Dru Lang on 12/23/14.
//  Copyright (c) 2014 drulang. All rights reserved.
//

#import "GameScene.h"
#import "GameOverScene.h"
@import AVFoundation;

#define ARC4RANDOM_MAX 0x100000000

static inline CGFloat ScalarRandomRange(CGFloat min, CGFloat max) {
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) * (max-min) + min);
}

static inline CGPoint CGPointAdd(const CGPoint a, const CGPoint b) {
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint CGPointSubtract(const CGPoint a, const CGPoint b) {
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint CGPointMultiplyScalar(const CGPoint a, const CGFloat scalar) {
    return CGPointMake(a.x * scalar, a.y * scalar);
}

static inline CGFloat CGPointLength(const CGPoint a) {
    return sqrtf(a.x * a.x + a.y * a.y); //Pythagorean Theorm
}

static inline CGPoint CGPointNormalize(const CGPoint a) {
    CGFloat length = CGPointLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

static inline CGFloat CGPointToAngle(const CGPoint a) {
    return atan2f(a.y, a.x);
}

static const float ZOMBIE_MOVE_POINTS_PER_SEC = 120.0;
static const float CAT_MOVE_POINTS_PER_SEC = 120.0;

@implementation GameScene {
    SKSpriteNode *_zombie;
    CGPoint _velocity;
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    SKAction *_zombieAnimation;
    SKAction *_catCollisionSound;
    SKAction *_enemeyCollisionSound;
    BOOL _zombieInvincible;
    BOOL _gameOver;
    int _lives;
    AVAudioPlayer *_backgroundMusicPlayer;
}

- (instancetype)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [UIColor whiteColor];
        _gameOver = NO;
        _lives = 5;
        
        // Build background
        SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
        bg.position = CGPointMake(self.size.width / 2, self.size.height / 2);
        bg.anchorPoint = CGPointMake(.5, .5);
        [self playBackgroundMusic:@"bgMusic.mp3"];
        
        //Add zombie
        _zombie = [SKSpriteNode spriteNodeWithImageNamed:@"zombie1"];
        _zombie.position = CGPointMake(100, 100);
        _zombie.zPosition = 100;
        
        //1
        NSMutableArray *textures = [NSMutableArray arrayWithCapacity:10];
        //2
        for (int i =1; i < 4; i++) {
            NSString *textureName = [NSString stringWithFormat:@"zombie%d", i];
            SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
            [textures addObject:texture];
        }
        //3
        for (int i = 4; i > 1; i--) {
            NSString *textureName = [NSString stringWithFormat:@"zombie%d", i];
            SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
            [textures addObject:texture];
        }
        //4
        _zombieAnimation = [SKAction animateWithTextures:textures timePerFrame:.1];
        //5
        [self startZombieAnimation];
        
        [self addChild:bg];
        [self addChild:_zombie];
        
        //Generate enemy
        SKAction  *spawnEnemyAction = [SKAction performSelector:@selector(spawnEnemy) onTarget:self];
        SKAction *wait = [SKAction waitForDuration:2];
        SKAction *sequence =[SKAction sequence: @[spawnEnemyAction, wait]];
        [self runAction:[SKAction repeatActionForever:sequence]];
        
        //Generate cats
        SKAction *generateCatAction = [SKAction performSelector:@selector(spawnCat) onTarget:self];
        SKAction *catSpawnWait = [SKAction waitForDuration:1];
        SKAction *catSequence = [SKAction sequence:@[generateCatAction, catSpawnWait]];
        [self runAction:[SKAction repeatActionForever:catSequence]];
        
        //Preload sounds
        _catCollisionSound = [SKAction playSoundFileNamed:@"hitCat.wav" waitForCompletion:NO];
        _enemeyCollisionSound = [SKAction playSoundFileNamed:@"hitCatLady.wav" waitForCompletion:NO];
        
    }
    return self;
}

- (void)update:(NSTimeInterval)currentTime {
    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }
    _lastUpdateTime = currentTime;
    //NSLog(@"%0.2f milliseconds since last update", _dt * 1000);
    
    [self boundsCheckPlayer];
    [self rotateSprite:_zombie toFace:_velocity];
    //NSLog(@"Velocity: %@", NSStringFromCGPoint(_velocity));
    [self moveSprite:_zombie velocity:_velocity];
    [self moveTrain];
    
    if (_lives <= 0 && !_gameOver) {
        _gameOver = YES;
        NSLog(@"You Lose");
        [_backgroundMusicPlayer stop];
        //1
        SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:NO];
        //2
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:.5];
        [self.view presentScene:gameOverScene transition:reveal];
    }
}

- (void)didEvaluateActions {
    [self checkCollisions];
}

- (void)spawnEnemy {
    SKSpriteNode *enemy = [SKSpriteNode spriteNodeWithImageNamed:@"enemy"];
    enemy.name = @"enemy";
    
    CGFloat enemyY = ScalarRandomRange(enemy.size.height / 2, self.size.height - enemy.size.height / 2);
    enemy.position = CGPointMake(self.size.width + (enemy.size.width/2), enemyY);
    [self addChild:enemy];
    
    SKAction *actionMove = [SKAction moveTo:CGPointMake(-enemy.size.width /2, enemy.position.y) duration:2.0];
    SKAction *actionRemove = [SKAction removeFromParent];
    SKAction *sequence = [SKAction sequence:@[actionMove, actionRemove]];
    [enemy runAction:sequence];
}

- (void)spawnCat {
    //1
    SKSpriteNode *cat = [SKSpriteNode spriteNodeWithImageNamed:@"cat"];
    cat.name = @"cat";
    
    CGFloat catX = ScalarRandomRange(0, self.size.width);
    CGFloat catY = ScalarRandomRange(0, self.size.height);
    cat.position = CGPointMake(catX, catY);
    cat.xScale = 0;
    cat.yScale = 0;
    cat.zRotation = -M_PI / 16;
    [self addChild:cat];
    
    //2
    SKAction *appear = [SKAction scaleTo:1 duration:.5];
    SKAction *leftWiggle = [SKAction rotateByAngle:M_PI / 8 duration:.3];
    SKAction *rightWiggle = [leftWiggle reversedAction];
    SKAction *fullWiggle = [SKAction sequence:@[leftWiggle, rightWiggle]];
    
    SKAction *scaleUp = [SKAction scaleBy:1.2 duration:0.25];
    SKAction *scaleDown = [scaleUp reversedAction];
    SKAction *fullScale = [SKAction sequence:@[scaleUp, scaleDown, scaleUp, scaleDown]];
    
    SKAction *group = [SKAction group:@[fullScale, fullWiggle]];
    SKAction *groupWait = [SKAction repeatAction:group count:10];
    
    SKAction *disapear = [SKAction scaleTo:0 duration:.5];
    SKAction *remove = [SKAction removeFromParent];
    
    SKAction *sequence = [SKAction sequence:@[appear, groupWait, disapear, remove]];
    [cat runAction:sequence];
}

- (void)moveSprite:(SKSpriteNode *)sprite velocity:(CGPoint)velocity {
    CGPoint amountToMove = CGPointMultiplyScalar(_velocity, _dt);
    
    //NSLog(@"Amount to move: %@", NSStringFromCGPoint(amountToMove));
    sprite.position = CGPointAdd(sprite.position, amountToMove);
}

- (void)moveZombieToward:(CGPoint)location {
    CGPoint offset = CGPointSubtract(location, _zombie.position);
    
    CGPoint direction = CGPointNormalize(offset);
    _velocity = CGPointMultiplyScalar(direction, ZOMBIE_MOVE_POINTS_PER_SEC);
}

- (void)boundsCheckPlayer {
    //1
    CGPoint newPosition = _zombie.position;
    CGPoint newVelocity = _velocity;
    
    //2
    CGPoint bottomLeft = CGPointZero;
    CGPoint topRight = CGPointMake(self.size.width, self.size.height);
    
    //3
    if (newPosition.x <= bottomLeft.x) {
        newPosition.x = bottomLeft.x;
        newVelocity.x = -newVelocity.x;
    }
    
    if (newPosition.x >= topRight.x) {
        newPosition.x = topRight.x;
        newVelocity.x = -newVelocity.x;
    }
    
    if (newPosition.y <= bottomLeft.y) {
        newPosition.y = bottomLeft.y;
        newVelocity.y = -newVelocity.y;
    }
    
    if (newPosition.y >= topRight.y) {
        newPosition.y = topRight.y;
        newVelocity.y = -newVelocity.y;
    }
    
    //4
    _zombie.position = newPosition;
    _velocity = newVelocity;
}

- (void)checkCollisions {
    //Try cats
    [self enumerateChildNodesWithName:@"cat" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *cat = (SKSpriteNode *)node;
        if (CGRectIntersectsRect(cat.frame, _zombie.frame)) {
            [self runAction:_catCollisionSound];
            
            //Make the cat follow the zombie
            cat.name = @"train";
            [cat removeAllActions];
            SKAction *scale = [SKAction scaleTo:1 duration:.3];
            [cat runAction:scale];
            cat.zRotation = 0;
            
            SKAction *turnGreen = [SKAction colorizeWithColor:[UIColor greenColor] colorBlendFactor:1 duration:.2];
  
            SKAction *normalColor = [turnGreen reversedAction];
            SKAction *sequence = [SKAction sequence:@[turnGreen, normalColor]];
            [cat runAction:sequence];
        }
    }];
    
    //Check Enemy
    [self enumerateChildNodesWithName:@"enemy" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *enemy = (SKSpriteNode *)node;
        CGRect smallerFrame = CGRectInset(enemy.frame, 20, 20);
        if (CGRectIntersectsRect(smallerFrame, _zombie.frame) && !_zombieInvincible) {
            //Zombie collided with the enemy so make him invincible and start blinking to show
            [self runAction:_enemeyCollisionSound];
            [self loseCats];
            _lives--;
            _zombieInvincible = YES;
            
            //Make zombie blink
            float blinkTimes = 10;
            float blinkDuration = 3;
            SKAction *blinkAction = [SKAction customActionWithDuration:blinkDuration actionBlock:^(SKNode *node, CGFloat elapsedTime) {
                float slice = blinkDuration / blinkTimes;
                float remainder = fmodf(elapsedTime, slice);
                node.hidden = remainder > slice / 2;
                if (elapsedTime == blinkDuration) {
                    node.hidden = NO;
                    _zombieInvincible = NO;
                }
            }];
            _zombie.hidden = NO;
            [_zombie runAction:blinkAction];
        }
    }];
}

- (void)rotateSprite:(SKSpriteNode *)sprite toFace:(CGPoint)direction{
    sprite.zRotation = CGPointToAngle(direction);
}

- (void)moveTrain {
    __block CGPoint targetPosition = _zombie.position;
    __block int trainCount = 0;
    
    [self enumerateChildNodesWithName:@"train" usingBlock:^(SKNode *node, BOOL *stop) {
        trainCount++;
        if (!node.hasActions) {
            float actionDuration = .3;
            
            CGPoint offset = CGPointSubtract(targetPosition, node.position); //a
            CGPoint direction = CGPointNormalize(offset); //b, unit vector
            CGPoint amountToMovePerSec = CGPointMultiplyScalar(direction, CAT_MOVE_POINTS_PER_SEC); //C
            CGPoint amountToMove = CGPointMultiplyScalar(amountToMovePerSec, actionDuration); //d

            SKAction *moveAction = [SKAction moveByX:amountToMove.x y:amountToMove.y duration:actionDuration];
            [node runAction:moveAction];
        }
        targetPosition = node.position; //Will point to the next cat in line on next iteration
    }];
    
    if (trainCount >= 30 && !_gameOver) {
        _gameOver = YES;
        NSLog(@"You win!");
        [_backgroundMusicPlayer stop];
        //1
        SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:YES];
        //2
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:.5];
        [self.view presentScene:gameOverScene transition:reveal];
    }
}

- (void)loseCats {
    //1
    __block int loseCount = 0;
    
    [self enumerateChildNodesWithName:@"train" usingBlock:^(SKNode *node, BOOL *stop) {
        //2
        CGPoint randomSpot = node.position;
        randomSpot.x += ScalarRandomRange(-100, 100);
        randomSpot.y += ScalarRandomRange(-100, 100);
        
        //3
        node.name = @"";
        SKAction *group = [SKAction group:@[
                                            [SKAction rotateByAngle:M_PI * 4 duration:1],
                                            [SKAction moveTo:randomSpot duration:1],
                                            [SKAction scaleTo:0 duration:1]
                                            ]];
        SKAction *sequence = [SKAction sequence:@[group, [SKAction removeFromParent]]];
        [node runAction: sequence];
        
        // 4
        loseCount++;
        if (loseCount >= 2) {
            *stop = YES;
        }
    }];
}

- (void)playBackgroundMusic:(NSString *)filename {
    NSError *error;
    NSURL  *backgroundMusicURL = [[NSBundle mainBundle] URLForResource:filename withExtension:nil];
    _backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&error];
    _backgroundMusicPlayer.numberOfLoops = -1;
    [_backgroundMusicPlayer prepareToPlay];
    [_backgroundMusicPlayer play];
}

#pragma mark Zombie Animation

- (void)startZombieAnimation {
    if (![_zombie actionForKey:@"animation"]) {
        [_zombie runAction:[SKAction repeatActionForever:_zombieAnimation] withKey:@"animation"];
    }
}

- (void)stopZombieAnimation {
    [_zombie removeActionForKey:@"animation"];
}

#pragma mark Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self moveZombieToward:touchLocation];
}

@end
