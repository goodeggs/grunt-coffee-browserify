browserify = require 'browserify'
coffee = require 'coffee-script'
through = require 'through'
uglify = require 'uglify-js'
fs = require 'fs'
path = require 'path'
{EventEmitter} = require 'events'

defaultCompiler = (src, filepath, debug, done) -> process.nextTick done.bind(null, null, src)
compilers =
  '.js': defaultCompiler
  '.json': defaultCompiler
  '.node': defaultCompiler
  '.coffee': (src, filepath, debug, done) ->
    if debug
      {js, v3SourceMap} = coffee.compile src, bare: true, sourceMap: true, filename: filepath
      code = js

      if v3SourceMap
        map = JSON.parse v3SourceMap
        map.sources = [ filepath ]
        map.sourcesContent = [ src ]

        code += '\n//@ sourceMappingURL=data:application/json;base64,'
        code += new Buffer(JSON.stringify map).toString('base64')
    else
      code = coffee.compile src, bare: true, filename: filepath

    process.nextTick done.bind(null, null, code)

module.exports = class CoffeeBrowserify extends EventEmitter
  run: (config, done) ->
    bundle = browserify extensions: ['.coffee']

    bundle.transform (filename) =>
      @emit 'filename', filename

      src = ''

      write = (buf) -> src += buf

      end = ->
        ext = path.extname filename
        compiler = compilers[ext]
        throw new Error "No compiler for #{filename}" unless compiler?
        code = compiler src, filename, config.debug, (err, code) =>
          @queue code
          @queue null

      return through write, end

    cwd = process.cwd()

    bundle.add path.resolve(cwd, item) for item in config.add or []
    bundle.external item for item in config.external or []

    for item in config.require or []
      if typeof item is 'object'
        for target, expose of item
          bundle.require target, {expose}
      else
        bundle.require item

    code = ''

    s = bundle
      .bundle(transformAll: true, debug: config.debug)
      .pipe(through (data) -> code += data)

    s.once 'end', ->
      fs.writeFile path.resolve(cwd, config.dest), code, 'utf8', done
