require File.dirname(__FILE__) + '/lib/aws/session_store/dynamo_db/version'

Gem::Specification.new do |spec|
  spec.name          = "aws-sessionstore-dynamodb"
  spec.version       = Aws::SessionStore::DynamoDB::VERSION
  spec.authors       = ["Ruby Robinson"]
  spec.summary       = "The Amazon DynamoDB Session Store handles sessions " +
                       "for Ruby web applications using a DynamoDB backend."
  spec.homepage      = "http://github.com/aws/aws-sessionstore-dynamodb-ruby"
  spec.license       = "Apache License 2.0"

  # file list is generated with `git ls-files | grep -v -E -e '^spec/' -e '^\.' -e '^tasks/'`
  spec.files         = %w(
    Gemfile
    LICENSE.txt
    README.md
    Rakefile
    aws-sessionstore-dynamodb.gemspec
    lib/aws-sessionstore-dynamodb.rb
    lib/aws/session_store/dynamo_db/configuration.rb
    lib/aws/session_store/dynamo_db/errors/base_handler.rb
    lib/aws/session_store/dynamo_db/errors/default_handler.rb
    lib/aws/session_store/dynamo_db/garbage_collection.rb
    lib/aws/session_store/dynamo_db/invalid_id_error.rb
    lib/aws/session_store/dynamo_db/lock_wait_timeout_error.rb
    lib/aws/session_store/dynamo_db/locking/base.rb
    lib/aws/session_store/dynamo_db/locking/null.rb
    lib/aws/session_store/dynamo_db/locking/pessimistic.rb
    lib/aws/session_store/dynamo_db/missing_secret_key_error.rb
    lib/aws/session_store/dynamo_db/rack_middleware.rb
    lib/aws/session_store/dynamo_db/railtie.rb
    lib/aws/session_store/dynamo_db/table.rb
    lib/aws/session_store/dynamo_db/tasks/session_table.rake
    lib/aws/session_store/dynamo_db/version.rb
    lib/rails/generators/sessionstore/dynamodb/USAGE
    lib/rails/generators/sessionstore/dynamodb/dynamodb_generator.rb
    lib/rails/generators/sessionstore/dynamodb/templates/session_store_dynamodb.yml
    lib/rails/generators/sessionstore/dynamodb/templates/sessionstore_migration.rb
  ) 

  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'aws-sdk', '~> 2.0'
  spec.add_dependency 'rack', '~> 1.0'
end
