class Background {
  PImage treesImg;
  PImage mountainsImg;
  PImage frontMountainsImg; 
  PImage moonImg;
  PImage waterfallSpritesheet;
  PImage[] waterfallFrames;
  float waterfallCurrentFrame = 0.0f;
  final float WATERFALL_ANIM_SPEED = 0.15f;
  
  // Stars variables
  int numStars = 200;
  PVector[] starPositions;
  float[] starSizes;
  float[] starBrightness;
  float starTwinkleSpeed = 0.02;
  
  Background(String treesPath) {
    treesImg = loadImage(treesPath);
    // Load the mountain background image
    mountainsImg = loadImage("PixelArt_Samurai/Environment/PNG/Environment_Back_Mountain.png");
    // Load the front mountains image
    frontMountainsImg = loadImage("PixelArt_Samurai/Environment/PNG/Environment_Front_Mountains.png");
    // Load the moon image from CharacterPack directory
    moonImg = loadImage("CharacterPack/Enviro/Moons/moon_01.png");
    
    // Load the waterfall spritesheet
    waterfallSpritesheet = loadImage("PixelArt_Samurai/Environment/PNG/Environment_Waterfall.png");
    
    // Set up waterfall animation frames by extracting from spritesheet
    extractWaterfallFrames();
    
    // Initialize stars
    setupStars();
  }
  
  void setupStars() {
    starPositions = new PVector[numStars];
    starSizes = new float[numStars];
    starBrightness = new float[numStars];
    
    for (int i = 0; i < numStars; i++) {
      // Position stars randomly across the sky
      starPositions[i] = new PVector(
        random(width), 
        random(height * 0.7) // Keep stars in upper 70% of screen
      );
      
      // Random star sizes
      starSizes[i] = random(1, 3);
      
      // Random initial brightness values
      starBrightness[i] = random(150, 255);
    }
  }
  
  void extractWaterfallFrames() {
    int frameCount = 8;
    waterfallFrames = new PImage[frameCount];
    
    // Calculate the width of each frame
    int frameWidth = waterfallSpritesheet.width / frameCount;
    int frameHeight = waterfallSpritesheet.height;
    
    // Extract each frame
    for (int i = 0; i < frameCount; i++) {
      waterfallFrames[i] = waterfallSpritesheet.get(i * frameWidth, 0, frameWidth, frameHeight);
    }
  }

  void display() {
    // Draw gradient night sky background
    pushStyle();
    // Create a dark blue to black gradient for the night sky
    for (int y = 0; y < height; y++) {
      float inter = map(y, 0, height, 0, 1);
      color c = lerpColor(color(5, 10, 50), color(0, 0, 15), inter);
      stroke(c);
      line(0, y, width, y);
    }
    popStyle();
    
    // Draw stars
    drawStars();
    
    // Draw the moon in the top right portion of the sky
    float moonScale = 1;
    image(moonImg, width * 0.8, height * 0.2, 
          moonImg.width * moonScale, moonImg.height * moonScale);
    
    // Draw mountains in the background
    float mountainScale = 2.0;  
    float mountainY = height - mountainsImg.height * mountainScale * 0.6;  // Position mountains higher in the background
    
    // Draw mountains across the screen
    for (int x = 0; x < width; x += mountainsImg.width * mountainScale) {
      image(mountainsImg, x + mountainsImg.width * mountainScale / 2, mountainY, 
            mountainsImg.width * mountainScale, mountainsImg.height * mountainScale);
    }
    
    // Draw front mountains at the left edge
    float frontMountainScale = 1.5;
    float frontMountainY = height - frontMountainsImg.height * frontMountainScale * 0.9;
    
    pushStyle();
    imageMode(CORNER);
    image(frontMountainsImg, 
          -frontMountainsImg.width * frontMountainScale * 0.1, // Slightly offset from left edge
          frontMountainY,
          frontMountainsImg.width * frontMountainScale,
          frontMountainsImg.height * frontMountainScale);
    popStyle();
    
    // Draw trees across the entire screen 
    boolean flip = false;
    for (int x = 0; x < width; x += treesImg.width) {
      pushMatrix();
      if (flip) {
        scale(-1, 1);
        image(treesImg, -x - treesImg.width / 2, height - treesImg.height / 2);
      } else {
        image(treesImg, x + treesImg.width / 2, height - treesImg.height / 2);
      }
      popMatrix();
      flip = !flip;
    }

    // Draw animated waterfall at the right edge of the screen
    drawWaterfall();
  }
  
  void drawStars() {
    pushStyle();
    noStroke();
    
    for (int i = 0; i < numStars; i++) {
      // Make stars twinkle by varying brightness
      starBrightness[i] += sin(frameCount * starTwinkleSpeed + i) * 3;
      starBrightness[i] = constrain(starBrightness[i], 100, 255);
      
      // Draw the star
      fill(255, 255, 255, starBrightness[i]);
      
      // Occasionally draw a larger star with a glow effect
      if (i % 15 == 0) { 
        // Draw glow
        for (int j = 3; j > 0; j--) {
          fill(255, 255, 255, starBrightness[i] / (j*2));
          circle(starPositions[i].x, starPositions[i].y, starSizes[i] * j);
        }
        // Draw center
        fill(255, 255, 255, starBrightness[i]);
        circle(starPositions[i].x, starPositions[i].y, starSizes[i]);
      } else {
        // Draw regular star
        circle(starPositions[i].x, starPositions[i].y, starSizes[i]);
      }
    }
    popStyle();
  }
  
  void drawWaterfall() {
    // Update animation frame
    waterfallCurrentFrame += WATERFALL_ANIM_SPEED;
    if (waterfallCurrentFrame >= waterfallFrames.length) {
      waterfallCurrentFrame = 0;
    }
    
    // Get current frame
    int frameIndex = (int)waterfallCurrentFrame;
    PImage currentFrame = waterfallFrames[frameIndex];
    
    // Scale waterfall to appropriate size
    float waterfallScale = 1.5;
    
    // Position waterfall at the right edge of the screen
    pushStyle();
    imageMode(CORNER);
    
    // Calculate position to have waterfall start from above the mountains and reach the ground
    float waterfallX = width - currentFrame.width * waterfallScale;
    float waterfallY = height - currentFrame.height * waterfallScale - 50;  // Start higher than ground level
    
    // Draw the waterfall
    image(currentFrame, waterfallX, waterfallY, 
          currentFrame.width * waterfallScale, 
          currentFrame.height * waterfallScale * 1.2);  // Stretch vertically a bit
    
    popStyle();
    
    // Add mist/splash effect at the bottom of the waterfall
    pushStyle();
    noStroke();
    fill(255, 255, 255, 60);
    ellipse(waterfallX + currentFrame.width * waterfallScale / 2, 
            height - 15, 
            currentFrame.width * waterfallScale * 1.2, 30);
    popStyle();
  }
}