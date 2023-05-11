-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Folders
local vfx = ReplicatedStorage.VFX
local remotes = ReplicatedStorage.Remotes

-- Modules
local cameraShakeModule = require(ReplicatedStorage.CameraShaker)

-- Player
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Remotes
local knockbackRemote = remotes.Knockback
local takeDamageRemote = remotes.TakeDamage

-- Misc
local camera = game.Workspace.CurrentCamera
local sound = script.SFX
local iterations = 20
local debounce = false

-- Camera shake setup
local camShake = cameraShakeModule.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
	camera.CFrame = camera.CFrame * shakeCf
end)

function getPartsInHitbox(player)
	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	
	local overlapParams = OverlapParams.new()
	
	-- Create the hitbox; hitbox is offset by 50 from the HRP and has the size 14, 6, 88
	local contents = workspace:GetPartBoundsInBox(humanoidRootPart.CFrame*CFrame.new(0, 0, -50), Vector3.new(14, 6, 88), overlapParams)
		
	-- Visualisation of the hitbox
	--[[local part = Instance.new("Part", workspace)
	part.Parent = player.Character
	part.Anchored = true
	part.CFrame = humanoidRootPart.CFrame*CFrame.new(0, 0, -50)
	part.Size = Vector3.new(14, 6, 88)
	part.CanCollide = false
	part.Transparency = 0.5
	]]
	
	return contents
end

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.F then
			if debounce == true then return end 
			debounce = true
			
			local characterLookVector = character.HumanoidRootPart.CFrame.LookVector
			local characterRightVector = character.HumanoidRootPart.CFrame.RightVector

			local furthestPart
			
			local animation = Instance.new("Animation")
			animation.AnimationId = "http://www.roblox.com/asset/?id=11889121736" 
			local animationTrack = character.Humanoid:LoadAnimation(animation)
			animationTrack:Play()
			
			wait(1.25)
			
			local folder = Instance.new("Folder", workspace)
			folder.Name = "Rocks"
			
			for i= 1, iterations do
				local part = ReplicatedStorage.Part:Clone()

				part.Position = character.HumanoidRootPart.Position + characterLookVector * (i*3)
				
				--[[
				If our current iteration is an odd number, the part will be positioned on the right.
				If our current iteration is an even number, the part will be positioned on the left
				]]
				if i % 2 == 0 then
					part.Position -= characterRightVector * 10
				else
					part.Position += characterRightVector * 10
				end
								
				part.Parent = folder
				part.Anchored = true
				part.Name = i

				-- Randomise orientation
				part.CFrame *=  CFrame.Angles(math.rad(math.random(1, 180)), math.rad(math.random(1, 180)), math.rad(math.random(1, 180)))
				
				-- Begin camera shake
				camShake:Start()
				camShake:Shake(cameraShakeModule.Presets.Explosion)
				
				-- Play SFX
				sound.Playing = true
				
				if i == iterations then furthestPart = part end
			end
			
			-- VFX
			local spiralVFX = ReplicatedStorage.VFX.Spiral:Clone()
			spiralVFX.Parent = workspace
			spiralVFX.CFrame = character.HumanoidRootPart.CFrame
			
			-- Offset the VFX's orientation
			spiralVFX.CFrame *= CFrame.Angles(0, math.rad(-90), 0)
			
			local connection
			local i = 0
			
			connection = RunService.Heartbeat:Connect(function(deltaTime)
				i += 1
				
				-- Rotate the VFX by -10 every heartbeat
				spiralVFX.CFrame *= CFrame.Angles(math.rad(-10), 0, 0)
				spiralVFX.Position = character.HumanoidRootPart.Position + characterLookVector * i
				
				local magnitude = (spiralVFX.Position - furthestPart.Position).Magnitude
				
				-- Once the VFX is close enough to the furthest part, tween it out and destroy it
				if magnitude <= 15 then
					TweenService:Create(spiralVFX, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
					wait(.5)
					spiralVFX:Destroy()
					connection:Disconnect() 
				end
			end)
			
			local hit = getPartsInHitbox(player)
			
			local alreadyHit = {}
			for _, v in pairs(hit) do
				local hitCharacter = v.Parent
				local hitHumanoid = hitCharacter:FindFirstChild("Humanoid")
				
				if hitHumanoid and not alreadyHit[hitHumanoid] then
					alreadyHit[hitHumanoid] = true
					knockbackRemote:FireServer(hitHumanoid.Parent, characterLookVector)
					takeDamageRemote:FireServer(hitHumanoid, 100)
				end
			end
			
			wait(5)
			for _, v in pairs (game.Workspace.Rocks:GetChildren()) do
				local tween = TweenService:Create(v, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
			end
			
			wait(4)
			game.Workspace.Rocks:Destroy()
			
			debounce = false
		end
	end
end)
