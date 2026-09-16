Rails.application.routes.draw do
  get 'kamiliff/sdk.js', to: 'liff#sdk', defaults: { format: :js }
  get 'liff_entry', to: 'liff#entry'
  post 'liff_route', to: 'liff#route'
end
