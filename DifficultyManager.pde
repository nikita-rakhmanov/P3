class DifficultyManager {
  // Difficulty level (1-5)
  private int difficultyLevel = 3; // Default is medium
  
  // Enemy scaling factors
  private float enemyCountScale = 1.0f;
  private float enemySpawnRateScale = 1.0f;
  private float enemyHealthScale = 1.0f;
  private float enemyDamageScale = 1.0f;
  private float enemySpeedScale = 1.0f;  // New variable for enemy speed scaling
  
  // Pickup scaling factors
  private float ammoSpawnChanceScale = 1.0f;
  private float healthSpawnChanceScale = 1.0f;
  
  DifficultyManager() {
    // Initialize with default medium difficulty
    setDifficultyLevel(3);
  }
  
  DifficultyManager(int level) {
    setDifficultyLevel(level);
  }
  
  void setDifficultyLevel(int level) {
    // Clamp difficulty between 1-5
    difficultyLevel = constrain(level, 1, 5);
    
    // Recalculate scaling factors based on difficulty
    calculateScalingFactors();
  }
  
  private void calculateScalingFactors() {
    // Convert difficulty from 1-5 scale to 0.0-1.0 for calculations
    float normalizedDifficulty = (difficultyLevel - 1) / 4.0f;
    
    // Enemy count scales non-linearly with difficulty
    // Easy (1): 1-2 enemies, Hard (5): 5-7 enemies
    enemyCountScale = map(normalizedDifficulty, 0, 1, 0.3f, 2.0f);
    
    // Spawn rate increases with difficulty (enemies spawn faster)
    // Easy: 0.7x spawn rate, Hard: 1.5x spawn rate
    enemySpawnRateScale = map(normalizedDifficulty, 0, 1, 0.7f, 2.0f);
    
    // Enemy health scales with difficulty
    // Easy: 0.8x health, Hard: 1.5x health
    enemyHealthScale = map(normalizedDifficulty, 0, 1, 0.8f, 1.5f);
    
    // Enemy damage scales with difficulty
    // Easy: 0.7x damage, Hard: 1.3x damage
    enemyDamageScale = map(normalizedDifficulty, 0, 1, 0.7f, 1.3f);
    
    // Enemy speed scales with difficulty
    // Easy: 0.8x speed, Hard: 1.4x speed
    enemySpeedScale = map(normalizedDifficulty, 0, 1, 0.8f, 1.4f);
    
    // Pickup spawn chances scale inversely with difficulty
    // Easy: 1.5x more pickups, Hard: 0.7x fewer pickups
    ammoSpawnChanceScale = map(normalizedDifficulty, 0, 1, 1.5f, 0.7f);
    healthSpawnChanceScale = map(normalizedDifficulty, 0, 1, 1.5f, 0.7f);
  }
  
  // Getters for scaling factors
  int getDifficultyLevel() { return difficultyLevel; }
  
  // Calculate actual enemy count for spawner
  int getScaledEnemyCount(int baseCount) {
    return max(1, round(baseCount * enemyCountScale));
  }
  
  // Calculate actual spawn delay
  long getScaledSpawnDelay(long baseDelay) {
    return round(baseDelay / enemySpawnRateScale);
  }
  
  // Calculate scaled health for enemies
  int getScaledEnemyHealth(int baseHealth) {
    return round(baseHealth * enemyHealthScale);
  }
  
  // Calculate scaled damage for enemies
  int getScaledEnemyDamage(int baseDamage) {
    return round(baseDamage * enemyDamageScale);
  }
  
  // Calculate scaled speed/acceleration for enemies
  float getScaledEnemySpeed(float baseSpeed) {
    return baseSpeed * enemySpeedScale;
  }
  
  // Calculate scaled ammo spawn chance
  float getScaledAmmoSpawnChance(float baseChance) {
    return constrain(baseChance * ammoSpawnChanceScale, 0, 1);
  }
  
  // Calculate scaled health spawn chance
  float getScaledHealthSpawnChance(float baseChance) {
    return constrain(baseChance * healthSpawnChanceScale, 0, 1);
  }
  
  // Get difficulty name for display
  String getDifficultyName() {
    switch(difficultyLevel) {
      case 1: return "Easy";
      case 2: return "Normal";
      case 3: return "Medium";
      case 4: return "Hard";
      case 5: return "Expert";
      default: return "Medium";
    }
  }
  
  // Get the raw enemy damage scale factor (useful for debugging)
  float getRawEnemyDamageScale() {
    return enemyDamageScale;
  }
  
  // Get the raw enemy speed scale factor (useful for debugging)
  float getRawEnemySpeedScale() {
    return enemySpeedScale;
  }
}