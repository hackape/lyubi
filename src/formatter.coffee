fs = require 'fs'
module.exports = (filename, content) ->
  content = content.replace(/^(\d{2})(\d{2})(?=\ [<>》《])/gm, '$1:$2')
  content = content.replace /(》)|(《)/g, ($s, $1, $2)->
    return '>' if $1
    return '<' if $2

  fs.writeFileSync filename, content
  return content
