class LevelGenerator {
  // Constants for level generation
  final float platformWidth = 32; // Width of a single platform unit (image width)
  final float platformHeight = 16; // Height of platform image
  final int NUM_LAYERS = 4; // Fixed number of layers (like the original design)
  
  // Level objects
  ArrayList<PlatformObject> platforms = new ArrayList<PlatformObject>();
  ArrayList<Spring> springs = new ArrayList<Spring>();
  ArrayList<Enemy> enemies = new ArrayList<Enemy>();
  ArrayList<Coin> coins = new ArrayList<Coin>();
  
  // Constructor
  LevelGenerator() {
    // Default constructor
  }
  
  // Generate a complete level
  boolean generateLevel(Character player) {
    // Clear any existing objects
    platforms.clear();
    springs.clear();
    enemies.clear();
    coins.clear();
    
    // Generate the level with structures similar to the original design
    generateStructuredPlatforms();
    placeStructuredSprings();
    placeStructuredEnemies(player);
    placeCoins();
    
    return true; // We know this structured approach will create valid levels
  }
  
  // Generate platforms in a structured pattern similar to the original design
  void generateStructuredPlatforms() {
    float groundY = height - 30;
    
    // ---- LAYER 1: Ground level ----
    // Create ground platforms at the bottom (just a reference, not actual platforms)
    // We won't add visual platforms here as the ground.display() handles this
    
    // ---- LAYER 2: First platform layer (height - 150) ----
    float layer2Y = height - 150;
    
    // Left platform cluster
    float leftX = random(width * 0.2f, width * 0.3f);
    createPlatformCluster(leftX, layer2Y, int(random(2, 4)));
    
    // Right platform cluster
    float rightX = random(width * 0.7f, width * 0.8f);
    createPlatformCluster(rightX, layer2Y, int(random(2, 4)));
    
    // ---- LAYER 3: Second platform layer (height - 270) ----
    float layer3Y = height - 270;
    
    // Middle platform cluster
    float middleX = random(width * 0.45f, width * 0.55f);
    createPlatformCluster(middleX, layer3Y, int(random(2, 4)));
    
    // ---- LAYER 4: Third platform layer (height - 330) ----
    float layer4Y = height - 330;
    
    // Left-upper platform cluster
    float leftUpperX = random(width * 0.3f, width * 0.4f);
    createPlatformCluster(leftUpperX, layer4Y, int(random(2, 4)));
    
    // Right-upper platform cluster
    float rightUpperX = random(width * 0.6f, width * 0.7f);
    createPlatformCluster(rightUpperX, layer4Y, int(random(2, 4)));
    
    // ---- LAYER 5: Top platform layer (height - 410 to 490) ----
    
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
  
  // Place springs at fixed positions similar to the original design
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
  
  // Place coin at the top platform (goal)
  void placeCoins() {
    // Find the highest platform (which should be our goal platform)
    PlatformObject highest = null;
    for (PlatformObject platform : platforms) {
      if (highest == null || platform.position.y < highest.position.y) {
        highest = platform;
      }
    }
    
    // Place coin above the highest platform
    if (highest != null) {
      coins.add(new Coin(new PVector(highest.position.x, highest.position.y - 40)));
    } else {
      // Fallback - center of top area
      coins.add(new Coin(new PVector(width * 0.5f, height - 510)));
    }
  }
}