class Enemy extends PhysicsObject {
    private PImage[] idleFrames;
    private PImage[] hitFrames;
    private PImage[] attackFrames;
    private PImage[] deathFrames;
    private PImage[] runFrames;
    private float currentFrame = 0.0f;
    boolean hFlip = false;
    private int health = 100; 
    boolean isDead = false;
    boolean isHit = false;
    boolean isAttacking = false;
    boolean isRunning = false;
    Character player; 
    public SteeringController steeringController;
    
    // FSM 
    public EnemyFSM fsm;
    
    // Add enemy type to customize behavior
    public int enemyType; // 1, 2, 3, 4 for assassin, 5 for spearman
    
    // Debugging display
    private boolean showState = false; // Set to true to show the current state above the enemy
    
    // Attack collision detection
    private final static int ATTACK_COLLISION_START_FRAME = 4; 
    private final static int ATTACK_COLLISION_END_FRAME = 12;

    public Enemy(PVector start, Character player, int enemyType) {
        super(start, 1.0f); 
        this.player = player;
        this.enemyType = enemyType;
        
        // Initialize with default health
        this.health = 100;
        
        // Load different graphics based on enemy type
        // Type 5 will be our spearman
        if (enemyType == 5) {
            loadIdleFramesSpearman("PixelArt_Samurai/Enemies/Spearman/PNG/Outlined/Spearman_Idle_Outlined.png");
            loadHitFramesSpearman("PixelArt_Samurai/Enemies/Spearman/PNG/Outlined/Spearman_Hit_Outlined.png");
            loadAttackFramesSpearman("PixelArt_Samurai/Enemies/Spearman/PNG/Outlined/Spearman_Attack_Outlined.png");
            loadDeathFramesSpearman("PixelArt_Samurai/Enemies/Spearman/PNG/Outlined/Spearman_Death_Outlined.png");
            loadRunFramesSpearman("PixelArt_Samurai/Enemies/Spearman/PNG/Outlined/Spearman_Run_Outlined.png");
        } else {
            // Default to assassin graphics for other types
            loadIdleFrames("PixelArt_Samurai/Enemies/Assassin/PNG/WithoutOutline/Assassin_Idle.png");
            loadHitFrames("PixelArt_Samurai/Enemies/Assassin/PNG/WithoutOutline/Assassin_Hit.png");
            loadAttackFrames("PixelArt_Samurai/Enemies/Assassin/PNG/WithoutOutline/Assassin_Attack.png");
            loadDeathFrames("PixelArt_Samurai/Enemies/Assassin/PNG/WithoutOutline/Assassin_Death.png");
            loadRunFrames("PixelArt_Samurai/Enemies/Assassin/PNG/WithoutOutline/Assassin_Run.png");
        }
        
        // Initialize the steering controller
        steeringController = new SteeringController(this);
        
        // Initialize the FSM
        fsm = new EnemyFSM(this);
    }

    // Add this method to set health based on difficulty scaling
    public void setHealth(int newHealth) {
        this.health = newHealth;
    }

    // Make sure getHealth() returns the actual health value
    public int getHealth() {
        return this.health;
    }

    // Frame loading methods 
    void loadIdleFrames(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 8; // Number of frames in the sprite sheet
        int frameWidth = spriteSheet.width / frameCount; // Width of each frame
        idleFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            idleFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }

    void loadHitFrames(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 9; 
        int frameWidth = spriteSheet.width / frameCount; 
        hitFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            hitFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }

    void loadDeathFrames(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 19; 
        int frameWidth = spriteSheet.width / frameCount; 
        deathFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            deathFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }

    void loadAttackFrames(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 19; 
        int frameWidth = spriteSheet.width / frameCount; 
        attackFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            attackFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }
    
    void loadRunFrames(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 8; 
        int frameWidth = spriteSheet.width / frameCount;
        runFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            runFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }

    void loadIdleFramesSpearman(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 8; // Spearman has 8 idle frames
        int frameWidth = spriteSheet.width / frameCount; // Width of each frame
        idleFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            idleFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }

    void loadHitFramesSpearman(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 10; // Spearman has 10 hit frames
        int frameWidth = spriteSheet.width / frameCount; 
        hitFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            hitFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }

    void loadDeathFramesSpearman(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 25; // Spearman has 25 death frames
        int frameWidth = spriteSheet.width / frameCount; 
        deathFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            deathFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }

    void loadAttackFramesSpearman(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 19; // Spearman has 19 attack frames
        int frameWidth = spriteSheet.width / frameCount; 
        attackFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            attackFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }

    void loadRunFramesSpearman(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 8; // Spearman has 8 run frames
        int frameWidth = spriteSheet.width / frameCount;
        runFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            runFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }

    void takeDamage(int damage) {
        // Apply damage but ensure health doesn't go below 0
        health = max(0, health - damage);
        
        isHit = true;
        currentFrame = 0;
        
        if (health <= 0) {
            isDead = true;
            currentFrame = 0;
        }
    }

    void update() {
        // Update FSM instead of behavior directly
        fsm.update();
        
        // Update animation based on state
        updateAnimation();
        
        // Update facing direction based on movement
        if (velocity.x < -0.1) {
            hFlip = true;
        } else if (velocity.x > 0.1) {
            hFlip = false;
        }
        
        // If we're moving, update running state
        isRunning = Math.abs(velocity.x) > 0.1;
        
        // Handle physics
        super.update();
    }
    
    // Animation update separated from behavior
    void updateAnimation() {
        // Determine animation speed based on state
        float animSpeed = 0.1f;
        
        if (isDead) {
            // Death animation
            animSpeed = 0.2f;
            
            if (enemyType == 5) {
                // Spearman death animation - special handling
                currentFrame += animSpeed;
                
                if (currentFrame < deathFrames.length - 9) {
                    // Play first part of death animation normally
                    // This gets us to frame 16
                } else {
                    // Once we reach the last 9 frames, loop these frames
                    if (currentFrame >= deathFrames.length) {
                        // Reset to start of looping range (frame 16)
                        currentFrame = deathFrames.length - 9;
                    }
                }
                return;
            } else {
                // Regular enemies (assassins) - freeze on last frame
                currentFrame += animSpeed;
                if (currentFrame >= deathFrames.length) {
                    currentFrame = deathFrames.length - 1; // Freeze on last frame
                }
                return;
            }
        }
        
        if (isHit) {
            // Hit animation
            animSpeed = 0.2f;
            currentFrame += animSpeed;
            if (currentFrame >= hitFrames.length) {
                currentFrame = 0;
                isHit = false;
            }
            return;
        }
        
        if (isAttacking) {
            // Attack animation
            animSpeed = 0.2f;
            currentFrame += animSpeed;
            if (currentFrame >= attackFrames.length) {
                currentFrame = 0;
                isAttacking = false; // Let FSM handle the next state
            }
            return;
        }
        
        // Running or idle animation
        if (isRunning) {
            currentFrame += 0.1f;
            if (currentFrame >= runFrames.length) {
                currentFrame = 0;
            }
        } else {
            // Idle animation
            currentFrame += 0.1f;
            if (currentFrame >= idleFrames.length) {
                currentFrame = 0;
            }
        }
    }

    void draw() {
        PImage frame;
        if (isDead) {
            // Make sure we don't go out of bounds with the animation frame
            int frameIndex = min((int)currentFrame, deathFrames.length-1);
            frame = deathFrames[frameIndex];
        } else if (isHit) {
            frame = hitFrames[min((int)currentFrame, hitFrames.length-1)];
        } else if (isAttacking) {
            frame = attackFrames[min((int)currentFrame, attackFrames.length-1)];
        } else if (isRunning) {
            frame = runFrames[min((int)currentFrame, runFrames.length-1)];
        } else {
            frame = idleFrames[min((int)currentFrame, idleFrames.length-1)];
        }

        if (hFlip) {
            pushMatrix();
            scale(-1.0, 1.0);
            image(frame, -this.position.x, this.position.y);
            popMatrix();
        } else {
            image(frame, this.position.x, this.position.y);
        }
        
        // Draw state above enemy (for debugging)
        if (showState) {
            pushStyle();
            fill(255);
            textAlign(CENTER);
            textSize(12);
            text(fsm.getCurrentState().toString(), position.x, position.y - 40);
            popStyle();
        }
    }

    public boolean isInAttackRange(Character player) {
        if (player.position.x >= position.x - 30 && player.position.x <= position.x + 30) {
            return true;
        } else {
            return false;
        }
    }

    public boolean isInAttackCollisionFrame() {
        if (enemyType == 5) {
            // Spearman has different attack collision frames due to spear reach
            return (currentFrame >= 6 && currentFrame <= 14);
        } else {
            // Original collision frames for assassin
            return (currentFrame >= ATTACK_COLLISION_START_FRAME && currentFrame <= ATTACK_COLLISION_END_FRAME);
        }
    }

    public boolean isAttacking() {
        return isAttacking;
    }

    public int getEnemyType() {
        return enemyType;
    }
}