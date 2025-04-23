class Seek implements SteeringBehavior {
  PVector targetPosition;
  float maxAcceleration;
  
  Seek(PVector targetPosition, float maxAcceleration) {
    this.targetPosition = targetPosition;
    this.maxAcceleration = maxAcceleration;
  }
  
  PVector calculateForce(PhysicsObject character) {
    // Calculate direction to target
    PVector direction = PVector.sub(targetPosition, character.position);
    
    // If we're already at the target, return no force
    if (direction.mag() < 0.1) {
      return new PVector(0, 0);
    }
    
    // Return maximum acceleration in that direction
    direction.normalize();
    direction.mult(maxAcceleration);
    return direction;
  }
}