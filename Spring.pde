class Spring extends PhysicsObject {
  PImage platformImage;
  private boolean isCompressed = false;
  private float compressionTimer = 0.0f;
  private final float ANIMATION_SPEED = 0.2f;
  private final float BOUNCE_FORCE = 50.0f; 
  private color springColor = color(255, 100, 100); // Reddish color for the spring indicator
  
  Spring(PVector position) {
    super(position, 1.0f); 
    this.radius = 10.0f;
    this.isStatic = true; //static object
    
    platformImage = loadImage("CharacterPack/GPE/platforms/platform_through.png");
    
    //if isn't available, create a placeholder
    if (platformImage == null) {
      platformImage = createPlaceholderImage(64, 16, color(150, 150, 150));
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
    super.update();
    
    // If compressed, update the timer
    if (isCompressed) {
      compressionTimer += ANIMATION_SPEED;
      if (compressionTimer >= 1.0) {
        isCompressed = false;
        compressionTimer = 0;
      }
    }
  }
  
  void draw() {
    pushStyle();
    
    // Draw the platform image
    image(platformImage, position.x, position.y);
    
    // Draw the spring indicator
    if (isCompressed) {
      // Compressed spring (flatter)
      fill(springColor);
      noStroke();
      rect(position.x - platformImage.width/2 + 4, position.y - platformImage.height/2 - 4, 
           platformImage.width - 8, 4);
    } else {
      // Extended spring (taller)
      fill(springColor);
      noStroke();
      beginShape();
      // Draw a zigzag shape 
      float zigzagWidth = platformImage.width - 8; 
      float zigzagHeight = 8;
      float startX = position.x - zigzagWidth/2;
      float startY = position.y - platformImage.height/2 - zigzagHeight;
      
      // Draw zigzag pattern across the full width
      vertex(startX, startY + zigzagHeight);
      
      // Calculate how many zigzag segments to fit across the platform
      int segments = 5; //odd number for symmetry
      float segmentWidth = zigzagWidth / segments;
      
      for (int i = 0; i < segments; i++) {
        if (i % 2 == 0) {
          // Up segment
          vertex(startX + (i+0.5) * segmentWidth, startY);
        } else {
          // Down segment
          vertex(startX + (i+0.5) * segmentWidth, startY + zigzagHeight);
        }
      }
      
      vertex(startX + zigzagWidth, startY + zigzagHeight);
      endShape();
    }
    
    popStyle();
  }
  
  boolean compress() {
    // Compress the spring and return true if it wasn't already compressed
    if (!isCompressed) {
      isCompressed = true;
      compressionTimer = 0;
      return true;
    }
    return false;
  }
  
  float getBounceForce() {
    return BOUNCE_FORCE;
  }
}