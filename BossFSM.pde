import java.util.HashMap;

// Define the possible states for the Boss
enum BossState {
  IDLE,   // (Optional, might transition out quickly)
  CHASE,
  ATTACK,
  HIT,
  DEAD
}

// --- FSM Core Class ---
class BossFSM {
  private BossDemon owner; // Operates on a BossDemon
  private BossState currentState;
  private HashMap<BossState, BossStateHandler> stateHandlers;

  BossFSM(BossDemon owner) {
    this.owner = owner;
    this.currentState = BossState.IDLE; // Start Idle

    // Initialize state handlers for the boss states
    stateHandlers = new HashMap<BossState, BossStateHandler>();
    stateHandlers.put(BossState.IDLE, new BossIdleState(this));
    stateHandlers.put(BossState.CHASE, new BossChaseState(this));
    stateHandlers.put(BossState.ATTACK, new BossAttackState(this));
    stateHandlers.put(BossState.HIT, new BossHitState(this));
    stateHandlers.put(BossState.DEAD, new BossDeadState(this));

    stateHandlers.get(currentState).enter();
    println("Boss FSM Initialized. Starting state: " + currentState);
  }

  void update() {
    // Get the current state handler and update it
    BossStateHandler currentHandler = stateHandlers.get(currentState);
    if (currentHandler != null) {
        currentHandler.update();
        // Check for transitions AFTER update
        checkStateTransitions();
    } else {
        println("Error: No handler found for BossState: " + currentState);
    }
  }

  void checkStateTransitions() {
    BossStateHandler currentHandler = stateHandlers.get(currentState);
    BossState nextState = currentHandler.checkTransitions(); // Ask the current state handler if we should change

    if (nextState != currentState) {
      // --- State Change Occurs ---
      BossStateHandler oldHandler = stateHandlers.get(currentState);
      BossStateHandler newHandler = stateHandlers.get(nextState);

      // Exit the old state
      if (oldHandler != null) oldHandler.exit();

      println("Boss state changing: " + currentState + " -> " + nextState); // Debug
      currentState = nextState; // Change the current state

      // Enter the new state
      if (newHandler != null) newHandler.enter();
    }
  }

  // Force a state change (e.g., when taking damage)
  void forceState(BossState newState) {
     if (newState != currentState) {
         println("Boss state forced: " + currentState + " -> " + newState); // Debug
         stateHandlers.get(currentState).exit();
         currentState = newState;
         stateHandlers.get(currentState).enter();
     }
  }

  BossDemon getOwner() {
    return owner;
  }

  BossState getCurrentState() {
    return currentState;
  }
}

// --- State Handler Interface ---
interface BossStateHandler {
  void enter();  // Called once when entering the state
  void update(); // Called every frame while in this state
  void exit();   // Called once when exiting the state
  BossState checkTransitions(); // Determines the next state based on conditions
}

// --- State Handler Implementations ---

// IDLE State (Boss might not stay here long)
class BossIdleState implements BossStateHandler {
  private BossFSM fsm;
  private float idleTimer = 0;
  private final float MAX_IDLE_TIME = 0.5f; // Boss gets impatient quickly

  BossIdleState(BossFSM fsm) { this.fsm = fsm; }

  public void enter() {
    println("Boss Entering IDLE");
    BossDemon owner = fsm.getOwner();
    owner.steeringController.clearBehaviors(); // Stop moving
    owner.isWalking = false;
    owner.isAttacking = false; // Ensure not stuck in attack
    idleTimer = 0;
  }

  public void update() {
      idleTimer += 1.0f / frameRate; // Basic timer
  }

  public void exit() {
      // Nothing needed
  }

  public BossState checkTransitions() {
    BossDemon owner = fsm.getOwner();
    // Immediate checks
    if (owner.isDead) return BossState.DEAD;
    if (owner.isHit) return BossState.HIT; // Hit interrupts idle

    // If player is close or idle time is up, start chasing
    float detectionRange = 800.0f; // Boss has good vision
    if (PVector.dist(owner.position, owner.player.position) < detectionRange || idleTimer > MAX_IDLE_TIME) {
      return BossState.CHASE;
    }

    return BossState.IDLE; // Stay idle
  }
}

// CHASE State
class BossChaseState implements BossStateHandler {
  private BossFSM fsm;
  private Seek seekBehavior; // Store the behavior for easy target updating

  BossChaseState(BossFSM fsm) { this.fsm = fsm; }

  public void enter() {
    println("Boss Entering CHASE");
    BossDemon owner = fsm.getOwner();
    owner.steeringController.clearBehaviors();
    owner.isWalking = true; // Set walking animation flag

    // Add Seek behavior - Boss might be strong but not necessarily super fast
    float bossChaseSpeed = 0.8f; // Adjust as needed
    seekBehavior = new Seek(owner.player.position, bossChaseSpeed);
    owner.steeringController.addBehavior(seekBehavior, 1.0f); // Full weight to seeking
  }

  public void update() {
    BossDemon owner = fsm.getOwner();
    // Keep updating the target position for the seek behavior
    seekBehavior.targetPosition = owner.player.position;
    // Apply steering force
    owner.steeringController.calculateSteering();
  }

  public void exit() {
    BossDemon owner = fsm.getOwner();
    owner.isWalking = false; // Stop walking animation explicitly
  }

  public BossState checkTransitions() {
    BossDemon owner = fsm.getOwner();
    // Immediate checks
    if (owner.isDead) return BossState.DEAD;
    if (owner.isHit) return BossState.HIT; // Hit interrupts chase

    // Check if close enough to attack
    if (owner.isInAttackRange(owner.player)) {
       return BossState.ATTACK;
    }

    // No "give up" range, boss keeps chasing
    return BossState.CHASE;
  }
}

// ATTACK State
class BossAttackState implements BossStateHandler {
  private BossFSM fsm;

  BossAttackState(BossFSM fsm) { this.fsm = fsm; }

  public void enter() {
    println("Boss Entering ATTACK");
    BossDemon owner = fsm.getOwner();
    owner.steeringController.clearBehaviors(); // Stop moving while attacking
    owner.startAttack(); // Tell the BossDemon object to handle the animation start
  }

  public void update() {
    // Animation and collision logic are handled within BossDemon.update() and BossDemon.updateAnimation()
  }

  public void exit() {
    BossDemon owner = fsm.getOwner();
     owner.isAttacking = false;
  }

  public BossState checkTransitions() {
    BossDemon owner = fsm.getOwner();
    // Immediate checks
    if (owner.isDead) return BossState.DEAD;
    if (owner.isHit) return BossState.HIT; // Hit interrupts attack

    // Check if the attack animation has finished playing
    if (!owner.isAttacking()) {
        // Attack finished, immediately decide next action
        if (owner.isInAttackRange(owner.player)) {
            return BossState.CHASE;
        } else {
            // Player moved out of range during attack
            return BossState.CHASE;
        }
    }

    // Stay in attack state while animation plays
    return BossState.ATTACK;
  }
}

// HIT State
class BossHitState implements BossStateHandler {
  private BossFSM fsm;

  BossHitState(BossFSM fsm) { this.fsm = fsm; }

  public void enter() {
    println("Boss Entering HIT");
    BossDemon owner = fsm.getOwner();
    owner.steeringController.clearBehaviors(); // Stop moving during hit stun
  }

  public void update() {
    // Hit animation playback is handled in BossDemon.updateAnimation()
  }

  public void exit() {
    BossDemon owner = fsm.getOwner();
    owner.isHit = false;
  }

  public BossState checkTransitions() {
    BossDemon owner = fsm.getOwner();
    // Immediate check
    if (owner.isDead) return BossState.DEAD; // Death overrides hit

    // Check if the hit animation is finished playing
    if (!owner.isHit) {
       // Hit animation finished, recover by chasing
       return BossState.CHASE;
    }

    // Stay in hit state while animation plays
    return BossState.HIT;
  }
}

// DEAD State
class BossDeadState implements BossStateHandler {
  private BossFSM fsm;

  BossDeadState(BossFSM fsm) { this.fsm = fsm; }

  public void enter() {
    println("Boss Entering DEAD");
    BossDemon owner = fsm.getOwner();
    owner.steeringController.clearBehaviors(); // No more steering
  }

  public void update() {
    // Death animation plays via BossDemon.updateAnimation()
  }

  public void exit() {
  }

  public BossState checkTransitions() {
    // Boss stays dead
    return BossState.DEAD;
  }
}