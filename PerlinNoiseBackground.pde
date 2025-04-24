class PerlinNoiseBackground extends Background {
  PImage noiseImage;
  float noiseScale = 0.01; // Scale of noise (smaller = more zoomed out)
  float timeOffset = 0;    // For animation
  color[] colorPalette;    // Store our color palette
  
  // Optimization parameters
  float resolutionScale = 0.3;  // Generate at 30% resolution to save performance
  int frameSkip = 5;           // Only regenerate every 5 frames
  
  PerlinNoiseBackground() {
    super("CharacterPack/Enviro/BG/trees_bg.png"); // Call parent constructor but won't use the image
    
    // Generate a black and red color palette
    colorPalette = new color[5];
    colorPalette[0] = color(0, 0, 0);         // Pure black
    colorPalette[1] = color(30, 0, 0);        // Very dark red
    colorPalette[2] = color(70, 10, 10);      // Dark red
    colorPalette[3] = color(120, 20, 20);     // Medium red
    colorPalette[4] = color(180, 30, 30);     // Brighter red (not too bright to maintain atmosphere)
    
    // Create initial noise image at reduced resolution
    int scaledWidth = int(width * resolutionScale);
    int scaledHeight = int(height * resolutionScale);
    noiseImage = createImage(scaledWidth, scaledHeight, RGB);
    
    // Generate initial pattern
    generateNoisePattern();
  }
  
  void generateNoisePattern() {
    // Work with reduced resolution for better performance
    int scaledWidth = noiseImage.width;
    int scaledHeight = noiseImage.height;
    
    noiseImage.loadPixels();
    
    // Calculate adjusted noise scale to maintain the same visual scale at lower resolution
    float adjustedNoiseScale = noiseScale / resolutionScale;
    
    for (int y = 0; y < scaledHeight; y++) {
      for (int x = 0; x < scaledWidth; x++) {
        // Calculate noise value with time offset for animation
        float noiseValue = noise(x * adjustedNoiseScale, y * adjustedNoiseScale, timeOffset);
        
        // Map the noise value to a color from our palette
        int colorIndex = floor(map(noiseValue, 0, 1, 0, colorPalette.length - 0.01));
        color pixelColor = colorPalette[colorIndex];
        
        // Add some variation based on noise value
        // For red tones, we'll adjust mostly the red channel
        float redVariation = map(noiseValue, 0, 1, 0.7, 1.1);
        float darkening = map(noiseValue, 0, 1, 0.9, 1.0); // Subtle darkening for atmosphere
        
        pixelColor = color(
          red(pixelColor) * redVariation,
          green(pixelColor) * darkening,
          blue(pixelColor) * darkening
        );
        
        // Set the pixel color
        noiseImage.pixels[y * scaledWidth + x] = pixelColor;
      }
    }
    
    noiseImage.updatePixels();
  }
  
  void update() {
    // Increment time offset for animation (very small for subtle movement)
    timeOffset += 0.005;
    
    // Regenerate the pattern less frequently to save performance
    if (frameCount % frameSkip == 0) {
      generateNoisePattern();
    }
  }
  
  @Override
  void display() {
    // Update the noise pattern
    update();
    
    // Draw the noise pattern, scaling it up to full screen
    imageMode(CORNER);
    image(noiseImage, 0, 0, width, height);
    imageMode(CENTER); // Reset to the mode used by the game
  }
}