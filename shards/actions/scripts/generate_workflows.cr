require "../../../src/rcl"

Dir.mkdir_p(".github/workflows")

def as_s(value : RCL::Value?) : String
  value.is_a?(String) ? value : ""
end

def as_arr(value : RCL::Value?) : Array(RCL::Value)
  value.is_a?(Array(RCL::Value)) ? value : ([] of RCL::Value)
end

Dir.glob("shards/actions/workflows/*.rcl") do |path|
  doc = RCL.parse_file(path)
  block = doc.blocks.first?
  raise "missing root workflow block in #{path}" unless block
  raise "root block must be `workflow` in #{path}" unless block.not_nil!.name == "workflow"
  workflow = doc.to_h

  id = block.not_nil!.argument || File.basename(path, ".rcl")
  out = [] of String
  out << "name: #{as_s(workflow["name"]?)}"
  out << ""
  out << "on:"
  as_arr(workflow["on"]?).each do |event|
    out << "  - #{event.as(String)}"
  end
  out << ""
  out << "jobs:"

  workflow.each do |key, value|
    next unless key == "job"
    next unless value.is_a?(Hash(String, RCL::Value))
    value.keys.sort.each do |job_id|
      job_any = value[job_id]
      job = job_any.as(Hash(String, RCL::Value))
      out << "  #{job_id}:"
      out << "    runs-on: #{as_s(job["runs_on"]?)}"
      out << "    steps:"
      as_arr(job["steps"]?).each do |step|
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
  end

  out_path = ".github/workflows/#{id}.yml"
  File.write(out_path, out.join("\n") + "\n")
  puts "generated #{out_path}"
end
