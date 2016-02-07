# -*- coding: utf-8; mode: ruby -*-
require 'erb'
require 'yaml'

namespace :stretcher do

  def local_working_path_base
    '/var/tmp/application'
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
    "https://github.com/tjinjin/stretcher-app"
  end

  def time_now
    time_now = Time.now.strftime("%Y%m%d%H%M%S")
  end

  def branch
    'master'
  end

  def current_version
    %x(git rev-parse #{branch}).chomp
  end

  def exclude_dirs
    '--exclude tmp'
  end

  def rails_env
    ENV['RAILS_ENV'] ||= 'development'
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
          #{local_tarball_path}
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
    puts 'precompile'
  end

  desc "create tarball"
  task :create_tarball do
    puts 'tarball'
  end

  desc "upload tarball to s3"
  task :upload_tarball do
    puts 'upload'
  end

  desc "create and upload manifest"
  task :create_and_upload_manifest do
    'manifest'
  end
end
