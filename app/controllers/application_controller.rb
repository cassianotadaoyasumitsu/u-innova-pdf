class ApplicationController < ActionController::Base
  # Allow browsers that support basic web features while still maintaining security
  allow_browser versions: { chrome: ">= 60", firefox: ">= 60", safari: ">= 12", edge: ">= 79" }
end
