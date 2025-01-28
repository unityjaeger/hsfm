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
