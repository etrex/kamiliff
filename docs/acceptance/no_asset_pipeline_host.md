# 無資產管線 Rails 宿主驗收

## KAMILIFF-HOST-001（2026-09-10 14:01 CST）

Agent 在 Kamiliff 套件目錄直接執行：

```sh
PATH=/Users/etrexkuo/.asdf/installs/ruby/4.0.6/bin:$PATH ruby script/acceptance/no_asset_pipeline_host.rb
```

腳本建立一次性的 Rails 8.1 宿主，明確使用 `--skip-asset-pipeline` 與 `--skip-javascript`，並透過 Kamiliff 自己的 bundle 啟動該宿主。這不是既有 dummy app，也沒有預先載入 Sprockets 或 Propshaft。宿主成功載入 `Kamiliff::Engine`，且公開觀察結果為：

```json
{"engine":"kamiliff_engine","assets_configured":false,"booted":true}
```

這證明沒有 `config.assets` 的 Rails 宿主可以載入 Kamiliff；若 initializer 再次無條件呼叫 `assets.precompile`，相同 boot 流程會在輸出結果前失敗。回歸測試 `test/v1/no_asset_pipeline_host_test.rb` 直接執行同一個腳本，使用相同 Rails 參數、套件、輸入與可觀察結果。
