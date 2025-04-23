class BoundedWander implements SteeringBehavior {
  private PVector circleCenter;
  private float circleDistance;
  private float circleRadius;
  private float wanderAngle;
  private float maxAcceleration;
  
  // Platform boundary parameters
  private float minX;
  private float maxX;
  private float y;  // The y-coordinate of the platform (top surface)
  
  BoundedWander(float maxAcceleration, float circleDistance, float circleRadius, 
                float minX, float maxX, float y) {
    this.maxAcceleration = maxAcceleration;
    this.circleDistance = circleDistance;
    this.circleRadius = circleRadius;
    this.wanderAngle = random(TWO_PI); // Start with random angle
    
    // Set platform boundaries
    this.minX = minX;
    this.maxX = maxX;
    this.y = y;
  }
  
  PVector calculateForce(PhysicsObject character) {
    // Check if character is approaching or exceeding the boundary
    if (character.position.x < minX + character.radius) {
      // Too close to left boundary, force movement right
      PVector bounceForce = new PVector(maxAcceleration, 0);
      return bounceForce;
    } else if (character.position.x > maxX - character.radius) {
      // Too close to right boundary, force movement left
      PVector bounceForce = new PVector(-maxAcceleration, 0);
      return bounceForce;
    }
    
    // Calculate the circle center
    PVector circleCenter;
    
    if (character.velocity.mag() < 0.01) {
      // If not moving, use a default forward direction
      circleCenter = new PVector(character.position.x + circleDistance, character.position.y);
    } else {
      // Use velocity direction to position the circle
      circleCenter = character.velocity.copy();
      circleCenter.normalize();
      circleCenter.mult(circleDistance);
      circleCenter.add(character.position);
    }
    
    // Calculate the displacement force
    PVector displacement = new PVector(0, -1); // Start with upward vector
    
    // Rotate displacement by wander angle
    float x = displacement.x * cos(wanderAngle) - displacement.y * sin(wanderAngle);
    float y = displacement.x * sin(wanderAngle) + displacement.y * cos(wanderAngle);
    displacement.x = x;
    displacement.y = y;
    
    // Scale displacement to circle radius
    displacement.mult(circleRadius);
    
    // Set the wander force
    PVector wanderForce = PVector.add(circleCenter, displacement);
    wanderForce.sub(character.position);
    
    // Change the wander angle slightly for next frame for a more random behavior
    wanderAngle += random(-0.5, 0.5);
    
    // Normalize and scale by max acceleration
    wanderForce.normalize();
    wanderForce.mult(maxAcceleration);
    
    // If the wander force would push the character off the platform, constrain it
    if ((character.position.x + wanderForce.x < minX + character.radius) || 
        (character.position.x + wanderForce.x > maxX - character.radius)) {
      // Reverse the x component
      wanderForce.x *= -1;
    }
    
    // Reduce vertical movement to keep it on platform
    wanderForce.y *= 0.1;
    
    return wanderForce;
  }
}