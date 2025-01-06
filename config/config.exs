import Config

config :telegex, 
  # Use Jason by default. Overridable by end-users.
  json_library: Jason

import_config "#{config_env()}.exs"
