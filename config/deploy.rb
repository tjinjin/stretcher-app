role :build, ['192.168.34.42'], :no_release => true
set :application, 'my_app_name'
set :deploy_to, '/var/www'
set :deploy_roles, 'web'
set :stretcher_hooks, 'config/stretcher.yml.erb'
set :local_tarball_name, 'rails-applicaiton.tar.gz'
set :stretcher_src, "s3://tjinjin-try-stretcher/assets/rails-application-#{env.now}.tgz"
set :manifest_path, "s3://tjinjin-try-stretcher/manifests"
