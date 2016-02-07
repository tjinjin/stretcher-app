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
    puts 'checkout'
  end

  desc "bundle install"
  task :bundle do
    puts 'bundle'
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
