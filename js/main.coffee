$ = (q) ->
    return document.querySelector(q)

window.onload = ->
    $('#process').onclick = process
    $('#idsample').onclick = showSampleID
    $('#datasample').onclick = showSampleData



SAMPLE_IDS = ("V00" + Math.random().toFixed(6).slice(-6) for i in [0...20])
SAMPLE_NAMES = ["Rowden Shaun","Wetherbee Janay","Kimmell Kala","Dimmick Rikki","Storment Anitra","Karp Cassie","Mccallion Kisha","Sable Elijah","Svoboda Freeman","Reddick Trista","Sproull Deloras","Paisley Kerry","Furby Weston","Reyes Shiela","Ballou Clement","Woolum Gala","Desilets Stacey","Rickel Alethea","Royston Peg","Marlar Annamaria"]

showSampleID = ->
    $('#idorder').value = SAMPLE_IDS.join('\n')
showSampleData = ->
    paddWithSpace = (s, n) ->
        return (s + "                    ").slice(0,n)
    longNames = (paddWithSpace(n.toUpperCase(), 20) for n in SAMPLE_NAMES)
    ids = SAMPLE_IDS.slice()
    ids.sort()
    scores = (Math.round(Math.random()*20) for i in [0...20])

    # make the actual sample data
    # NAME(20) ID(11) SCORE(5) PERCENT(2)
    lines = []
    for i in [0...10]
        ret = ''
        ret += longNames[i]
        ret += paddWithSpace(ids[i].slice(-6), 11)
        ret += paddWithSpace(scores[i], 5)
        ret += scores[i]*5
        lines.push ret
    lines.sort()
    $('#data').value = lines.join('\n')


capitalizeName = (name) ->
    name = name.toLowerCase().split(/\W+/)
    return (s.charAt(0).toUpperCase() + s.slice(1) for s in name).join(' ')

process = ->
    idorder = $('#idorder').value.split(/\D+/)
    idorder = (s.slice(-6) for s in idorder when s.match(/\d{6}$/))

    summaryList = scantronSummaryToList($('#data').value)
    summaryHash = {}
    for l in summaryList
        summaryHash[l.id] = l

    output = ""
    for id in idorder
        output += "#{id},#{summaryHash[id]?.score || ''},\"#{summaryHash[id]?.name || ''}\"\n"

    $('#result').value = output

# process scatron data assumed to be of the form "LAST FIRST ?? ID SCORE PERCENT\n"
scantronSummaryToList = (s) ->
    # given a line of the appropriate form, return an object with 
    # the data split up
    processLine = (l) ->
        l = l.split(/\s+/)
        idIndex = null
        # the most robust way to parse these is to first find where the ID
        # is then look backwards and forwards from there.  It should be
        # the first thing we encounter with 6 decimal digits
        for str,i in l
            if str.match(/\d{6}$/)
                idIndex = i
                break
        if not idIndex?
            throw new Error("Could not find id in \'#{l}'")
        ret = {}
        ret.id = l[idIndex].slice(-6)
        ret.score = l[idIndex + 1]
        ret.name = capitalizeName(l.slice(0,idIndex).join(' '))
        ret.percent = l[idIndex + 2]

        return ret

    lines = []
    for l in s.split(/\n/)
        try
            lines.push processLine(l)
        catch e
            console.log e
    return lines

