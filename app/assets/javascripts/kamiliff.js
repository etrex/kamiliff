function liff_send_text_message(text){
  liff.sendMessages(
    [
      {
        type: 'text',
        text: text
      }
    ]
  ).then(function(){
    liff.closeWindow();
  })
  .catch(function(error){
    alert('error: ' + JSON.stringify(error));
  });
}

function register_kamiliff_submit(){
  function dispatch_liff_event(data){
    var event = new CustomEvent('liff_submit', { 'detail': data });
    window.dispatchEvent(event);
  }
  $('input[type="submit"]').click(function(e){
    e.preventDefault();
    dispatch_liff_event(get_request_text($("form")));
  })

  function get_request_text(form_element){
    var data = get_form_data(form_element);
    var method = form_element.attr("method").toUpperCase();
    var url = form_element.attr("action");
    return {
      data: data,
      method: method,
      url: url
    }
  }

  function get_form_data(form_element){
    var excpet = ["utf8","authenticity_token"];
    var form = form_element.serializeArray();
    form = form.filter(function(a){ return !excpet.includes(a.name) })
    var data = {}
    form.forEach(function(a){ set_object_value(data, a.name, a.value) })
    return data;
  }

  function set_object_value(object, path, value){
    var o = object;
    var p = path.replace(/(\]\[)/g, "[").replace(/]$/g, "").split("[")
    var last_key = p.pop();
    p.forEach(function(key){
      o[key] = o[key] || {}
      o = o[key]
    })
    o[last_key] = value;
  }
}