import processing.core.PFont;

// Extend the existing Background class
class AsciiBackground extends Background {

  // --- Fields specific to AsciiBackground ---
  int cols, rows;          // Number of columns and rows in the character grid
  int fontSize = 12;      // The size of the font characters
  float cellWidth, cellHeight; // Calculated width and height of each character cell
  PFont asciiFont;        // Using a different name to avoid potential confusion with inherited fields

  char[][] characters;    // 2D array holding the character for each grid cell
  // Character set sorted roughly by visual density
  String charSet = " .'`^\",:;Il!i~+_-?][}{1)(|/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$";
  // String charSet = " .,:;+*#%@"; // Simpler alternative

  float noiseScale = 0.5;  // Noise pattern "zoom" level
  float timeScale = 0.005; // Animation speed
  float zOffset = 0;       // Time dimension for noise

  int updateFrequency = 2; // Update grid every N frames for performance
  int frameCounter = 0;    // Frame counter for update frequency

  // --- Constructor ---
  AsciiBackground() {
    // Call the parent class constructor first
    super("CharacterPack/Enviro/BG/trees_bg.png"); // Call parent constructor but won't use the image

    println("Initializing AsciiBackground (extends Background)...");

    // --- Initialize AsciiBackground specific things ---
    // Load the font for ASCII display
    try {
      asciiFont = createFont("Courier New", fontSize, true);
      println("Using font: Courier New for ASCII Background");
    } catch (Exception e) {
      println("Warning: Monospace font 'Courier New' not found. Using default SansSerif for ASCII.");
      asciiFont = createFont("SansSerif", fontSize, true); // Fallback
    }

    // Calculate grid dimensions based on the font
    // Use textWidth() with the specific font we loaded
    textFont(asciiFont); // Temporarily set font to measure accurately
    cellWidth = textWidth('W'); // Estimate cell width
    cellHeight = fontSize;      // Approximate cell height

    if (cellWidth <= 0) { // Safety check if font loading failed badly
        println("Error: Cell width calculation failed. Using fallback.");
        cellWidth = fontSize * 0.6f; // Rough estimate
    }

    cols = (int)(width / cellWidth) + 1;
    rows = (int)(height / cellHeight) + 1;

    // Initialize the character grid array
    characters = new char[cols][rows];

    // Populate the grid with initial characters
    updateGrid();

    println("ASCII Background Initialized: Grid size " + cols + "x" + rows);
  }

  // --- Methods specific to AsciiBackground ---

  // Method to update the character grid based on Perlin noise
  void updateGrid() {
    zOffset += timeScale; // Increment time for animation

    for (int j = 0; j < rows; j++) {
      for (int i = 0; i < cols; i++) {
        float noiseX = i * noiseScale;
        float noiseY = j * noiseScale;
        float noiseValue = noise(noiseX, noiseY, zOffset); // Get 3D noise value

        // Map noise value (0-1) to character index in charSet
        int charIndex = int(map(noiseValue, 0.0f, 1.0f, 0, charSet.length()));
        charIndex = constrain(charIndex, 0, charSet.length() - 1); // Ensure index is valid

        characters[i][j] = charSet.charAt(charIndex); // Assign character
      }
    }
  }

  // --- Override the display() method ---
  // This method REPLACES the display() method inherited from the Background class
  @Override
  void display() {
    // DO NOT call super.display() as we're completely replacing the background drawing

    frameCounter++;
    // Update the character grid periodically for performance
    if (frameCounter % updateFrequency == 0) {
       updateGrid();
    }

    // --- Drawing Setup for ASCII ---
    pushStyle(); // Isolate drawing settings

    // Set the correct font and alignment
    textFont(asciiFont, fontSize);
    textAlign(LEFT, TOP);
    // Set the fill color for the ASCII characters
    fill(100, 150, 255, 190); // Semi-transparent blue color

    // Clear the background with a solid color
    background(0); // Black background behind the ASCII characters

    // --- Draw the ASCII Characters ---
    for (int j = 0; j < rows; j++) { // Loop through rows
      for (int i = 0; i < cols; i++) { // Loop through columns
        // Calculate screen position for this character cell
        float screenX = i * cellWidth;
        float screenY = j * cellHeight;

        // Draw the character
        text(characters[i][j], screenX, screenY);
      }
    }

    popStyle(); // Restore previous drawing settings
  }

  // Note: The methods inherited from Background (like drawStars, drawWaterfall, etc.)
  // still technically exist in this class, but they are NOT called by this overridden
  // display() method, so they won't have any visual effect when using AsciiBackground.
}