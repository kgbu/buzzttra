function bindUI() {
  $('addForm').observe('submit', routeToAJAX);
  $('searchForm').observe('submit', routeToAJAX);
} // bindUI


Ajax.Responders.register({
  onCreate: function() {
    $('progress').show();
  },
  onComplete: function(response) {
    if (response._complete) {
      $('buzzlist').hide();
      var list = $('buzzlist');
      var newlist = new Element('dl', {id: 'buzzlist'});
      var r = response.transport.responseText
      var j = r.evalJSON();
try {
      j.data.items.each(function(e) {
        var dt = new Element('dt');
        var dd = new Element('dd');
        var str = "<a href=\"/buzztra/activities/get/" + e.actor.id +
                  "\">" + e.actor.name + "</a>"
        dt.update(str);
        dd.update(e.object.content);
        newlist.insert(dt);
        newlist.insert(dd);
      });
      list.replace(newlist);
      $('buzzlist').show();
      $('progress').hide();
  } catch(er) {
      alert(er.inspect());
  } // end of try clause
    }  
  }
});


function routeToAJAX(event) {
  event.stop();
  var form = event.element();
  new Ajax.Request( form.action, {
    method: form.method,
    parameters: Form.serialize(form)
  });
} // routeToAJAX

document.observe('dom:loaded', bindUI);
