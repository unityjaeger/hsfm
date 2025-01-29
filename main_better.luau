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
    addTwoWayTransition: (self: FSM, from: string, to: string, condition: (context: {any}) -> boolean) -> (),
	getChildOf: (self: FSM, state: string) -> FSM?,
	setDefaultState: (self: FSM, state: string) -> (),
	setContext: (self: FSM, context: {any}) -> (),
	patchContext: (self: FSM, context: {any}) -> (),
	update: (self: FSM, deltaTime: number) -> ()
}

local function addTransition(self: FSM, from: string, to: string, condition: (context: {any}) -> boolean): ()
	local transitions = self._transitions
	if not transitions[from] then
		transitions[from] = {}
	end
	transitions[from][to] = condition
end

local function addTwoWayTransition(self: FSM, from: string, to: string, condition: (context: {any}) -> boolean): ()
    addTransition(from, to, condition)
    addTransition(to, from, function(context)
        return not condition(context)
    end)
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

local function update(self: FSM, deltaTime: number): ()
    local from = self.currentState
    local context = self._context
    local states = self._states

    local state = states[from]

    local transitions = self._transitions[from]
    if transitions then
        for to, condition in self._transitions[from] do
            if condition(context) then
                local newState = states[to]

                local onExit = (state.parent or state).onExit
                local onEnter = (newState.parent or newState).onEnter

                self.currentState = to
                state = newState

                onExit(context)
                onEnter(context)
            end
        end
    end

    if state.parent then
        state.parent.onUpdate(context, deltaTime)
        state:update()
    else
        state.onUpdate(context, deltaTime)
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
	
	fsm.addTransition = addTransition
    fsm.addTwoWayTransition = addTwoWayTransition
	fsm.getChildOf = getChildOf
	fsm.setDefaultState = setDefaultState
	fsm.setContext = setContext
    fsm.patchContext = patchContext

	fsm.update = update
	
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
fsm:addTransition("Grounded", "Physics", function()
    return true
end)

local physicsFSM = fsm:getChildOf("Physics")
physicsFSM:setContext({xVelocity = 0})
physicsFSM:setDefaultState("Walk")

physicsFSM:addTransition("Walk", "Idle", function(context)
	return context.xVelocity <= 0
end)

fsm:update()
fsm:update()
