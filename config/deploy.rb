role :build, ['192.168.34.40'], :no_release => true
set :application, 'your-application'
set :deploy_to, '/var/www'
set :deploy_roles, 'www'
set :stretcher_hooks, 'config/stretcher.yml.erb'
set :local_tarball_name, 'rails-applicaiton.tar.gz'
set :stretcher_src, "s3://#{ENV['S3_BUCKET']}/assets/rails-application-#{env.now}.tgz"
set :manifest_path, "s3://#{ENV['S3_BUCKET']}/manifests/"
