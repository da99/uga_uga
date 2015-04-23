

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
      'p', ['"my paragraph"']
    ]
  end

  it "runs code from README.md" do
    file     = File.expand_path(File.dirname(__FILE__) + '/../README.md')
    contents = File.read( file )
    code     = (contents[/```ruby([^`]+)```/] && $1).gsub('puts ','')

    result = eval(code, nil, file, contents.split("\n").index('```ruby') + 1)

    result.should == [
      "bobby was called",
      "howie called with :funny",
      'mandel called with "comedian"'
    ]
  end # === it

  it "parses lines without blocks" do
    code = <<-EOF
      a :href => addr /a
      a :href addr    /a
      p { }
    EOF

    clean(uga code).
      should == [
        :html, "a :href => addr /a",
        :html, "a :href addr    /a",
        :css, []
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

    clean(uga code).
      should == [
        :css, [
          :css, [
            :css, ['"my"']
          ]
        ]
    ]
  end

  it "passes all text before a block start: cmd, cmd {" do
    result = []
    code = %^
      cmd, cmd {
        inner, inner {
        }
      }
    ^
    uga(code).stack.first[:selectors]
    .should == "cmd, cmd"
  end # === it

  it "does not parse mustaches as blocks: {{ }}" do
    code = "
      p { {{code}} }
   "
   clean(uga(code)).should == [:css, ['{{code}}']]
  end # === it

end # === describe :uga
