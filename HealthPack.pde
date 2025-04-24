class HealthPack {
  private PVector position;
  private PImage healthImage;
  private boolean collected = false;
  private float radius = 16.0f; // Collision radius
  private float scale = 1.0f;
  private long collectionTime = 0; // Time when the health pack was collected
  
  // Glow effect properties
  private float glowIntensity = 0;
  private float glowSpeed = 0.03f;
  private color glowColor = color(0, 255, 100, 150); // Green glow for health
  
  HealthPack(PVector position) {
    this.position = position.copy();
    this.healthImage = loadImage("32px/health-green 32px.png");
    
    // If the image isn't available, create a placeholder
    if (this.healthImage == null) {
      println("Warning: Health image not found, creating placeholder");
      this.healthImage = createPlaceholderImage(32, 32, color(0, 255, 0));
    }
  }
  
  // Create a placeholder image if the actual image can't be loaded
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
    // Update the glow effect intensity with a pulsating pattern
    glowIntensity = 0.25f + 0.25f * sin(frameCount * glowSpeed);
    
    // Make the health pack float/pulse slightly
    if (!collected) {
      scale = 1.0f + 0.05f * sin(frameCount * 0.1f);
    } else {
      // Fade out when collected
      glowIntensity = max(0, glowIntensity - 0.05f);
      scale *= 0.9f; // Shrink as it disappears
    }
  }
  
  void draw() {
    if (collected && scale < 0.1f) return; // Don't draw if fully collected/shrunk
    
    pushStyle();
    imageMode(CENTER);
    
    // Draw the glowing effect
    if (!collected || glowIntensity > 0) {
      blendMode(ADD);
      noStroke();
      
      // Outer glow
      fill(glowColor, 40 * glowIntensity);
      ellipse(position.x, position.y, radius * 3.0f * scale, radius * 3.0f * scale);
      
      // Middle glow
      fill(glowColor, 80 * glowIntensity);
      ellipse(position.x, position.y, radius * 2.0f * scale, radius * 2.0f * scale);
      
      // Inner glow
      fill(glowColor, 120 * glowIntensity);
      ellipse(position.x, position.y, radius * 1.5f * scale, radius * 1.5f * scale);
      
      blendMode(BLEND);
    }
    
    // Draw the actual health image
    image(healthImage, position.x, position.y, 
          healthImage.width * scale, 
          healthImage.height * scale);
    
    popStyle();
  }
  
  boolean isCollected() {
    return collected;
  }
  
  void collect() {
    if (!collected) {
      collected = true;
      collectionTime = millis();
    }
  }
  
  // Getter for the radius property for collision detection
  float getRadius() {
    return radius;
  }
}