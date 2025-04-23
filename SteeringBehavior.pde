interface SteeringBehavior {
  PVector calculateForce(PhysicsObject character);
}

class SteeringOutput {
  PVector linear = new PVector(0, 0);
  float angular = 0;
  
  SteeringOutput() {}
  
  void add(SteeringOutput other, float weight) {
    linear.add(PVector.mult(other.linear, weight));
    angular += other.angular * weight;
  }
}