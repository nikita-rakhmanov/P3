class LevelGenerator {
  // Constants for level generation
  final float platformWidth = 32; // Width of a single platform unit (image width)
  final float platformHeight = 16; // Height of platform image
  final int NUM_LAYERS = 4; // Fixed number of layers (like the original design)
  
  // Maximum attempts to create a valid level
  final int MAX_GENERATION_ATTEMPTS = 10;
  
  // Level objects
  ArrayList<PlatformObject> platforms = new ArrayList<PlatformObject>();
  ArrayList<Spring> springs = new ArrayList<Spring>();
  ArrayList<Enemy> enemies = new ArrayList<Enemy>();
  ArrayList<Coin> coins = new ArrayList<Coin>();
  ArrayList<Ammo> ammoPickups = new ArrayList<Ammo>();
  ArrayList<HealthPack> healthPacks = new ArrayList<HealthPack>();
  LevelExit levelExit = null;

  DifficultyManager difficultyManager;
  
  // Temporary pathfinding components for validation
  GridMap tempGridMap;
  PathFinder tempPathFinder;
  
  // Constructor
  LevelGenerator(DifficultyManager difficultyManager) {
    // Default constructor
    this.difficultyManager = difficultyManager;
  }
  
  // Generate a complete level with validation
  boolean generateLevel(Character player) {
    // Clear any existing objects
    platforms.clear();
    springs.clear();
    enemies.clear();
    coins.clear();
    ammoPickups.clear();
    healthPacks.clear();

    
    // Generate-and-test approach: keep generating until we get a valid level
    boolean validLevel = false;
    int attempts = 0;
    
    while (!validLevel && attempts < MAX_GENERATION_ATTEMPTS) {
      attempts++;
      println("Level generation attempt: " + attempts);
      
      // Clear previous attempt
      platforms.clear();
      springs.clear();
      
      // Generate a new level layout
      generateStructuredPlatforms();
      placeStructuredSprings();
      
      // Setup temporary pathfinding for validation
      setupTempPathfinding();
      
      // Validate the level
      validLevel = validateLevel(player);
      
      if (!validLevel) {
        println("Generated level failed validation. Trying again...");
      }
    }
    
    if (validLevel) {
      println("Valid level generated after " + attempts + " attempts.");
      // Now place enemies and coins on the validated level
      placeStructuredEnemies(player);
      placeCoins();
      placeAmmoPickups();
      placeHealthPacks();
      placeLevelExit();
      return true;
    } else {
      println("Failed to generate a valid level after " + MAX_GENERATION_ATTEMPTS + " attempts.");
      // Fall back to a known-good configuration
      createFallbackLevel();
      return false;
    }
  }
  
  // Create a fallback level with guaranteed playability
  void createFallbackLevel() {
    println("Using fallback level configuration...");
    
    // Clear any existing objects
    platforms.clear();
    springs.clear();
    healthPacks.clear();
    
    // Define a fixed, guaranteed playable layout
    float platformWidth = 32;
    
    // Ground to middle platforms
    platforms.add(new PlatformObject(width * 0.25f, height - 150)); 
    platforms.add(new PlatformObject(width * 0.25f + platformWidth, height - 150));
    platforms.add(new PlatformObject(width * 0.75f, height - 150)); 
    platforms.add(new PlatformObject(width * 0.75f + platformWidth, height - 150));
    
    // Middle platform
    platforms.add(new PlatformObject(width * 0.5f, height - 270));
    platforms.add(new PlatformObject(width * 0.5f + platformWidth, height - 270));
    platforms.add(new PlatformObject(width * 0.5f - platformWidth, height - 270));
    
    // Upper platforms
    platforms.add(new PlatformObject(width * 0.35f, height - 390));
    platforms.add(new PlatformObject(width * 0.65f, height - 390));
    
    // Top platform (goal)
    platforms.add(new PlatformObject(width * 0.5f, height - 490));
    
    // Add springs at critical locations
    springs.add(new Spring(new PVector(width * 0.2f, height - 20))); // Left ground spring
    springs.add(new Spring(new PVector(width * 0.8f, height - 20))); // Right ground spring
    springs.add(new Spring(new PVector(width * 0.5f, height - 150))); // Middle layer spring
    
    // Setup pathfinding and validate this fallback layout
    setupTempPathfinding();
    boolean isValid = validateLevel(null);
    println("Fallback level validity: " + isValid);
    
    // Place level exit
    placeLevelExit();
  }
  
  // Set up temporary pathfinding for level validation
  private void setupTempPathfinding() {
    float cellSize = 16.0f;
    tempGridMap = new GridMap(width, height, cellSize);
    
    // Mark ground as non-walkable
    float groundLevel = height - 30;
    for (int x = 0; x < tempGridMap.cols; x++) {
      for (int y = 0; y < tempGridMap.rows; y++) {
        float worldY = (y + 0.5f) * cellSize;
        if (worldY >= groundLevel) {
          tempGridMap.setWalkable(x, y, false);
        }
      }
    }
    
    // Mark platforms as non-walkable but areas above platforms as walkable
    for (PlatformObject platform : platforms) {
      float platWidth = platform.platformImage.width;
      float platHeight = platform.platformImage.height;
      
      // Get grid coordinates for platform
      PVector topLeft = tempGridMap.worldToGrid(new PVector(
        platform.position.x - platWidth/2,
        platform.position.y - platHeight/2
      ));
      
      PVector bottomRight = tempGridMap.worldToGrid(new PVector(
        platform.position.x + platWidth/2,
        platform.position.y + platHeight/2
      ));
      
      // Mark platform area as non-walkable
      for (int x = (int)topLeft.x; x <= (int)bottomRight.x; x++) {
        for (int y = (int)topLeft.y; y <= (int)bottomRight.y; y++) {
          if (tempGridMap.isValid(x, y)) {
            tempGridMap.setWalkable(x, y, false);
          }
        }
      }
      
      // Mark the area directly above platform as walkable
      for (int x = (int)topLeft.x; x <= (int)bottomRight.x; x++) {
        int y = (int)topLeft.y - 1;
        if (tempGridMap.isValid(x, y)) {
          tempGridMap.setWalkable(x, y, true);
        }
      }
    }
    
    // Create the temporary pathfinder
    tempPathFinder = new PathFinder(tempGridMap);
  }
  
  // Validate level by checking connectivity and reachability
  // Replace your validateLevel method with this version that doesn't rely on PathFinder
  private boolean validateLevel(Character player) {
    // First, check if we have all the necessary components
    if (platforms.isEmpty()) {
      println("Validation failed: No platforms found");
      return false;
    }
    
    if (springs.isEmpty()) {
      println("Validation failed: No springs found");
      return false;
    }
    
    // --- Step 1: Check if there are platforms at all major height layers ---
    float[] keyHeights = {height - 150, height - 270, height - 330, height - 410, height - 490};
    for (float layerY : keyHeights) {
      ArrayList<PlatformObject> layerPlatforms = findPlatformsAtHeight(layerY, 30);
      if (layerPlatforms.isEmpty()) {
        println("Validation failed: No platforms at height " + layerY);
        return false;
      }
    }
    
    // --- Step 2: Check if there are ground springs ---
    boolean hasGroundSpring = false;
    for (Spring spring : springs) {
      if (spring.position.y > height - 50) {
        hasGroundSpring = true;
        break;
      }
    }
    
    if (!hasGroundSpring) {
      println("Validation failed: No springs at ground level");
      return false;
    }
    
    // --- Step 3: Check vertical progression ---
    // We'll check if each layer can be reached from the layer below
    
    // Get platforms grouped by layer
    HashMap<Float, ArrayList<PlatformObject>> platformsByLayer = new HashMap<Float, ArrayList<PlatformObject>>();
    for (float height : keyHeights) {
      platformsByLayer.put(height, findPlatformsAtHeight(height, 30));
    }
    
    // Check bottom-to-top progression
    for (int i = 1; i < keyHeights.length; i++) {
      float lowerLayer = keyHeights[i-1];
      float upperLayer = keyHeights[i];
      
      // Get platforms in these layers
      ArrayList<PlatformObject> lowerPlatforms = platformsByLayer.get(lowerLayer);
      ArrayList<PlatformObject> upperPlatforms = platformsByLayer.get(upperLayer);
      
      // Skip if either layer is empty (already checked above)
      if (lowerPlatforms.isEmpty() || upperPlatforms.isEmpty()) continue;
      
      // Check if any platform in the upper layer can be reached from any in the lower
      boolean progressionPossible = false;
      
      for (PlatformObject lower : lowerPlatforms) {
        for (PlatformObject upper : upperPlatforms) {
          // Calculate distance between platforms
          float dx = abs(lower.position.x - upper.position.x);
          float dy = lower.position.y - upper.position.y; // Lower y value means higher platform
          
          // Is the height difference within jump range?
          float jumpHeight = 170; // Estimate of jump height
          if (dy < jumpHeight && dx < 120) {
            progressionPossible = true;
            break;
          }
        }
        if (progressionPossible) break;
      }
      
      // Also check if springs can reach the upper layer
      if (!progressionPossible) {
        for (Spring spring : springs) {
          // Skip if spring is not on the lower layer
          boolean springOnLowerLayer = false;
          for (PlatformObject platform : lowerPlatforms) {
            if (abs(spring.position.x - platform.position.x) < platformWidth &&
                abs(spring.position.y - platform.position.y) < platformHeight) {
              springOnLowerLayer = true;
              break;
            }
          }
          
          // Also consider ground springs for the first layer
          if (i == 1 && spring.position.y > height - 50) {
            springOnLowerLayer = true;
          }
          
          if (!springOnLowerLayer) continue;
          
          // Check if spring can reach any platform in upper layer
          for (PlatformObject upper : upperPlatforms) {
            float dx = abs(spring.position.x - upper.position.x);
            float dy = spring.position.y - upper.position.y;
            
            // Spring has greater reach
            float springReach = 400; // Estimate of spring bounce height
            if (dy < springReach && dx < 200) {
              progressionPossible = true;
              break;
            }
          }
          if (progressionPossible) break;
        }
      }
      
      if (!progressionPossible) {
        println("Validation failed: Cannot progress from layer " + lowerLayer + " to " + upperLayer);
        return false;
      }
    }
    
    // --- Step 4: Verify goal platform is reachable ---
    PlatformObject goalPlatform = findHighestPlatform();
    if (goalPlatform == null) {
      println("Validation failed: No goal platform found");
      return false;
    }
    
    // Check if the goal platform is connected to the layer below it
    float goalY = goalPlatform.position.y;
    float layerBelowGoalY = height - 410; // Expected height of the layer below the goal
    
    ArrayList<PlatformObject> layerBelowGoal = findPlatformsAtHeight(layerBelowGoalY, 30);
    boolean goalReachable = false;
    
    // Check if goal can be reached by normal jump from layer below
    for (PlatformObject platform : layerBelowGoal) {
      float dx = abs(platform.position.x - goalPlatform.position.x);
      float dy = platform.position.y - goalPlatform.position.y;
      
      if (dy < 180 && dx < 140) { // Slightly larger values for the final jump
        goalReachable = true;
        break;
      }
    }
    
    // Check if goal can be reached from spring on layer below
    if (!goalReachable) {
      for (Spring spring : springs) {
        // Check if spring is on a platform in the layer below
        boolean springOnLayerBelow = false;
        for (PlatformObject platform : layerBelowGoal) {
          if (abs(spring.position.x - platform.position.x) < platformWidth &&
              abs(spring.position.y - platform.position.y) < platformHeight) {
            springOnLayerBelow = true;
            break;
          }
        }
        
        if (!springOnLayerBelow) continue;
        
        // Check if spring can reach goal
        float dx = abs(spring.position.x - goalPlatform.position.x);
        float dy = spring.position.y - goalPlatform.position.y;
        
        if (dy < 450 && dx < 200) { // Larger values for spring to goal
          goalReachable = true;
          break;
        }
      }
    }
    
    if (!goalReachable) {
      println("Validation failed: Goal platform is not reachable");
      return false;
    }
    
    return true; // All validation checks passed!
  }
  
  // Find platforms at a specific height (with tolerance)
  private ArrayList<PlatformObject> findPlatformsAtHeight(float targetY, float tolerance) {
    ArrayList<PlatformObject> result = new ArrayList<PlatformObject>();
    for (PlatformObject platform : platforms) {
      if (abs(platform.position.y - targetY) < tolerance) {
        result.add(platform);
      }
    }
    return result;
  }
  
  // Find the highest platform (goal platform)
  private PlatformObject findHighestPlatform() {
    PlatformObject highest = null;
    for (PlatformObject platform : platforms) {
      if (highest == null || platform.position.y < highest.position.y) {
        highest = platform;
      }
    }
    return highest;
  }
  
  // Special check if the goal platform is reachable via springs or jumps
  private boolean isGoalReachable(PlatformObject goalPlatform) {
    // Get position of top of goal platform
    PVector goalPos = new PVector(goalPlatform.position.x, 
                                 goalPlatform.position.y - platformHeight/2 - 10);
    
    // First check if directly reachable from ground
    PVector startPos = new PVector(width / 2, height - 30);
    Path directPath = tempPathFinder.findPath(startPos, goalPos);
    if (!directPath.isEmpty()) {
      return true;
    }
    
    // Check if reachable via springs
    for (Spring spring : springs) {
      // Get position just above spring
      PVector springTopPos = new PVector(spring.position.x, spring.position.y - 20);
      
      // Is spring reachable?
      Path pathToSpring = tempPathFinder.findPath(startPos, springTopPos);
      if (!pathToSpring.isEmpty() || abs(springTopPos.x - startPos.x) < 200) {
        // Spring is reachable, now can spring reach goal?
        float springJumpHeight = 300; // Max height gain from spring
        float horizontalRange = 150;  // Horizontal range with spring
        
        if (goalPos.y > springTopPos.y - springJumpHeight && 
            abs(goalPos.x - springTopPos.x) < horizontalRange) {
          return true; // Goal is within spring's reach
        }
      }
    }
    
    // Check if reachable via intermediate platforms
    for (PlatformObject platform : platforms) {
      // Skip if this is the goal platform
      if (platform == goalPlatform) continue;
      
      // Get position on top of platform
      PVector platformPos = new PVector(platform.position.x, 
                                       platform.position.y - platformHeight/2 - 10);
      
      // Check if platform is reachable
      Path pathToPlatform = tempPathFinder.findPath(startPos, platformPos);
      if (!pathToPlatform.isEmpty() || isPlatformReachableViaSpring(platform)) {
        // Platform is reachable, can we reach goal from here?
        float jumpHeight = 150; // Normal jump height
        float horizontalRange = 100; // Horizontal range with jump
        
        // Is goal platform above this platform and within jump reach?
        if (goalPos.y < platformPos.y && 
            goalPos.y > platformPos.y - jumpHeight &&
            abs(goalPos.x - platformPos.x) < horizontalRange) {
          return true; // Goal is reachable from this platform
        }
      }
    }
    
    return false; // Goal not reachable by any means
  }
  
  // Check if a platform is reachable via any spring
  private boolean isPlatformReachableViaSpring(PlatformObject platform) {
    PVector platformPos = new PVector(platform.position.x, 
                                     platform.position.y - platformHeight/2 - 10);
    
    for (Spring spring : springs) {
      PVector springPos = new PVector(spring.position.x, spring.position.y - 20);
      
      // Is spring at ground level? (simplified check)
      boolean springOnGround = spring.position.y > height - 50;
      
      if (springOnGround) {
        // Ground-level spring
        float springJumpHeight = 300;
        float horizontalRange = 150;
        
        if (platformPos.y > springPos.y - springJumpHeight && 
            abs(platformPos.x - springPos.x) < horizontalRange) {
          return true; // Platform reachable from spring
        }
      }
    }
    
    return false;
  }
  
  // Generate platforms in a structured pattern with randomization
  void generateStructuredPlatforms() {
    float groundY = height - 30;
    
    // ---- LAYER 1: First platform layer (height - 150) ----
    float layer1Y = height - 150;
    
    // Left platform cluster
    float leftX = random(width * 0.2f, width * 0.3f);
    createPlatformCluster(leftX, layer1Y, int(random(2, 4)));
    
    // Right platform cluster
    float rightX = random(width * 0.7f, width * 0.8f);
    createPlatformCluster(rightX, layer1Y, int(random(2, 4)));
    
    // ---- LAYER 2: Second platform layer (height - 270) ----
    float layer2Y = height - 270;
    
    // Middle platform cluster
    float middleX = random(width * 0.45f, width * 0.55f);
    createPlatformCluster(middleX, layer2Y, int(random(2, 4)));
    
    // ---- LAYER 3: Third platform layer (height - 330) ----
    float layer3Y = height - 330;
    
    // Left-upper platform cluster
    float leftUpperX = random(width * 0.3f, width * 0.4f);
    createPlatformCluster(leftUpperX, layer3Y, int(random(2, 4)));
    
    // Right-upper platform cluster
    float rightUpperX = random(width * 0.6f, width * 0.7f);
    createPlatformCluster(rightUpperX, layer3Y, int(random(2, 4)));
    
    // ---- LAYER 4: Top platform layer (height - 410 to 490) ----
    
    // Left top platform
    float leftTopX = random(width * 0.4f, width * 0.45f);
    createPlatformCluster(leftTopX, height - 410, int(random(1, 3)));
    
    // Center top platform (goal platform, higher than others)
    createPlatformCluster(width * 0.5f, height - 490, int(random(2, 3)));
    
    // Right top platform
    float rightTopX = random(width * 0.55f, width * 0.6f);
    createPlatformCluster(rightTopX, height - 410, int(random(1, 3)));
  }
  
  // Create a cluster of platforms centered at (x,y) with specified width
  void createPlatformCluster(float x, float y, int widthInUnits) {
    // Add the center platform
    platforms.add(new PlatformObject(x, y));
    
    // Add platforms to the left and right
    for (int i = 1; i < widthInUnits; i++) {
      // Left extension (may be skipped randomly for variety)
      if (random(1) > 0.3 || i == 1) { // Higher chance to add, always add at least one
        platforms.add(new PlatformObject(x - i * platformWidth, y));
      }
      
      // Right extension (may be skipped randomly for variety)
      if (random(1) > 0.3 || i == 1) { // Higher chance to add, always add at least one
        platforms.add(new PlatformObject(x + i * platformWidth, y));
      }
    }
  }
  
  // Place springs at strategic positions for vertical traversal
  void placeStructuredSprings() {
    // Always place springs at the ground level on both sides
    springs.add(new Spring(new PVector(width * random(0.1f, 0.2f), height - 20)));
    springs.add(new Spring(new PVector(width * random(0.8f, 0.9f), height - 20)));
    
    // Find platforms in the first layer (height ~ 150)
    ArrayList<PlatformObject> firstLayerPlatforms = new ArrayList<PlatformObject>();
    float targetY = height - 150;
    
    for (PlatformObject platform : platforms) {
      if (abs(platform.position.y - targetY) < 10) {
        firstLayerPlatforms.add(platform);
      }
    }
    
    // Place a spring on a first-layer platform near the center if available
    if (!firstLayerPlatforms.isEmpty()) {
      // Find the platform closest to center
      PlatformObject closestToCenter = firstLayerPlatforms.get(0);
      float closestDistance = abs(closestToCenter.position.x - width/2);
      
      for (PlatformObject platform : firstLayerPlatforms) {
        float distance = abs(platform.position.x - width/2);
        if (distance < closestDistance) {
          closestToCenter = platform;
          closestDistance = distance;
        }
      }
      
      // Place spring directly on this platform - fixed positioning
      // The Y coordinate should be the platform's Y position
      springs.add(new Spring(new PVector(closestToCenter.position.x, closestToCenter.position.y)));
    } else {
      // Fallback - add a spring somewhere in the middle of the first layer
      springs.add(new Spring(new PVector(width * 0.5f, height - 150)));
    }
  }
  
  // Place enemies in positions similar to the original design
  void placeStructuredEnemies(Character player) {
    // Create 4 enemies with different types, like in the original design
    Enemy enemy1, enemy2, enemy3, enemy4;
    
    // Lower level enemies (ground level)
    enemy1 = new Enemy(new PVector(width * random(0.2f, 0.3f), height - 30), player, 1);
    enemy2 = new Enemy(new PVector(width * random(0.7f, 0.8f), height - 30), player, 2);
    
    // Upper level enemies (on platforms)
    // Find platforms at around height - 330
    ArrayList<PlatformObject> upperPlatforms = new ArrayList<PlatformObject>();
    for (PlatformObject platform : platforms) {
      if (abs(platform.position.y - (height - 330)) < 20) {
        upperPlatforms.add(platform);
      }
    }
    
    // Place enemies on upper platforms if available
    if (upperPlatforms.size() >= 2) {
      // Find a left and right platform
      PlatformObject leftPlatform = null;
      PlatformObject rightPlatform = null;
      
      for (PlatformObject p : upperPlatforms) {
        if (p.position.x < width/2 && (leftPlatform == null || p.position.x > leftPlatform.position.x)) {
          leftPlatform = p;
        }
        if (p.position.x > width/2 && (rightPlatform == null || p.position.x < rightPlatform.position.x)) {
          rightPlatform = p;
        }
      }
      
      // Create enemies on these platforms
      if (leftPlatform != null) {
        enemy3 = new Enemy(new PVector(leftPlatform.position.x, 
                                      leftPlatform.position.y - platformHeight/2 - 20), player, 3);
      } else {
        // Fallback
        enemy3 = new Enemy(new PVector(width * 0.35f, height - 350), player, 3);
      }
      
      if (rightPlatform != null) {
        enemy4 = new Enemy(new PVector(rightPlatform.position.x, 
                                       rightPlatform.position.y - platformHeight/2 - 20), player, 4);
      } else {
        // Fallback
        enemy4 = new Enemy(new PVector(width * 0.65f, height - 350), player, 4);
      }
    } else {
      // Fallback positions if we don't have enough platforms
      enemy3 = new Enemy(new PVector(width * 0.35f, height - 350), player, 3);
      enemy4 = new Enemy(new PVector(width * 0.65f, height - 350), player, 4);
    }
    
    // Apply difficulty scaling to enemy health
    scaleEnemyHealth(enemy1);
    scaleEnemyHealth(enemy2);
    scaleEnemyHealth(enemy3);
    scaleEnemyHealth(enemy4);
    
    // Add enemies to the list
    enemies.add(enemy1);
    enemies.add(enemy2);
    enemies.add(enemy3);
    enemies.add(enemy4);
    
    // Set initial states
    enemies.get(0).fsm.forceState(EnemyState.PATROL);
    enemies.get(1).fsm.forceState(EnemyState.PATROL);
    enemies.get(2).fsm.forceState(EnemyState.IDLE);
    enemies.get(3).fsm.forceState(EnemyState.PATROL);
  }

  // Helper method to scale enemy health based on difficulty
  private void scaleEnemyHealth(Enemy enemy) {
    if (difficultyManager == null) return;
    
    // Get base health
    int baseHealth = enemy.getHealth();
    
    // Scale health based on difficulty
    int scaledHealth = difficultyManager.getScaledEnemyHealth(baseHealth);
    
    // Apply the scaled health
    enemy.setHealth(scaledHealth);
    
    // Optional debug output
    float healthMultiplier = (float)scaledHealth / baseHealth;
    String difficultyName = difficultyManager.getDifficultyName();
    println("Level 1 Enemy (Type " + enemy.enemyType + ") scaled health: " + 
            scaledHealth + " (" + (int)(healthMultiplier * 100) + "%) at " + 
            difficultyName + " difficulty");
  }
  
  // Place coin at the top platform (goal)
  void placeCoins() {
    // Find the highest platform (which should be our goal platform)
    PlatformObject highest = findHighestPlatform();
    
    // Place coin above the highest platform
    if (highest != null) {
      coins.add(new Coin(new PVector(highest.position.x, highest.position.y - 40)));
    } else {
      // Fallback - center of top area
      coins.add(new Coin(new PVector(width * 0.5f, height - 510)));
    }
  }

  void placeAmmoPickups() {
    // Use difficulty manager to scale number of pickups (if available)
    int baseNumAmmoPickups = int(random(1, 3));
    int numAmmoPickups = baseNumAmmoPickups;
    
    // Scale based on difficulty if difficultyManager exists
    if (difficultyManager != null) {
        // Calculate max pickups based on difficulty
        float scaledMax = baseNumAmmoPickups * difficultyManager.getScaledAmmoSpawnChance(1.0f);
        
        // Round to nearest integer, with minimum of 1
        numAmmoPickups = max(1, round(scaledMax));
        
        if (showDebugPath) { // Use existing debug flag
            println("Ammo pickups: Base count " + baseNumAmmoPickups + 
                   ", Scaled to " + numAmmoPickups + 
                   " at difficulty " + difficultyManager.getDifficultyLevel());
        }
    }
    
    // Find platforms at different heights for distribution
    ArrayList<PlatformObject> lowPlatforms = findPlatformsAtHeight(height - 150, 30);
    ArrayList<PlatformObject> midPlatforms = findPlatformsAtHeight(height - 270, 30);
    ArrayList<PlatformObject> highPlatforms = findPlatformsAtHeight(height - 330, 30);
    
    // Make sure we have platforms at each level
    if (lowPlatforms.isEmpty() || midPlatforms.isEmpty() || highPlatforms.isEmpty()) {
        // Fallback placements if we don't have all platform levels
        ammoPickups.add(new Ammo(new PVector(width * 0.3f, height - 200)));
        if (numAmmoPickups >= 2) {
            ammoPickups.add(new Ammo(new PVector(width * 0.7f, height - 200)));
        }
        return;
    }
    
    // Strategic placement at different heights
    // Always place one at low level for initial gameplay
    if (!lowPlatforms.isEmpty()) {
        PlatformObject platform = lowPlatforms.get(int(random(lowPlatforms.size())));
        ammoPickups.add(new Ammo(new PVector(platform.position.x, platform.position.y - 20)));
    }
    
    // Place one at mid level
    if (!midPlatforms.isEmpty() && numAmmoPickups >= 2) {
        PlatformObject platform = midPlatforms.get(int(random(midPlatforms.size())));
        ammoPickups.add(new Ammo(new PVector(platform.position.x, platform.position.y - 20)));
    }
    
    // Place one at high level if we want 3 pickups
    if (!highPlatforms.isEmpty() && numAmmoPickups >= 3) {
        PlatformObject platform = highPlatforms.get(int(random(highPlatforms.size())));
        ammoPickups.add(new Ammo(new PVector(platform.position.x, platform.position.y - 20)));
    }
}

void placeHealthPacks() {
    // Use difficulty manager to scale number of health packs
    int baseNumHealthPacks = int(random(1, 3));
    int numHealthPacks = baseNumHealthPacks;
    
    // Scale based on difficulty if difficultyManager exists
    if (difficultyManager != null) {
        // Calculate max health packs based on difficulty
        float scaledMax = baseNumHealthPacks * difficultyManager.getScaledHealthSpawnChance(1.0f);
        
        // Round to nearest integer, with minimum of 1
        numHealthPacks = max(1, round(scaledMax));
        
        if (showDebugPath) { // Use existing debug flag
            println("Health packs: Base count " + baseNumHealthPacks + 
                   ", Scaled to " + numHealthPacks + 
                   " at difficulty " + difficultyManager.getDifficultyLevel());
        }
    }
    
    // Find platforms at different heights
    ArrayList<PlatformObject> lowPlatforms = findPlatformsAtHeight(height - 150, 30);
    ArrayList<PlatformObject> midPlatforms = findPlatformsAtHeight(height - 270, 30);
    ArrayList<PlatformObject> highPlatforms = findPlatformsAtHeight(height - 330, 30);
    
    // Make sure we have platforms
    if (lowPlatforms.isEmpty() && midPlatforms.isEmpty() && highPlatforms.isEmpty()) {
        // Fallback placements if we don't have proper platforms
        healthPacks.add(new HealthPack(new PVector(width * 0.5f, height - 180)));
        return;
    }
    
    // Height offset for placing items above platforms
    float heightOffset = -25.0f;
    
    // Place first health pack at mid level if possible
    if (!midPlatforms.isEmpty()) {
        // Find a platform that doesn't have ammo on it
        PlatformObject bestPlatform = null;
        for (PlatformObject platform : midPlatforms) {
            boolean hasAmmo = false;
            for (Ammo ammo : ammoPickups) {
                if (abs(ammo.position.x - platform.position.x) < 30) {
                    hasAmmo = true;
                    break;
                }
            }
            // This check should be OUTSIDE the inner loop
            if (!hasAmmo) {
                bestPlatform = platform;
                break;
            }
        }
        
        // If we couldn't find a platform without ammo, use any platform
        if (bestPlatform == null && !midPlatforms.isEmpty()) {
            bestPlatform = midPlatforms.get(int(random(midPlatforms.size())));
        }
        
        if (bestPlatform != null) {
            healthPacks.add(new HealthPack(new PVector(bestPlatform.position.x, bestPlatform.position.y + heightOffset)));
        }
    }
    
    // Place second health pack at high level if requested
    if (numHealthPacks >= 2) {
        // Try high platforms first, then low platforms as fallback
        ArrayList<PlatformObject> targetPlatforms = !highPlatforms.isEmpty() ? highPlatforms : lowPlatforms;
        
        if (!targetPlatforms.isEmpty()) {
            // Again, try to find a platform without ammo
            PlatformObject bestPlatform = null;
            for (PlatformObject platform : targetPlatforms) {
                boolean hasAmmo = false;
                for (Ammo ammo : ammoPickups) {
                    if (abs(ammo.position.x - platform.position.x) < 30) {
                        hasAmmo = true;
                        break;
                    }
                }
                // This check should be OUTSIDE the inner loop
                if (!hasAmmo) {
                    bestPlatform = platform;
                    break;
                }
            }
            
            // If we couldn't find a platform without ammo, use any platform
            if (bestPlatform == null && !targetPlatforms.isEmpty()) {
                bestPlatform = targetPlatforms.get(int(random(targetPlatforms.size())));
            }
            
            if (bestPlatform != null) {
                healthPacks.add(new HealthPack(new PVector(bestPlatform.position.x, bestPlatform.position.y + heightOffset)));
            }
        }
    }
}

    void placeLevelExit() {
      // Create the exit at ground level in the central area
      // Initially inactive - will be activated when coin is collected
      float exitX = width * random(0.4f, 0.6f); // Random position in central area
      levelExit = new LevelExit(new PVector(exitX, height - 30));
      
      // Make sure the exit is initially inactive
      levelExit.deactivate();
    }
}