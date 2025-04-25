class Level2Exit {
  private PVector position;
  private PImage exitImage;
  private boolean active = false;
  private float radius = 50.0f; // Collision radius
  
  // Visual effect properties
  private float glowIntensity = 0;
  private float vibrationAmount = 0;
  private float glowSpeed = 0.05f;
  private float vibrateSpeed = 0.15f;
  
  Level2Exit(PVector position) {
    this.position = position.copy();
    
    // Load the exit image
    exitImage = loadImage("CharacterPack/Enviro/Exits/exit_01.png");
    
    // Create a placeholder if the image failed to load
    if (exitImage == null) {
      println("Warning: Exit image not found, creating placeholder");
      exitImage = createPlaceholderImage(80, 160, color(200, 230, 255));
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
    if (!active) return;
    
    // Update glow effect
    glowIntensity = 0.5f + 0.5f * sin(frameCount * glowSpeed);
    
    // Update vibration effect
    vibrationAmount = 2 * sin(frameCount * vibrateSpeed);
  }
  
  void draw() {
    if (!active) return;
    
    pushStyle();
    
    // Draw the exit image 
    imageMode(CENTER);
    
    // slight vibration effect 
    float offsetX = vibrationAmount;
    float offsetY = vibrationAmount * 0.5f;
    
    // Draw the actual image
    image(exitImage, position.x + offsetX, position.y + offsetY);
    
    popStyle();
  }
  
  void activate() {
    active = true;
    
    // Visual effect for activation
    pushStyle();
    fill(200, 230, 255, 150);
    ellipse(position.x, position.y, radius * 4, radius * 4);
    popStyle();
  }
  
  void deactivate() {
    active = false;
  }
  
  boolean isPlayerInRange(Character player) {
    // Check if player is in collision range with the exit
    return active && PVector.dist(player.position, position) < radius + player.radius;
  }
}