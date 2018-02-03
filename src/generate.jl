import Distributions.sample

""" 
    randmvn(S)

Sampling singular semidefinite multivariate normal distributions ``x ~ N(0, A)``

```
S = cholfact(A, :L, Val{true})
x = randmvn(S)
```


"""
randmvn(S) = ipermute!(S[:L]*permute!(randn(size(S,1)),S[:p]), S[:p])

function randmvn(S::Base.LinAlg.CholeskyPivoted, n) 
    d = size(S,1)
    Z = zeros(d, n)
    for i in 1:n
        Z[:,i] = randmvn(S)
    end
    Z
end

"""
Y, X = sample(n, m, M::LinearHomogSystem) 

Sample observations

n -- number of observations per simulation
m -- number of independent simulations
M -- linear dynamic system and observation model

Y -- observations (d2xnxm array)
X -- simulated processes (dxnxm array)

"""
function sample(n, m, M::LinearHomogSystem{Vector{T}}) where {T} 

    H, Phi, b = M.H, M.Phi, M.b

    d2, d = size(M.H)

    
    X = zeros(d, n, m)
    Y = zeros(d2, n, m)



    Nv = MvNormal(zeros(d2), M.R)
    S = cholfact(M.Q, :L, Val{true}) # allow singular Q
    Sx0 = cholfact(M.P0, :L, Val{true}) #  
    #Nw = MvNormal(zeros(d), M.Q)
    #Nx0 = MvNormal(M.x0, M.P0)    

    for j in 1:m
        x = M.x0 + randmvn(Sx0)
        V = rand(Nv, n)
        W = randmvn(S, n)
        X[.., 1, j] = Phi*x + b + W[:, 1]
        Y[.., 1, j] = H*x + V[:, 1]
        for i in 2:n
            x[:] = Phi*x + b + W[:, i]
            X[.., i, j] = x
            Y[.., i, j] = H*x + V[:, i]
        end

    end

    return Y, X
end


function sample(n, m, M::LinearHomogSystem{Tx, TP, Ty}) where {Tx, TP, Ty} 

    H, Phi, b = M.H, M.Phi, M.b
    
    X = zeros(Tx, n, m)
    Y = zeros(Ty, n, m)


    Nx0 = Gaussian(M.x0, M.P0)
    Nw = Gaussian(zero(Tx), M.Q)
    Nv = Gaussian(zero(Ty), M.R)
    
    for j in 1:m
        x = rand(Nx0)
        V = rand(Nv, (n,))
        W = rand(Nv, (n,))
        X[1, j] = Phi*x + b + W[1]
        Y[1, j] = H*x + V[1]
        for i in 2:n
            x = Phi*x + b + W[i]
            X[i, j] = x
            Y[i, j] = H*x + V[i]
        end

    end

    return Y, X
end

function sample(n, M)
    Y, X = sample(n, 1, M)
    squeeze(Y, ndims(Y)), squeeze(X, ndims(X))
end