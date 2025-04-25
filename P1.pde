import processing.sound.*;

Background bg;
Character character;
LevelGenerator levelGenerator;
Platform ground;
ArrayList<Enemy> enemies = new ArrayList<Enemy>();
ArrayList<Spring> springs = new ArrayList<Spring>();
ArrayList<PlatformObject> platforms = new ArrayList<PlatformObject>();
ArrayList<Coin> coins = new ArrayList<Coin>();
ArrayList<HealthPack> healthPacks = new ArrayList<HealthPack>();
boolean attackLanded = false;
boolean gameOver = false;
boolean gameStarted = false;
PhysicsEngine physicsEngine;
long gameStartTime = 0;
long gameEndTime = 0;
boolean timerRunning = false;
GridMap gridMap;
static PathFinder pathFinder;
boolean showDebugGrid = false;
boolean showDebugPath = false;
int currentCamera = 1; // 1 = default camera, 2 = player follow camera
float cameraZoom = 1.5f; 
PVector cameraPosition = new PVector(0, 0); 
float cameraLerpFactor = 0.1f; 
float targetCameraZoom = 1.0f;
float currentCameraZoom = 1.0f;
float cameraTransitionSpeed = 0.05f; 
SoundFile bgMusicLevel1;
SoundFile bgMusicLevel2;
SoundFile currentBgMusic;
boolean musicChanging = false;
boolean musicEnabled = true;
float musicVolume = 0.4f; 
float currentMusicVolume = 0.0f; 
float fadeSpeed = 0.01f; // Increased from 0.001f for faster fading
boolean fadingIn = true; 
boolean useProceduralGeneration = true; // Flag to use procedural generation
ArrayList<Ammo> ammoPickups = new ArrayList<Ammo>();
LevelExit levelExit;
Level2Exit level2Exit;
int currentLevel = 1; // Current level number
boolean inLevelTransition = false;
boolean cameraFocusOnExit = false;
long cameraFocusStartTime = 0;
int savedCameraMode = 1; // Save previous camera mode
PVector savedCameraPosition = new PVector(0, 0);
float savedCameraZoom = 1.0f;
boolean pendingExitActivation = false;
long exitActivationTime = 0;
final long EXIT_ACTIVATION_DELAY = 1000; // Delay in milliseconds before activating exit
EnemySpawner enemySpawner;
DifficultyManager difficultyManager;
int currentDifficulty = 1; // Default medium difficulty (1-5 scale)

BossDemon bossDemon = null;

boolean victoryPending = false;
long bossDeathTime = 0;
final long VICTORY_DELAY = 5500; // 5.5 seconds delay to show death animation

boolean showDifficultySelection = false;
String[] difficultyNames = {"Very Easy", "Easy", "Normal", "Hard", "Very Hard"};
int selectedDifficulty = 2; // Default to Normal (array index + 1)

class PlatformObject extends PhysicsObject {
  PImage platformImage;
  
  PlatformObject(float x, float y) {
    super(new PVector(x, y), 0.0f); 
    this.isStatic = true;
    this.radius = 25.0f;
    
    // Load the platform image
    platformImage = loadImage("CharacterPack/GPE/platforms/platform_through.png");
  }
  
  void draw() {
    image(platformImage, position.x, position.y);
  }
}

void setup() {
  size(1024, 768);
  noSmooth();
  imageMode(CENTER);
  textMode(CENTER);

  // Load all background music tracks
  bgMusicLevel1 = new SoundFile(this, "music/bg_song.mp3");
  bgMusicLevel2 = new SoundFile(this, "music/bg_2_song.mp3");
  
  // Set initial music to level 1
  currentBgMusic = bgMusicLevel1;
  currentBgMusic.loop();
  currentBgMusic.amp(0); // Start with volume at 0 for fade in
  currentMusicVolume = 0.0f;
  fadingIn = true;

  // physics engine
  physicsEngine = new PhysicsEngine();

  // Load background and ground
  bg = new Background("CharacterPack/Enviro/BG/trees_bg.png");
  ground = new Platform("CharacterPack/GPE/platforms/platform_through.png");
  
  // Create character in the middle
  character = new Character(new PVector(width / 2, height - 30));

  // Initialize the difficulty manager
  // difficultyManager = new DifficultyManager(currentDifficulty);

  // // Create level generator and generate level
  // LevelGenerator levelGenerator = new LevelGenerator(difficultyManager);
  // boolean levelGenerated = false;

  // Initialize and generate a new level
  initializeLevel();
  
}

// Use this function to initialize and use the level generator
void initializeLevel() {
  // Clear existing game objects
  platforms.clear();
  springs.clear();
  enemies.clear();
  coins.clear();
  ammoPickups.clear();
  healthPacks.clear();
  bossDemon = null; // Clear boss reference
  
  // Determine which level to load
  if (currentLevel == 1) {
    initializeLevel1();
  } else if (currentLevel == 2) {
    initializeLevel2();
  } else if (currentLevel == 3) {
    initializeLevel3();
  } 
  
  // Configure physics engine and other systems
  setupPhysicsEngine();
  setupPathfinding();
  
  // Reset game start time when initializing a new level
  gameStartTime = millis();
}

void initializeLevel1() {
  // Initialize the difficulty manager
  difficultyManager = new DifficultyManager(currentDifficulty);

  // Initialize level generator
  levelGenerator = new LevelGenerator(difficultyManager);
  
  if (useProceduralGeneration) {
    // Generate procedural level
    println("Generating procedural level...");
    boolean levelGenerated = levelGenerator.generateLevel(character);
    
    if (levelGenerated) {
      // Use generated objects
      println("Procedural level generated successfully");
      platforms = levelGenerator.platforms;
      springs = levelGenerator.springs;
      enemies = levelGenerator.enemies;
      coins = levelGenerator.coins;
      ammoPickups = levelGenerator.ammoPickups;
      healthPacks = levelGenerator.healthPacks;
      levelExit = levelGenerator.levelExit; // Add this line
    } else {
      // Fallback to fixed level if generation fails
      println("Level generation failed, using fallback level");
      createFixedLevel();
    }
  } else {
    // Use fixed level design
    createFixedLevel();
  }
  
  // Load the regular background
  bg = new Background("CharacterPack/Enviro/BG/trees_bg.png");

  // Change music to level 1 theme
  changeLevelMusic(1);
}

void initializeLevel2() {
  println("Initializing Level 2 (Perlin Noise with Enemy Waves)...");
  
  // Clear all game objects
  platforms.clear();
  springs.clear();
  enemies.clear();
  coins.clear();
  ammoPickups.clear();
  healthPacks.clear();
  
  // Use the Perlin noise background
  bg = new PerlinNoiseBackground();
  
  // Create a custom Platform class for level 2 ground at the correct height
  class Level2Ground extends Platform {
    Level2Ground(String imgPath) {
      super(imgPath);
    }
    
    void display() {
      for (int x = 0; x < width; x += img.width) {
        image(img, x + img.width/2, height + 10);
      }
    }
  }
  
  // Use the samurai environment ground texture with correct positioning
  ground = new Level2Ground("PixelArt_Samurai/Environment/PNG/Environment_Ground.png");
  
  // Place the player at the true ground level
  character.position = new PVector(width * 0.5f, height - character.radius);
  character.velocity = new PVector(0, 0);
  
  // Create the level exit at the right edge of the screen (initially inactive)
  float exitX = width - 50;
  float exitY = height - 50;
  level2Exit = new Level2Exit(new PVector(exitX, exitY));
  level2Exit.deactivate(); // Make sure it starts deactivated
  
  // Initialize the difficulty manager
  difficultyManager = new DifficultyManager(currentDifficulty);
  
  // Initialize the enemy spawner with references to the global object lists and difficulty manager
  enemySpawner = new EnemySpawner(character, enemies, difficultyManager);
  enemySpawner.ammoPickups = ammoPickups;
  enemySpawner.healthPacks = healthPacks;
  
  // Pass the level exit reference to the enemy spawner
  enemySpawner.levelExit = level2Exit;
  
  // Configure physics engine with minimal objects
  setupPhysicsEngine();
  setupPathfinding();
  
  // Start spawning enemies after a short delay
  Thread enemySpawnerThread = new Thread(new Runnable() {
    public void run() {
      try {
        Thread.sleep(3000);
        enemySpawner.start();
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
    }
  });
  enemySpawnerThread.start();

  // Change music to level 2 theme
  changeLevelMusic(2);
}

// Level 3
void initializeLevel3() {
  println("Initializing Level 3 (Fixed Level Design)...");

  // Clear all game objects
  platforms.clear();
  springs.clear();
  enemies.clear();
  coins.clear();
  ammoPickups.clear();
  healthPacks.clear();

  // Use the samurai environment background
  bg = new AsciiBackground();

  // Create a custom Platform class for level 2 ground at the correct height
  class Level2Ground extends Platform {
    Level2Ground(String imgPath) {
      super(imgPath);
    }
    
    void display() {
      for (int x = 0; x < width; x += img.width) {
        image(img, x + img.width/2, height + 10);
      }
    }
  }
  
  ground = new Level2Ground("PixelArt_Samurai/Environment/PNG/Environment_Ground.png");
  
  // Place the player at the true ground level
  character.position = new PVector(width * 0.5f, height - character.radius);
  
  // Initialize the difficulty manager
  difficultyManager = new DifficultyManager(currentDifficulty);

  // Create the Boss Demon
  float bossGroundY = height - 50; 
  bossDemon = new BossDemon(new PVector(width * 0.75f, bossGroundY), character);
  
  // Configure physics engine with minimal objects
  setupPhysicsEngine();

  // Level 3 uses the same music as level 2
  changeLevelMusic(2);
}

// Create the fixed level (your original level design)
void createFixedLevel() {

  float platformWidth = 32;

  // First layer - low platforms 
  platforms.add(new PlatformObject(width * 0.25f - platformWidth, height - 150)); 
  platforms.add(new PlatformObject(width * 0.25f, height - 150));                
  platforms.add(new PlatformObject(width * 0.25f + platformWidth, height - 150));
  
  platforms.add(new PlatformObject(width * 0.75f - platformWidth, height - 150)); 
  platforms.add(new PlatformObject(width * 0.75f, height - 150));                 
  platforms.add(new PlatformObject(width * 0.75f + platformWidth, height - 150));
  
  // Second layer - middle platforms 
  platforms.add(new PlatformObject(width * 0.5f - platformWidth, height - 270));
  platforms.add(new PlatformObject(width * 0.5f, height - 270));                
  platforms.add(new PlatformObject(width * 0.5f + platformWidth, height - 270)); 
  
  // Third layer - higher platforms
  platforms.add(new PlatformObject(width * 0.35f - platformWidth, height - 330)); 
  platforms.add(new PlatformObject(width * 0.35f, height - 330));                 
  platforms.add(new PlatformObject(width * 0.35f + platformWidth, height - 330)); 
  
  platforms.add(new PlatformObject(width * 0.65f - platformWidth, height - 330)); 
  platforms.add(new PlatformObject(width * 0.65f, height - 330));                
  platforms.add(new PlatformObject(width * 0.65f + platformWidth, height - 330)); 
  
  // Fourth layer - high platforms 
  platforms.add(new PlatformObject(width * 0.5f - platformWidth, height - 410)); 
  platforms.add(new PlatformObject(width * 0.5f, height - 490));                 
  platforms.add(new PlatformObject(width * 0.5f + platformWidth, height - 410)); 
  
  // Add springs at strategic locations 
  springs.add(new Spring(new PVector(width * 0.15f, height - 20))); // Left lower spring
  springs.add(new Spring(new PVector(width * 0.85f, height - 20))); // Right lower spring
  springs.add(new Spring(new PVector(width * 0.5f, height - 150))); // Middle spring on first platform
  
  // Create enemies
  Enemy enemy1 = new Enemy(new PVector(width / 4, height - 30), character, 1);
  Enemy enemy2 = new Enemy(new PVector(width * 3 / 4, height - 30), character, 2);
  Enemy enemy3 = new Enemy(new PVector(width * 0.35f, height - 330 - 20), character, 3); 
  Enemy enemy4 = new Enemy(new PVector(width * 0.65f, height - 330 - 20), character, 4); 

  enemies.add(enemy1);
  enemies.add(enemy2);
  enemies.add(enemy3);
  enemies.add(enemy4);

  // Configure initial states
  enemies.get(0).fsm.forceState(EnemyState.PATROL);
  enemies.get(1).fsm.forceState(EnemyState.PATROL);
  enemies.get(2).fsm.forceState(EnemyState.IDLE);
  enemies.get(3).fsm.forceState(EnemyState.PATROL);
  
  // Add a coin on the top platform
  coins.add(new Coin(new PVector(width * 0.5f, height - 510 - 10)));
  
  // Add health packs
  healthPacks.add(new HealthPack(new PVector(width * 0.4f, height - 350)));
  healthPacks.add(new HealthPack(new PVector(width * 0.6f, height - 350)));

  // Add ammo pickups
  ammoPickups.add(new Ammo(new PVector(width * 0.2f, height - 150)));
}

// Setup the physics engine with current game objects
void setupPhysicsEngine() {
  // Clear the physics engine
  physicsEngine = new PhysicsEngine();
  
  // Add objects to physics engine
  physicsEngine.addObject(character);
  
  for (Enemy enemy : enemies) {
    physicsEngine.addObject(enemy);
  }

  // Add Boss Demon (if it exists for this level)
  if (bossDemon != null) {
      physicsEngine.addObject(bossDemon);
  }
  
  for (Spring spring : springs) {
    physicsEngine.addObject(spring);
  }
  
  for (PlatformObject platform : platforms) {
    physicsEngine.addObject(platform);
  }
  
  // Add force generators
  GravityForce gravity = new GravityForce(1.5f);
  DragForce drag = new DragForce(0.01f);
  
  // Apply forces to character
  physicsEngine.addForceGenerator(character, gravity);
  physicsEngine.addForceGenerator(character, drag);
  
  // Apply forces to enemies
  for (Enemy enemy : enemies) {
    physicsEngine.addForceGenerator(enemy, gravity);
    physicsEngine.addForceGenerator(enemy, drag);
  }

  if (bossDemon != null) {
      physicsEngine.addForceGenerator(bossDemon, gravity);
      physicsEngine.addForceGenerator(bossDemon, drag);
      println("Forces applied to Boss Demon.");
  }
}

// initialize the pathfinding grid
void setupPathfinding() {
  float cellSize = 16.0f; // Size of each grid cell in pixels
  gridMap = new GridMap(width, height, cellSize);
  
  float groundLevel = height; //  where the character stands on the ground
  
  // Mark all cells below ground level as non-walkable
  for (int x = 0; x < gridMap.cols; x++) {
    for (int y = 0; y < gridMap.rows; y++) {
      float worldY = (y + 0.5f) * cellSize; // Center of cell in world coordinates
      
      if (worldY >= groundLevel) {
        gridMap.setWalkable(x, y, false);
      }
    }
  }
  
  // Mark platforms as non-walkable but areas above platforms as walkable
  for (PlatformObject platform : platforms) {
    float platformWidth = platform.platformImage.width;
    float platformHeight = platform.platformImage.height;
    
    // Get grid coordinates for platform
    PVector topLeft = gridMap.worldToGrid(new PVector(
      platform.position.x - platformWidth/2,
      platform.position.y - platformHeight/2
    ));
    
    PVector bottomRight = gridMap.worldToGrid(new PVector(
      platform.position.x + platformWidth/2,
      platform.position.y + platformHeight/2
    ));
    
    // Mark platform area as non-walkable
    for (int x = (int)topLeft.x; x <= (int)bottomRight.x; x++) {
      for (int y = (int)topLeft.y; y <= (int)bottomRight.y; y++) {
        if (gridMap.isValid(x, y)) {
          gridMap.setWalkable(x, y, false);
        }
      }
    }
    
    // Mark the area directly above platform as walkable
    for (int x = (int)topLeft.x; x <= (int)bottomRight.x; x++) {
      int y = (int)topLeft.y - 1;
      if (gridMap.isValid(x, y)) {
        gridMap.setWalkable(x, y, true);
      }
    }
  }
  
  // Create the pathfinder
  pathFinder = new PathFinder(gridMap);
}

// getter for PathFinder
PathFinder getPathFinder() {
  return pathFinder;
}

// Update keyPressed to start the timer when the game begins
void keyPressed() {
  if (!gameStarted) {
    if (!showDifficultySelection) {
      // From main menu to difficulty selection
      if (key == ENTER || key == RETURN) {
        showDifficultySelection = true;
      }
    } else {
      // On difficulty selection screen
      if (keyCode == UP) {
        selectedDifficulty = max(1, selectedDifficulty - 1);
      } else if (keyCode == DOWN) {
        selectedDifficulty = min(5, selectedDifficulty + 1);
      } else if (key == ENTER || key == RETURN) {
        // Start game with selected difficulty
        gameStarted = true;
        showDifficultySelection = false;
        currentDifficulty = selectedDifficulty;
        // Start the timer when the game begins
        gameStartTime = millis();
        timerRunning = true;
        
        // Apply selected difficulty
        setGameDifficulty(currentDifficulty);
      } else if (keyCode == ESC || key == BACKSPACE) {
        // Return to main menu
        showDifficultySelection = false;
        key = 0; // Prevent ESC from quitting the game
      }
    }
  } else if (!gameOver) { // Only process inputs when game is active
    // Camera controls
    if (key == '1') {
      currentCamera = 1; // Default camera
    } else if (key == '2') {
      currentCamera = 2; // Follow camera
    }
    
    character.handleKeyPressed(key);
      } else if (key == 'r' || key == 'R') { // Allow restart with 'R' key
    resetGame();
  }

  // Toggle music with 'M' key
  if (key == 'm' || key == 'M') {
    musicEnabled = !musicEnabled;
    if (musicEnabled) {
      // Start fading in music
      if (!currentBgMusic.isPlaying()) {
        currentBgMusic.loop();  // Use loop() instead of play()
      }
      fadingIn = true;
    } else {
      // Start fading out music (actual pause happens when volume reaches 0)
      fadingIn = false;
    }
  }

  // Toggle debug grid display with 'G' key
  if (key == 'g' || key == 'G') {
    showDebugGrid = !showDebugGrid;
  }
  
  // Toggle debug path display with 'P' key
  if (key == 'p' || key == 'P') {
    showDebugPath = !showDebugPath;
    // Update the pathfinder debug mode
    pathFinder.setDebugMode(showDebugPath);
    
    // Update all PathFollow behaviors
    for (Enemy enemy : enemies) {
      for (SteeringBehavior behavior : enemy.steeringController.behaviors) {
        if (behavior instanceof PathFollow) {
          ((PathFollow)behavior).setDebugDraw(showDebugPath);
        }
      }
    }
  }
}

void keyReleased() {
  if (gameStarted && !gameOver) { // Only process inputs when game is active
    character.handleKeyReleased(key);
  }
}

void mousePressed() {
  if (gameStarted && !gameOver && mouseButton == LEFT) { // Only process inputs when game is active
    character.shoot();
  }
}

void draw() {
  background(0);
  
  // Handle music volume fading
  updateMusicFade();

  // Handle camera focus animation
  handleCameraFocusAnimation();
  
  // Check for pending exit activation
  checkPendingExitActivation(); // Add this line
  
  // Handle camera before drawing anything
  pushMatrix();
  
  // Update target zoom based on current camera
  targetCameraZoom = (currentCamera == 2) ? cameraZoom : 1.0f;

  // Smoothly interpolate camera zoom
  currentCameraZoom = lerp(currentCameraZoom, targetCameraZoom, cameraTransitionSpeed);
  
  if (character != null) {
    // For both camera modes, center on the player 
    PVector targetPosition = new PVector();
    
    if (currentCamera == 1) {
      // Default camera logic (unchanged)
      float progressToDefaultView = 1.0 - constrain((currentCameraZoom - 1.0) / (cameraZoom - 1.0), 0, 1);
      targetPosition.x = width/2 - character.position.x;
      targetPosition.y = height/2 - character.position.y;
      targetPosition.x = lerp(targetPosition.x, 0, progressToDefaultView);
      targetPosition.y = lerp(targetPosition.y, 0, progressToDefaultView);
    } else {
      // Follow camera logic      
      // Calculate the visible area in world coordinates
      float visibleWidth = width / currentCameraZoom;
      float visibleHeight = height / currentCameraZoom;
      
      // Check if the visible area is larger than the game world
      if (visibleWidth >= width || visibleHeight >= height) {
        // If visible area is larger than game world, center on the game world
        targetPosition.x = width/2 - (width/2) * currentCameraZoom;
        targetPosition.y = height/2 - (height/2) * currentCameraZoom;
      } else {
        // Normal case - constrain player within appropriate margins
        float marginX = visibleWidth / 2;
        float marginY = visibleHeight / 2;
        
        // Constrain player position to ensure it's not too close to the edges
        float boundedPlayerX = constrain(character.position.x, marginX, width - marginX);
        float boundedPlayerY = constrain(character.position.y, marginY, height - marginY);
        
        // Set camera position based on this bounded position
        targetPosition.x = width/2 - boundedPlayerX * currentCameraZoom;
        targetPosition.y = height/2 - boundedPlayerY * currentCameraZoom;
      }
    }
    
    // Adaptive lerp speed 
    float distanceToTarget = PVector.dist(cameraPosition, targetPosition);
    float baseLerpFactor = constrain(cameraLerpFactor * (1 + distanceToTarget / 500), 0.03, 0.2);
    
    // Smooth transition for camera position
    cameraPosition.x = lerp(cameraPosition.x, targetPosition.x, baseLerpFactor);
    cameraPosition.y = lerp(cameraPosition.y, targetPosition.y, baseLerpFactor);
    
    // Apply camera transformation
    translate(cameraPosition.x, cameraPosition.y);
    scale(currentCameraZoom);
  }
  
  // Draw the background and game world
  bg.display();
  ground.display();

  // Draw debug grid if enabled
  if (showDebugGrid) {
    gridMap.debugDraw();
  }
  
  // Draw pathfinder debug info if enabled
  if (showDebugPath) {
    pathFinder.debugDraw();
  }
  
  if (!gameStarted) {
    displayStartScreen();
    popMatrix(); // Don't forget to pop the matrix before returning
    return;
  }
  
  if (!gameOver) {
    // Update physics engine
    physicsEngine.update();
    
    // Update character and enemies
    character.update();
    for (Enemy enemy : enemies) {
      enemy.update();
    }

    // Update enemy spawner if in level 2 and game is active
    if (currentLevel == 2 && gameStarted && !gameOver && enemySpawner != null) {
      enemySpawner.update();
    }

    //Update Boss Demon
    if (bossDemon != null && !bossDemon.isDead) { // Check if null
          bossDemon.update(); // This calls the BossFSM update internally
    }
    
    // Update and check coins 
    updateCoins();

    // Update ammo pickups
    updateAmmoPickups();
    
    // Update health packs
    updateHealthPacks();
    
    // Handle bullet collisions with all enemies
    handleBulletCollisions();
    
    // Handle attack collisions with all enemies
    handleAttackCollisions();
    
    // Check if any enemy is attacking the player
    handleEnemyAttacks();
    
    // Check if player is dead
    if (character.isDead) {
      gameOver = true;
    }
    
    // Check for platform collisions
    handlePlatformCollisions();
    handleEnemyPlatformCollisions();
  }
  
  // Check for spring collisions
  checkSprings();

  // Check for collision with level exit
  if (levelExit != null && !inLevelTransition && !gameOver) {
    levelExit.update();
    
    if (levelExit.isPlayerInRange(character)) {
      // Player has entered the exit - start level transition
      inLevelTransition = true;
      levelExit.deactivate();
      
      // Transition to the next level after a short delay
      Thread transitionThread = new Thread(new Runnable() {
        public void run() {
          try {
            // Wait for a moment
            Thread.sleep(1000);
            
            // Increment level and reset player position
            currentLevel++;
            resetPlayerForLevel(currentLevel);
            
            // Initialize the new level
            initializeLevel();
            
            // End transition
            inLevelTransition = false;
          } catch (InterruptedException e) {
            e.printStackTrace();
          }
        }
      });
      transitionThread.start();
    }
  }

  // check for level2Exit
  if (currentLevel == 2 && level2Exit != null && !inLevelTransition && !gameOver) {
    level2Exit.update();
    
    if (level2Exit.isPlayerInRange(character)) {
      // Player has entered the level 2 exit - start level transition
      inLevelTransition = true;
      level2Exit.deactivate();
      
      // Transition to the next level after a short delay
      Thread transitionThread = new Thread(new Runnable() {
        public void run() {
          try {
            // Wait for a moment
            Thread.sleep(1000);
            
            // Increment level and reset player position
            currentLevel++;
            resetPlayerForLevel(currentLevel);
            
            // Initialize the new level
            initializeLevel();
            
            // End transition
            inLevelTransition = false;
          } catch (InterruptedException e) {
            e.printStackTrace();
          }
        }
      });
      transitionThread.start();
    }
  }

// Add Victory Condition (Level 3 Boss Defeated)
if (currentLevel == 3 && bossDemon != null && bossDemon.isDead) {
    // If this is the first frame the boss is detected as dead
    if (!victoryPending && !gameOver) {
        println("Boss defeated! Playing death animation...");
        victoryPending = true;
        bossDeathTime = millis();
        if (timerRunning) {
            gameEndTime = millis();
            timerRunning = false;
        }
    }
    
    // Only show victory screen after the delay
    if (victoryPending && !gameOver && millis() > bossDeathTime + VICTORY_DELAY) {
        println("Level 3 Victory!");
        gameOver = true; // Now trigger victory screen
        victoryPending = false;
    }
}

  // Draw level transition effect
  if (inLevelTransition) {
    pushStyle();
    fill(0, 0, 0, map(min(frameCount % 60, 60 - frameCount % 60), 0, 30, 0, 255));
    rect(0, 0, width, height);
    popStyle();
  }
  
  // Draw all game objects
  drawGameObjects();
  
  // Handle camera focus animation
  handleCameraFocusAnimation();
  
  // Pop the matrix to restore default transformation for HUD drawing
  popMatrix();
  
  // Draw HUD (in screen space)
  displayHUD();
  
  // Show camera and music info
  fill(255);
  textSize(16);
  textAlign(LEFT);
  text("Camera: " + (currentCamera == 1 ? "Default" : "Follow Player") + " ('1' or '2' to change)", 50, height - 630);
  text("Music: " + (musicEnabled ? "ON" : "OFF") + " (Press 'M' to toggle)", 50, height - 600);
}

// Function to handle music fade in/out
void updateMusicFade() {
  if (musicEnabled && !musicChanging) {
    // Fade in when music is enabled
    if (fadingIn) {
      currentMusicVolume += fadeSpeed;
      if (currentMusicVolume >= musicVolume) {
        currentMusicVolume = musicVolume;
        fadingIn = false;
      }
      currentBgMusic.amp(currentMusicVolume);
      
      // Make sure music is playing
      if (!currentBgMusic.isPlaying()) {
        currentBgMusic.loop();
      }
    }
  } else if (!musicEnabled || !fadingIn) {
    // Fade out when music is disabled or we're changing tracks
    currentMusicVolume -= fadeSpeed;
    if (currentMusicVolume <= 0) {
      currentMusicVolume = 0;
      if (!musicEnabled && currentBgMusic.isPlaying()) {
        currentBgMusic.pause();
      }
    }
    if (currentBgMusic.isPlaying()) {
      currentBgMusic.amp(currentMusicVolume);
    }
  }
}

// Create a new method to change music based on level
void changeLevelMusic(int level) {
  // Don't change if music is disabled
  if (!musicEnabled) return;
  
  // Don't change if already changing
  if (musicChanging) return;
  
  // Create a final reference for use inside the thread
  final SoundFile newMusic;
  
  // Select the appropriate music for the level
  if (level == 1) {
    newMusic = bgMusicLevel1;
  } else {
    // Levels 2 and 3 share the same music
    newMusic = bgMusicLevel2;
  }
  
  // If we're already playing the correct music, do nothing
  if (newMusic == currentBgMusic) return;
  
  // Start music transition
  musicChanging = true;
  
  // Start fading out current music
  fadingIn = false;
  
  // Create a thread to handle the music transition
  Thread musicTransitionThread = new Thread(new Runnable() {
    public void run() {
      try {
        // Wait for current music to fade out
        while (currentMusicVolume > 0.01) {
          Thread.sleep(50);
        }
        
        // Stop current music and switch to new
        if (currentBgMusic.isPlaying()) {
          currentBgMusic.stop();
        }
        
        currentBgMusic = newMusic; // This now uses the final variable
        currentBgMusic.loop();
        currentBgMusic.amp(0);
        currentMusicVolume = 0;
        
        // Start fading in new music
        fadingIn = true;
        musicChanging = false;
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
    }
  });
  musicTransitionThread.start();
}

void handleBulletCollisions() {
  ArrayList<Bullet> bullets = character.getBullets();
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet bullet = bullets.get(i);
    boolean hitDetected = false;
    
    for (Enemy enemy : enemies) {
      if (!hitDetected && bullet.isActive() && !enemy.isDead && 
          PVector.dist(bullet.position, enemy.position) < enemy.radius + bullet.radius) {
        // Hit detected
        PVector force = PVector.sub(enemy.position, bullet.position).normalize().mult(5);
        force.y = -5; // Add upward force
        enemy.applyForce(force);
        enemy.takeDamage(10);
        bullet.deactivate();
        bullets.remove(i);
        hitDetected = true;
      }
    }

    if (!hitDetected && bossDemon != null && !bossDemon.isDead && // Check boss exists and alive
        PVector.dist(bullet.position, bossDemon.position) < bossDemon.radius + bullet.radius) {
       println("Boss Hit by Bullet!");
       PVector force = PVector.sub(bossDemon.position, bullet.position).normalize().mult(3); // Less knockback for boss
       force.y = -3;
       bossDemon.applyForce(force);
       bossDemon.takeDamage(10); // Boss damage from bullets
       bullet.deactivate();
       bullets.remove(i);
       hitDetected = true;
    }
  }
}

void handleAttackCollisions() {
  if (character.isAttacking() && character.isAttackCollisionFrame()) {
    for (Enemy enemy : enemies) {
      if (!enemy.isDead && character.isInAttackRange(enemy)) {
        if (!attackLanded) {
          PVector force = PVector.sub(enemy.position, character.position).normalize().mult(10);
          force.y = -10; // Add upward force
          enemy.applyForce(force);
          enemy.takeDamage(20);
          attackLanded = true;
        }
      }
    }
    if (bossDemon != null && !bossDemon.isDead && character.isInAttackRange(bossDemon)) { // Use Character's range check vs Boss
          println("Boss Hit by Melee!");
          PVector force = PVector.sub(bossDemon.position, character.position).normalize().mult(5); // Less knockback
          force.y = -5;
          bossDemon.applyForce(force);
          bossDemon.takeDamage(15); // Boss melee damage taken 
          attackLanded = true;
      }
  } else {
    attackLanded = false;
  }
}

void handleEnemyAttacks() {
  for (Enemy enemy : enemies) {
    if (enemy.isAttacking() && enemy.isInAttackRange(character) && 
        enemy.isInAttackCollisionFrame() && !character.isDead) {
      
      // Apply knockback force
      PVector force = PVector.sub(character.position, enemy.position).normalize().mult(10);
      force.y = -10;
      character.applyForce(force);
      
      // Base damage value
      int baseDamage = 10;
      
      // Scale damage based on difficulty if difficultyManager exists
      int scaledDamage = baseDamage;
      if (difficultyManager != null) {
        scaledDamage = difficultyManager.getScaledEnemyDamage(baseDamage);
        println("Scaled damage: " + scaledDamage);
      }
      
      // Apply the scaled damage to the character
      character.takeDamage(scaledDamage);
    }
  }
  if (bossDemon != null && !bossDemon.isDead && bossDemon.isAttacking() && // Check boss state
        bossDemon.isInAttackRange(character) && // Use boss's range check method
        bossDemon.isInAttackCollisionFrame()) { // Use boss's collision frame check

         println("Player Hit by Boss!");
         PVector force = PVector.sub(character.position, bossDemon.position).normalize().mult(15); // Stronger knockback
         force.y = -15;
         character.applyForce(force);

         int bossBaseDamage = 15; // Boss deals more damage
         int scaledBossDamage = bossBaseDamage;
         // Apply difficulty scaling for boss
         if (difficultyManager != null) { scaledBossDamage = difficultyManager.getScaledEnemyDamage(bossBaseDamage); }
         character.takeDamage(scaledBossDamage);
    }
}

void handlePlatformCollisions() {
  // Get character's position 
  float characterFeetY = character.position.y + character.radius;
  float characterLeftX = character.position.x - character.radius * 0.8;
  float characterRightX = character.position.x + character.radius * 0.8;
  
  boolean wasOnPlatform = false;
  
  // First check if character is on the  ground
  if (character.position.y >= height - 30) {
    // character.position.y = height - 30 - character.radius;
    character.velocity.y = 0;
    character.fallingDown = false;
    character.jumpStartY = character.position.y;
    wasOnPlatform = true;
  } else {
    // Check platforms
    for (PlatformObject platform : platforms) {
      // Calculate platform bounds based on image dimensions
      float platformWidth = platform.platformImage.width;
      float platformHeight = platform.platformImage.height;
      float platformTopY = platform.position.y - platformHeight/2;
      float platformLeftX = platform.position.x - platformWidth/2;
      float platformRightX = platform.position.x + platformWidth/2;
      
      // Check horizontal overlap
      boolean horizontalOverlap = characterRightX > platformLeftX && characterLeftX < platformRightX;
      
      if (horizontalOverlap) {
        // Check if character is near the top of the platform and falling
        boolean isFallingOntoTop = character.velocity.y >= 0 && 
                                characterFeetY >= platformTopY && 
                                characterFeetY <= platformTopY + 15;
        
        if (isFallingOntoTop) {
          // Place character on top of platform
          character.position.y = platformTopY - character.radius;
          character.velocity.y = 0;
          character.fallingDown = false;
          character.jumpStartY = character.position.y;
          wasOnPlatform = true;
          break;
        }
      }
    }
  }
  
  // Always set falling state if not on platform and not jumping
  if (!wasOnPlatform && !character.jumpingUp) {
    character.fallingDown = true;
    
    // Apply gravity immediately when falling off platform edge
    if (character.velocity.y == 0) {
      character.velocity.y = 0.1; // Small initial downward velocity
    }
  }
}

void handleEnemyPlatformCollisions() {
  float groundLevel = height;
  
  for (Enemy enemy : enemies) {
    if (enemy.isDead) continue;
    
    float enemyFeetY = enemy.position.y + enemy.radius - 5;
    boolean onSomething = false;
    
    // Check if enemy is on the ground
    if (enemyFeetY >= groundLevel) {
      enemy.position.y = groundLevel - enemy.radius;
      enemy.velocity.y = 0;
      onSomething = true;
    } 
    // Only check platforms if enemy is above ground level
    else {
      // Check if enemy is on any platform
      for (PlatformObject platform : platforms) {
        float platformWidth = platform.platformImage.width;
        float platformHeight = platform.platformImage.height;
        float platformTopY = platform.position.y - platformHeight/2;
        float platformLeftX = platform.position.x - platformWidth/2;
        float platformRightX = platform.position.x + platformWidth/2;
        
        // Check if enemy is horizontally within platform bounds
        if (enemy.position.x + enemy.radius * 0.8 >= platformLeftX && 
            enemy.position.x - enemy.radius * 0.8 <= platformRightX) {
          
          // Check if enemy is on this platform (feet at platform level)
          if (Math.abs(enemyFeetY - platformTopY) < 5) {
            enemy.position.y = platformTopY - enemy.radius;
            enemy.velocity.y = 0;
            onSomething = true;
            break;
          }
        }
      }
    }
    
    // If enemy is not on ground or any platform, ensure they fall
    if (!onSomething && enemy.velocity.y <= 0) {
      enemy.velocity.y = 0.1; // Start falling if not already falling
    }
  }
  
  // Handle Boss Demon platform collisions
  if (bossDemon != null && !bossDemon.isDead) {

    float groundLevelBoss = height - 30;

    if (bossDemon.radius <= 0) {
       bossDemon.radius = 30; 
    }
    float bossFeetY = bossDemon.position.y + bossDemon.radius;
    boolean bossOnSomething = false;

    // Check if boss is on the ground
    if (bossFeetY >= groundLevelBoss - 5) { 
      bossDemon.position.y = groundLevelBoss - bossDemon.radius; // Set position precisely above ground
      if (bossDemon.velocity.y > 0) { // Only stop downward velocity
         bossDemon.velocity.y = 0;
      }
      bossOnSomething = true;
    }

    // Only check platforms if boss is above ground level
    if (!bossOnSomething) { 
      // Check if boss is on any platform
      for (PlatformObject platform : platforms) {
        float platformWidth = platform.platformImage.width;
        float platformHeight = platform.platformImage.height;
        float platformTopY = platform.position.y - platformHeight/2;
        float platformLeftX = platform.position.x - platformWidth/2;
        float platformRightX = platform.position.x + platformWidth/2;

        // Check horizontal overlap (using boss radius for approximation)
        boolean horizontalOverlap = (bossDemon.position.x + bossDemon.radius * 0.8f > platformLeftX) &&
                                    (bossDemon.position.x - bossDemon.radius * 0.8f < platformRightX);

        if (horizontalOverlap) {
          // Check if boss is near the top of the platform and falling/stable
          boolean isFallingOntoTop = bossDemon.velocity.y >= -0.1f && // Allow for slight upward velocity if just landed
                                     bossFeetY >= platformTopY - 5 && // Feet are near or slightly below platform top
                                     bossFeetY <= platformTopY + 15; // Feet are not too far below platform top

          if (isFallingOntoTop) {
            // Place boss on top of platform
            bossDemon.position.y = platformTopY - bossDemon.radius;
            if (bossDemon.velocity.y > 0) { // Only stop downward velocity
              bossDemon.velocity.y = 0;
            }
            bossOnSomething = true;
            break; // Exit platform loop once landed on one
          }
        }
      }
    }

    // If boss is not on ground or any platform, ensure it falls
    if (!bossOnSomething && bossDemon.velocity.y <= 0) { // Check if not moving down or moving up
       // Only apply downward velocity if it's not already falling significantly
       if(bossDemon.velocity.y > -0.1) { // Avoid overriding upward bounces immediately
          bossDemon.velocity.y = 0.1f; // Start falling gently
       }
    }
  }
}

void checkSprings() {
  for (Spring spring : springs) {
    // Calculate distance between character's feet and spring's top surface
    float characterFeetY = character.position.y + character.getRadius();
    float springTopY = spring.position.y - spring.platformImage.height/2;
    
    // collision check
    boolean isAboveSpring = abs(character.position.x - spring.position.x) < spring.platformImage.width/2 * 0.7f;
    boolean isTouchingSpring = characterFeetY >= springTopY - 10 && characterFeetY <= springTopY + 10;
    boolean isFalling = character.velocity.y > 1.0;
    
    if (isAboveSpring && isTouchingSpring && isFalling) {
      character.position.y = springTopY - character.getRadius();
      
      if (spring.compress()) {
        // Clear any accumulated forces that might counteract the bounce
        character.clearForces();
        
        // Apply upward velocity
        character.velocity.y = -spring.getBounceForce();
        
        // Add a horizontal boost in the direction the character is moving
        if (character.velocity.x != 0) {
          character.velocity.x *= 1.3; // Increase horizontal momentum by 30%
        }
        
        // Set spring bounce state
        character.setSpringBounce(true);
        character.jumpingUp = true;
        character.fallingDown = false;
        character.jumpStartY = character.position.y;

        // visual effect for jump
        pushStyle();
        fill(255, 255, 0, 150); 
        noStroke();
        ellipse(spring.position.x, spring.position.y, 100, 50); 
        
        // particles
        for (int i = 0; i < 10; i++) {
          float particleX = spring.position.x + random(-40, 40);
          float particleY = spring.position.y + random(-10, 10);
          fill(255, random(200, 255), 0, 200);
          ellipse(particleX, particleY, random(5, 15), random(5, 15));
        }
        popStyle();
      }
    }
  }
}

void drawGameObjects() {
  // Draw platforms
  for (PlatformObject platform : platforms) {
    platform.draw();
  }
  
  // Draw springs
  for (Spring spring : springs) {
    spring.draw();
  }
  
  // Draw coins
  for (Coin coin : coins) {
    coin.draw();
  }
  
  // Draw health packs
  for (HealthPack health : healthPacks) {
    health.draw();
  }
  
  // Draw character
  character.draw();
  
  // Draw enemies
  for (Enemy enemy : enemies) {
    enemy.draw();
  }

  if (bossDemon != null) { // Check if null
      bossDemon.draw();
  }

  // Draw ammo pickups
  for (Ammo ammo : ammoPickups) {
    ammo.draw();
  }

  // Draw the appropriate level exit based on current level
  if (currentLevel == 1 && levelExit != null) {
    levelExit.draw();
  } else if (currentLevel == 2 && level2Exit != null) {
    level2Exit.draw();
  }

  // Draw spawn effects if we're in level 2
  if (currentLevel == 2 && enemySpawner != null) {
    enemySpawner.drawEffects();
  }
}

void displayHUD() {
  // Health display
  fill(255);
  textSize(20);
  text("Health: " + character.getHealth(), 50, 50);

  // Ammo count display with icon
  textSize(20);
  fill(255, 255, 0); // Yellow text for ammo
  text("Ammo: " + character.getAmmoCount(), 50, 110);  // Display under health/time
  
  // Enemy health display
  for (int i = 0; i < enemies.size(); i++) {
    if (!enemies.get(i).isDead) {
      fill(255, 0, 0); // Red for alive enemies
      text("Enemy " + (i+1) + ": " + enemies.get(i).getHealth(), width - 170, 50 + i * 30);
    } else {
      fill(0, 255, 0); // Green for defeated enemies
      text("Enemy " + (i+1) + ": Defeated", width - 170, 50 + i * 30);
    }
  }
  
  // Display enemies defeated counter
  int defeatedCount = 0;
  for (Enemy enemy : enemies) {
    if (enemy.isDead) defeatedCount++;
  }
  
  fill(255, 215, 0); // Gold color
  text("Enemies Defeated: " + defeatedCount + "/" + enemies.size(), width/2 - 100, 50);
  
  // Stopwatch display
  fill(255);
  if (timerRunning) {
    long currentTime = millis();
    long elapsedTime = currentTime - gameStartTime;
    text("Time: " + formatTime(elapsedTime), 50, 80);
  } else if (gameEndTime > 0) {
    // Display final time after victory
    long elapsedTime = gameEndTime - gameStartTime;
    text("Time: " + formatTime(elapsedTime), 50, 80);
  }

  // <<< Boss Health Display >>>
  if (currentLevel == 3 && bossDemon != null) { // Check level and boss exists
      pushStyle();
      rectMode(CORNER); // CORNER for drawing bars
      float maxBossHealth = 500.0f; // Store max health
      float bossHealthPercentage = max(0, (float)bossDemon.getHealth() / maxBossHealth); // Ensure >= 0

      float barWidth = width * 0.6f; // Boss health bar wide
      float barHeight = 20;
      float barX = (width - barWidth) / 2; // Centered horizontally
      float barY = 30; // Near top of screen

      // Background
      fill(50, 50, 50, 200); // Semi-transparent dark grey
      noStroke();
      rect(barX, barY, barWidth, barHeight, 3); // Slight rounding

      // Foreground (Current Health)
      color healthColor = lerpColor(color(200, 0, 0), color(0, 200, 0), bossHealthPercentage * bossHealthPercentage); // Skew towards red faster
      fill(healthColor);
      rect(barX, barY, barWidth * bossHealthPercentage, barHeight, 3);

      rectMode(CENTER); // Reset rectMode
      textAlign(LEFT, BASELINE); // Reset alignment
      popStyle();
  }
  
  // Game over message 
  if (gameOver) {
    displayGameOver();
  }
  
  // Show level intro if we just changed levels
  displayLevelIntro();
  }

// format milliseconds as mm:ss.ms
String formatTime(long millis) {
  int seconds = (int) (millis / 1000) % 60;
  int minutes = (int) (millis / (1000 * 60));
  int ms = (int) (millis % 1000) / 10; // Show only 2 digits for milliseconds
  
  return String.format("%02d:%02d.%02d", minutes, seconds, ms);
}

void displayStartScreen() {
  fill(0, 0, 0, 150);
  rect(0, 0, width, height);
  
  // Game title
  fill(255);
  textSize(80);
  textAlign(CENTER, CENTER);
  text("OVER S∞∞N", width/2, height/3 - 40);
  
  if (!showDifficultySelection) {
    // Controls section
    textSize(30);
    text("CONTROLS", width/2, height/2 - 60);
    
    textSize(24);
    int yPos = height/2;
    text("A / D - Move left / right", width/2, yPos);
    text("W - Jump", width/2, yPos + 35);
    text("SPACE - Attack", width/2, yPos + 70);
    text("SHIFT - Glide", width/2, yPos + 105);
    text("M - Toggle music", width/2, yPos + 140);
    
    // Start prompt
    textSize(30);
    fill(255, 255, 0);
    text("Press ENTER to select difficulty", width/2, height - 100);
  } else {
    // Difficulty selection screen
    textSize(40);
    fill(255);
    text("SELECT DIFFICULTY", width/2, height/2 - 100);
    
    // Draw difficulty options
    for (int i = 0; i < difficultyNames.length; i++) {
      int diffLevel = i + 1;
      float yPos = height/2 - 20 + (i * 50);
      
      // Highlight selected difficulty
      if (diffLevel == selectedDifficulty) {
        fill(255, 215, 0); // Gold for selected
        rect(width/2 - 150, yPos - 20, 300, 40, 5);
      }
      
      fill(diffLevel == selectedDifficulty ? 0 : 255); // Black text on gold, white otherwise
      textSize(24);
      text(diffLevel + ": " + difficultyNames[i], width/2, yPos);
    }
    
    // Instructions
    fill(255);
    textSize(20);
    text("Use UP/DOWN arrows to select, ENTER to confirm", width/2, height/2 + 250);
  }
  
  // Reset text alignment
  textAlign(LEFT, BASELINE);
}

void displayGameOver() {
  fill(0, 0, 0, 150);
  rect(0, 0, width, height);
  
  // Set text alignment once for all text
  textAlign(CENTER, CENTER);
  
  // Check if player died or if they won
  boolean playerDied = character.isDead;
  
  if (playerDied) {
    // Game over text - defeat
    fill(255, 0, 0);
    textSize(80);
    text("GAME OVER", width/2, height/2 - 40);
  }
  // If player isn't dead, check for victory conditions
  else if (currentLevel == 3 && bossDemon != null && bossDemon.isDead) {
      // Boss Victory Message
      fill(255, 215, 0); // Gold color
      textSize(80);
      text("VICTORY!", width/2, height/2 - 60);

      fill(255);
      textSize(30);
      text("The Demon Lord lies defeated!", width/2, height/2); // Boss specific text

      // Show the final time
      textSize(24);
      if (gameEndTime > 0) { // Make sure timer stopped
           text("Your time: " + formatTime(gameEndTime - gameStartTime), width/2, height/2 + 50);
      }
  } 
  else {
    // Regular victory text - all enemies defeated and coin collected
    fill(255, 215, 0); // Gold color
    textSize(80);
    text("VICTORY!", width/2, height/2 - 40);
    
    fill(255);
    textSize(30);
    text("You defeated all enemies and reached the summit!", width/2, height/2 + 10);
    
    // Show the final time
    textSize(24);
    text("Your time: " + formatTime(gameEndTime - gameStartTime), width/2, height/2 + 50);
  }
  
  // Instructions to restart
  fill(255);
  textSize(30);
  text("Press 'R' to restart", width/2, height/2 + 100);
  
  // Reset text alignment to default for the rest of the game
  textAlign(LEFT, BASELINE);
}

void resetGame() {
  // Reset game state
  gameOver = false;
  attackLanded = false;
  
  // Reset level
  currentLevel = 1;
  inLevelTransition = false;
  
  // Reset timer
  gameStartTime = millis();
  gameEndTime = 0;
  timerRunning = true;
  
  // Clear all collections
  physicsEngine = new PhysicsEngine();
  enemies.clear();
  springs.clear();
  platforms.clear();
  coins.clear();
  ammoPickups.clear();
  healthPacks.clear();
  bossDemon = null; // Reset boss
  
  // Recreate character
  character = new Character(new PVector(width / 2, height - 30));
  
  // Reset victory sequence flags
  victoryPending = false;
  bossDeathTime = 0;
  
  // Reset menu state
  gameStarted = false;
  showDifficultySelection = false;
  
  initializeLevel();
  
  // Reset camera position and transition values
  cameraPosition = new PVector(0, 0);
  currentCamera = 1; // Default back to camera 1
  currentCameraZoom = 1.0f;
  targetCameraZoom = 1.0f;

  // Reset music to level 1
  changeLevelMusic(1);

  // If music was disabled, keep it that way
  if (musicEnabled && !currentBgMusic.isPlaying()) {
    currentBgMusic.loop();
    fadingIn = true;
    currentMusicVolume = 0;
    currentBgMusic.amp(0);
  }
}

// Update the updateCoins method to stop the timer when the player wins
void updateCoins() {
  // Update all coins
  for (int i = coins.size() - 1; i >= 0; i--) {
    Coin coin = coins.get(i);
    coin.update();
    
    // Check for collision with player if not already collected
    if (!coin.isCollected() && !gameOver) {
      // distance-based collision check
      float distance = PVector.dist(character.position, coin.position);
      if (distance < character.radius + coin.radius) {
        // Check if all enemies are defeated
        boolean allEnemiesDefeated = true;
        for (Enemy enemy : enemies) {
          if (!enemy.isDead) {
            allEnemiesDefeated = false;
            break;
          }
        }
        
        if (allEnemiesDefeated) {
          // All enemies are defeated, allow coin collection
          coin.collect();
          
          // Activate the level exit
          if (levelExit != null) {
            levelExit.activate(); // This will now set a flag instead of using a thread
          }
          
          // Add victory visual effect
          pushStyle();
          fill(255, 255, 0, 100);
          ellipse(coin.position.x, coin.position.y, 200, 200);
          popStyle();
        } else {
          // Not all enemies defeated, show a message
          pushStyle();
          fill(255, 0, 0, 150);
          textSize(20);
          textAlign(CENTER, CENTER);
          text("Defeat all enemies first!", width/2, height/2 - 100);
          popStyle();
        }
      }
    }
  }
}

void updateHealthPacks() {
  // Update all health packs
  for (int i = healthPacks.size() - 1; i >= 0; i--) {
    HealthPack healthPack = healthPacks.get(i);
    healthPack.update();
    
    // Check for collision with player if not already collected
    if (!healthPack.isCollected() && !gameOver) {
      // distance-based collision check
      float distance = PVector.dist(character.position, healthPack.position);
      if (distance < character.radius + healthPack.getRadius()) {
        // Only collect if player doesn't have full health
        if (character.getHealth() < 100) {
          // Collect the health pack and heal the player
          healthPack.collect();
          character.heal(25); // Heal by 25 health points
          
          // Add collection visual effect
          pushStyle();
          fill(0, 255, 0, 100);
          ellipse(healthPack.position.x, healthPack.position.y, 100, 100);
          popStyle();
        }
      }
    }
    
    // Check if it's time to remove collected health pack
    if (healthPack.isCollected() && millis() > healthPack.collectionTime + 1000) {
      healthPacks.remove(i);
    }
  }
}

// handle ammo pickup collection:
void updateAmmoPickups() {
  // Update all ammo pickups
  for (int i = ammoPickups.size() - 1; i >= 0; i--) {
    Ammo ammo = ammoPickups.get(i);
    ammo.update();
    
    // Check for collection
    if (!ammo.isCollected() && !gameOver) {
      float distance = PVector.dist(character.position, ammo.position);
      if (distance < character.radius + ammo.getRadius()) {
        // Collect the ammo and add to player's ammo count
        ammo.collect();
        character.addAmmo(5); // Add 5 shots to player's ammo
        
        // Add collection visual effect
        pushStyle();
        fill(255, 255, 0, 100);
        ellipse(ammo.position.x, ammo.position.y, 100, 100);
        popStyle();
      }
    }
    
    // Check if it's time to remove collected ammo
    if (ammo.isCollected() && millis() > ammo.collectionTime + 1000) {
      ammoPickups.remove(i);
    }
  }
}

// Reset player for new level
void resetPlayerForLevel(int level) {
  // Reset player position based on level
  if (level == 1) {
    character.position = new PVector(width / 2, height - 30);
  } else if (level == 2) {
    character.position = new PVector(width * 0.2f, height - 30);
  } else if (level == 3) {
    character.position = new PVector(width * 0.2f, height - 30);
  }
  
  // Reset player velocity
  character.velocity = new PVector(0, 0);
  
  // Make sure player is not in any special states
  character.jumpingUp = false;
  character.fallingDown = false;
}

// Display a level intro
void displayLevelIntro() {
  // Only show for a few seconds after level change
  long currentTime = millis();
  if (currentTime - gameStartTime < 2000) {
    pushStyle();
    
    // Semi-transparent background
    fill(0, 0, 0, 150);
    rect(0, 0, width, height);
    
    // Level title
    textAlign(CENTER, CENTER);
    textSize(60);
    fill(255, 215, 0);
    text("LEVEL " + currentLevel, width/2, height/2 - 40);
    
    // Level description
    textSize(24);
    fill(255);
    if (currentLevel == 1) {
      text("Training Grounds", width/2, height/2 + 20);
      text("Defeat enemies and find the exit", width/2, height/2 + 60);
    } else if (currentLevel == 2) {
      text("Mountain Path", width/2, height/2 + 20);
      text("Survive the journey ahead", width/2, height/2 + 60);
    } else if (currentLevel == 3) {
      text("Final Challenge", width/2, height/2 + 20);
      text("Face the ultimate boss", width/2, height/2 + 60);
    }
    
    popStyle();
  }
}

// Add this method to P1.pde
void handleCameraFocusAnimation() {
  if (cameraFocusOnExit && levelExit != null) {
    long currentTime = millis();
    long elapsedTime = currentTime - cameraFocusStartTime;
    
    // Reduced animation duration for a quicker, less intrusive effect
    final long CAMERA_FOCUS_DURATION = 2000; // 2 seconds instead of 3
    
    if (elapsedTime < CAMERA_FOCUS_DURATION) {
      // Determine which phase of the animation we're in
      float phase = elapsedTime / (float) CAMERA_FOCUS_DURATION;
      
      // Save camera state if we're just starting
      if (phase < 0.01) {
        savedCameraMode = currentCamera;
        savedCameraPosition = cameraPosition.copy();
        savedCameraZoom = currentCameraZoom;
        currentCamera = 3; // Special camera mode for animation
      }
      
      // Use a single smooth curve for the entire animation instead of distinct phases
      float animationProgress = easeInOutQuad(phase);
      
      // First half: subtle zoom in to exit
      if (phase < 0.5) {
        float zoomProgress = map(phase, 0, 0.5f, 0, 1);
        zoomProgress = easeInOutQuad(zoomProgress);
        
        // Much more subtle zoom (1.2f instead of 2.5f)
        float maxZoom = 1.2f;
        
        // Gentler camera movement - reduced multiplier for position
        PVector targetPosition = new PVector(
          width/2 - levelExit.position.x * 1.2f, // Reduced from 2.5f
          height/2 - levelExit.position.y * 1.2f  // Reduced from 2.5f
        );
        
        cameraPosition.x = lerp(savedCameraPosition.x, targetPosition.x, zoomProgress);
        cameraPosition.y = lerp(savedCameraPosition.y, targetPosition.y, zoomProgress);
        currentCameraZoom = lerp(savedCameraZoom, maxZoom, zoomProgress);
      }
      // Second half: smoothly return to normal
      else {
        float returnProgress = map(phase, 0.5f, 1.0f, 0, 1);
        returnProgress = easeInOutQuad(returnProgress);
        
        // Restore saved camera position and mode
        PVector targetPosition = (savedCameraMode == 2) ? 
          calculatePlayerCameraPosition() : savedCameraPosition;
        
        cameraPosition.x = lerp(cameraPosition.x, targetPosition.x, returnProgress);
        cameraPosition.y = lerp(cameraPosition.y, targetPosition.y, returnProgress);
        currentCameraZoom = lerp(currentCameraZoom, savedCameraZoom, returnProgress);
        
        // If we're at the end, restore the camera mode
        if (phase > 0.99) {
          currentCamera = savedCameraMode;
          cameraFocusOnExit = false;
        }
      }
    }
    else {
      // Animation complete
      currentCamera = savedCameraMode;
      cameraFocusOnExit = false;
    }
  }
}

// Helper method to calculate player camera position (for when returning to player-following camera)
PVector calculatePlayerCameraPosition() {
  if (character != null) {
    float visibleWidth = width / cameraZoom;
    float visibleHeight = height / cameraZoom;
    
    float marginX = visibleWidth / 2;
    float marginY = visibleHeight / 2;
    
    float boundedPlayerX = constrain(character.position.x, marginX, width - marginX);
    float boundedPlayerY = constrain(character.position.y, marginY, height - marginY);
    
    return new PVector(
      width/2 - boundedPlayerX * cameraZoom,
      height/2 - boundedPlayerY * cameraZoom
    );
  }
  return new PVector(0, 0);
}

// Easing function for smooth animation
float easeInOutQuad(float t) {
  return t < 0.5f ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2;
}

// Add this method to check for pending activation
void checkPendingExitActivation() {
  if (pendingExitActivation && millis() > exitActivationTime + EXIT_ACTIVATION_DELAY) {
    // Trigger camera animation after delay
    cameraFocusOnExit = true;
    cameraFocusStartTime = millis();
    pendingExitActivation = false;
  }
}

// Add this method to change difficulty during gameplay
void setGameDifficulty(int level) {
  currentDifficulty = constrain(level, 1, 5);
  
  if (difficultyManager != null) {
    difficultyManager.setDifficultyLevel(currentDifficulty);
    
    // Update the enemy spawner with the new difficulty
    if (enemySpawner != null) {
      enemySpawner.setDifficulty(currentDifficulty);
    }
    
    println("Game difficulty set to " + currentDifficulty + 
            " (" + difficultyManager.getDifficultyName() + ")");
  }
}