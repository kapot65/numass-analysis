using Pluto
using Pkg

Pkg.instantiate()
Pkg.precompile()

session = Pluto.ServerSession()

session.options.server.auto_reload_from_file = true
session.options.server.host = "127.0.0.1"
session.options.server.launch_browser = true

session.options.security.require_secret_for_access = false
session.options.security.require_secret_for_open_links = false

Pluto.run(session)