import java.awt.Point;

// Instance variables
GObject ship; // index of all active physics objects
PImage img; // physics object render image
boolean mouseFollow; // state flag
boolean looseFollow; // state flag
boolean hyperspace; // state flag
boolean hs_toggle; // state flag
color hColor; // HS label color state tracker
HashMap<Integer, Boolean> keyHeld; // index of all currently held-down keycodes

// Constants
static final int SIZE = 50; // size of the object
static final float MAX_TRACKING_VELOCITY = 2.0f; // maximum keyboard input tracking velocity
static final float ACCELERATION = 0.05f; // constant acceleration while under input
static final float INERTIA_DAMPENING = 0.01f; // negative acceleration while not under input
static final float DAMPENING_THRESHOLD = 0.1f; // how close the object has to be to the mouse cursor
                                               // (in fractions of the screen size) to start slowing down
static final float STOP_THRESHOLD = 0.005f; // how close the object has to be to the cursor to stop completely
static final float HYPERSPACE_VELOCITY = 1000.0f; //things

void setup()
{
  // Set canvas size and background color
  size(1280, 1024);
  background(color(0));
  
  // Load object image and initialize keyboard input tracking map
  img = loadImage("ship.png");
  keyHeld = new HashMap<Integer, Boolean>();
  
  // Initialize state variables
  mouseFollow = false;
  looseFollow = true;
  hyperspace = false;
  hs_toggle = false;
  hColor = color(0, 0, 0);
  
  // Create ship physics object
  ship = new GObject(0.0f, img, 400, 100, SIZE, SIZE);
}

void draw()
{
  // Clear the screen
  background(color(0));
  
  // Draw help text
  textSize(12);
  fill(color(255));
  text(String.format("Current input mode: %s", mouseFollow ? "mouse/" + 
      (looseFollow ? "loose-follow" : "tight-follow") + "\nLeft-click: loose follow\nRight-click: tight follow" : 
      "keyboard\nArrow keys: move\nSpacebar: Hyperspace Drive™"), 0, 0, width, height);
  
  // Hyperspace feedback
  textSize(72);
  fill(hColor);
  if(hyperspace) text("HYPERSPACE\nENGAGED!", width / 2, height / 2, width, height);
  hColor += 24;
  if(hColor > color(255, 255, 255)) hColor = color(0, 0, 0);
  
  // Render the ship object, calculate collision detection, and account for user input
  ship.render();
  ship.calculateCollision(width, height);
  calculateDelta(ship);
}

/**
 * Delegate to the proper input calculation method for the current input mode.
 */
void calculateDelta(GObject g)
{
  if(mouseFollow) calculateDM(g);
  else calculateDK(g);
}

void calculateDM(GObject g)
{  
  // Get distance from the mouse cursor, and the signs of said distances
  float[] relCoords = objectDist(g);
  int[] boosts = getBoostDir(g);
  
  // Give the object a push towards the mouse cursor
  g.velocityDelta(ACCELERATION * boosts[0], ACCELERATION * boosts[1]);
  
  // Return if loose follow mode is engaged
  if(looseFollow) return;
  
  // If loose follow is not engaged, get the decimal distance from the cursor
  float multX = relCoords[0] / width;
  float multY = relCoords[1] / height;
  
  // Stop the ship in one or both axes if it is close to the cursor in that axis
  if(multX < STOP_THRESHOLD) g.setVelocity(0.0f, g.getVelocity()[1]);
  if(multY < STOP_THRESHOLD) g.setVelocity(g.getVelocity()[0], 0.0f);
}

void calculateDK(GObject g)
{
  boolean noInput = false;
  
  // Hyperspace commands
  if(keyHeld(' '))
  {
    if(hs_toggle) g.setVelocity(HYPERSPACE_VELOCITY, g.getVelocity()[1]);
    else g.setVelocity(-HYPERSPACE_VELOCITY, g.getVelocity()[1]);
    hs_toggle = !hs_toggle;
    
    hyperspace = true;
    return;
  }
  
  // Set X axis acceleration
  if(keyHeld(LEFT)) g.velocityDelta(-ACCELERATION, 0.0f);
  else if(keyHeld(RIGHT)) g.velocityDelta(ACCELERATION, 0.0f);
  else noInput = true;
  
  // Set Y axis acceleration. If none of the four buttons is pressed, apply braking force to the object.
  if(keyHeld(UP)) g.velocityDelta(0.0f, -ACCELERATION);
  else if(keyHeld(DOWN)) g.velocityDelta(0.0f, ACCELERATION);
  else if(noInput) applyInertiaDampening(g);
}

void applyInertiaDampening(GObject g, int... axes)
{
  float[] velocity = g.getVelocity();
    
  // Apply inertia cancellation to each specified velocity axis
  for(int i : axes)
  {
    float tmp = Math.abs(velocity[i]);
    if(tmp == 0.0f) continue;
    tmp -= INERTIA_DAMPENING;
    tmp = tmp < 0.0f ? tmp = 0.0f : tmp;
    velocity[i] = velocity[i] < 0.0f ? -tmp : tmp;
  }
  
  g.setVelocity(velocity[0], velocity[1]);
}

boolean keyHeld(int code){
  return keyHeld.get(code) != null && keyHeld.get(code);
}

/**
 * Get the distance from the active object to the mouse cursor.
 */ 
float[] objectDist(GObject g)
{
  Point gc = g.getCoordinates();
  
  // Check to see how far this object is from the cursor
  float diffX = Math.abs(mouseX - gc.x);
  float diffY = Math.abs(mouseY - gc.y);
  
  // Average the two distance values
  float distance = (diffX + diffY) / 2.0f;
  
  return new float[]{diffX, diffY, distance};
}

/**
 * 
 */
int[] getBoostDir(GObject g)
{
  // Determine whether the mouse cursor is positive, negative, or equal relative to the object
  // in the specified axis, and return the appropriate multiplier.
  return new int[]{mouseX <= g.getCoordinates().x ? mouseX == g.getCoordinates().x ? 0 : -1 : 1, 
                   mouseY <= g.getCoordinates().y ? mouseY == g.getCoordinates().y ? 0 : -1 : 1};
}

void mousePressed()
{
  // Enable mouse follow when the mouse is pressed, and clear keyboard hold states
  mouseFollow = true;
  for(int i : keyHeld.keySet()) keyHeld.put(i, false);
  if(mouseButton == LEFT) looseFollow = true;
  else looseFollow = false;
}

void keyPressed()
{
  // Reset the scene if the enter key is pressed
  if(keyCode == ENTER || keyCode == RETURN) ship.reset();
  if(mouseFollow) mouseFollow = false;
  keyHeld.put(keyCode, true); //<>//
}

void keyReleased()
{
  keyHeld.put(keyCode, false);
  
  // Reset object if the hyperspace key is released
  if(key == ' '){
    ship.reset();
    hyperspace = false;
  }
}


class GObject
{
  // Public physics constants
  public static final float Y_IMPACT_PENALTY = 2.0f;
  public static final float X_IMPACT_PENALTY = 2.0f;
  public static final float FRICTION_PENALTY = 0.0f;
  
  // Internal properties
  private PImage graphic; // the image used for this object
  private Point initialCoords; // starting coordinates used for reset
  private Point currentCoords; // current active coordinates
  private float gravity; // gravitational constant
  private float[] velocity; // current instantaneous velocity
  private boolean hasInput; // if the object is currently under the control of a user input method
  private boolean atRest; // is this object resting against the Y+ boundary, used to prevent
                          // the object spazzing out when it comes to a stop due to gravity
  
  /**
   * Constructs a new physics object.
   * @param gravity the constant gravitational acceleration this object should experience,
   *                in PPF^2 (pixels per frame squared). Values below 0 will be negated.
   * @param graphic the image to display on this physics object
   * @param x the initial X coordinate for this object
   * @param y the initial Y coordinate for this object
   * @param w the width that the provided graphic should be resized to. Values less than or equal to 0 will
              be ignored, and the image's original size will be used instead.
   * @param w the height that the provided graphic should be resized to. Values less than or equal to 0 will
              be ignored, and the image's original size will be used instead.
   */
  public GObject(float gravity, PImage graphic, int x, int y, int w, int h)
  {
    this.gravity = gravity < 0.0f ? -gravity : gravity;
    this.graphic = graphic;
    this.initialCoords = new Point(x, y);
    this.currentCoords = new Point(x, y);
    this.atRest = false;
    
    if(w > 0 && h > 0) graphic.resize(w, h);
    velocity = new float[2];
  }
  
  /**
   * Draws this object to canvas, and updates its internal position, velocity, and gravity calculations.
   */
  public void render()
  {
    // Draw image
    image(graphic, currentCoords.x, currentCoords.y);
    
    // Update next draw coordinates with the current velocity
    currentCoords.x += velocity[0];
    currentCoords.y += velocity[1];
    
    // Account for gravitational acceleration in the Y-axis if the object has not come to a stop in the Y-axis
    if(!atRest) velocity[1] += gravity;
    else{
      // Account for friction in the X-axis if the object has come to a rest along the Y-axis
      float tmp = velocity[0];
      if(Math.abs(tmp) - FRICTION_PENALTY >= 0) tmp -= tmp > 0 ? FRICTION_PENALTY : -FRICTION_PENALTY;
      else tmp = 0.0f;
      velocity[0] = tmp;
    }
  }
  
  /**
   * Calculates collision with the edge of the canvas, and updates velocities accordingly.
   * In a "real-time" simulation, this should be called directly <i>before</i> {@link #render()} is called.
   */ 
  public void calculateCollision(float w, float h)
  {
    // voodoo magic code, do not touch
    if(currentCoords.x + graphic.width >= w) // X+
    { 
      float tmp = velocity[0];
      tmp -= X_IMPACT_PENALTY * 2;
      tmp = tmp < 0.0f ? 0.0f : tmp;
      tmp = -tmp;
      velocity[0] = tmp;
      currentCoords.x = (int)(w - (graphic.width + 1.0f));
    }else if(currentCoords.x <= 0) // X-
    { 
      float tmp = velocity[0];
      tmp += X_IMPACT_PENALTY * 2;
      tmp = tmp > 0.0f ? 0.0f : tmp;
      tmp = -tmp;
      velocity[0] = tmp;
      currentCoords.x = 1;
    }
    
    if(currentCoords.y + graphic.height > h) // Y+
    {
      float tmp = velocity[1];
      tmp -= Y_IMPACT_PENALTY * 2;
      tmp = tmp < 0.0f ? 0.0f : tmp;
      if(tmp == 0.0f) atRest = true;
      tmp = -tmp;
      velocity[1] = tmp;
      currentCoords.y = (int)(h - (graphic.height + 1.0f));
    }else if(currentCoords.y <= 0) // Y-
    {
      float tmp = velocity[1];
      tmp += Y_IMPACT_PENALTY * 2;
      tmp = tmp > 0.0f ? 0.0f : tmp;
      tmp = -tmp;
      velocity[1] = tmp;
      currentCoords.y = 1;
    }
  }
  
  /**
   * Gets the gravitational constant being applied to this object, in PPF^2 (pixels per frame squared).
   */
  public float getGravity(){
    return gravity;
  }
  
  /**
   * Sets the gravitational constant for this object, where 0 is floating with no gravity.
   * @param gravity the gravitational constant to be applied to this object, in PPF^2 (pixels per frame squared)
   */
  public void setGravity(float gravity){
    this.gravity = gravity;
  }
  
  /**
   * Gets the current instantaneous velocity of this object in the X,Y axes.
   * @returns a length-2 array containing this object's velocities in the [x,y] axes, in that order
   */ 
  public float[] getVelocity(){
    return new float[]{velocity[0], velocity[1]};
  }
  
  /**
   * Gets this object's current X,Y coordinates.
   */
  public Point getCoordinates(){
    return new Point(currentCoords.x, currentCoords.y);
  }
  
  /**
   * Sets the current instantaneous velocity of this object to the specified X,Y values.
   * @param x the horizontal velocity of this object
   * @param y the vertical velocity of this object (note: affected by gravity unless setGravity(0.0f) is called)
   */
  public void setVelocity(float x, float y){
    this.velocity[0] = x;
    this.velocity[1] = y;
    if(y > 0.0f) atRest = false;
  }
  
  /**
   * Adds the specified amount of momentum to this object in the X,Y axes.
   * @param x the velocity to add to this object in the horizontal axis
   * @param y the velocity to add to this object in the vertical axis (note: affected by gravity unless setGravity(0.0f) is called)
   */
  public void velocityDelta(float x, float y){
    this.velocity[0] += x;
    this.velocity[1] += y;
    if(atRest && Math.abs(y) > 0.0f) atRest = false;
  }
  
  /**
   * Resets this object to its original position, and negates any velocity it may have had.
   * Does not update its actual position until render() is called.
   */
  public void reset()
  {
    velocity[0] = 0.0f;
    velocity[1] = 0.0f;
    currentCoords.x = initialCoords.x;
    currentCoords.y = initialCoords.y;
    atRest = false;
  }
}
