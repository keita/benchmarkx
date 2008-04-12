$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")
require "benchmarkx"

require "rubygems"
require "stringio"
require "bacon"

describe "BenchmarkX" do
  before do
    FileUtils.rm_f "graph.png"
    FileUtils.rm_f "rehearsal-graph.png"
  end

  after do
    FileUtils.rm_f "graph.png"
    FileUtils.rm_f "rehearsal-graph.png"
  end

  # Records the reporting within the block
  def report(&block)
    begin
      @result = StringIO.new
      $stdout = @result
      yield
      $stdout = STDOUT
    rescue Object => ex
      $stdout = STDOUT
      raise ex
    end
  end

  it 'should create a graph image' do
    report do
      BenchmarkX.bm do |x|
        x.report("A") { 1 }
        x.report("B") { 2 }
        x.report("C") { 3 }
      end
    end
    File.exist?("graph.png").should.be.true
  end

  it 'should handle "bm" method' do
    report do
      Proc.new {
        BenchmarkX.bm do |x|
          x.report("A") { 1 }
          x.report("B") { 2 }
          x.report("C") { 3 }
        end
      }.should.not.raise
    end
  end

  it 'should handle "bmbm" method' do
    report do
      Proc.new {
        BenchmarkX.bmbm do |x|
          x.report("A") { 1 }
          x.report("B") { 2 }
          x.report("C") { 3 }
        end
      }.should.not.raise
    end
    File.exist?("rehearsal-graph.png").should.be.true
    File.exist?("graph.png").should.be.true
  end

  it 'should report the result to STDOUT by the normal benchmark format' do
    report do
      BenchmarkX.bm do |x|
        x.report("A") { 1 }
        x.report("B") { 2 }
        x.report("C") { 3 }
      end
    end
    @result.string.should =~ /user\s+system\s+total\s+real/
  end

  it 'should setup gruff object' do
    report do
      BenchmarkX.bm do |x|
        x.gruff.should.be.kind_of(Gruff::SideBar)
        x.gruff.title = "BenchmarkX"
        x.gruff.title.should == "BenchmarkX"
        x.report("A") { 1 }
        x.report("B") { 2 }
        x.report("C") { 3 }
      end
    end
  end

  it 'should keep label order' do
    report do
      BenchmarkX.bm do |x|
        x.report("A") { 1 }
        x.report("B") { 2 }
        x.report("C") { 3 }
        x.labels.should == ["A", "B", "C"]
      end
    end
  end
end
