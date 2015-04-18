
# Uga\_Uga

Don't use this.
Use [Parslet](http://kschiess.github.io/parslet/) or [OMeta](https://github.com/alexwarth/ometa-js).

Here is a video on creating your own external DSL:
[Writing DSL's with Parslet by Jason Garber](https://www.youtube.com/watch?v=ET_POMJNWNs)

## Installation

    gem 'uga_uga'

## Usage

```ruby
  require "uga_uga"

  code = <<-EOF
    bobby {
      howie { :funny }
      mandel { "comedian" }
    }
  EOF

  results = []

  Uga_Uga.uga code do |name, blok|

    case name

    when "bobby"
      results << "bobby was called"
      blok

    when "howie"
      results << "howie was called"
      blok

    when "mandel"
      results << "mandel was called"
      blok

    when ":funny", '"comedian"'

    else
      fail ArgumentError, "Command not found: #{name.inspect}"
    end

  end

  puts results.inspect

```
