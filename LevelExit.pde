class LevelExit {
  private PVector position;
  private PImage[] exitFrames;
  private float currentFrame = 0.0f;
  private final float ANIMATION_SPEED = 0.15f;
  private float radius = 40.0f; // Collision radius
  private boolean active = true;
  
  LevelExit(PVector position) {
    this.position = position.copy();
    
    // Load all 16 frames of the exit animation
    exitFrames = new PImage[16];
    for (int i = 0; i < 16; i++) {
      String framePath = "CharacterPack/GPE/nextlevel/nextlevel1/nextlevel_1_" + nf(i + 1, 2) + ".png";
      exitFrames[i] = loadImage(framePath);
      
      // Create a placeholder if the image failed to load
      if (exitFrames[i] == null) {
        exitFrames[i] = createPlaceholderImage(64, 64, color(100, 200, 255));
      }
    }
  }
  
  private PImage createPlaceholderImage(int w, int h, color c) {
    PImage img = createImage(w, h, ARGB);
    img.loadPixels();
    for (int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = c;
    }
    img.updatePixels();
    return img;
  }
  
  void update() {
    // Update animation frame
    currentFrame += ANIMATION_SPEED;
    if (currentFrame >= exitFrames.length) {
      currentFrame = 0;
    }
  }
  
  void draw() {
    if (!active) return;
    
    // Draw the exit animation
    int frameIndex = min((int)currentFrame, exitFrames.length - 1);
    
    // Draw the exit image
    image(exitFrames[frameIndex], position.x, position.y);
  }
  
  boolean isPlayerInRange(Character player) {
    // Check if player is in collision range with the exit
    return active && PVector.dist(player.position, position) < radius + player.radius;
  }
  
  void deactivate() {
    active = false;
  }
}