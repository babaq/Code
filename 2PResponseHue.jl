
# Peichao's Notes:
# 1. Code was written for 2P data (Direction-Spatial frequency-Hue test) from Scanbox. Will export results (dataframe and csv) for plotting.
# 2. If you have multiple planes, it works with splited & interpolated dat. Note results are slightly different.
# 3. If you have single plane, need to change the code (signal and segmentation) a little bit to make it work.

using NeuroAnalysis,Statistics,DataFrames,DataFramesMeta,StatsPlots,Mmap,Images,StatsBase,Interact, CSV,MAT, DataStructures, HypothesisTests, StatsFuns, Random

# Expt info
disk = "O:"
subject = "AF4"  # Animal
recordSession = "005" # Unit
testId = "007"  # Stimulus test
hueSpace = "DKL"
interpolatedData = true   # If you have multiplanes. True: use interpolated data; false: use uniterpolated data. Results are slightly different.
preOffset = 0.1
responseOffset = 0.05
α = 0.05   # p value
isplot = false

## Prepare data & result path
exptId = join(filter(!isempty,[recordSession, testId]),"_")
dataFolder = joinpath(disk,subject, "2P_data", join(["U",recordSession]), exptId)
metaFolder = joinpath(disk,subject, "2P_data", join(["U",recordSession]), "metaFiles")

## load expt, scanning parameters
metaFile=matchfile(Regex("[A-Za-z0-9]*$testId[A-Za-z0-9]*_[A-Za-z0-9]*_meta.mat"),dir=metaFolder,adddir=true)[1]
dataset = prepare(metaFile)
ex = dataset["ex"]
envparam = ex["EnvParam"]
sbx = dataset["sbx"]["info"]

## Align Scan frames with stimulus
# Calculate the scan parameters
scanFreq = sbx["resfreq"]
lineNum = sbx["sz"][1]
if haskey(sbx, "recordsPerBuffer_bi")
   scanMode = 2  # bidirectional scanning   # if process Splitted data, =1
else
   scanMode = 1  # unidirectional scanning
end
sbxfs = 1/(lineNum/scanFreq/scanMode)   # frame rate
trialOnLine = sbx["line"][1:2:end]
trialOnFrame = sbx["frame"][1:2:end] + round.(trialOnLine/lineNum)        # if process splitted data use frame_split
trialOffLine = sbx["line"][2:2:end]
trialOffFrame = sbx["frame"][2:2:end] + round.(trialOnLine/lineNum)    # if process splitted data use frame_split

# On/off frame indces of trials
trialEpoch = Int.(hcat(trialOnFrame, trialOffFrame))
# minTrialDur = minimum(trialOffFrame-trialOnFrame)
# histogram(trialOffFrame-trialOnFrame,nbins=20,title="Trial Duration(Set to $minTrialDur)")

# Transform Trials ==> Condition
ctc = DataFrame(ex["CondTestCond"])
trialNum =  size(ctc,1)
conditionAll = condin(ctc)
# Remove extra conditions (only for AF4), and seperate blanks
others = (:ColorID, [27,28,36])
ci = .!in.(conditionAll[!,others[1]],[others[2]])
# factors = finalfactor(conditionAll)
conditionCond = conditionAll[ci,:]
condNum = size(conditionCond,1) # not including blanks

# Extract blank condition
blank = (:ColorID, 36)
bi = in.(conditionAll[!,blank[1]],[blank[2]])
conditionBlank = conditionAll[bi,:]
# replace!(bctc.ColorID, 36 =>Inf)

# Change ColorID ot HueAngle if needed
if hueSpace == "DKL"
    ucid = sort(unique(conditionCond.ColorID))
    hstep = 360/length(ucid)
    conditionCond.ColorID = (conditionCond.ColorID.-minimum(ucid)).*hstep
    conditionCond=rename(conditionCond, :ColorID => :HueAngle)
end


# On/off frame indces of condations/stimuli
preStim = ex["PreICI"]; stim = ex["CondDur"]; postStim = ex["SufICI"]
trialOnTime = fill(0, trialNum)
condOfftime = preStim + stim
preEpoch = [0 preStim-preOffset]
condEpoch = [preStim+responseOffset condOfftime-responseOffset]
preFrame=epoch2samplerange(preEpoch, sbxfs)
condFrame=epoch2samplerange(condEpoch, sbxfs)
# preOn = fill(preFrame.start, trialNum)
# preOff = fill(preFrame.stop, trialNum)
# condOn = fill(condFrame.start, trialNum)
# condOff = fill(condFrame.stop, trialNum)

## Load data
segmentFile=matchfile(Regex("[A-Za-z0-9]*[A-Za-z0-9]*_merged.segment"),dir=dataFolder,adddir=true)[1]
segment = prepare(segmentFile)
signalFile=matchfile(Regex("[A-Za-z0-9]*[A-Za-z0-9]*_merged.signals"),dir=dataFolder,adddir=true)[1]
signal = prepare(signalFile)
sig = transpose(signal["sig"])   # 1st dimention is cell roi, 2nd is fluorescence trace
spks = transpose(signal["spks"])  # 1st dimention is cell roi, 2nd is spike train

# planeNum = size(segment["mask"],3)  # how many planes
planeNum = 1
planeStart = 1

## Use for loop process each plane seperately
# for pn in 1:planeNum
pn=1  # for test
global planeStart
display(planeStart)
# Initialize DataFrame for saving results
recordPlane = string("00",pn-1)  # plane/depth, this notation only works for expt has less than 10 planes
siteId = join(filter(!isempty,[recordSession, testId, recordPlane]),"_")
dataExportFolder = joinpath(disk,subject, "2P_analysis", join(["U",recordSession]), siteId, "DataExport")
resultFolder = joinpath(disk,subject, "2P_analysis", join(["U",recordSession]), siteId, "Plots")
isdir(dataExportFolder) || mkpath(dataExportFolder)
isdir(resultFolder) || mkpath(resultFolder)
result = DataFrame()

cellRoi = segment["seg_ot"]["vert"][pn]   # ???? Note: this vert structure was saved for Python, col and row are reversed.
cellNum = length(cellRoi)
display(cellNum)
cellId = collect(range(1, step=1, stop=cellNum))  # Currently, the cellID is the row index of signal

if interpolatedData
    rawF = sig[planeStart:planeStart+cellNum-1,:]
    # spike = spks[planeStart:planeStart+cellNum-1,:]
else
    rawF = transpose(signal["sig_ot"]["sig"][pn])
    # spike = transpose(signal["sig_ot"]["spks"][pn])
end

planeStart = planeStart+cellNum   # update, only works when planeStart is globalized
result.py = 0:cellNum-1
result.ani = fill(subject, cellNum)
result.dataId = fill(siteId, cellNum)
result.cellId = 1:cellNum

## Plot dF/F traces of all trials for all cells
# Cut raw fluorescence traces according to trial on/off time and calculate dF/F
cellTimeTrial = sbxsubrm(rawF,trialEpoch,cellId;fun=dFoF(preFrame))  # cellID x timeCourse x Trials
# Mean response within stim time
cellMeanTrial = dropdims(mean(cellTimeTrial[:,condFrame,:], dims=2), dims=2)  # cellID x Trials
# Plot
if isplot
    @manipulate for cell in 1:cellNum
        plotanalog(transpose(cellTimeTrial[cell,:,:]), fs=sbxfs, timeline=condEpoch.-preStim, xunit=:s, ystep=1,cunit=:p, color=:fire,xext=preStim)
    end
end

## Average over repeats, and put each cell's response in factor space (hue-dir-sf...), and find the maximal level of each factor
factors = finalfactor(conditionCond)
fa = OrderedDict(f=>unique(conditionCond[f]) for f in factors)  # factor levels, the last one of each factor maybe blank(Inf)
fms=[];fses=[];  # factor mean spac, factor sem space, mean and sem of each condition of each cell
ufm = Dict(k=>[] for k in keys(fa))  # maxi factor level of each cell
for cell in 1:cellNum
    # cell=1
    mseuc = condresponse(cellMeanTrial[cell,:],conditionCond)  # condtion response, averaged over repeats
    fm,fse,_  = factorresponse(mseuc)  # put condition response into factor space
    p = Any[Tuple(argmax(coalesce.(fm,-Inf)))...]
    push!(fms,fm.*100);push!(fses,fse.*100)   # change to percentage (*100)
    for f in collect(keys(fa))
        fd = findfirst(f.==keys(fa))   # facotr dimention
        push!(ufm[f], fa[f][p[fd]])  # find the maximal level of each factor
    end
end
# Plot
if isplot
    @manipulate for cell in 1:cellNum
        heatmap(fms[cell])
    end
    @manipulate for cell in 1:cellNum
        blankResp = cellMeanTrial[cell,condition[condition.HueAngle.!=Inf,:i]]  # Blank conditions
        histogram(abs.(blankResp), nbins=10)
    end
end

## Get the responsive cells & blank response
mseub=[];uresponsive=[];umodulative=[]
cti = reduce(append!,conditionCond[:, :i],init=Int[])  # Choose hue condition, exclude blanks and others
for cell in 1:cellNum
    # cell=1
    condResp = cellMeanTrial[cell,cti]  #
    push!(umodulative,ismodulative([DataFrame(Y=condResp) ctc[cti,:]], alpha=α, interact=true))  # Check molulativeness within stim conditions
    blankResp = cellMeanTrial[cell,vcat(conditionBlank[:,:i]...)]  # Choose blank conditions
    mseuc = condresponse(cellMeanTrial[cell,:],[vcat(conditionBlank[:,:i]...)]) # Get the mean & sem of blank response for a cell
    push!(mseub, mseuc)
    # isresp = []
    # for i in 1:condNum
    #     condResp = cellMeanTrial[cell,condition[i, :i]]
    #     push!(isresp, pvalue(UnequalVarianceTTest(blankResp,condResp))<α)
    # end
    # condResp = cellMeanTrial[cell,condition[(condition.Dir .==ufm[:Dir][cell]) .& (condition.SpatialFreq .==ufm[:SpatialFreq][cell]), :i][1]]
    condResp = cellMeanTrial[cell,conditionCond[(conditionCond.HueAngle .==ufm[:HueAngle][cell]).& (conditionCond.Dir .==ufm[:Dir][cell]) .& (conditionCond.SpatialFreq .==ufm[:SpatialFreq][cell]), :i][1]]
    push!(uresponsive, pvalue(UnequalVarianceTTest(blankResp,condResp))<α)   # Check responsiveness between stim condtions and blank conditions
    # push!(uresponsive,any(isresp))
    # plotcondresponse(condResp cctc)
    # foreach(i->savefig(joinpath(resultdir,"Unit_$(unitid[cell])_CondResponse$i")),[".png",".svg"])
end

visResp = uresponsive .| umodulative   # Combine responsivenness and modulativeness as visual responsiveness
display(["uresponsive:", count(uresponsive)])
display(["umodulative:", count(umodulative)])
display(["Responsive cells:", count(visResp)])
result.visResp = visResp
result.responsive = uresponsive
result.modulative = umodulative

## Check which cell is significantly tuning by orientation or direction
oripvalue=[];orivec=[];dirpvalue=[];dirvec=[];huepvalue=[];huevec=[];
for cell in 1:cellNum
    # cell=1  # for test
    # Get all trial Id of under maximal sf
    # mcti = @where(condition, :SpatialFreq .== ufm[:SpatialFreq][cell])
    mcti = conditionCond[(conditionCond.HueAngle.==ufm[:HueAngle][cell]).&(conditionCond.SpatialFreq.==ufm[:SpatialFreq][cell]), :]
    resp=[cellMeanTrial[cell,mcti.i[r][t]] for r in 1:nrow(mcti), t in 1:mcti.n[1]]
    # resu= [factorresponsestats(mcti[:dir],resp[:,t],factor=:dir) for t in 1:mcti.n[1]]
    # orivec = reduce(vcat,[resu[t].oov for t in 1:mcti.n[1]])
    pori=[];pdir=[];
    for j = 1:100
        for i=1:size(resp,1)
            shuffle!(@view resp[i,:])
        end
        resu= [factorresponsestats(mcti[:Dir],resp[:,t],factor=:Dir) for t in 1:mcti.n[1]]
        orivec = reduce(vcat,[resu[t].om for t in 1:mcti.n[1]])
        orip = hotellingt2test([real(orivec) imag(orivec)],[0 0],0.05)
        # push!(orivec, orivectemp)
        # check significance of direction selective
       oriang = angle(mean(-orivec, dims=1)[1])  # angel orthogonal to mean ori vector
       orivecdir = exp(im*oriang/2)   # dir axis vector (orthogonal to ori vector) in direction space
       dirvec = reduce(vcat,[resu[t].dm for t in 1:mcti.n[1]])
       dirp = dirsigtest(orivecdir, dirvec)
       push!(pori, orip);push!(pdir, dirp);
    end
    yso,nso,wso,iso=histrv(float.(pori),0,1,nbins=20)
    ysd,nsd,wsd,isd=histrv(float.(pdir),0,1,nbins=20)
    push!(oripvalue,mean(yso[findmax(nso)[2]])); push!(dirpvalue,mean(ysd[findmax(nsd)[2]]));
    mcti = conditionCond[(conditionCond.Dir.==ufm[:Dir][cell]).&(conditionCond.SpatialFreq.==ufm[:SpatialFreq][cell]), :]
    resp=[cellMeanTrial[cell,mcti.i[r][t]] for r in 1:nrow(mcti), t in 1:mcti.n[1]]
    phue=[];
    for j = 1:100
        for i=1:size(resp,1)
            shuffle!(@view resp[i,:])
        end
        resu= [factorresponsestats(mcti[:HueAngle],resp[:,t],factor=:HueAngle) for t in 1:mcti.n[1]]
        huevec = reduce(vcat,[resu[t].hm for t in 1:mcti.n[1]])
        huep = hotellingt2test([real(huevec) imag(huevec)],[0 0],0.05)
        push!(phue,huep)
    end
    ysh,nsh,wsh,ish=histrv(float.(phue),0,1,nbins=20)
    push!(huepvalue,mean(ysh[findmax(nsh)[2]]))
end
result.orip = oripvalue
result.dirp = dirpvalue
result.huep = huepvalue

## Get the optimal factor level using Circular Variance for each cell
ufs = Dict(k=>[] for k in keys(fa))
for u in 1:length(fms), f in collect(keys(fa))
    p = Any[Tuple(argmax(coalesce.(fms[u],-Inf)))...] # Replace missing with -Inf, then find the x-y coordinates of max value.
    fd = findfirst(f.==keys(fa))   # facotr dimention
    fdn = length(fa[f])  # dimention length/number of factor level
    p[fd]=1:fdn   # pick up a slice for plotting tuning curve
    mseuc=DataFrame(m=fms[u][p...],se=fses[u][p...],u=fill(cellId[u],fdn),ug=fill(parse(Int, recordPlane), fdn))  # make DataFrame for plotting
    mseuc[f]=fa[f]
    # The optimal dir, ori (based on circular variance) and sf (based on log10 fitting)
    push!(ufs[f],factorresponsestats(dropmissing(mseuc)[f],dropmissing(mseuc)[:m],factor=f))
    # plotcondresponse(dropmissing(mseuc),colors=[:black],projection=[],responseline=[], responsetype=:ResponseF)
    # foreach(i->savefig(joinpath(resultdir,"Unit_$(unitid[u])_$(f)_Tuning$i")),[".png"]#,".svg"])
end
result.optsf = ufs[:SpatialFreq]
tempDF=DataFrame(ufs[:Dir])
result.optdir = tempDF.od
result.dircv = tempDF.dcv
result.optori = tempDF.oo
result.oricv = tempDF.ocv
tempDF=DataFrame(ufs[:HueAngle])
result.opthue = tempDF.oh
result.huecv = tempDF.hcv
result.maxh = tempDF.maxh
result.maxhr = tempDF.maxr

# Plot tuning curve of each factor of each cell
isplot = true
if isplot
    @manipulate for u in 1:length(fms), f in collect(keys(fa))
        p = Any[Tuple(argmax(coalesce.(fms[u],-Inf)))...]  # Replace missing with -Inf, then find the x-y coordinates of max value.
        fd = findfirst(f.==keys(fa))   # facotr dimention
        fdn = length(fa[f])  # dimention length/number of factor level
        p[fd]=1:fdn  # pick up a slice for plotting tuning curve
        mseuc=DataFrame(m=fms[u][p...],se=fses[u][p...],u=fill(cellId[u],fdn),ug=fill(parse(Int, recordPlane), fdn))  # make DataFrame for plotting
        mseuc[f]=fa[f]
        plotcondresponse(dropmissing(mseuc),colors=[:black],projection=:polar,responseline=[], responsetype=:ResponseF)
    end
end

# Fitting direction and orientation tuning (need to finish)


#Save results
CSV.write(joinpath(resultFolder,join([subject,"_",siteId,"_result.csv"])), result)
save(joinpath(dataExportFolder,join([subject,"_",siteId,"_result.jld2"])), "result",result)

# end
planeStart = 1  # no clear function like Matab, reset it mannually

# Plot Spike Train for all trials of all cells
# epochext = preicidur
# @manipulate for cell in 1:cellNum
# ys,ns,ws,is = subrv(spike[cell,:],condOn,condOff,isminzero=true,shift=0)
# plotspiketrain(ys,timeline=[0,minCondDur],title="Unit_$(unitid[u])")
# end

# for u in 1:length(unitspike)
# ys,ns,ws,is = subrv(unitspike[u],condOn.-epochext,condOff.+epochext,isminzero=true,shift=epochext)
# plotspiketrain(ys,timeline=[0,minCondDur],title="Unit_$(unitid[u])")
# foreach(i->savefig(joinpath(resultdir,"Unit_$(unitid[u])_SpikeTrian$i")),[".png",".svg"])
# end

# foreach(i->cctcli[condition[i,:i]] .= i, 1:condNum)
# vcat(condition[1:end-1, :i]...)

# Tuning map
# plotunitposition(unitposition,color=map(i->HSV(2*i.oo,1,1-i.ocv),ufs[:Ori]),alpha=1)
# foreach(i->savefig(joinpath(resultdir,"UnitPosition_OriTuning$i")),[".png",".svg"])
# plotunitposition(unitposition,color=map(i->HSV(i.od,1,1-i.dcv),ufs[:Ori]),alpha=1)
# foreach(i->savefig(joinpath(resultdir,"UnitPosition_DirTuning$i")),[".png",".svg"])
# save(joinpath(resultdir,"factorresponse.jld2"),"factorstats",ufs,"fms",fms,"fses",fses,"fa",fa)

# @df DataFrame(ufs[:Ori]) corrplot([:oo :od :ocv :dcv],nbins=30)