--!optimize 2
--!strict
local Hermite = {}
local doWarn = false

export type SplinePoint = {
    Point:number,
    Degree:number
}

local function xCheck(X:number, Above:boolean)
    if X > 1 and Above then
        if doWarn then
            warn("[Hermite]: X exceeds the supported range [0, 1]; clamped to 1.")
        end
        return 1
    elseif X < 0 then
        if doWarn then
            warn("[Hermite]: X is below the supported range [0, 1]; clamped to 0.")
        end
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

--upvals
local pi = math.pi
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local exp = math.exp
local sort = table.sort
local clamp = math.clamp
local floor = math.floor

function Hermite:Sigmoid(X:number, Step:number?, Shift:number?):number --x is num, shift is middle point(x=0.5 always there) and step is sharpness(the higher, the sharper)
    X = xCheck(X, true)
    local cStep = Step or 1
    local cShift = Shift or 0.5
    return 1 / (1 + exp(-cStep * (X - cShift)))
end

function Hermite:Linear(X:number, Start:number, End:number):number
    X = xCheck(X, true)
    return Start + (End - Start) * X
end

function Hermite:Bezier(X:number, Points:{number}, Order:boolean):number
    if Order then
        sort(Points)
    end
    X = xCheck(X, true)
    local count = #Points
    if count <= 1 or count >= 6 then --bezier limits. You can change them if you want. Change BinomialTable then aswell.
        if doWarn then
            warn("! [Hermite]: Bezier aborted: expected 2-5 control points.")
        end
        return 0
    end
    local n = count - 1
    local bin = BinomialTable[n]
    local Final = 0
    local av1 = 1 - X

    for i = 0, n do
        local point = Points[i + 1]
        local weight = bin[i] * ((av1)^(n - i)) * (X^i)

        Final += point * weight
    end

    return Final
end

local function BounceOut(X:number)
    local n = 7.5625
    local d = 2.75
    local res = X

    if X < 1 / d then
        return n * X^2
    elseif X < 2 / d then
        res -= 1.5 / d
        return n * res * res + 0.75
    elseif X < 2.5 / d then
        res -= 2.25 / d
        return n * res * res + 0.9375
    else
        res -= 2.625 / d
        return n * res * res + 0.984375
    end
end

local EasingGraphs : {[Enum.EasingStyle] : {[Enum.EasingDirection] : (number)->(number)}} = { --you are free to add custom and rewriting enums if you want to. :Custom() is still easier
    [Enum.EasingStyle.Linear] = {
        [Enum.EasingDirection.In] = function(x:number)
            return x
        end,
        [Enum.EasingDirection.Out] = function(x:number)
            return x
        end,
        [Enum.EasingDirection.InOut] = function(x:number)
            return x
        end
    },
    [Enum.EasingStyle.Sine] = {
        [Enum.EasingDirection.In] = function(x:number)
            return 1 - cos((x * pi) * 0.5)
        end,
        [Enum.EasingDirection.Out] = function(x:number)
            return sin((x * pi) * 0.5)
        end,
        [Enum.EasingDirection.InOut] = function(x:number)
            return -(cos(pi * x) - 1) * 0.5
        end
    },
    [Enum.EasingStyle.Quad] = {
        [Enum.EasingDirection.In] = function(x:number)
            return x * x
        end,
        [Enum.EasingDirection.Out] = function(x:number)
            return 1 - (1 - x) * (1 - x)
        end,
        [Enum.EasingDirection.InOut] = function(x:number)
            return x < 0.5 and 2 * x * x or 1 - ((-2 * x + 2)^2) * 0.5
        end
    },
    [Enum.EasingStyle.Cubic] = {
        [Enum.EasingDirection.In] = function(x:number)
            return x * x * x
        end,
        [Enum.EasingDirection.Out] = function(x:number)
            return 1 - (1 - x)^3
        end,
        [Enum.EasingDirection.InOut] = function(x:number)
            return x < 0.5 and 4 * x * x * x or 1 - ((-2 * x + 2)^3) * 0.5
        end
    },
    [Enum.EasingStyle.Quart] = {
        [Enum.EasingDirection.In] = function(x:number)
            return x * x * x * x
        end,
        [Enum.EasingDirection.Out] = function(x:number)
            return 1 - (1 - x)^4
        end,
        [Enum.EasingDirection.InOut] = function(x:number)
            return x < 0.5 and 8 * x * x * x * x or 1 - ((-2 * x + 2)^4) * 0.5
        end
    },
    [Enum.EasingStyle.Quint] = {
        [Enum.EasingDirection.In] = function(x:number)
            return x*x*x*x*x
        end,
        [Enum.EasingDirection.Out] = function(x:number)
            return 1 - (1 - x)^5
        end,
        [Enum.EasingDirection.InOut] = function(x:number)
            return x < 0.5 and 16 * x*x*x*x*x or 1 - ((-2 * x + 2)^5) * 0.5
        end
    },
    [Enum.EasingStyle.Exponential] = {
        [Enum.EasingDirection.In] = function(x:number)
            return x == 0 and 0 or 2^(10 * x - 10)
        end,
        [Enum.EasingDirection.Out] = function(x:number)
            return x == 1 and 1 or 1 - (2^(-10 * x))
        end,
        [Enum.EasingDirection.InOut] = function(x:number)
            if x == 0 then 
                return 0
            elseif x == 1 then 
                return 1
            elseif x < 0.5 then
                return (2^(20 * x - 10)) * 0.5
            else 
                return (2 - (2^(-20 * x + 10))) * 0.5 
            end
        end
    },
    [Enum.EasingStyle.Circular] = {
        [Enum.EasingDirection.In] = function(x:number)
            return 1 - sqrt(1 - x*x)
        end,
        [Enum.EasingDirection.Out] = function(x:number)
            return sqrt(1 - (x - 1)^2)
        end,
        [Enum.EasingDirection.InOut] = function(x:number)
            return x < 0.5 and (1 - sqrt(1 - (2 * x)^2)) * 0.5 or (sqrt(1 - (-2 * x + 2)^2) + 1) * 0.5
        end
    },
    [Enum.EasingStyle.Back] = {
        [Enum.EasingDirection.In] = function(x:number)
            return 2.70158 * x*x*x - 1.70158 * x*x
        end,
        [Enum.EasingDirection.Out] = function(x:number)
            return 1 + 2.70158 * ((x - 1)^3) + 1.70158 * ((x - 1)^2)
        end,
        [Enum.EasingDirection.InOut] = function(x:number)
            local c = 1.70158 * 1.525
            return x < 0.5 and ((2 * x)^2 * ((c + 1) * 2 * x - c)) * 0.5 or ((2 * x - 2)^2 * ((c + 1) * (x * 2 - 2) + c) + 2) * 0.5
        end
    },
    [Enum.EasingStyle.Elastic] = {
        [Enum.EasingDirection.In] = function(x:number)
            local c = (2 * pi) / 3
            if x == 0 or x == 1 then return x end
            return -(2^(10 * x - 10)) * sin((x * 10 - 10.75) * c)
        end,
        [Enum.EasingDirection.Out] = function(x:number)
            local c = (2 * pi) / 3
            if x == 0 or x == 1 then return x end
            return (2^(-10 * x)) * sin((x * 10 - 0.75) * c) + 1
        end,
        [Enum.EasingDirection.InOut] = function(x:number)
            local c = (2 * pi) / 4.5
            if x == 0 or x == 1 then return x end
            return x < 0.5 and -(2^(20 * x - 10) * sin((20 * x - 11.125) * c)) * 0.5 or (2^(-20 * x + 10) * sin((20 * x - 11.125) * c)) * 0.5 + 1
        end
    },
    [Enum.EasingStyle.Bounce] = {
        [Enum.EasingDirection.In] = function(x:number)
            return 1 - BounceOut(1 - x)
        end,
        [Enum.EasingDirection.Out] = function(x:number)
            return BounceOut(x)
        end,
        [Enum.EasingDirection.InOut] = function(x:number)
            return x < 0.5 and (1 - BounceOut(1 - 2 * x)) * 0.5 or (1 + BounceOut(2 * x -1)) * 0.5
        end
    }
}

local CustomGraphs : {[string]: (number)->(number)} = {

}

function Hermite:Graph(X:number, Type:Enum.EasingStyle, Way:Enum.EasingDirection):number
    X = xCheck(X, true)
    local fn = EasingGraphs[Type]
    if not fn then
        if doWarn then
            warn("! [Hermite]: Graph aborted: unsupported easing style.")
        end
        return 0
    end
    return fn[Way](X)
end

function Hermite:Custom(X:number, Formula:(number)->number, Check:boolean):number
    local res = X
    if Check then
        res = xCheck(X, true)
    end
    return Formula(res)
end

function Hermite:Sample(Id:string, Formula:(number)->number):(number)->(number)
    CustomGraphs[Id] = Formula
    return Formula
end

function Hermite:Evaluate(Id:string, X:number):number
    local Formula = CustomGraphs[Id]
    if not Formula then
        if doWarn then
            warn("! [Hermite]: Evaluate aborted: unable to find formula.")
        end
        return 0
    end
    return Formula(X)
end

function Hermite:Erase(Id:string):number
    CustomGraphs[Id] = nil
    return 0
end

function Hermite:Spline(X:number, Points:{SplinePoint}, Order:boolean):number
    if Order then
        sort(Points)
    end
    local xc = xCheck(X, false)
    local Segments = #Points - 1
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
    local CurrentT = t > Segments and 1 or (t - (Part - 1))

    local p0 = Points[Part].Point
    local p1 = Points[Part + 1].Point
    local d0 = Points[Part].Degree
    local d2 = Points[Part + 1].Degree

    local t2 = CurrentT^2
    local t3 = CurrentT^3

    local h0 = 2 * t3 - 3 * t2 + 1
    local h1 = -2 * t3 + 3 * t2
    local h2 = t3 - 2 * t2 + CurrentT
    local h3 = t3 - t2
    return p0 * h0 + d0 * h2 + p1 * h1 + d2 * h3
end

function Hermite:DefineWarn(Warn:boolean):boolean
    doWarn = Warn
    return Warn
end

function Hermite:Step(X:number, Steps:number):number
    return floor(X * Steps) / Steps
end

return Hermite