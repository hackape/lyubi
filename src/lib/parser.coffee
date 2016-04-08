fs = require 'fs'
formatter = require './formatter'

getTimestamp = (dateString, mm_ss, offset=0) ->
  d = new Date("#{dateString}, #{mm_ss}:00")
  d = new Date(d.getTime()+86400000*offset) if offset > 0
  return d

msToMin = (ms) -> ms/1000/60

module.exports = (filename) ->
  dateString = undefined
  retEvents = []
  content = fs.readFileSync filename, 'utf-8'
  content = formatter(filename, content)

  lines = content.split '\n'
  dateStringPattern = /^\d{4}\-\d{1,2}\-\d{1,2}/
  if dateStringPattern.test(lines[0])
    dateString = lines[0]
  else
    matched = filename.split('/').pop().match(dateStringPattern)
    dateString = matched[0] if matched

  retEvents.date = dateString
  throw 'Error! DateString not supplied. Cannot proceed.' if not dateString

  lines.reduce((retEvents, line) ->
    matched = line.match(/^(\d\d:\d\d) (.*)$/)
    return retEvents if not matched

    thisEvent = {
      start: getTimestamp(dateString, matched[1])
      tags: []
    }

    matched[2].split(/(?=[><])/).forEach (action) ->
      if action.startsWith '>'
        thisEvent['summary'] = action[1..].trim()
      else
        thisEvent['endLast'] = action[1..].trim()
    lastEvent = retEvents[retEvents.length - 1]
    retEvents.push thisEvent

    if thisEvent.summary and thisEvent.summary.endsWith '+'
      thisEvent.tags.push 'lb-work' if thisEvent.tags.indexOf('lb-work') == -1
      thisEvent.summary = thisEvent.summary.slice(0, -1)

    return retEvents if not lastEvent # first iter

    if thisEvent.endLast and thisEvent.endLast.endsWith '+'
      lastEvent.tags.push 'lb-work' if lastEvent.tags.indexOf('lb-work') == -1
      thisEvent.endLast = thisEvent.endLast.slice(0, -1)

    duration = thisEvent.start - lastEvent.start
    # cross midnight
    if duration < 0
      thisEvent.start = getTimestamp(dateString, matched[1], 1)
      duration = thisEvent.start - lastEvent.start

    lastEvent.duration = msToMin(duration)
    lastEvent.end = thisEvent.start
    if not lastEvent.summary
      lastEvent.summary = thisEvent.endLast if thisEvent.endLast
    else
      lastEvent.summary += " - #{thisEvent.endLast}" if thisEvent.endLast and thisEvent.endLast != lastEvent.summary

    retEvents.splice(retEvents.length - 2, 1) if not lastEvent.summary
    return retEvents
  , retEvents)

  return retEvents
