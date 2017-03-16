-- Starfield Vita
-- By gnmmarechal
--
--
-- http://gs2012.xyz
-- 
-- PSXScene: gnmmarechal
-- Wololo: gnmmarechal
-- GBATemp: gnmmarechal
-- Reddit: /u/gnmpolicemata
-- YouTube: https://youtube.com/gnmpolicemata
--
--
--
--

local debugMode = false
local debugAllowed = false
local verString = "Starfield Vita v0.2 - by gnmmarechal"

-- Set CPU clock to 444MHz
System.setCpuSpeed(444)
local FPS_TARGET = 60
local pad = Controls.read()
local oldpad = pad
System.createDirectory("ux0:/data")
System.createDirectory("ux0:/data/Starfield-Vita")

Socket.init()
-- Init sound
Sound.init()
themeA = Sound.openMp3("app0:/res/sound/bensound-scifi.mp3")

local running = true

-- GekiHEN Splash Screen
local splashScreen = Graphics.loadImage("app0:/res/img/splash.png")
local logoImage = Graphics.loadImage("app0:/res/img/logo.png")

local splashTimer = Timer.new()

while(Timer.getTime(splashTimer) <= 3000) do
	Graphics.initBlend()
	Screen.clear()
	--
	Graphics.drawImage(0, 0, splashScreen)
	--
	Graphics.termBlend()
	Screen.flip()
end
Timer.destroy(splashTimer)

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
local recordScore = 0
local scoreFilePath = "ux0:/data/Starfield-Vita/record.dat"
local lives = 3

local gameLoopCounter = 0
local lifeTakenTimer = Timer.new()
local lifeTaken = false
local curScene = 0

local shipCoords = {
	x = 40,
	y = math.floor(height/2) 
}


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

function readScore(scorePath)
	if System.doesFileExist(scorePath) then
		fileStream = io.open(scorePath ,FREAD)
		recordScore = tonumber(io.read(fileStream, io.size(fileStream)))
		io.close(fileStream)
	end	
end
function saveScore(scoreVar, scorePath)
	if System.doesFileExist(scorePath) then
		System.deleteFile(scorePath)
	end	
	fileStream = io.open(scorePath ,FCREATE)
	io.write(fileStream, scoreVar, string.len(tostring(scoreVar)))
	io.close(fileStream)	
end
local fps_counter = 0
local fps_timer = Timer.new()
local function reachedFPScap(x)
	fps_counter = fps_counter + 1
	local frameTime = 1000/x
	if Timer.getTime(fps_timer) >= frameTime then
		Timer.reset(fps_timer)
		fps_counter = 0
	end
	return (fps_counter >= x)
end

function drawPlayer(coordX, coordY)
	Graphics.fillRect(coordX - 9, coordX + 9, coordY - 4, coordY + 4, color.red) 
end

function getDist(x1, y1, x2, y2)
	return (math.sqrt(((x2-x1) * (x2-x1)) + ((y2-y1) * (y2-y1))))
end

-- Game functions
function updateServerScore(intScore)
	if Network.isWifiEnabled() then
		local skt  = Socket.connect("game.gs2012.xyz", 80)
		local payload = "GET /starfield-vita/SFVupdateScore.php?score="..intScore.."&user="..System.getUsername().." HTTP/1.1\r\nHost: game.gs2012.xyz\r\n\r\n"
		Socket.send(skt, payload)
	end
end

function gameOver()
	if score > recordScore then
		recordScore = score
		saveScore(recordScore, scoreFilePath)
		updateServerScore(recordScore)
	end
	score = 0
	lives = 3
	
	gameLoopCounter = 0
	lifeTakenTimer = Timer.new()
	lifeTaken = false
	curScene = 0
	for i = 1, STARS do
		newStars[i] = {width, math.random(height), math.sqrt(math.random(4))}
	end	
end
function gameMenu()
	Graphics.drawImage(210, 50, logoImage)
	Graphics.debugPrint(0, 0, verString, color.royalBlue)
	Graphics.debugPrint(0, 20, "Record: "..recordScore, color.royalBlue)
	Graphics.debugPrint(0, 40, "Press X to start", color.royalBlue)
	if Controls.check(pad, SCE_CTRL_CROSS) and (not Controls.check(oldpad, SCE_CTRL_CROSS)) then
		curScene = 1
		System.wait(100)
	end
end
function starfield()
	gameLoopCounter = gameLoopCounter + 1
	Graphics.debugPrint(0, 0, "Points: "..score, color.royalBlue)
	Graphics.debugPrint(0, 15, "Lives: "..lives, color.royalBlue)	
	if gameLoopCounter == 1 then
		gameTimer = Timer.new()
	end
	-- Draw Ship
	drawPlayer(shipCoords.x, shipCoords.y)
	
	-- Control ship (Analogs)
	analogX, analogY = Controls.readLeftAnalog()
	if analogY <= 120 then
		--shipCoords.y = shipCoords.y - (math.floor(analogY/20))
		if analogY <= 60 then
			valToChange = -2
		else
			valToChange = -1
		end
		shipCoords.y = shipCoords.y + valToChange
	end
	if analogY >= 135 then
		--shipCoords.y = shipCoords.y + (math.floor(analogY/20))
		if analogY >= 195 then
			valToChange = 2
		else
			valToChange = 1
		end
		shipCoords.y = shipCoords.y + valToChange		
	end
	if analogX <= 115 then
		--shipCoords.y = shipCoords.y - (math.floor(analogY/20))
		if analogX <= 120 then
			valToChange = -2
		else
			valToChange = -1
		end
		shipCoords.x = shipCoords.x + valToChange			
	end
	if analogX >= 140 then
		--shipCoords.y = shipCoords.y + (math.floor(analogY/20))
		if analogX >= 195 then
			valToChange = 2
		else
			valToChange = 1
		end
		shipCoords.x = shipCoords.x + valToChange	
	end	
	
	-- Control Ship (DPAD)
	if Controls.check(pad, SCE_CTRL_UP) then
		shipCoords.y = shipCoords.y - 1
	end
	if Controls.check(pad, SCE_CTRL_DOWN) then
		shipCoords.y = shipCoords.y + 1
	end
	if Controls.check(pad, SCE_CTRL_LEFT) then
		shipCoords.x = shipCoords.x - 1
	end
	if Controls.check(pad, SCE_CTRL_RIGHT) then
		shipCoords.x = shipCoords.x + 1
	end	
	if shipCoords.x <= 0 then
		shipCoords.x = 0
	end
	if shipCoords.x >= width then
		shipCoords.x = width
	end
	if shipCoords.y >= height then
		shipCoords.y = height
	end
	if shipCoords.y <= 0 then
		shipCoords.y = 0
	end
	if debugMode then
		Graphics.debugPrint(0, 30, "shipX: "..shipCoords.x.." shipY: "..shipCoords.y.." Analog X: "..analogX.." Analog Y: "..analogY, color.royalBlue)
	end
	-- Don't spawn stars for the first 5 seconds.
	if Timer.getTime(gameTimer) >= 5000 then
		for i = 1, STARS do
			Graphics.fillCircle(newStars[i][1], newStars[i][2], 4, color.white)
			
			newStars[i][1] = newStars[i][1] - newStars[i][3];
			if newStars[i][1] < 0 then -- Spawn a new star for each star that goes out of the screen
				newStars[i] = {width, math.random(height), math.sqrt(math.random(4))}
			end
			
			-- Check collision
			if (Timer.getTime(lifeTakenTimer) >= 300) then
				Timer.pause(lifeTakenTimer)
				Timer.reset(lifeTakenTimer)
				lifeTaken = false
			end
			if (getDist(newStars[i][1], newStars[i][2], shipCoords.x, shipCoords.y) <= 4) then
			
				if not lifeTaken then
					lives = lives - 1			
					if lives <= 0 then
						curScene = 2
					end	
					Timer.resume(lifeTakenTimer)
					lifeTaken = true
				end
			end
			

			
		end
		score = score + math.floor(Timer.getTime(gameTimer)/1000 * FPS_TARGET/60)
	else
		Timer.pause(lifeTakenTimer)
		Timer.reset(lifeTakenTimer)
	end
	
	
end
function game(scene)
	if scene == 0 then
		gameMenu()
	elseif scene == 1 then
		starfield()
	elseif scene == 2 then
		gameOver()
	end	
end

for i = 1, STARS do
	newStars[i] = {width, math.random(height), math.sqrt(math.random(4))}
end
Sound.play(themeA, LOOP)
-- Starfield


readScore(scoreFilePath)
local oldpad = Controls.read()
while running do

	while not reachedFPScap(FPS_TARGET) do
		local pad = Controls.read()
		Graphics.initBlend()
		Screen.clear()
		--
		game(curScene)
		--
		Graphics.termBlend()
		Screen.flip()
		
		
		if debugMode then
			if Controls.check(pad, SCE_CTRL_LTRIGGER) and (not Controls.check(oldpad, SCE_CTRL_LTRIGGER) then
				FPS_TARGET = FPS_TARGET - 1
				if FPS_TARGET <= 0 then
					FPS_TARGET = 1
				end
			end
			if Controls.check(pad, SCE_CTRL_RTRIGGER) and (not Controls.check(oldpad, SCE_CTRL_RTRIGGER) then
				FPS_TARGET = FPS_TARGET + 1
			end
		end
		
		if Controls.check(pad, SCE_CTRL_SELECT) and debugAllowed and (not Controls.check(oldpad, SCE_CTRL_SELECT) then
			debugMode = not debugMode
		end
		if Controls.check(pad, SCE_CTRL_START) and (not Controls.check(oldpad, SCE_CTRL_START)) then
			System.takeScreenshot("ux0:/data/file.jpg", true, 0)
		end
		oldpad = pad		
	end
	

end

Sound.term()
Socket.term()
System.exit()
