class GridMap {
  Node[][] grid;
  int cols, rows;
  float cellSize;
  
  GridMap(float width, float height, float cellSize) {
    this.cellSize = cellSize;
    this.cols = ceil(width / cellSize);
    this.rows = ceil(height / cellSize);
    
    // Initialize grid with all walkable nodes
    grid = new Node[cols][rows];
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        grid[x][y] = new Node(new PVector(x, y), true);
      }
    }
  }
  
  // Convert world position to grid position
  PVector worldToGrid(PVector worldPos) {
    int x = floor(worldPos.x / cellSize);
    int y = floor(worldPos.y / cellSize);
    return new PVector(constrain(x, 0, cols-1), constrain(y, 0, rows-1));
  }
  
  // Convert grid position to world position (center of cell)
  PVector gridToWorld(PVector gridPos) {
    float x = (gridPos.x + 0.5) * cellSize;
    float y = (gridPos.y + 0.5) * cellSize;
    return new PVector(x, y);
  }
  
  // Check if a grid position is valid
  boolean isValid(int x, int y) {
    return x >= 0 && x < cols && y >= 0 && y < rows;
  }
  
  // Check if a node is walkable
  boolean isWalkable(int x, int y) {
    if (!isValid(x, y)) return false;
    return grid[x][y].walkable;
  }
  
  // Set node as walkable or not
  void setWalkable(int x, int y, boolean walkable) {
    if (isValid(x, y)) {
      grid[x][y].walkable = walkable;
    }
  }
  
  // Get neighbors of a node - specialized for platformer movement
  ArrayList<Node> getNeighbors(Node node) {
    ArrayList<Node> neighbors = new ArrayList<Node>();
    int x = (int)node.position.x;
    int y = (int)node.position.y;
    
    // Left neighbor (horizontal movement)
    if (isWalkable(x-1, y)) {
      neighbors.add(grid[x-1][y]);
    }
    
    // Right neighbor (horizontal movement)
    if (isWalkable(x+1, y)) {
      neighbors.add(grid[x+1][y]);
    }
    
    // Below neighbor (falling)
    if (isValid(x, y+1) && isWalkable(x, y+1)) {
      // Check if there's ground below current position
      boolean hasGroundBelow = false;
      
      // Check the cell directly below
      if (isValid(x, y+1) && !isWalkable(x, y+1)) {
        hasGroundBelow = true;
      }
      
      // If no ground below, add the below cell as a neighbor (can fall)
      if (!hasGroundBelow) {
        neighbors.add(grid[x][y+1]);
      }
    }
    
    // Check for falling off edges of platforms
    // If standing on ground and there's space to the left/right + down
    boolean standingOnGround = isValid(x, y+1) && !isWalkable(x, y+1);
    
    // Left edge
    if (standingOnGround && isValid(x-1, y) && isWalkable(x-1, y) && 
        isValid(x-1, y+1) && isWalkable(x-1, y+1)) {
      neighbors.add(grid[x-1][y+1]); // Can step left and fall
    }
    
    // Right edge
    if (standingOnGround && isValid(x+1, y) && isWalkable(x+1, y) && 
        isValid(x+1, y+1) && isWalkable(x+1, y+1)) {
      neighbors.add(grid[x+1][y+1]); // Can step right and fall
    }
    
    return neighbors;
  }
  
  // Draw the grid for debugging
  void debugDraw() {
    pushStyle();
    rectMode(CORNER);
    
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        if (!grid[x][y].walkable) {
          // Non-walkable cells are red
          fill(255, 0, 0, 100);
          rect(x * cellSize, y * cellSize, cellSize, cellSize);
        } else {
          // Walkable cells are green
          fill(0, 255, 0, 30);
          rect(x * cellSize, y * cellSize, cellSize, cellSize);
        }
      }
    }
    
    popStyle();
  }
}