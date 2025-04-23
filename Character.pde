class Character extends PhysicsObject {
    // animation variables
    private final static float ANIMATION_SPEED = 0.1f;
    private final static float ATTACK_ANIMATION_SPEED = 0.3f; 
    private final static float MOVEMENT_SPEED = 1.3f;
    private final static float JUMP_FORCE = 8.0f; 
    private final static float GLIDE_GRAVITY = 0.5f; 
    private final static float JUMP_HEIGHT = 60.0f;
    private final static int JUMP_PAUSE_DURATION = 1; // Number of frames to pause at the peak of the jump
    private final static float ATTACK_RANGE = 70.0f;
    private final static int ATTACK_COLLISION_START_FRAME = 4; 
    private final static int ATTACK_COLLISION_END_FRAME = 8; 
    private final static float SPRING_GRAVITY_REDUCTION = 0.9f; // Reduced gravity when bouncing on spring
    private int springForceFrames = 0;
    private final static int MAX_SPRING_FORCE_FRAMES = 60; // Number of frames to apply spring force

    private PImage[] idleFrames;
    private PImage[] runFrames;
    private PImage[] jumpFrames;
    private PImage[] fallFrames;
    private PImage[][] attackFrames;
    private PImage[] shootFrames;
    private int[] attackFrameCounts = {12, 13, 9}; // Number of frames in each attack animation
    private float currentFrame = 0.0f;
    private boolean hFlip = false;
    private boolean springBounce = false;

    private boolean movingLeft, movingRight, jumpingUp, fallingDown, attacking, attackingFlag, gliding;
    private float jumpStartY;
    private int jumpPauseCounter = 0;
    private int currentAttackIndex = 0;
    private int health = 100; // Initial health
    public boolean isDead = false;

    private boolean shooting = false;
    private ArrayList<Bullet> bullets = new ArrayList<Bullet>();
    private long lastShotTime = 0;
    private final static int SHOT_COOLDOWN = 500;
    
    // Force generators
    private ConstantForce movementForce;
    private ConstantForce jumpForce;


    public Character(PVector start) {
        super(start, 1.0f); 
        
        // force generators
        movementForce = new ConstantForce(new PVector(0, 0));
        jumpForce = new ConstantForce(new PVector(0, 0));
        
        this.idleFrames = new PImage[16];
        for (int i = 0; i < 16; i++) {
            String framePath = "CharacterPack/Player/Idle/player_idle_" + nf(i + 1, 2) + ".png";
            this.idleFrames[i] = loadImage(framePath);
        }
        this.runFrames = new PImage[10];
        for (int i = 0; i < 10; i++) {
            String framePath = "CharacterPack/Player/Run/player_run_" + nf(i + 1, 2) + ".png";
            this.runFrames[i] = loadImage(framePath);
        }
        this.jumpFrames = new PImage[6];
        for (int i = 0; i < 6; i++) {
            String framePath = "CharacterPack/Player/JumpUp/player_jumpup_" + nf(i + 1, 2) + ".png";
            this.jumpFrames[i] = loadImage(framePath);
        }
        this.fallFrames = new PImage[6];
        for (int i = 0; i < 6; i++) {
            String framePath = "CharacterPack/Player/JumpDown/player_jumpdown_" + nf(i + 1, 2) + ".png";
            this.fallFrames[i] = loadImage(framePath);
        }
        this.attackFrames = new PImage[3][];
        for (int j = 0; j < 3; j++) {
            this.attackFrames[j] = new PImage[attackFrameCounts[j]];
            for (int i = 0; i < attackFrameCounts[j]; i++) {
                String framePath = "CharacterPack/Player/Attack/Attack0" + (j + 1) + "/player_attack0" + (j + 1) + "_" + nf(i + 1, 2) + ".png";
                this.attackFrames[j][i] = loadImage(framePath);
            }
        }
        this.shootFrames = new PImage[12];
        for (int i = 0; i < 12; i++) {
            String framePath = "CharacterPack/Player/Shoot/player_shoot_" + nf(i + 1, 2) + ".png";
            this.shootFrames[i] = loadImage(framePath);
        }
    }

    public void update() {
        // Update movement forces based on player input
        updateMovementForces();
        
        // Update animation
        updateAnimation();
        
        // Handle jump logic
        updateJumpState();
        
        // Update bullets
        updateBullets();
        
        // Call parent update -> handle physics and integration
        super.update();
    }
    
    private void updateMovementForces() {
        // Reset movement force
        PVector moveForce = new PVector(0, 0);
        
        // Apply movement forces based on input
        if (movingLeft) {
            moveForce.x = -MOVEMENT_SPEED;
            this.hFlip = true;
        }
        if (movingRight) {
            moveForce.x = MOVEMENT_SPEED;
            this.hFlip = false;
        }
        
        // Apply the calculated movement force
        applyForce(moveForce);
    }
    
    private void updateAnimation() {
        if (shooting) {
            currentFrame += ATTACK_ANIMATION_SPEED;
            if (currentFrame >= shootFrames.length) {
                shooting = false;
                currentFrame = 0;
            } else {
                currentFrame %= shootFrames.length;
            }
        } else if (attacking) {
            currentFrame += ATTACK_ANIMATION_SPEED;
            if (currentFrame >= attackFrames[currentAttackIndex].length) {
                attacking = false;
                currentFrame = 0;
            } else {
                currentFrame %= attackFrames[currentAttackIndex].length;
            }
        } else {
            currentFrame += ANIMATION_SPEED;
            if (jumpingUp) {
                currentFrame %= jumpFrames.length;
            } else if (fallingDown) {
                currentFrame %= fallFrames.length;
            } else if (movingLeft || movingRight) {
                currentFrame %= runFrames.length;
            } else {
                currentFrame %= idleFrames.length;
            }
        }
    }
    
    private void updateJumpState() {
        if (jumpPauseCounter > 0) {
            jumpPauseCounter--;
            if (jumpPauseCounter == 0) {
                fallingDown = true;
            }
        }
        
        if (jumpingUp) {
            if (springBounce) {
                // Only apply upward force for a limited number of frames
                if (springForceFrames < MAX_SPRING_FORCE_FRAMES) {
                    // Apply an upward force that counteracts most of gravity during spring bounce
                    applyForce(new PVector(0, -2.8f * SPRING_GRAVITY_REDUCTION));
                    springForceFrames++;
                }
                
                // Check if we're starting to fall
                if (velocity.y >= 0) {
                    jumpingUp = false;
                    fallingDown = true;
                    springBounce = false; // Reset spring bounce state
                    springForceFrames = 0; // Reset frame counter
                }
                
                // go much higher during spring bounce
                if (position.y < 5) {  
                    position.y = 5;
                    velocity.y *= 0.3;  //slowdown if hitting ceiling
                }
            } else {
                // Normal jump
                float jumpProgress = (jumpStartY - position.y) / JUMP_HEIGHT;
                float currentJumpForce = JUMP_FORCE * (1.0f - jumpProgress * 0.3f);
                
                if (position.y > jumpStartY - JUMP_HEIGHT) {
                    applyForce(new PVector(0, -currentJumpForce));
                } else {
                    jumpingUp = false;
                    jumpPauseCounter = JUMP_PAUSE_DURATION;
                }
            }
        }
        
        // Check for gliding 
        if (fallingDown && gliding) {
            applyForce(new PVector(0, -GLIDE_GRAVITY));
        }
        
        // if not on ground and not jumping, then we should be falling
        if (!jumpingUp && !isOnGround()) {
            fallingDown = true;
        }
        
        // If we're falling but velocity is upward (from a spring bounce) -> correct it
        if (fallingDown && velocity.y < 0) {
            jumpingUp = true;
            fallingDown = false;
        }
    }

    private boolean isOnGround() {
        // check if the character is on the main ground
        boolean onMainGround = position.y >= height - 30 - radius;
        return onMainGround;
    }
    
    private void updateBullets() {
        // Update bullets
        for (int i = bullets.size() - 1; i >= 0; i--) {
            Bullet bullet = bullets.get(i);
            bullet.update();
            
            // Remove bullets that are off-screen or hit enemies
            if (bullet.isOffScreen()) {
                bullets.remove(i);
            }
        }
    }

    public void draw() {
        PImage[] frames;
        int frameIndex = 0;
        
        // Determine which animation frames to use
        if (shooting) {
            frames = shootFrames;
            frameIndex = min((int)currentFrame, shootFrames.length - 1);
        } else if (attacking) {
            frames = attackFrames[currentAttackIndex];
            frameIndex = min((int)currentFrame, attackFrames[currentAttackIndex].length - 1);
        } else if (jumpingUp) {
            frames = jumpFrames;
            frameIndex = min((int)currentFrame, jumpFrames.length - 1);
        } else if (fallingDown) {
            frames = fallFrames;
            frameIndex = min((int)currentFrame, fallFrames.length - 1);
        } else if (movingLeft || movingRight) {
            frames = runFrames;
            frameIndex = min((int)currentFrame, runFrames.length - 1);
        } else {
            frames = idleFrames;
            frameIndex = min((int)currentFrame, idleFrames.length - 1);
        }

        // access the frame
        PImage frame = frames[frameIndex];
        
        // Draw the character
        if (this.hFlip) {
            pushMatrix();
            scale(-1.0, 1.0);
            image(frame, -this.position.x, this.position.y);
            popMatrix();
        } else {
            image(frame, this.position.x, this.position.y);
        }

        // Draw bullets
        for (Bullet bullet : bullets) {
            bullet.draw();
        }
    }

    // getters of position 
    public float getX() {
        return this.position.x;
    }

    public float getY() {
        return this.position.y;
    }

    public boolean isAttacking() {
        return attacking;
    }

    public boolean isInAttackRange(PhysicsObject other) {
        float distance = PVector.dist(this.position, other.position);
        return distance < ATTACK_RANGE;
    }

    public boolean isAttackCollisionFrame() {
        return currentFrame >= ATTACK_COLLISION_START_FRAME && currentFrame <= ATTACK_COLLISION_END_FRAME;
    }

    public void takeDamage(int damage) {
        health -= damage;
        // make the player red for a short time
        fill(255, 0, 0, 100);
        rect(0, 0, width, height);
        // go back to normal color
        fill(255);  
        if (health <= 0) {
            isDead = true;
        }
    }

    void handleKeyPressed(char key) {
        if (key == 'a' || key == 'A') {
            movingLeft = true;
        } else if (key == 'd' || key == 'D') {
            movingRight = true;
        } else if (key == 'w' || key == 'W') {
            if (!jumpingUp && !fallingDown) {
                jumpingUp = true;
                fallingDown = false;
                jumpStartY = this.position.y;
            }
        } else if (key == 's' || key == 'S') {
            // jump down immediately if currently jumping up (not used for now)
            if (jumpingUp) {
                jumpingUp = false;
                jumpPauseCounter = 0;
                fallingDown = true;
            }
        } else if (key == ' ' && !attackingFlag) {
            attacking = true;
            attackingFlag = true;
            currentFrame = 0;
            currentAttackIndex = (currentAttackIndex + 1) % attackFrames.length;
        } else if (key == CODED && keyCode == SHIFT) {
            gliding = true;
        }
    }

    void handleKeyReleased(char key) {
        if (key == 'a' || key == 'A') {
            movingLeft = false;
        } else if (key == 'd' || key == 'D') {
            movingRight = false;
        } else if (key == ' ') {
            attackingFlag = false;
        } else if (key == CODED && keyCode == SHIFT) {
            gliding = false;
        }
    }

    // get health
    public int getHealth() {
        return health;
    }

    public void shoot() {
        long currentTime = millis();
        if (currentTime - lastShotTime > SHOT_COOLDOWN && !shooting && !attacking) {
            shooting = true;
            currentFrame = 0;
            
            // Create a new bullet
            PVector bulletPos = new PVector(position.x, position.y);
            PVector bulletVel = new PVector(hFlip ? -10 : 10, 0); // Bullet speed and direction
            bullets.add(new Bullet(bulletPos, bulletVel));
            
            lastShotTime = currentTime;
        }
    }

    public ArrayList<Bullet> getBullets() {
        return bullets;
    }
    
    public boolean isFacingLeft() {
        return this.hFlip;
    }

    public void setSpringBounce(boolean springBounce) {
        this.springBounce = springBounce;
        if (springBounce) {
            this.springForceFrames = 0; // Reset the frame counter when activating spring bounce
        }
    }
    
}