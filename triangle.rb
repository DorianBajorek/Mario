  require 'ruby2d'

  set width: 1800
  set height: 600
  set background: 'white'
  isGame = true
  background = Image.new('background.jpg', width: 1800, height: 600, z: -1)
  $current_level = 1

  class Mario
    attr_reader :x, :y, :size, :jumping, :health_points, :score

    def initialize
      @x = 50
      @y = 450
      @size = 50
      @jumping = false
      @health_points = 3
      @score = 0
      @image = Image.new('mario.png', x: @x, y: @y, width: @size, height: @size, z: 10)
    end

    def reset_position
      @x = 50
      @y = 450
      @jumping = false
      @image.x = @x
      @image.y = @y
    end

    def move_right
      @x += 5
      @image.x = @x
    end

    def move_left
      @x -= 5
      @image.x = @x
    end

    def jump
      unless @jumping
        @jumping = true
        @y -= 220
        @image.y = @y
      end
    end

    def fall
      if @jumping
        @y += 5
        @image.y = @y
        @jumping = false if @y >= 500
      end
    end

    def go_down
      @y += 5
      @image.y = @y
    end

    def draw
      @image.add
    end

    def damage
      @x = 0
      @health_points -= 1
    end
    
    def get_health
      return health_points
    end

    def add_coin(value)
      @score += value
    end

    def get_score
      return score
    end

    def set_on_platform(x, platform)
      @x = x
      @y = platform.y - @size
      @jumping = false
      @image.x = @x
      @image.y = @y
    end

    def collision?(other)
      mario_bottom = @y + @size
      other_top = other.y
      @x < other.x + other.size &&
        @x + @size > other.x &&
        mario_bottom >= other_top &&
        mario_bottom <= other_top + other.size
    end
  end

  class Platform
    attr_reader :x, :y, :width, :height

    def initialize(x, y, width, height)
      @x = x
      @y = y
      @width = width
      @height = height
      @color = 'brown'
      @square = Rectangle.new(x: @x, y: @y, width: @width, height: @height, color: @color, z: 1)
    end

    def draw
      @square.add
    end
  end

  class Mob
    attr_reader :x, :y, :size, :direction, :left_bound, :right_bound 

    def initialize(platform)
      @size = 40
      @direction = :right
      reset_position(platform)
      @left_bound = platform.x
      @right_bound = platform.x + platform.width - size
      @image = Image.new('mob.png', x: @x, y: @y, width: @size, height: @size, z: 5)
    end

    def move
      if @x >= @right_bound
        @direction = :left
      elsif @x <= @left_bound
        @direction = :right
      end
      case @direction
      when :right
        @x += 2
      when :left
        @x -= 2
      end

      @image.x = @x
    end

    def reset_position(platform)
      @x = platform.x + rand(platform.width - @size)
      @y = platform.y - @size
    end

    def change_direction
      @direction = @direction == :right ? :left : :right
    end

    def draw
      @image.add
    end

    def collision?(other)
      mob_bottom = @y + @size
      other_top = other.y
      @x < other.x + other.size &&
        @x + @size > other.x &&
        mob_bottom >= other_top &&
        mob_bottom <= other_top + other.size
    end
  end

  class Coin
    attr_reader :x, :y, :size, :value

    def initialize(platform)
      @size = 50
      @value = 5
      reset_position(platform)
      @image = Image.new('coin.png', x: @x, y: @y, width: @size, height: @size, z: 5)
    end

    def reset_position(platform)
      @x = platform.x + rand(platform.width - @size)
      @y = platform.y - @size
    end

    def draw
      @image.add
    end

    def collision?(other)
      coin_bottom = @y + @size
      other_top = other.y
      @x < other.x + other.size &&
        @x + @size > other.x &&
        coin_bottom >= other_top &&
        coin_bottom <= other_top + other.size
    end

    def destroy
      @image = Image.new('coin.png', x: @x, y: @y, width: 0, height: @size, z: 5) #remove 
      @value = 0
    end

    def get_value
      return value
    end
  end

  class GreenBlock
    attr_reader :x, :y, :size

    def initialize(x, y, size)
      @x = x
      @y = y
      @size = size
      @color = 'green'
      @square = Rectangle.new(x: @x, y: @y, width: @size, height: @size, color: @color, z: 1)
    end

    def on_top?(mario)
      mario_bottom = mario.y + mario.size
      @x < mario.x + mario.size - 45 &&
        @x + @size > mario.x &&
        mario_bottom >= @y &&
        mario_bottom <= @y + @size
    end

    def draw
      @square.add
    end
  end
  green_block = GreenBlock.new(1750, 550, 50)

  def on_platform?(mario, platform)
    mario_bottom = mario.y + mario.size
    platform_top = platform.y
    mario.x < platform.x + platform.width &&
      mario.x + mario.size > platform.x &&
      mario_bottom >= platform_top &&
      mario_bottom <= platform_top + platform.height
  end

  def is_dead(mario)
    mario.y > 600 or mario.get_health == 0
  end

  mario = Mario.new

  def create_platforms_from_file(file_path)
    platforms = []

    File.open(file_path, 'r') do |file|
      file.each_line do |line|
        values = line.split(',').map(&:to_i)
        platforms << Platform.new(*values)
      end
    end

    return platforms
  end

  def create_mobs(platforms)
    mobs = []
    
    mobs << Mob.new(platforms[3])
    mobs << Mob.new(platforms[2])
    return mobs
  end

  def create_coins(platforms)
    coins = [
      Coin.new(platforms[1]),
      Coin.new(platforms[2])
    ]
    return coins
  end

  file_path = 'C:\Users\Dorian\Desktop\MarioGame\level1.txt'
  platforms = create_platforms_from_file(file_path)
  mobs = create_mobs(platforms)
  coins = create_coins(platforms)

  update do
    on_platform = false

    platforms.each do |platform|
      if on_platform?(mario, platform)
        mario.set_on_platform(mario.x, platform)
        on_platform = true
        break
      end
    end
    if $current_level == 2
      Text.new('WIN!!!', x: 700, y: 300, size: 50, color: 'red').add
    end
    if green_block.on_top?(mario)
      if $current_level == 1
        $current_level += 1
        puts $current_level
      end
      puts $current_level
      mario.set_on_platform(mario.x, green_block)
      on_platform = true
      sleep(1)
      on_platform = false
      file_path = 'C:\Users\Dorian\Desktop\MarioGame\level2.txt'
      platforms = create_platforms_from_file(file_path)
      mobs = create_mobs(platforms)
      coins = create_coins(platforms)
      mario.reset_position
    end
    mario.go_down unless on_platform

    mario.fall

    mobs.each do |mob|
      if mario.collision?(mob)
        puts 'Kolizja z mobem'
        mario.damage
      end
      mob.move
    end
    coins.each do |coin|
      if mario.collision?(coin)
        puts 'Kolizja z monetą'
        mario.add_coin(coin.get_value)
        coin.destroy
      end
    end

    clear
    background.draw
    Text.new("Health Points: #{mario.get_health}", x: 200, y: 200, size: 20, color: 'black').add
    Text.new("Score: #{mario.get_score}", x: 200, y: 220, size: 20, color: 'black').add
    platforms.each(&:draw)
    mario.draw
    green_block.draw
    coins.each(&:draw)
    mobs.each(&:draw)

    if is_dead(mario)
      Text.new('Game Over', x: 700, y: 300, size: 50, color: 'red').add
      isGame = false
    end
  end

  on :key do |event|
    case event.key
    when 'right'
      mario.move_right
    when 'left'
      mario.move_left
    when 'up'
      mario.jump
    when 'e'
      file_path = 'C:\Users\Dorian\Desktop\MarioGame\level2.txt'
      platforms = create_platforms_from_file(file_path)
      mario.reset_position
    when 'x'
      close
    end 
  end

  show