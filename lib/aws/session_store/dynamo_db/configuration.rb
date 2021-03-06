# Copyright 2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

require 'yaml'
require 'aws-sdk'

module Aws::SessionStore::DynamoDB
  # This class provides a Configuration object for all DynamoDB transactions
  # by pulling configuration options from Runtime, a YAML file, the ENV and
  # default settings.
  #
  # == Environment Variables
  # The Configuration object can load default values from your environment. An example
  # of setting and environment variable is below:
  #
  #   export DYNAMO_DB_SESSION_TABLE_NAME='Sessions'
  #
  # == Handling Errors
  # There are two configurable options for error handling: :raise_errors and :error_handler.
  #
  # If you would like to use the Default Error Handler, you can decide to set :raise_errors
  # to true or false depending on whether you want all errors, regadless of class, to be raised
  # up the stack and essentially throw a 500.
  #
  # If you decide to use your own Error Handler. You may pass it in for the value of the key
  # :error_handler as a cofniguration object. You must implement the BaseErrorHandler class.
  # @see BaseHandler Interface for Error Handling for DynamoDB Session Store.
  #
  # == Locking Strategy
  # By default, locking is not implemented for the session store. You must trigger the
  # locking strategy through the configuration of the session store. Pessimistic locking,
  # in this case, means that only one read can be made on a session at once. While the session
  # is being read by the process with the lock, other processes may try to obtain a lock on
  # the same session but will be blocked. See the accessors with lock in their name for
  # how to configure the pessimistic locking strategy to your needs.
  #
  # == DynamoDB Specific Options
  # You may configure the table name and table hash key value of your session table with
  # the :table_name and :table_key options. You may also configure performance options for
  # your table with the :consistent_read, :read_capacity, write_capacity. For more information
  # about these configurations see CreateTable method for Amazon DynamoDB.
  #
  class Configuration

    # Default configuration options
    DEFAULTS = {
      :access_key_id => nil,
      :secret_access_key => nil,
      :table_name => "sessions",
      :table_key => "session_id",
      :user_key => nil,
      :consistent_read => true,
      :read_capacity => 10,
      :write_capacity => 5,
      :raise_errors => false,
      :max_age => 604800, # 1weeks
      :enable_locking => false,
      :lock_expiry_time => 500,
      :lock_retry_delay => 500,
      :lock_max_wait_time => 1,
      :secret_key => nil,
      :verbose => false,
      :local_mode => false,
      :local_endpoint => "http://localhost:8000"
    }

    attr_reader :access_key_id
    attr_reader :secret_access_key

    # @return [String] Session table name.
    attr_reader :table_name

    # @return [String] Session table hash key name.
    attr_reader :table_key

    # @return [String] Name of user key in session data.
    attr_reader :user_key

    # @return [true] If a strongly consistent read is used
    # @return [false] If an eventually consistent read is used.
    # See Aws DynamoDB documentation for table consistent_read for more
    # information on this setting.
    attr_reader :consistent_read

    # @return [Integer] Maximum number of reads consumed per second before
    #   DynamoDB returns a ThrottlingException. See Aws DynamoDB documentation
    #   for table read_capacity for more information on this setting.
    attr_reader :read_capacity

    # @return [Integer] Maximum number of writes consumed per second before
    #   DynamoDB returns a ThrottlingException. See Aws DynamoDB documentation
    #   for table write_capacity for more information on this setting.
    attr_reader :write_capacity

    # @return [true] All errors are raised up the stack when default ErrorHandler
    #   is used.
    # @return [false] Only specified errors are raised up the stack when default
    #   ErrorHandler is used.
    attr_reader :raise_errors

    # @return [DynamoDB Client] DynamoDB client.
    attr_reader :dynamo_db_client

    # @return [Error Handler] An error handling object that handles all exceptions
    #   thrown during execution of the Aws DynamoDB Session Store Rack Middleware.
    #   For more information see the Handling Errors Section.
    attr_reader :error_handler

    # @return [Integer] Maximum number of seconds earlier
    #   from the current time that a session was updated.
    attr_reader :max_age

    # @return [String] The secret key for HMAC encryption.
    attr_reader :secret_key

    # @return [true] Pessimistic locking strategy will be implemented for
    #   all session accesses.
    # @return [false] No locking strategy will be implemented for
    #   all session accesses.
    attr_reader :enable_locking

    # @return [Integer] Time in milleseconds after which lock will expire.
    attr_reader :lock_expiry_time

    # @return [Integer] Time in milleseconds to wait before retrying to obtain
    #   lock once an attempt to obtain lock has been made and has failed.
    attr_reader :lock_retry_delay

    # @return [Integer] Maximum time in seconds to wait to acquire lock
    #   before giving up.
    attr_reader :lock_max_wait_time

    # @return [true] Info printed to stdout
    # @return [false] Run silent, run deep
    attr_reader :verbose

    # @return [true] DynamoDB Local Mode
    # @return [false] DynamoDB Mode
    attr_reader :local_mode

    # @return [String] DynamoDB Local EndPoint URL
    attr_reader :local_endpoint

    # Provides configuration object that allows access to options defined
    # during Runtime, in a YAML file, in the ENV and by default.
    #
    # @option options [String] :table_name ("Sessions") Name of the session
    #   table.
    # @option options [String] :table_key ("id") The hash key of the sesison
    #   table.
    # @option options [String] :user_key ("id") Name of user key in session.
    # @option options [Boolean] :consistent_read (true) If true, a strongly
    #   consistent read is used. If false, an eventually consistent read is
    #   used.
    # @option options [Integer] :read_capacity (10) The maximum number of
    #   strongly consistent reads consumed per second before
    #   DynamoDB raises a ThrottlingException. See Aws DynamoDB documentation
    #   for table read_capacity for more information on this setting.
    # @option options [Integer] :write_capacity (5) The maximum number of writes
    #   consumed per second before DynamoDB returns a ThrottlingException.
    #   See Aws DynamoDB documentation for table write_capacity for more
    #   information on this setting.
    # @option options [DynamoDB Client] :dynamo_db_client
    #   (Aws::DynamoDB::ClientV2) DynamoDB client used to perform database
    #   operations inside of middleware application.
    # @option options [Boolean] :raise_errors (false) If true, all errors are
    #   raised up the stack when default ErrorHandler. If false, Only specified
    #   errors are raised up the stack when default ErrorHandler is used.
    # @option options [Error Handler] :error_handler (DefaultErrorHandler)
    #   An error handling object that handles all exceptions thrown during
    #   execution of the Aws DynamoDB Session Store Rack Middleware.
    #   For more information see the Handling Errors Section.
    # @option options [Integer] :max_age (nil) Maximum number of seconds earlier
    #   from the current time that a session was updated.
    # @option options [String] :secret_key (nil) Secret key for HMAC encription.
    # @option options [Integer] :enable_locking (false) If true, a pessimistic
    #   locking strategy will be implemented for all session accesses.
    #   If false, no locking strategy will be implemented for all session
    #   accesses.
    # @option options [Integer] :lock_expiry_time (500) Time in milliseconds
    #   after which lock expires on session.
    # @option options [Integer] :lock_retry_delay (500) Time in milleseconds to
    #   wait before retrying to obtain lock once an attempt to obtain lock
    #   has been made and has failed.
    # @option options [Integer] :lock_max_wait_time (500) Maximum time in seconds
    #   to wait to acquire lock before giving up.
    # @option options [String] :secret_key (SecureRandom.hex(64))
    #   Secret key for HMAC encription.
    # @option options [Boolean] :verbose (true)
    # @option options [Boolean] :local_mode (true)
    # @option options [String] :local_endpoint (100) Default: http://localhost:8000
    def initialize(options = {})
      @options = default_options.merge(
        file_options(options).merge(
          symbolize_keys(options)
        )
      )
      check_aws_keys!(@options)
      @options = update_option_dynamodb_local_endpoint(@options) if @options[:local_mode]
      @options = client_error.merge(@options)
      set_attributes(@options)
    end

    # @return [Hash] The merged configuration hash.
    def to_hash
      @options.dup
    end

    def session_tables(opts={})
      scan_query = { table_name: table_name }.merge(opts)
      dynamo_db_client.scan(scan_query)
    end

    private

    def check_aws_keys!(options = {})
      val = options[:access_key_id]
      fail 'set config[:access_key_id]' if val.nil? || val.empty?
      val = options[:secret_access_key]
      fail 'set config[:secret_access_key]' if val.nil? || val.empty?
    end

    def update_option_dynamodb_local_endpoint(options)
      options[:endpoint] = options[:local_endpoint]
      options
    end

    # @return [Hash] DDB client.
    def gen_dynamo_db_client
      dynamo_db_client = @options[:dynamo_db_client]
      if dynamo_db_client.nil?
        client_opts = client_subset(@options)
        dynamo_db_client = Aws::DynamoDB::Client.new(client_opts)
      end

      {:dynamo_db_client => dynamo_db_client}
    end

    # @return [Hash] Default Error Handler
    def gen_error_handler
      default_handler = Aws::SessionStore::DynamoDB::Errors::DefaultHandler
      error_handler = @options[:error_handler] ||
                            default_handler.new(@options[:raise_errors])
      {:error_handler => error_handler}
    end

    # @return [Hash] Client and error objects in hash.
    def client_error
      gen_error_handler.merge(gen_dynamo_db_client)
    end

    # @return [Hash] Default Session table options.
    def default_options
      DEFAULTS
    end

    # @return [Hash] Environment options that are useful for Session Handler.
    def env_options
      default_options.keys.inject({}) do |opts, opt_name|
        env_var = "DYNAMO_DB_SESSION_#{opt_name.to_s.upcase}"
        opts[opt_name] = ENV[env_var] if ENV.key?(env_var)
        opts
      end
    end

    # @return [Hash] File options.
    def file_options(options = {})
      if rails_defined && File.exists?(rails_config_file_path)
        load_from_file(rails_config_file_path)
      else
        {}
      end
    end

    # @return [Boolean] Necessary Rails variables defined.
    def rails_defined
      defined?(Rails) && defined?(Rails.root) && defined?(Rails.env)
    end

    # Load options from YAML file depending on existence of Rails
    # and possible development stage defined.
    def load_from_file(file_path)
      require "erb"
      opts = YAML.load(ERB.new(File.read(file_path)).result)[Rails.env] || {}
      symbolize_keys(opts)
    end

    # @return [String] Configuration path found in environment or YAML file.
    def config_file_path(options)
      options[:config_file] || ENV["DYNAMO_DB_SESSION_CONFIG_FILE"]
    end

    # @return [String] Rails configuraton path to YAML file default.
    def rails_config_file_path
      File.join(Rails.root, "config", "session_store_dynamodb.yml")
    end

    # Set accessible attributes after merged options.
    def set_attributes(options)
      @options.keys.each do |opt_name|
        instance_variable_set("@#{opt_name}", options[opt_name])
      end
    end

    # @return [Hash] Hash with all symbolized keys.
    def symbolize_keys(options)
      options.inject({}) do |opts, (opt_name, opt_value)|
        opts[opt_name.to_sym] = opt_value
        opts
      end
    end

    CLIENT_KEYS = [
        :access_key_id, :secret_access_key, :credentials, :region, :endpoint,
        :http_continue_timeout, :http_idle_timeout, :http_open_timeout, :http_read_timeout,
        :ssl_ca_bundle, :ssl_ca_directory, :ssl_ca_store, :ssl_verify_peer,
        :retry_limit, :log_level, :logger, :profile, :stub_responses
    ]

    # @return [Hash] Client subset options hash.
    def client_subset(options = {})
      options.inject({}) do |opts, (opt_name, opt_value)|
        opts[opt_name.to_sym] = opt_value if CLIENT_KEYS.include?(opt_name.to_sym)
        opts
      end
    end
  end
end
