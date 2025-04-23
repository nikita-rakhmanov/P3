import java.util.Collections; // For Collections.reverse()

// A* pathfinding implementation
class PathFinder {
  GridMap gridMap;
  boolean debugMode;
  
  // For visualization
  ArrayList<PVector> closedSetPositions;
  ArrayList<PVector> openSetPositions;
  
  PathFinder(GridMap gridMap) {
    this.gridMap = gridMap;
    this.debugMode = false;
    this.closedSetPositions = new ArrayList<PVector>();
    this.openSetPositions = new ArrayList<PVector>();
  }
  
  void setDebugMode(boolean debugMode) {
    this.debugMode = debugMode;
  }
  
  // Heuristic function: h(n) = |Δx| + max(0, Δy)
  // This favors horizontal movement and falling down 
  float heuristic(PVector a, PVector b) {
    float dx = abs(a.x - b.x);
    float dy = a.y - b.y; 
    return dx + max(0, dy);
  }
  
  // Find path using A* algorithm
  Path findPath(PVector startPos, PVector goalPos) {
    // Reset debug visualizations
    closedSetPositions.clear();
    openSetPositions.clear();
    
    // Check if the path request is reasonable
    float maxPathDistance = 400.0f; // Maximum world distance for path search
    if (PVector.dist(startPos, goalPos) > maxPathDistance) {
      println("Warning: Path requested is too long, returning empty path");
      return new Path();
    }
    
    // Early termination for unreachable goals (player above enemy)
    if (goalPos.y < startPos.y - 25) { // Add small buffer for slight elevation differences
      // The goal is above the start - unreachable in a platformer
      if (debugMode) println("Goal is above start position and unreachable");
      return new Path();
    }
    
    PVector startGrid = gridMap.worldToGrid(startPos);
    PVector goalGrid = gridMap.worldToGrid(goalPos);
    
    // If they're on the same height (same platform) but separated by unwalkable cells
    if (Math.abs(startGrid.y - goalGrid.y) < 2) {  // Approximately same height
      int startX = (int)startGrid.x;
      int startY = (int)startGrid.y;
      int goalX = (int)goalGrid.x;
      int goalY = (int)goalGrid.y;
      
      // Check if there's a continuous walkable path 
      boolean hasDirectPath = true;
      for (int x = Math.min(startX, goalX); x <= Math.max(startX, goalX); x++) {
        if (!gridMap.isValid(x, startY) || !gridMap.isWalkable(x, startY)) {
          hasDirectPath = false;
          break;
        }
      }
      
      if (!hasDirectPath) {
        if (debugMode) println("No direct path between enemy and player on platform");
        return new Path();
      }
    }
    
    int startX = (int)startGrid.x;
    int startY = (int)startGrid.y;
    int goalX = (int)goalGrid.x;
    int goalY = (int)goalGrid.y;
    
    // Quick check for invalid input
    if (!gridMap.isValid(startX, startY) || !gridMap.isValid(goalX, goalY)) {
      return new Path();
    }
    
    // If start or goal is not walkable, find nearest walkable node
    if (!gridMap.isWalkable(startX, startY)) {
      // Find nearest walkable node for start
      Node nearest = findNearestWalkableNode(startX, startY);
      if (nearest == null) return new Path();
      startX = (int)nearest.position.x;
      startY = (int)nearest.position.y;
    }
    
    if (!gridMap.isWalkable(goalX, goalY)) {
      // Find nearest walkable node for goal
      Node nearest = findNearestWalkableNode(goalX, goalY);
      if (nearest == null) return new Path();
      goalX = (int)nearest.position.x;
      goalY = (int)nearest.position.y;
    }
    
    // Get start and goal nodes
    Node startNode = gridMap.grid[startX][startY];
    Node goalNode = gridMap.grid[goalX][goalY];
    
    // A* algorithm
    ArrayList<Node> openSet = new ArrayList<Node>();
    ArrayList<Node> closedSet = new ArrayList<Node>();
    
    openSet.add(startNode);
    
    // Add time limit to prevent searches that take too long
    long startTime = millis();
    final long MAX_SEARCH_TIME = 100; // Max search time in milliseconds
    int iterations = 0;
    final int MAX_ITERATIONS = 1000; // Max iterations to prevent infinite loops
    
    // While open set is not empty
    while (!openSet.isEmpty()) {
      // Check time and iteration limits
      if (millis() - startTime > MAX_SEARCH_TIME) {
        // println("A* search timed out after " + MAX_SEARCH_TIME + "ms");
        return new Path();
      }
      
      if (iterations++ > MAX_ITERATIONS) {
        // println("A* search exceeded max iterations (" + MAX_ITERATIONS + ")");
        return new Path();
      }
      // Find node with lowest f cost
      Node current = openSet.get(0);
      for (int i = 1; i < openSet.size(); i++) {
        if (openSet.get(i).f < current.f) {
          current = openSet.get(i);
        }
      }
      
      // Move current from open to closed set
      openSet.remove(current);
      closedSet.add(current);
      
      // For debug visualization
      if (debugMode) {
        openSetPositions.clear();
        closedSetPositions.clear();
        for (Node n : openSet) openSetPositions.add(gridMap.gridToWorld(n.position));
        for (Node n : closedSet) closedSetPositions.add(gridMap.gridToWorld(n.position));
      }
      
      // If we reached the goal, reconstruct path
      if (current.equals(goalNode)) {
        return reconstructPath(current);
      }
      
      // Check all neighbors
      ArrayList<Node> neighbors = gridMap.getNeighbors(current);
      
      for (Node neighbor : neighbors) {
        // Skip if already evaluated
        boolean inClosedSet = false;
        for (Node n : closedSet) {
          if (n.equals(neighbor)) {
            inClosedSet = true;
            break;
          }
        }
        if (inClosedSet) continue;
        
        // Calculate tentative g score
        float moveCost = 1.0; // Base cost for all moves
        
        // Make falling slightly cheaper to prefer it over purely horizontal movement
        if (neighbor.position.y > current.position.y) {
          moveCost = 0.9;
        }
        
        float tentativeG = current.g + moveCost;
        
        // See if this path is better than any previous one
        boolean inOpenSet = false;
        for (Node n : openSet) {
          if (n.equals(neighbor)) {
            inOpenSet = true;
            if (tentativeG < n.g) {
              // Found better path to this neighbor
              n.g = tentativeG;
              n.h = heuristic(n.position, goalNode.position);
              n.f = n.g + n.h;
              n.parent = current;
            }
            break;
          }
        }
        
        // If not in open set, add it
        if (!inOpenSet) {
          neighbor.g = tentativeG;
          neighbor.h = heuristic(neighbor.position, goalNode.position);
          neighbor.f = neighbor.g + neighbor.h;
          neighbor.parent = current;
          openSet.add(neighbor);
        }
      }
    }
    
    // No path found
    return new Path();
  }
  
  // Find the nearest walkable node to a given position
  Node findNearestWalkableNode(int x, int y) {
    // Check immediate vicinity first (to avoid expensive search)
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        int nx = x + dx;
        int ny = y + dy;
        if (gridMap.isValid(nx, ny) && gridMap.isWalkable(nx, ny)) {
          return gridMap.grid[nx][ny];
        }
      }
    }
    
    // If not found, do a BFS search (more expensive)
    ArrayList<Node> queue = new ArrayList<Node>();
    boolean[][] visited = new boolean[gridMap.cols][gridMap.rows];
    
    // Add starting point
    queue.add(new Node(new PVector(x, y), false));
    visited[x][y] = true;
    
    // BFS
    while (!queue.isEmpty()) {
      Node current = queue.remove(0);
      int cx = (int)current.position.x;
      int cy = (int)current.position.y;
      
      // Check all 4 directions
      int[][] dirs = {{0,1}, {1,0}, {0,-1}, {-1,0}};
      for (int[] dir : dirs) {
        int nx = cx + dir[0];
        int ny = cy + dir[1];
        
        if (gridMap.isValid(nx, ny) && !visited[nx][ny]) {
          visited[nx][ny] = true;
          
          if (gridMap.isWalkable(nx, ny)) {
            return gridMap.grid[nx][ny];
          }
          
          queue.add(new Node(new PVector(nx, ny), false));
        }
      }
    }
    
    // No walkable node found
    return null;
  }
  
  // Reconstruct path from goal to start
  Path reconstructPath(Node goalNode) {
    Path path = new Path();
    Node current = goalNode;
    
    // Add a safety counter for debugging
    int safetyCounter = 0;
    final int MAX_PATH_NODES = 200; // Safety limit
    
    // Traverse parent pointers back to start
    while (current != null && safetyCounter < MAX_PATH_NODES) {
      path.addPoint(gridMap.gridToWorld(current.position));
      current = current.parent;
      safetyCounter++;
    }
    
    if (safetyCounter >= MAX_PATH_NODES) {
      // println("Warning: Path reconstruction safety limit reached. Possible circular reference.");
    }
    
    // Reverse to get path from start to goal
    Collections.reverse(path.points);
    
    // Path smoothing to remove unnecessary waypoints
    smoothPath(path);
    
    return path;
  }
  
  // Smooth the path by removing unnecessary waypoints
  void smoothPath(Path path) {
    if (path.size() <= 2) return; // Nothing to smooth
    
    for (int i = 0; i < path.points.size() - 2;) {
      PVector current = path.points.get(i);
      PVector next = path.points.get(i + 2);
      
      // If we can go directly from current to next+1, remove next
      boolean canSkip = true;
      
      // Convert to grid coordinates
      PVector currentGrid = gridMap.worldToGrid(current);
      PVector nextGrid = gridMap.worldToGrid(next);
      
      // Only optimize if on same y-level (so we don't mess with falling)
      if (currentGrid.y == nextGrid.y) {
        int x1 = (int)currentGrid.x;
        int x2 = (int)nextGrid.x;
        int y = (int)currentGrid.y;
        
        // Check if all cells between are walkable
        for (int x = min(x1, x2); x <= max(x1, x2); x++) {
          if (!gridMap.isWalkable(x, y)) {
            canSkip = false;
            break;
          }
        }
        
        if (canSkip) {
          path.points.remove(i + 1); // Remove middle point
        } else {
          i++; // Move to next point
        }
      } else {
        i++; // Different y-levels, don't optimize
      }
    }
  }
  
  // Debug visualization
  void debugDraw() {
    if (!debugMode) return;
    
    pushStyle();
    
    // Draw closed set nodes (already evaluated)
    fill(255, 0, 0, 100);
    noStroke();
    for (PVector pos : closedSetPositions) {
      ellipse(pos.x, pos.y, 10, 10);
    }
    
    // Draw open set nodes (to be evaluated)
    fill(0, 255, 0, 100);
    for (PVector pos : openSetPositions) {
      ellipse(pos.x, pos.y, 10, 10);
    }
    
    popStyle();
  }
}