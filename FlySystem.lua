--[[
-- Roblox = JustyNeru                  Discord = nep00143
]]

--\\Modules

local CameraController = require(game.ReplicatedStorage.CameraController) -- My module for creating camera animations.

--\\ Services

local RunService = game:GetService("RunService") -- Run Service for the runtime
local UIS = game:GetService("UserInputService") -- To get player inputs
local TweenService = game:GetService("TweenService") -- To tween the FOV stuff
local Players = game:GetService("Players") -- To get the LocalPlayer

--\\ Player Stuff
local LocalPlayer = Players.LocalPlayer -- getting the LocalPlayer
local char:Model = script.Parent -- getting the player char
local HMD:Humanoid = char:WaitForChild("Humanoid") -- getting humanoid
local RootPart:BasePart = char:WaitForChild("HumanoidRootPart") -- Getting HumanoidRootPart
local Forces:Attachment = RootPart:FindFirstChild("Forces") -- Getting Forces attachment
local Camera:Camera = workspace.CurrentCamera -- Getting Camera

--\\ Configs

local AnimsRemote = game.ReplicatedStorage.Remote -- Getting the remote to activate the animations

local Configs = {
	IsFlying = false, -- To find out if your flight is active or not.
	IsSprinting = false, -- To know if the player is sprinting right now
	LinearVelocity = nil, -- LinearVelocity Object
	AlignOrientation = nil, -- AlignOrientation Object

	--\\ Movement_Configs

	--\\ Front

	FMaxVelocity = 200, -- Used to set the maximum speed of the player flying forward.
	FSpeedMultiplier = .1, -- It serves to multiply in alpha (Lerp)
	FMovementAlpha = 0, -- Lerp Alpha

	--\\ Back

	BMaxVelocity = 50, -- Used to set the maximum speed of the player flying backwards.
	BSpeedMultiplier = .1, -- It serves to multiply in alpha (Lerp)
	BMovementAlpha = 0, -- Lerp Alpha

	--\\ Right

	RMaxVelocity = 50, -- Used to set the maximum speed of the player flying Right.
	RSpeedMultiplier = .1, -- It serves to multiply in alpha (Lerp)
	RMovementAlpha = 0, -- Lerp Alpha

	--\\ Left

	LMaxVelocity = 50, -- Used to set the maximum speed of the player flying Left.
	LSpeedMultiplier = .1, -- It serves to multiply in alpha (Lerp)
	LMovementAlpha = 0, -- Lerp Alpha

	--\\ Up

	UpMaxVelocity = 80, -- Used to set the maximum speed going up.
	UpSpeedMultiplier = .12, -- It serves to multiply in alpha (Lerp)
	UpMovementAlpha = 0, -- Lerp Alpha

	--\\ Down

	DownMaxVelocity = 80, -- Used to set the maximum speed going down.
	DownSpeedMultiplier = .12, -- It serves to multiply in alpha (Lerp)
	DownMovementAlpha = 0, -- Lerp Alpha

	--\\ Diagonals

	FRMaxVelocity = 150, -- Used to set the max speed on FrontRight diagonal.
	FRMovementAlpha = 0, -- Lerp Alpha
	FLMaxVelocity = 150, -- Used to set the max speed on FrontLeft diagonal.
	FLMovementAlpha = 0, -- Lerp Alpha
	BRMaxVelocity = 45, -- Used to set the max speed on BackRight diagonal.
	BRMovementAlpha = 0, -- Lerp Alpha
	BLMaxVelocity = 45, -- Used to set the max speed on BackLeft diagonal.
	BLMovementAlpha = 0, -- Lerp Alpha

	--\\ Sprint

	SprintMultiplier = 1.8, -- How much faster the Front goes when sprinting.
	SprintFOV = 85, -- FOV to use when sprinting.
	NormalFOV = 70, -- Normal FOV to go back when not sprinting.
	FOVSpeed = 5, -- Speed of the FOV lerp.

	--\\ Hover

	HoverBobSpeed = 2.5, -- Speed of the hover bobbing when idle.
	HoverBobAmount = 3, -- How much the hover moves up and down.
	HoverTime = 0, -- Internal timer for the hover.

	--\\ Limits

	MaxHeight = 480, -- Max Y the player can go while flying.
	MinHeight = 3, -- Min Y to avoid going under the map.
	SoftPush = 25, -- Force used to push back when hitting the height limit.

	--\\ Toggle

	ToggleCooldown = 0.5, -- Cooldown to avoid spam on Space.
	LastToggleTime = 0, -- Last time the player toggled fly.

	--\\ CameraConfig

	LastCameraOrientation = nil, -- Value of the camera's previous orientation
	TargetRoll = 0, -- The target roll for the character when he turns the camera.
	CurrentRoll = 0, -- the Current roll of the character
	RollSmooth = 5, -- How fast the roll follows the target.
	TargetPitch = 0, -- The target pitch when going forward or back.
	CurrentPitch = 0, -- The current pitch applied.
	PitchAmount = 7, -- How much pitch to add on Front and Backwards.
}

--\\ Functions

local function EnsureForces() -- I make sure the Forces attachment really exists
	if Forces and Forces.Parent then -- If it already exists i just return it
		return Forces -- Returning the attachment
	end
	local found = RootPart:FindFirstChild("Forces") -- I try to find it again in case it loaded late
	if found and found:IsA("Attachment") then -- If i found it now
		Forces = found -- I save the reference
		return Forces -- And return it
	end
	local newAttach = Instance.new("Attachment") -- I create a new Attachment
	newAttach.Name = "Forces" -- I name it Forces
	newAttach.Position = Vector3.new(0, 0, 0) -- I leave it centered on the RootPart
	newAttach.Parent = RootPart -- I parent it to the RootPart
	Forces = newAttach -- I save it on the local var
	return Forces -- I return the new one
end

local function CanToggle() -- I check if the player can toggle fly right now
	local now = os.clock() -- I get the current time
	local diff = now - Configs.LastToggleTime -- I calculate the diff from last toggle
	if diff < Configs.ToggleCooldown then -- If its still on cooldown
		return false -- I block it
	end
	Configs.LastToggleTime = now -- I update the last toggle time
	return true -- I allow it
end

local function PlayTakeoffCam() -- I play the takeoff camera anim
	if CameraController and type(CameraController.Play) == "function" then -- I check if Play really exists before calling
		local ok, err = pcall(function() -- I use pcall so it never breaks the fly if the module fails
			CameraController:Play("Takeoff") -- I play my takeoff anim here
		end)
		if not ok then -- If the camera module failed
			warn(err) -- I just warn it
		end
	end -- If theres no Play i just skip, no error
end

local function PlayLandingCam() -- I play the landing camera anim
	if CameraController and type(CameraController.Play) == "function" then -- I check if Play really exists
		local ok, err = pcall(function() -- Same pcall protection here
			CameraController:Play("Landing") -- I play my landing anim here
		end)
		if not ok then -- If it failed
			warn(err) -- I just warn it
		end
	end -- If theres no Play i just skip
end

local function HandleHumanoidForFly(enable:boolean) -- I setup the humanoid for fly or back to normal
	if enable then -- If enabling fly
		HMD.AutoRotate = false -- I disable AutoRotate so the gyro controls it
		HMD.PlatformStand = true -- I set PlatformStand to avoid trip
		HMD:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) -- I disable FallingDown
		HMD:ChangeState(Enum.HumanoidStateType.Physics) -- I force Physics for smoother fly
	else -- If disabling fly
		HMD.AutoRotate = true -- I enable AutoRotate back
		HMD.PlatformStand = false -- I remove PlatformStand
		HMD:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true) -- I enable FallingDown back
		HMD:ChangeState(Enum.HumanoidStateType.Freefall) -- I drop him on Freefall so gravity comes back
	end
end

local function TurnFly() -- Function to activate or deactivate the fly
	if not CanToggle() then -- I check the cooldown first
		return -- If on cooldown i just return
	end
	if not Configs.IsFlying and not Configs.LinearVelocity then -- I check if the player is not flying and if there is a BodyVelocity object already created to be sure.
		print("Flying") -- I print the state
		EnsureForces() -- I make sure Forces exists before creating the movers
		Configs.IsFlying = true -- I changed the flying status to true.
		Configs.HoverTime = 0 -- I reset the hover timer
		Configs.LastCameraOrientation = Camera.CFrame.LookVector -- I init the last camera orientation here to avoid snap

		-- LinearVelocity SETUP

		local LinearVelocity = Instance.new("LinearVelocity", Forces) -- I Create the LinearVelocity instance and put inside Forces attachment
		LinearVelocity.Attachment0 = Forces -- i setup the Attachment0
		LinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World -- I set it to World so LookVector works directly
		LinearVelocity.ForceLimitsEnabled = false -- I disable the roblox's forces to prevent them from interfering
		LinearVelocity.MaxForce = math.huge -- I set max force to huge so it always reaches the speed
		LinearVelocity.VectorVelocity = Vector3.zero -- I start with zero speed
		LinearVelocity.Enabled = true -- I enable it
		Configs.LinearVelocity = LinearVelocity -- Put on configs table

		-- AlignOrientation SETUP

		local AlignOrientation = Instance.new("AlignOrientation", Forces) -- I Create the AlignOrientation instance and put inside Forces attachment
		AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment -- i Setup the Alignment Mode to One Attachment
		AlignOrientation.Attachment0 = Forces -- i setup the Attachment0
		AlignOrientation.MaxTorque = math.huge -- I set max torque to huge
		AlignOrientation.Responsiveness = 100 -- I set a high responsiveness
		AlignOrientation.RigidityEnabled = false -- I keep rigidity off for smoother turns
		AlignOrientation.Enabled = true -- I enable it
		AlignOrientation.CFrame = RootPart.CFrame -- I init it on the current CFrame
		Configs.AlignOrientation = AlignOrientation -- Put on configs table

		HandleHumanoidForFly(true) -- I setup the humanoid for fly
		PlayTakeoffCam() -- I play the takeoff cam
	elseif Configs.IsFlying and Configs.LinearVelocity then -- checks if it is already flying and if a bodyVelocity has already been created.
		print("Not Flying") -- I print the state
		Configs.IsFlying = false -- I changed the flying status to false.
		Configs.IsSprinting = false -- I reset sprinting
		Configs.LinearVelocity:Destroy() -- Destroys LinearVelocity
		Configs.LinearVelocity = nil -- Remove the reference to it.
		Configs.AlignOrientation:Destroy() -- Destroys AlignOrientation
		Configs.AlignOrientation = nil -- Remove the reference to it.
		Configs.LastCameraOrientation = nil -- I clear the last camera orientation
		Configs.TargetRoll = 0 -- I reset the target roll
		Configs.CurrentRoll = 0 -- I reset the current roll
		Configs.TargetPitch = 0 -- I reset the target pitch
		Configs.CurrentPitch = 0 -- I reset the current pitch
		HandleHumanoidForFly(false) -- I put the humanoid back to normal
		PlayLandingCam() -- I play the landing cam
		AnimsRemote:Fire(nil, "Stop") -- If it stops flying, the animation is Stopped.
		Camera.FieldOfView = Configs.NormalFOV -- I force the FOV back to normal
	end
end

local function IsSprintingNow() -- I check if the player wants to sprint
	if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then -- If shift is down
		return true -- He wants to sprint
	end
	return false -- He is not sprinting
end

local function getState() -- It takes the currently pressed key on the player and translates it into an Action/State.
	local W = UIS:IsKeyDown(Enum.KeyCode.W) -- I check W
	local A = UIS:IsKeyDown(Enum.KeyCode.A) -- I check A
	local S = UIS:IsKeyDown(Enum.KeyCode.S) -- I check S
	local D = UIS:IsKeyDown(Enum.KeyCode.D) -- I check D
	local E = UIS:IsKeyDown(Enum.KeyCode.E) -- I check E for up
	local Q = UIS:IsKeyDown(Enum.KeyCode.Q) -- I check Q for down
	local State = "Idle" -- I start as Idle
	if W and D then -- If pressing FrontRight combo
		State = "FrontRight" -- I set diagonal
	elseif W and A then -- If pressing FrontLeft combo
		State = "FrontLeft" -- I set diagonal
	elseif S and D then -- If pressing BackRight combo
		State = "BackRight" -- I set diagonal
	elseif S and A then -- If pressing BackLeft combo
		State = "BackLeft" -- I set diagonal
	elseif W then -- If only W
		State = "Front" -- I set Front
	elseif S then -- If only S
		State = "Backwards" -- I set Backwards
	elseif A then -- If only A
		State = "Left" -- I set Left
	elseif D then -- If only D
		State = "Right" -- I set Right
	elseif E then -- If only E
		State = "Up" -- I set Up
	elseif Q then -- If only Q
		State = "Down" -- I set Down
	end
	return State -- I return the final state
end

local function ResetMovement() -- Reset all alphas to ensure that future transitions will go smoothly.
	if Configs.FMovementAlpha >= .1 then -- If front alpha is high
		Configs.FMovementAlpha = 0 -- I reset it
	end
	if Configs.BMovementAlpha >= .1 then -- If back alpha is high
		Configs.BMovementAlpha = 0 -- I reset it
	end
	if Configs.RMovementAlpha >= .1 then -- If right alpha is high
		Configs.RMovementAlpha = 0 -- I reset it
	end
	if Configs.LMovementAlpha >= .1 then -- If left alpha is high
		Configs.LMovementAlpha = 0 -- I reset it
	end
	if Configs.UpMovementAlpha >= .1 then -- If up alpha is high
		Configs.UpMovementAlpha = 0 -- I reset it
	end
	if Configs.DownMovementAlpha >= .1 then -- If down alpha is high
		Configs.DownMovementAlpha = 0 -- I reset it
	end
	if Configs.FRMovementAlpha >= .1 then -- If FrontRight alpha is high
		Configs.FRMovementAlpha = 0 -- I reset it
	end
	if Configs.FLMovementAlpha >= .1 then -- If FrontLeft alpha is high
		Configs.FLMovementAlpha = 0 -- I reset it
	end
	if Configs.BRMovementAlpha >= .1 then -- If BackRight alpha is high
		Configs.BRMovementAlpha = 0 -- I reset it
	end
	if Configs.BLMovementAlpha >= .1 then -- If BackLeft alpha is high
		Configs.BLMovementAlpha = 0 -- I reset it
	end
end

local function ClampHeight() -- I keep the player inside the height limits
	local y = RootPart.Position.Y -- I get the current Y
	if y > Configs.MaxHeight then -- If above max
		RootPart.CFrame = RootPart.CFrame - Vector3.new(0, y - Configs.MaxHeight, 0) -- I pull him back down
		if Configs.LinearVelocity then -- If velocity exists
			local v = Configs.LinearVelocity.VectorVelocity -- I get the velocity
			Configs.LinearVelocity.VectorVelocity = Vector3.new(v.X, -Configs.SoftPush, v.Z) -- I push him down a bit
		end
	end
	if y < Configs.MinHeight and Configs.IsFlying then -- If under min while flying
		RootPart.CFrame = RootPart.CFrame + Vector3.new(0, Configs.MinHeight - y, 0) -- I push him up
	end
end

local MovementFunctions = { -- All functions for each movement
	Idle = function() -- When idle i just hover
		ResetMovement() -- always keeps the Alphas at 0
		Configs.LinearVelocity.VectorVelocity = Vector3.zero -- Set the speed to zero.
		local bob = math.sin(Configs.HoverTime * Configs.HoverBobSpeed) * Configs.HoverBobAmount -- I calc the bob offset
		Configs.LinearVelocity.VectorVelocity = Vector3.new(0, bob, 0) -- I apply the bob on Y
	end,
	Front = function(Vector: Vector3, dt: number) -- Moving forward, it receives the current LookVector and the deltaTime to lerp
		local lv:LinearVelocity = Configs.LinearVelocity -- Reference LinearVelocity for ease of use.
		local mult = 1 -- I start the multiplier normal
		if IsSprintingNow() then -- I check sprint
			mult = Configs.SprintMultiplier -- I apply sprint multiplier
			Configs.IsSprinting = true -- I mark sprinting
		else -- If not sprinting
			Configs.IsSprinting = false -- I unmark it
		end
		Configs.FMovementAlpha += dt * Configs.FSpeedMultiplier -- calculation to increase lerp
		local finalAlpha = math.clamp(Configs.FMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1
		local target = Vector * Configs.FMaxVelocity * mult -- I build the target speed
		if UIS:IsKeyDown(Enum.KeyCode.E) then -- If also holding E
			target += Vector3.new(0, Configs.UpMaxVelocity * 0.5, 0) -- I blend a bit of up
		end
		if UIS:IsKeyDown(Enum.KeyCode.Q) then -- If also holding Q
			target += Vector3.new(0, -Configs.DownMaxVelocity * 0.5, 0) -- I blend a bit of down
		end
		local finalVelocity = lv.VectorVelocity:Lerp(target, finalAlpha) -- Calculate the target velocity using lerp, taking the current lookvector and multiplying it by the speed multiplier.
		lv.VectorVelocity = finalVelocity -- Place the result of lerp in the velocity of LinearVelocity.
	end,
	Backwards = function(Vector: Vector3, dt: number) -- Moving backWards, it receives the current LookVector and the deltaTime to lerp
		local lv:LinearVelocity = Configs.LinearVelocity -- Reference LinearVelocity for ease of use.
		local BackVector = Vector * -1 -- I transform the LookVector into BackVector by making it negative
		Configs.IsSprinting = false -- I never sprint backwards
		Configs.BMovementAlpha += dt * Configs.BSpeedMultiplier -- calculation to increase lerp
		local finalAlpha = math.clamp(Configs.BMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1
		local target = BackVector * Configs.BMaxVelocity -- I build the target
		local finalVelocity = lv.VectorVelocity:Lerp(target, finalAlpha) -- Calculate the target velocity using lerp, taking the current BackVector and multiplying it by the speed multiplier.
		lv.VectorVelocity = finalVelocity -- Place the result of lerp in the velocity of LinearVelocity.
	end,
	Right = function(Vector: Vector3, dt: number) -- Moving Right, it receives the current RightVector and the deltaTime to lerp
		local lv:LinearVelocity = Configs.LinearVelocity -- Reference LinearVelocity for ease of use.
		Configs.IsSprinting = false -- I dont sprint sideways
		Configs.RMovementAlpha += dt * Configs.RSpeedMultiplier -- calculation to increase lerp
		local finalAlpha = math.clamp(Configs.RMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1
		local target = Vector * Configs.RMaxVelocity -- I build the target
		local finalVelocity = lv.VectorVelocity:Lerp(target, finalAlpha) -- Calculate the target velocity using lerp, taking the current RightVector and multiplying it by the speed multiplier.
		lv.VectorVelocity = finalVelocity -- Place the result of lerp in the velocity of LinearVelocity.
	end,
	Left = function(Vector: Vector3, dt: number) -- Moving Left, it receives the current RightVector and the deltaTime to lerp
		local lv:LinearVelocity = Configs.LinearVelocity -- Reference LinearVelocity for ease of use.
		local LeftVector = Vector * -1 -- I transform the RightVector into LeftVector by making it negative
		Configs.IsSprinting = false -- I dont sprint sideways
		Configs.LMovementAlpha += dt * Configs.LSpeedMultiplier -- calculation to increase lerp
		local finalAlpha = math.clamp(Configs.LMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1
		local target = LeftVector * Configs.LMaxVelocity -- I build the target
		local finalVelocity = lv.VectorVelocity:Lerp(target, finalAlpha) -- Calculate the target velocity using lerp, taking the current LeftVector and multiplying it by the motion multiplier.
		lv.VectorVelocity = finalVelocity -- Place the result of lerp in the velocity of LinearVelocity.
	end,
	Up = function(Vector: Vector3, dt: number) -- Moving Up, it receives LookVector but i only use Y
		local lv:LinearVelocity = Configs.LinearVelocity -- Reference LinearVelocity for ease of use.
		Configs.IsSprinting = false -- I dont sprint up
		Configs.UpMovementAlpha += dt * Configs.UpSpeedMultiplier -- calculation to increase lerp
		local finalAlpha = math.clamp(Configs.UpMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1
		local target = Vector3.new(0, Configs.UpMaxVelocity, 0) -- I build straight up target
		target += Vector * 0.15 * Configs.UpMaxVelocity -- I keep a little bit of forward drift so it feels natural
		local finalVelocity = lv.VectorVelocity:Lerp(target, finalAlpha) -- I lerp to up
		lv.VectorVelocity = finalVelocity -- Place the result of lerp in the velocity.
	end,
	Down = function(Vector: Vector3, dt: number) -- Moving Down, same idea as Up
		local lv:LinearVelocity = Configs.LinearVelocity -- Reference LinearVelocity for ease of use.
		Configs.IsSprinting = false -- I dont sprint down
		Configs.DownMovementAlpha += dt * Configs.DownSpeedMultiplier -- calculation to increase lerp
		local finalAlpha = math.clamp(Configs.DownMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1
		local target = Vector3.new(0, -Configs.DownMaxVelocity, 0) -- I build straight down target
		target += Vector * 0.15 * Configs.DownMaxVelocity -- I keep a little forward drift
		local finalVelocity = lv.VectorVelocity:Lerp(target, finalAlpha) -- I lerp to down
		lv.VectorVelocity = finalVelocity -- Place the result of lerp in the velocity.
	end,
	FrontRight = function(Vector: Vector3, dt: number) -- Diagonal FrontRight, Vector here is already combined
		local lv:LinearVelocity = Configs.LinearVelocity -- Reference LinearVelocity for ease of use.
		local mult = 1 -- Normal multiplier
		if IsSprintingNow() then -- Check sprint
			mult = Configs.SprintMultiplier -- Apply sprint
			Configs.IsSprinting = true -- Mark sprint
		else
			Configs.IsSprinting = false -- Unmark
		end
		Configs.FRMovementAlpha += dt * Configs.FSpeedMultiplier -- calculation to increase lerp
		local finalAlpha = math.clamp(Configs.FRMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1
		local target = Vector * Configs.FRMaxVelocity * mult -- I build diagonal target
		local finalVelocity = lv.VectorVelocity:Lerp(target, finalAlpha) -- I lerp to it
		lv.VectorVelocity = finalVelocity -- Place the result
	end,
	FrontLeft = function(Vector: Vector3, dt: number) -- Diagonal FrontLeft, Vector here is already combined
		local lv:LinearVelocity = Configs.LinearVelocity -- Reference LinearVelocity for ease of use.
		local mult = 1 -- Normal multiplier
		if IsSprintingNow() then -- Check sprint
			mult = Configs.SprintMultiplier -- Apply sprint
			Configs.IsSprinting = true -- Mark sprint
		else
			Configs.IsSprinting = false -- Unmark
		end
		Configs.FLMovementAlpha += dt * Configs.FSpeedMultiplier -- calculation to increase lerp
		local finalAlpha = math.clamp(Configs.FLMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1
		local target = Vector * Configs.FLMaxVelocity * mult -- I build diagonal target
		local finalVelocity = lv.VectorVelocity:Lerp(target, finalAlpha) -- I lerp to it
		lv.VectorVelocity = finalVelocity -- Place the result
	end,
	BackRight = function(Vector: Vector3, dt: number) -- Diagonal BackRight
		local lv:LinearVelocity = Configs.LinearVelocity -- Reference LinearVelocity for ease of use.
		Configs.IsSprinting = false -- No sprint back
		Configs.BRMovementAlpha += dt * Configs.BSpeedMultiplier -- calculation to increase lerp
		local finalAlpha = math.clamp(Configs.BRMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1
		local target = Vector * Configs.BRMaxVelocity -- I build diagonal target
		local finalVelocity = lv.VectorVelocity:Lerp(target, finalAlpha) -- I lerp to it
		lv.VectorVelocity = finalVelocity -- Place the result
	end,
	BackLeft = function(Vector: Vector3, dt: number) -- Diagonal BackLeft
		local lv:LinearVelocity = Configs.LinearVelocity -- Reference LinearVelocity for ease of use.
		Configs.IsSprinting = false -- No sprint back
		Configs.BLMovementAlpha += dt * Configs.BSpeedMultiplier -- calculation to increase lerp
		local finalAlpha = math.clamp(Configs.BLMovementAlpha, 0, 1) -- To ensure that alpha never goes above 0 or 1
		local target = Vector * Configs.BLMaxVelocity -- I build diagonal target
		local finalVelocity = lv.VectorVelocity:Lerp(target, finalAlpha) -- I lerp to it
		lv.VectorVelocity = finalVelocity -- Place the result
	end,
}

--\\ Code

UIS.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean) -- Pego o input do player
	if gameProcessedEvent then -- If the game already used this input
		return -- I ignore it
	end
	if input.KeyCode == Enum.KeyCode.Space and not Configs.IsFlying and HMD:GetState() == Enum.HumanoidStateType.Freefall then -- If his input is a space and he is in FreeFall, then I will use the turnFly function.
		TurnFly() -- Depending on whether the player is already flying or not, they can disable or enable fly.
	elseif input.KeyCode == Enum.KeyCode.Space and Configs.IsFlying then -- If space while flying
		TurnFly() -- Depending on whether the player is already flying or not, they can disable or enable fly.
		AnimsRemote:Fire(nil, "Stop") -- If it stops flying, the animation is Stopped.
	end
	if input.KeyCode == Enum.KeyCode.E and Configs.IsFlying then -- If E while flying i reset vertical alpha for fast response
		Configs.UpMovementAlpha = 0 -- I reset up alpha
	end
	if input.KeyCode == Enum.KeyCode.Q and Configs.IsFlying then -- If Q while flying
		Configs.DownMovementAlpha = 0 -- I reset down alpha
	end
end)

HMD.Died:Connect(function() -- When the player dies
	if Configs.IsFlying then -- If he was flying
		Configs.IsFlying = false -- I force the flag off
		if Configs.LinearVelocity then -- If velocity still exists
			Configs.LinearVelocity:Destroy() -- I destroy it
			Configs.LinearVelocity = nil -- I clear it
		end
		if Configs.AlignOrientation then -- If gyro still exists
			Configs.AlignOrientation:Destroy() -- I destroy it
			Configs.AlignOrientation = nil -- I clear it
		end
		AnimsRemote:Fire(nil, "Stop") -- I stop the anims
	end
end)

RunService.PreRender:Connect(function(deltaTime: number) -- the main code
	if not char or not RootPart or not HMD then -- if the char, rootPart, or HMD are not yet created, return
		return -- I return
	end
	if HMD.Health <= 0 then -- If dead
		return -- I return
	end
	local LookVector = RootPart.CFrame.LookVector -- Getting the updated LookVector
	local RightVector = RootPart.CFrame.RightVector -- Getting the updated RightVector
	if Configs.IsFlying then -- Check if it's flying for the rest of the code to happen.
		if not Configs.LinearVelocity or not Configs.AlignOrientation then -- If movers got lost
			return -- I return to avoid error
		end
		local Align:AlignOrientation = Configs.AlignOrientation -- References AlignOrientation for ease of use
		if not Configs.LastCameraOrientation then -- If there is no last orientation, it initializes.
			Configs.LastCameraOrientation = Camera.CFrame.LookVector -- I set it as LookVector, since the character is always looking in the same direction as the camera during flight.
		end
		local LastCameraLook:Vector3 = Configs.LastCameraOrientation -- I'll take the previous look from the camera.
		local ActualCameraLook:Vector3 = Camera.CFrame.LookVector -- And take the current one.
		local CameraCross = LastCameraLook:Cross(ActualCameraLook) -- I get the Cross product based on the camera.
		Configs.LastCameraOrientation = ActualCameraLook -- Then I'll update LastCameraOrientation.
		Configs.TargetRoll = CameraCross.Y * 360 -- I take the Y from the Cross product, which is equivalent to the yaw, and multiply it by 360 to increase the force.
		Configs.TargetRoll = math.clamp(Configs.TargetRoll, -45, 45) -- I clamp the roll so it never spins crazy
		local stateEarly = getState() -- I get the state early to calc pitch
		if stateEarly == "Front" or stateEarly == "FrontRight" or stateEarly == "FrontLeft" then -- If going forward
			Configs.TargetPitch = -Configs.PitchAmount -- I tilt a bit forward
		elseif stateEarly == "Backwards" or stateEarly == "BackRight" or stateEarly == "BackLeft" then -- If going back
			Configs.TargetPitch = Configs.PitchAmount -- I tilt a bit back
		else -- If not moving on Z
			Configs.TargetPitch = 0 -- I reset pitch
		end
		local Alpha = 1 - math.exp(-Configs.RollSmooth * deltaTime) -- I perform an alpha calculation to interpolate the roll.
		Configs.CurrentRoll += (Configs.TargetRoll - Configs.CurrentRoll) * Alpha -- Instead of using Lerp, I prefer to perform a calculation to continuously retrieve the TargetRoll - CurrentRoll * Alpha, updating it little by little until it reaches the target.
		Configs.CurrentPitch += (Configs.TargetPitch - Configs.CurrentPitch) * Alpha -- I do the same smoothing for pitch
		Configs.CurrentRoll = math.clamp(Configs.CurrentRoll, -50, 50) -- I clamp current roll
		Align.CFrame = Camera.CFrame * CFrame.Angles(math.rad(Configs.CurrentPitch), 0, math.rad(Configs.CurrentRoll)) -- I apply the roll and pitch directly to the Gyro. And at the same time I update it to look directly in the direction of the camera.
		local state = getState() -- I use the function that translates the input into state and retrieve the current state.
		AnimsRemote:Fire(state) -- I activate the animation of this state.
		if state == "Right" or state == "Left" then -- I do a quick check to see if the state is equal to either Left or Right in order to use RightVector.
			MovementFunctions[state](RightVector, deltaTime) -- I call the sideways move
		elseif state == "Front" or state == "Backwards" then -- If Front or Back
			MovementFunctions[state](LookVector, deltaTime) -- I call with LookVector
		elseif state == "Up" or state == "Down" then -- If vertical
			MovementFunctions[state](LookVector, deltaTime) -- I call vertical, it mostly uses Y
		elseif state == "FrontRight" or state == "FrontLeft" then -- If front diagonals
			local combined = (LookVector + RightVector) -- I combine both vectors
			if state == "FrontLeft" then -- If left diagonal
				combined = (LookVector - RightVector) -- I flip the Right part
			end
			combined = combined.Unit -- I normalize it so diagonal is not faster
			MovementFunctions[state](combined, deltaTime) -- I call the diagonal func
		elseif state == "BackRight" or state == "BackLeft" then -- If back diagonals
			local combinedBack = (-LookVector + RightVector) -- I combine back + right
			if state == "BackLeft" then -- If back left
				combinedBack = (-LookVector - RightVector) -- I flip it
			end
			combinedBack = combinedBack.Unit -- I normalize
			MovementFunctions[state](combinedBack, deltaTime) -- I call the diagonal func
		else -- If Idle
			Configs.HoverTime += deltaTime -- I increase hover timer
			MovementFunctions[state]() -- I call Idle with no vector
		end
		ClampHeight() -- I clamp the height every frame
		local wantFOV = Configs.NormalFOV -- I start wanting normal FOV
		if Configs.IsSprinting then -- If sprinting
			wantFOV = Configs.SprintFOV -- I want sprint FOV
		end
		local fovAlpha = 1 - math.exp(-Configs.FOVSpeed * deltaTime) -- I calc FOV alpha
		Camera.FieldOfView += (wantFOV - Camera.FieldOfView) * fovAlpha -- I lerp the FOV
	end
end)

--END

--[[
I hope you liked it :D, made by Neru
]]
