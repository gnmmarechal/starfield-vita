-- Starfield Vita
-- By gnmmarechal
--
--
-- http://gs2012.xyz
-- 
--
-- Wololo: gnmmarechal
-- GBATemp: gnmmarechal
-- Reddit: /u/gnmpolicemata
-- YouTube: https://youtube.com/gnmpolicemata
--
--
--
--

-- Set CPU clock to 444MHz
System.setCpuSpeed(444)

-- Init sound
Sound.init()
themeA = Sound.openMp3("app0:/sound/themeA.mp3")

running = true
-- Set PS Vita Resolution
local width = 960
local height = 544

-- Colours
local color = {
	white = Color.new(255,255,255),
	red = Color.new(255,0,0),
	yellow = Color.new(255,255,0),
	royalBlue = Color.new(65, 105, 225)
}


-- Important Variables
local score = 0
local lives = 3

local gameLoopCounter = 0;



-- Stars
local STARS = 100

-- Array for the stars to be stored
local newStars = {}
for i = 1, STARS, do
	newStars[i] = {}
	for j = 1, 3 do
		newStars[i][j] = 0
	end
end


-- Important functions

-- Game functions
function starfield()
	gameLoopCounter = gameLoopCounter + 1
	
	if gameLoopCounter == 1 then
		gameTimer = Timer.new()
	end
  
	for i = 1, STARS then
		Graphics.fillCircle(stars[i][1], stars[i][2], 5, white)
		
		stars[i][1] = stars[i][1] - stars[i][3];
		if newStars[i][1] < 0 then -- Spawn a new star for each star that goes out of the screen
			newStars[i][1] = math.random(width)
			newStars[i][2] = math.random(height)
			newStars[i][3] = math.sqrt(math.random(100))
		end
	end	
	
	
end


Sound.play(themeA, LOOP)
-- Starfield
while running do
	Graphics.initBlend()
	Screen.clear()
	--
	starfield()
	
	
	--
	Graphics.termBlend()
	Screen.flip()
	if Controls.check(Controls.read(), SCE_CTRL_START) then
		System.exit()
	end
	
end

Sound.term()
