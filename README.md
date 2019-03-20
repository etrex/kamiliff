# Kamiliff

Kamiliff make LIFF easy to use.

# Feature
- register LIFF once and reuse to your all path.
- liff_submit event: a hook when LIFF form submit, with form data in js object format.
- liff_send_text_message: quick send message and close LIFF.

## Installation

```ruby
gem 'kamiliff'
```

Login to line developers, and create 3 LIFF for 3 different size.

- for compact
  - name: Compact
  - size: Compact
  - Endpoint URL: https://yourwebsite/liff

- for tall
  - name: Tall
  - size: Tall
  - Endpoint URL: https://yourwebsite/liff

- for full
  - name: Full
  - size: Full
  - Endpoint URL: https://yourwebsite/liff

And then copy the result to enviroment parameters:

```
LIFF_COMPACT=line://app/for_compact_liff_id
LIFF_TALL=line://app/for_tall_liff_id
LIFF_FULL=line://app/for_full_liff_id
```

## Usage

### Generate LIFF Link

You can change any path to liff by `liff_path` method.

For example:

```
liff_path(path: '/todos/new')
```

You can choice the liff size by `liff_size` parameter. the default value of liff_size is compact.

```
liff_path(path: '/todos/new', liff_size: :compact)
liff_path(path: '/todos/new', liff_size: :tall)
liff_path(path: '/todos/new', liff_size: :full)
```

liff_path method add format :liff automatically.

### Implement LIFF View

Kamiliff using view format `.liff`, so you can reuse exists controller and model, you can create a LIFF form by only adding a new view file.

Suppose you have a resource `todos`, you want to create a liff form for `todos/new`, so you create a file `app/views/todos/new.liff.erb`, the content is as follows:

```
<% content_for :title, "new todo" %>

<%= render "todos/form.html", todo: @todo %>
```

You can test the form at [localhost:3000/todos/new.liff](localhost:3000/todos/new.liff)

### Receive LIFF Submit Event And Send Message

You need to add those js to handle the `liff_submit` event when user submit a form in LIFF.

``` js
window.addEventListener("liff_submit", function(event){
  var json = JSON.stringify(event.detail.data);
  var url = event.detail.url;
  var method = event.detail.method;
  var request_text = method + " " + url + "\n" + json;
  liff_send_text_message(request_text);
});
```

## Author
create by [etrex](https://etrex.tw)

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
