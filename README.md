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
# change directory
cd kamiliff_demo
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

For the [Behaviors from accessing the LIFF URL to opening the LIFF app](https://developers.line.biz/en/docs/liff/opening-liff-app/#redirect-flow) setting, please use the Concatenate mode. That's the default value in the Kamiliff. If you want to use the Replace mode([will be removed on March 1, 2021](https://developers.line.biz/en/news/2020/11/20/discontinue-replace-mode-announcement/)), you can add an enviroment variable `LIFF_MODE` and set the value to `replace`.

### Set environment variables
Create a file `.env` with the following content under the root directory. Kamiliff provides two setting ways, you can choose the one based on the position where LIFF apps added.

```
LINE_LOGIN_CHANNEL_ID={LINE_LOGIN_CHANNEL_ID}
LINE_LOGIN_CHANNEL_SECRET={LINE_LOGIN_CHANNEL_SECRET}
LIFF_COMPACT=https://liff.line.me/{FOR_COMPACT_LIFF_ID}
LIFF_TALL=https://liff.line.me/{FOR_TALL_LIFF_ID}
LIFF_FULL=https://liff.line.me/{FOR_FULL_LIFF_ID}
```

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

## How to test this gem

```
rails t
```
