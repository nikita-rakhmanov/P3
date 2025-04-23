class Platform {
  PImage img;

  Platform(String imgPath) {
    img = loadImage(imgPath);
  }

  void display() {
    for (int x = 0; x < width; x += img.width) {
      image(img, x, height - img.height);
    }
  }
}