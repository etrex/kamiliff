Rails.application.routes.draw do
  # liff
  get 'liff_entry', to: 'liff#entry'
  post 'liff_route', to: 'liff#route'
end
