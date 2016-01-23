role :build, ['192.168.34.42'], :no_release => true
set :application, 'stretcher_app'
set :deploy_to, '/var/www/stretcher_app'
set :deploy_roles, 'web'
set :stretcher_hooks, 'config/stretcher.yml.erb'
set :local_tarball_name, 'rails-applicaiton.tar.gz'
set :stretcher_src, "s3://tjinjin-backend-stretcher/assets/rails-application-#{env.now}.tgz"
set :manifest_path, "s3://tjinjin-backend-stretcher/manifests"
