$ = (q) ->
    return document.querySelector(q)

window.onload = ->
    $('#process').onclick = process

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

