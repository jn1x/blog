(function() {
  var init, load_app;

  init = function() {
    var xhr;

    return xhr = $.ajax({
      type: 'GET',
      url: 'rss.xml',
      dataType: 'xml',
      success: function(xml) {
        return load_app(xml);
      },
      failure: function() {
        return setTimeout(init, 3000);
      }
    });
  };

  load_app = function(rss_xml) {
    var rss_json;

    rss_json = $.xml2json(rss_xml);
    return Loader.hide();
  };

  Backbone.Marionette.TemplateCache.prototype.compileTemplate = function(rawTemplate) {
    return Handlebars.compile(rawTemplate);
  };

  window.Loader = {
    dom: function() {
      return this.$el || (this.$el = $('#modals #loader'));
    },
    show: function() {
      var $el;

      $el = this.dom().show().removeClass('hidden');
      $el.spin({
        lines: 7,
        length: 2,
        width: 6,
        radius: 6,
        corners: 1,
        rotate: 0,
        trail: 45,
        speed: 0.9,
        shadow: false,
        hwaccel: true,
        color: '#333'
      });
      return $('#search').addClass('hidden');
    },
    hide: function() {
      var $el;

      $el = this.dom().addClass('hidden');
      $el.spin(false);
      $('#search').removeClass('hidden');
      return setTimeout((function() {
        return $el.hide();
      }), 250);
    }
  };

  $(document).ready(function() {
    init();
    return Loader.show();
  });

}).call(this);
