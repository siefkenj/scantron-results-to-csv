// Generated by CoffeeScript 1.4.0
var $, SAMPLE_IDS, SAMPLE_NAMES, capitalizeName, i, process, scantronSummaryToList, showSampleData, showSampleID;

$ = function(q) {
  return document.querySelector(q);
};

window.onload = function() {
  $('#process').onclick = process;
  $('#idsample').onclick = showSampleID;
  return $('#datasample').onclick = showSampleData;
};

SAMPLE_IDS = (function() {
  var _i, _results;
  _results = [];
  for (i = _i = 0; _i < 20; i = ++_i) {
    _results.push("V00" + Math.random().toFixed(6).slice(-6));
  }
  return _results;
})();

SAMPLE_NAMES = ["Rowden Shaun", "Wetherbee Janay", "Kimmell Kala", "Dimmick Rikki", "Storment Anitra", "Karp Cassie", "Mccallion Kisha", "Sable Elijah", "Svoboda Freeman", "Reddick Trista", "Sproull Deloras", "Paisley Kerry", "Furby Weston", "Reyes Shiela", "Ballou Clement", "Woolum Gala", "Desilets Stacey", "Rickel Alethea", "Royston Peg", "Marlar Annamaria"];

showSampleID = function() {
  return $('#idorder').value = SAMPLE_IDS.join('\n');
};

showSampleData = function() {
  var ids, lines, longNames, n, paddWithSpace, ret, scores, _i;
  paddWithSpace = function(s, n) {
    return (s + "                    ").slice(0, n);
  };
  longNames = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = SAMPLE_NAMES.length; _i < _len; _i++) {
      n = SAMPLE_NAMES[_i];
      _results.push(paddWithSpace(n.toUpperCase(), 20));
    }
    return _results;
  })();
  ids = SAMPLE_IDS.slice();
  ids.sort();
  scores = (function() {
    var _i, _results;
    _results = [];
    for (i = _i = 0; _i < 20; i = ++_i) {
      _results.push(Math.round(Math.random() * 20));
    }
    return _results;
  })();
  lines = [];
  for (i = _i = 0; _i < 10; i = ++_i) {
    ret = '';
    ret += longNames[i];
    ret += paddWithSpace(ids[i].slice(-6), 11);
    ret += paddWithSpace(scores[i], 5);
    ret += scores[i] * 5;
    lines.push(ret);
  }
  lines.sort();
  return $('#data').value = lines.join('\n');
};

capitalizeName = function(name) {
  var s;
  name = name.toLowerCase().split(/\W+/);
  return ((function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = name.length; _i < _len; _i++) {
      s = name[_i];
      _results.push(s.charAt(0).toUpperCase() + s.slice(1));
    }
    return _results;
  })()).join(' ');
};

process = function() {
  var id, idorder, l, output, s, summaryHash, summaryList, _i, _j, _len, _len1, _ref, _ref1;
  idorder = $('#idorder').value.split(/\D+/);
  idorder = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = idorder.length; _i < _len; _i++) {
      s = idorder[_i];
      if (s.match(/\d{6}$/)) {
        _results.push(s.slice(-6));
      }
    }
    return _results;
  })();
  summaryList = scantronSummaryToList($('#data').value);
  summaryHash = {};
  for (_i = 0, _len = summaryList.length; _i < _len; _i++) {
    l = summaryList[_i];
    summaryHash[l.id] = l;
  }
  output = "";
  for (_j = 0, _len1 = idorder.length; _j < _len1; _j++) {
    id = idorder[_j];
    output += "" + id + "," + (((_ref = summaryHash[id]) != null ? _ref.score : void 0) || '') + ",\"" + (((_ref1 = summaryHash[id]) != null ? _ref1.name : void 0) || '') + "\"\n";
  }
  return $('#result').value = output;
};

scantronSummaryToList = function(s) {
  var l, lines, processLine, _i, _len, _ref;
  processLine = function(l) {
    var idIndex, ret, str, _i, _len;
    l = l.split(/\s+/);
    idIndex = null;
    for (i = _i = 0, _len = l.length; _i < _len; i = ++_i) {
      str = l[i];
      if (str.match(/\d{6}$/)) {
        idIndex = i;
        break;
      }
    }
    if (!(idIndex != null)) {
      throw new Error("Could not find id in \'" + l + "'");
    }
    ret = {};
    ret.id = l[idIndex].slice(-6);
    ret.score = l[idIndex + 1];
    ret.name = capitalizeName(l.slice(0, idIndex).join(' '));
    ret.percent = l[idIndex + 2];
    return ret;
  };
  lines = [];
  _ref = s.split(/\n/);
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    l = _ref[_i];
    try {
      lines.push(processLine(l));
    } catch (e) {
      console.log(e);
    }
  }
  return lines;
};
