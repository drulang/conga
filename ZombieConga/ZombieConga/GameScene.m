//
//  GameScene.m
//  ZombieConga
//
//  Created by Dru Lang on 12/23/14.
//  Copyright (c) 2014 drulang. All rights reserved.
//

#import "GameScene.h"

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

@implementation GameScene {
    SKSpriteNode *_zombie;
    CGPoint _velocity;
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    SKAction *_zombieAnimation;
    SKAction *_catCollisionSound;
    SKAction *_enemeyCollisionSound;
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
    NSLog(@"%0.2f milliseconds since last update", _dt * 1000);
    
    [self boundsCheckPlayer];
    [self rotateSprite:_zombie toFace:_velocity];
    NSLog(@"Velocity: %@", NSStringFromCGPoint(_velocity));
    [self moveSprite:_zombie velocity:_velocity];
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
    
    NSLog(@"Amount to move: %@", NSStringFromCGPoint(amountToMove));
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
            [cat removeFromParent];
            [self runAction:_catCollisionSound];
        }
    }];
    
    //Check Enemy
    [self enumerateChildNodesWithName:@"enemy" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *enemy = (SKSpriteNode *)node;
        CGRect smallerFrame = CGRectInset(enemy.frame, 20, 20);
        if (CGRectIntersectsRect(smallerFrame, _zombie.frame)) {
            [enemy removeFromParent];
            [self runAction:_enemeyCollisionSound];
        }
    }];
}

- (void)rotateSprite:(SKSpriteNode *)sprite toFace:(CGPoint)direction{
    sprite.zRotation = CGPointToAngle(direction);
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
