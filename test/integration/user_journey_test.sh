#! /usr/bin/env bash
# reproduce the documented user journey for installing and running tailwindcss-rails
# this is run in the CI pipeline, non-zero exit code indicates a failure

set -o pipefail
set -eux

# set up dependencies
rm -f Gemfile.lock
bundle remove actionmailer
bundle add rails --skip-install ${RAILSOPTS:-}
bundle install

# fetch the upstream executables
bundle exec rake download

# do our work a directory with spaces in the name (#176, #184)
rm -rf "My Workspace"
mkdir "My Workspace"
pushd "My Workspace"

# create a rails app
bundle exec rails -v
bundle exec rails new test-app --skip-bundle
pushd test-app

# make sure to use the same version of rails (e.g., install from git source if necessary)
bundle remove rails
bundle add rails --skip-install ${RAILSOPTS:-}

# use the tailwindcss-rails under test
bundle add tailwindcss-rails --path="../.."
bundle install
bundle show --paths

# install tailwindcss
bin/rails tailwindcss:install

# TEST: tailwind was installed correctly
grep tailwind app/views/layouts/application.html.erb

# TEST: rake tasks don't exec (#188)
cat <<EOF >> Rakefile
task :still_here do
  puts "Rake process did not exit early"
end
EOF

bin/rails tailwindcss:build still_here | grep "Rake process did not exit early"
