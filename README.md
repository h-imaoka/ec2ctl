# Ec2ctl

**!!! WORK IN PROGRESS !!!**

TODO: Add spec. etc...

## Installation

Add this line to your application's Gemfile:

    gem 'ec2ctl'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ec2ctl

## Usage

TODO: Write more usage instructions here

```
Commands:
  ec2ctl add NAME ELB_NAME     # Add instance to ELB. Instance will be searched by Name tag.
  ec2ctl help [COMMAND]        # Describe available commands or one specific command
  ec2ctl lb ELB_NAME           # Show load balancer registered instance statuses.
  ec2ctl list PATTERN          # List all instances in region. Specify PATTERN to filter results by name.
  ec2ctl remove NAME ELB_NAME  # Remove instance from ELB. Instance will be searched by Name tag.
  ec2ctl ssh NAME COMMAND      # Execute remote command to specified instance by given name.
  ec2ctl start NAME            # Start instance. Instance will be searched by Name tag.
  ec2ctl status NAME           # Show instance status. Instance will be searched by Name tag.
  ec2ctl stop NAME             # Stop instance. Instance will be searched by Name tag.

Options:
  k, [--access-key-id=ACCESS_KEY_ID]
  s, [--secret-access-key=SECRET_ACCESS_KEY]
  r, [--region=REGION]
      [--profile=PROFILE]
      [--color], [--no-color]
                                              # Default: true
```

## Contributing

1. Fork it ( http://github.com/y13i/ec2ctl/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
