do
	local function createFSM(config)
		local fsm = {
			currentState = nil,
			isFSM = true,

			transitions = {},
			context = {},
			states = config
		}

		return fsm
	end

	local function createSubFSM(state, config)
		local fsm = {
			currentState = nil,
			isFSM = true,

			onEnter = state.onEnter,
			onExit = state.onExit,
			onUpdate = state.onUpdate,

			transitions = {},
			context = {},
			states = config
		}



		return fsm
	end

	local function create(state, config)
		if state and config then
			return createSubFSM(state, config)
		else
			return createFSM(state)
		end
	end

	local function parsePath(fsm, path)
		local path = string.split(path, "/")
		local last = table.remove(path)
		local start = fsm

		for _, str in path do
			start = start.states[str]
		end

		return start.transitions, last
	end

	local function defineTransition(fsm, from, to, condition)
		local path = fsm.states
		local transitions, from = parsePath(fsm, from)
		local _, to = parsePath(fsm, to)
		if not transitions[from] then
			transitions[from] = {}
		end
		transitions[from][to] = condition
	end

	local attack = {
		onEnter = function() end,
		onExit = function() end,
		onUpdate = function() end
	}
	local combat = table.clone(attack)
	local fetching = table.clone(combat)

	local fsm1 = create({
		["Combat"] = create(combat, {
			["Attack"] = attack
		}),
		["Fetching"] = fetching
	})

	defineTransition(fsm1, "Combat", "Fetching", function() end)
	defineTransition(fsm1, "Combat/Attack", "Combat/Attack", function() end)
	

	print(fsm1)
end

--[[
{
	transitions = {},
	child = FSM? optional,
	states = {
		...
	},
	context = {},
	currentState = ...
}
]]

type State = {
	onEnter: (context: any) -> (),
	onExit: (context: any) -> (),
	onUpdate: (context: any, deltaTime: number) -> (),
}

type Config = {
	[string]: FSM | State
}

type FSM = {
	currentState: string,
	_transitions: {
		[string]: {
			[string]: (context: string) -> bool
		}
	},
	_context: {any},
	_states: Config,
	
	addTransition: (self: FSM, from: string, to: string, condition: (context: {any}) -> boolean) -> (),
	getChildOf: (self: FSM, state: string) -> FSM?,
	setDefaultState: (self: FSM, state: string) -> (),
	context: {
		set: (self: FSM, context: {any}) -> (),
		patch: (self: FSM, context: {any}) -> (),
	},
	update: (self: FSM, deltaTime: number) -> ()
}

local function addTransition(self: FSM, from: string, to: string, condition: (context: {any}) -> boolean): ()
	local transitions = self._transitions
	if not transitions[from] then
		transitions[from] = {}
	end
	transitions[from][to] = condition
end

local function getChildOf(self: FSM, state: string): FSM?
	local child = self._states[state]
	return child._isFSM and child or nil
end

local function setContext(self: FSM, context: {any}): ()
	self._context = context
end

local function patchContext(self: FSM, context: {any}): ()
	for k, v in context do
		self._context[k] = v
	end
end

local function setDefaultState(self: FSM, state: string): ()
	if self.currentState == nil then
		self.currentState = state
	end
end

local function update(self: FSM, deltaTime: number)
	-- do topmost state then call :update on child state
end

local function create(config: Config): FSM
	local fsm = {
		_isFSM = true,
		_transitions = {},
		_context = {},
		_states = config,
		currentState = nil,
	}
	
	fsm.addTransition = addTransition
	fsm.getChildOf = getChildOf
	fsm.setDefaultState = setDefaultState
	fsm.context = {
		set = setContext,
		patch = patchContext
	}
	
	fsm.update = update
	
	return fsm
end

local physics = {onUpdate = function()end, onEnter = function()end, onExit = function()end}
local grounded = table.clone(physics)
local idle = table.clone(physics)
local walk = table.clone(physics)

local fsm = create({
	Physics = create({
		Walk = walk,
		Idle = idle
	}),
	Grounded = grounded
})

fsm:setDefaultState("Physics")

local physicsFSM = fsm:getChildOf("Physics")
physicsFSM.context:set({xVelocity = 0})
physicsFSM:setDefaultState("Walk")

physicsFSM:addTransition("Walk", "Idle", function(context)
	return context.xVelocity <= 0
end)

print(fsm)
fsm:update()

--i FORGOR: parent state for children fsms, make a parentState field and a transition utility function
