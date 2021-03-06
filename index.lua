-- Starfield Vita
-- By gnmmarechal
--
--
-- http://gs2012.xyz
-- 
-- PSX-Place: gnmmarechal
-- Wololo: gnmmarechal
-- GBATemp: gnmmarechal
-- Reddit: /u/gnmpolicemata
-- YouTube: https://youtube.com/gnmpolicemata
--
--
--
--

System.setCpuSpeed(444)
Socket.init()
Sound.init()


-- Basic Settings
local debugMode = false
local debugAllowed = false
local verString = "Starfield Vita v0.2.1 - by gnmmarechal"
local FPS_TARGET = 60
local Display = {
	width = 960,
	height = 544
}
local Default = {
	splashTime = 3000,
	release = 1,
	lives = 3,
	MAX_STARS = 50,
	score = 0,
	startingScene = 0,
	scoreFilePath = "ux0:/data/Starfield-Vita/record.dat",
	username = "ERROR"
}

local Resources = {
	sound = {
		bgm1 = Sound.openMp3("app0:/res/sound/bensound-scifi.mp3")
	}
	image = {
		splashScreen = Graphics.loadImage("app0:/res/img/splash.png"),
		logoImage = Graphics.loadImage("app0:/res/img/logo.png")
	}
}
local rel = Default.release
-- Colours
local color = {
	white = Color.new(255,255,255),
	red = Color.new(255,0,0),
	yellow = Color.new(255,255,0),
	royalBlue = Color.new(65, 105, 225)
}

System.createDirectory("ux0:/data")
System.createDirectory("ux0:/data/Starfield-Vita")
local pad = Controls.read()
local oldpad = pad
local running = true
local worldScore = Default.score
local worldPerson = Default.username
local score = Default.score
local recordScore = Default.score
local lives = Default.lives
local gameLoopCounter = 0
local lifeTakenTimer = Timer.new()
local lifeTaken = false
local curScene = Default.startingScene
local shipCoords = {
	x = 40,
	y = math.floor(Display.height/2) 
}

Sound.play(Resources.sound.bgm1, LOOP)

-- Splash Screen
local splashTimer = Timer.new()
while(Timer.getTime(splashTimer) <= Default.splashTime) do
	Graphics.initBlend()
	Screen.clear()
	--
	Graphics.drawImage(0, 0, splashScreen)
	--
	Graphics.termBlend()
	Screen.flip()
end
Timer.destroy(splashTimer)

-- Array for the stars to be stored
local newStars = {}
for i = 1, Default.MAX_STARS do
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
function explode(div,str) -- Splits a string into a table, with div as the delimiter and str as the string.
    if (div=='') then return false end
    local pos,arr = 0,{}
    for st,sp in function() return string.find(str,div,pos,true) end do
        table.insert(arr,string.sub(str,pos,st-1))
        pos = sp + 1
    end
    table.insert(arr,string.sub(str,pos))
    return arr
end
function getServerInfo(var) -- Returns a value from the server (score, username, etc.)
	retVal = "Connection?"
	if Network.isWifiEnabled() then
		local skt = Socket.connect("game.gs2012.xyz", 80)
		local payload = "GET /starfield-vita/index.php?"..var.." HTTP/1.1\r\nHost: game.gs2012.xyz\r\n\r\n"
		Socket.send(skt, payload)
		
		raw_data = ""
		while raw_data == "" do
			raw_data = raw_data .. Socket.receive(skt, 8192)
		end
		local lines = explode("\r\n", raw_data)
		retVal = lines[10]
	end
	return retVal
end
function updateServerScore(intScore) -- Sends a new high score to the server
	if Network.isWifiEnabled() then
		local skt  = Socket.connect("game.gs2012.xyz", 80)
		local payload = "GET /starfield-vita/SFVupdateScore.php?rel="..rel.."&score="..intScore.."&user="..System.getUsername().." HTTP/1.1\r\nHost: game.gs2012.xyz\r\n\r\n"
		Socket.send(skt, payload)
	end
end

function gameOver() -- Game end operations
	if score > recordScore then
		recordScore = score
		saveScore(recordScore, scoreFilePath)
		updateServerScore(recordScore)
		worldScore = getServerInfo("score")
		worldPerson = getServerInfo("user")
	end
	score = 0
	lives = Default.lives
	gameLoopCounter = 0
	lifeTakenTimer = Timer.new()
	lifeTaken = false
	curScene = Default.startingScene
	for i = 1, Default.MAX_STARS do
		newStars[i] = {Display.width, math.random(Display.height), math.sqrt(math.random(4))}
	end	
end
function gameMenu()
	Graphics.drawImage(210, 50, logoImage)
	Graphics.debugPrint(0, 0, verString, color.royalBlue)
	Graphics.debugPrint(0, 20, "Local High Score: "..recordScore, color.royalBlue)
	Graphics.debugPrint(0, 40, "World High Score: "..worldScore.." by "..worldPerson, color.royalBlue)
	Graphics.debugPrint(0, 60, "Press X to start", color.royalBlue)
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
	if shipCoords.x >= Display.width then
		shipCoords.x = Display.width
	end
	if shipCoords.y >= Display.height then
		shipCoords.y = Display.height
	end
	if shipCoords.y <= 0 then
		shipCoords.y = 0
	end
	if debugMode then
		Graphics.debugPrint(0, 30, "shipX: "..shipCoords.x.." shipY: "..shipCoords.y.." Analog X: "..analogX.." Analog Y: "..analogY, color.royalBlue)
	end
	-- Don't spawn stars for the first 5 seconds.
	if Timer.getTime(gameTimer) >= 5000 then
		for i = 1, Default.MAX_STARS do
			Graphics.fillCircle(newStars[i][1], newStars[i][2], 4, color.white)
			
			newStars[i][1] = newStars[i][1] - newStars[i][3];
			if newStars[i][1] < 0 then -- Spawn a new star for each star that goes out of the screen
				newStars[i] = {Display.width, math.random(Display.height), math.sqrt(math.random(4))}
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

for i = 1, Default.MAX_STARS do
	newStars[i] = {Display.width, math.random(Display.height), math.sqrt(math.random(4))}
end

-- Starfield


readScore(scoreFilePath)
local oldpad = Controls.read()

if Network.isWifiEnabled() then
	worldScore = getServerInfo("score")
	worldPerson = getServerInfo("user")
end
while running do

	while not reachedFPScap(FPS_TARGET) do
		pad = Controls.read()
		Graphics.initBlend()
		Screen.clear()
		--
		game(curScene)
		--
		Graphics.termBlend()
		Screen.flip()
		
		
		if debugMode then
			if Controls.check(pad, SCE_CTRL_LTRIGGER) and not Controls.check(oldpad, SCE_CTRL_LTRIGGER) then
				FPS_TARGET = FPS_TARGET - 1
				if FPS_TARGET <= 0 then
					FPS_TARGET = 1
				end
			end
			if Controls.check(pad, SCE_CTRL_RTRIGGER) and not Controls.check(oldpad, SCE_CTRL_RTRIGGER) then
				FPS_TARGET = FPS_TARGET + 1
			end
		end
		
		if Controls.check(pad, SCE_CTRL_SELECT) and debugAllowed and not Controls.check(oldpad, SCE_CTRL_SELECT) then
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
