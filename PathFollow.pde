class PathFollow implements SteeringBehavior {
  Path path;
  float arrivalRadius;
  float maxAcceleration;
  boolean debugDraw;
  private int currentWaypointIndex = 0;
  
  PathFollow(Path path, float arrivalRadius, float maxAcceleration) {
    this.path = path;
    this.arrivalRadius = arrivalRadius;
    this.maxAcceleration = maxAcceleration;
    this.debugDraw = false;
    this.currentWaypointIndex = 0;
  }
  
  void setDebugDraw(boolean debug) {
    this.debugDraw = debug;
  }
  
  PVector calculateForce(PhysicsObject character) {
    // If no path or empty path, return no force
    if (path == null || path.isEmpty()) {
      return new PVector(0, 0);
    }
    
    // Make sure current waypoint index is valid
    if (currentWaypointIndex >= path.size()) {
      currentWaypointIndex = path.size() - 1;
    }
    
    // Get the current target waypoint
    PVector target = path.getPoint(currentWaypointIndex);
    if (target == null) {
      return new PVector(0, 0);
    }
    
    // Calculate direction to target
    PVector toTarget = PVector.sub(target, character.position);
    float distance = toTarget.mag();
    
    // If reached the current waypoint, move to the next one
    if (distance < arrivalRadius) {
      currentWaypointIndex++;
      
      // If we've reached the end of the path, stop
      if (currentWaypointIndex >= path.size()) {
        return new PVector(0, 0);
      }
      
      // Get the next waypoint
      target = path.getPoint(currentWaypointIndex);
      toTarget = PVector.sub(target, character.position);
      distance = toTarget.mag();
    }
    
    // Calculate force
    PVector force = new PVector(toTarget.x, 0);
    
    // Allow vertical force when we need to fall down
    if (toTarget.y > 0 && abs(toTarget.x) < 15) {
      force.y = toTarget.y;
    }
    
    // Normalize and scale
    if (force.mag() > 0) {
      force.normalize();
      force.mult(maxAcceleration);
    }
    
    // Draw debug visualization 
    if (debugDraw && target != null) {
      pushStyle();
      
      // Draw path
      path.debugDraw();
      
      // Highlight the current waypoint
      fill(255, 0, 0);
      ellipse(target.x, target.y, 10, 10);
      
      // Draw line from character to target
      stroke(255, 0, 0);
      strokeWeight(1);
      line(character.position.x, character.position.y, target.x, target.y);
      
      // Show the force vector
      stroke(0, 255, 255);
      line(character.position.x, character.position.y, 
           character.position.x + force.x * 10, 
           character.position.y + force.y * 10);
      
      popStyle();
    }
    
    return force;
  }
}