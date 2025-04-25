import processing.core.PImage;
import processing.core.PVector;

class BossDemon extends PhysicsObject {

    // --- Animation Frames ---
    private PImage[] idleFrames;
    private PImage[] walkFrames;
    private PImage[] cleaveFrames; // Boss attack
    private PImage[] hitFrames;
    private PImage[] deathFrames;

    private float currentFrame = 0.0f;
    private boolean hFlip = false; // Horizontal flip state

    // --- State Variables (Flags managed partly by FSM now) ---
    private int health = 500; // Bosses have more health
    boolean isDead = false;
    boolean isHit = false;     // Is currently playing the hit animation
    boolean isAttacking = false; // Is currently playing the cleave animation
    boolean isWalking = false;   // Flag for walking animation

    // --- References & Components ---
    Character player;
    public SteeringController steeringController; // Can reuse steering behaviors
    private BossFSM fsm; // <<< ADD FSM field >>>

    // --- Configuration ---
    private float animationSpeed = 0.15f; // Base animation speed
    private float attackAnimationSpeed = 0.2f;
    private float hitAnimationSpeed = 0.25f;
    private float deathAnimationSpeed = 0.18f;
    private float walkAnimationSpeed = 0.2f;

    // Attack collision frames (adjust based on visual inspection of 'cleave' animation)
    private final static int ATTACK_COLLISION_START_FRAME = 10; // Example, adjust!
    private final static int ATTACK_COLLISION_END_FRAME = 13;  // Example, adjust!

    // --- Constructor ---
    public BossDemon(PVector start, Character player) {
        // Bosses are heavier and larger
        super(start, 3.0f); // Call PhysicsObject constructor (position, mass)
        this.radius = 60.0f; // Adjust radius based on sprite size
        this.player = player;
        this.health = 500;   // Set initial boss health

        // --- Load Graphics ---
        loadIdleFramesDemon("boss_demon/01_demon_idle/");
        loadWalkFramesDemon("boss_demon/02_demon_walk/");
        loadCleaveFramesDemon("boss_demon/03_demon_cleave/");
        loadHitFramesDemon("boss_demon/04_demon_take_hit/");
        loadDeathFramesDemon("boss_demon/05_demon_death/");

        // --- Initialize Components ---
        steeringController = new SteeringController(this);
        fsm = new BossFSM(this); // <<< INITIALIZE FSM HERE >>>

        println("Boss Demon created at " + start);
    }

    void loadFramesFromFolder(String folderPath, int frameCount, String baseName, PImage[] targetArray) {
        println("Loading " + frameCount + " frames from: " + folderPath);
        if (targetArray == null || targetArray.length != frameCount) {
            println("Error: Target array not initialized correctly for " + folderPath);
            targetArray = new PImage[frameCount]; // Attempt recovery
        }

        for (int i = 0; i < frameCount; i++) {
            String filename = folderPath + baseName + "_" + (i + 1) + ".png"; 
            try {
                targetArray[i] = loadImage(filename);
                if (targetArray[i] == null) {
                    println("Error loading frame: " + filename + " - loadImage returned null.");
                }
            } catch (Exception e) {
                println("Exception loading frame: " + filename);
                e.printStackTrace();
            }
        }
    }


    void loadIdleFramesDemon(String folderPath) {
        int frameCount = 6;
        idleFrames = new PImage[frameCount];
        loadFramesFromFolder(folderPath, frameCount, "demon_idle", idleFrames);
    }

    void loadWalkFramesDemon(String folderPath) {
        int frameCount = 12;
        walkFrames = new PImage[frameCount];
        loadFramesFromFolder(folderPath, frameCount, "demon_walk", walkFrames);
    }

    void loadCleaveFramesDemon(String folderPath) {
        int frameCount = 15;
        cleaveFrames = new PImage[frameCount];
        loadFramesFromFolder(folderPath, frameCount, "demon_cleave", cleaveFrames);
    }

    void loadHitFramesDemon(String folderPath) {
        int frameCount = 5;
        hitFrames = new PImage[frameCount];
        loadFramesFromFolder(folderPath, frameCount, "demon_take_hit", hitFrames);
    }

    void loadDeathFramesDemon(String folderPath) {
        int frameCount = 22;
        deathFrames = new PImage[frameCount];
        loadFramesFromFolder(folderPath, frameCount, "demon_death", deathFrames);
    }


    // --- Core Logic ---
    public int getHealth() {
        return health;
    }

    public void takeDamage(int damage) {
        if (isDead) return; // Can't damage a dead boss

        health = max(0, health - damage);
        println("Boss took " + damage + " damage. Health: " + health);

        isAttacking = false; // Interrupt attack if hit

        if (health <= 0) {
            isDead = true;
            isHit = false; // Death overrides hit
            currentFrame = 0; // Reset animation frame for death
            fsm.forceState(BossState.DEAD); // <<< Force DEAD state in FSM >>>
        } else {
             // Only trigger hit state if not dead
             isHit = true;
             currentFrame = 0; // Reset animation frame for hit
             fsm.forceState(BossState.HIT); // <<< Force HIT state in FSM >>>
        }
    }

    // Update method now primarily delegates to the FSM
    void update() {
        // --- Let FSM Handle Behavior ---
        fsm.update(); // <<< CALL FSM UPDATE >>>

        // Update facing direction based on player position, but only if not attacking/hit
        // (FSM state check ensures this)
        if (fsm.getCurrentState() != BossState.ATTACK && fsm.getCurrentState() != BossState.HIT && fsm.getCurrentState() != BossState.DEAD) {
           if (player.position.x < this.position.x - 10) { // Look towards player
              hFlip = false;
           } else if (player.position.x > this.position.x + 10) {
              hFlip = true;
           }
        }

        // Update animation based on flags set by FSM and this class
        updateAnimation();

        // Apply physics (forces applied by steering behaviors via FSM)
        super.update();
    }


    void updateAnimation() {
        // This logic remains mostly the same, playing animations based on flags
        // The FSM is responsible for *setting* the isHit, isAttacking, isWalking flags
        // appropriately when entering/exiting states.

        float animSpeed = animationSpeed; // Base speed
        PImage[] currentFrames = idleFrames; // Default

        // Check states in order of priority
        if (isDead) { // Check isDead flag (set in takeDamage)
            animSpeed = deathAnimationSpeed;
            currentFrames = deathFrames;
            currentFrame += animSpeed;
            // Freeze on last frame of death animation
            if (currentFrames != null && currentFrames.length > 0 && currentFrame >= currentFrames.length) {
                currentFrame = currentFrames.length - 1;
            }
            return; // Don't process other states if dead
        }

        if (isHit) { // Check isHit flag (set by takeDamage, unset by FSM exit/checkTransitions or here)
            animSpeed = hitAnimationSpeed;
            currentFrames = hitFrames;
            currentFrame += animSpeed;
            // Check if animation finished
            if (currentFrames != null && currentFrames.length > 0 && currentFrame >= currentFrames.length) {
                isHit = false; // Animation finished. FSM's HIT state checkTransitions will see this.
                currentFrame = 0;
            }
            return; // Don't process other states if hit
        }

        if (isAttacking) { // Check isAttacking flag (set by FSM AttackState enter, unset here/FSM exit)
            animSpeed = attackAnimationSpeed;
            currentFrames = cleaveFrames;
            currentFrame += animSpeed;
             // Check if animation finished
            if (currentFrames != null && currentFrames.length > 0 && currentFrame >= currentFrames.length) {
                isAttacking = false; // Animation finished. FSM's ATTACK state checkTransitions will see this.
                currentFrame = 0;
            }
             return; // Don't process other states if attacking
        }

        // If not dead, hit, or attacking, check walking (set by FSM ChaseState)
        if (isWalking) { // Check isWalking flag (set/unset by FSM Chase/Idle states)
            animSpeed = walkAnimationSpeed;
            currentFrames = walkFrames;
        } else {
            // Otherwise, default to Idle
            animSpeed = animationSpeed; // Use base idle speed
            currentFrames = idleFrames;
        }

        // Update frame for idle/walk
        currentFrame += animSpeed;
        // Loop animation
        if (currentFrames != null && currentFrames.length > 0 && currentFrame >= currentFrames.length) {
            currentFrame = 0;
        }
    }


    void draw() {
        PImage[] currentFrames = idleFrames; // Default to prevent null pointer if logic fails early

        // Determine which animation set to use based on flags
        if (isDead) {
            currentFrames = deathFrames;
        } else if (isHit) {
            currentFrames = hitFrames;
        } else if (isAttacking) {
            currentFrames = cleaveFrames;
        } else if (isWalking) {
            currentFrames = walkFrames;
        } else {
            currentFrames = idleFrames; // Default case
        }

        // Ensure frame index is valid AND frames array is loaded
        int frameIndex = (int)currentFrame;
        PImage frame = null; // Start as null

        if (currentFrames != null && currentFrames.length > 0) {
             // Clamp index to valid range
             frameIndex = constrain(frameIndex, 0, currentFrames.length - 1);
             frame = currentFrames[frameIndex]; // Get the actual frame
        } else {
             println("Warning: Animation frames array is null or empty for current BossDemon state!");
        }


        if (frame == null) {
             // Draw a placeholder if frame is missing or array wasn't loaded
             println("Warning: Current frame is null for BossDemon! Index: " + frameIndex + " State: [Dead:" + isDead + ", Hit:" + isHit + ", Atk:" + isAttacking + ", Walk:" + isWalking + "]");
             pushStyle();
             fill(255, 0, 255, 200); // Bright pink placeholder
             noStroke();
             ellipse(this.position.x, this.position.y, this.radius, this.radius); // Use radius
             popStyle();
             return; // Don't try to draw null image
        }


        // Draw the frame with potential horizontal flip
        pushMatrix();
        translate(this.position.x, this.position.y);
        if (hFlip) {
            scale(-1.0, 1.0);
        }
        // imageMode is CENTER by default in the main sketch
        // Adjust drawing scale if needed
        float visualScale = 1.0f; // Make boss appear larger (no)
        image(frame, 0, 0, frame.width * visualScale, frame.height * visualScale);
        popMatrix();

        // Optional: Draw health bar above boss
        drawHealthBar();
    }

    void drawHealthBar() {
        if(isDead) return; // Don't draw if dead

        float barWidth = 100; // Width of the health bar
        float barHeight = 10; // Height of the health bar
        // Position above the boss, considering scaled visual size if necessary
        float barX = position.x - barWidth / 2;
        float barY = position.y - (radius * 1.5f) - 20; // Position above scaled sprite visual top

        pushStyle();
        rectMode(CORNER); // Use CORNER for drawing bars easily
        // Background of health bar
        fill(50); // Dark grey
        noStroke();
        rect(barX, barY, barWidth, barHeight, 2); // Added slight rounding

        // Foreground (current health)
        // Assuming max health is 500
        float currentHealthWidth = map(health, 0, 500, 0, barWidth);
        // Ensure width doesn't go negative
        currentHealthWidth = max(0, currentHealthWidth);

        fill(200, 0, 0); // Red
        rect(barX, barY, currentHealthWidth, barHeight, 2);

        // Optional: Border
        stroke(200); // Light grey border
        strokeWeight(1);
        noFill();
        rect(barX, barY, barWidth, barHeight, 2);
        rectMode(CENTER); // Reset to default if needed elsewhere
        popStyle();
    }


    // --- Attack Helpers ---

    // startAttack() is now primarily called BY the FSM when entering AttackState
    public void startAttack() {
        // FSM should ensure conditions are met, but safety checks here are good
        if (fsm.getCurrentState() == BossState.ATTACK && !isHit && !isDead) {
            // Check if already attacking to prevent resetting frame mid-swing
            if (!isAttacking) {
                 println("BossDemon: startAttack() called by FSM.");
                 isAttacking = true;
                 isWalking = false; // Stop walking animation flag
                 currentFrame = 0; // Start attack animation from beginning
                 // Physical movement should stop because FSM cleared steering behaviors
            }
        } else {
             println("Warning: startAttack called from invalid state: " + fsm.getCurrentState());
        }
    }

    // Returns true if the boss is currently in the attack animation sequence
    public boolean isAttacking() {
        return isAttacking; // Directly return the flag managed by FSM/updateAnimation
    }

    // Check if the player is within the boss's melee range
    // (Used by FSM to decide when to transition to ATTACK)
    public boolean isInAttackRange(Character targetPlayer) {
        if (isDead || targetPlayer == null) return false;

        float attackReach = 100.0f; // How far the boss can hit horizontally
        float verticalTolerance = 60.0f; // How much vertical difference is allowed for the attack

        float dx = targetPlayer.position.x - this.position.x;
        float dy = targetPlayer.position.y - this.position.y;

        // Check horizontal distance based on facing direction (hFlip)
        boolean horizontallyClose;
        if (hFlip) { // Facing left
            horizontallyClose = (dx < 0 && dx > -attackReach); // Player is to the left, within reach
        } else { // Facing right
            horizontallyClose = (dx > 0 && dx < attackReach); // Player is to the right, within reach
        }

        // Check vertical distance
        boolean verticallyClose = abs(dy) < verticalTolerance;

        return horizontallyClose && verticallyClose;
    }

    // Check if the current frame of the attack animation should deal damage
    // (Used by main sketch's handleEnemyAttacks)
    public boolean isInAttackCollisionFrame() {
        // Ensure we are actually in the attacking animation state AND the frame is correct
        if (!isAttacking) {
            return false;
        }
        // Check if the currentFrame falls within the defined collision range
        return (currentFrame >= ATTACK_COLLISION_START_FRAME && currentFrame <= ATTACK_COLLISION_END_FRAME);
    }

} 