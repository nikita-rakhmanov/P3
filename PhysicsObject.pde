// Add this field to the PhysicsObject class
class PhysicsObject {
    PVector position;
    PVector velocity;
    PVector acceleration;
    PVector forceAccum;  
    float mass;
    float radius; // For collision detection
    float friction = 0.7; // Friction coefficient to reduce sliding
    boolean isStatic = false; // Flag to identify static objects like platforms and springs

    PhysicsObject(PVector position, float mass) {
        this.position = position.copy();
        this.velocity = new PVector(0, 0);
        this.acceleration = new PVector(0, 0);
        this.forceAccum = new PVector(0, 0);  
        this.mass = mass;
        this.radius = 20; 
    }

    void applyForce(PVector force) {
        // Don't apply forces to static objects
        if (isStatic) return;
        
        // Add force to accumulator instead of directly affecting acceleration
        PVector f = force.copy();
        forceAccum.add(f);
    }
    
    // Clear accumulated forces
    void clearForces() {
        forceAccum.set(0, 0);
    }

    void update() {
        // Static objects don't move
        if (isStatic) return;
        
        // Calculate acceleration from accumulated forces
        acceleration = PVector.div(forceAccum, mass);
        
        // Update velocity with acceleration
        velocity.add(acceleration);
        
        // Apply friction to reduce sliding
        velocity.mult(friction);
        
        // Update position with velocity
        position.add(velocity);
        
        // Clear forces for the next update
        clearForces();

        // Boundary checks to keep the object within the screen
        if (position.x < radius) {
            position.x = radius;
            velocity.x = 0; // Stop horizontal velocity when hitting the boundary
        } else if (position.x > width - radius) {
            position.x = width - radius;
            velocity.x = 0; // Stop horizontal velocity when hitting the boundary
        }

        if (position.y < radius) {
            position.y = radius;
            velocity.y = 0; // Stop vertical velocity when hitting the boundary
        } else if (position.y > height - radius) {
            position.y = height - radius;
            velocity.y = 0; // Stop vertical velocity when hitting the boundary
        }
    }

    void display() {
        // Override this to display the object
    }

    boolean isColliding(PhysicsObject other) {
        float distance = PVector.dist(this.position, other.position);
        return distance < this.radius + other.radius;
    }

    void resolveCollision(PhysicsObject other) {
        // If both objects are static, no collision resolution is needed
        if (this.isStatic && other.isStatic) return;
        
        PVector collisionNormal = PVector.sub(other.position, this.position).normalize();
        PVector relativeVelocity = PVector.sub(other.velocity, this.velocity);
        float separatingVelocity = PVector.dot(relativeVelocity, collisionNormal);

        if (separatingVelocity > 0) return;

        float newSeparatingVelocity = -separatingVelocity;
        float totalInverseMass = 1/this.mass;
        
        // If the other object is static, only move this object
        if (other.isStatic) {
            // Push the non-static object away from the static object
            PVector separationVector = PVector.mult(collisionNormal, this.radius + other.radius - PVector.dist(this.position, other.position));
            this.position.sub(separationVector);
            
            // Reflect velocity for the non-static object only
            this.velocity.add(PVector.mult(collisionNormal, -2 * PVector.dot(this.velocity, collisionNormal)));
            this.velocity.mult(0.7); // damping
            return;
        }
        
        // If this object is static, only move the other object
        if (this.isStatic) {
            // Push the non-static object away from the static object
            PVector separationVector = PVector.mult(collisionNormal, this.radius + other.radius - PVector.dist(this.position, other.position));
            other.position.add(separationVector);
            
            // Reflect velocity for the non-static object only
            other.velocity.add(PVector.mult(collisionNormal, -2 * PVector.dot(other.velocity, collisionNormal)));
            other.velocity.mult(0.7); // Add some damping
            return;
        }
        
        // If neither is static (both objects move)
        totalInverseMass += 1/other.mass;
        
        float impulse = newSeparatingVelocity / totalInverseMass;
        PVector impulseVector = PVector.mult(collisionNormal, impulse);
        
        // Apply impulse proportionally based on mass
        this.velocity.add(PVector.div(impulseVector, this.mass));
        other.velocity.sub(PVector.div(impulseVector, other.mass));
    }

    public float getRadius() {
        return radius;
    }
    
    public boolean isStatic() {
        return isStatic;
    }
    
    public void setStatic(boolean isStatic) {
        this.isStatic = isStatic;
    }
}