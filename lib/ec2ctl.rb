require "ec2ctl/version"

require "thor"
require "aws-sdk"
require "net/ssh"
require "net/http"
require "colorize"
require "terminal-table"
require "timeout"
require "unindent"

module Ec2ctl
  class CLI < Thor
    own_region = begin
      timeout 3 do
        Net::HTTP.get("169.254.169.254", "/latest/meta-data/placement/availability-zone")[0..-2]
      end
    rescue
      nil
    end

    class_option :access_key_id,     default: nil,        aliases: [:k]
    class_option :secret_access_key, default: nil,        aliases: [:s]
    class_option :region,            default: own_region, aliases: [:r]
    class_option :profile
    class_option :color,             default: true,       type: :boolean

    option :sort, default: name, aliases: [:S]
    option :limit, type: :numeric, aliases: [:l]
    desc "list PATTERN", "List all instances in region. Specify PATTERN to filter results by name."
    def list pattern = ""
      rows = []

      ec2.instances.each do |instance|
        name = instance.tags["Name"].to_s
        next if !pattern.empty? and !name.match pattern

        rows << [
          instance.id,
          name,
          instance.instance_type,
          instance.private_ip_address,
          instance.public_ip_address,
          status_colorize(instance.status),
        ]
      end

      col = case options[:sort]
      when /ID/i      then 0
      when /Name/i    then 1
      when /Type/i    then 2
      when /private/i then 3
      when /public/i  then 4
      when /status/i  then 5
      end

      rows.sort_by! {|row| row[col].to_s} if col
      rows = rows[0, options[:limit]] if options[:limit]

      puts Terminal::Table.new headings: ["ID", "Name", "Type", "Private IP", "Public IP", "Status"], rows: rows
    end

    desc "status NAME", "Show instance status. Instance will be searched by Name tag."
    def status name
      instance = find_instance_by_name name
      tags     = instance.tags.to_h

      puts <<-EOS.unindent
        * Name:              #{tags["Name"]}
        * Status:            #{status_colorize instance.status}
        * Instance Type:     #{instance.instance_type}
        * Private IP:        #{instance.private_ip_address}
        * Public IP:         #{instance.public_ip_address}
        * Availability Zone: #{instance.availability_zone}
        * Other Tags:        #{tags.reject {|k, v| k == "Name"}.inspect}
      EOS
    end

    desc "start NAME", "Start instance. Instance will be searched by Name tag."
    def start name
      instance = find_instance_by_name name
      abort "Instance is not stopped!" unless instance.status == :stopped
      instance.start
      sleep 2
      puts "Instance is now #{status_colorize instance.status}."
    end

    desc "stop NAME", "Stop instance. Instance will be searched by Name tag."
    def stop name
      instance = find_instance_by_name name
      abort "Instance is not running!" unless instance.status == :running
      instance.stop
      sleep 2
      puts "Instance is now #{status_colorize instance.status}."
    end

    option :user,          default: "ec2-user",      aliases: [:u]
    option :port,          default: 22,              aliases: [:p]
    option :identity_file, default: "~/.ssh/id_rsa", aliases: [:i]
    option :passphrase,    default: nil,             aliases: [:P]
    option :via_public_ip, default: false,           type: :boolean
    desc "ssh NAME COMMAND", "Execute remote command to specified instance by given name."
    def ssh name, command
      instance   = find_instance_by_name name
      ip_address = options[:via_public_ip] ? instance.public_ip_address : instance.private_ip_address

      ssh_options = {
        keys:       [options[:identity_file]],
        passphrase: options[:passphrase],
      }

      Net::SSH.start ip_address, options[:user], ssh_options do |ssh|
        puts ssh.exec!(command)
      end
    end

    desc "add NAME ELB_NAME", "Add instance to ELB. Instance will be searched by Name tag."
    def add name, elb_name
      instance      = find_instance_by_name name
      load_balancer = find_load_balancer_by_name elb_name

      abort "Instance is already registered to the load balancer!" if load_balancer.instances.include? instance

      puts "Adding instance to the load balancer..."
      load_balancer.instances.add instance
    end

    desc "remove NAME ELB_NAME", "Remove instance from ELB. Instance will be searched by Name tag."
    def remove name, elb_name
      instance      = find_instance_by_name name
      load_balancer = find_load_balancer_by_name elb_name

      abort "Instance is not registered to the load balancer!" unless load_balancer.instances.include? instance

      puts "Removing instance from the load balancer..."
      load_balancer.instances.remove instance
    end

    desc "lb ELB_NAME", "Show load balancer registered instance statuses."
    def lb elb_name
      load_balancer = find_load_balancer_by_name elb_name
      instances     = load_balancer.instances
      rows          = []

      load_balancer.instances.health.each do |instance_health|
        next unless instances.any? {|instance| instance.id == instance_health[:instance].id}

        rows << [
          instance_health[:instance].tags["Name"],
          instance_health[:instance].id,
          instance_health[:description],
          instance_health[:state],
        ]
      end

      puts Terminal::Table.new headings: ["Name", "Instance ID", "Description", "State"], rows: rows
    end

    private

    def aws_config
      hash = {}

      if options[:profile]
        provider = AWS::Core::CredentialProviders::SharedCredentialFileProvider.new profile_name: options[:profile]
        hash.update credential_provider: provider
      else
        hash.update access_key_id: options[:access_key_id], secret_access_key: options[:secret_access_key] if options[:access_key_id] && options[:secret_access_key]
      end

      hash.update region: options[:region] if options[:region]
      hash
    end

    def ec2
      AWS::EC2.new aws_config
    end

    def elb
      AWS::ELB.new aws_config
    end

    def status_colorize status
      return status unless options[:color]

      color = case status
      when :pending, :stopping then :magenta
      when :running            then :green
      when :stopped            then :light_blue
      when :shutting_down      then :yellow
      when :terminated         then :red
      else                     :default
      end

      status.to_s.colorize color
    end

    def find_instance_by_name name
      instance = ec2.instances.with_tag("Name", name).first
      abort "No instance found!" unless instance
      puts "Instance found: " + instance.inspect
      instance
    end

    def find_load_balancer_by_name name
      load_balancer = elb.load_balancers[name]
      abort "No load balancer found!" unless load_balancer
      puts "Load balancer found: " + load_balancer.inspect
      load_balancer
    end
  end
end
