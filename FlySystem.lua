--[[
-- Roblox = JustyNeru                  Discord = nep00143
]]

--\\Modules

local CameraController = require(game.ReplicatedStorage.CameraController) -- My module for creating camera animations.

--\\ Services

local RunService = game:GetService("RunService") -- Run Service for the runtime
local UIS = game:GetService("UserInputService") -- To get player inputs

--\\ Player Stuff
local char:Model = script.Parent -- getting the player char
local HMD:Humanoid = char:WaitForChild("Humanoid") -- getting humanoid
local RootPart:BasePart = char:WaitForChild("HumanoidRootPart") -- Getting HumanoidRootPart

local Forces:Attachment = RootPart:FindFirstChild("Forces") -- Getting Forces attachment

local Camera:Camera = workspace.CurrentCamera  -- Getting Camera

--\\ Configs

local AnimsRemote = game.ReplicatedStorage.Remote -- Getting the remote to activate the animations

local Configs = {
	IsFlying = false, -- To find out if your flight is active or not.
	
	LinearVelocity = nil, --LinearVelocity Object
	AlignOrientation = nil, --AlignOrientation Object
	
	--\\ Movement_Configs
	
				--\\ Front
	
	FMaxVelocity = 200,  -- Used to set the maximum speed of the player flying forward.
	FSpeedMultiplier = .1, -- It serves to multiply in alpha (Lerp)
	FMovementAlpha = 0, -- Lerp Alpha
	
				--\\ Back
	
	BMaxVelocity = 50, -- Used to set the maximum speed of the player flying backwards.
	BSpeedMultiplier = .1, -- It serves to multiply in alpha (Lerp)
	BMovementAlpha = 0,  -- Lerp Alpha
	
				--\\ Right
	
	RMaxVelocity = 50,-- Used to set the maximum speed of the player flying Right.
	RSpeedMultiplier = .1, -- It serves to multiply in alpha (Lerp)
	RMovementAlpha = 0,  -- Lerp Alpha
	
				--\\ Left
	
	LMaxVelocity = 50, -- Used to set the maximum speed of the player flying Right.
	LSpeedMultiplier = .1, -- It serves to multiply in alpha (Lerp)
	LMovementAlpha = 0, -- Lerp Alpha
	
	--\\ CameraConfig
	
	LastCameraOrientation = nil, -- Value of the camera's previous orientation
	TargetRoll = 0, -- The target roll for the character when he turns the camera.
	CurrentRoll = 0 -- the Current roll of the character
}

--\\ Functions

local function TurnFly() -- Function to activate or deactivate the fly
	if not Configs.IsFlying and not Configs.LinearVelocity then -- I check if the player is not flying and if there is a BodyVelocity object already created to be sure.
		
		print("Flying")
		
		Configs.IsFlying = true --I changed the flying status to true.
		
		-- LinearVelocity SETUP
		
		local LinearVelocity = Instance.new("LinearVelocity", Forces) -- I Create the LinearVelocity instance and put inside Forces attachment
		
		LinearVelocity.Attachment0 = Forces -- i setup the Attachment0
		
		LinearVelocity.ForceLimitsEnabled = false -- I disable the roblox's forces to prevent them from interfering
		 
		Configs.LinearVelocity = LinearVelocity -- Put on configs table
		
		--AlignOrientation SETUP
		
		local AlignOrientation = Instance.new("AlignOrientation", Forces)  -- I Create the AlignOrientation instance  and put inside Forces attachment
		
		AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment -- i Setup the Alignment Mode to One Attachment
		AlignOrientation.Attachment0 = Forces -- i setup the Attachment0
		
		AlignOrientation.MaxTorque = math.huge
		AlignOrientation.Responsiveness = 100
		
		Configs.AlignOrientation = AlignOrientation -- Put on configs table
		
		
	elseif Configs.IsFlying and Configs.LinearVelocity then -- checks if it is already flying and if a bodyVelocity has already been created.
		
		print("Not Flying")
		
		Configs.IsFlying = false -- I changed the flying status to false.
		Configs.LinearVelocity:Destroy() -- Destroys LinearVelocity
		Configs.LinearVelocity = nil -- Remove the reference to it.
		Configs.AlignOrientation:Destroy() -- Destroys AlignOrientation
		Configs.AlignOrientation = nil-- Remove the reference to it.
	end
end

local function getState() -- It takes the currently pressed key on the player and translates it into an Action/State.
	local State = "Idle"
	
	if UIS:IsKeyDown(Enum.KeyCode.W) then
		State = "Front"
	elseif UIS:IsKeyDown(Enum.KeyCode.S) then
		State = "Backwards"
	elseif UIS:IsKeyDown(Enum.KeyCode.A) then
		State = "Left"
	elseif UIS:IsKeyDown(Enum.KeyCode.D) then
		State = "Right"
	end
	
	return State
end

local function ResetMovement() -- Reset all alphas to ensure that future transitions will go smoothly.
	if Configs.FMovementAlpha >= .1 then
		Configs.FMovementAlpha = 0
	end
	
	if Configs.BMovementAlpha >= .1 then
		Configs.BMovementAlpha = 0
	end
	
	if Configs.RMovementAlpha >= .1 then
		Configs.RMovementAlpha = 0
	end
	
	if Configs.LMovementAlpha >= .1 then
		Configs.LMovementAlpha = 0
	end
end

local MovementFunctions = { -- -- All functions for each movement
	Idle = function()
		ResetMovement() -- always keeps the Alphas at 0
		Configs.LinearVelocity.VectorVelocity = Vector3.zero -- Set the speed to zero.
	end,
	Front = function(Vector: Vector3, dt: number) -- Moving forward, it receives the current LookVector and the deltaTime to lerp
		
		local lv:LinearVelocity= Configs.LinearVelocity -- Reference BodyVelocity for ease of use.
		
		Configs.FMovementAlpha += dt * Configs.FSpeedMultiplier -- calculation to increase lerp
		
		local finalAlpha = math.clamp(Configs.FMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1
		
		local finalVelocity = lv.VectorVelocity:Lerp(Vector * Configs.FMaxVelocity, finalAlpha) -- Calculate the target velocity using lerp, taking the current lookvector and multiplying it by the speed multiplier.
		
	 lv.VectorVelocity = finalVelocity -- Place the result of lerp in the velocity of BodyVelocity.
	end,
	
	Backwards = function(Vector: Vector3, dt: number) -- Moving backWards, it receives the current LookVector and the deltaTime to lerp
		local lv:LinearVelocity = Configs.LinearVelocity -- Reference BodyVelocity for ease of use.
		
		local BackVector = Vector * -1 -- I transform the LookVector into BackVector by making it negative
		
		Configs.BMovementAlpha += dt * Configs.BSpeedMultiplier  -- calculation to increase lerp

		local finalAlpha = math.clamp(Configs.BMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1

		local finalVelocity = lv.VectorVelocity:Lerp(BackVector * Configs.BMaxVelocity, finalAlpha) -- Calculate the target velocity using lerp, taking the current BackVector and multiplying it by the speed multiplier.

		lv.VectorVelocity = finalVelocity -- Place the result of lerp in the velocity of BodyVelocity.
	end,
	Right = function(Vector: Vector3, dt: number) -- Moving Right, it receives the current RightVector and the deltaTime to lerp
		local lv:LinearVelocity = Configs.LinearVelocity -- Reference BodyVelocity for ease of use.
		Configs.RMovementAlpha += dt * Configs.RSpeedMultiplier  -- calculation to increase lerp

		local finalAlpha = math.clamp(Configs.RMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1

		local finalVelocity = lv.VectorVelocity:Lerp(Vector * Configs.RMaxVelocity, finalAlpha) -- Calculate the target velocity using lerp, taking the current RightVector and multiplying it by the speed multiplier.

		lv.VectorVelocity = finalVelocity -- Place the result of lerp in the velocity of BodyVelocity.
	end,
	Left = function(Vector: Vector3, dt: number) -- Moving Left, it receives the current RightVecrto and the deltaTime to lerp
		local lv:LinearVelocity = Configs.LinearVelocity -- Reference BodyVelocity for ease of use.
		local LeftVector = Vector * -1 -- I transform the RightVector into LeftVector by making it negative
		Configs.LMovementAlpha += dt * Configs.LSpeedMultiplier  -- calculation to increase lerp

		local finalAlpha = math.clamp(Configs.LMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1

		local finalVelocity = lv.VectorVelocity:Lerp(LeftVector * Configs.LMaxVelocity, finalAlpha) -- Calculate the target velocity using lerp, taking the current lookvector and multiplying it by the motion multiplier.

		lv.VectorVelocity = finalVelocity -- Place the result of lerp in the velocity of BodyVelocity.
	end,
}

--\\ Code

UIS.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)   -- Pego o input do player
	if gameProcessedEvent then
		return
	end
	
	
	if input.KeyCode == Enum.KeyCode.Space and not Configs.IsFlying and HMD:GetState() == Enum.HumanoidStateType.Freefall then -- If his input is a space and he is in FreeFall, then I will use the turnFly function.
		TurnFly() -- Depending on whether the player is already flying or not, they can disable or enable fly.
		
	elseif  input.KeyCode == Enum.KeyCode.Space and Configs.IsFlying then
		
		TurnFly() -- Depending on whether the player is already flying or not, they can disable or enable fly.
		AnimsRemote:Fire(nil, "Stop")-- If it stops flying, the animation is Stopped.
	end
end)

RunService.PreRender:Connect(function(deltaTime: number) -- the main code
	if not char or not RootPart or not HMD then
		return -- if the char, rootPart, or HMD are not yet created, return
	end
	
	local LookVector = RootPart.CFrame.LookVector -- Getting the updated LookVector
	
	
	local RightVector = RootPart.CFrame.RightVector  -- Getting the updated RightVector
	
	
	if Configs.IsFlying then -- Check if it's flying for the rest of the code to happen.
		local Align:AlignOrientation = Configs.AlignOrientation -- References bodyGyro for ease of use
		
		if not Configs.LastCameraOrientation then--  If there is no last orientation, it initializes.
			Configs.LastCameraOrientation = Camera.CFrame.LookVector -- I set it as LookVector, since the character is always looking in the same direction as the camera during flight.
		end
		local LastCameraLook:Vector3 = Configs.LastCameraOrientation -- I'll take the previous look from the camera.
		local ActualCameraLook:Vector3 = Camera.CFrame.LookVector -- And take the current one.
		
		local CameraCross = LastCameraLook:Cross(ActualCameraLook) -- I get the Cross product based on the camera.
		
		Configs.LastCameraOrientation = ActualCameraLook -- Then I'll update LastCameraOrientation.
		
		Configs.TargetRoll = CameraCross.Y * 360 -- I take the Y from the Cross product, which is equivalent to the yaw, and multiply it by 360 to increase the force.
		
		local Alpha = 1 - math.exp(-5 * deltaTime) -- I perform an alpha calculation to interpolate the roll.
		
		Configs.CurrentRoll += (Configs.TargetRoll - Configs.CurrentRoll) * Alpha -- Instead of using Lerp, I prefer to perform a calculation to continuously retrieve the TargetRoll - CurrentRoll * Alpha, updating it little by little until it reaches the target.
		
		Align.CFrame = Camera.CFrame * CFrame.Angles(0, 0, math.rad(Configs.CurrentRoll)) -- I apply the roll directly to the Gyro. And at the same time I update it to look directly in the direction of the camera.
		
		print("TargetRoll:", Configs.TargetRoll, "| CurrentRoll:", Configs.CurrentRoll) -- For debugging purposes, to check if the roll is being calculated correctly.
		
		local state = getState() -- I use the function that translates the input into state and retrieve the current state.
		AnimsRemote:Fire(state) -- I activate the animation of this state.
		if state == "Right" or state == "Left" then -- I do a quick check to see if the state is equal to either Left or Right in order to use RightVector.
			MovementFunctions[state](RightVector, deltaTime)
		else-- If it's not Right or Left, I use LookVector.
			MovementFunctions[state](LookVector, deltaTime)
		end
	end
end)

--END

--[[
I hope you liked it :D, made by Neru
]]
