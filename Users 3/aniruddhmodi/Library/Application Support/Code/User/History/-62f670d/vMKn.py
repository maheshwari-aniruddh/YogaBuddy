 random
import math
# Initialize Pygame
pygame.init()

# Setup display
WIDTH, HEIGHT = 800, 600
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Particle Swarm")

# Colors
BLACK = (10, 10, 15)
COLORS = [
     (255, 100, 100), (100, 255, 100), (100, 100, 255),
         (255, 255, 100), (255, 100, 255), (100, 255, 255)
]

class Particle:
        def __init__(self, x, y):
                     self.x = x
                             self.y = y.       sel
]