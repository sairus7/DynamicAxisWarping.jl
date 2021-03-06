using DynamicAxisWarping, Plots

fs = 70
t  = range(0,stop=1,step=1/fs)
y0 = sin.(2pi .*t)
y1 = sin.(3pi .*t)
y  = [y0;y1[2:end]] .+ 0.01 .* randn.()
q  = [y0;y0[2:end]] .+ 0.01 .* randn.()

y[10:15] .+= 0.5
q[13:25] .+= 0.5


##
f1 = plot([q y])
f2 = dtwplot(q,y,lc=:green, lw=1)
f3 = matchplot(q,y,ds=3,separation=1)
plot(f1,f2,f3, legend=false, layout=3, grid=false)

##

svec = exp10.(LinRange(-3, 1, 500))
res = map(svec) do s
    y  = [y0;y1[2:end]] .+ s .* randn.()
    q  = [y0;y0[2:end]] .+ s .* randn.()
    c,i1,i2 = dtw(q,y, transportcost=1.05)
    ni = length(y)
    length(i1) - findfirst(==(ni), i1) + 1
end
scatter(svec, res, xscale=:log10, xlabel="Noise std", ylabel="N points matched to last")
