

describe :uga.inspect do

  it "runs" do
    code = <<-EOF
      p {
        "my paragraph"
      }
    EOF

    o = Uga_Uga.new(code) do
      case
      when rex?(" (word) { ")
        final = {
          :type =>captures.first,
          :raw  =>grab_until(bracket shift, '}')
        }
      when stack.empty?
        final = {
          :type=>String,
          :output=>grab_all.join("\n")
        }
      else
        fail ArgumentError, "Unknown common: #{l!}"
      end
    end

    clean(o).should == [
      'p', [String, '"my paragraph"']
    ]
  end

  it "runs code from README.md" do
    file     = File.expand_path(File.dirname(__FILE__) + '/../README.md')
    contents = File.read( file )
    code     = (contents[/```ruby([^`]+)```/] && $1).gsub('puts ','')

    result = eval(code, nil, file, contents.split("\n").index('```ruby') + 1)
    result.should.match /bobby/
  end # === it

  it "parses lines without blocks" do
    code = <<-EOF
      a :href => addr /a
      a :href addr    /a
      p { }
    EOF

    Uga_Uga.clean(Uga_Uga.uga code).
      should == [ "a :href => addr",
                  "a :href addr",
                  "p", []
    ]
  end

  it "parses inner blocks" do
    code = <<-EOF
      p {
        span {
          inner { "my" }
        }
      }
    EOF

    Uga_Uga.clean(Uga_Uga.uga code).
      should == [
        "p", [
          "span", [
            "inner", ['"my"']
          ]
        ]
    ]
  end

  it "yields the inner block" do
    result = []
    code = <<-EOF
      p {
        span {
          1 {
            2 {
              3 { "my text" }
            }
          }
        }
      }
    EOF

    Uga_Uga.uga(code) do |cmd, code|
      if cmd['"']
        result << cmd
      else
        result << cmd.to_sym 
      end
      code
    end

    result.should == [:p, :span, :'1', :'2', :'3', '"my text"']
  end # === it

  it "passes all text before a block start: cmd, cmd {" do
    result = []
    code = %^
      cmd, cmd {
        inner, inner {
        }
      }
    ^
    Uga_Uga.uga(code) do |cmd, code|
      result << cmd
      code
    end
    result.should == ["cmd, cmd", "inner, inner"]
  end # === it

  it "yields lines without a block" do
    code = "
      br /
      br /
      p { }
    "
    result = []
    Uga_Uga.uga(code) do |cmd, code|
      result << cmd
      code
    end

    result.should == ['br /', 'br /', 'p']
  end # === it

  it "passes block w/original whitespace" do
    blok = "
         a 
          a a
          a
    "
    code = "
      p {#{blok}}
   "
   result = nil
   Uga_Uga.uga(code) { |cmd, code| result = code.join }
   result.should == blok
  end # === it

  it "does not parse mustaches as blocks: {{ }}" do
    code = "
      p {{ code }}
   "
   result = nil
   Uga_Uga.uga(code) { |cmd, code| result = cmd }
   result.should == code.strip
  end # === it

end # === describe :uga
