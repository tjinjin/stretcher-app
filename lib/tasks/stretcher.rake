# -*- coding: utf-8; mode: ruby -*-
require 'erb'
require 'yaml'
require 'open3'

namespace :stretcher do
  config = YAML.load_file(File.expand_path('../../tasks/stretcher.yml', __FILE__))

  def local_working_path_base
    config['local_working_path_base']
  end

  def local_repo_path
    "#{local_working_path_base}/repo"
  end

  def local_checkout_path
    "#{local_working_path_base}/checkout"
  end

  def local_build_path
    "#{local_working_path_base}/build"
  end

  def local_tarball_path
    "#{local_working_path_base}/tarballs"
  end

  def repo_url
    config['repo_url']
  end

  def time_now
    @time_now ||= Time.now.strftime("%Y%m%d%H%M%S")
  end

  def branch
    ENV['CIRCLE_BRANCH'] ||= 'master'
  end

  def current_version
    %x(git rev-parse #{branch}).chomp
  end

  def exclude_dirs
    '--exclude tmp'
  end

  def rails_env
    config['rails_env'] ||= ENV['RAILS_ENV']
  end

  def local_tarball_name
    config['local_tarball_name']
  end

  def stretcher_path
    config['stretcher_path']
  end

  def stretcher_src
    "#{stretcher_path}/rails-application-#{time_now}.tgz"
  end

  def checksum
    %x(openssl sha256 #{local_tarball_path}/current/#{local_tarball_name} | awk -F' ' '{print $2}').chomp
  end

  def deploy_to
    config['deploy_to']
  end

  def deploy_roles
    config['deploy_roles']
  end

  def tempfile_path
    "#{local_working_path_base}/tmp"
  end

  def manifest_path
    config['manifest_path']
  end

  def stretcher_hook
    cofnig['stretcher_hook']
  end

  def consul_host
    config['consul_host']
  end

  desc "Create tarball"
  task :archive_project =>
  [:ensure_directories, :checkout_local,
   :bundle, :assets_precompile,
   :create_tarball, :upload_tarball,
   :create_and_upload_manifest
  ]

  desc "ensure directories"
  task :ensure_directories do
    %x(
      mkdir -p \
          #{local_repo_path} \
          #{local_checkout_path} \
          #{local_build_path} \
          #{local_tarball_path} \
          #{tempfile_path}
    )
  end

  desc "checkout repository"
  task :checkout_local do
    if File.exist?("#{local_repo_path}/HEAD")
      %x(git remote update)
    else
      %x(git clone --mirror #{repo_url} #{local_repo_path})
    end
    %x(
      mkdir -p #{local_checkout_path}/#{time_now}
      git archive #{branch} | tar -x -C #{local_checkout_path}/#{time_now}
      echo #{current_version} > #{local_checkout_path}/#{time_now}/REVISION
    )

    %x(
      rsync -av --delete #{exclude_dirs} \
          #{local_checkout_path}/#{time_now}/ #{local_build_path}/
    )
  end

  desc "bundle install"
  task :bundle do
    Bundler.with_clean_env do
      sh <<-EOC
        bundle install \
        --gemfile #{local_build_path}/Gemfile \
        --deployment --path vendor/bundle -j 4 \
        --without development test RAILS_ENV="#{rails_env}"
      EOC
    end
  end

  desc "assets precompile"
  task :assets_precompile do
    sh <<-EOC
      cd #{local_build_path}
      bundle exec rake assets:precompile RAILS_ENV="#{rails_env}"
    EOC
  end

  desc "create tarball"
  task :create_tarball do
    sh <<-EOC
      cd #{local_build_path}
      mkdir -p "#{local_tarball_path}/#{time_now}"
      tar -cf - --exclude tmp --exclude spec ./ | gzip -9 > \
        #{local_tarball_path}/#{time_now}/#{local_tarball_name}
    EOC
    sh <<-EOC
      cd #{local_tarball_path}
      rm -f current
      ln -sf #{time_now} current
    EOC
  end

  desc "upload tarball to s3"
  task :upload_tarball do
    sh <<-EOC
      aws s3 cp #{local_tarball_path}/current/#{local_tarball_name} #{stretcher_src}
    EOC
  end

  desc "create and upload manifest"
  task :create_and_upload_manifest do
    template = File.read(File.expand_path('../../templates/manifest.yml.erb', __FILE__))
    yaml = YAML.load(ERB.new(%x(cat #{local_build_path}/config/#{stretcher_hook})).result(binding))
    deploy_roles.each do |role|
      hooks = yaml[role]
      yml = ERB.new(template).result(binding)
      tempfile_path = Tempfile.open("manifest_#{role}_#{time_now}") do |t|
        t.write yml
        t.path
      end
      p tempfile_path
      sh <<-EOC
       mv  #{tempfile_path} "#{local_tarball_path}/current/manifest_#{role}_#{rails_env}_#{time_now}.yml"
      EOC
      sh <<-EOC
        aws s3 cp "#{local_tarball_path}/current/manifest_#{role}_#{rails_env}_#{time_now}.yml" "#{manifest_path}/manifest_#{role}_#{rails_env}_#{time_now}.yml"
      EOC
    end
  end

  desc "kick start consul event"
  task :kick_start do
    deploy_roles.each do |role|
      o, e, s = Open3.capture3("aws s3 ls #{manifest_path}/manifest_#{role}_#{rails_env} | awk -F' ' '{print $4}' | tail -1")
      current_manifest = o.chomp
      puts "kick start -> #{current_manifest}"
      sh <<-EOC
        curl -X PUT -d "#{manifest_path}/#{current_manifest}" http://#{consul_host}:8500/v1/event/fire/deploy_#{role}_#{rails_env}\?pretty
      EOC
    end
  end

  desc "rollback consul event"
  task :rollback do
    deploy_roles.each do |role|
      o, e, s = Open3.capture3("aws s3 ls #{manifest_path}/manifest_#{role}_#{rails_env} | awk -F' ' '{print $4}' | tail -2 | head -1")
      current_manifest = o.chomp
      puts "kick start -> #{current_manifest}"
      sh <<-EOC
        curl -X PUT -d "#{manifest_path}/#{current_manifest}" http://#{consul_host}:8500/v1/event/fire/deploy_#{role}_#{rails_env}\?pretty
      EOC
    end
  end
end
