// Modify the Coin class to not be a physics object
class Coin {
  private PVector position;
  private PImage[] coinFrames;
  private PImage[] destroyFrames;
  private float currentFrame = 0.0f;
  private boolean collected = false;
  private final float ANIMATION_SPEED = 0.2f;
  private float radius = 25.0f;
  private float scale = 1.5f;   
  
  // Glow effect properties
  private float glowIntensity = 0;
  private float glowSpeed = 0.03f;
  private color glowColor = color(255, 215, 0, 150); // Golden yellow with transparency
  
  Coin(PVector position) {
    this.position = position.copy();
    
    coinFrames = new PImage[13];
    destroyFrames = new PImage[13];
    
    for (int i = 0; i < 13; i++) {
      String framePath = "CharacterPack/GPE/pickups/coin/coin_" + nf(i+1, 2) + ".png";
      coinFrames[i] = loadImage(framePath);
      
      String destroyPath = "CharacterPack/GPE/pickups/coin/destroy/coin_destroy_" + nf(i+1, 2) + ".png";
      destroyFrames[i] = loadImage(destroyPath);
    }
  }
  
  void update() {
    currentFrame += ANIMATION_SPEED;
    
    if (!collected) {
      if (currentFrame >= coinFrames.length) {
        currentFrame = 0;
      }
      
      // Update the glow effect intensity with a pulsating pattern
      glowIntensity = 0.5f + 0.5f * sin(frameCount * glowSpeed);
    } else {
      if (currentFrame >= destroyFrames.length) {
        currentFrame = destroyFrames.length - 1;
      }
      
      // Fade out the glow when collected
      glowIntensity = max(0, glowIntensity - 0.05f);
    }
  }
  
  void draw() {
    PImage[] frames = collected ? destroyFrames : coinFrames;
    int frameIndex = min((int)currentFrame, frames.length - 1);
    
    pushStyle();
    imageMode(CENTER);
    
    // Draw the glowing effect (multiple passes for better glow)
    if (!collected || glowIntensity > 0) {
      blendMode(ADD);
      noStroke();
      
      // Outer glow
      fill(glowColor, 40 * glowIntensity);
      ellipse(position.x, position.y, radius * 2.2f * scale, radius * 2.2f * scale);
      
      // Middle glow
      fill(glowColor, 80 * glowIntensity);
      ellipse(position.x, position.y, radius * 1.6f * scale, radius * 1.6f * scale);
      
      // Inner glow 
      fill(glowColor, 120 * glowIntensity);
      ellipse(position.x, position.y, radius * 1.2f * scale, radius * 1.2f * scale);
      
      blendMode(BLEND);
    }
    
    // Draw the actual coin image 
    image(frames[frameIndex], position.x, position.y, 
          frames[frameIndex].width * scale, 
          frames[frameIndex].height * scale);
    
    popStyle();
  }
  
  boolean isCollected() {
    return collected;
  }
  
  void collect() {
    if (!collected) {
      collected = true;
      currentFrame = 0; // Reset frame to start destroy animation
    }
  }
}