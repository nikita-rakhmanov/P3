enum EnemyState {
  IDLE,
  PATROL,
  CHASE,
  ATTACK,
  HIT,
  DEAD
}

class EnemyFSM {
  private Enemy owner;
  private EnemyState currentState;
  private HashMap<EnemyState, EnemyStateHandler> stateHandlers;
  
  EnemyFSM(Enemy owner) {
    this.owner = owner;
    this.currentState = EnemyState.IDLE;
    
    // Initialize state handlers
    stateHandlers = new HashMap<EnemyState, EnemyStateHandler>();
    stateHandlers.put(EnemyState.IDLE, new IdleStateHandler(this));
    stateHandlers.put(EnemyState.PATROL, new PatrolStateHandler(this));
    stateHandlers.put(EnemyState.CHASE, new ChaseStateHandler(this));
    stateHandlers.put(EnemyState.ATTACK, new AttackStateHandler(this));
    stateHandlers.put(EnemyState.HIT, new HitStateHandler(this));
    stateHandlers.put(EnemyState.DEAD, new DeadStateHandler(this));
  }
  
  void update() {
    // Get the current state handler and update
    EnemyStateHandler currentHandler = stateHandlers.get(currentState);
    currentHandler.update();
    
    // Check for state transitions
    checkStateTransitions();
  }
  
  void checkStateTransitions() {
    // This method will check conditions and potentially change states
    EnemyStateHandler currentHandler = stateHandlers.get(currentState);
    EnemyState nextState = currentHandler.checkTransitions();
    
    if (nextState != currentState) {
      // State change
      EnemyStateHandler oldHandler = stateHandlers.get(currentState);
      EnemyStateHandler newHandler = stateHandlers.get(nextState);
      
      // Exit old state
      oldHandler.exit();
      
      // Change state
      currentState = nextState;
      
      // Enter new state
      newHandler.enter();
      
      // Debug message
    //   println("Enemy state changed from " + currentState + " to " + nextState);
    }
  }
  
  void forceState(EnemyState newState) {
    if (newState != currentState) {
      // Exit current state
      stateHandlers.get(currentState).exit();
      
      // Change state
      currentState = newState;
      
      // Enter new state
      stateHandlers.get(currentState).enter();
      
    //   println("Enemy state forced to " + newState);
    }
  }
  
  Enemy getOwner() {
    return owner;
  }
  
  EnemyState getCurrentState() {
    return currentState;
  }
}

// Base interface for state handlers
interface EnemyStateHandler {
  void enter();  // Called when entering the state
  void update(); // Called every frame while in this state
  void exit();   // Called when exiting the state
  EnemyState checkTransitions(); // Check if should transition to a new state
}

// Implementations for each state
class IdleStateHandler implements EnemyStateHandler {
  private EnemyFSM fsm;
  private float idleTimer;
  private final float IDLE_DURATION = 2.0f; // seconds
  
  IdleStateHandler(EnemyFSM fsm) {
    this.fsm = fsm;
    this.idleTimer = 0;
  }
  
  void enter() {
    Enemy enemy = fsm.getOwner();
    // Clear all behaviors
    enemy.steeringController.clearBehaviors();
    // Reset animation state
    enemy.isRunning = false;
    enemy.isAttacking = false;
    idleTimer = 0;
  }
  
  void update() {
    // Increment idle timer
    idleTimer += 1.0f / frameRate;
  }
  
  void exit() {
    // Nothing to clean up
  }
  
  EnemyState checkTransitions() {
    Enemy enemy = fsm.getOwner();
    Character player = enemy.player;
    
    // Check if enemy should transition to another state
    if (enemy.isDead) {
      return EnemyState.DEAD;
    } else if (enemy.isHit) {
      return EnemyState.HIT;
    }
    
    // Check if player is within detection range
    float detectionRange = 200.0f;
    float distToPlayer = PVector.dist(enemy.position, player.position);
    
    if (distToPlayer < detectionRange) {
      return EnemyState.CHASE; // Player detected, start chasing
    } else if (idleTimer > IDLE_DURATION) {
      return EnemyState.PATROL; // Idle time exceeded, start patrolling
    }
    
    return EnemyState.IDLE; // Stay idle
  }
}

class PatrolStateHandler implements EnemyStateHandler {
  private EnemyFSM fsm;
  private PVector patrolStart;
  private PVector patrolEnd;
  private float patrolWidth = 150.0f;
  
  PatrolStateHandler(EnemyFSM fsm) {
    this.fsm = fsm;
  }
  
  void enter() {
    Enemy enemy = fsm.getOwner();
    enemy.steeringController.clearBehaviors();
    
    // Customize patrol behavior based on enemy type
    switch(enemy.getEnemyType()) {
      case 1: // Aggressive 
        patrolWidth = 100.0f;
        break;
      case 2: // Mixed - medium area
        patrolWidth = 150.0f;
        break;
      case 3: // Platform enemy - stays in place more
        patrolWidth = 100.0f;
        break;
      case 4: // Evasive
        patrolWidth = 100.0f;
        // Add flee behavior to move away from player even during patrol
        enemy.steeringController.addBehavior(new Flee(enemy.player.position, 1.2f, 200), 0.8f);
        break;
    }
    
    // Set up patrol area around current position
    patrolStart = new PVector(enemy.position.x - patrolWidth/2, enemy.position.y);
    patrolEnd = new PVector(enemy.position.x + patrolWidth/2, enemy.position.y);
    
    // Add wander behavior for patrolling 
    enemy.steeringController.addBehavior(
      new BoundedWander(0.3f, 30, 15, 
                       patrolStart.x, 
                       patrolEnd.x, 
                       enemy.position.y), 1.0f);
    
    // Add a small random force to get movement started
    enemy.applyForce(new PVector(random(-0.5f, 0.5f), 0));
    
    enemy.isRunning = true;
  }
  
  void update() {
    // Calculate steering forces for patrol
    Enemy enemy = fsm.getOwner();
    
    // Update the target position for any Flee behaviors
    for (int i = 0; i < enemy.steeringController.behaviors.size(); i++) {
      SteeringBehavior behavior = enemy.steeringController.behaviors.get(i);
      if (behavior instanceof Flee) {
        ((Flee)behavior).targetPosition = enemy.player.position;
      }
    }
    
    enemy.steeringController.calculateSteering();
  }
  
  void exit() {
    // Nothing to clean up
  }
  
  EnemyState checkTransitions() {
    Enemy enemy = fsm.getOwner();
    Character player = enemy.player;
    
    if (enemy.isDead) {
      return EnemyState.DEAD;
    } else if (enemy.isHit) {
      return EnemyState.HIT;
    }
    
    float chaseRange = 150.0f;
    float distToPlayer = PVector.dist(enemy.position, player.position);
    
    if (distToPlayer < chaseRange) {
      return EnemyState.CHASE;
    }
    
    return EnemyState.PATROL; // Stay in patrol
  }
}

// ChaseStateHandler class
class ChaseStateHandler implements EnemyStateHandler {
  private EnemyFSM fsm;
  private Path currentPath;
  private PVector lastPlayerPosition;
  private float playerMovementThreshold = 50.0f; // Distance player must move to trigger recalculation
  private boolean usePathfinding = true;
  
  ChaseStateHandler(EnemyFSM fsm) {
    this.fsm = fsm;
  }
  
  void enter() {
    Enemy enemy = fsm.getOwner();
    enemy.steeringController.clearBehaviors();
    
    // For evasive enemy (type 4), don't use pathfinding at all - evasive behavior
    if (enemy.getEnemyType() == 4) {
      usePathfinding = false;
      setupSteeringBehaviors(enemy);
      enemy.isRunning = true;
      return;
    }
    
    if (usePathfinding) {
      // Store initial player position
      lastPlayerPosition = enemy.player.position.copy();
      
      // Calculate initial path when entering chase state
      calculateNewPath(enemy);
    } else {
      // Fallback to normal steering behaviors
      setupSteeringBehaviors(enemy);
    }
    
    enemy.isRunning = true;
  }
  
  private void calculateNewPath(Enemy enemy) {
    // Create a path from current enemy position to current player position
    PVector start = enemy.position.copy();
    PVector goal = enemy.player.position.copy();
    
    try {
      if (pathFinder != null) {
        // Get a new path
        Path newPath = pathFinder.findPath(start, goal);
        
        // Only update if we got a valid path
        if (newPath != null && !newPath.isEmpty()) {
          currentPath = newPath;
          updatePathFollowBehavior(enemy);
        }
      } else {
        println("Warning: PathFinder is null, falling back to steering behaviors");
        usePathfinding = false;
        setupSteeringBehaviors(enemy);
      }
    } catch (Exception e) {
      println("Error calculating path: " + e.getMessage());
      usePathfinding = false;
      setupSteeringBehaviors(enemy);
    }
  }
  
  private void setupSteeringBehaviors(Enemy enemy) {
    // fallback behavior if pathfinding fails
    float acceleration = 0.9f;
    float weight = 1.0f;
    
    switch(enemy.getEnemyType()) {
      case 1: // Aggressive chaser
        acceleration = 1.2f;
        weight = 1.0f;
        break;
      case 2: // Mixed behavior
        acceleration = 0.7f;
        weight = 0.8f;
        enemy.steeringController.addBehavior(new Wander(0.3f, 50, 30), 0.2f);
        break;
      case 3: // Platform enemy
        acceleration = 0.5f;
        weight = 0.6f;
        break;
      case 4: // Evasive enemy
        acceleration = 0.6f;
        weight = 0.4f;
        enemy.steeringController.addBehavior(new Flee(enemy.player.position, 1f, 100), 0.6f);
        break;
    }
    
    enemy.steeringController.addBehavior(
      new Seek(enemy.player.position, acceleration), weight);
  }
  
  private void updatePathFollowBehavior(Enemy enemy) {
    // Remove any existing PathFollow behaviors
    for (int i = enemy.steeringController.behaviors.size() - 1; i >= 0; i--) {
      if (enemy.steeringController.behaviors.get(i) instanceof PathFollow) {
        enemy.steeringController.behaviors.remove(i);
        enemy.steeringController.weights.remove(i);
      }
    }
    
    // Add a new PathFollow behavior with the current path
    float arrivalRadius = 15.0f;
    float acceleration = 0.9f;
    float weight = 1.0f;
    
    switch(enemy.getEnemyType()) {
      case 1: // Aggressive
        acceleration = 1.2f;
        arrivalRadius = 12.0f;
        break;
      case 2: // Mixed
        acceleration = 0.7f;
        arrivalRadius = 15.0f;
        break;
      case 3: // Platform
        acceleration = 0.5f;
        arrivalRadius = 18.0f;
        weight = 0.8f;
        break;
      case 4: // Evasive
        acceleration = 0.6f;
        arrivalRadius = 20.0f;
        weight = 0.7f;
        enemy.steeringController.addBehavior(new Flee(enemy.player.position, 0.4f, 80), 0.25f);
        break;
    }
    
    PathFollow pathFollow = new PathFollow(currentPath, arrivalRadius, acceleration);
    pathFollow.setDebugDraw(showDebugPath);
    enemy.steeringController.addBehavior(pathFollow, weight);
  }
  
  void update() {
    Enemy enemy = fsm.getOwner();
    
    if (usePathfinding) {
      // Check if player has moved enough to warrant a path recalculation
      float playerMovementDistance = PVector.dist(enemy.player.position, lastPlayerPosition);
      
      if (playerMovementDistance > playerMovementThreshold) {
        // println("Player moved, recalculating path...");
        // Player has moved significantly, recalculate path
        calculateNewPath(enemy);
        lastPlayerPosition = enemy.player.position.copy();
      }
      
      // Check if path is still valid (enemy might have fallen off a platform)
      if (currentPath != null && !currentPath.isEmpty()) {
        // If the first waypoint is too far from the enemy, recalculate
        PVector firstPoint = currentPath.getFirstPoint();
        if (firstPoint != null) {
          float distToFirstPoint = PVector.dist(enemy.position, firstPoint);
          if (distToFirstPoint > 200) {
            // println("Path is too far, recalculating...");
            calculateNewPath(enemy);
          }
        }
      }
    } else {
      // Update target positions for regular steering behaviors
      for (int i = 0; i < enemy.steeringController.behaviors.size(); i++) {
        SteeringBehavior behavior = enemy.steeringController.behaviors.get(i);
        if (behavior instanceof Seek) {
          ((Seek)behavior).targetPosition = enemy.player.position;
        } else if (behavior instanceof Flee) {
          ((Flee)behavior).targetPosition = enemy.player.position;
        }
      }
    }
    
    // Apply forces
    enemy.steeringController.calculateSteering();
  }
  
  void exit() {
    // Nothing specific to clean up
  }
  
  EnemyState checkTransitions() {
    Enemy enemy = fsm.getOwner();
    Character player = enemy.player;
    
    if (enemy.isDead) {
      return EnemyState.DEAD;
    } else if (enemy.isHit) {
      return EnemyState.HIT;
    }
    
    // Customize ranges based on enemy type
    float attackRange = 25.0f;
    float giveUpRange = 250.0f;
    
    switch(enemy.getEnemyType()) {
      case 1: // Aggressive - never gives up, attacks from further
        attackRange = 35.0f;
        giveUpRange = 400.0f;
        break;
      case 2: // Mixed - standard values
        attackRange = 25.0f;
        giveUpRange = 250.0f;
        break;
      case 3: // Platform enemy - more hesitant to attack
        attackRange = 20.0f;
        giveUpRange = 100.0f;
        break;
      case 4: // Evasive - prefers to keep distance and gives up chase easily
        attackRange = 20.0f;
        giveUpRange = 90.0f;
        break;
    }
    
    float distToPlayer = PVector.dist(enemy.position, player.position);
    
    if (distToPlayer < attackRange) {
      return EnemyState.ATTACK;
    } else if (distToPlayer > giveUpRange) {
      return EnemyState.PATROL; // Lost the player, go back to patrol
    }
    
    return EnemyState.CHASE; // Continue chasing
  }
}

class AttackStateHandler implements EnemyStateHandler {
  private EnemyFSM fsm;
  
  AttackStateHandler(EnemyFSM fsm) {
    this.fsm = fsm;
  }
  
  void enter() {
    Enemy enemy = fsm.getOwner();
    enemy.steeringController.clearBehaviors();
    enemy.isAttacking = true;
    enemy.currentFrame = 0;
    
    // Make enemy face the player
    if (enemy.player.position.x < enemy.position.x) {
      enemy.hFlip = true;
    } else {
      enemy.hFlip = false;
    }
  }
  
  void update() {
    // Attack animation and logic is already handled in the Enemy class
  }
  
  void exit() {
    Enemy enemy = fsm.getOwner();
    enemy.isAttacking = false;
  }
  
  EnemyState checkTransitions() {
    Enemy enemy = fsm.getOwner();
    
    if (enemy.isDead) {
      return EnemyState.DEAD;
    } else if (enemy.isHit) {
      return EnemyState.HIT;
    }
    
    // Transition after attack animation is complete
    if (enemy.currentFrame >= enemy.attackFrames.length - 1) {
      // Attack finished, check distance to player
      float attackRange = 25.0f;
      float distToPlayer = PVector.dist(enemy.position, enemy.player.position);
      
      if (distToPlayer < attackRange) {
        // Still in range, attack again
        return EnemyState.ATTACK;
      } else {
        // Out of range, chase
        return EnemyState.CHASE;
      }
    }
    
    return EnemyState.ATTACK; // Continue attacking
  }
}

class HitStateHandler implements EnemyStateHandler {
  private EnemyFSM fsm;
  
  HitStateHandler(EnemyFSM fsm) {
    this.fsm = fsm;
  }
  
  void enter() {
    Enemy enemy = fsm.getOwner();
    enemy.steeringController.clearBehaviors();
    enemy.currentFrame = 0;
    // Hit animation is already handled in the Enemy class
  }
  
  void update() {
    // Hit reaction is handled by the Enemy class
  }
  
  void exit() {
    Enemy enemy = fsm.getOwner();
    enemy.isHit = false;
  }
  
  EnemyState checkTransitions() {
    Enemy enemy = fsm.getOwner();
    
    if (enemy.isDead) {
      return EnemyState.DEAD;
    }
    
    // Transition after hit animation is complete
    if (enemy.currentFrame >= enemy.hitFrames.length - 1) {
      // Hit reaction finished, decide next state
      float attackRange = 25.0f;
      float distToPlayer = PVector.dist(enemy.position, enemy.player.position);
      
      if (distToPlayer < attackRange) {
        return EnemyState.ATTACK;
      } else {
        return EnemyState.CHASE;
      }
    }
    
    return EnemyState.HIT; // Continue hit reaction
  }
}

class DeadStateHandler implements EnemyStateHandler {
  private EnemyFSM fsm;
  
  DeadStateHandler(EnemyFSM fsm) {
    this.fsm = fsm;
  }
  
  void enter() {
    Enemy enemy = fsm.getOwner();
    enemy.steeringController.clearBehaviors();
    enemy.currentFrame = 0;
    // Death animation is handled by the Enemy class
  }
  
  void update() {
    // Death animation and logic is handled by the Enemy class
  }
  
  void exit() {
    // nothing to clean up
  }
  
  EnemyState checkTransitions() {
    // No transitions from dead state
    return EnemyState.DEAD;
  }
}