class Wander implements SteeringBehavior {
  private PVector circleCenter;
  private float circleDistance;
  private float circleRadius;
  private float wanderAngle;
  private float maxAcceleration;
  
  Wander(float maxAcceleration, float circleDistance, float circleRadius) {
    this.maxAcceleration = maxAcceleration;
    this.circleDistance = circleDistance;
    this.circleRadius = circleRadius;
    this.wanderAngle = random(TWO_PI); // Start with random angle
  }
  
  PVector calculateForce(PhysicsObject character) {
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
    
    return wanderForce;
  }
  
  // For debugging
  void debugDraw(PhysicsObject character) {
    pushStyle();
    noFill();
    stroke(255, 165, 0); // Orange
    
    // Calculate the circle center
    PVector circleCenter;
    if (character.velocity.mag() < 0.01) {
      circleCenter = new PVector(character.position.x + circleDistance, character.position.y);
    } else {
      circleCenter = character.velocity.copy();
      circleCenter.normalize();
      circleCenter.mult(circleDistance);
      circleCenter.add(character.position);
    }
    
    // Draw the wander circle
    ellipse(circleCenter.x, circleCenter.y, circleRadius * 2, circleRadius * 2);
    
    // Calculate and draw the displacement
    PVector displacement = new PVector(0, -1);
    float x = displacement.x * cos(wanderAngle) - displacement.y * sin(wanderAngle);
    float y = displacement.x * sin(wanderAngle) + displacement.y * cos(wanderAngle);
    displacement.x = x;
    displacement.y = y;
    displacement.mult(circleRadius);
    
    // Draw the target point
    fill(255, 0, 0);
    ellipse(circleCenter.x + displacement.x, circleCenter.y + displacement.y, 5, 5);
    
    popStyle();
  }
}