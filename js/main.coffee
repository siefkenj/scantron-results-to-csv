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

    {lines: summaryList, erroniousLines:erroniousLines} = scantronSummaryToList($('#data').value)
    # if we ever have an id collision, make sure to track it!
    duplicatesHash = {}
    summaryHash = {}
    for l in summaryList
        if not summaryHash[l.id]?
            summaryHash[l.id] = l
        else
            duplicatesHash[l.id] = (duplicatesHash[l.id] || [summaryHash[l.id]])
            duplicatesHash[l.id].push l
    # if we had a collision, it is best to just not report the score
    for h,l of duplicatesHash
        delete summaryHash[h]

    output = ""
    for id in idorder
        output += "V00#{id},#{summaryHash[id]?.score || ''},\"#{summaryHash[id]?.name || ''}\"\n"
        if summaryHash[id]
            summaryHash[id].used = true

    unused = (v for k,v of summaryHash when not v.used)
    errorOutput = ""
    if unused.length > 0
        errorOutput += "Tests with unmatched student numbers:\n"
        for dat in unused
            errorOutput +=  dat.originalLine + "\n" #"V00#{dat.id},#{dat?.score || ''},\"#{dat?.name || ''}\"\n"
        errorOutput += "\n\n"
    if erroniousLines.length > 0
        errorOutput += "Lines that could not be processed:\n"
        for l in erroniousLines
            errorOutput += l + '\n'
        errorOutput += "\n\n"
    if Object.keys(duplicatesHash).length > 0
        errorOutput += "Lines with IDs interpreted identically (scores not reported):\n"
        for h,l of duplicatesHash
            console.log duplicatesHash
            for v in l
                errorOutput += v.originalLine + '\n'
            errorOutput += '\n'
        errorOutput += "\n\n"

    badBubblers = (l for l in summaryList when l.badBubbling)
    if badBubblers.length > 0
        errorOutput += "Students who incorrectly filled out bubble sheet (scores may be reported):\n"
        for l in badBubblers
            errorOutput += l.originalLine + '\n'
        errorOutput += "\n\n"




    $('#result').value = output
    $('#errors').value = errorOutput


# process scatron data assumed to be of the form "LAST FIRST ?? ID SCORE PERCENT\n"
scantronSummaryToList = (s) ->
    # given a line of the appropriate form, return an object with
    # the data split up
    processLine = (l) ->
        originalLine = l
        # names and IDs aren't always separated by whitespace, so add some whitespace
        # in so things split correct if theres ever a letter right next to a number
        l = l.replace(/([a-zA-Z])(\d)/g, "$1 $2").split(/\s+/)
        idIndex = null
        # the most robust way to parse these is to first find where the ID
        # is then look backwards and forwards from there.  It should be
        # the first thing we encounter with 6 decimal digits
        for str,i in l
            if str.match(/\d{6}$/)
                idIndex = i
                break
        if not idIndex? or l[idIndex].length < 6
            e = new Error("Could not find id in \'#{l}'")
            e.originalLine = originalLine
            throw e
        ret = {originalLine: originalLine}
        # we use a huristic for identifying a 6 digit id.  Common student
        # errors are to enter a leading zero 0757575 or to repeat the last
        # digit twice 7575755, so try to extract a real student ID if the length is wrong
        id = l[idIndex]
        if id.length > 6
            oldID = id
            ret.badBubbling = true
            if id.charAt(0) is '0'
                id = id.slice(-6)
            else
                id = id.slice(0,6)
            console.log oldID, id
        ret.id = id
        ret.score = l[idIndex + 1]
        ret.name = capitalizeName(l.slice(0,idIndex).join(' '))
        ret.percent = l[idIndex + 2]

        return ret

    lines = []
    erroniousLines = []
    for l in s.split(/\n/)
        try
            lines.push processLine(l)
        catch e
            if e.originalLine?.match(/\w/)
                erroniousLines.push e.originalLine
            console.log e
    return {lines:lines, erroniousLines: erroniousLines}

