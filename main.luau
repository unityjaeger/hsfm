--needs blackboard/context
--example hierarchy
--[[
local h = {
    t.Example1 = {
        t.Example2,
        t.Example3
    },
    t.Fexample1 = {
        t.Example2,
        t.Fexample2
    }
}

createTransition("Example1", "Fexample1", function(context)
    return context.someValue < 10
end)
]]

type HFSMObject = {
    onEnter: (context: {any}) -> (),
    onExit: (context: {any}) -> (),
    onUpdate: (context: {any}) -> ()
}

type HSFMInput = {
    [HFSMObject]: {HFSMObject}
}

local function createHSFM(hierarchy: HSFMInput)
    local HSFM = {
        currentState = nil,
        currentSubState = nil,
        defaults = {},
        transitions = {},
        substateTransitions = {},
        context = {}
    }

    return HSFM
end

local function transition(tbl, from, to, condition)
    if not tbl[from] then
        tbl[from] = {}
    end

    tbl[from][to] = condition
end

local function createTransition(hsfm, from, to, condition)
    transition(hsfm.transitions, from, to, condition)
end

local function createSubstateTransition(hsfm, parentState, from, to, condition)
    local tbl = hsfm.substateTransitions
    if not tbl[parentState] then
        print(parentState)
        tbl[parentState] = {}
    end
    if not tbl[parentState][from] then
        tbl[parentState][from] = {}
    end

    tbl[parentState][from][to] = condition
end

local function setCurrentState(hsfm, state)
    hsfm.currentState = state
end

local function setSubstateDefaults(hsfm, defaults)
    for state, substate in defaults do
        hsfm.defaults[state] = substate
    end
end

local function setContext(hsfm, newContext)
    hsfm.context = newContext
end

local function patchContext(hsfm, patch)
    for k, v in patch do
        hsfm.context[k] = v
    end
end

local function update(hsfm)
    local context = hsfm.context

    for to, condition in hsfm.transitions[hsfm.currentState] do
        if hsfm.currentState ~= to and condition(context) then
            local from = hsfm.currentState
            local fromSubstate = hsfm.currentSubState
            hsfm.currentState = to
            hsfm.currentSubState = hsfm.defaults[to] --nil is also a valid outcome

            if hsfm.currentSubState then
                hsfm.currentSubState.onEnter(context)
            end
            if fromSubstate then
                fromSubstate.onExit(context)
            end

            to.onEnter(context)
            from.onExit(context)
            break
        end
    end

    print(hsfm.currentState, hsfm.substateTransitions[hsfm.currentState])
    if hsfm.substateTransitions[hsfm.currentState] then
        for to, condition in hsfm.substateTransitions[hsfm.currentState][hsfm.currentSubState] do
            if hsfm.currentSubState ~= to and condition(context) then
                local from = hsfm.currentSubState
                hsfm.currentSubState = to

                to.onEnter(context)
                if from then
                    from.onExit(context)
                end

                break
            end
        end
    end 

    hsfm.currentState.onUpdate(context)
    hsfm.currentSubState.onUpdate(context)
end

local grounded = {onEnter = function()end,onExit = function()end,onUpdate = function()end}
local airbone = table.clone(grounded)

local idle = table.clone(grounded)
local walk = table.clone(idle)
local fly = table.clone(walk)
local jump = table.clone(fly)

local hsfm = createHSFM({
    [grounded] = {
        idle,
        walk
    },
    [airbone] = {
        fly,
        jump
    }
})
setCurrentState(hsfm, grounded)
setContext(hsfm, {rizz = 0})

createTransition(hsfm, grounded, airbone, function(context) return context.rizz < 5 end)
createSubstateTransition(hsfm, airbone, fly, jump, function(context) return context.rizz ~= 0 end)

print(hsfm.currentState.id)
patchContext(hsfm, {rizz = 10})
update(hsfm)
print(hsfm.currentState.id)

return {
    context = {
        setContext = setContext,
        patchContext = patchContext
    },

    update = update,
    createHSFM = createHSFM,
    setDefaultState = setDefaultState,
    createTransition = createTransition,
    createSubstateTransition = createSubstateTransition,
}
