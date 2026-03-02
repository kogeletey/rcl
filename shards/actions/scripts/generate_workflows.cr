require "../../../src/rcl"

Dir.mkdir_p(".github/workflows")

def as_s(value : RCL::Value?) : String
  value.is_a?(String) ? value : ""
end

def as_arr(value : RCL::Value?) : Array(RCL::Value)
  value.is_a?(Array(RCL::Value)) ? value : ([] of RCL::Value)
end

def as_h(value : RCL::Value?) : Hash(String, RCL::Value)
  value.is_a?(Hash(String, RCL::Value)) ? value : ({} of String => RCL::Value)
end

Dir.glob("shards/actions/workflows/*.rcl") do |path|
  doc = RCL.parse_file(path)
  block = doc.blocks.first?
  raise "missing root workflow block in #{path}" unless block
  raise "root block must be `workflow` in #{path}" unless block.not_nil!.name == "workflow"
  workflow = doc.to_h
  name = as_s(workflow["name"]?)
  raise "workflow.name must be string in #{path}" if name.empty?
  events = as_arr(workflow["on"]?)
  raise "workflow.on must be non-empty array in #{path}" if events.empty?
  jobs = as_h(workflow["job"]?)
  raise "workflow.job must be object in #{path}" if jobs.empty?

  id = block.not_nil!.argument || File.basename(path, ".rcl")
  out = [] of String
  out << "name: #{name}"
  out << ""
  out << "on:"
  events.each do |event|
    raise "workflow.on items must be string in #{path}" unless event.is_a?(String)
    out << "  - #{event.as(String)}"
  end
  out << ""
  out << "jobs:"

  jobs.keys.sort.each do |job_id|
    job_any = jobs[job_id]
    job = as_h(job_any)
    runs_on = as_s(job["runs_on"]?)
    raise "job #{job_id} runs_on must be string in #{path}" if runs_on.empty?
    steps = as_arr(job["steps"]?)
    raise "job #{job_id} steps must be non-empty array in #{path}" if steps.empty?
    out << "  #{job_id}:"
    out << "    runs-on: #{runs_on}"
    out << "    steps:"
    steps.each do |step|
      raise "job #{job_id} steps item must be string in #{path}" unless step.is_a?(String)
      step_s = step.as(String)
      if step_s.starts_with?("uses:")
        out << "      - uses: #{step_s.sub("uses:", "")}"
      elsif step_s.starts_with?("run:")
        out << "      - run: #{step_s.sub("run:", "")}"
      else
        out << "      - run: #{step_s}"
      end
    end
  end

  out_path = ".github/workflows/#{id}.yml"
  File.write(out_path, out.join("\n") + "\n")
  puts "generated #{out_path}"
end
