ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

set :url, 'http://localhost/'
set :repo_url, 'https://github.com/tjinjin/stretcher-app'
set :ssh_options, {
   user: 'vagrant',
   keys: %w(~/.vagrant.d/insecure_private_key),
   forward_agent: false,
   auth_methods: %w(publickey)
}

role %w(master web db), "192.168.34.42"
role %w(master web db), "192.168.34.43"
role %w(master web db), "192.168.34.44"
