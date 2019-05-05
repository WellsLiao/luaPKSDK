LCEaseFunc = {
    linear = function(t, d)
        return t / d
    end,
    sineIn = function(t, d)
        return -math.cos(t / d * (math.pi / 2)) + 1
    end,
    sineOut = function(t, d)
        return math.sin(t / d * (math.pi / 2))
    end,
    sineInOut = function(t, d)
        return -1 / 2 * (math.cos(math.pi * t / d) - 1)
    end,
    backIn = function(t, d)
        local s = 1.5
        local a = t / d
        return a * t * ((s + 1) * t - s)
    end,
    backOut = function(t, d)
        local s = 1.5
        local a = t / d
        return ((a - 1) * a * ((s + 1) * t + s) + 1)
    end,
    backInOut = function(t, d)
        local s = 1.5
        local a = t / d
        local s = s * 1.525
        if ((a / 2) < 1) then
            return c / 2 * (t * t * ((s + 1) * t - s))
        else
            t = t - 2
            return c / 2 * (t * t * ((s + 1) * t + s) + 2)
        end
    end,
    cubicIn = function(t, d)
        local a = t / d
        return (a) * t * t
    end,
    cubicOut = function(t, d)
        t = t / d
        return ((t - 1) * t * t + 1)
    end,
    cubicInOut = function(t, d)
        local a = t / d
        if ((a / 2) < 1) then
            return c / 2 * t * t * t
        else
            t = t - 2
            return c / 2 * (t * t * t + 2)
        end
    end
}
