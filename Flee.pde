class Flee implements SteeringBehavior {
  PVector targetPosition;
  float maxAcceleration;
  float fleeRadius; // Only flee within this radius
  
  Flee(PVector targetPosition, float maxAcceleration, float fleeRadius) {
    this.targetPosition = targetPosition.copy();
    this.maxAcceleration = maxAcceleration;
    this.fleeRadius = fleeRadius;
  }
  
  PVector calculateForce(PhysicsObject character) {
    // Calculate direction away from target
    PVector direction = PVector.sub(character.position, targetPosition);
    float distance = direction.mag();
    
    // Only flee if within radius
    if (distance > fleeRadius) {
      return new PVector(0, 0);
    }
    
    // Scale by distance (flee harder when closer)
    // stronger fleeing behavior
    float scale = map(distance, 0, fleeRadius, 1.5, 0.5);
    
    // Return acceleration away from target
    direction.normalize();
    direction.mult(maxAcceleration * scale);
    return direction;
  }
}