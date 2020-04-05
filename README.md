# Kamiliff
Kamiliff make LIFF easy to use.

# Feature
- register LIFF once and reuse to your all path.
- liff_submit event: a hook when LIFF form submit, with form data in js object format.
- liff_send_text_message: quick send message and close LIFF.

## Installation & Usage
### Create a new rails repository:

```bash
# create rails repository
rails new kamiliff_demo
# install gem
bundle add kamiliff
bundle add dotenv-rails
```

### Add LIFF Endpoint URL
Login to LINE Developers, and create 3 LIFF for 3 different size.

- For compact
  - LIFF app name: Compact
  - Size: Compact
  - Endpoint URL: https://yourwebsite/liff_entry

- For tall
  - LIFF app name: Tall
  - Size: Tall
  - Endpoint URL: https://yourwebsite/liff_entry

- For full
  - LIFF app name: Full
  - Size: Full
  - Endpoint URL: https://yourwebsite/liff_entry

Since the compact size is default. You could only create the compact one.

**NOTICE:** As LINE announcement, due to a function enhancement with LIFF v2, you should add LIFF apps to LINE Login channel. The LIFF apps added to Messaging API channels are still allowed to use.

### Set environment variables
Create a file `.env` with the following content under root directory:

- LIFF apps added to Messaging API channel (v1)
```
LIFF_COMPACT=line://app/{FOR_COMPACT_LIFF_ID}
LIFF_TALL=line://app/{FOR_TALL_LIFF_ID}
LIFF_FULL=line://app/{FOR_FULL_LIFF_ID}
```

- LIFF apps added to LINE Login channel (v2)
```
LIFF_COMPACT=https://liff.line.me/{FOR_COMPACT_LIFF_ID}
LIFF_TALL=https://liff.line.me/{FOR_TALL_LIFF_ID}
LIFF_FULL=https://liff.line.me/{FOR_FULL_LIFF_ID}
```

You could choose another setting method.

### Generate simple todo resource
Create todo resource:

```bash
rails g scaffold todo name desc
rails db:migrate
```

### Create LIFF view
Create liff view for new action at `app/views/todos/new.liff.erb`.

```
<%= render "todos/form.html", todo: @todo %>

<script>
document.title = "new todo";

window.addEventListener("liff_submit", function(event){
  var json = JSON.stringify(event.detail.data);
  var url = event.detail.url;
  var method = event.detail.method;
  var request_text = method + " " + url + "\n" + json;
  liff_send_text_message(request_text);
});
</script>
```

The javascript listen to submit button click, and build the message from form data, and send to current LINE chatroom, and then close the LIFF webview.

You could modify those javascript to change the format.

### Test LIFF view
Add following content into `app/views/todos/index.html.erb`.

```
<%= liff_path(path: new_todo_path) %>
```

Copy this url and paste to any LINE chatroom.

Click this url in LINE app.

The correct usage is put this url into Rich Manu or Flex Message or Template Message with url action.

### How to change LIFF size
You can change the size of LIFF by adding a parameter to the helper method, like this:

```
<%= liff_path(path: new_todo_path, liff_size: :compact) %>
<%= liff_path(path: new_todo_path, liff_size: :tall) %>
<%= liff_path(path: new_todo_path, liff_size: :full) %>
```

## Apps use Kamiliff
See my kamiliff demo: [https://github.com/etrex/kamiliff_demo](https://github.com/etrex/kamiliff_demo)

## Author
Create by [etrex](https://etrex.tw)

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
