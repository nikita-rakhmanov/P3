# How to Run the Game

- Make sure you have Processing installed on your computer
- Make sure you have the Processing Sound library installed (you can do this from the Processing IDE by going to Sketch > Import Library > Add Library and searching for "Sound")
- Open the P1.pde file in the Processing IDE
- Click the "Run" button or press Ctrl+R (Cmd+R on Mac)

# Gameplay Guide

## Objective

- Navigate through procedurally generated levels
- Defeat enemies in your path
- Collect ammo boxes to shoot projectiles
- Collect coins and reach exits to progress
- Defeat the final boss in Level 3
- Complete the game as quickly as possible

## Controls

- A/D - Move left/right
- W - Jump
- SPACE - Attack (melee)
- SHIFT - Glide (while in the air)
- LEFT MOUSE BUTTON - Shoot projectiles (requires ammo)
- R - Restart the game (after game over)
- ENTER - Start the game 
- M - Mute/Unmute the music

## Camera Controls

- 1 - Switch to default camera view
- 2 - Switch to player-following camera view

## Debug Visualization

- G - Toggle grid visualization for pathfinding
- P - Toggle path visualization to see enemy navigation paths

## Game Elements

- **Character**: You control a samurai with melee and ranged attacks
- **Enemies**: 
  - Four assassin types with different AI behaviors in Level 1
  - Spearmen enemies in Level 2 with extended attack range
  - Boss Demon in Level 3 with high health and powerful attacks
- **Springs**: Bounce on these to reach higher platforms
- **Platforms**: Navigate these to climb upward
- **Ammo Boxes**: Blue glowing boxes that give you 5 projectiles each
- **Health Packs**: Green glowing items that restore 25 health points
- **Golden Coin**: Collect this after defeating all enemies to progress in Level 1
- **Level Exits**: Reach these to progress to the next level
- **Procedural Backgrounds**: Each level features a unique procedurally generated background

## Level Structure

- **Level 1**: Procedurally generated platformer level with vertical progression
- **Level 2**: Dynamic arena with procedurally spawning enemies and items
- **Level 3**: Boss battle with procedural ASCII background

## Difficulty Selection

At the start of the game, choose from five difficulty levels:
- Very Easy: Reduced enemy health, damage, and spawn rates with more pickups
- Easy: Slightly reduced enemy attributes
- Normal: Balanced gameplay experience
- Hard: Increased enemy health, damage, and spawn rates with fewer pickups
- Very Hard: Significantly enhanced enemy attributes and minimal resources

## Gameplay Tips

- Use the springs strategically to reach higher platforms
- You can defeat enemies using either melee attacks (SPACE) or ranged attacks (LEFT MOUSE)
- The glide ability (SHIFT) helps with horizontal movement while airborne
- Watch your health - it appears in the top left corner
- Collect ammo boxes to shoot projectiles - use them wisely!
- You must defeat ALL enemies before you can collect the coin or activate the exit
- After defeating all enemies, reach the level exit to progress

## Level-Specific Tips

### Level 1:
- Focus on vertical traversal
- Clear each platform of enemies before progressing upward
- Use springs to access higher platforms that might be out of normal jump range

### Level 2:
- Enemies spawn in waves - be prepared for continuous combat
- Items appear throughout the level - prioritize collecting them
- Position yourself strategically to handle enemies approaching from both sides

### Level 3 (Boss Fight):
- The boss has a large health bar at the top of the screen
- Dodge the boss's powerful attacks which have wide range
- Use a combination of melee and ranged attacks
- Watch for patterns in the boss's movement and attacks
- Time your attacks during the boss's recovery periods

## Enemy Type Strategies

- **Aggressive Enemies (Type 1):** These enemies will relentlessly pursue you. Use vertical movement to your advantage as they struggle with platform navigation. Get into positions where you can attack from far.

- **Mixed-Behavior Enemies (Type 2):** These enemies are slower and more focused on patrolling. Time your attacks when they're less focused on you.

- **Platform-Bound Enemies (Type 3):** These enemies stay on their platforms. Use ranged attacks to deal with them safely from a distance, or time your approach when they're moving away from your landing spot.

- **Evasive Enemies (Type 4):** These enemies maintain distance and are difficult to corner. Use the spring platforms to gain height advantage, then glide down for surprise attacks when they're retreating.

- **Spearmen (Level 2):** These enemies have longer attack range than assassins. Keep more distance when engaging them, and use ranged attacks when possible.

- **Boss Demon (Level 3):** The boss has high health, powerful attacks, and more aggressive behavior. Use the entire arena space to maneuver, and strike during its attack recovery periods.


## Credits:
- Graphics from "CharacterPack" and "PixelArt_Samurai" asset packs on itch.io [(https://itch.io/)]
- Music composed by me 
- Boss character from "Boss Demon" asset pack 

**Enjoy the game!**