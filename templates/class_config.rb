#!/usr/bin/env ruby

require 'yaml'
require_relative 'utilities.rb'

class Config
  include Helpers

  attr_accessor :config
  attr_reader :raw

  # Class initialization
  #
  # @param String {config_file} The path to the config file
  def initialize(config_file)
    collect_config_values if validates(config_file)
  end

  # Validate
  #
  # Reads the config file and validates necessary values
  def validates(config_file)
    vagrant_dir = File.expand_path(Dir.pwd)

    begin
      raise TypeError unless defined?(config_file) && (config_file.kind_of? String)
    rescue TypeError => e
      handle_error(e, "There was an error with `config_file` declaration: '#{config_file}'")
    end

    @config_config_file_path = File.join(vagrant_dir, config_file)

    begin
      raise Errno::ENOENT unless File.file?(@config_config_file_path)
    rescue Errno::ENOENT => e
      handle_error(e, "Config file not found")
    end

    # Save raw config files for access in the Vagrantfile
    @raw = YAML.load_file(@config_config_file_path)

    # Allowed PHP values and associated PHP install directories
    @php_versions = ['56', '70', '71']
    @php_dirs = ['php56', 'php70', 'php71']

    box_defaults = {}
    box_defaults['php'] = @php_versions.at(1)
    box_defaults['ssl'] = false
    box_defaults['ssl_enabled'] = false
    box_defaults['san_list'] = []

    # Fill in the blanks with default values
    @raw = box_defaults.merge(@raw)

    begin
      raise KeyError unless @php_versions.include?(@raw.fetch('php').to_s)
    rescue KeyError => e
      handle_error(e, "Accepted `php` values are '#{@php_versions.first}', '#{@php_versions.at(1)}', and '#{@php_versions.last}'")
    end

    @raw['php_dir'] = @php_dirs[@php_versions.index(@raw.fetch('php').to_s)]

    required_properties = ['user', 'root', 'sync', 'host']
    @raw['sites'].each_key do |dict|
      required_properties.each do |property|
        begin
          raise KeyError unless @raw['sites'].fetch(dict).fetch(property).kind_of? String
        rescue KeyError => e
          handle_error(e, "Missing or incorrect `#{property}` value for site '#{dict}'")
        end
      end
    end
  end

  # Transforms and collects site property values
  def collect_config_values
    @config = {}.merge(@raw)

    sites = {}
    subdomains = {}

    users = {}
    groups = {}
    user_id = 501
    group_id = 901

    vhosts_dir = '/usr/local/dh/apache2/apache2-dreambox/etc/vhosts/'

    site_defaults = {}
    site_defaults['is_subdomain'] = false
    site_defaults['php'] = @config.fetch('php')
    site_defaults['php_dir'] = @config.fetch('php_dir')

    @config['sites'].each_key do |dict|
      # Make a deep copy of the hash so it's not altered as we are iterating
      site = Marshal.load(Marshal.dump(@config['sites'].fetch(dict)))

      # User and Group ID
      # Assign a UID based either on a previously-declared user or a new user
      # Assign a GID based either on a previously-declared group, a new group, or the default

      if users.key?(site['user'])
        site['uid'] = users[site['user']]
      else
        site['uid'] = user_id += 1
        users.merge!(site['user'] => site['uid'])
      end

      site['group'] = 'dreambox' unless site['group']
      if groups.key?(site['group'])
        site['gid'] = groups[site['group']]
      else
        site['gid'] = group_id += 1
        groups.merge!(site['group'] => site['gid'])
      end

      # PHP Version
      # Collect the root PHP version unless the site's version is set
      # Set the `php_dir` based on the collected PHP version
      site['php'] =
        if site.key?('php')
          site.fetch('php').to_s
        else
          @config.fetch('php').to_s
        end
      site['php_dir'] = @php_dirs[@php_versions.index(site.fetch('php'))]

      # Paths
      # Clean and build paths used by Vagrant and/or the provisioners

      site['sync'] = trim_slashes(@config['sites'].fetch(dict).fetch('sync'))

      site['sync_destination'] = File.join('/home/', site.fetch('user'), trim_slashes(site.fetch('root')))
      site['document_root'] = (site.key?('public')) ?
        File.join(site['sync_destination'], trim_slashes(site.fetch('public'))) :
        site['sync_destination']

      site['vhost_file'] = File.join("#{vhosts_dir}", "#{dict}.conf")

      # SSL
      # Inherit the SSL setting from the root unless set in the site
      # The SSL setting informs whether or not hosts and aliases are collected

      site['ssl'] = @config.fetch('ssl') unless site.key?('ssl')

      if (@config.fetch('ssl') && false != site.fetch('ssl')) || site.fetch('ssl')
        @config['ssl_enabled'] = ssl_enabled = true
      end

      add_item_to_root(site.fetch('host'), 'san_list') if ssl_enabled

      if site['aliases'].kind_of? Array
        site['aliases'].each { |the_alias| add_item_to_root(the_alias, 'san_list') } if ssl_enabled
        # Aliases will be printed in the site's Apache conf
        site['aliases'] = site.fetch('aliases').join(' ')
      end

      # Subdomains
      # Each subdomain is converted to a site hash; gets its own Apache conf

      if site['subdomains'].kind_of? Hash
        site['subdomains'].each_key do |sub|
          path = site['subdomains'][sub]
          subdomain_name = "#{sub}.#{dict}"
          subdomains[subdomain_name] = {
            'user' => site.fetch('user'), # Inherited from the parent site
            'uid' => site.fetch('uid'), # Inherited from the parent site
            'group' => site.fetch('group'), # Inherited from the parent site
            'gid' => site.fetch('gid'), # Inherited from the parent site
            'document_root' => File.join(site['document_root'], trim_slashes(path)),
            'is_subdomain' => true,
            'vhost_file' => File.join("#{vhosts_dir}", "#{subdomain_name}.conf"),
            'host' => "#{sub}.#{ remove_www(site.fetch('host')) }",
            'ssl' => site.fetch('ssl'), # Inherited from the parent site
            'php' => site.fetch('php'), # Inherited from the parent site
            'php_dir' => site.fetch('php_dir'), # Inherited from the parent site
          }
          add_item_to_root(subdomains[subdomain_name].fetch('host'), 'san_list') if ssl_enabled
        end
      end

      # Clean properties not used by Vagrant and/or provisioners
      site.delete('public')
      site.delete('subdomains')

      # Fill in the blanks with the site default values
      sites[dict] = site_defaults.merge(site)
    end

    # Merge subdomain and sites
    @config['sites'] = @config.fetch('sites').merge(sites)
    @config['sites'] = @config.fetch('sites').merge(subdomains)

    # Build the hosts string
    # To be echoed onto openssl.cnf during SSL setup
    @config['san_list'].map!.with_index(1) { |host, index| "DNS.#{index} = #{host}" } if @config['san_list'].length > 0
    delimiter = (@config['san_list'].length > 0) ? '\n' : ''
    @config['san_list'] = @config.fetch('san_list').join(delimiter)

    print_debug_info(@config, @config_config_file_path) if @config.key?('debug') && @config.fetch('debug')
  end
end
