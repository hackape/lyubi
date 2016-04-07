`#!/usr/bin/env node
`
fs = require 'fs'
parser = require './parser'
ics = require './ics'
program = require 'commander'

toISOString = (date) ->
  ISOString = Date.prototype.toISOString.call date
  return ISOString.replace(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.\d{3}Z$/, '$1$2$3T$4$5$6')

main = (input, output, mode)->  
  files = fs.readdirSync input
  listOfDailyLogs = []
  files.forEach (filename) ->
    return if filename.startsWith('.') or filename.endsWith('.ics')
    return if fs.statSync("#{input}/#{filename}").isDirectory()
    parsedData = parser("#{input}/#{filename}")
    listOfDailyLogs.push parsedData if parsedData

  if mode == 'split'
    [workCal, lifeCal] = ics(listOfDailyLogs, mode)
    fs.writeFileSync "#{output}/LyubiWork_#{toISOString(new Date())}.ics", workCal
    fs.writeFileSync "#{output}/LyubiLife_#{toISOString(new Date())}.ics", lifeCal
  else if mode = 'flat'
    cal = ics(listOfDailyLogs, mode)
    fs.writeFileSync "#{output}/LyubiCal_#{toISOString(new Date())}.ics", cal


program
  .option '-i, --in <dir_in>', 'Specify input directory'
  .option '-o, --out <dir_out>', 'Specify output directory'
  .option '-f, --flat', 'Toggle flat mode'
  .parse(process.argv)

input = program.in or process.cwd()
output = program.out or process.cwd()
mode = if program.flat then 'flat' else 'split'

main(input, output, mode)