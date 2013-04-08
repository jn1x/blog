# Rebuild the post feed in the blog:
#   coffee build.coffee 
# To recompile assets, first install dev dependencies:    npm install --dev
# Then run this script with -a:    coffee build.coffee -a
# This build script got out of hand quickly.

fs     = require 'fs'
_      = require 'underscore'
haml   = require 'hamljs'
md     = require 'markdown'
moment = require 'moment'
rss    = require 'rss'
path   = require 'path'

# some config options for the blog
BLOG_CONFIG =
  base_url: 'http://jnix.co/'
  author: 'jnix'
  title: 'webhax and whatnot'

# patch the markdown filter into haml for later
haml.filters.markdown = (str) -> md.markdown.toHTML(str)

# dev-dependencies, only need them if we are rebuilding assets
BUILD_ASSETS = _.contains(process.argv, '-a')
if BUILD_ASSETS
  glob   = require 'glob'
  less   = require 'less'
  coffee = require 'coffee-script'

# first step: compile coffee/less files in assets/**
compile_assets = ->
  # asset compilers available (coffee & less)
  compilers =
    _concat_compile_and_write: (build_info, compile_fn, callback_fn=false) ->
      # concatenates input files in build.json into one long string
      dir = build_info.dirname + '/'
      js = _.map(build_info.input, (in_file) -> fs.readFileSync(dir+in_file, 'utf8'))
            .join("\n")
      if !callback_fn
        fs.writeFile dir+build_info.output, compile_fn(js) # compile & write to disk
      else  
        compile_fn js, (err, str) ->
          if err then [console.log(err), throw err]
          fs.writeFile dir+build_info.output, callback_fn(err, str)
    coffee: (build_info) -> @_concat_compile_and_write(build_info, coffee.compile)
    less:   (build_info) ->
      parser = new less.Parser
      @_concat_compile_and_write build_info, 
        -> parser.parse.apply(parser, arguments),
        (err, t) ->
          t.toCSS(compress: true)
    haml:   (build_info) -> 
      @_concat_compile_and_write(build_info, (str) -> haml.compile(str)())

  # recursively look up build.json files
  build_files = glob 'assets/**/build.json', (err, files) ->
    if err then return console.log 'No build files found. Aborting compilation.'
    _.each files, (file) ->
      json = JSON.parse(fs.readFileSync(file, 'utf8'))
      _.each json, (build_info) ->
        build_info.dirname = path.dirname(file)
        compilers[build_info.compiler](build_info)
    console.log("#{files.length} build.json files processed.")

# second step: parse the posts into an rss feed,
# for consumption/rendering by the client-side JS
compile_posts = ->
  # look through posts/**.haml and build rss.xml, for client-side consumption
  rss_data = {}
  post_files = fs.readdirSync('./posts').sort().reverse()
  format_err = (f) -> console.log("Unknown file #{f} in posts/."); false
  post_data = _.map post_files, (post_file) ->
    # parse the date out of the filename (YYYY-mm-dd-title)
    matches = post_file.match(/^((.*?)-(.*?)-(.*?))-(.*)$/)
    if !matches then return format_err(post_file)
    # compile the haml post
    console.log "Processing '#{post_file}'"
    post_src = fs.readFileSync("./posts/"+post_file).toString()
    post_contents = haml.compile(post_src)() || ''
    # substring and kill dangling markup and markup outside %article
    post_blurb = post_contents.substring(post_contents.indexOf('<article'), 300)
                              .replace(/<[^>]*$/igm, '') || ''
    title_matches = post_src.match(/[<]h\d[>](.*?)[<]h\d[>]/igm) 
    title_matches ||= ['', path.basename(matches[5], '.haml')]
    post_title = title_matches[1] || ''
    # return some metadata about the post
    return {
      title:       post_title,
      date:        moment(matches[1]).format(),
      description: post_blurb,
      url:         BLOG_CONFIG.base_url+post_title
    }
  # output post_data to an XML feed in ./rss.xml
  feed = new rss({
    title: BLOG_CONFIG.author+' | '+BLOG_CONFIG.title,
    description: BLOG_CONFIG.description,
    feed_url: BLOG_CONFIG.base_url+'rss.xml',
    site_url: BLOG_CONFIG.base_url,
    author: BLOG_CONFIG.author,
  })
  _.each post_data, (item) -> feed.item(item)
  fs.writeFile 'rss.xml', feed.xml()
  console.log "#{post_data.length} posts saved to rss.xml."

main = ->
  compile_assets() if BUILD_ASSETS
  compile_posts()
  console.log 'Blog generation completed.'

# kick it all off
main()