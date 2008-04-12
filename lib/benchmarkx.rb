require "benchmark"
require "gruff"

module BenchmarkX
  VERSION = "001"

  include Benchmark

  alias :benchmark_orig :benchmark

  # Same as Benchmark.benchmark.
  def benchmark(caption = "", label_width = nil, fmtstr = nil, *labels)
    # copied from benchmark.rb
    sync = STDOUT.sync
    STDOUT.sync = true
    label_width ||= 0
    fmtstr ||= FMTSTR
    raise ArgumentError, "no block" unless iterator?
    print caption

    # modified
    report = Report.new(label_width, fmtstr)
    results = yield(report)

    # copied from benchmark.rb and modified
    Array === results and results.grep(Tms).each {|t|
      label = labels.shift
      print((label || t.label || "").ljust(label_width), t.format(fmtstr))
      report.record(label, t)
    }
    STDOUT.sync = sync

    # new
    report.render
  end

  alias :bmbm_orig :bmbm

  # Same as Benchmark.bmbm
  def bmbm(width = 0, &blk)
    # copied from benchmark.rb
    job = Job.new(width)
    yield(job)
    width = job.width
    sync = STDOUT.sync
    STDOUT.sync = true

    # copied from benchmark.rb
    # rehearsal
    print "Rehearsal "
    puts '-'*(width+CAPTION.length - "Rehearsal ".length)
    list = []
    rehearsal = Report.new # appended
    job.list.each{|label,item|
      print(label.ljust(width))
      res = Benchmark::measure(&item)
      print res.format()
      list.push res

      # new
      rehearsal.record(label, res)
    }
    sum = Tms.new; list.each{|i| sum += i}
    ets = sum.format("total: %tsec")
    printf("%s %s\n\n",
           "-"*(width+CAPTION.length-ets.length-1), ets)

    # new
    rehearsal.filename = "rehearsal-" + rehearsal.filename
    rehearsal.gruff.title = rehearsal.gruff.title.to_s + "(Rehearsal)"
    rehearsal.render

    # copied from benchmark.rb
    # take
    print ' '*width, CAPTION
    list = []
    ary = []
    report = Report.new # appended
    job.list.each{|label,item|
      GC::start
      print label.ljust(width)
      res = Benchmark::measure(&item)
      print res.format()
      ary.push res
      list.push [label, res]

      # new
      report.record(label, res)
    }

    # new
    report.render

    # copied from benchmark.rb
    STDOUT.sync = sync
    ary
  end

  module_function :benchmark, :measure, :realtime, :bm, :bmbm

  class Report < Benchmark::Report
    attr_accessor :filename
    attr_reader :gruff, :labels, :utimes, :stimes, :totals, :reals

    alias :initialize_orig :initialize

    def initialize(width = 0, fmtstr = nil)
      initialize_orig(width, fmtstr)
      @gruff = Gruff::SideBar.new
      @gruff.x_axis_label = "sec"
      @gruff.sort = false
      @labels, @utimes, @stimes, @totals, @reals = [], [], [], [], []
      @filename = "graph.png"
    end

    def item(label = "", *fmt, &blk)
      # copied from benchmark.rb
      print label.ljust(@width)
      res = Benchmark::measure(&blk)
      print res.format(@fmtstr, *fmt)

      # new
      record(label, res)

      # copied from benchmark.rb
      res
    end

    alias :report :item

    def record(label,time)
      @labels << label
      @utimes << time.utime
      @stimes << time.stime
      @totals << time.total
      @reals << time.real
    end

    def render
      @labels.each_with_index{|label, idx| @gruff.labels[idx] = label }
      @gruff.data("user", @utimes)
      @gruff.data("system", @stimes)
      @gruff.data("total", @totals)
      @gruff.data("real", @reals)
      @gruff.write(@filename)
      return self
    end
  end
end

# copied from benchmark.rb and modified a little
if __FILE__ == $0
  include BenchmarkX

  n = ARGV[0].to_i.nonzero? || 50000
  puts "#{n} times iterations of `a = \"1\"'"
  benchmark("       " + CAPTION, 7, FMTSTR) do |x|
    x.filename = "graph1.png"
    x.gruff.title = "#{n} times iterations of `a = \"1\"'"
    x.report("for:")   {for i in 1..n; a = "1"; end} # Benchmark::measure
    x.report("times:") {n.times do   ; a = "1"; end}
    x.report("upto:")  {1.upto(n) do ; a = "1"; end}
  end
end
