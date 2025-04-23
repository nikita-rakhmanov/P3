import processing.sound.*;

Background bg;
Character character;
Platform ground;
ArrayList<Enemy> enemies = new ArrayList<Enemy>();
ArrayList<Spring> springs = new ArrayList<Spring>();
ArrayList<PlatformObject> platforms = new ArrayList<PlatformObject>();
ArrayList<Coin> coins = new ArrayList<Coin>();
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
SoundFile bgMusic;
boolean musicEnabled = true;
float musicVolume = 0.4f; 
float currentMusicVolume = 0.0f; 
float fadeSpeed = 0.001f; 
boolean fadingIn = true; 

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

  // Load and start background music
  bgMusic = new SoundFile(this, "music/bg_song.mp3");
  bgMusic.loop();
  bgMusic.amp(0); // Start with volume at 0 for fade in
  currentMusicVolume = 0.0f;
  fadingIn = true;

  // physics engine
  physicsEngine = new PhysicsEngine();

  // Load background and ground
  bg = new Background("CharacterPack/Enviro/BG/trees_bg.png");
  ground = new Platform("CharacterPack/GPE/platforms/platform_through.png");
  
  // Create character in the middle
  character = new Character(new PVector(width / 2, height - 30));
  
  // Create enemies on both sides with FSM-based behaviors, including enemy type
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

  float platformWidth = 32; // width of platform_through.png
    
  // Create platforms for vertical traversal 
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
  
  // Add a coin on the top platform
  coins.add(new Coin(new PVector(width * 0.5f, height - 510 - 10))); 

  // Setup pathfinding
  setupPathfinding();
  
  // Add objects to physics engine
  physicsEngine.addObject(character);
  for (Enemy enemy : enemies) {
    physicsEngine.addObject(enemy);
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
    if (key == ENTER || key == RETURN) {
      gameStarted = true;
      // Start the timer when the game begins
      gameStartTime = millis();
      timerRunning = true;
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
      if (!bgMusic.isPlaying()) {
        bgMusic.loop();  // Use loop() instead of play()
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
    
    // Update and check coins 
    updateCoins();
    
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
  
  // Draw all game objects
  drawGameObjects();
  
  // Pop the matrix to restore default transformation for HUD drawing
  popMatrix();
  
  // Draw HUD (in screen space)
  displayHUD();
  
  // Show camera and music info
  fill(255);
  textSize(16);
  textAlign(LEFT);
  text("Camera: " + (currentCamera == 1 ? "Default" : "Follow Player") + " ('1' or '2' to change)", 50, height - 650);
  text("Music: " + (musicEnabled ? "ON" : "OFF") + " (Press 'M' to toggle)", 50, height - 620);
}

// Function to handle music fade in/out
void updateMusicFade() {
  if (fadingIn && musicEnabled) {
    // Fade in
    currentMusicVolume += fadeSpeed;
    if (currentMusicVolume >= musicVolume) {
      currentMusicVolume = musicVolume;
      fadingIn = false;
    }
    bgMusic.amp(currentMusicVolume);
  } else if (!fadingIn && !musicEnabled) {
    // Fade out
    currentMusicVolume -= fadeSpeed;
    if (currentMusicVolume <= 0) {
      currentMusicVolume = 0;
      bgMusic.pause();
    }
    bgMusic.amp(currentMusicVolume);
  }
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
  } else {
    attackLanded = false;
  }
}

void handleEnemyAttacks() {
  for (Enemy enemy : enemies) {
    if (enemy.isAttacking() && enemy.isInAttackRange(character) && 
        enemy.isInAttackCollisionFrame() && !character.isDead) {
      PVector force = PVector.sub(character.position, enemy.position).normalize().mult(10);
      force.y = -10;
      character.applyForce(force);
      character.takeDamage(10);
    }
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
  
  // Draw character
  character.draw();
  
  // Draw enemies
  for (Enemy enemy : enemies) {
    enemy.draw();
  }
}

void displayHUD() {
  // Health display
  fill(255);
  textSize(20);
  text("Health: " + character.getHealth(), 50, 50);
  
  // Enemy health display
  for (int i = 0; i < enemies.size(); i++) {
    if (!enemies.get(i).isDead) {
      fill(255, 0, 0); // Red for alive enemies
      text("Enemy " + (i+1) + ": " + enemies.get(i).getHealth(), width - 200, 50 + i * 30);
    } else {
      fill(0, 255, 0); // Green for defeated enemies
      text("Enemy " + (i+1) + ": Defeated", width - 200, 50 + i * 30);
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
  
  // Game over message 
  if (gameOver) {
    displayGameOver();
  }
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
  text("Press ENTER to start", width/2, height - 100);
  
  // Reset text alignment
  textAlign(LEFT, BASELINE);
}

void displayGameOver() {
  fill(0, 0, 0, 150);
  rect(0, 0, width, height);
  
  // Check if player died or if they won
  boolean playerDied = character.isDead;
  
  if (playerDied) {
    // Game over text - defeat
    fill(255, 0, 0);
    textSize(80);
    textAlign(CENTER, CENTER);
    text("GAME OVER", width/2, height/2 - 40);
  } else {
    // Victory text - all enemies defeated and coin collected
    fill(255, 215, 0); // Gold color
    textSize(80);
    textAlign(CENTER, CENTER);
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
  
  // Reset text alignment
  textAlign(LEFT, BASELINE);
}

void resetGame() {
  // Reset game state
  gameOver = false;
  attackLanded = false;
  
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
  
  // Recreate character, enemies, platforms and springs
  character = new Character(new PVector(width / 2, height - 30));
  
  // Create enemies on both sides with FSM-based behaviors, including enemy type
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

  float platformWidth = 32;

  // Recreate platforms
  platforms.add(new PlatformObject(width * 0.25f - platformWidth, height - 150));
  platforms.add(new PlatformObject(width * 0.25f, height - 150));                 
  platforms.add(new PlatformObject(width * 0.25f + platformWidth, height - 150)); 
  
  platforms.add(new PlatformObject(width * 0.75f - platformWidth, height - 150)); 
  platforms.add(new PlatformObject(width * 0.75f, height - 150));                
  platforms.add(new PlatformObject(width * 0.75f + platformWidth, height - 150)); 
  
  platforms.add(new PlatformObject(width * 0.5f - platformWidth, height - 270)); 
  platforms.add(new PlatformObject(width * 0.5f, height - 270));                
  platforms.add(new PlatformObject(width * 0.5f + platformWidth, height - 270)); 
  
  platforms.add(new PlatformObject(width * 0.35f - platformWidth, height - 330)); 
  platforms.add(new PlatformObject(width * 0.35f, height - 330));                
  platforms.add(new PlatformObject(width * 0.35f + platformWidth, height - 330)); 
  
  platforms.add(new PlatformObject(width * 0.65f - platformWidth, height - 330));
  platforms.add(new PlatformObject(width * 0.65f, height - 330));                 
  platforms.add(new PlatformObject(width * 0.65f + platformWidth, height - 330)); 
  
  platforms.add(new PlatformObject(width * 0.5f - platformWidth, height - 410)); 
  platforms.add(new PlatformObject(width * 0.5f, height - 490));                 
  platforms.add(new PlatformObject(width * 0.5f + platformWidth, height - 410));
  
  // Recreate springs
  springs.add(new Spring(new PVector(width * 0.15f, height - 20)));
  springs.add(new Spring(new PVector(width * 0.85f, height - 20)));
  springs.add(new Spring(new PVector(width * 0.5f, height - 150)));
  
  // Recreate coins
  coins.add(new Coin(new PVector(width * 0.5f, height - 510 - 10))); 
  
  // Add objects to physics engine
  physicsEngine.addObject(character);
  for (Enemy enemy : enemies) {
    physicsEngine.addObject(enemy);
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
  
  physicsEngine.addForceGenerator(character, gravity);
  physicsEngine.addForceGenerator(character, drag);
  
  for (Enemy enemy : enemies) {
    physicsEngine.addForceGenerator(enemy, gravity);
    physicsEngine.addForceGenerator(enemy, drag);
  }
  
  // Reset camera position and transition values
  cameraPosition = new PVector(0, 0);
  currentCamera = 1; // Default back to camera 1
  currentCameraZoom = 1.0f;
  targetCameraZoom = 1.0f;

  // If music was disabled, keep it that way
  if (musicEnabled && !bgMusic.isPlaying()) {
    bgMusic.play();
    fadingIn = true;
    currentMusicVolume = 0;
    bgMusic.amp(0);
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
          
          // Stop the timer when the player wins
          if (timerRunning) {
            gameEndTime = millis();
            timerRunning = false;
          }
          
          // Add victory visual effect
          pushStyle();
          fill(255, 255, 0, 100);
          ellipse(coin.position.x, coin.position.y, 200, 200);
          popStyle();
          
          // Set game won state after a short delay to allow animation to play
          Thread coinThread = new Thread(new Runnable() {
            public void run() {
              try {
                // Wait for the coin destroy animation to finish
                Thread.sleep(1000);
                gameOver = true;
              } catch (InterruptedException e) {
                e.printStackTrace();
              }
            }
          });
          coinThread.start();
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