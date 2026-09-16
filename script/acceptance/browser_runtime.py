"""Loopback-only interactive SDK substitute; never sends real LINE messages."""
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import json
ROOT = Path(__file__).resolve().parents[2]
PAGE = '''<!doctype html><meta charset="utf-8"><title>Kamiliff 合成 SDK 驗收</title>
<h1>Kamiliff 合成 SDK 驗收</h1><p>本機模擬平台，不會發送 LINE 訊息。</p>
<button id="login">外部瀏覽器登入返回網址</button><button id="auth">驗證身分（同時兩次）</button><button id="cancel">取消分享</button><button id="unsupported">不支援分享</button><button id="share">分享成功並關閉</button><button id="fail">發送失敗</button><button id="send">發送成功並關閉</button><button id="conflict">帳號衝突</button><button id="invalid">憑證失效</button>
<pre id="result">等待操作</pre><script>
let mode='success', initializations=0, closes=0, requests=0, fallbacks=0;
window.liff={init:async()=>{initializations++},isLoggedIn:()=>mode!=='login',getIDToken:()=>mode,
login:options=>{document.querySelector('#result').textContent=JSON.stringify(options)},isInClient:()=>true,isApiAvailable:()=>mode!=='unsupported',
shareTargetPicker:async()=>mode==='cancel'?undefined:{status:'success'},
sendMessages:async()=>{if(mode==='fail')throw new Error('delivery_failed')},closeWindow:()=>{closes++}};
</script><script src="/kamiliff/sdk.js"></script><script>
const client=Kamiliff.createSession({liffId:'synthetic-app',endpointPath:'/entry',entryUrl:'/entry?page=ranking&group=3',sessionUrl:'/session',csrfToken:()=> 'synthetic-csrf',onVerified:()=>{requests++},fallback:async()=>{fallbacks++;return{status:'fallback'}}});
async function run(next,action){mode=next;try {let result=await action();document.querySelector('#result').textContent=JSON.stringify({result,initializations,closes,requests,fallbacks})}catch(error){document.querySelector('#result').textContent=JSON.stringify({error:error.code||error.message,initializations,closes,requests,fallbacks})}}
document.querySelector('#login').onclick=()=>run('login',()=>client.authenticate());
document.querySelector('#auth').onclick=()=>run('success',()=>Promise.all([client.authenticate(),client.authenticate()]));
for(const name of ['cancel','unsupported','share'])document.getElementById(name).onclick=()=>run(name,()=>client.shareMessages([{type:'text',text:'synthetic'}],{close:true}));
for(const name of ['fail','send'])document.getElementById(name).onclick=()=>run(name,()=>client.sendMessages([{type:'text',text:'synthetic'}],{close:true}));
for(const name of ['conflict','invalid'])document.getElementById(name).onclick=()=>run(name,()=>client.authenticate());
</script>'''
class Handler(BaseHTTPRequestHandler):
 def log_message(self,*args):pass
 def do_GET(self):
  if self.path=='/kamiliff/sdk.js':body=(ROOT/'app/assets/javascripts/kamiliff.js').read_bytes();kind='text/javascript'
  else:body=PAGE.encode();kind='text/html; charset=utf-8'
  self.send_response(200);self.send_header('Content-Type',kind);self.end_headers();self.wfile.write(body)
 def do_POST(self):
  token=json.loads(self.rfile.read(int(self.headers['Content-Length'])))['id_token']
  error={'conflict':'explicit_link_required','invalid':'invalid_line_identity'}.get(token)
  self.send_response(401 if error else 200);self.send_header('Content-Type','application/json');self.end_headers();self.wfile.write(json.dumps({'error':error} if error else {'status':'verified'}).encode())
if __name__=='__main__':
 server=HTTPServer(('127.0.0.1',0),Handler);print('http://127.0.0.1:%s/entry'%server.server_port,flush=True);server.serve_forever()
