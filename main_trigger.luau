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
	_transitions: {},
	_context: {any},
	_states: Config,
	

	getChildOf: (self: FSM, state: string) -> FSM?,
	setDefaultState: (self: FSM, state: string) -> (),
	setContext: (self: FSM, context: {any}) -> (),
	patchContext: (self: FSM, context: {any}) -> (),
	update: (self: FSM, deltaTime: number) -> ()
}

local function addTrigger(self: FSM, from: string, to: string, trigger: number | string): ()
    local transitions = self._transitions
	if not transitions[trigger] then
		transitions[trigger] = {}
	end
    transitions[trigger][from] = to
end

local function getChildOf(self: FSM, state: string): FSM?
	local child = self._states[state]
	return child.parent and child or nil
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

local function trigger(self: FSM, trigger: number | string): ()
    local context = self._context
    local states = self._states
    local from = self.currentState

    local to = self._transitions[trigger][from]
    if to then
        local oldState = states[from]
        local newState = states[to]

        local onExit = (oldState.parent or oldState).onExit
        local onEnter = (newState.parent or newState).onEnter

        self.currentState = to
        onExit(context)
        onEnter(context)
    end
end

local function create(parentState: State, config: Config): FSM
	local fsm = {
		_transitions = {},
		_context = {},
		_states = config,
		currentState = nil,
        parent = parentState
	}
	
	fsm.addTrigger = addTrigger
	fsm.getChildOf = getChildOf
	fsm.setDefaultState = setDefaultState
	fsm.setContext = setContext
    fsm.patchContext = patchContext

	fsm.trigger = trigger
	
	return fsm
end

local function construct(name)
    return {
        onUpdate = function()
            print("updated", name)
        end,
        onEnter = function()
            print("entered", name)
        end,
        onExit = function()
            print("exited", name)
        end
    }
end

local physics = construct("Physics")
local grounded = construct("Grounded")
local idle = construct("Idle")
local walk = construct("Walk")

local fsm = create(nil, {
	Physics = create(physics, {
		Walk = walk,
		Idle = idle
	}),
	Grounded = grounded
})

fsm:setDefaultState("Grounded")
fsm:addTrigger("Grounded", "Physics", "to_physics")

local physicsFSM = fsm:getChildOf("Physics")
physicsFSM:setContext({xVelocity = 0})
physicsFSM:setDefaultState("Walk")

physicsFSM:addTrigger("Walk", "Idle", "enter_idle")

fsm:trigger("to_physics")
physicsFSM:trigger("enter_idle")
--[[output
exited	Grounded
entered	Physics
exited	Walk
entered	Idle
]]
