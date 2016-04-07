toISOString = (date) ->
  ISOString = Date.prototype.toISOString.call date
  return ISOString.replace(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.\d{3}Z$/, '$1$2$3T$4$5$6Z')

min2hour = (duration) ->
  return duration+'\'' if duration < 60
  hour = Math.floor(duration / 60)
  minute = duration % 60
  if minute > 0 then "#{hour}h#{minute}\'" else "#{hour}h"

genEventString = (event) ->
  return '' if not event.summary
  dtstart = toISOString event.start
  dtend = if event.end then toISOString event.end else toISOString event.start
  uid = "#{dtstart}-hackape@lyubishchev-log"
  eventTemplate = """
BEGIN:VEVENT
SUMMARY:#{event.summary} (#{min2hour(event.duration)})
DTSTART:#{dtstart}
DTEND:#{dtend}
UID:#{uid}
TRANSP:TRANSPARENT
END:VEVENT
"""
# add this if want tags:
# DESCRIPTION:#{event.tags.join(', ')}

  return eventTemplate

module.exports = (listOfLogs, mode='flat') ->
  if mode == 'flat'
    listOfEvents = listOfLogs.reduce((listOfEvents, dailyLog)->
      listOfEvents.concat dailyLog
    , [])
    events = listOfEvents.reduce((eventsString, event) ->
      eventsString += genEventString(event)+'\n'
    ,'')
    events = events.trim()
    return calendarTemplate = """
BEGIN:VCALENDAR
METHOD:PUBLISH
VERSION:2.0
X-WR-CALNAME:LyubiCal
X-APPLE-CALENDAR-COLOR:#63DA38
CALSCALE:GREGORIAN
#{events}
END:VCALENDAR
"""

  if mode == 'daily'
    return listOfCals = listOfLogs.reduce((listOfCals, dailyLog)->
      eventsString = dailyLog.reduce((eventsString, event) ->
        eventsString += genEventString(event)+'\n'
      ,'')
      events = eventsString.trim()
      calendarTemplate = """
BEGIN:VCALENDAR
METHOD:PUBLISH
VERSION:2.0
X-WR-CALNAME:LyubiCal
X-APPLE-CALENDAR-COLOR:#63DA38
CALSCALE:GREGORIAN
#{events}
END:VCALENDAR
"""
      listOfCals.push calendarTemplate
    [])

  if mode == 'split'
    listOfEvents = listOfLogs.reduce((listOfEvents, dailyLog)->
      listOfEvents.concat dailyLog
    , [])

    workEvents = ''
    lifeEvents = ''
    listOfEvents.forEach (event)->
      if event.tags.indexOf('lb-work') > -1 #work
        workEvents += genEventString(event)+'\n'
      else #life
        lifeEvents += genEventString(event)+'\n'

    workEvents = workEvents.trim()
    lifeEvents = lifeEvents.trim()

    workCal = """
BEGIN:VCALENDAR
METHOD:PUBLISH
VERSION:2.0
X-WR-CALNAME:LyubiWork
X-APPLE-CALENDAR-COLOR:#1BADF8
CALSCALE:GREGORIAN
#{workEvents}
END:VCALENDAR
"""
    lifeCal = """
BEGIN:VCALENDAR
METHOD:PUBLISH
VERSION:2.0
X-WR-CALNAME:LyubiLife
X-APPLE-CALENDAR-COLOR:#63DA38
CALSCALE:GREGORIAN
#{lifeEvents}
END:VCALENDAR
"""
    return [workCal, lifeCal]





