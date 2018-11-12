
abstract type StateSpaceModel <: Evolution
end

#=struct BiBlock{T1,T21,T22}
    L1::T1
    L21::T21
    L22::T22
end=#

struct StateObs{T,S}
    x::T
    obs::S
end

function rand(rng::AbstractRNG, U::StateObs)
    x = rand(rng, U.x)
    y = rand(rng, U.obs(Gaussian(x, false*I)))
    x, y
end

"""
```
LinearStateSpaceModel <: StateSpaceModel

LinearStateSpaceModel(sys, obs, prior)
```

Combines a linear system `sys`, an observations model `obs` and
a `prior` to a linear statespace model in a modular way. See [LinearHomogSystem`](@ref)
for a "batteries included" complete linear system.
"""
struct LinearStateSpaceModel{Tsys,Tobs} <: StateSpaceModel
    sys::Tsys
    obs::Tobs
end

function evolve(SSM::LinearStateSpaceModel, (t, x)::Pair{<:Any, <:Gaussian})
    t, x = evolve(SSM.sys, t => x)
    t => StateObs(x, SSM.obs)
end

function evolve(SSM::LinearStateSpaceModel, (t, (x,y))::Pair{<:Any, <:Tuple})
    t, x = evolve(SSM.sys, t => x)
    t => StateObs(x, SSM.obs)
end

dims(SSM) = size(SSM.H)

llikelihood(SSM, yres, S) = logpdf(Gaussian(zero(yres), S), yres)
