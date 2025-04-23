class SteeringController {
  private PhysicsObject owner;
  public ArrayList<SteeringBehavior> behaviors;
  private ArrayList<Float> weights;
  
  public SteeringController(PhysicsObject owner) {
    this.owner = owner;
    this.behaviors = new ArrayList<SteeringBehavior>();
    this.weights = new ArrayList<Float>();
  }
  
  // Add a steering behavior with a weight
  public void addBehavior(SteeringBehavior behavior, float weight) {
    behaviors.add(behavior);
    weights.add(weight);
  }
  
  // Remove a specific behavior
  public void removeBehavior(SteeringBehavior behavior) {
    int index = behaviors.indexOf(behavior);
    if (index >= 0) {
      behaviors.remove(index);
      weights.remove(index);
    }
  }
  
  // Clear all behaviors
  public void clearBehaviors() {
    behaviors.clear();
    weights.clear();
  }
  
  // Calculate the combined steering force from all behaviors
  public void calculateSteering() {
    if (behaviors.size() == 0) return;
    
    PVector totalForce = new PVector(0, 0);
    
    // Calculate weighted sum of all steering forces
    for (int i = 0; i < behaviors.size(); i++) {
      SteeringBehavior behavior = behaviors.get(i);
      float weight = weights.get(i);
      
      PVector force = behavior.calculateForce(owner);
      force.mult(weight);
      totalForce.add(force);
    }
    
    // Apply the resulting force to the owner
    owner.applyForce(totalForce);
  }
  
}