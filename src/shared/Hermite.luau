--!optimize 2
--!strict
local Hermite = {}
local doWarn = false
local BezCPunder = 2
local BezCPabove = 5
local BakeLimit = 268_000_000

--upvals
local exp = math.exp
local sort = table.sort
local clamp = math.clamp
local floor = math.floor
local max = math.max
local min = math.min
local bc = buffer.create
local w32 = buffer.writef32
local r32 = buffer.readf32

export type SplinePoint = {
    Point:number,
    Degree:number
}

export type genCG<T> = {
    [string]: (number)->(T)
}

local function xCheck(X:number, Above:boolean):number
    if not doWarn then
        return clamp(X, 0, 1)
    end
    if X > 1 and Above then
        warn("[Hermite]: X exceeds the supported range [0, 1]; clamped to 1.")
        return 1
    elseif X < 0 then
        warn("[Hermite]: X is below the supported range [0, 1]; clamped to 0.")
        return 0
    end
    return X
end

local BinomialTable:{[number]: {[number]: number}} = { -- calculated by: !x * !y / !(x - y)
    [1] = {
        [0] = 1,
        [1] = 1
    },
    [2] = {
        [0] = 1,
        [1] = 2,
        [2] = 1
    },
    [3] = {
        [0] = 1,
        [1] = 3,
        [2] = 3,
        [3] = 1
    },
    [4] = {
        [0] = 1,
        [1] = 4,
        [2] = 6,
        [3] = 4,
        [4] = 1
    },
    [5] = {
        [0] = 1,
        [1] = 5,
        [2] = 10,
        [3] = 10,
        [4] = 5,
        [5] = 1
    }
}

function Hermite.Sigmoid(X:number, Step:number?, Shift:number?):number --x is num, shift is middle point(x=0.5 always there) and step is sharpness(the higher, the sharper)
    X = xCheck(X, true)
    local cStep = Step or 1
    local cShift = Shift or 0.5
    return 1 / (1 + exp(-cStep * (X - cShift)))
end

function Hermite.Linear(X:number, Start:number, End:number):number
    X = xCheck(X, true)
    return Start + (End - Start) * X
end

function Hermite.Bezier(X:number, Points:{number}, Order:boolean?):number
    local tPoints = Points
    if Order then
        sort(tPoints)
    end
    X = xCheck(X, true)
    local count = #tPoints
    if count < BezCPunder or count > BezCPabove then --bezier limits. You can change them if you want. Change BinomialTable then aswell.
        if doWarn then
            warn(`! [Hermite]: Bezier aborted: expected {BezCPunder}-{BezCPabove} control points.`)
        end
        return 0
    end
    local n = count - 1
    local bin = BinomialTable[n]
    local Final = 0
    local av1 = 1 - X

    for i = 0, n do
        local point = tPoints[i + 1]
        local weight = bin[i] * ((av1)^(n - i)) * (X^i)

        Final += point * weight
    end

    return Final
end

local CustomGraphs : genCG<unknown> = {

}


function Hermite.Custom(X:number, Formula:(number)->number, Check:boolean):number
    local res = X
    if Check then
        res = xCheck(X, true)
    end
    return Formula(res)
end

function Hermite.Sample<T>(Id:string, Formula:(number)->T):()
    CustomGraphs[Id] = Formula :: (number)->unknown
    return
end

function Hermite.Evaluate<T>(Id:string, X:number):T
    local Formula = CustomGraphs[Id]
    if not Formula then
        if doWarn then
            warn("! [Hermite]: Evaluate aborted: unable to find formula.")
        end
        return nil :: any
    end
    return (Formula::(number)->T)(X)
end

function Hermite.Erase(Id:string):()
    CustomGraphs[Id] = nil
    return
end

function Hermite.Spline(X:number, Points:{SplinePoint}, Order:boolean):number
    local tPoints = Points
    if Order then
        sort(tPoints, function(a, b)
            return a.Point < b.Point
        end)
    end
    local xc = xCheck(X, false)
    local Segments = #tPoints - 1
    if Segments < 1 then
        if doWarn then
            warn("! [Hermite]: Spline aborted: expected atleast 2 points.")
        end
        return 0
    end
    local t = clamp(xc, 0, Segments)

    local Part = floor(t) + 1
    if Part > Segments then
        Part = Segments
    end
    local part2 = Part + 1
    local CurrentT = t > Segments and 1 or (t - (Part - 1))

    local p0 = tPoints[Part].Point
    local p1 = tPoints[part2].Point
    local d0 = tPoints[Part].Degree
    local d2 = tPoints[part2].Degree

    local t2 = CurrentT*CurrentT
    local t3 = t2*CurrentT

    local h0 = 2 * t3 - 3 * t2 + 1
    local h1 = -2 * t3 + 3 * t2
    local h2 = t3 - 2 * t2 + CurrentT
    local h3 = t3 - t2
    return p0 * h0 + d0 * h2 + p1 * h1 + d2 * h3
end

function Hermite.DefineWarn(Warn:boolean):()
    doWarn = Warn
    return
end

function Hermite.Step(X:number, Steps:number):number
    if Steps == 0 then
        if doWarn then
            warn("! [Hermite]: Step aborted: given value was zero, interrupting division.")
        end
        return 0
    end
    return floor(X * Steps) / Steps
end

local Bakeable : {[string]:(number, ...any)->number} = {
    ["Sigmoid"] = Hermite.Sigmoid,
    ["Linear"] = Hermite.Linear,
    ["Bezier"] = Hermite.Bezier,
    ["Spline"] = Hermite.Spline,
    ["Step"] = Hermite.Step
}

function Hermite.Bake(Method:string, Resolution:number, Decode:boolean, ...:any):{number} | buffer
    local fn = Bakeable[Method]
    if not fn then
        if doWarn then
            warn(`! [Hermite]: Bake aborted: {Method} is not a valid Hermite function.`)
        end
    end
    local steps = max(1, Resolution)
    steps = min(Resolution, BakeLimit)
    local buf = bc((steps + 1) * 4)
    local x = 0
    local y = 0
    for i = 0, steps do
        x = i / steps
        y = fn(x, ...)
        w32(buf, i * 4, y)
    end
    if Decode then
        local result = {}
        for ii = 0, steps do
            result[ii + 1] = r32(buf, ii * 4)
        end
        return result
    end
    return buf
end

return Hermite