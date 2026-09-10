if Rails.application.config.respond_to?(:assets) && Rails.application.config.assets.respond_to?(:precompile)
  Rails.application.config.assets.precompile << "kamiliff.js"
end
