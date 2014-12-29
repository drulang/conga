//
//  GameScene.m
//  ZombieConga
//
//  Created by Dru Lang on 12/23/14.
//  Copyright (c) 2014 drulang. All rights reserved.
//

#import "GameScene.h"

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

@implementation GameScene {
    SKSpriteNode *_zombie;
    CGPoint _velocity;
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
}

- (instancetype)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [UIColor whiteColor];
        
        // Build background
        SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
        bg.position = CGPointMake(self.size.width / 2, self.size.height / 2);
        bg.anchorPoint = CGPointMake(.5, .5);
        
        //Add zombie
        _zombie = [SKSpriteNode spriteNodeWithImageNamed:@"zombie1"];
        _zombie.position = CGPointMake(100, 100);
        
        [self addChild:bg];
        [self addChild:_zombie];
        [self spawnEnemy];
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
}

- (void)spawnEnemy {
    SKSpriteNode *enemy = [SKSpriteNode spriteNodeWithImageNamed:@"enemy"];
    enemy.position = CGPointMake(self.size.width + (enemy.size.width/2), self.size.height / 2);
    [self addChild:enemy];
    
    SKAction *actionMidMove = [SKAction moveByX:-self.size.width / 2 - enemy.size.width /2 y:-self.size.height/2 + enemy.size.height / 2 duration:1];
    SKAction *actionMove = [SKAction moveByX:-self.size.width /2 - enemy.size.width / 2 y:self.size.height/2 +enemy.size.height/2 duration:1];
    SKAction *wait = [SKAction waitForDuration:.25];
    SKAction *logMessage = [SKAction runBlock:^{
        NSLog(@"Reached bottom");
    }];

    SKAction *sequence = [SKAction sequence:@[actionMidMove,logMessage, wait, actionMove]];
    sequence = [SKAction sequence:@[sequence, [sequence reversedAction]]];
    
    SKAction *repeat = [SKAction repeatActionForever:sequence];
    [enemy runAction:repeat];
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

- (void)rotateSprite:(SKSpriteNode *)sprite toFace:(CGPoint)direction{
    sprite.zRotation = CGPointToAngle(direction);
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
