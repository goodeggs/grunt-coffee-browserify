module.exports = (grunt) ->
  grunt.registerMultiTask 'browserify', 'Assembles JS files with browserify', ->
    CoffeeBrowserify = require './coffee_browserify'

    config = @data
    done = @async()
    start = new Date()

    coffeeBrowserify = new CoffeeBrowserify()

    coffeeBrowserify.on 'filename', (filename) ->
      grunt.log.writeln "Included #{filename.cyan}"

    coffeeBrowserify.run config, =>
      grunt.log.writeln "File #{config.dest.cyan} created in #{(new Date() - start) / 1000} seconds."
      done()
