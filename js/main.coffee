#$ = (q) ->
#    return document.querySelector(q)

window.onload = ->
    $('#process').click process
    $('#idsample').click showSampleID
    $('#datasample').click showSampleData
    $('#downloadcsv').click ->
        data = $('#result').val()
        window.downloadManager = new DownloadManager('grades.csv', data, 'text/csv')
        downloadManager.download()


    # process the data whenever the textarea changes (but rate-limit the
    # frequency with which we call process)
    timer = new ExclusiveTimer
    dataAreaTracker = new TextAreaChangeTracker('#data')
    idorderAreaTracker = new TextAreaChangeTracker('#idorder')
    dataAreaTracker.change ->
        timer.setTimeout(process, 250)
    idorderAreaTracker.change ->
        timer.setTimeout(process, 250)


    process()



SAMPLE_IDS = ("V00" + Math.random().toFixed(6).slice(-6) for i in [0...20])
SAMPLE_NAMES = ["Rowden Shaun","Wetherbee Janay","Kimmell Kala","Dimmick Rikki","Storment Anitra","Karp Cassie","Mccallion Kisha","Sable Elijah","Svoboda Freeman","Reddick Trista","Sproull Deloras","Paisley Kerry","Furby Weston","Reyes Shiela","Ballou Clement","Woolum Gala","Desilets Stacey","Rickel Alethea","Royston Peg","Marlar Annamaria"]

showSampleID = ->
    $('#idorder').val(SAMPLE_IDS.join('\n'))
    $('#idorder').change()
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
        sliceAmount = if Math.random() < .2 then -5 else -6
        ret += paddWithSpace(ids[i].slice(sliceAmount), 11)
        ret += paddWithSpace(scores[i], 5)
        ret += scores[i]*5
        lines.push ret
    lines.sort()
    $('#data').val(lines.join('\n'))
    $('#data').change()


capitalizeName = (name) ->
    name = name.toLowerCase().split(/\W+/)
    return (s.charAt(0).toUpperCase() + s.slice(1) for s in name).join(' ')

# given a list of ids in the appropriate order,
# returns a list of the same length in the same order containing
# the student names and scores listed in data corresponding to the appropriate IDs
createMergedTable = (idList=[], data) ->
    errors = []

    # create a hash based in ids from data, adding any collisions to errors
    idHash = {}
    duplicateIdHash = {}
    for s in data
        # if the id doesnt exist, create an entry for it
        if not idHash[s.id]?
            idHash[s.id] = s
        # if it does exist, add it to the duplicates list
        else
            duplicateIdHash[s.id] = (duplicateIdHash[s.id] || [idHash[s.id]])
            duplicateIdHash[s.id].push s
    for id,l of duplicateIdHash
        delete idHash[id]
        for s in l
            errors.push {originalLine: s.originalLine, included: false, reason: "Parsed ID 'V00#{s.id}' appeared multiple times"}

    ret = []
    # if we passed in an empty ID list, we just return all the data in no particular order
    if idList.length is 0
        for id,s of idHash
            ret.push s
    else
        for id in idList
            ret.push(idHash[id] || {id: id})
            if idHash[id]?
                idHash[id].included = true
        # things that didn't get included are errors
        for id,s of idHash
            if not s.included
                errors.push {originalLine: s.originalLine, included: false, reason: "No matching ID found in ID List"}

    return {lines: ret, errors: errors}

idsToList = (str) ->
    ids = str.split(/\D+/)
    ids = (s.slice(-6) for s in ids when s.match(/\d{6}$/))
    return ids


process = ->
    idList = idsToList($('#idorder')[0].value)
    {lines: scantronData, errors: processingErrors} = scantronSummaryToList($('#data')[0].value)
    {lines: outputList, errors: mergingErrors} = createMergedTable(idList, scantronData)

    errors = processingErrors.concat(mergingErrors)

    csv = ("V00#{s.id},#{s.score || ''},\"#{s.name|| ''}\"" for s in outputList).join('\n')
    $('#result')[0].value = csv

    tbody = $('#errors-table tbody')
    tbody.empty()
    for err in errors
        tbody.append """<tr>
                            <td class='data'>#{err.originalLine}</td>
                            <td class='included-#{!!err.included}'>#{if err.included then 'Yes' else 'No'}</td>
                            <td class='reason'>#{err.reason}</td>
                        </tr>"""
    if errors.length > 0
        $('#error-area').show()
    else
        $('#error-area').hide()



    return

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
        ret.id = id
        ret.score = l[idIndex + 1]
        ret.name = capitalizeName(l.slice(0,idIndex).join(' '))
        ret.percent = l[idIndex + 2]

        return ret

    lines = []
    erroniousLines = []
    for l in s.split(/\n/)
        # the header in the email has two special lines, we don't need
        # to report tham as errors if the user has accidentally included them
        if l.match(/SUMMARY SHEET/) or l.match(/SCORE PERCENT/)
            continue
        try
            lines.push processLine(l)
        catch e
            if e.originalLine?.match(/\w/)
                erroniousLines.push {originalLine: e.originalLine, reason: 'Could not parse student ID'}
    return {lines:lines, errors: erroniousLines}

###
# ExclusiveTimer keeps a queue of all timeout
# callbacks, but only issues the most recent one.
# That is, if another callback request is added before the
# timer on the previous one runs out, only the new one is executed
# (when it's time has elapased) and the previous one is ignored.
###
class ExclusiveTimer
    constructor: ->
        @queue = []
    setTimeout: (callback, delay) ->
        for c in @queue
            c.execute = false
        myIndex = @queue.length
        @queue.push {callback: callback, execute: true}

        doCallback = =>
            if @queue[myIndex]?.execute
                @queue[myIndex].callback()
                @queue.length = 0

        window.setTimeout(doCallback, delay)

###
# Keep track of all changes to a particular textarea
# including ones that may happen on keyup, keydown, blur,
# etc.
###
class TextAreaChangeTracker
    constructor: (@textarea) ->
        @textarea = $(@textarea)
        @value = @textarea.val()
        @onchangeCallbacks = []

        @textarea.change => window.setTimeout(@_triggerIfChanged,100)
        @textarea.keydown => window.setTimeout(@_triggerIfChanged,100)
        @textarea.keypress => window.setTimeout(@_triggerIfChanged,100)
        @textarea.blur => window.setTimeout(@_triggerIfChanged,100)

    _triggerIfChanged: =>
        #@textarea.blur()
        newVal = @textarea[0].value
        if newVal != @value
            @value = newVal
            for c in @onchangeCallbacks
                c()
    change: (callback) ->
        @onchangeCallbacks.push callback

###
# Various methods of downloading data to the users compuer so they can save it.
# Initially DownloadManager.download will try to bounce off download.php,
# a server-side script that sends the data it receives back with approprate
# headers. If this fails, it will try to use the blob API to and the
# 'download' attribute of an anchor to download the file with a suggested file name.
# If this fails, a dataURI is used.
###
class DownloadManager
    DOWNLOAD_SCRIPT: 'download.php'
    constructor: (@filename, @data, @mimetype='application/octet-stream') ->
    # a null status means no checks have been performed on whether that method will work
        @downloadMethodAvailable =
            serverBased: null
            blobBased: null
            dataUriBased: null

    # run through each download method and if it works,
    # use that method to download the graph. @downloadMethodAvailable
    # starts as all null and will be set to true or false after a test has been run
    download: () =>
        if @downloadMethodAvailable.serverBased == null
            @testServerAvailability(@download)
            return
        if @downloadMethodAvailable.serverBased == true
            @downloadServerBased()
            return

        if @downloadMethodAvailable.blobBased == null
            @testBlobAvailability(@download)
            return
        if @downloadMethodAvailable.blobBased == true
            @downloadBlobBased()
            return

        if @downloadMethodAvailable.dataUriBased == null
            @testDataUriAvailability(@download)
            return
        if @downloadMethodAvailable.dataUriBased == true
            @downloadDataUriBased()
            return

    testServerAvailability: (callback = ->) =>
        $.ajax
            url: @DOWNLOAD_SCRIPT
            dataType: 'text'
            success: (data, status, response) =>
                if response.getResponseHeader('Content-Description') is 'File Transfer'
                    @downloadMethodAvailable.serverBased = true
                else
                    @downloadMethodAvailable.serverBased = false
                callback.call(this)
            error: (data, status, response) =>
                @downloadMethodAvailable.serverBased = false
                callback.call(this)

    testBlobAvailability: (callback = ->) =>
        if (window.webkitURL or window.URL) and (window.Blob or window.MozBlobBuilder or window.WebKitBlobBuilder)
            @downloadMethodAvailable.blobBased = true
        else
            @downloadMethodAvailable.blobBased = true
        callback.call(this)

    testDataUriAvailability: (callback = ->) =>
        # not sure how to check for this ...
        @downloadMethodAvailable.dataUriBased = true
        callback.call(this)

    downloadServerBased: () =>
        input1 = $('<input type="hidden"></input>').attr({name: 'filename', value: @filename})
        # encode our data in base64 so it doesn't get mangled by post (i.e., so '\n' to '\n\r' doesn't happen...)
        input2 = $('<input type="hidden"></input>').attr({name: 'data', value: btoa(@data)})
        input3 = $('<input type="hidden"></input>').attr({name: 'mimetype', value: @mimetype})
        # target=... is set to our hidden iframe so we don't change the url of our main page
        form = $('<form action="'+@DOWNLOAD_SCRIPT+'" method="post" target="downloads_iframe"></form>')
        form.append(input1).append(input2).append(input3)

        # submit the form and hope for the best!
        form.appendTo(document.body).submit().remove()

    downloadBlobBased: (errorCallback=@download) =>
        try
            # first convert everything to an arraybuffer so raw bytes in our string
            # don't get mangled
            buf = new ArrayBuffer(@data.length)
            bufView = new Uint8Array(buf)
            for i in [0...@data.length]
                bufView[i] = @data.charCodeAt(i) & 0xff

            try
                # This is the recommended method:
                blob = new Blob(buf, {type: 'application/octet-stream'})
            catch e
                # The BlobBuilder API has been deprecated in favour of Blob, but older
                # browsers don't know about the Blob constructor
                # IE10 also supports BlobBuilder, but since the `Blob` constructor
                # also works, there's no need to add `MSBlobBuilder`.
                bb = new (window.WebKitBlobBuilder || window.MozBlobBuilder)
                bb.append(buf)
                blob = bb.getBlob('application/octet-stream')

            url = (window.webkitURL || window.URL).createObjectURL(blob)

            downloadLink = $('<a></a>').attr({href: url, download: @filename})
            $(document.body).append(downloadLink)
            # trigger the file save dialog
            downloadLink[0].click()
            # clean up when we're done
            downloadLink.remove()
        catch e
            @downloadMethodAvailable.blobBased = false
            errorCallback.call(this)

    downloadDataUriBased: () =>
        document.location.href = "data:application/octet-stream;base64," + btoa(@data)
