class Path {
  ArrayList<PVector> points;
  private final int MAX_PATH_LENGTH = 200; // reasonable maximum path length
  
  Path() {
    points = new ArrayList<PVector>();
  }
  
  void addPoint(PVector point) {
    // Only add points if we haven't reached the maximum path length
    if (points.size() < MAX_PATH_LENGTH) {
      points.add(point);
    } else {
      // Print a warning if we hit the limit (helps with debugging)
      if (points.size() == MAX_PATH_LENGTH) {
        // println("Warning: Maximum path length reached (" + MAX_PATH_LENGTH + "), truncating path");
      }
    }
  }
  
  boolean isEmpty() {
    return points.isEmpty();
  }
  
  PVector getFirstPoint() {
    if (!isEmpty()) {
      return points.get(0);
    }
    return null;
  }
  
  void removeFirstPoint() {
    if (!isEmpty()) {
      points.remove(0);
    }
  }
  
  PVector getPoint(int index) {
    if (index >= 0 && index < points.size()) {
      return points.get(index);
    }
    return null;
  }
  
  int size() {
    return points.size();
  }
  
  // Debug - draw the path with lines and points
  void debugDraw() {
    if (isEmpty()) return;
    
    pushStyle();
    stroke(0, 100, 255);
    strokeWeight(2);
    noFill();
    
    // Draw the path as a line
    beginShape();
    for (PVector point : points) {
      vertex(point.x, point.y);
    }
    endShape();
    
    // Draw each waypoint
    fill(255, 0, 0);
    noStroke();
    for (PVector point : points) {
      ellipse(point.x, point.y, 6, 6);
    }
    
    // Draw start and end points differently
    if (points.size() > 0) {
      fill(0, 255, 0);
      ellipse(points.get(0).x, points.get(0).y, 8, 8);
      
      if (points.size() > 1) {
        fill(255, 0, 255);
        ellipse(points.get(points.size()-1).x, points.get(points.size()-1).y, 8, 8);
      }
    }
    
    popStyle();
  }
}