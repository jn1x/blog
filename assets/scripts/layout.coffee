# some bootstrap code to get everything loaded & running

init = ->
  # kick off loading the rss.xml file
  xhr = $.ajax
    type: 'GET'
    url: 'rss.xml'
    dataType: 'xml'
    success: (xml) -> load_app(xml)
    failure: -> # try again in 3 seconds
      setTimeout init, 3000

load_app = (rss_xml) ->
  # now we have the RSS feed. let's convert it to JSON,
  #   store it for offline use, and then display it.
  rss_json = $.xml2json(rss_xml)
  Loader.hide()
  # now let's launch our backbone marionette app :)
  
# patch Backbone to use Handlebars.js to compile our templates
Backbone.Marionette.TemplateCache.prototype.compileTemplate = (rawTemplate) ->
  Handlebars.compile(rawTemplate)

# app-wide show/hide Loader API
window.Loader = {
  dom: -> @$el ||= $('#modals #loader')
  show: ->
    $el = @dom().show().removeClass('hidden')
    $el.spin(
      lines: 7, length: 2, width: 6, radius: 6, corners: 1, rotate: 0,
      trail: 45, speed: 0.9, shadow: false, hwaccel: true, color: '#333'
    )
    $('#search').addClass('hidden')
  hide: ->
    $el = @dom().addClass('hidden')
    $el.spin(false)
    $('#search').removeClass('hidden')
    setTimeout (-> $el.hide()), 250
}

$(document).ready ->
  init()
  Loader.show()
