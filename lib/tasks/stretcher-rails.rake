# -*- coding: utf-8; mode: ruby -*-

namespace :stretcher do

  desc "Create tarball"
  task :archive_project =>
  [:ensure_directories, :checkout_local,
   :bundle, :assets_precompile,
   :create_tarball, :upload_tarball,
   :create_and_upload_manifest
  ]

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
end
