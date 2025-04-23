class PhysicsEngine {
  private ArrayList<PhysicsObject> objects;
  private ForceRegistry forceRegistry;
  
  // Flag to enable/disable collision detection
  private boolean detectCollisions = true;
  
  PhysicsEngine() {
    objects = new ArrayList<PhysicsObject>();
    forceRegistry = new ForceRegistry();
  }
  
  // Add a physics object to the engine
  void addObject(PhysicsObject object) {
    if (!objects.contains(object)) {
      objects.add(object);
    }
  }
  
  // Remove a physics object from the engine
  void removeObject(PhysicsObject object) {
    objects.remove(object);
    forceRegistry.removeAll(object);
  }
  
  // Add a force generator to an object
  void addForceGenerator(PhysicsObject object, ForceGenerator fg) {
    forceRegistry.add(object, fg);
  }
  
  // Remove a force generator from an object
  void removeForceGenerator(PhysicsObject object, ForceGenerator fg) {
    forceRegistry.remove(object, fg);
  }
  
  // Update the physics simulation
  void update() {
    // Update all forces
    forceRegistry.updateForces();
    
    // Update all objects
    for (PhysicsObject obj : objects) {
      obj.update();
    }
    
    // Handle collisions if enabled
    if (detectCollisions) {
      checkCollisions();
    }
  }
  
  // Enable or disable collision detection
  void setCollisionDetection(boolean enable) {
    detectCollisions = enable;
  }
  
  private void checkCollisions() {
    // collision detection
    for (int i = 0; i < objects.size(); i++) {
        PhysicsObject objA = objects.get(i);
        
        for (int j = i + 1; j < objects.size(); j++) {
            PhysicsObject objB = objects.get(j);
            
            // Skip collisions between:
            // 1. Character and Enemy/Platform
            // 2. Enemy and Platform
            // 3. Enemy and other Enemies 
            if ((objA instanceof Character && (objB instanceof Enemy || objB instanceof PlatformObject)) || 
                ((objA instanceof Enemy || objA instanceof PlatformObject) && objB instanceof Character) ||
                (objA instanceof Enemy && objB instanceof PlatformObject) ||
                (objA instanceof PlatformObject && objB instanceof Enemy) ||
                (objA instanceof Enemy && objB instanceof Enemy)) {  // Added this condition
                continue;  // Skip to the next iteration
            }
            
            // Check and resolve collision
            if (objA.isColliding(objB)) {
                objA.resolveCollision(objB);
            }
        }
    }
}
  
  // Get all physics objects
  ArrayList<PhysicsObject> getObjects() {
    return objects;
  }
  
  // Debug visualization (circles)
  void debugDraw() {
    for (PhysicsObject obj : objects) {
      pushStyle();
      noFill();
      stroke(0, 255, 0);
      ellipse(obj.position.x, obj.position.y, obj.radius * 2, obj.radius * 2);
      popStyle();
    }
  }
}