using ModelingToolkit
@info "定义接口..."
@connector function StreamNode(; name)
    sts = @variables begin
        p(t0) = 1.0e5
        t(t0) = 300.0
        s(t0) = 1.0e5
    end
    ODESystem(Equation[], t0, sts, []; name=name)
end
function StreamPort(; name)
    @named in = StreamNode()
    @named out = StreamNode()
    sts = @variables begin
        Δp(t0) = 1.0e5
        Δt(t0) = 300.0
        Δs(t0) = 1.0e5
    end
    eqs = [
        Δp ~ out.p - in.p
        Δt ~ out.t - in.t
        Δs ~ out.s - in.s
    ]
    compose(ODESystem(eqs, t0, sts, []; name=name), in,out)
end

@info "定义组件..."
# 汽轮机turbine
function Turbine(; name,P = 4000)
    @named oneport = StreamPort()
    @unpack Δs, out = oneport
    ps = @parameters P = P
    eqs = [
        out.p ~ P
        out.t ~ PropsSI("T", "P", out.p, "S",out.s, fluid)
        Δs ~ 0
         #等熵过程
        ]
    return extend(ODESystem(eqs, t0, [], ps; name=name), oneport)
end

# 冷凝器condenser
function Condenser(; name)
    @named oneport = StreamPort()
    @unpack Δt, out = oneport
    eqs = [
        out.p ~ PropsSI("P", "T", out.t, "Q", 0, fluid)                              
        out.s ~ PropsSI("S", "T", out.t, "Q", 0, fluid)
        Δt ~ 0  #等温过程
    ]
    return extend(ODESystem(eqs, t0, [], []; name=name), oneport)
end

# 水泵pump
function Pump(; name, P = 3000000)
    @named oneport = StreamPort()
    @unpack Δs, out = oneport
    ps = @parameters P = P
    eqs = [
        out.p ~ P
        out.t ~ PropsSI("T", "P", out.p, "S",out.s, fluid)
        Δs ~ 0 #等熵过程
        ]
    return extend(ODESystem(eqs, t0, [], ps; name=name), oneport)
end
#eqs = equations(pump)

# 锅炉boiler
function Boiler(; name, T = 700 +273.15 )
    @named oneport = StreamPort()
    @unpack Δp, out = oneport
    ps = @parameters T = T
    #sts = @variables T(t0) pp(t0)
    #ps = @parameters Tmax = Tmax
    #Dt(T) = ifelse(T>Tmax, 0.0, 10.0)
    eqs = [
        out.t ~ T
        out.s ~ PropsSI("S", "T", out.t, "P",out.p, fluid)
        Δp ~ 0 #等压过程
    ]
    return extend(ODESystem(eqs, t0, [], ps; name=name), oneport)
end

