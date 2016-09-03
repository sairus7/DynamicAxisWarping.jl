using TimeWarp
using TimeWarp.WarpPlots
pyplot() # use pyplot

# UCI data repository must be downloaded first, run TimeWarp.download_data()
data = TimeWarp.traindata("gun_point");

class = round(Int,data[:,1])
y = data[:,2:end]'

# c = [ cl==1 ? :blue : :red for cl in class ]'
# plot(y, linecolor=c, legend=false)

avg, result = dba([Sequence(y[:,i]) for i in 1:size(y,2)])

plot(y, linecolor=:grey, legend=false)
plot!(avg, linecolor=:red, legend=false, line=(2))
