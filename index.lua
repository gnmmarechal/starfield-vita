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
--themeA = Sound.openMp3("app0:/sound/themeA.mp3")

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
local STARS = 50

-- Array for the stars to be stored
local newStars = {}
for i = 1, STARS do
	newStars[i] = {}
	for j = 1, 3 do
		newStars[i][j] = 0
	end
end


-- Important functions
local fps_counter = 0
local fps_timer = Timer.new()
local function reachedFPScap(x)
	fps_counter = fps_counter + 1
	if Timer.getTime(fps_timer) >= 1000 then
		Timer.reset(fps_timer)
		fps_counter = 0
	end
	return (fps_counter >= x)
end


-- Game functions
function starfield()
	gameLoopCounter = gameLoopCounter + 1
	
	if gameLoopCounter == 1 then
		gameTimer = Timer.new()
	end
  
	for i = 1, STARS do
		Graphics.fillCircle(newStars[i][1], newStars[i][2], 4, color.white)
		
		newStars[i][1] = newStars[i][1] - newStars[i][3];
		if newStars[i][1] < 0 then -- Spawn a new star for each star that goes out of the screen
			newStars[i] = {width, math.random(height), math.sqrt(math.random(100))}
		end
	end	
	
	
end


for i = 1, STARS do
	newStars[i] = {width, height, math.random(10)}
end
--Sound.play(themeA, LOOP)
-- Starfield



while running do

	while not reachedFPScap(10) do
		Graphics.initBlend()
		Screen.clear()
		--
		starfield()
		
		
		--
		Graphics.termBlend()
		Screen.flip()
		if Controls.check(Controls.read(), SCE_CTRL_START) then
			running = false
		end
	end
end

Sound.term()
System.exit()
