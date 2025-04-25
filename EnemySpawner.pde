class EnemySpawner {
  Character player;
  ArrayList<Enemy> enemies;
  ArrayList<Ammo> ammoPickups;
  ArrayList<HealthPack> healthPacks;
  
  // Add reference to difficulty manager
  DifficultyManager difficultyManager;
  
  // Base values (unscaled by difficulty)
  int baseMaxEnemies = 6;        // Base maximum enemies to spawn
  long baseBaseDelay = 2000;     // Base delay between spawns in milliseconds
  long baseRandomDelay = 1500;   // Base random additional delay in milliseconds
  float baseAmmoSpawnChance = 0.3;   // Base 30% chance to spawn ammo after an enemy
  float baseHealthSpawnChance = 0.2; // Base 20% chance to spawn health after an enemy
  
  // Spawn settings - these will be scaled by difficulty
  int maxEnemies = 3;        // Maximum number of enemies to spawn
  int currentWave = 0;       // Current wave of enemies
  int enemiesSpawned = 0;    // Number of enemies spawned so far
  
  // Item limits
  int maxAmmo = 1;           // Maximum number of ammo pickups at once
  int maxHealthPacks = 2;    // Maximum number of health packs at once
  
  // Timing variables
  long lastSpawnTime = 0;    // Time of last spawn
  long baseDelay = 2000;     // Base delay between spawns in milliseconds
  long randomDelay = 1500;   // Random additional delay in milliseconds
  long nextSpawnTime = 0;    // Time for next spawn
  
  // Position settings
  float spawnHeight = 100;   // Height above ground (increased as requested)
  float minDistanceFromPlayer = 150; // Minimum distance from player
  float maxDistanceFromPlayer = 300; // Maximum distance from player
  
  // Enemy settings
  int enemyType = 5;         // Spearman enemy type
  
  // Item spawn settings
  float ammoSpawnChance = 0.3;    // 30% chance to spawn ammo after an enemy
  float healthSpawnChance = 0.2;  // 20% chance to spawn health after an enemy
  long itemSpawnDelay = 4000;     // Spawn items 4 seconds after enemy spawns
  ArrayList<ScheduledItemSpawn> scheduledItems = new ArrayList<ScheduledItemSpawn>();
  
  // Effect settings
  ArrayList<SmokeEffect> smokeEffects = new ArrayList<SmokeEffect>();
  
  // References for level exit
  Level2Exit levelExit;
  boolean exitSpawned = false;
  boolean isActive = false;  // Whether the spawner is currently active

  // Exit auto-activation timer
  long spawnerDeactivationTime = 0;
  final long EXIT_AUTO_ACTIVATION_DELAY = 5000; // 5 seconds after spawner finishes
  
  // Constructor with difficulty manager
  EnemySpawner(Character player, ArrayList<Enemy> enemies, DifficultyManager difficultyManager) {
    this.player = player;
    this.enemies = enemies;
    this.difficultyManager = difficultyManager;
    
    // Get references to the global lists
    this.ammoPickups = ammoPickups;
    this.healthPacks = healthPacks;
    
    // Apply difficulty scaling to spawner parameters
    applyDifficultyScaling();
    
    resetSpawnTimer();
  }
  
  // Original constructor for backward compatibility
  EnemySpawner(Character player, ArrayList<Enemy> enemies) {
    this.player = player;
    this.enemies = enemies;
    
    // Get references to the global lists
    this.ammoPickups = ammoPickups;
    this.healthPacks = healthPacks;
    
    resetSpawnTimer();
  }
  
  // Apply difficulty scaling to all relevant parameters
  void applyDifficultyScaling() {
    if (difficultyManager == null) return;
    
    // Scale number of enemies based on difficulty
    maxEnemies = difficultyManager.getScaledEnemyCount(baseMaxEnemies);
    
    // Scale timing parameters
    baseDelay = difficultyManager.getScaledSpawnDelay(baseBaseDelay);
    randomDelay = difficultyManager.getScaledSpawnDelay(baseRandomDelay);
    
    // Scale spawn chances
    ammoSpawnChance = difficultyManager.getScaledAmmoSpawnChance(baseAmmoSpawnChance);
    healthSpawnChance = difficultyManager.getScaledHealthSpawnChance(baseHealthSpawnChance);
    
    println("Difficulty level " + difficultyManager.getDifficultyLevel() + 
            " (" + difficultyManager.getDifficultyName() + "): " +
            "Spawning " + maxEnemies + " enemies with spawn delay " + baseDelay + "ms");
  }
  
  // Set a new difficulty level
  void setDifficulty(int level) {
    if (difficultyManager != null) {
      difficultyManager.setDifficultyLevel(level);
      applyDifficultyScaling();
    }
  }
  
  void start() {
    isActive = true;
    enemiesSpawned = 0;
    resetSpawnTimer();
    println("Enemy spawner activated");
  }
  
  void stop() {
    isActive = false;
    println("Enemy spawner deactivated");
  }
  
  void resetSpawnTimer() {
    lastSpawnTime = millis();
    nextSpawnTime = lastSpawnTime + baseDelay + (long)random(randomDelay);
  }
  
  void update() {
    if (!isActive && scheduledItems.isEmpty() && smokeEffects.isEmpty() && !exitSpawned) {
        // Check if it's time to auto-activate the exit
        long currentTime = millis();
        if (spawnerDeactivationTime > 0 && 
            currentTime - spawnerDeactivationTime > EXIT_AUTO_ACTIVATION_DELAY) {
            
            println("Auto-activating exit (5-second timer after spawning)");
            activateExit();
            return;
        }
    }
    
    long currentTime = millis();
    
    // Update existing smoke effects
    for (int i = smokeEffects.size() - 1; i >= 0; i--) {
      SmokeEffect effect = smokeEffects.get(i);
      effect.update();
      if (effect.isDead()) {
        smokeEffects.remove(i);
      }
    }
    
    // Check for scheduled item spawns
    for (int i = scheduledItems.size() - 1; i >= 0; i--) {
      ScheduledItemSpawn item = scheduledItems.get(i);
      if (currentTime >= item.spawnTime) {
        // Check if we can spawn the item based on current counts
        boolean canSpawn = false;
        
        if (item.isAmmo && countActiveAmmo() < maxAmmo) {
          canSpawn = true;
        } else if (!item.isAmmo && countActiveHealthPacks() < maxHealthPacks) {
          canSpawn = true;
        }
        
        if (canSpawn) {
          // Spawn the item
          if (item.isAmmo) {
            spawnAmmo(item.position);
          } else {
            spawnHealthPack(item.position);
          }
        }
        
        // Remove from scheduled list regardless
        scheduledItems.remove(i);
      }
    }
    
    // Check if it's time to spawn a new enemy
    if (isActive && currentTime >= nextSpawnTime && enemiesSpawned < maxEnemies) {
      PVector spawnPosition = calculateSpawnPosition();
      spawnEnemy(spawnPosition);
      enemiesSpawned++;
      resetSpawnTimer();
      
      // Schedule possible item spawns
      maybeScheduleItems(spawnPosition);
    }
    
    // If all enemies have been spawned, deactivate the spawner
    if (isActive && enemiesSpawned >= maxEnemies) {
      isActive = false;
      spawnerDeactivationTime = millis(); // Record when spawner was deactivated
      println("All enemies spawned (" + enemiesSpawned + "), deactivating spawner. Exit will appear in 5 seconds.");
    }
    
    // Check if all enemies are defeated and if we need to activate the exit
    checkForLevelCompletion();
  }

  void checkForLevelCompletion() {
    // Skip if the exit is already spawned/activated
    if (exitSpawned) return;

    // Check if all enemies have been spawned
    if (enemiesSpawned < maxEnemies) return;

    // Check if all enemies are defeated
    boolean allDefeated = true;
    int aliveCount = 0; // Counter for alive enemies

    for (int i = 0; i < enemies.size(); i++) {
        Enemy enemy = enemies.get(i);
        
        // FIX: Also check health directly in case isDead wasn't set correctly
        if (!enemy.isDead && enemy.getHealth() <= 0) {
            // Fix inconsistent state - enemy should be dead if health is 0
            println("  Fixing inconsistent state: Enemy " + i + " has 0 health but not marked dead");
            enemy.isDead = true; // Mark enemy as dead if health is 0 or less
        }
        
        // Now check if the enemy is still alive
        if (!enemy.isDead) {
            allDefeated = false;
            aliveCount++; // Increment count of alive enemies
        }
    }

    // Print the final result of the check in a more concise way
    if (aliveCount > 0) {
        println("  Level completion check: " + aliveCount + " enemies still alive");
    }
    
    // If all enemies are defeated, activate the exit
    if (allDefeated) {
        println("  All enemies defeated! Activating exit...");
        activateExit();
    }
  }
  
  void activateExit() {
    // Just activate the already-created levelExit
    if (levelExit != null) {
      levelExit.activate();
      println("Level exit activated");
    } else {
      println("Warning: Cannot activate level exit (null reference)");
    }
    
    // Mark as spawned/activated
    exitSpawned = true;
    
    // Create a large smoke effect at the exit location
    SmokeEffect exitSmoke = new SmokeEffect(new PVector(width - 100, height - 100), 60);
    smokeEffects.add(exitSmoke);
  }
  
  // Count active (non-collected) ammo pickups
  int countActiveAmmo() {
    int count = 0;
    for (Ammo ammo : ammoPickups) {
      if (!ammo.isCollected()) {
        count++;
      }
    }
    return count;
  }
  
  // Count active (non-collected) health packs
  int countActiveHealthPacks() {
    int count = 0;
    for (HealthPack pack : healthPacks) {
      if (!pack.isCollected()) {
        count++;
      }
    }
    return count;
  }
  
  PVector calculateSpawnPosition() {
    // Decide which side to spawn on (left or right of player)
    boolean spawnOnLeft = random(1) < 0.5;
    
    // Calculate spawn position
    float distanceFromPlayer = random(minDistanceFromPlayer, maxDistanceFromPlayer);
    float spawnX;
    
    if (spawnOnLeft) {
      spawnX = player.position.x - distanceFromPlayer;
    } else {
      spawnX = player.position.x + distanceFromPlayer;
    }
    
    // Make sure spawn position is within screen bounds
    spawnX = constrain(spawnX, 50, width - 50);
    
    // Calculate spawn y position (higher above ground as requested)
    float spawnY = height - spawnHeight - random(20, 50);
    
    return new PVector(spawnX, spawnY);
  }
  
  void spawnEnemy(PVector position) {
    // Create smoke effect at spawn position
    SmokeEffect smoke = new SmokeEffect(position, 30);
    smokeEffects.add(smoke);
    
    // Create the enemy
    Enemy enemy = new Enemy(position.copy(), player, enemyType);
    
    // Scale enemy health based on difficulty if available
    if (difficultyManager != null) {
      int baseHealth = enemy.getHealth();
      int scaledHealth = difficultyManager.getScaledEnemyHealth(baseHealth);
      
      // We can't directly set health since there's no setter in the Enemy class
      // For now we just show the intended health scaling
      float healthMultiplier = (float)scaledHealth / baseHealth;
      println("Enemy spawned with " + (healthMultiplier > 1 ? "increased" : "decreased") + 
              " health: " + scaledHealth + " (" + (int)(healthMultiplier * 100) + "%)");
      
      // Future enhancement: Add a setHealth method to Enemy class
    }
    
    // Set initial state to patrol
    enemy.fsm.forceState(EnemyState.PATROL);
    
    // Add enemy to the list
    enemies.add(enemy);
    
    // Add to physics engine
    physicsEngine.addObject(enemy);
    
    // Apply forces
    GravityForce gravity = new GravityForce(1.5f);
    DragForce drag = new DragForce(0.01f);
    physicsEngine.addForceGenerator(enemy, gravity);
    physicsEngine.addForceGenerator(enemy, drag);
    
    println("Spearman enemy spawned at: " + position.x + ", " + position.y);
  }
  
  void maybeScheduleItems(PVector enemyPosition) {
    // Check if we already have max ammo
    if (countActiveAmmo() < maxAmmo && random(1) < ammoSpawnChance) {
      // Schedule ammo spawn with a delay
      long spawnTime = millis() + itemSpawnDelay + (long)random(-500, 500);
      
      // Create position on the ground
      PVector itemPos = new PVector(
        enemyPosition.x + random(-100, 100), 
        height - 30 // On the ground
      );
      
      // Make sure position is within screen bounds
      itemPos.x = constrain(itemPos.x, 50, width - 50);
      
      // Schedule the spawn
      scheduledItems.add(new ScheduledItemSpawn(itemPos, spawnTime, true));
    }
    
    // Check if we already have max health packs
    if (countActiveHealthPacks() < maxHealthPacks && random(1) < healthSpawnChance) {
      // Schedule health pack spawn with a delay
      long spawnTime = millis() + itemSpawnDelay + (long)random(-500, 500);
      
      // Create position on the ground
      PVector itemPos = new PVector(
        enemyPosition.x + random(-100, 100), 
        height - 30 // On the ground
      );
      
      // Make sure position is within screen bounds
      itemPos.x = constrain(itemPos.x, 50, width - 50);
      
      // Schedule the spawn
      scheduledItems.add(new ScheduledItemSpawn(itemPos, spawnTime, false));
    }
  }
  
  void spawnAmmo(PVector position) {
    // Create smoke effect at spawn position (smaller than enemy smoke)
    SmokeEffect smoke = new SmokeEffect(position, 15);
    smokeEffects.add(smoke);
    
    // Create the ammo pickup
    Ammo ammo = new Ammo(position);
    
    // Add to global list
    ammoPickups.add(ammo);
    
    println("Ammo spawned at: " + position.x + ", " + position.y);
  }
  
  void spawnHealthPack(PVector position) {
    // Create smoke effect at spawn position (smaller than enemy smoke)
    SmokeEffect smoke = new SmokeEffect(position, 15);
    smokeEffects.add(smoke);
    
    // Create the health pack
    HealthPack healthPack = new HealthPack(position);
    
    // Add to global list
    healthPacks.add(healthPack);
    
    println("Health pack spawned at: " + position.x + ", " + position.y);
  }
  
  void drawEffects() {
    // Draw all smoke effects
    for (SmokeEffect effect : smokeEffects) {
      effect.display();
    }
    
    // Draw the exit if spawned
    if (exitSpawned && levelExit != null) {
      levelExit.draw();
    }
  }
  
  // Helper class for scheduled item spawns
  class ScheduledItemSpawn {
    PVector position;
    long spawnTime;
    boolean isAmmo; // true for ammo, false for health pack
    
    ScheduledItemSpawn(PVector position, long spawnTime, boolean isAmmo) {
      this.position = position;
      this.spawnTime = spawnTime;
      this.isAmmo = isAmmo;
    }
  }
  
  // Inner class for smoke particle effect
  class SmokeEffect {
    PVector position;
    ArrayList<SmokeParticle> particles;
    int numParticles;
    boolean active = true;
    long startTime;
    long lifetime = 2000; // Effect lasts for 2 seconds
    
    SmokeEffect(PVector position, int numParticles) {
      this.position = position.copy();
      this.numParticles = numParticles;
      this.startTime = millis();
      
      // Create particles
      particles = new ArrayList<SmokeParticle>();
      for (int i = 0; i < numParticles; i++) {
        particles.add(new SmokeParticle(position));
      }
    }
    
    void update() {
      // Check if effect has expired
      if (millis() - startTime > lifetime) {
        active = false;
        return;
      }
      
      // Update all particles and remove those that are no longer visible
      for (int i = particles.size() - 1; i >= 0; i--) {
        SmokeParticle p = particles.get(i);
        p.update();
        
        // Remove particles that have faded out completely
        if (p.alpha <= 0) {
          particles.remove(i);
        }
      }
      
      // Also mark the effect as inactive if all particles are gone
      if (particles.isEmpty()) {
        active = false;
      }
    }
    
    void display() {
      // Draw all particles
      for (SmokeParticle p : particles) {
        p.display();
      }
    }
    
    boolean isDead() {
      return !active;
    }
  }
  
  // Individual smoke particle
  class SmokeParticle {
    PVector position;
    PVector velocity;
    float size;
    float alpha;
    float fadeSpeed;
    
    SmokeParticle(PVector origin) {
      position = origin.copy();
      // Random velocity, mostly upward
      velocity = new PVector(random(-1, 1), random(-3, -1));
      // Random size
      size = random(10, 25);
      // Start partially transparent
      alpha = random(150, 200);
      // How quickly it fades
      fadeSpeed = random(2, 5);
    }
    
    void update() {
      // Move particle
      position.add(velocity);
      
      // Slowly expand
      size += 0.2;
      
      // Fade out
      alpha -= fadeSpeed;
      if (alpha < 0) alpha = 0;
    }
    
    void display() {
      // Don't draw if completely transparent
      if (alpha <= 0) return;
      
      pushStyle();
      // Use white smoke with transparency
      fill(200, 200, 200, alpha);
      noStroke();
      ellipse(position.x, position.y, size, size);
      popStyle();
    }
  }
}