class Bullet extends PhysicsObject {
    private PImage bulletImage;
    private boolean active = true;
    private color bulletColor = color(255); // White bullet color
    
    public Bullet(PVector position, PVector velocity) {
        super(position, 0.1f); 
        this.velocity = velocity.copy();
        this.radius = 3.0f; // Small collision radius
        
        // Create a simple pixel-like bullet image
        bulletImage = createImage(3, 3, ARGB);
        bulletImage.loadPixels();
        for (int y = 0; y < bulletImage.height; y++) {
            for (int x = 0; x < bulletImage.width; x++) {
                // Create a small square with slightly rounded corners
                if ((x == 0 || x == bulletImage.width-1) && (y == 0 || y == bulletImage.height-1)) {
                    // Leave corners transparent for a slightly rounded look
                    bulletImage.pixels[y * bulletImage.width + x] = color(255, 0);
                } else {
                    bulletImage.pixels[y * bulletImage.width + x] = bulletColor;
                }
            }
        }
        bulletImage.updatePixels();
    }
    
    void update() {
        // Bullet moves in a straight line 
        position.add(velocity);
        
        // Check if bullet has gone off-screen
        if (isOffScreen()) {
            active = false;
        }
    }
    
    void draw() {
        if (!active) return;
        
        // Draw the bullet with a slight glow effect
        pushStyle();
        imageMode(CENTER);
        blendMode(ADD);
        noStroke();
        fill(bulletColor, 100);
        ellipse(position.x, position.y, 3, 3);
        image(bulletImage, position.x, position.y);
        popStyle();
    }
    
    boolean isOffScreen() {
        return position.x < 0 || position.x > width || position.y < 0 || position.y > height;
    }
    
    void deactivate() {
        active = false;
    }
    
    boolean isActive() {
        return active;
    }
}