class DifficultyManager {
  private int difficultyLevel; // 1-5
  
  // Player parameters
  private float playerDamageMultiplier;
  private float playerHealthMultiplier;
  private float playerSpeedMultiplier;
  private float playerJumpMultiplier;
  
  // Enemy parameters
  private float enemyDamageMultiplier;
  private float enemyHealthMultiplier;
  private float enemySpeedMultiplier;
  private float enemyAttackSpeedMultiplier;
  private float enemyDetectionRangeMultiplier;
  private int maxEnemiesPerWave;
  private float enemySpawnRateMultiplier;
  
  // Collectible parameters
  private float ammoPickupFrequency;
  private float healthPickupFrequency;
  private int ammoPerPickup;
  private int healthPerPickup;
  
  private float collectibleDensity;
  
  // Constructor
  public DifficultyManager(int difficultyLevel) {
    this.difficultyLevel = constrain(difficultyLevel, 1, 5);
    
    // Initialize all multipliers based on difficulty
    updateParameters();
  }
  
  // Update all parameters based on the current difficulty level
  private void updateParameters() {
    // Convert difficulty to a normalized value between 0.0 and 1.0
    float normalizedDifficulty = (difficultyLevel - 1) / 4.0f;
    
    // Player parameters (higher values at LOWER difficulties)
    playerDamageMultiplier = map(normalizedDifficulty, 0, 1, 1.5f, 0.8f);
    playerHealthMultiplier = map(normalizedDifficulty, 0, 1, 1.5f, 0.8f);
    playerSpeedMultiplier = map(normalizedDifficulty, 0, 1, 1.2f, 0.9f);
    playerJumpMultiplier = map(normalizedDifficulty, 0, 1, 1.2f, 0.9f);
    
    // Enemy parameters (higher values at HIGHER difficulties)
    enemyDamageMultiplier = map(normalizedDifficulty, 0, 1, 0.7f, 1.5f);
    enemyHealthMultiplier = map(normalizedDifficulty, 0, 1, 0.7f, 1.5f);
    enemySpeedMultiplier = map(normalizedDifficulty, 0, 1, 0.8f, 1.4f);
    enemyAttackSpeedMultiplier = map(normalizedDifficulty, 0, 1, 0.8f, 1.3f);
    enemyDetectionRangeMultiplier = map(normalizedDifficulty, 0, 1, 0.7f, 1.3f);
    
    // Enemy spawn parameters
    maxEnemiesPerWave = (int)map(normalizedDifficulty, 0, 1, 1, 5);
    enemySpawnRateMultiplier = map(normalizedDifficulty, 0, 1, 0.5f, 1.5f);
    
    // Collectible parameters
    ammoPickupFrequency = map(normalizedDifficulty, 0, 1, 0.5f, 0.2f);
    healthPickupFrequency = map(normalizedDifficulty, 0, 1, 0.5f, 0.15f);
    ammoPerPickup = (int)map(normalizedDifficulty, 0, 1, 10, 3);
    healthPerPickup = (int)map(normalizedDifficulty, 0, 1, 40, 15);
    
    // Level generation parameter
    collectibleDensity = map(normalizedDifficulty, 0, 1, 0.4f, 0.15f);
  }
  
  // Getters for all parameters
  public int getDifficultyLevel() {
    return difficultyLevel;
  }
  
  public void setDifficultyLevel(int level) {
    difficultyLevel = constrain(level, 1, 5);
    updateParameters();
  }
  
  // Player parameter getters
  public float getPlayerDamageMultiplier() {
    return playerDamageMultiplier;
  }
  
  public float getPlayerHealthMultiplier() {
    return playerHealthMultiplier;
  }
  
  public float getPlayerSpeedMultiplier() {
    return playerSpeedMultiplier;
  }
  
  public float getPlayerJumpMultiplier() {
    return playerJumpMultiplier;
  }
  
  // Enemy parameter getters
  public float getEnemyDamageMultiplier() {
    return enemyDamageMultiplier;
  }
  
  public float getEnemyHealthMultiplier() {
    return enemyHealthMultiplier;
  }
  
  public float getEnemySpeedMultiplier() {
    return enemySpeedMultiplier;
  }
  
  public float getEnemyAttackSpeedMultiplier() {
    return enemyAttackSpeedMultiplier;
  }
  
  public float getEnemyDetectionRangeMultiplier() {
    return enemyDetectionRangeMultiplier;
  }
  
  // Enemy spawn parameter getters
  public int getMaxEnemiesPerWave() {
    return maxEnemiesPerWave;
  }
  
  public float getEnemySpawnRateMultiplier() {
    return enemySpawnRateMultiplier;
  }
  
  // Collectible parameter getters
  public float getAmmoPickupFrequency() {
    return ammoPickupFrequency;
  }
  
  public float getHealthPickupFrequency() {
    return healthPickupFrequency;
  }
  
  public int getAmmoPerPickup() {
    return ammoPerPickup;
  }
  
  public int getHealthPerPickup() {
    return healthPerPickup;
  }

  
  public float getCollectibleDensity() {
    return collectibleDensity;
  }
  
  // Helper method to get string representation of difficulty
  public String getDifficultyName() {
    switch(difficultyLevel) {
      case 1: return "Novice";
      case 2: return "Easy";
      case 3: return "Normal";
      case 4: return "Hard";
      case 5: return "Expert";
      default: return "Normal";
    }
  }
}