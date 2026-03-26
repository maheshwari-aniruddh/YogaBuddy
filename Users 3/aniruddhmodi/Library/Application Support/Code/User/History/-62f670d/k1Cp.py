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
                             self.y = y.       sel        self.vy = random.uniform(-2, 2)
                                     self.color = random.choice(COLORS)
                             self.life = 255
                             self.size = random.randint(2, 6)
                             
                                 def update(self):
                                    self.x += self.vx
                                            self.y += self.vy
                                            self.vy += 0.05  # slight gravity
                                            self.life -= 2
                                            
                                                def draw(self, surface):
                                                  if self.life > 0:
                                                                    alpha_color = (*self.color, max(0, self.life))
                                                                                pygame.draw.circle(surface, self.color, (int(self.x), int(self.y)), self.size)
                                                                    
                                                                    particles = []
                                                                    clock = pygame.time.Clock()
                                                                    running = True
                                                                    # Main Loop
                                                                    while running:
                                                                               screen.fill(BLACK)
                                                                                   
                                                                                       for event in pygame.event.get():
                                                                                               if event.type == pygame.QUIT:
                                                                                                                   running = False.           
                                                                                                                       # Add new particles at the mouse position
                                                                                                                           mx, my = pygame.mouse.get_pos()
                                                                                                                       for _ in range(5):
                                                                                                                                   particles.append(Particle(mx, my))
                                                                                                                                           
                                                                                                                                               # Update and draw particles
                                                                                                                                                   for p in particles[:]:
                                                                                                                                                            p.update()
                                                                                                                                                                    p.draw(screen)
                                                                                                                                                                    if p.life <= 0:
                                                                                                                                                                                particles.remove(p)
                                                                                                                                                                                            
                                                                                                                                                                                                pygame.display.flip()
                                                                                                                                                                                    clock.tick(60)
                                                                                                                                                                                
                                                                                                                                                                                pygame.quit()
                                                                                                                                                                                
]